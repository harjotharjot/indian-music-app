import SwiftUI
import UIKit

@main
struct IndianMusicApp: App {
    @StateObject private var audio = AudioCoordinator()
    @State private var activeInstrument = 0
    @State private var orientation = UIInterfaceOrientation.portrait
    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height {
                    HStack(spacing:0) {
                        if orientation == .landscapeLeft { switcher(vertical:true); Divider() }
                        instrument
                        if orientation != .landscapeLeft { Divider(); switcher(vertical:true) }
                    }
                } else {
                    VStack(spacing:0) {
                        instrument
                        Divider()
                        switcher(vertical:false)
                    }
                }
            }
            .background(SceneOrientationReader(orientation:$orientation).frame(width:0,height:0))
            .environmentObject(audio)
            .onChange(of:activeInstrument) { _ in audio.releaseKeys() }
        }
    }
    @ViewBuilder private var instrument: some View {
        if activeInstrument == 0 { PracticeView() }
        else { ContentView() }
    }
    private func switcher(vertical: Bool) -> some View {
        Group {
            if vertical {
                VStack(spacing:16) {
                    switchButton(0,title:"Harmonium",symbol:"pianokeys")
                    switchButton(1,title:"Tanpura",symbol:"waveform")
                }.frame(width:82).frame(maxHeight:.infinity)
            } else {
                HStack(spacing:16) {
                    switchButton(0,title:"Harmonium",symbol:"pianokeys")
                    switchButton(1,title:"Tanpura",symbol:"waveform")
                }.frame(height:52).padding(.horizontal,16)
            }
        }.background(.bar)
    }
    private func switchButton(_ value: Int,title: String,symbol: String) -> some View {
        Button { activeInstrument=value } label: {
            VStack(spacing:3) {
                Image(systemName:symbol).font(.title3)
                Text(title).font(.caption2)
            }
            .frame(maxWidth:.infinity,minHeight:46)
            .foregroundStyle(activeInstrument == value ? Color.accentColor : Color.secondary)
            .background(activeInstrument == value ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius:8))
        }
        .accessibilityIdentifier(value == 0 ? "switch.harmonium" : "switch.tanpura")
        .accessibilityValue(activeInstrument == value ? "Selected" : "")
    }
}

// Interface orientation (not raw device orientation) identifies the physical port edge.
// UIKit landscapeLeft places the Home/charging-port side on the left; landscapeRight on the right.
private struct SceneOrientationReader: UIViewControllerRepresentable {
    @Binding var orientation: UIInterfaceOrientation
    func makeUIViewController(context: Context) -> ReaderController { ReaderController() }
    func updateUIViewController(_ controller: ReaderController,context: Context) {
        controller.changed = { value in if orientation != value { orientation=value } }
        controller.report()
    }
    final class ReaderController: UIViewController {
        var changed: ((UIInterfaceOrientation)->Void)?
        private var last: UIInterfaceOrientation?
        override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); report() }
        override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); report() }
        override func viewWillTransition(to size: CGSize,with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to:size,with:coordinator)
            coordinator.animate(alongsideTransition:nil) { [weak self] _ in self?.report() }
        }
        func report() {
            guard let value=view.window?.windowScene?.interfaceOrientation,value != .unknown,value != last else { return }
            last=value
            DispatchQueue.main.async { [weak self] in self?.changed?(value) }
        }
    }
}
