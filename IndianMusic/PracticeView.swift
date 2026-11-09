import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var audio: AudioCoordinator
    @State private var showControls = false
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height { landscapeContent }
                else { portraitContent }
            }
            .navigationTitle("Harmonium")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear { audio.releaseKeys() }
            .sheet(isPresented: $showControls) { controlsSheet }
        }
    }
    private var portraitContent: some View {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button(audio.harmoniumEnabled ? "Turn keyboard off" : "Enable harmonium") {
                            audio.harmoniumEnabled ? audio.disableHarmonium() : audio.enableHarmonium()
                        }.buttonStyle(.borderedProminent)
                        Button("Release all keys", action: audio.releaseKeys).buttonStyle(.bordered)
                    }
                    if let message = audio.message { Text(message).font(.footnote).foregroundStyle(.secondary) }
                    navigationSlider
                    HarmoniumKeyboard(settings: audio.harmonium, sa: audio.settings.key,
                                      enabled: audio.harmoniumEnabled, epoch: audio.keyboardEpoch,
                                      onChange: audio.setHarmoniumKeys)
                        .frame(height: 220)
                        .accessibilityIdentifier("harmonium.keyboard")
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
                }.padding()
            }
    }
    private var landscapeContent: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Button(audio.harmoniumEnabled ? "Off" : "Enable") {
                    audio.harmoniumEnabled ? audio.disableHarmonium() : audio.enableHarmonium()
                }.buttonStyle(.borderedProminent)
                Button(action:audio.releaseKeys) { Text("Release keys") }.buttonStyle(.bordered).accessibilityLabel("Release all keys")
                Spacer(minLength:0)
                Button { audio.releaseKeys(); showControls=true } label: {
                    Image(systemName:"slider.horizontal.3")
                }
            }.font(.subheadline)
            navigationSlider
            HarmoniumKeyboard(settings:audio.harmonium,sa:audio.settings.key,
                              enabled:audio.harmoniumEnabled,epoch:audio.keyboardEpoch,
                              onChange:audio.setHarmoniumKeys)
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .accessibilityIdentifier("harmonium.keyboard")
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
        }.padding(.horizontal,12).padding(.vertical,4)
    }
    private var navigationSlider: some View {
        Slider(value: Binding(get: { audio.harmonium.navigation },
                              set: { audio.harmonium.navigationPosition = $0 }), in: 0...1,
               onEditingChanged: { editing in if editing { audio.releaseKeys() } })
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
                }
            }.navigationTitle("Practice controls")
                .toolbar { Button("Done") { showControls=false } }
        }
    }
}
