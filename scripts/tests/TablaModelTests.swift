import Foundation
@main struct TablaModelTests {
    static func main() throws {
        let counts=[6,7,8,16,12,10]
        let sequences=[
            "Dha|Dhin|Na|Dha|Tin|Na", "Tin|Tin|Na|Dhin|Na|Dhin|Na",
            "Dha|Ge|Na|Ti|Na|Ka|Dhin|Na",
            "Dha|Dhin|Dhin|Dha|Dha|Dhin|Dhin|Dha|Dha|Tin|Tin|Na|Na|Dhin|Dhin|Dha",
            "Dhin|Dhin|Dha Ge|Ti Ra Ki Ta|Tun|Na|Kat|Ta|Dha Ge|Ti Ra Ki Ta|Dhin|Na",
            "Dhin|Na|Dhin|Dhin|Na|Tin|Na|Dhin|Dhin|Na"]
        for (index,taal) in TablaTaal.allCases.enumerated() {
            precondition(taal.matras==counts[index] && taal.labels.joined(separator:"|")==sequences[index])
            precondition(taal.strokes.first!.tick==0 && taal.strokes.last!.tick<(taal.matras*4))
            for bpm in [30.0,80,137,240] {
                var model=TablaTimeline(taal:taal,bpm:bpm)
                // 12 hours: arbitrary non-integral beat durations, no rounded-interval accumulation.
                let frames=Int64(12*3600*48000)
                let events=model.events(through:frames)
                precondition(events.count>10000)
                for event in events {
                    let expected=event.beat*48000*60/bpm
                    precondition(abs(Double(event.frame)-expected)<=0.5001)
                }
                precondition(zip(events,events.dropFirst()).allSatisfy{$0.frame<$1.frame})
            }
        }
        precondition(TablaTaal.rupak.khali==[1] && TablaTaal.rupak.strokes[0].bol == .tin && TablaTaal.rupak.strokes[0].strength==1)
        let ek=TablaTaal.ektaal.strokes
        precondition(ek.filter{(8..<12).contains($0.tick)}.map(\.tick)==[8,10])
        precondition(ek.filter{(12..<16).contains($0.tick)}.map(\.tick)==[12,13,14,15])
        var model=TablaTimeline(taal:.ektaal,bpm:80)
        let initial=model.events(through:110000)
        let boundary=ceil(model.nextBeat),at=model.frame(at:boundary)
        model.setTempo(137);model.setTempo(141)
        precondition(abs(model.frame(at:boundary)-at)<0.001)
        let after=model.events(through:Int64(at)+500000)
        precondition(initial.last!.frame<after.first!.frame)
        precondition(after.allSatisfy { event in
            let expected=event.beat<boundary ? event.beat*36000:at+(event.beat-boundary)*48000*60/141
            return abs(Double(event.frame)-expected)<=0.5001
        })
        var settings=TablaSettings();settings.bpm = .nan;settings.volume=4
        precondition(settings.validated().bpm==80 && settings.validated().volume==1)
        let data=try JSONEncoder().encode(TablaSettings(taal:.jhaptal,bpm:137,volume:0.37))
        let restored=try JSONDecoder().decode(TablaSettings.self,from:data)
        precondition(restored==TablaSettings(taal:.jhaptal,bpm:137,volume:0.37))
        print("PASS: six reference thekas/vibhags; Rupak khali sam; Ektaal subdivisions; 12-hour absolute-frame drift <=0.5 frame at 30/80/137/240 BPM; phase-continuous tempo edits; settings round-trip")
    }
}
