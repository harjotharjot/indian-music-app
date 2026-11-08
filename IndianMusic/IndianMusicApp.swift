import SwiftUI

@main
struct IndianMusicApp: App {
    @StateObject private var audio = AudioCoordinator()

    var body: some Scene {
        WindowGroup {
            TabView {
                PracticeView().tabItem { Label("Harmonium", systemImage: "pianokeys") }
                ContentView().tabItem { Label("Tanpura", systemImage: "waveform") }
            }.environmentObject(audio)
        }
    }
}
