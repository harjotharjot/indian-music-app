import Foundation

enum TablaBol: String, Codable, CaseIterable {
    case dha, dhin, na, tin, tun, ge, ke, ti, ta
}
struct TablaStroke: Equatable {
    let tick: Int // quarter-matra ticks, relative to a complete avartan
    let bol: TablaBol
    let strength: Int // preloaded dynamic layers: 0 soft, 1 ordinary, 2 accented
}
enum TablaTaal: String, CaseIterable, Codable, Identifiable {
    case dadra, rupak, keherwa, teentaal, ektaal, jhaptal
    var id: String { rawValue }
    var title: String {
        switch self {
        case .dadra:return "Dadra"
        case .rupak:return "Rupak"
        case .keherwa:return "Keherwa"
        case .teentaal:return "Teentaal"
        case .ektaal:return "Ektaal"
        case .jhaptal:return "Jhaptal"
        }
    }
    var groups: [Int] {
        switch self {
        case .dadra:return [3,3]
        case .rupak:return [3,2,2]
        case .keherwa:return [4,4]
        case .teentaal:return [4,4,4,4]
        case .ektaal:return [2,2,2,2,2,2]
        case .jhaptal:return [2,3,2,3]
        }
    }
    var matras: Int { groups.reduce(0,+) }
    var khali: Set<Int> {
        switch self {
        case .dadra:return [4]
        case .rupak:return [1]
        case .keherwa:return [5]
        case .teentaal:return [9]
        case .ektaal:return [3,7]
        case .jhaptal:return [6]
        }
    }
    var groupStarts: [Int] {
        var start=1
        return groups.map { count in defer { start+=count };return start }
    }
    var labels: [String] {
        switch self {
        case .dadra:return ["Dha","Dhin","Na","Dha","Tin","Na"]
        case .rupak:return ["Tin","Tin","Na","Dhin","Na","Dhin","Na"]
        case .keherwa:return ["Dha","Ge","Na","Ti","Na","Ka","Dhin","Na"]
        case .teentaal:return ["Dha","Dhin","Dhin","Dha","Dha","Dhin","Dhin","Dha","Dha","Tin","Tin","Na","Na","Dhin","Dhin","Dha"]
        case .ektaal:return ["Dhin","Dhin","Dha Ge","Ti Ra Ki Ta","Tun","Na","Kat","Ta","Dha Ge","Ti Ra Ki Ta","Dhin","Na"]
        case .jhaptal:return ["Dhin","Na","Dhin","Dhin","Na","Tin","Na","Dhin","Dhin","Na"]
        }
    }
    var strokes: [TablaStroke] {
        let bols: [[TablaBol]]
        switch self {
        case .dadra:bols=[[.dha],[.dhin],[.na],[.dha],[.tin],[.na]]
        case .rupak:bols=[[.tin],[.tin],[.na],[.dhin],[.na],[.dhin],[.na]]
        case .keherwa:bols=[[.dha],[.ge],[.na],[.ti],[.na],[.ke],[.dhin],[.na]]
        case .teentaal:bols=[[.dha],[.dhin],[.dhin],[.dha],[.dha],[.dhin],[.dhin],[.dha],[.dha],[.tin],[.tin],[.na],[.na],[.dhin],[.dhin],[.dha]]
        case .ektaal:bols=[[.dhin],[.dhin],[.dha,.ge],[.ti,.ta,.ke,.ta],[.tun],[.na],[.ke],[.na],[.dha,.ge],[.ti,.ta,.ke,.ta],[.dhin],[.na]]
        case .jhaptal:bols=[[.dhin],[.na],[.dhin],[.dhin],[.na],[.tin],[.na],[.dhin],[.dhin],[.na]]
        }
        return bols.enumerated().flatMap { index, beat in
            beat.enumerated().map { sub,bol in
                // Rupak's sam remains khali: no extra bayan or heavy sam accent.
                let accent = groupStarts.contains(index+1) && !khali.contains(index+1)
                return TablaStroke(tick:index*4+sub*(4/beat.count),bol:bol,
                                   strength:sub>0 ? 0:(accent ? 2:1))
            }
        }
    }
}
struct TablaSettings: Codable, Equatable {
    var taal: TablaTaal = .teentaal
    var bpm: Double = 80
    var volume: Double = 0.6
    func validated() -> Self {
        var value=self
        value.bpm=bpm.isFinite ? min(240,max(30,bpm)):80
        value.volume=volume.isFinite ? min(1,max(0,volume)):0.6
        return value
    }
}
enum TablaTransport: String { case stopped, playing, paused }
struct TablaPosition {
    let taal: TablaTaal
    let matra: Int // zero while awaiting the first scheduled sam
    let cycle: Int
    let state: TablaTransport
}

// Absolute sample positions are rounded once, never accumulated as rounded durations.
// Piecewise tempo segments retain the phase of all events already submitted to Core Audio.
struct TablaTimeline {
    struct Segment { let beat: Double; let frame: Double; let bpm: Double }
    struct Event { let frame: Int64; let stroke: TablaStroke; let beat: Double }
    private(set) var taal: TablaTaal
    private(set) var segments: [Segment]
    private(set) var cycle: Int64 = 0
    private(set) var index=0
    let sampleRate: Double
    init(taal: TablaTaal,bpm: Double,startFrame: Int64=0,sampleRate: Double=48000) {
        self.taal=taal;self.sampleRate=sampleRate
        segments=[Segment(beat:0,frame:Double(startFrame),bpm:bpm)]
    }
    var nextBeat: Double { Double(cycle*Int64(taal.matras))+Double(taal.strokes[index].tick)/4 }
    func frame(at beat: Double) -> Double {
        let s=segments.last(where:{$0.beat<=beat}) ?? segments[0]
        return s.frame+(beat-s.beat)*sampleRate*60/s.bpm
    }
    func beat(at frame: Double) -> Double {
        let s=segments.last(where:{$0.frame<=frame}) ?? segments[0]
        return s.beat+(frame-s.frame)*s.bpm/(sampleRate*60)
    }
    mutating func events(through horizon: Int64) -> [Event] {
        let strokes=taal.strokes
        var result:[Event]=[]
        while true {
            let beat=Double(cycle*Int64(taal.matras))+Double(strokes[index].tick)/4
            let scheduled=Int64(frame(at:beat).rounded())
            if scheduled>horizon { break }
            result.append(Event(frame:scheduled,stroke:strokes[index],beat:beat))
            index+=1
            if index==strokes.count { index=0;cycle+=1 }
        }
        return result
    }
    mutating func setTempo(_ bpm: Double) {
        let boundary=ceil(nextBeat)
        let at=frame(at:boundary)
        // Rapid slider updates replace an unrendered segment at the same boundary.
        segments.removeAll(where:{$0.beat>=boundary && $0.beat>0})
        if boundary==0 { segments=[Segment(beat:0,frame:at,bpm:bpm)] }
        else { segments.append(Segment(beat:boundary,frame:at,bpm:bpm)) }
    }
    func position(at frame: Int64,state: TablaTransport) -> TablaPosition {
        let beat=beat(at:Double(frame))
        guard beat>=0 else { return TablaPosition(taal:taal,matra:0,cycle:0,state:state) }
        let whole=Int(floor(beat+1e-8))
        return TablaPosition(taal:taal,matra:whole%taal.matras+1,cycle:whole/taal.matras+1,state:state)
    }
}
