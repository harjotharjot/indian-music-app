import Foundation
import CoreGraphics

struct HarmoniumSettings: Codable, Equatable {
    var volume: Double = 0.6
    var octave: Int = 3
    var twoOctaves = false
    var showSargam = true
    var navigationPosition: Double? = nil
    var navigation: Double { min(1, max(0, navigationPosition ?? Double(octave - 2) / 2)) }
    var startNote: Int { (octave + 1) * 12 }
    var span: Int { twoOctaves ? 24 : 12 }
    func validated() -> Self {
        var value = self
        value.volume = volume.isFinite ? min(1, max(0, volume)) : 0.6
        if let position = navigationPosition { value.navigationPosition = position.isFinite ? min(1,max(0,position)) : 0 }
        value.octave = min(twoOctaves ? 3 : 4, max(2, octave))
        return value
    }
    static func sargam(note: Int, sa: Int) -> String {
        ["Sa", "re", "Re", "ga", "Ga", "Ma", "Mā", "Pa", "dha", "Dha", "ni", "Ni"][((note - sa) % 12 + 12) % 12]
    }
}

// Finger identity survives a slide off the keyboard. End/cancel cannot leave a voice held.
struct TouchNoteLedger<ID: Hashable> {
    private struct Position { var note: Int? }
    private var touches: [ID: Position] = [:]
    var notes: Set<Int> { Set(touches.values.compactMap(\.note)) }
    mutating func begin(_ id: ID, note: Int?) { touches[id] = Position(note: note) }
    mutating func move(_ id: ID, note: Int?) {
        guard touches[id] != nil else { return }
        touches[id] = Position(note: note)
    }
    mutating func end(_ id: ID) { touches.removeValue(forKey: id) }
    mutating func cancelAll() { touches.removeAll() }
}

struct KeyboardGeometry {
    struct Key { let note: Int; let frame: CGRect; let black: Bool }
    let keys: [Key]
    init(start: Int, span: Int, width: CGFloat, height: CGFloat) {
        func isBlack(_ note: Int) -> Bool { [1,3,6,8,10].contains(note % 12) }
        let whiteCount = (start...start+span).filter { !isBlack($0) }.count
        let w = width / CGFloat(whiteCount)
        var whiteIndex = 0
        var result: [Key] = []
        for note in start...start+span {
            let black = isBlack(note)
            let frame: CGRect
            if black {
                frame = CGRect(x: CGFloat(whiteIndex)*w-w*0.28, y: 0, width: w*0.56, height: height*0.61)
            } else {
                frame = CGRect(x: CGFloat(whiteIndex)*w, y: 0, width: w, height: height)
                whiteIndex += 1
            }
            result.append(Key(note: note, frame: frame, black: black))
        }
        keys = result
    }
    init(position: Double, width: CGFloat, height: CGFloat) {
        // Stable key widths; navigation changes only the viewport translation.
        let whiteWidth = max(44, height / 4.05)
        let content = KeyboardGeometry(start:36,span:36,width:22*whiteWidth,height:height)
        let offset = CGFloat(min(1,max(0,position))) * max(0,22*whiteWidth-width)
        keys = content.keys.map { Key(note:$0.note, frame:$0.frame.offsetBy(dx:-offset,dy:0), black:$0.black) }
        viewport = CGRect(x:0,y:0,width:width,height:height)
    }
    private var viewport: CGRect? = nil
    func note(at point: CGPoint) -> Int? {
        if let viewport, !viewport.contains(point) { return nil }
        guard let firstWhite=keys.first(where:{ !$0.black }), let lastWhite=keys.last(where:{ !$0.black }),
            point.y>=0,point.y<firstWhite.frame.height,
            point.x>=firstWhite.frame.minX,point.x<lastWhite.frame.maxX else { return nil }
        let blacks=keys.filter { $0.black }
        if let first=blacks.first, point.y < first.frame.maxY {
            // The entire upper region belongs to black keys. Adjacent territories
            // meet at their center midpoint, including across B/C and E/F gaps.
            for index in 0..<(blacks.count-1) {
                let boundary=(blacks[index].frame.midX+blacks[index+1].frame.midX)/2
                if point.x < boundary { return blacks[index].note }
            }
            return blacks.last?.note
        }
        let whites=keys.filter { !$0.black }
        guard let first=whites.first, point.y>=0, point.y<first.frame.height else { return nil }
        // One canonical coordinate transform avoids infinitesimal gaps between
        // separately translated CGRects at shared white-key borders.
        let index=Int(floor((point.x-first.frame.minX)/first.frame.width))
        return whites.indices.contains(index) ? whites[index].note:nil
    }
}

// Taps are immediate. Only a change of note under an existing finger is filtered.
// Very brief crossings keep the previous note; a deliberate glissando that stays
// in each region for >=18 ms still plays every note. No delayed note survives lift.
struct SlideIntentFilter<ID: Hashable> {
    private struct Finger {
        var accepted: Int?
        var candidate: Int?
        var deadline: TimeInterval?
        var point: CGPoint
        var time: TimeInterval
    }
    private var fingers: [ID: Finger] = [:]
    var nextDeadline: TimeInterval? { fingers.values.compactMap(\.deadline).min() }
    var accepted: [ID: Int] { fingers.compactMapValues(\.accepted) }
    mutating func begin(_ id: ID, note: Int?, point: CGPoint, time: TimeInterval) {
        fingers[id] = Finger(accepted:note,candidate:nil,deadline:nil,point:point,time:time)
    }
    mutating func move(_ id: ID, note: Int?, point: CGPoint, time: TimeInterval) {
        guard var finger=fingers[id] else { return }
        let dt=max(0.001,time-finger.time)
        let speed=Double(hypot(point.x-finger.point.x,point.y-finger.point.y))/dt
        finger.point=point; finger.time=time
        if note == nil {
            finger.accepted=nil; finger.candidate=nil; finger.deadline=nil
        } else if note == finger.accepted {
            finger.candidate=nil; finger.deadline=nil
        } else if note != finger.candidate {
            finger.candidate=note
            let dwell: TimeInterval = speed < 180 ? 0.006 : speed < 1000 ? 0.012 : 0.018
            finger.deadline=time+dwell
        }
        fingers[id]=finger
    }
    mutating func advance(to time: TimeInterval) {
        for id in Array(fingers.keys) {
            guard var finger=fingers[id],let deadline=finger.deadline,deadline<=time else { continue }
            finger.accepted=finger.candidate; finger.candidate=nil; finger.deadline=nil
            fingers[id]=finger
        }
    }
    mutating func end(_ id: ID) { fingers.removeValue(forKey:id) }
    mutating func cancelAll() { fingers.removeAll() }
}

// Independent of interface orientation: physical gravity still changes while
// iOS portrait lock is on. Only an actual landscape -> portrait movement exits.
enum PracticePhysicalPose: Equatable {
    case portrait, landscapeLeft, landscapeRight, uncertain
    var isLandscape: Bool { self == .landscapeLeft || self == .landscapeRight }
    static func gravity(x: Double,y: Double,z: Double) -> Self {
        guard abs(z)<0.65 else { return .uncertain }
        if y < -0.82 && abs(x)<0.42 { return .portrait }
        if abs(x)>0.82 && abs(y)<0.42 { return x>0 ? .landscapeLeft:.landscapeRight }
        return .uncertain
    }
}
struct PracticeFullscreenState {
    private(set) var active=false
    private(set) var portraitReturnArmed=false
    private(set) var confirmedLandscape: PracticePhysicalPose?
    private var pose: PracticePhysicalPose = .uncertain
    private var since: TimeInterval = 0
    mutating func enter() { active=true;portraitReturnArmed=false;confirmedLandscape=nil;resetObservation() }
    mutating func exit() { active=false;portraitReturnArmed=false;confirmedLandscape=nil;resetObservation() }
    mutating func resetObservation() { pose = .uncertain;since=0 }
    mutating func observe(_ value: PracticePhysicalPose,time: TimeInterval) -> Bool {
        guard active else { return false }
        if value != pose { pose=value;since=time }
        if value.isLandscape && time-since>=0.35 {
            portraitReturnArmed=true;confirmedLandscape=value
        }
        if value == .portrait && portraitReturnArmed && time-since>=0.5 {
            exit();return true
        }
        return false
    }
}
