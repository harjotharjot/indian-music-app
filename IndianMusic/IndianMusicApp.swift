import SwiftUI
import UIKit
import CoreMotion
import Combine

@main
struct IndianMusicApp: App {
    @UIApplicationDelegateAdaptor(PracticeAppDelegate.self) private var delegate
    @StateObject private var fullscreen = PracticeFullscreenController.shared
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var audio = AudioCoordinator()
    @State private var activeInstrument = 0
    @State private var orientation = UIInterfaceOrientation.portrait
    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height {
                    HStack(spacing:0) {
                        if orientation == .landscapeLeft { switcher(vertical:true).zIndex(1); Divider() }
                        instrument
                        if orientation != .landscapeLeft { Divider(); switcher(vertical:true).zIndex(1) }
                    }
                } else {
                    VStack(spacing:0) {
                        instrument
                        Divider()
                        switcher(vertical:false)
                    }
                }
            }
            .ignoresSafeArea(.container, edges: orientation.isLandscape ? (activeInstrument == 0 ? .horizontal : (orientation == .landscapeLeft ? .leading : .trailing)) : [])
            .background(SceneOrientationReader(orientation:$orientation).frame(width:0,height:0))
            .environmentObject(audio)
            .environmentObject(fullscreen)
            .onChange(of:scenePhase) { phase in fullscreen.setForeground(phase == .active) }
            .onChange(of:fullscreen.actualOrientation) { value in
                if value != .unknown && value != orientation { orientation=value }
            }
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
                    if value == 1 { TanpuraGlyph().fill().frame(width:20,height:25).rotationEffect(.degrees(45)).frame(width:28,height:28) }
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
        private var orientationObserver: NSObjectProtocol?
        deinit {
            if let orientationObserver {
                NotificationCenter.default.removeObserver(orientationObserver)
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
        }
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if orientationObserver == nil {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                orientationObserver = NotificationCenter.default.addObserver(
                    forName:UIDevice.orientationDidChangeNotification, object:nil, queue:.main
                ) { [weak self] _ in
                    // A 180-degree landscape rotation has the same size/insets and
                    // need not cause layout callbacks. Read the window scene after
                    // its transition; raw device orientation is only the signal.
                    DispatchQueue.main.asyncAfter(deadline:.now()+0.5) { [weak self] in self?.report() }
                }
            }
            report()
        }
        override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); report() }
        override func viewWillTransition(to size: CGSize,with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to:size,with:coordinator)
            coordinator.animate(alongsideTransition:nil) { [weak self] _ in self?.report() }
        }
        func report() {
            PracticeFullscreenController.shared.connect(view.window?.windowScene)
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

@MainActor
final class PracticeAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        PracticeFullscreenController.shared.supportedOrientations
    }
}

@MainActor
final class PracticeFullscreenController: ObservableObject {
    static let shared=PracticeFullscreenController()
    @Published private(set) var isForced=false
    @Published private(set) var actualOrientation=UIInterfaceOrientation.unknown
    @Published private(set) var message: String?
    var supportedOrientations: UIInterfaceOrientationMask { isForced ? .landscape:.allButUpsideDown }
    private weak var scene: UIWindowScene?
    private var state=PracticeFullscreenState()
    private let motion=CMMotionManager()
    private var timer: Timer?
    private var foreground=true
    private var lastMotion: TimeInterval = 0
    private var requested: UIInterfaceOrientationMask = .landscapeRight
    private var requestSerial=0

    func connect(_ value: UIWindowScene?) {
        if let value {
            scene=value
            DispatchQueue.main.async { [weak self] in self?.syncOrientation() }
        }
    }
    private func syncOrientation() {
        if let value=scene?.interfaceOrientation,value != actualOrientation { actualOrientation=value }
    }
    func enter() {
        state.enter();isForced=true;message=nil
        requested = scene?.interfaceOrientation == .landscapeLeft ? .landscapeLeft:.landscapeRight
        rotate(to:requested);startObserving()
    }
    func exit() {
        state.exit();isForced=false;message=nil;stopObserving();rotate(to:.portrait)
        let serial=requestSerial
        DispatchQueue.main.asyncAfter(deadline:.now()+0.8) { [weak self] in
            guard let self,!self.isForced,self.requestSerial==serial else { return }
            self.restoreAutomaticRotation()
        }
    }
    func setForeground(_ active: Bool) {
        foreground=active
        if active && isForced {
            if scene?.interfaceOrientation.isLandscape != true { rotate(to:requested) }
            startObserving()
        } else { stopObserving() }
    }
    private func restoreAutomaticRotation() {
        guard !isForced, let windowScene=scene else { return }
        requestSerial+=1
        windowScene.windows.forEach { $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }
        // Clear the one-orientation scene preference used to leave full screen,
        // as well as restoring the app mask. Ordinary rotations remain automatic.
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations:.allButUpsideDown)) { error in
            print("Restore automatic rotation: \(error.localizedDescription)")
        }
        DispatchQueue.main.asyncAfter(deadline:.now()+0.5) { [weak self] in self?.syncOrientation() }
    }
    private func rotate(to mask: UIInterfaceOrientationMask) {
        guard let windowScene=scene ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where:{ $0.activationState == .foregroundActive }) else { return }
        scene=windowScene
        requestSerial+=1;let serial=requestSerial
        windowScene.windows.forEach { $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }
        // A locked-device half-turn need not deliver UIDevice/layout callbacks.
        DispatchQueue.main.asyncAfter(deadline:.now()+0.6) { [weak self] in self?.syncOrientation() }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations:mask)) { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self,self.requestSerial==serial else { return }
                print("Practice rotation request failed: \(error.localizedDescription)")
                self.state.exit();self.isForced=false;self.stopObserving()
                self.message="Full screen could not rotate. Tap to try again."
            }
        }
    }
    private func startObserving() {
        stopObserving();guard isForced && foreground else { return }
        state.resetObservation();lastMotion=0
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval=0.2
            motion.startDeviceMotionUpdates(using:.xArbitraryZVertical,to:.main) { [weak self] data,_ in
                guard let g=data?.gravity else { return }
                let pose=PracticePhysicalPose.gravity(x:g.x,y:g.y,z:g.z)
                Task { @MainActor [weak self] in
                    self?.lastMotion=ProcessInfo.processInfo.systemUptime
                    self?.observe(pose)
                }
            }
        }
        // Simulator/sensor-unavailable fallback. Gravity remains the real-device
        // source when portrait lock prevents UIDevice orientation notifications.
        let timer=Timer(timeInterval:0.2,repeats:true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,ProcessInfo.processInfo.systemUptime-self.lastMotion>1 else { return }
                if self.motion.isDeviceMotionAvailable && self.lastMotion==0 { return }
                let pose: PracticePhysicalPose
                switch UIDevice.current.orientation {
                case .portrait:pose = .portrait
                case .landscapeLeft:pose = .landscapeRight
                case .landscapeRight:pose = .landscapeLeft
                default:pose = .uncertain
                }
                self.observe(pose)
            }
        }
        self.timer=timer;RunLoop.main.add(timer,forMode:.common)
    }
    private func stopObserving() {
        if timer != nil { UIDevice.current.endGeneratingDeviceOrientationNotifications() }
        timer?.invalidate();timer=nil;motion.stopDeviceMotionUpdates()
    }
    private func observe(_ pose: PracticePhysicalPose) {
        guard isForced && foreground else { return }
        if state.observe(pose,time:ProcessInfo.processInfo.systemUptime) { exit();return }
        if let physical=state.confirmedLandscape {
            let side: UIInterfaceOrientationMask = physical == .landscapeLeft ? .landscapeLeft:.landscapeRight
            if side != requested { requested=side;rotate(to:side) }
        }
    }
}
