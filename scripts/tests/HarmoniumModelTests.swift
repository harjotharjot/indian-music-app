import Foundation
import CoreGraphics

@main
struct HarmoniumModelTests {
    static func main() throws {
        var ledger = TouchNoteLedger<Int>()
        ledger.begin(1,note:60);ledger.begin(2,note:64);ledger.begin(3,note:67)
        precondition(ledger.notes == [60,64,67])
        ledger.move(2,note:60);ledger.end(1)
        precondition(ledger.notes == [60,67], "One lifted finger must not release the other finger's key")
        ledger.move(2,note:nil);precondition(ledger.notes == [67])
        ledger.move(2,note:62);precondition(ledger.notes == [62,67])
        ledger.cancelAll();ledger.move(2,note:60);precondition(ledger.notes.isEmpty)
        for sa in 0..<12 { precondition(HarmoniumSettings.sargam(note:60+sa,sa:sa)=="Sa") }
        let geometry=KeyboardGeometry(start:60,span:12,width:400,height:200)
        precondition(geometry.keys.count==13)
        precondition(geometry.note(at:CGPoint(x:50,y:30))==61) // Black-key priority.
        precondition(geometry.note(at:CGPoint(x:50,y:180))==62)
        precondition(geometry.note(at:CGPoint(x:-1,y:30))==nil)
        for position in stride(from:0.0,through:1.0,by:0.01) {
            let g=KeyboardGeometry(position:position,width:740,height:240)
            for x in stride(from:CGFloat(0),to:740,by:2) {
                if let note=g.note(at:CGPoint(x:x,y:40)) { precondition([1,3,6,8,10].contains(note%12)) }
                if let note=g.note(at:CGPoint(x:x,y:180)) { precondition(![1,3,6,8,10].contains(note%12)) }
            }
            precondition(g.note(at:CGPoint(x:-1,y:100)) == nil)
        }
        let left=KeyboardGeometry(position:0,width:740,height:240)
        let right=KeyboardGeometry(position:1,width:740,height:240)
        precondition(left.keys.first!.frame.minX == 0)
        precondition(abs(right.keys.last!.frame.maxX-740)<0.001)
        let legacy=Data(#"{"volume":0.6,"octave":3,"twoOctaves":false,"showSargam":true}"#.utf8)
        let migrated = try JSONDecoder().decode(HarmoniumSettings.self,from:legacy)
        precondition(migrated.navigation == 0.5)
        var settings=HarmoniumSettings();settings.octave=4;settings.twoOctaves=true
        precondition(settings.validated().octave==3)
        let decoded = try JSONDecoder().decode(HarmoniumSettings.self,from:JSONEncoder().encode(settings))
        precondition(decoded==settings)
        print("PASS: chord ledger, duplicate fingers, slides, cancellation, all 12 Sa labels, geometry, octave clamping and persistence")
    }
}
