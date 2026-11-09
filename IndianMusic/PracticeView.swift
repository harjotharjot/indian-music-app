import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var audio: AudioCoordinator
    @EnvironmentObject private var fullscreen: PracticeFullscreenController
    @State private var showControls = false
    @State private var navigating = false
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height { landscapeContent }
                else { portraitContent(size:geometry.size) }
            }
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
                            Picker("Sa", selection: $audio.settings.key) {
                                ForEach(0..<12,id: \.self) { Text(TanpuraSettings.noteNames[$0]).tag($0) }
                            }
                            Stepper(value: $audio.settings.cents, in: -100...100, step: 1) {
                                Text("Fine tuning: \(audio.settings.cents,specifier:"%+.0f") cents")
                            }
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
    private var landscapeContent: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Button(audio.harmoniumEnabled ? "Off" : "Enable") {
                    audio.harmoniumEnabled ? audio.disableHarmonium() : audio.enableHarmonium()
                }.buttonStyle(.borderedProminent).accessibilityIdentifier("harmonium.enable")
                Button(action:audio.releaseKeys) { Text("Release keys") }.buttonStyle(.bordered).accessibilityLabel("Release all keys")
                if fullscreen.isForced {
                    Button { audio.releaseKeys();fullscreen.exit() } label: {
                        Image(systemName:"arrow.down.right.and.arrow.up.left")
                    }.accessibilityLabel("Exit full screen").accessibilityIdentifier("harmonium.exitFullscreen")
                }
                Spacer(minLength:0)
                Button { audio.releaseKeys(); showControls=true } label: {
                    Image(systemName:"slider.horizontal.3")
                }.accessibilityLabel("Practice settings").accessibilityIdentifier("harmonium.settings")
            }.font(.subheadline)
            HStack {
                Text("Sa \(audio.settings.saName) · \(audio.settings.cents,specifier:"%+.0f") cents")
                Toggle("Sargam",isOn:$audio.harmonium.showSargam).toggleStyle(.button)
                Spacer()
                if let message=audio.message { Text(message).lineLimit(1).foregroundStyle(.secondary) }
                Button(action:audio.toggle) { Label("Tanpura",systemImage:audio.isPlaying ? "pause.fill":"play.fill") }
                Picker("Tanpura",selection:$audio.settings.pattern) {
                    ForEach(TanpuraPattern.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.segmented).frame(width:110)
            }.font(.caption)
            if let message=fullscreen.message { Text(message).font(.caption).foregroundStyle(.secondary) }
            navigationSlider
            HarmoniumKeyboard(settings:audio.harmonium,sa:audio.settings.key,
                              enabled:audio.harmoniumEnabled && !navigating,epoch:audio.keyboardEpoch,
                              onChange:audio.setHarmoniumKeys)
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .accessibilityIdentifier("harmonium.keyboard")

        }.padding(.leading,fullscreen.actualOrientation == .landscapeLeft ? 8:24)
         .padding(.trailing,fullscreen.actualOrientation == .landscapeLeft ? 24:8)
         .padding(.vertical,4)
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
                    Picker("Sa",selection:$audio.settings.key) {
                        ForEach(0..<12,id:\.self) { Text(TanpuraSettings.noteNames[$0]).tag($0) }
                    }
                    Stepper(value:$audio.settings.cents,in:-100...100,step:1) {
                        Text("Fine tuning: \(audio.settings.cents,specifier:"%+.0f") cents")
                    }
                }
                Section("Independent volumes") {
                    Text("Harmonium \(Int((audio.harmonium.volume*100).rounded()))%")
                    Slider(value:$audio.harmonium.volume,in:0...1)
                    Text("Tanpura \(Int((audio.settings.volume*100).rounded()))%")
                    Slider(value:$audio.settings.volume,in:0...1)
                }
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
