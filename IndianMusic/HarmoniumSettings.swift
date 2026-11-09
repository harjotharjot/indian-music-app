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
        let whiteWidth = max(44, width / 16)
        let content = KeyboardGeometry(start:36,span:36,width:22*whiteWidth,height:height)
        let offset = CGFloat(min(1,max(0,position))) * max(0,22*whiteWidth-width)
        keys = content.keys.map { Key(note:$0.note, frame:$0.frame.offsetBy(dx:-offset,dy:0), black:$0.black) }
        viewport = CGRect(x:0,y:0,width:width,height:height)
    }
    private var viewport: CGRect? = nil
    func note(at point: CGPoint) -> Int? {
        if let viewport, !viewport.contains(point) { return nil }
        guard let white = keys.first(where: { !$0.black && $0.frame.contains(point) }) else { return nil }
        let height = white.frame.height
        if point.y >= height * 0.5 { return white.note }
        let pc=white.note % 12
        let groupStart = white.note - (pc <= 4 ? pc : pc-5)
        let whites=keys.filter { !$0.black && $0.note >= groupStart && $0.note <= groupStart+(pc <= 4 ? 4:6) }
        let blacks=keys.filter { $0.black && $0.note > groupStart && $0.note < groupStart+(pc <= 4 ? 4:6) }
        guard let first=whites.first, !blacks.isEmpty else { return nil }
        let regionWidth=CGFloat(whites.count)*first.frame.width / CGFloat(blacks.count)
        let index=min(blacks.count-1,max(0,Int((point.x-first.frame.minX)/regionWidth)))
        return blacks[index].note
    }
}
