import Foundation

@main
struct SettingsTests {
    static func main() throws {
        var settings = TanpuraSettings()
        settings.key = 9
        settings.octave = 3
        precondition(abs(settings.frequency - 220) < 1e-9)
        settings.cents = 1
        precondition(abs(settings.frequency / 220 - pow(2, 1.0/1200)) < 1e-10)
        settings.key = 0
        settings.octave = 2
        settings.cents = 0
        precondition(abs(settings.frequency - 65.40639132514966) < 1e-8)
        for key in 0..<12 {
            settings.key = key
            for octave in 2...3 {
                settings.octave = octave
                for cents in [-100.0, 0, 37, 100] {
                    settings.cents = cents
                    let shift = settings.pitchShiftCents(referenceHz: 138.77)
                    let actual = 138.77 * pow(2, Double(shift)/1200)
                    precondition(abs(1200 * log2(actual/settings.frequency)) < 0.001)
                    precondition(abs(shift) < 2400)
                }
            }
        }
        let roundTrip = try JSONDecoder().decode(TanpuraSettings.self,
                                                  from: JSONEncoder().encode(settings))
        precondition(roundTrip == settings)
        settings.key = -9
        settings.octave = 9
        settings.cents = .nan
        settings.speed = 10
        settings.volume = -1
        let safe = settings.validated()
        precondition(safe.key == 0 && safe.octave == 3 && safe.cents == 0)
        precondition(safe.speed == 1.25 && safe.volume == 0)
        print("PASS: frequency, one-cent tuning, all 12 keys in two octaves, pitch range, persistence and invalid-value clamping.")
    }
}
