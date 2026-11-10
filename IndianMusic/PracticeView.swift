import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var audio: AudioCoordinator
    @EnvironmentObject private var fullscreen: PracticeFullscreenController
    @State private var showControls = false
    @State private var navigating = false
    @State private var miniPanel: MiniPanel?
    private enum MiniPanel { case tanpura, tabla }
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height { landscapeContent(size:geometry.size) }
                else { portraitContent(size:geometry.size) }
            }
            .ignoresSafeArea(.container,edges:fullscreen.actualOrientation.isLandscape
                ? (fullscreen.actualOrientation == .landscapeLeft ? .trailing:.leading):[])
            .navigationTitle("Harmonium")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear { audio.releaseKeys() }
            .sheet(isPresented: $showControls) { controlsSheet }
        }
    }
    private func portraitContent(size: CGSize) -> some View {
        VStack(spacing:6) {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button(audio.harmoniumEnabled ? "Turn keyboard off" : "Enable harmonium") {
                            audio.harmoniumEnabled ? audio.disableHarmonium() : audio.enableHarmonium()
                        }.buttonStyle(.borderedProminent).accessibilityIdentifier("harmonium.enable")
                        Button("Release keys", action: audio.releaseKeys).buttonStyle(.bordered)
                    }
                    if let message = audio.message { Text(message).font(.footnote).foregroundStyle(.secondary) }
                    if let message=fullscreen.message { Text(message).font(.caption).foregroundStyle(.secondary) }
                    Toggle("Sargam labels", isOn: $audio.harmonium.showSargam)
                    Text("Sa follows the selected key. Lowercase notes are komal; Mā is tivra Ma.")
                        .font(.caption).foregroundStyle(.secondary)
                    GroupBox("Shared tuning") {
                        VStack {
                            SharedTuningControls()
                            Text("Keys retain their piano pitches; Sa changes labels and the drone. Fine tuning adjusts both instruments.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    GroupBox("Mixer") {
                        VStack {
                            Text("Harmonium \(Int((audio.harmonium.volume*100).rounded()))%")
                            Slider(value: $audio.harmonium.volume,in: 0...1).accessibilityLabel("Harmonium volume")
                            HStack {
                                Text("Tanpura \(Int((audio.settings.volume*100).rounded()))%")
                                Spacer()
                                Button(audio.isPlaying ? "Pause" : "Play", action: audio.toggle)
                            }
                            Slider(value: $audio.settings.volume,in: 0...1).accessibilityLabel("Tanpura volume")
                            Picker("Tanpura",selection: $audio.settings.pattern) {
                                ForEach(TanpuraPattern.allCases) { Text($0.title).tag($0) }
                            }.pickerStyle(.segmented)
                        }
                    }
                    GroupBox("Tabla") {
                        VStack {
                            Button(audio.tablaState == .playing ? "Pause tabla":"Play tabla") {
                                audio.tablaState == .playing ? audio.pauseTabla():audio.startTabla()
                            }
                            TablaSettingsControls()
                        }
                    }
                    GroupBox("Tanpura speed") {
                        VStack {
                            Text("\(audio.settings.speed,specifier:"%.2f")×")
                            Slider(value:$audio.settings.speed,in:0.75...1.25,step:0.01)
                                .accessibilityLabel("Tanpura speed").accessibilityIdentifier("harmonium.speed")
                        }
                    }
                }.padding()
            }
            .frame(maxHeight:.infinity)
            .accessibilityIdentifier("harmonium.settingsScroll")
            navigationSlider.padding(.horizontal,16)
            HarmoniumKeyboard(settings:audio.harmonium,sa:audio.settings.key,
                              enabled:audio.harmoniumEnabled && !navigating,epoch:audio.keyboardEpoch,
                              onChange:audio.setHarmoniumKeys)
                .frame(height:min(220,(size.width-32)/8*4.05))
                .padding(.horizontal,16)
                .accessibilityIdentifier("harmonium.keyboard")
        }.padding(.bottom,4)
            .toolbar {
                ToolbarItem(placement:.navigationBarTrailing) {
                    Button { audio.releaseKeys();showControls=true } label: {
                        Image(systemName:"slider.horizontal.3")
                    }.accessibilityLabel("Practice settings").accessibilityIdentifier("harmonium.settings")
                }
                ToolbarItem(placement:.navigationBarTrailing) {
                    Button { audio.releaseKeys();fullscreen.enter() } label: {
                        Label("Full screen",systemImage:"arrow.up.left.and.arrow.down.right")
                    }.accessibilityIdentifier("harmonium.fullscreen")
                }
            }
    }
    private func landscapeContent(size:CGSize) -> some View {
        VStack(spacing: 6) {
            HStack(alignment:.top, spacing:12) {
                HStack(spacing:6) {
                    Button(audio.harmoniumEnabled ? "Off" : "Enable") {
                        audio.harmoniumEnabled ? audio.disableHarmonium() : audio.enableHarmonium()
                    }.buttonStyle(.borderedProminent).accessibilityIdentifier("harmonium.enable")
                    Button("Release keys",action:audio.releaseKeys)
                        .buttonStyle(.bordered).accessibilityLabel("Release all keys")
                    Toggle("Sargam",isOn:$audio.harmonium.showSargam).toggleStyle(.button)
                }.frame(maxWidth:.infinity,alignment:.leading).padding(.top,24)
                VStack(spacing:6) {
                    summaryButton("\(audio.settings.saName) · \(Int(audio.settings.cents)) cents",
                                  panel:.tanpura,identifier:"harmonium.tuningSummary")
                    HStack(spacing:6) {
                        Button(action:audio.toggle) {
                            Label("Tanpura",systemImage:audio.isPlaying ? "pause.fill":"play.fill")
                        }.accessibilityIdentifier("harmonium.tanpuraPlayPause")
                            .accessibilityValue(audio.isPlaying ? "Playing":"Paused")
                        Picker("Tanpura",selection:$audio.settings.pattern) {
                            ForEach(TanpuraPattern.allCases) { Text($0.title).tag($0) }
                        }.pickerStyle(.segmented).frame(width:120)
                    }
                }.frame(maxWidth:.infinity)
                VStack(spacing:6) {
                    summaryButton("\(audio.tablaSettings.taal.title) · \(Int(audio.tablaSettings.bpm)) BPM",
                                  panel:.tabla,identifier:"harmonium.tablaSummary")
                    Button {
                        audio.tablaState == .playing ? audio.pauseTabla():audio.startTabla()
                    } label: {
                        Label("Tabla",systemImage:audio.tablaState == .playing ? "pause.fill":"play.fill")
                            .frame(height:32)
                    }.accessibilityIdentifier("harmonium.tablaPlayPause")
                        .accessibilityValue(audio.tablaState.rawValue.capitalized)
                }.frame(width:size.width<750 ? 145:170)
            }.font(.caption)
            if let message=fullscreen.message { Text(message).font(.caption).foregroundStyle(.secondary) }
            navigationSlider
            HarmoniumKeyboard(settings:audio.harmonium,sa:audio.settings.key,
                              enabled:audio.harmoniumEnabled && !navigating,epoch:audio.keyboardEpoch,
                              onChange:audio.setHarmoniumKeys)
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .accessibilityIdentifier("harmonium.keyboard")

        }
        .overlay(alignment:miniPanel == .tabla ? .topTrailing:.top) {
            if let panel=miniPanel {
                miniSettings(panel,height:min(180,max(70,size.height-150))).padding(.top,78)
            }
        }
        .toolbar {
            ToolbarItem(placement:.navigationBarTrailing) {
                Button { showControls=true;miniPanel=nil } label: { Image(systemName:"slider.horizontal.3") }
                    .accessibilityLabel("Practice settings").accessibilityIdentifier("harmonium.settings")
            }
            if fullscreen.isForced {
                ToolbarItem(placement:.navigationBarTrailing) {
                    Button { audio.releaseKeys();fullscreen.exit() } label: {
                        Image(systemName:"arrow.down.right.and.arrow.up.left")
                    }.accessibilityLabel("Exit full screen").accessibilityIdentifier("harmonium.exitFullscreen")
                }
            }
        }
        .padding(.leading,fullscreen.actualOrientation == .landscapeLeft ? 8:24)
         .padding(.trailing,fullscreen.actualOrientation == .landscapeLeft ? 24:8)
         .padding(.vertical,4)
    }
    private func summaryButton(_ title:String,panel:MiniPanel,identifier:String) -> some View {
        Button { miniPanel = miniPanel == panel ? nil:panel } label: {
            HStack(spacing:5) {
                Text(title).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength:0)
                Image(systemName:"chevron.down").font(.caption2)
            }.frame(maxWidth:.infinity,minHeight:28)
        }.buttonStyle(.bordered).accessibilityIdentifier(identifier)
    }
    private func miniSettings(_ panel:MiniPanel,height:CGFloat) -> some View {
        VStack(spacing:8) {
            HStack {
                Text(panel == .tanpura ? "Tanpura · Shared tuning":"Tabla").font(.headline)
                Spacer()
                Button { miniPanel=nil } label: { Image(systemName:"xmark.circle.fill") }
                    .accessibilityLabel("Close mini settings").accessibilityIdentifier("harmonium.miniClose")
            }
            ScrollView {
                VStack(spacing:8) {
                    if panel == .tanpura {
                        SharedTuningControls()
                        HStack {
                            Text("Speed \(audio.settings.speed,specifier:"%.2f")×").monospacedDigit()
                            Slider(value:$audio.settings.speed,in:0.75...1.25,step:0.01)
                                .accessibilityLabel("Tanpura speed")
                        }
                        HStack {
                            Text("Volume")
                            Slider(value:$audio.settings.volume,in:0...1).accessibilityLabel("Tanpura volume")
                        }
                    } else { TablaSettingsControls() }
                }
            }.frame(height:height)
        }.font(.caption).padding(12).frame(width:300)
            .background(.regularMaterial,in:RoundedRectangle(cornerRadius:12))
            .overlay(RoundedRectangle(cornerRadius:12).stroke(.secondary.opacity(0.3)))
            .shadow(radius:6).accessibilityIdentifier("harmonium.miniSettings")
    }
    private var navigationSlider: some View {
        Slider(value: Binding(get: { audio.harmonium.navigation },
                              set: { audio.harmonium.navigationPosition = $0 }), in: 0...1,
               onEditingChanged: { editing in navigating = editing; audio.releaseKeys() })
            .accessibilityLabel("Keyboard range")
            .accessibilityIdentifier("harmonium.navigation")
            .accessibilityValue("\(Int(audio.harmonium.navigation * 100)) percent")
            .frame(height: 30)
    }
    private var controlsSheet: some View {
        NavigationStack {
            Form {
                Section("Shared tuning") {
                    SharedTuningControls(identifierPrefix:"harmonium.sheet")
                }
                Section("Independent volumes") {
                    Text("Harmonium \(Int((audio.harmonium.volume*100).rounded()))%")
                    Slider(value:$audio.harmonium.volume,in:0...1)
                    Text("Tanpura \(Int((audio.settings.volume*100).rounded()))%")
                    Slider(value:$audio.settings.volume,in:0...1)
                }
                Section("Tabla") { TablaSettingsControls() }
                Section("Tanpura speed") {
                    Text("\(audio.settings.speed,specifier:"%.2f")×")
                    Slider(value:$audio.settings.speed,in:0.75...1.25,step:0.01)
                        .accessibilityLabel("Tanpura speed").accessibilityIdentifier("harmonium.speed.sheet")
                }
            }.navigationTitle("Practice controls")
                .toolbar { Button("Done") { showControls=false } }
        }
    }
}
