import SwiftUI

@main
struct IndianMusicApp: App {
    @StateObject private var audio = AudioCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audio)
        }
    }
}
