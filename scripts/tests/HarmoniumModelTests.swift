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
        for width in [CGFloat(350),740,812] {
            for height in [CGFloat(220),260] {
                for position in [0.0,0.123,0.5,0.997,1] {
                    let g=KeyboardGeometry(position:position,width:width,height:height)
                    let blacks=g.keys.filter { $0.black }
                    let split=blacks.first!.frame.maxY
                    for x in stride(from:CGFloat(0.01),to:width,by:0.5) {
                        for y in [CGFloat(0),split/2,split-0.01] {
                            let note=g.note(at:CGPoint(x:x,y:y))
                            precondition(note != nil && [1,3,6,8,10].contains(note!%12),"Entire upper region is black")
                        }
                        let below=g.note(at:CGPoint(x:x,y:split))
                        precondition(below != nil && ![1,3,6,8,10].contains(below!%12),"Lower region begins at black-key tips")
                    }
                    for index in 0..<(blacks.count-1) {
                        let midpoint=(blacks[index].frame.midX+blacks[index+1].frame.midX)/2
                        guard midpoint>0.01 && midpoint<width-0.01 else { continue }
                        precondition(g.note(at:CGPoint(x:midpoint-0.001,y:split/2))==blacks[index].note)
                        precondition(g.note(at:CGPoint(x:midpoint,y:split/2))==blacks[index+1].note,"Neighbor begins exactly at midpoint")
                    }
                    if height>=44*4.05 {
                        precondition(abs(g.keys.first!.frame.height/g.keys.first!.frame.width-4.05)<0.0001)
                    }
                    precondition(g.note(at:CGPoint(x:-0.01,y:40)) == nil)
                    precondition(g.note(at:CGPoint(x:width+0.01,y:40)) == nil)
                }
            }
        }
        var fullscreen=PracticeFullscreenState()
        fullscreen.enter()
        for t in stride(from:0.0,through:2,by:0.2) { precondition(!fullscreen.observe(.portrait,time:t)) }
        precondition(fullscreen.active && !fullscreen.portraitReturnArmed,"Holding upright after tapping must not immediately exit")
        precondition(!fullscreen.observe(.landscapeRight,time:3))
        precondition(!fullscreen.observe(.landscapeRight,time:3.4))
        precondition(fullscreen.portraitReturnArmed)
        precondition(!fullscreen.observe(.portrait,time:4))
        precondition(!fullscreen.observe(.uncertain,time:4.2),"Passing through flat must not exit")
        precondition(!fullscreen.observe(.portrait,time:5))
        precondition(fullscreen.observe(.portrait,time:5.6) && !fullscreen.active)
        precondition(PracticePhysicalPose.gravity(x:-1,y:0,z:0) == .landscapeRight)
        precondition(PracticePhysicalPose.gravity(x:1,y:0,z:0) == .landscapeLeft)
        precondition(PracticePhysicalPose.gravity(x:0,y:-1,z:0) == .portrait)
        precondition(PracticePhysicalPose.gravity(x:0,y:0,z:1) == .uncertain)
        fullscreen.enter();fullscreen.exit()
        precondition(!fullscreen.active)
        var filter=SlideIntentFilter<Int>()
        filter.begin(1,note:61,point:.zero,time:0)
        precondition(filter.accepted[1]==61,"Taps must be immediate")
        filter.move(1,note:60,point:CGPoint(x:30,y:0),time:0.010)
        filter.move(1,note:59,point:CGPoint(x:70,y:0),time:0.014)
        filter.advance(to:0.020)
        precondition(filter.accepted[1]==61,"Do not sound the crossed C")
        filter.advance(to:0.033)
        precondition(filter.accepted[1]==59,"Accept the deliberate B after <=18 ms")
        filter.end(1);filter.advance(to:1)
        precondition(filter.accepted.isEmpty && filter.nextDeadline == nil)
        // Both white/black directions, slow movement, and deliberate glissandi.
        for notes in [[60,61,62,63,64,65,66,67],[67,66,65,64,63,62,61,60]] {
            filter.begin(2,note:notes[0],point:.zero,time:2)
            for (index,note) in notes.dropFirst().enumerated() {
                let t=2+Double(index+1)*0.060
                filter.move(2,note:note,point:CGPoint(x:Double(index+1)*44,y:80),time:t)
                filter.advance(to:t+0.019)
                precondition(filter.accepted[2]==note,"Intentional glissando must register")
            }
            filter.end(2)
        }
        filter.begin(3,note:60,point:.zero,time:4)
        filter.move(3,note:61,point:CGPoint(x:10,y:0),time:4.001)
        filter.move(3,note:60,point:.zero,time:4.005)
        filter.advance(to:4.1);precondition(filter.accepted[3]==60,"Boundary reversal cancels pending notes")
        filter.move(3,note:nil,point:CGPoint(x:-10,y:0),time:4.2)
        precondition(filter.accepted[3] == nil,"Leaving releases immediately")
        filter.begin(4,note:64,point:.zero,time:4.3)
        filter.begin(5,note:64,point:.zero,time:4.3)
        filter.end(4);precondition(filter.accepted[5]==64,"Independent fingers survive duplicate-note release")
        filter.move(5,note:65,point:CGPoint(x:20,y:0),time:4.31)
        filter.cancelAll();filter.advance(to:5)
        filter.move(5,note:67,point:.zero,time:5.1)
        precondition(filter.accepted.isEmpty,"Cancellation never retriggers a stale finger")
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
        print("PASS: chord ledger, duplicate fingers, slides, cancellation, all 12 Sa labels, exact black-key boundary sweeps, filtered crossings, glissandi, cancellation, octave clamping and persistence")
    }
}
