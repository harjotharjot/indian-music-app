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
    private var geometry: KeyboardGeometry {
        KeyboardGeometry(start: settings.startNote, span: settings.span, width: bounds.width, height: bounds.height)
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
        if self.settings.startNote != settings.startNote || self.settings.span != settings.span || self.epoch != epoch || !enabled {
            releaseAll()
        }
        self.settings = settings; self.sa = sa; self.epoch = epoch
        isUserInteractionEnabled = enabled
        alpha = enabled ? 1 : 0.5
        setNeedsDisplay()
    }
    func releaseAll() {
        guard !ledger.notes.isEmpty else { ledger.cancelAll(); return }
        ledger.cancelAll(); onChange?([]); setNeedsDisplay()
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { releaseAll(); return }
        var ancestor = superview
        while let view = ancestor {
            if let scroll = view as? UIScrollView {
                scroll.delaysContentTouches = false
                scroll.canCancelContentTouches = false
            }
            ancestor = view.superview
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if lastSize != bounds.size { releaseAll(); lastSize = bounds.size; setNeedsDisplay() }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { ledger.begin(ObjectIdentifier(touch), note: geometry.note(at: touch.location(in: self))) }
        changed()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { ledger.move(ObjectIdentifier(touch), note: geometry.note(at: touch.location(in: self))) }
        changed()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { ledger.end(ObjectIdentifier(touch)) }; changed()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { ledger.end(ObjectIdentifier(touch)) }; changed()
    }
    private func changed() { onChange?(ledger.notes); setNeedsDisplay() }
    override func draw(_ rect: CGRect) {
        let keys = geometry.keys
        for key in keys.filter({ !$0.black }) + keys.filter({ $0.black }) {
            let pressed = ledger.notes.contains(key.note)
            (pressed ? UIColor.systemBlue : key.black ? UIColor(white: 0.12, alpha: 1) : UIColor.white).setFill()
            let path = UIBezierPath(rect: key.frame.insetBy(dx: 0.5, dy: 0.5)); path.fill()
            UIColor.gray.setStroke(); path.lineWidth = 0.5; path.stroke()
            let western = ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"][key.note%12]
            let label = settings.showSargam ? HarmoniumSettings.sargam(note: key.note, sa: sa) : western
            let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
            let color: UIColor = pressed || key.black ? .white : .black
            let attrs: [NSAttributedString.Key: Any] = [.font:UIFont.systemFont(ofSize: settings.twoOctaves ? 10 : 13, weight: .medium),.foregroundColor:color,.paragraphStyle:paragraph]
            (label as NSString).draw(in: CGRect(x:key.frame.minX, y:key.frame.maxY-31, width:key.frame.width, height:24), withAttributes:attrs)
        }
    }
}
