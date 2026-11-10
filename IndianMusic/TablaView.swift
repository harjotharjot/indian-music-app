import SwiftUI

struct TablaView:View {
    @EnvironmentObject private var audio:AudioCoordinator
    @EnvironmentObject private var fullscreen:PracticeFullscreenController
    @State private var showCredits=false
    @State private var showTaals=false
    @Environment(\.scenePhase) private var scenePhase
    // Display refresh only. Musical events are scheduled in audio sample frames.
    private let displayClock=Timer.publish(every:0.1,on:.main,in:.common).autoconnect()
    var body:some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    let compact=geometry.size.width>geometry.size.height
                    VStack(spacing:compact ? 10:16) {
                        if compact {
                            HStack(spacing:12) {
                                taalPicker
                                Spacer(minLength:4)
                                playbackControls
                                Spacer(minLength:4)
                                positionIndicator
                            }
                            HStack(spacing:10) {
                                bpmLabel
                                tempoSlider
                                bpmStepper
                                volumeControls.frame(width:geometry.size.width*0.3)
                            }
                        } else {
                            HStack { taalPicker;Spacer();bpmLabel }
                            HStack(spacing:14) { playbackControls;Spacer();positionIndicator }
                            VStack(spacing:6) {
                                HStack { Text("Tempo");Spacer();bpmStepper }
                                tempoSlider
                            }
                            volumeControls
                        }
                        beatGrid(width:geometry.size.width-32)
                        Text("Tempo and taal changes take effect at the next unscheduled matra. Stroke tails ring naturally across beats and cycles.")
                            .font(.caption).foregroundStyle(.secondary)
                        if let message=audio.message { Text(message).font(.caption).foregroundStyle(.secondary) }
                        #if DEBUG
                        if ProcessInfo.processInfo.arguments.contains("--phase5-audio-regression") {
                            HStack {
                                Button("Begin interruption") { audio.testAudioNotification(0) }.accessibilityIdentifier("tabla.testBegin")
                                Button("End interruption") { audio.testAudioNotification(1) }.accessibilityIdentifier("tabla.testEnd")
                                Button("Recover engine") { audio.testAudioNotification(2) }.accessibilityIdentifier("tabla.testRecover")
                            }
                        }
                        #endif
                    }.padding(16)
                }
            }
            .navigationTitle("Tabla").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.navigationBarLeading) {
                    Button { showCredits=true } label: { Image(systemName:"info.circle") }.accessibilityLabel("Tabla sound credits")
                }
                if fullscreen.isForced {
                    ToolbarItem(placement:.navigationBarTrailing) {
                        Button { audio.releaseKeys();fullscreen.exit() } label: {
                            Label("Exit full screen",systemImage:"arrow.down.right.and.arrow.up.left")
                        }.accessibilityIdentifier("tabla.exitFullscreen")
                    }
                }
            }
            .sheet(isPresented:$showCredits) {
                NavigationStack {
                    List {
                        Text("Actual recorded tabla bols from Naad by Oormi Creations and Contributors. Upstream distributes the library under MIT; individual recording performers are not identified.")
                        Link("Naad sample library",destination:URL(string:"https://github.com/oormicreations/naad")!)
                        Text("Whole recorded attacks and decays, native sample playback, compatible alternate takes and light accents. No synthesized strokes or artificial sustain loops. Source pitch is fixed; shared Sa controls do not transpose tabla.")
                        Text("Thekas and vibhags checked against David and Chandrakantha Courtney’s Index of Tals. One standard basic theka per taal. Rupak’s sam is khali.")
                        Link("Taal reference",destination:URL(string:"https://chandrakantha.com/music-and-dance/i-class-music/index-of-tals/")!)
                        Text((try? String(contentsOf:Bundle.main.resourceURL!.appendingPathComponent("Sounds/Tabla/LICENSE.txt"))) ?? "MIT notice is included with the sample files.")
                    }.navigationTitle("Tabla sources").toolbar { Button("Done") { showCredits=false } }
                }
            }
            .sheet(isPresented:$showTaals) {
                NavigationStack {
                    List(TablaTaal.allCases) { taal in
                        Button {
                            audio.tablaSettings.taal=taal
                            showTaals=false
                        } label: {
                            HStack {
                                Text("\(taal.title) · \(taal.matras)")
                                Spacer()
                                if audio.tablaSettings.taal == taal { Image(systemName:"checkmark") }
                            }
                        }.accessibilityLabel("\(taal.title) · \(taal.matras)")
                    }.navigationTitle("Choose taal").navigationBarTitleDisplayMode(.inline)
                        .toolbar { Button("Done") { showTaals=false } }
                }.presentationDetents([.medium,.large])
            }
            .onReceive(displayClock) { _ in
                if scenePhase == .active && !showCredits && !showTaals && audio.tablaState == .playing { audio.refreshTablaPosition() }
            }
        }
    }
    private var taalPicker:some View {
        Button { showTaals=true } label: {
            HStack(spacing:5) {
                Text("\(audio.tablaSettings.taal.title) · \(audio.tablaSettings.taal.matras)")
                Image(systemName:"chevron.down").font(.caption)
            }
        }.accessibilityLabel("\(audio.tablaSettings.taal.title) · \(audio.tablaSettings.taal.matras)")
            .accessibilityIdentifier("tabla.taal")
    }
    private var bpmLabel:some View {
        Text("\(Int(audio.tablaSettings.bpm)) BPM").font(.title3.monospacedDigit())
            .fixedSize().accessibilityIdentifier("tabla.bpmLabel")
    }
    private var bpmStepper:some View {
        Stepper("BPM",value:$audio.tablaSettings.bpm,in:30...240,step:1).labelsHidden()
            .accessibilityLabel("BPM").accessibilityIdentifier("tabla.bpmStepper")
    }
    private var tempoSlider:some View {
        Slider(value:$audio.tablaSettings.bpm,in:30...240,step:1)
            .accessibilityLabel("Tempo").accessibilityIdentifier("tabla.tempo")
    }
    private var volumeControls:some View {
        HStack {
            Text("Volume")
            Slider(value:$audio.tablaSettings.volume,in:0...1)
                .accessibilityLabel("Tabla volume").accessibilityIdentifier("tabla.volume")
        }
    }
    private var playbackControls:some View {
        HStack(spacing:14) {
            Button(action:{ audio.tablaState == .playing ? audio.pauseTabla():audio.startTabla() }) {
                Label(audio.tablaState == .playing ? "Pause":(audio.tablaState == .paused ? "Resume":"Start"),systemImage:audio.tablaState == .playing ? "pause.fill":"play.fill")
                    .frame(minWidth:90,minHeight:34)
            }.buttonStyle(.borderedProminent).accessibilityIdentifier("tabla.playPause")
            Button("Stop",action:audio.stopTabla).buttonStyle(.bordered).accessibilityIdentifier("tabla.stop")
        }
    }
    private var positionIndicator:some View {
        VStack(alignment:.trailing) {
            Text(positionText).font(.headline.monospacedDigit()).fixedSize().accessibilityIdentifier("tabla.matra")
            if audio.tablaPosition.matra==1 {
                Text(audio.tablaSettings.taal.khali.contains(1) ? "SAM · KHALI":"SAM")
                    .font(.caption.bold()).foregroundStyle(.green).accessibilityIdentifier("tabla.sam")
            } else { Text(audio.tablaState.rawValue.capitalized).font(.caption).foregroundStyle(.secondary) }
        }
    }
    private var positionText:String {
        let n=audio.tablaPosition.matra
        return n>0 ? "Matra \(n) / \(audio.tablaSettings.taal.matras)":"— / \(audio.tablaSettings.taal.matras)"
    }
    private func beatGrid(width:CGFloat) -> some View {
        let taal=audio.tablaSettings.taal
        let columns=width>550 ? min(8,taal.matras):min(4,taal.matras)
        return LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:6),count:columns),spacing:6) {
            ForEach(0..<taal.matras,id:\.self) { index in
                VStack(spacing:5) {
                    Text("\(index+1)\(index==0 ? " · Sam":(taal.khali.contains(index+1) ? " · ○":""))").font(.caption.bold())
                    Text(taal.labels[index]).font(.subheadline).minimumScaleFactor(0.7).lineLimit(1)
                }.frame(maxWidth:.infinity,minHeight:52)
                    .background(audio.tablaPosition.matra==index+1 ? Color.accentColor.opacity(0.23):Color.secondary.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius:8).stroke(taal.groupStarts.contains(index+1) ? Color.accentColor.opacity(0.65):Color.clear,lineWidth:1))
                    .clipShape(RoundedRectangle(cornerRadius:8))
                    .accessibilityIdentifier("tabla.beat.\(index+1)")
            }
        }
    }
}
