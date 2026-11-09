import AVFoundation
import Foundation

// Each bank runs in a separate process to avoid Apple's cross-instance SF2 cache.
@main
struct HarmoniumComparisonTests {
    static func main() throws {
        let resources=URL(fileURLWithPath:CommandLine.arguments[1])
        let output=URL(fileURLWithPath:CommandLine.arguments[2])
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        let graph=try PracticeAudioGraph(resources:resources)
        let stereo=AVAudioFormat(standardFormatWithSampleRate:48000,channels:2)!
        let mono=AVAudioFormat(standardFormatWithSampleRate:48000,channels:1)!
        try graph.engine.enableManualRenderingMode(.offline,format:stereo,maximumFrameCount:4096)
        try graph.startEngine()
        var settings=HarmoniumSettings(); settings.volume=0.6
        graph.applyHarmonium(settings,cents:0)
        let buffer=AVAudioPCMBuffer(pcmFormat:stereo,frameCapacity:4096)!
        let summed=AVAudioPCMBuffer(pcmFormat:mono,frameCapacity:4096)!
        func render(_ count:Int, file:AVAudioFile? = nil) throws {
            var remaining=count, stalled=0
            while remaining>0 {
                let frames=AVAudioFrameCount(min(4096,remaining))
                switch try graph.engine.renderOffline(frames,to:buffer) {
                case .success:
                    stalled=0; summed.frameLength=buffer.frameLength
                    for i in 0..<Int(buffer.frameLength) {
                        let value=(buffer.floatChannelData![0][i]+buffer.floatChannelData![1][i])*0.5
                        precondition(value.isFinite && abs(value)<1)
                        summed.floatChannelData![0][i]=value
                    }
                    if let file { try file.write(from:summed) }
                    remaining-=Int(buffer.frameLength)
                case .cannotDoInCurrentContext,.insufficientDataFromInputNode:
                    stalled+=1;precondition(stalled<100)
                default: fatalError("Comparison render failed")
                }
            }
        }
        let notes=CommandLine.arguments.count>3 ? CommandLine.arguments[3].split(separator:",").compactMap { Int($0) } : Array(36...72)
        for note in notes {
            let settings:[String:Any]=[AVFormatIDKey:kAudioFormatLinearPCM,AVSampleRateKey:48000,
                AVNumberOfChannelsKey:1,AVLinearPCMBitDepthKey:16,AVLinearPCMIsFloatKey:false]
            let file=try AVAudioFile(forWriting:output.appendingPathComponent("note_\(note).wav"),settings:settings,
                commonFormat:.pcmFormatFloat32,interleaved:false)
            graph.setNotes([note]);try render(48000*32,file:file)
            graph.setNotes([]);try render(24000)
        }
        graph.stop()
        print("PASS: \(notes.count) native 32-second sustain comparisons, including transposed zones")
    }
}
