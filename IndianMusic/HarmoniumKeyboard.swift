import SwiftUI
import UIKit

struct HarmoniumKeyboard: UIViewRepresentable {
    let settings: HarmoniumSettings
    let sa: Int
    let enabled: Bool
    let epoch: Int
    let onChange: (Set<Int>) -> Void
    func makeUIView(context: Context) -> KeybedView { KeybedView() }
    func updateUIView(_ view: KeybedView, context: Context) {
        view.onChange = onChange
        view.configure(settings: settings, sa: sa, enabled: enabled, epoch: epoch)
    }
    static func dismantleUIView(_ view: KeybedView, coordinator: ()) { view.releaseAll() }
}

final class KeybedView: UIControl {
    var onChange: ((Set<Int>) -> Void)?
    private var settings = HarmoniumSettings()
    private var sa = 0
    private var epoch = -1
    private var lastSize = CGSize.zero
    private var ledger = TouchNoteLedger<ObjectIdentifier>()
    private var slideFilter = SlideIntentFilter<ObjectIdentifier>()
    private var slideTimer: Timer?
    private var activeFingerIDs: Set<ObjectIdentifier> = []
    private var geometry: KeyboardGeometry {
        KeyboardGeometry(position: settings.navigation, width: bounds.width, height: bounds.height)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        isExclusiveTouch = false
        backgroundColor = .secondarySystemBackground
        accessibilityLabel = "Harmonium keyboard"
        accessibilityHint = "Direct touch. Multiple fingers play chords. Lift all fingers to release notes."
        accessibilityTraits = [.allowsDirectInteraction]
        isAccessibilityElement = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }
    func configure(settings: HarmoniumSettings, sa: Int, enabled: Bool, epoch: Int) {
        if self.settings.navigation != settings.navigation || self.settings.startNote != settings.startNote || self.settings.span != settings.span || self.epoch != epoch || !enabled {
            releaseAll()
        }
        self.settings = settings; self.sa = sa; self.epoch = epoch
        isUserInteractionEnabled = enabled
        alpha = enabled ? 1 : 0.5
        setNeedsDisplay()
    }
    func releaseAll() {
        slideTimer?.invalidate(); slideTimer=nil; slideFilter.cancelAll(); activeFingerIDs.removeAll()
        guard !ledger.notes.isEmpty else { ledger.cancelAll(); return }
        ledger.cancelAll(); onChange?([]); setNeedsDisplay()
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { releaseAll(); return }

    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if lastSize != bounds.size { releaseAll(); lastSize = bounds.size; setNeedsDisplay() }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let id=ObjectIdentifier(touch), point=touch.location(in:self)
            let note=geometry.note(at:point)
            activeFingerIDs.insert(id)
            slideFilter.begin(id,note:note,point:point,time:touch.timestamp)
            ledger.begin(id,note:note)
        }
        changed()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let id=ObjectIdentifier(touch)
            // Coalesced samples preserve the actual path/velocity of fast slides.
            for sample in event?.coalescedTouches(for:touch) ?? [touch] {
                let point=sample.location(in:self)
                slideFilter.move(id,note:geometry.note(at:point),point:point,time:sample.timestamp)
            }
        }
        updateSlides()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }
    private func finish(_ touches: Set<UITouch>) {
        for touch in touches {
            let id=ObjectIdentifier(touch); slideFilter.end(id); ledger.end(id); activeFingerIDs.remove(id)
        }
        updateSlides()
    }
    private func updateSlides() {
        let now=ProcessInfo.processInfo.systemUptime
        slideFilter.advance(to:now)
        for (id,note) in slideFilter.accepted { ledger.move(id,note:note) }
        // Fingers outside the keyboard must release immediately, while remaining
        // tracked for a deliberate re-entry (as before).
        for id in Array(activeFingerIDs) where slideFilter.accepted[id] == nil { ledger.move(id,note:nil) }
        slideTimer?.invalidate(); slideTimer=nil
        if let deadline=slideFilter.nextDeadline {
            let timer=Timer(timeInterval:max(0.001,deadline-now),repeats:false) { [weak self] _ in
                Task { @MainActor [weak self] in self?.updateSlides() }
            }
            slideTimer=timer;RunLoop.main.add(timer,forMode:.common)
        }
        changed()
    }
    private func changed() { onChange?(ledger.notes); setNeedsDisplay() }
    override func draw(_ rect: CGRect) {
        let keys = geometry.keys
        for key in keys.filter({ !$0.black }) + keys.filter({ $0.black }) {
            let pressed = ledger.notes.contains(key.note)
            (pressed ? UIColor.systemBlue : key.black ? UIColor(white: 0.12, alpha: 1) : UIColor.white).setFill()
            let face=key.frame.insetBy(dx:0.5,dy:0.5)
            let radius=face.width*0.48
            let path=key.black ? UIBezierPath(roundedRect:face,
                byRoundingCorners:[.bottomLeft,.bottomRight],cornerRadii:CGSize(width:radius,height:radius))
                : UIBezierPath(rect:face)
            path.fill()
            UIColor.gray.setStroke(); path.lineWidth = 0.5; path.stroke()
            let western = ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"][key.note%12]
            let label = settings.showSargam ? HarmoniumSettings.sargam(note: key.note, sa: sa) : western
            let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
            let color: UIColor = pressed || key.black ? .white : .black
            let attrs: [NSAttributedString.Key: Any] = [.font:UIFont.systemFont(ofSize: 11, weight: .medium),.foregroundColor:color,.paragraphStyle:paragraph]
            (label as NSString).draw(in: CGRect(x:key.frame.minX, y:key.frame.maxY-31, width:key.frame.width, height:24), withAttributes:attrs)
        }
    }
}
