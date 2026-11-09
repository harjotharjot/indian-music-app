import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var audio: AudioCoordinator
    @EnvironmentObject private var fullscreen: PracticeFullscreenController
    @State private var showCredits = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height { landscapeContent }
                else { portraitContent }
            }
            .navigationTitle("Tanpura")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if fullscreen.isForced {
                    ToolbarItem(placement:.navigationBarTrailing) {
                        Button { audio.releaseKeys();fullscreen.exit() } label: {
                            Label("Exit full screen",systemImage:"arrow.down.right.and.arrow.up.left")
                        }.accessibilityIdentifier("tanpura.exitFullscreen")
                    }
                }
            }
            .sheet(isPresented: $showCredits) {
                NavigationStack {
                    List {
                        Text("Tanpura: C-scale recordings supplied by you for this private app. Original creator and redistribution license were not provided.")
                        Text("Adapted using excerpt selection, loop crossfades, level adjustment and playback transposition.")
                        Text("Harmonium: recordings by donyaquick at Euterpea Studio, Yale. CC0 1.0. Distributed WAVs from nbrosowsky/tonejs-instruments.")
                        Link("Harmonium source", destination: URL(string: "https://freesound.org/people/donyaquick/sounds/330410/")!)
                        Link("CC0 1.0", destination: URL(string: "https://creativecommons.org/publicdomain/zero/1.0/")!)
                        Text("Prepared with pitch calibration, trimmed leading silence and crossfaded sustain loops. Apple’s native sampler handles playback.")
                    }
                    .navigationTitle("Sound credits")
                    .toolbar { Button("Done") { showCredits = false } }
                }
            }
        }
    }
    private var portraitContent: some View {
            Form {
                Section {
                    Button(action: audio.toggle) {
                        Label(audio.isPlaying ? "Pause tanpura" : "Play tanpura",
                              systemImage: audio.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .accessibilityIdentifier("tanpura.playPause")
                    Picker("Tuning", selection: $audio.settings.pattern) {
                        ForEach(TanpuraPattern.allCases) { pattern in
                            Text(pattern.title).tag(pattern)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(audio.settings.pattern.description)
                        .foregroundStyle(.secondary)
                    if let message = audio.message {
                        Text(message).foregroundStyle(.secondary).accessibilityIdentifier("audio.status")
                    }
                } header: {
                    Text("Acoustic tanpura")
                } footer: {
                    Text("Playback continues when the screen locks.")
                }

                Section("Sa") {
                    Picker("Key", selection: $audio.settings.key) {
                        ForEach(0..<12, id: \.self) { key in
                            Text(TanpuraSettings.noteNames[key]).tag(key)
                        }
                    }
                    Picker("Octave", selection: $audio.settings.octave) {
                        Text("Lower · 2").tag(2)
                        Text("Higher · 3").tag(3)
                    }
                    Text("\(audio.settings.frequency, specifier: "%.2f") Hz")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Stepper(value: $audio.settings.cents, in: -100...100, step: 1) {
                        Text("Fine tuning: \(audio.settings.cents, specifier: "%+.0f") cents")
                            .monospacedDigit()
                    }
                    Slider(value: $audio.settings.cents, in: -100...100, step: 1)
                        .accessibilityLabel("Fine tuning in cents")
                    Button("Reset fine tuning") { audio.settings.cents = 0 }
                }

                Section("Playback") {
                    LabeledContent("Speed", value: String(format: "%.2f×", audio.settings.speed))
                    Slider(value: $audio.settings.speed, in: 0.75...1.25, step: 0.01)
                        .accessibilityLabel("Tanpura speed")
                    LabeledContent("Volume", value: "\(Int((audio.settings.volume * 100).rounded()))%")
                    Slider(value: $audio.settings.volume, in: 0...1, step: 0.01)
                        .accessibilityLabel("Tanpura volume")
                }
                Section {
                    Button("Sound credits") { showCredits = true }
                    Text("Version 0.4.3 · Practice instruments")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
    }
    private var landscapeContent: some View {
        HStack(spacing:24) {
            VStack(spacing:10) {
                Button(action:audio.toggle) {
                    Label(audio.isPlaying ? "Pause tanpura" : "Play tanpura",
                          systemImage:audio.isPlaying ? "pause.circle.fill":"play.circle.fill")
                        .font(.title3.bold()).frame(maxWidth:.infinity,minHeight:34)
                }.buttonStyle(.borderedProminent).accessibilityIdentifier("tanpura.playPause")
                Picker("Tuning",selection:$audio.settings.pattern) {
                    ForEach(TanpuraPattern.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.segmented)
                Text(audio.settings.pattern.description).font(.caption).foregroundStyle(.secondary)
                HStack {
                    Text("Volume").frame(width:65,alignment:.leading)
                    Slider(value:$audio.settings.volume,in:0...1,step:0.01)
                }
                HStack {
                    Text("\(audio.settings.speed,specifier:"%.2f")×").monospacedDigit().frame(width:65,alignment:.leading)
                    Slider(value:$audio.settings.speed,in:0.75...1.25,step:0.01).accessibilityLabel("Tanpura speed")
                }
            }
            Divider()
            VStack(spacing:10) {
                HStack {
                    Picker("Sa",selection:$audio.settings.key) {
                        ForEach(0..<12,id:\.self) { Text(TanpuraSettings.noteNames[$0]).tag($0) }
                    }
                    Picker("Octave",selection:$audio.settings.octave) {
                        Text("2").tag(2); Text("3").tag(3)
                    }
                }
                Text("\(audio.settings.frequency,specifier:"%.2f") Hz").monospacedDigit()
                Stepper(value:$audio.settings.cents,in:-100...100,step:1) {
                    Text("\(audio.settings.cents,specifier:"%+.0f") cents").monospacedDigit()
                }
                Slider(value:$audio.settings.cents,in:-100...100,step:1).accessibilityLabel("Fine tuning in cents")
                HStack {
                    Button("Reset tuning") { audio.settings.cents=0 }
                    Spacer()
                    Button("Sound credits") { showCredits=true }
                }
                if let message=audio.message { Text(message).font(.caption).foregroundStyle(.secondary) }
                Text("Playback continues with the screen locked.").font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.horizontal,20).padding(.vertical,4)
    }

}
