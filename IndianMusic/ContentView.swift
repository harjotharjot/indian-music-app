import SwiftUI

struct ContentView: View {
    @State private var tapCount = 0

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Indian Music")
                .font(.largeTitle.bold())
            Text("The app installed and opened successfully.")
                .multilineTextAlignment(.center)
            Text("Phase 1 · Version 0.1.0")
                .foregroundStyle(.secondary)
            Button("Test button: \(tapCount)") {
                tapCount += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }
}
