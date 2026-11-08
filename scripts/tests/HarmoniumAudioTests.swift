import AVFoundation
import Foundation

@main
struct HarmoniumAudioTests {
    static func main() throws {
        let resources=URL(fileURLWithPath:CommandLine.arguments[1])
        let destination=URL(fileURLWithPath:CommandLine.arguments[2])
        try FileManager.default.createDirectory(at:destination,withIntermediateDirectories:true)
        let graph=try PracticeAudioGraph(resources:resources)
        let format=AVAudioFormat(standardFormatWithSampleRate:48000,channels:2)!
        try graph.engine.enableManualRenderingMode(.offline,format:format,maximumFrameCount:4096)
        try graph.startEngine()
        let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:4096)!
        func render(_ count: Int, file: String? = nil) throws -> [Float] {
            let output=try file.map { try AVAudioFile(forWriting:destination.appendingPathComponent($0),settings:format.settings) }
            var result:[Float]=[];var stalled=0
            while result.count<count {
                let frames=AVAudioFrameCount(min(4096,count-result.count))
                switch try graph.engine.renderOffline(frames,to:buffer) {
                case .success:
                    stalled=0
                    if let output { try output.write(from:buffer) }
                    for i in 0..<Int(buffer.frameLength) {
                        let value=buffer.floatChannelData![0][i]
                        precondition(value.isFinite && abs(value)<1,"Nonfinite/clipping output")
                        result.append(value)
                    }
                case .cannotDoInCurrentContext,.insufficientDataFromInputNode:
                    stalled+=1;precondition(stalled<100)
                default:fatalError("Offline render failed")
                }
            }
            return result
        }
        var hs=HarmoniumSettings();hs.volume=0.45
        // Every playable key, both cents directions, actual Apple sampler renders.
        for note in 36...72 {
            for cents in [-37.0,0,37] {
                graph.applyHarmonium(hs,cents:cents)
                graph.setNotes([note])
                let y=try render(48000,file:"note_\(note)_\(Int(cents)).wav")
                precondition(y.map { abs($0) }.max()!>0.001)
                graph.setNotes([])
                let tail=try render(24000)
                precondition(tail.suffix(4096).allSatisfy { abs($0)<0.00001 },"Stuck note \(note)")
            }
        }
        graph.applyHarmonium(hs,cents:0)
        graph.setNotes([48,52,55,58,61,65])
        precondition(graph.activeNotes.count==6)
        _=try render(48000,file:"chord.wav")
        graph.setNotes([48,55,58,61,65]);precondition(graph.activeNotes.count==5)
        _=try render(48000)
        graph.allNotesOff();let quiet=try render(24000)
        precondition(quiet.suffix(4096).allSatisfy { abs($0)<0.00001 })
        graph.setNotes([57]);_=try render(48000*8,file:"held.wav")
        graph.allNotesOff();_=try render(24000)
        // Both buses sounding, changing patterns/tuning and note-off during the drone.
        var ts=TanpuraSettings();graph.apply(ts);graph.setVolume(0.4);graph.setGain(1,for:.pa)
        try graph.play();graph.setNotes([48,52,55])
        _=try render(48000*4,file:"mixed.wav")
        graph.setGain(0,for:.pa);graph.setGain(1,for:.ma);ts.cents=17;graph.apply(ts)
        graph.setNotes([50,53,57]);_=try render(48000*4)
        graph.harmoniumMixer.outputVolume = 0
        let droneOnly = try render(24000)
        precondition(droneOnly.map { abs($0) }.max()! > 0.001)
        graph.setVolume(0)
        let muted = try render(24000)
        precondition(muted.suffix(4096).allSatisfy { abs($0) < 0.00001 })
        graph.harmoniumMixer.outputVolume = 0.45
        graph.allNotesOff();graph.stopTanpura();_=try render(24000)
        for _ in 0..<20 { graph.setNotes([48,55]);_=try render(512);graph.allNotesOff();_=try render(512) }
        graph.allNotesOff();_=try render(24000)
        precondition(graph.activeNotes.isEmpty)
        graph.stop()
        print("PASS: 111 tuned key renders; released voices silent; six-note chord; eight-second sustain; simultaneous tanpura; rapid all-notes-off stress")
    }
}
