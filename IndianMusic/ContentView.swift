import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var audio: AudioCoordinator
    @State private var showCredits = false

    var body: some View {
        NavigationStack {
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
                    Text("Version 0.4.0 · Practice instruments")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Indian Music")
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
}
