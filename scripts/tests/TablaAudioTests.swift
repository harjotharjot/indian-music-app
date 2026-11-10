import AVFoundation
import Foundation
@main struct TablaAudioTests {
    static func main() throws {
        let resources=URL(fileURLWithPath:CommandLine.arguments[1])
        let destination=URL(fileURLWithPath:CommandLine.arguments[2])
        try FileManager.default.createDirectory(at:destination,withIntermediateDirectories:true)
        let graph=try PracticeAudioGraph(resources:resources)
        let format=AVAudioFormat(standardFormatWithSampleRate:48000,channels:2)!
        try graph.engine.enableManualRenderingMode(.offline,format:format,maximumFrameCount:2048)
        graph.tablaMixer.outputVolume=1
        try graph.startEngine()
        let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:2048)!
        func render(_ frames:Int,file:String?=nil) throws -> Double {
            let out=try file.map { try AVAudioFile(forWriting:destination.appendingPathComponent($0),settings:format.settings) }
            var count=0,stalls=0;var energy=0.0
            while count<frames {
                graph.tabla.pump()
                let n=AVAudioFrameCount(min(2048,frames-count))
                switch try graph.engine.renderOffline(n,to:buffer) {
                case .success:
                    stalls=0;count+=Int(n)
                    if let out { try out.write(from:buffer) }
                    for ch in 0..<2 {
                        for i in 0..<Int(n) {
                            let v=buffer.floatChannelData![ch][i]
                            precondition(v.isFinite && abs(v)<1,"Clipping/nonfinite three-instrument mix")
                            energy+=Double(v*v)
                        }
                    }
                case .cannotDoInCurrentContext,.insufficientDataFromInputNode:
                    stalls+=1;precondition(stalls<100)
                default:fatalError("Render error")
                }
            }
            return sqrt(energy/Double(frames*2))
        }
        func tryCheckRender(_ frames:Int) -> Double { try! render(frames) }
        _=try render(4096) // Settle native monitor-fader smoothing before waveform comparisons.
        struct Reference:Codable { let taal:String;let bpm:Double;let cycles:Int;let frames:Int;let rms:Double }
        var results:[Reference]=[]
        for taal in TablaTaal.allCases {
            for bpm in [30.0,80,137,240] {
                let cycles=bpm==80 ? 4:2
                let end=Int64((Double(taal.matras*cycles)*48000*60/bpm).rounded())
                graph.tabla.start(TablaSettings(taal:taal,bpm:bpm,volume:1),automatic:false,endFrame:end)
                let rms=try render(Int(end)+3*48000,file:"\(taal.rawValue)-\(Int(bpm))bpm.wav")
                precondition(rms>0.005 && graph.tabla.lateEvents==0 && graph.tabla.voiceExhaustions==0)
                results.append(Reference(taal:taal.rawValue,bpm:bpm,cycles:cycles,frames:Int(end),rms:rms))
                graph.tabla.stop()
            }
        }
        try JSONEncoder().encode(results).write(to:destination.appendingPathComponent("renders.json"))
        graph.tabla.start(TablaSettings(taal:.dadra,bpm:80,volume:1),automatic:false)
        _=try render(60000,file:"pause-first.wav")
        graph.tabla.pause();_=try render(48000,file:"pause-silence.wav")
        graph.tabla.start(TablaSettings(taal:.dadra,bpm:80,volume:1),automatic:false)
        _=try render(144000,file:"pause-second.wav");graph.tabla.stop()
        _=try render(48000)
        graph.tabla.start(TablaSettings(taal:.dadra,bpm:80,volume:1),automatic:false)
        _=try render(24000,file:"restart-attack.wav");graph.tabla.stop()
        // Native long-run scheduling at an awkward tempo, with every refill at audio-block boundaries.
        graph.tabla.start(TablaSettings(taal:.ektaal,bpm:137),automatic:false)
        precondition(tryCheckRender(300*48000)>0.005)
        precondition(graph.tabla.lateEvents==0 && graph.tabla.voiceExhaustions==0)
        graph.tabla.setTempo(191);_=try render(48000)
        let before=graph.tabla.position();graph.tabla.pause()
        precondition(graph.tabla.position().state == .paused)
        precondition(tryCheckRender(48000)<1e-7)
        precondition(graph.tabla.position().matra==before.matra)
        graph.tabla.setTempo(73);graph.tabla.start(TablaSettings(taal:.ektaal,bpm:73),automatic:false)
        precondition(tryCheckRender(3*48000)>0.005)
        for taal in TablaTaal.allCases {
            graph.tabla.setTaal(taal,bpm:73)
            precondition(tryCheckRender(3*48000)>0.002)
            precondition(graph.tabla.position().taal==taal && graph.tabla.lateEvents==0 && graph.tabla.voiceExhaustions==0)
        }
        graph.tabla.stop();precondition(tryCheckRender(48000)<1e-7)
        // Worst specified practice combination: six-note chord, maximum faders, fastest compound theka.
        var h=HarmoniumSettings();h.volume=1;graph.applyHarmonium(h,cents:0)
        graph.setNotes([48,52,55,60,64,67])
        var t=TanpuraSettings();t.volume=1;graph.apply(t);graph.setVolume(1)
        try graph.play();graph.setGain(1,for:.pa);graph.setGain(0,for:.ma)
        graph.tabla.start(TablaSettings(taal:.ektaal,bpm:240,volume:1),automatic:false)
        let mixed=try render(8*48000,file:"all-three-max-faders.wav");precondition(mixed>0.01)
        graph.setGain(0,for:.pa);graph.setGain(1,for:.ma);_=try render(5*48000)
        for pattern in TanpuraPattern.allCases {
            graph.setGain(pattern == .pa ? 1:0,for:.pa);graph.setGain(pattern == .ma ? 1:0,for:.ma)
            for taal in TablaTaal.allCases {
                graph.tabla.setTaal(taal,bpm:240)
                _=try render(4*48000)
                precondition(graph.tabla.voiceExhaustions==0 && graph.tabla.lateEvents==0)
            }
        }
        graph.tablaMixer.outputVolume=0
        precondition(tryCheckRender(48000)>0.01,"Muting tabla must preserve the other buses")
        graph.allNotesOff();graph.setVolume(0);_=try render(48000)
        precondition(tryCheckRender(48000)<1e-6,"Muted independent buses must be silent")
        graph.tablaMixer.outputVolume=1;precondition(tryCheckRender(48000)>0.005)
        graph.tabla.stop();graph.stop()
        print("PASS: 24 native renders across six taals and four tempos plus full tails; five-minute native clock; pause/resume, tempo and six taal changes; no late events or voice stealing; maximum-fader all-three mix finite/unclipped; independent buses")
    }
}
