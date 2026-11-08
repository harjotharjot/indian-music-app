// Offline research harness. No app UI or custom DSP.
import AVFoundation
import Foundation

@main
struct NativeShift {
    static func main() throws {
        guard CommandLine.arguments.count == 4,
              let cents = Float(CommandLine.arguments[3]) else {
            fatalError("Usage: native-shift input.wav output.wav cents")
        }
        let input = try AVAudioFile(forReading: URL(fileURLWithPath: CommandLine.arguments[1]))
        let format = input.processingFormat
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let pitch = AVAudioUnitTimePitch()
        pitch.rate = 1
        pitch.pitch = cents
        engine.attach(player)
        engine.attach(pitch)
        engine.connect(player, to: pitch, format: format)
        engine.connect(pitch, to: engine.mainMixerNode, format: format)
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
        player.scheduleFile(input, at: nil)
        try engine.start()
        player.play()
        let output = try AVAudioFile(forWriting: URL(fileURLWithPath: CommandLine.arguments[2]),
                                     settings: engine.manualRenderingFormat.settings)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat,
                                            frameCapacity: engine.manualRenderingMaximumFrameCount) else {
            fatalError("Cannot allocate rendering buffer")
        }
        // Preserve one second of tail for latency/duration measurement, not a V1 export policy.
        let end = input.length + AVAudioFramePosition(format.sampleRate)
        var retries = 0
        while engine.manualRenderingSampleTime < end {
            let frames = AVAudioFrameCount(min(AVAudioFramePosition(buffer.frameCapacity),
                                               end - engine.manualRenderingSampleTime))
            let status = try engine.renderOffline(frames, to: buffer)
            switch status {
            case .success:
                try output.write(from: buffer)
                retries = 0
            case .cannotDoInCurrentContext, .insufficientDataFromInputNode:
                retries += 1
                if retries > 100 { fatalError("Offline rendering stalled: \(status)") }
            case .error:
                fatalError("Offline render error")
            @unknown default:
                fatalError("Unknown render status")
            }
        }
        print("rate=\(pitch.rate) cents=\(pitch.pitch) reportedLatency=\(pitch.auAudioUnit.latency) inputFrames=\(input.length) outputFrames=\(output.length)")
        player.stop()
        engine.stop()
    }
}
