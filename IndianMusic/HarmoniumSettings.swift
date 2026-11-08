import Foundation
import CoreGraphics

struct HarmoniumSettings: Codable, Equatable {
    var volume: Double = 0.6
    var octave: Int = 3
    var twoOctaves = false
    var showSargam = true
    var startNote: Int { (octave + 1) * 12 }
    var span: Int { twoOctaves ? 24 : 12 }
    func validated() -> Self {
        var value = self
        value.volume = volume.isFinite ? min(1, max(0, volume)) : 0.6
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
                frame = CGRect(x: CGFloat(whiteIndex)*w-w*0.32, y: 0, width: w*0.64, height: height*0.62)
            } else {
                frame = CGRect(x: CGFloat(whiteIndex)*w, y: 0, width: w, height: height)
                whiteIndex += 1
            }
            result.append(Key(note: note, frame: frame, black: black))
        }
        keys = result
    }
    func note(at point: CGPoint) -> Int? {
        keys.first { $0.black && $0.frame.contains(point) }?.note ??
        keys.first { !$0.black && $0.frame.contains(point) }?.note
    }
}
