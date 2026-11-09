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
                VStack(spacing:4) {
                    if orientation == .landscapeRight {
                        switchButton(1,title:"Tanpura",symbol:"tanpura",vertical:true)
                        switchButton(0,title:"Harmonium",symbol:"pianokeys",vertical:true)
                    } else {
                        switchButton(0,title:"Harmonium",symbol:"pianokeys",vertical:true)
                        switchButton(1,title:"Tanpura",symbol:"tanpura",vertical:true)
                    }
                }.frame(width:50).frame(maxHeight:.infinity)
            } else {
                HStack(spacing:16) {
                    switchButton(0,title:"Harmonium",symbol:"pianokeys")
                    switchButton(1,title:"Tanpura",symbol:"tanpura")
                }.frame(height:52).padding(.horizontal,16)
            }
        }.background(.bar)
    }
    private func switchButton(_ value: Int,title: String,symbol: String, vertical: Bool = false) -> some View {
        Button { activeInstrument=value } label: {
            VStack(spacing:3) {
                Group {
                    if value == 1 { TanpuraGlyph().fill().frame(width:20,height:25) }
                    else { Image(systemName:symbol).font(.title3) }
                }
                if !vertical { Text(title).font(.caption2) }
            }
            .frame(maxWidth:.infinity,minHeight:46)
            .foregroundStyle(activeInstrument == value ? Color.accentColor : Color.secondary)
            .background(activeInstrument == value ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius:8))
        }
        .accessibilityLabel(title)
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

// A monochrome Shape inherits exactly the same foreground selection style as SF Symbols.
private struct TanpuraGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p=Path()
        func box(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat) {
            p.addRoundedRect(in:CGRect(x:rect.minX+x*rect.width,y:rect.minY+y*rect.height,
                width:w*rect.width,height:h*rect.height),cornerSize:CGSize(width:2,height:2))
        }
        box(0.39,0.02,0.22,0.72)
        box(0.23,0.12,0.54,0.06); box(0.23,0.24,0.54,0.06)
        p.addEllipse(in:CGRect(x:rect.minX+rect.width*0.16,y:rect.minY+rect.height*0.60,
            width:rect.width*0.68,height:rect.height*0.39))
        return p
    }
}
