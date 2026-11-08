import SwiftUI

@main
struct IndianMusicApp: App {
    @StateObject private var audio = AudioCoordinator()
    @State private var activeInstrument = 0
    var body: some Scene {
        WindowGroup {
            VStack(spacing:0) {
                Picker("Instrument",selection:$activeInstrument) {
                    Text("Harmonium").tag(0)
                    Text("Tanpura").tag(1)
                }.pickerStyle(.segmented).padding(.horizontal,16).padding(.vertical,6)
                Divider()
                if activeInstrument == 0 { PracticeView() }
                else { ContentView() }
            }.environmentObject(audio)
                .onChange(of:activeInstrument) { _ in audio.releaseKeys() }
        }
    }
}
