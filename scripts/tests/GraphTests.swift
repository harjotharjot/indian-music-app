import AVFoundation
import Foundation

@main
struct GraphTests {
    static func main() throws {
        let resources = URL(fileURLWithPath: CommandLine.arguments[1])
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2) else {
            fatalError("Invalid render format")
        }
        for pattern in TanpuraPattern.allCases {
            let graph = try PracticeAudioGraph(resources: resources)
            try graph.engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
            var settings = TanpuraSettings()
            settings.pattern = pattern
            settings.cents = 37
            settings.speed = pattern == .pa ? 0.75 : 1.25
            graph.apply(settings)
            graph.setGain(pattern == .pa ? 1 : 0, for: .pa)
            graph.setGain(pattern == .ma ? 1 : 0, for: .ma)
            graph.setVolume(0.8)
            try graph.play()
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4096)!
            let total: AVAudioFramePosition = 48_000 * 160
            var minRMS = Double.greatestFiniteMagnitude
            var peak = 0.0
            var stalled = 0
            while graph.engine.manualRenderingSampleTime < total {
                let frames = AVAudioFrameCount(min(4096, total - graph.engine.manualRenderingSampleTime))
                switch try graph.engine.renderOffline(frames, to: buffer) {
                case .success:
                    stalled = 0
                    let data = buffer.floatChannelData!
                    var energy = 0.0
                    for channel in 0..<2 {
                        for index in 0..<Int(buffer.frameLength) {
                            let value = Double(data[channel][index])
                            precondition(value.isFinite)
                            energy += value*value
                            peak = max(peak, abs(value))
                        }
                    }
                    if graph.engine.manualRenderingSampleTime > 48_000 {
                        minRMS = min(minRMS, sqrt(energy / Double(buffer.frameLength * 2)))
                    }
                case .cannotDoInCurrentContext, .insufficientDataFromInputNode:
                    stalled += 1
                    precondition(stalled < 100, "Render stalled")
                case .error: fatalError("Render failed")
                @unknown default: fatalError("Unknown render state")
                }
            }
            precondition(minRMS > 0.00001, "Unexpected silent block at a loop boundary")
            precondition(peak > 0.01 && peak < 1, "Silent or clipping output")
            graph.stop()
            try graph.play()
            // Allow native TimePitch to fill internal buffers after a restart.
            var energy = 0.0
            for _ in 0..<10 {
                if try graph.engine.renderOffline(4096, to: buffer) == .success {
                    for i in 0..<Int(buffer.frameLength) {
                        energy += abs(Double(buffer.floatChannelData![0][i]))
                    }
                }
            }
            precondition(energy > 1, "Restart did not produce audio")
            graph.stop()
            print("PASS: \(pattern.rawValue) 160-second shared-graph render at speed \(settings.speed), +37 cents; min block RMS=\(minRMS), peak=\(peak), restart passed.")
        }
    }
}
