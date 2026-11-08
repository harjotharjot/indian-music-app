import AVFoundation
import Foundation

struct TanpuraSource: Decodable {
    let pattern: TanpuraPattern
    let file: String
    let referenceHz: Double
}

// All control calls are serialized by AudioCoordinator on the main actor.
// Offline tests use this same graph without AVAudioSession or UI dependencies.
final class TanpuraGraph {
    let engine = AVAudioEngine()
    let tanpuraMixer = AVAudioMixerNode()
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
        let metadata = try Data(contentsOf: resources.appendingPathComponent("tanpura-sources.json"))
        let sources = try JSONDecoder().decode([TanpuraSource].self, from: metadata)
        guard sources.count == 2, Set(sources.map(\.pattern)) == Set(TanpuraPattern.allCases) else {
            throw GraphError.invalidResource("source list")
        }
        engine.attach(tanpuraMixer)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2) else {
            throw GraphError.invalidResource("audio format")
        }
        engine.connect(tanpuraMixer, to: engine.mainMixerNode, format: format)
        for source in sources {
            guard source.referenceHz.isFinite, (130...145).contains(source.referenceHz) else {
                throw GraphError.invalidResource(source.file)
            }
            let file = try AVAudioFile(forReading: resources.appendingPathComponent(source.file))
            guard file.length > 0, file.length < 2_000_000,
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
            engine.connect(pitch, to: tanpuraMixer, format: format)
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
        if !engine.isRunning {
            engine.prepare()
            try engine.start()
        }
        for voice in voices.values { voice.player.play() }
    }
    func stop() {
        for voice in voices.values { voice.player.stop() }
        engine.stop()
    }
    func setVolume(_ volume: Float) { tanpuraMixer.outputVolume = volume }
    func volume() -> Float { tanpuraMixer.outputVolume }
    func setGain(_ gain: Float, for pattern: TanpuraPattern) { voices[pattern]?.player.volume = gain }
    func gain(for pattern: TanpuraPattern) -> Float { voices[pattern]?.player.volume ?? 0 }
}
