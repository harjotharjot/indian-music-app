import AVFoundation
import Foundation

struct TanpuraSource: Decodable {
    let pattern: TanpuraPattern
    let file: String
    let referenceHz: Double
}

// All control calls are serialized by AudioCoordinator on the main actor.
// Offline tests use this same graph without AVAudioSession or UI dependencies.
final class PracticeAudioGraph {
    let engine = AVAudioEngine()
    // Dry buses are independent and share the engine clock. No taps/capture are installed.
    let tanpuraBus = AVAudioMixerNode()
    let harmoniumBus = AVAudioMixerNode()
    let tanpuraMixer = AVAudioMixerNode() // monitor fader
    let harmoniumMixer = AVAudioMixerNode() // monitor fader
    let sampler = AVAudioUnitSampler()
    private(set) var activeNotes: Set<Int> = []
    private let soundBankURL: URL
    private var voices: [TanpuraPattern: Voice] = [:]

    private struct Voice {
        let player: AVAudioPlayerNode
        let pitch: AVAudioUnitTimePitch
        let buffer: AVAudioPCMBuffer
        let referenceHz: Double
    }
    enum GraphError: LocalizedError {
        case invalidResource(String)
        var errorDescription: String? {
            switch self {
            case .invalidResource(let file): return "Cannot load tanpura sound: \(file)."
            }
        }
    }

    init(resources: URL) throws {
        soundBankURL = resources.appendingPathComponent("harmonium.sf2")
        let metadata = try Data(contentsOf: resources.appendingPathComponent("tanpura-sources.json"))
        let sources = try JSONDecoder().decode([TanpuraSource].self, from: metadata)
        guard sources.count == 2, Set(sources.map(\.pattern)) == Set(TanpuraPattern.allCases) else {
            throw GraphError.invalidResource("source list")
        }
        engine.attach(tanpuraMixer)
        engine.attach(tanpuraBus)
        engine.attach(harmoniumBus)
        engine.attach(harmoniumMixer)
        engine.attach(sampler)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2) else {
            throw GraphError.invalidResource("audio format")
        }
        engine.connect(tanpuraBus, to: tanpuraMixer, format: format)
        engine.connect(tanpuraMixer, to: engine.mainMixerNode, format: format)
        engine.connect(sampler, to: harmoniumBus, format: format)
        engine.connect(harmoniumBus, to: harmoniumMixer, format: format)
        engine.connect(harmoniumMixer, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.8
        try sampler.loadSoundBankInstrument(at: resources.appendingPathComponent("harmonium.sf2"),
                                           program: 0, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0)
        harmoniumMixer.outputVolume = 0.6
        for source in sources {
            guard source.referenceHz.isFinite, (120...145).contains(source.referenceHz) else {
                throw GraphError.invalidResource(source.file)
            }
            let file = try AVAudioFile(forReading: resources.appendingPathComponent(source.file))
            guard file.length > 0, file.length < 10_000_000,
                  file.processingFormat.sampleRate == 48_000,
                  file.processingFormat.channelCount == 2,
                  let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                 frameCapacity: AVAudioFrameCount(file.length)) else {
                throw GraphError.invalidResource(source.file)
            }
            try file.read(into: buffer)
            let player = AVAudioPlayerNode()
            let pitch = AVAudioUnitTimePitch()
            engine.attach(player)
            engine.attach(pitch)
            engine.connect(player, to: pitch, format: format)
            engine.connect(pitch, to: tanpuraBus, format: format)
            player.volume = 0
            voices[source.pattern] = Voice(player: player, pitch: pitch, buffer: buffer,
                                            referenceHz: source.referenceHz)
        }
        tanpuraMixer.outputVolume = 0
    }

    func apply(_ settings: TanpuraSettings) {
        let settings = settings.validated()
        for voice in voices.values {
            voice.pitch.pitch = settings.pitchShiftCents(referenceHz: voice.referenceHz)
            voice.pitch.rate = Float(settings.speed)
        }
    }
    func play() throws {
        // Both patterns stay scheduled, so switching only crossfades gains.
        for voice in voices.values {
            voice.player.stop()
            voice.player.scheduleBuffer(voice.buffer, at: nil, options: .loops)
        }
        try startEngine()
        for voice in voices.values { voice.player.play() }
    }
    func startEngine() throws {
        if !engine.isRunning {
            engine.prepare()
            try engine.start()
            // Engine resource allocation can reset the sampler instrument. Restore the
            // recorded bank after allocation, before accepting any keyboard notes.
            do {
                try sampler.loadSoundBankInstrument(at: soundBankURL, program: 0,
                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0)
            } catch { engine.stop(); throw error }
        }
    }
    func stopTanpura() {
        for voice in voices.values { voice.player.stop() }
    }
    func stop() {
        allNotesOff()
        stopTanpura()
        engine.stop()
    }
    func applyHarmonium(_ settings: HarmoniumSettings, cents: Double) {
        sampler.globalTuning = Float(cents)
        harmoniumMixer.outputVolume = Float(settings.validated().volume)
    }
    func setNotes(_ notes: Set<Int>) {
        let safe = Set(notes.filter { (36...84).contains($0) })
        for note in activeNotes.subtracting(safe) { sampler.stopNote(UInt8(note), onChannel: 0) }
        for note in safe.subtracting(activeNotes) { sampler.startNote(UInt8(note), withVelocity: 90, onChannel: 0) }
        activeNotes = safe
    }
    func allNotesOff() {
        setNotes([])
        sampler.sendController(123, withValue: 0, onChannel: 0)
        sampler.sendController(120, withValue: 0, onChannel: 0)
    }
    func setVolume(_ volume: Float) { tanpuraMixer.outputVolume = volume }
    func volume() -> Float { tanpuraMixer.outputVolume }
    func setGain(_ gain: Float, for pattern: TanpuraPattern) { voices[pattern]?.player.volume = gain }
    func gain(for pattern: TanpuraPattern) -> Float { voices[pattern]?.player.volume ?? 0 }
}
