import AVFoundation
import Foundation
import Darwin

// AVAudioPlayerNode performs sample playback and overlap. The dispatch timer merely
// replenishes a look-ahead queue; every musical onset has an absolute audio frame.
final class TablaSequencer {
    private struct Source: Decodable { let bol: TablaBol; let file: String }
    private struct Manifest: Decodable { let samples: [Source] }
    private struct Voice { let player: AVAudioPlayerNode; var freeAt: Int64 = 0 }
    private let engine: AVAudioEngine
    private let sourceBus=AVAudioMixerNode()
    private let queue=DispatchQueue(label:"music.tabla.schedule",qos:.userInitiated)
    private var timer: DispatchSourceTimer?
    private var voices:[Voice]=[]
    // [bol][take][dynamic layer], all decoded and allocated before playback.
    private var buffers:[TablaBol:[[AVAudioPCMBuffer]]]=[:]
    private var takes:[TablaBol:Int]=[:]
    private var timeline=TablaTimeline(taal:.teentaal,bpm:80)
    private var state:TablaTransport = .stopped
    private var frozenFrame:Int64=0
    private var offlineOrigin:Int64=0
    private var generation=0
    private(set) var lateEvents=0
    private(set) var voiceExhaustions=0
    private let rate:Double=48000
    private var endFrame:Int64?
    private let horizon:Int64=5760 // 120 ms, not a musical timebase

    init(engine:AVAudioEngine,bus:AVAudioMixerNode,resources:URL) throws {
        self.engine=engine
        let format=AVAudioFormat(standardFormatWithSampleRate:48000,channels:2)!
        let manifest=try JSONDecoder().decode(Manifest.self,from:Data(contentsOf:resources.appendingPathComponent("tabla-sources.json")))
        for entry in manifest.samples {
            let file=try AVAudioFile(forReading:resources.appendingPathComponent(entry.file))
            guard file.processingFormat.sampleRate==rate,file.processingFormat.channelCount==2,
                  file.length>0,file.length<240000,
                  let original=AVAudioPCMBuffer(pcmFormat:file.processingFormat,frameCapacity:AVAudioFrameCount(file.length)) else {
                throw PracticeAudioGraph.GraphError.invalidResource(entry.file)
            }
            try file.read(into:original)
            let layers:[AVAudioPCMBuffer]=[Float(0.80),0.94,1.06].map { gain in
                let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:original.frameLength)!
                buffer.frameLength=original.frameLength
                for channel in 0..<2 {
                    for frame in 0..<Int(original.frameLength) {
                        buffer.floatChannelData![channel][frame]=original.floatChannelData![channel][frame]*gain
                    }
                }
                return buffer
            }
            buffers[entry.bol,default:[]].append(layers)
        }
        guard TablaBol.allCases.allSatisfy({buffers[$0]?.isEmpty==false}) else {
            throw PracticeAudioGraph.GraphError.invalidResource("tabla stroke list")
        }
        engine.attach(sourceBus);engine.connect(sourceBus,to:bus,format:format)
        for _ in 0..<24 {
            let node=AVAudioPlayerNode();engine.attach(node)
            engine.connect(node,to:sourceBus,format:format)
            voices.append(Voice(player:node))
        }
    }
    private func frameLocked() -> Int64 {
        guard state == .playing else { return frozenFrame }
        if engine.isInManualRenderingMode { return max(0,engine.manualRenderingSampleTime-offlineOrigin) }
        guard let node=voices.first?.player,let time=node.lastRenderTime,
              let playerTime=node.playerTime(forNodeTime:time) else { return frozenFrame }
        return max(0,playerTime.sampleTime)
    }
    func position() -> TablaPosition {
        queue.sync { timeline.position(at:frameLocked(),state:state) }
    }
    func start(_ settings:TablaSettings,automatic:Bool=true,endFrame:Int64?=nil) {
        queue.sync {
            guard state != .playing else { return }
            let resuming=state == .paused
            generation+=1;let token=generation
            self.endFrame=endFrame
            if state == .stopped {
                timeline=TablaTimeline(taal:settings.taal,bpm:settings.bpm)
                takes=[:];frozenFrame=0;lateEvents=0;voiceExhaustions=0
                for index in voices.indices { voices[index].freeAt=0 }
            }
            offlineOrigin=engine.manualRenderingSampleTime-frozenFrame
            state = .playing
            // Submit first strokes before starting the common player clock.
            pumpLocked(now:frozenFrame)
            if !resuming {
                sourceBus.outputVolume=1
                sourceBus.auAudioUnit.reset()
            }
            if engine.isInManualRenderingMode {
                sourceBus.outputVolume=1
                for voice in voices { voice.player.play() }
            } else {
                // A fresh attack starts only after Apple's native fader has settled.
                // Resume fades the frozen waveform in, rather than jumping into a tail.
                let lead=0.025
                sourceBus.outputVolume=resuming ? 0:1
                let start=AVAudioTime(hostTime:mach_absolute_time()+AVAudioTime.hostTime(forSeconds:lead))
                for voice in voices { voice.player.play(at:start) }
                if resuming {
                    queue.asyncAfter(deadline:.now()+lead) { [weak self] in
                        guard let self,self.generation==token,self.state == .playing else { return }
                        self.sourceBus.outputVolume=1
                    }
                }
            }
            if automatic {
                let timer=DispatchSource.makeTimerSource(queue:queue)
                timer.schedule(deadline:.now(),repeating:.milliseconds(20),leeway:.milliseconds(3))
                timer.setEventHandler { [weak self] in
                    guard let self,self.state == .playing else { return }
                    self.pumpLocked(now:self.frameLocked())
                }
                self.timer=timer;timer.resume()
            }
        }
    }
    func pump() { queue.sync { if state == .playing { pumpLocked(now:frameLocked()) } } }
    private func submitLocked(_ events:[TablaTimeline.Event],now:Int64) {
        for event in events {
            if event.frame<now { lateEvents+=1;continue } // never burst stale bols after a stall
            let group=buffers[event.stroke.bol]!
            let take=takes[event.stroke.bol,default:0]%group.count
            takes[event.stroke.bol,default:0]+=1
            let buffer=group[take][event.stroke.strength]
            guard let index=voices.firstIndex(where:{$0.freeAt<=event.frame}) else {
                voiceExhaustions+=1;continue
            }
            voices[index].player.scheduleBuffer(buffer,at:AVAudioTime(sampleTime:event.frame,atRate:rate),options:[])
            voices[index].freeAt=event.frame+Int64(buffer.frameLength)
        }
    }
    private func pumpLocked(now:Int64) {
        submitLocked(timeline.events(through:min(now+horizon,endFrame.map{$0-1} ?? Int64.max)),now:now)
    }
    func setTempo(_ bpm:Double) {
        queue.sync {
            if state == .playing { pumpLocked(now:frameLocked()) }
            timeline.setTempo(bpm)
        }
    }
    func setTaal(_ taal:TablaTaal,bpm:Double) {
        queue.sync {
            if state == .stopped { timeline=TablaTimeline(taal:taal,bpm:bpm);return }
            let now=frameLocked()
            if state == .playing { pumpLocked(now:now) }
            let boundary=Int64(timeline.frame(at:ceil(timeline.nextBeat)).rounded())
            // Finish old subdivisions before the new sam, without truncating any tails.
            submitLocked(timeline.events(through:boundary-1),now:now)
            timeline=TablaTimeline(taal:taal,bpm:bpm,startFrame:boundary)
            if state == .playing { pumpLocked(now:now) }
        }
    }
    func pause() {
        queue.sync {
            guard state == .playing else { return }
            generation+=1
            timer?.cancel();timer=nil
            fadeLocked(to:0)
            frozenFrame=frameLocked()
            for voice in voices { voice.player.pause() }
            state = .paused
        }
    }
    func stop() {
        queue.sync {
            guard state != .stopped else { return }
            generation+=1
            timer?.cancel();timer=nil
            fadeLocked(to:0)
            for voice in voices { voice.player.stop() }
            state = .stopped;frozenFrame=0
        }
    }
    private func fadeLocked(to target:Float) {
        // The mixer already supplies an audio-rate ramp (~2048 frames); avoid
        // repeatedly restarting it with control-rate micro-steps. Let it finish
        // before freezing/stopping a player, so a nonzero tail is never chopped.
        sourceBus.outputVolume=target
        if !engine.isInManualRenderingMode && engine.isRunning {
            Thread.sleep(forTimeInterval:0.06)
        }
    }
    deinit { timer?.cancel() }
}
