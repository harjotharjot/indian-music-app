import Foundation

enum TanpuraPattern: String, Codable, CaseIterable, Identifiable {
    case pa, ma
    var id: String { rawValue }
    var title: String { self == .pa ? "Sa–Pa" : "Sa–Ma" }
    var description: String { self == .pa ? "Pa · Sa · Sa · low Sa" : "Ma · Sa · Sa · low Sa" }
}

struct TanpuraSettings: Codable, Equatable {
    static let noteNames = ["C", "C♯ / D♭", "D", "D♯ / E♭", "E", "F", "F♯ / G♭", "G", "G♯ / A♭", "A", "A♯ / B♭", "B"]
    var pattern: TanpuraPattern = .pa
    var key: Int = 1
    var octave: Int = 3
    var cents: Double = 0
    var speed: Double = 1
    var volume: Double = 0.6

    var frequency: Double {
        let midi = (octave + 1) * 12 + key
        return 440 * pow(2, (Double(midi - 69) + cents / 100) / 12)
    }
    var saName: String { "\(Self.noteNames[key])\(octave)" }
    func pitchShiftCents(referenceHz: Double) -> Float {
        Float(1200 * log2(frequency / referenceHz))
    }
    func validated() -> Self {
        var result = self
        result.key = min(11, max(0, key))
        result.octave = min(3, max(2, octave))
        result.cents = cents.isFinite ? min(100, max(-100, cents)) : 0
        result.speed = speed.isFinite ? min(1.25, max(0.75, speed)) : 1
        result.volume = volume.isFinite ? min(1, max(0, volume)) : 0.6
        return result
    }
}
