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
                    Text("Version 0.3.0 · Tanpura prototype")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Indian Music")
            .sheet(isPresented: $showCredits) {
                NavigationStack {
                    List {
                        Text("Acoustic tanpura recordings by Sankalp Gulati (sankalp). Licensed under Creative Commons Attribution 4.0.")
                        Link("Pa recording · Acoustic Tanpura 4", destination: URL(string: "https://freesound.org/people/sankalp/sounds/153263/")!)
                        Link("Ma recording · Acoustic Tanpura 5", destination: URL(string: "https://freesound.org/people/sankalp/sounds/153265/")!)
                        Link("CC BY 4.0 license", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
                        Text("Adapted from MP3 previews: selected excerpts, crossfaded loop joins, level adjustment and playback transposition. Speech at the end of the original Pa preview is excluded.")
                    }
                    .navigationTitle("Sound credits")
                    .toolbar { Button("Done") { showCredits = false } }
                }
            }
        }
    }
}
