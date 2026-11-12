import Foundation

// A finger tap on the front of the closed case, found in one earbud's raw motion (50 to 200 Hz).
// A finger on the front pushes one way: the sensor turns with the case, so however it's held, every recorded tap lines up
// with tapDirection, however light, and bumps elsewhere fall short. Strength and wobble overlap between the two, so they don't decide.
// The click is decided on the sample the spike arrives in, without waiting for the wobble to end. A first tap has to come from
// a still case, which keeps handling out; the finger's approach may drift it for up to 100 ms first. Just before a tap the case
// turned 28°/s at most, and just before tap-like jolts from moving it 41°/s or more, so turning asks for a firmer, more exact spike.
// A firm, exact spike with little turning counts even if the hand wasn't quite still. For a second after a tap the hand
// hasn't settled, so a spike there only has to come without much rotation.
// The thresholds come from closed-lid taps held in the hand, closed-lid handling and pointing (Tests/TapFixtures.csv)
// and from runs of the tap test. They and the default direction were tuned on AirPods Pro 3. AirPods 4 shares the H2
// motion stack but has a different case and earbud shape, so Teach Tap and the Tap Test should confirm its taps.
struct ClosedCaseTapDetector {
    // tap: click where the pointer was before `since` (sensor seconds), and keep it there through the wobble.
    // repeated means it counted only because it came soon after another tap. release: the pointer can move again.
    enum Event:Equatable{case tap(since:Double,jolt:Double,repeated:Bool),release}
    // Accelerations in g, rotation in degrees per second, times in seconds, so any sample rate works.
    static let jolt=0.2,softJolt=0.12,repeatJolt=0.22,stillAcceleration=0.08,minimumAlignment=0.9
    static let stillRotation=40.0,calmLead=30.0,leadRotation=60.0,calmRepeat=45.0,repeatRotation=90.0,fastRotation=35.0,runStartRotation=150.0
    static let firmJolt=0.3,firmAlignment=0.95,echoShare=0.7
    static let tapDirection:SIMD3<Double>={let v=SIMD3(-0.84,0.29,-0.46);return v/(v*v).sum().squareRoot()}()
    // A spike is the change over spikeOver, measured across a gap of at most spikeGap.
    static let spikeOver=0.015,spikeGap=0.05,stillFor=0.13,stillWindow=0.15,leadIn=0.1,peakWithin=0.03,refractory=0.25,fastRefractory=0.12
    // Rotation just before a spike is judged up to impactFrom ahead of it, because the impact itself turns the case.
    static let repeatLeadIn=0.12,impactFrom=0.02,runFor=1.0,runStartAfter=0.06,steadyFor=0.2
    // The case drops runs of samples over 60 ms more than twice a second, so stillness rides out gaps up to this.
    static let maximumGap=0.25
    fileprivate struct Sample{let t:Double;let a:SIMD3<Double>;let w:SIMD3<Double>}
    // The way a finger on the front pushes this case's sensor, learned in setup if it isn't tapDirection.
    var direction=Self.tapDirection
    private var recent:[Sample]=[],rotation:(t:Double,w:SIMD3<Double>)?
    private var lastTap = -Double.infinity,tapPeak=0.0,runFrom = -Double.infinity,steadyUntil:Double?
    // Jolts that didn't click, for the session log. The reader empties it.
    var ignored:[String]=[]
    private var lastIgnored = -Double.infinity,ignoredSize=0.0

    // Starting over lets go of a held pointer.
    mutating func reset()->[Event]{rotation=nil;runFrom = -Double.infinity;return restart()}
    private mutating func restart()->[Event]{
        let held=steadyUntil != nil;recent=[];steadyUntil=nil
        return held ? [.release]:[]
    }
    // Motion rows as the helper writes them: sequence, service (11 accelerometer, 12 gyroscope),
    // sensor microseconds, host uptime, then x, y, z in units of 1e-5. A batch can arrive out of order across services.
    mutating func feed(_ rows:[[Double]])->[Event]{
        rows.filter{$0.count==7}.sorted{$0[2]<$1[2]}.flatMap{feed(service:Int($0[1]),stamp:$0[2],x:$0[4],y:$0[5],z:$0[6])}
    }
    mutating func feed(service:Int,stamp:Double,x:Double,y:Double,z:Double)->[Event]{
        let t=stamp*1e-6,v=SIMD3(x,y,z)*1e-5
        guard t.isFinite,v.x.isFinite,v.y.isFinite,v.z.isFinite else{return []}
        if service==12{rotation=(t,v);return []}
        guard service==11 else{return []}
        if let last=recent.last,t<=last.t{return []}
        // Without a rotation close in time the shape can't be judged; after a long delivery gap it starts over.
        guard let rotation,abs(rotation.t-t)<=Self.maximumGap else{return restart()}
        var events:[Event]=[]
        if let last=recent.last,t-last.t>Self.maximumGap{events=restart()}
        let sample=Sample(t:t,a:v,w:rotation.w)
        defer{
            recent.append(sample)
            while let first=recent.first,t-first.t>Self.leadIn+Self.stillWindow+2*Self.maximumGap{recent.removeFirst()}
        }
        return events+step(sample)
    }
    private func length(_ v:SIMD3<Double>)->Double{(v*v).sum().squareRoot()}
    private mutating func step(_ s:Sample)->[Event]{
        var events:[Event]=[]
        if let steadyUntil,s.t>=steadyUntil{self.steadyUntil=nil;events.append(.release)}
        guard let before=recent.last(where:{s.t-$0.t>=Self.spikeOver}) ?? recent.first,s.t-before.t<=Self.spikeGap else{return events}
        let spike=s.a-before.a,size=length(spike),along=(spike*direction).sum()
        if s.t-lastTap<=Self.peakWithin{tapPeak=max(tapPeak,along)}
        guard s.t-lastTap>=Self.fastRefractory,size>=Self.softJolt else{return events}
        guard along>=size*Self.minimumAlignment else{
            // The rebound of any jolt points backwards, so only forward ones say anything about a tap.
            if size>=Self.jolt,along>0{ignore(s.t,size,String(format:"not on the front, alignment %.2f, jolt %.2f g",along/size,size))}
            return events
        }
        guard along>=Self.jolt else{ignore(s.t,along,String(format:"too soft, %.2f g",along));return events}
        let lead=rotations(from:s.t-Self.leadIn,to:s.t-Self.impactFrom).max(),justBefore=rotations(from:s.t-Self.repeatLeadIn,to:s.t-Self.impactFrom).max()
        // A case turning a little is often about to be moved, so a tap then has to be firmer and more exact.
        let firm=along>=Self.firmJolt && along>=size*Self.firmAlignment
        let base=still(before:s.t-Self.leadIn),first=base != nil && lead ?? 0<=(firm ? Self.leadRotation:Self.calmLead)
        let exact=firm && justBefore.map{$0<=Self.calmRepeat} ?? false
        // A spike turned down a moment ago starts a run for the next tap, not for the rest of itself.
        let repeated=s.t-runFrom<=Self.runFor && (runFrom==lastTap || s.t-runFrom>=Self.runStartAfter) && along>=Self.repeatJolt && justBefore.map{$0<=(firm ? Self.repeatRotation:Self.calmRepeat)} ?? false
        // Soon after a click, a tap's own echo is much weaker than it and comes with the hand turning.
        if s.t-lastTap<Self.refractory{
            guard repeated,along>=tapPeak*Self.echoShare,justBefore ?? .infinity<=Self.fastRotation else{return events}
        }
        guard first || repeated || exact else{
            // A tap turned down for coming straight after a move still starts a run, so the next one counts.
            if along>=Self.repeatJolt,let justBefore,justBefore<=Self.runStartRotation{runFrom=s.t}
            ignore(s.t,along,base==nil ? unsteady(before:s.t-Self.leadIn,along:along):String(format:"jolt %.2f g, rotating %.0f°/s just before",along,lead ?? 0))
            return events
        }
        // The finger's approach may drift the case a little; the click belongs where that began.
        let drift=base.flatMap{base in recent.first{$0.t>=s.t-Self.leadIn && length($0.a-base)>Self.stillAcceleration}?.t}
        if steadyUntil != nil{events.append(.release)}
        lastTap=s.t;tapPeak=along;runFrom=s.t;steadyUntil=s.t+Self.steadyFor
        return events+[.tap(since:min(drift ?? before.t,before.t),jolt:along,repeated:!first && repeated)]
    }
    private func rotations(from:Double,to:Double)->[Double]{recent.filter{$0.t>=from && $0.t<=to}.map{length($0.w)}}
    // A spike can be turned down twice on its way up, so a much stronger reason still gets logged.
    private mutating func ignore(_ t:Double,_ size:Double,_ why:String){
        guard t-lastIgnored>=Self.refractory || size>ignoredSize*1.5 else{return}
        lastIgnored=t;ignoredSize=size;ignored.append(String(format:"ignored at %.2f: ",t)+why)
    }
    private func unsteady(before end:Double,along:Double)->String{
        let window=recent.filter{$0.t<end && end-$0.t<=Self.stillWindow}
        return String(format:"sudden %.2f g, not still before it, %d samples, rotating up to %.0f°/s",along,window.count,window.map{length($0.w)}.max() ?? 0)
    }
    // The resting acceleration over about 140 ms ending at `end`, if the case was still then. A gap in that window
    // borrows earlier samples, up to one gap's worth, so it only means fewer samples to judge by.
    private func still(before end:Double)->SIMD3<Double>?{Self.still(recent,before:end)}
    fileprivate static func still(_ recent:[Sample],before end:Double)->SIMD3<Double>?{
        func length(_ v:SIMD3<Double>)->Double{(v*v).sum().squareRoot()}
        let earlier=recent.filter{$0.t<end}
        var window=earlier.filter{end-$0.t<=Self.stillWindow}
        while window.count<3 || end-(window.first?.t ?? end)<Self.stillFor,
              let more=earlier.last(where:{$0.t<(window.first?.t ?? end)}),end-more.t<=Self.stillWindow+Self.maximumGap{window.insert(more,at:0)}
        guard window.count>=3,let first=window.first,end-first.t>=Self.stillFor else{return nil}
        let base=window.reduce(SIMD3<Double>.zero){$0+$1.a}/Double(window.count)
        guard window.allSatisfy({length($0.w)<=Self.stillRotation && length($0.a-base)<=Self.stillAcceleration}) else{return nil}
        return base
    }
}

// Learns which way a person's taps push the sensor, from a few taps on a still case in any direction. A person whose
// taps already line up with tapDirection keeps it, because it comes from many more taps than three.
struct ClosedCaseTapLearner {
    // agreeing is the largest group of taps so far that went the same way.
    enum Event:Equatable{case tap(agreeing:Int,total:Int),tooSoft,finished(direction:SIMD3<Double>),failed}
    static let taps=3,mostTaps=6,tapsAgree=0.9,keepDefault=0.95,refractory=0.4,softAfter=0.08,windUp=2.0,windUpWithin=0.05
    private typealias Detector=ClosedCaseTapDetector
    private var recent:[Detector.Sample]=[],rotation:(t:Double,w:SIMD3<Double>)?,lastTap = -Double.infinity,lastSoft = -Double.infinity,softSince:Double?
    private var pushing:(start:Double,first:SIMD3<Double>,strongest:SIMD3<Double>)?
    private(set) var pushes:[SIMD3<Double>]=[]
    private var done=false

    mutating func feed(_ rows:[[Double]])->[Event]{
        rows.filter{$0.count==7}.sorted{$0[2]<$1[2]}.flatMap{feed(service:Int($0[1]),stamp:$0[2],x:$0[4],y:$0[5],z:$0[6])}
    }
    private func length(_ v:SIMD3<Double>)->Double{(v*v).sum().squareRoot()}
    mutating func feed(service:Int,stamp:Double,x:Double,y:Double,z:Double)->[Event]{
        let t=stamp*1e-6,v=SIMD3(x,y,z)*1e-5
        guard !done,t.isFinite,v.x.isFinite,v.y.isFinite,v.z.isFinite else{return []}
        if service==12{rotation=(t,v);return []}
        guard service==11,let rotation,abs(rotation.t-t)<=Detector.maximumGap else{return []}
        if let last=recent.last,t<=last.t{return []}
        let sample=Detector.Sample(t:t,a:v,w:rotation.w)
        defer{
            recent.append(sample)
            while let first=recent.first,t-first.t>Detector.leadIn+Detector.stillWindow+2*Detector.maximumGap{recent.removeFirst()}
        }
        guard let before=recent.last(where:{t-$0.t>=Detector.spikeOver}) ?? recent.first,t-before.t<=Detector.spikeGap else{return []}
        let spike=v-before.a
        // The first push is the finger's: what follows it, however strong, is the case rebounding.
        if let pushing{
            let along=(spike*pushing.first).sum()
            if t-pushing.start<=Detector.peakWithin,along>0{
                if length(spike)>length(pushing.strongest){self.pushing!.strongest=spike}
                return []
            }
            if t-pushing.start<=Self.windUpWithin{
                // The case can shift the other way just before a hard tap lands: a far bigger push this soon is the finger.
                if along<0,length(spike)>=Self.windUp*length(pushing.strongest){self.pushing=(t,spike,spike);lastTap=t}
                return []
            }
            self.pushing=nil
            pushes.append(pushing.strongest)
            return finish()
        }
        // A firm tap passes through this size on its way up, so too soft has to wait and see.
        var events:[Event]=[]
        if let softSince,t-softSince>=Self.softAfter{self.softSince=nil;lastSoft=t;events=[.tooSoft]}
        guard t-lastTap>=Self.refractory,length(spike)>=Detector.softJolt else{return events}
        if length(spike)>=Detector.jolt{softSince=nil}
        // As in the detector, a firm tap may come with more turning just ahead of it.
        let lead=length(spike)>=Detector.firmJolt ? Detector.leadRotation:Detector.calmLead
        let calm=recent.filter{$0.t>=t-Detector.leadIn && $0.t<=t-Detector.impactFrom}.allSatisfy{length($0.w)<=lead}
        guard calm,Detector.still(recent,before:t-Detector.leadIn) != nil else{return events}
        guard length(spike)>=Detector.jolt else{
            if softSince==nil,t-lastSoft>=Self.refractory{softSince=t}
            return events
        }
        lastTap=t;pushing=(t,spike,spike)
        return events
    }
    private mutating func finish()->[Event]{
        let group=Self.largestGroup(pushes)
        var events:[Event]=[.tap(agreeing:group.count,total:pushes.count)]
        if group.count>=Self.taps{
            let mean=Self.unit(group.reduce(.zero,+))
            done=true;events.append(.finished(direction:(mean*Detector.tapDirection).sum()>=Self.keepDefault ? Detector.tapDirection:mean))
        }else if pushes.count>=Self.mostTaps{done=true;events.append(.failed)}
        return events
    }
    private static func unit(_ v:SIMD3<Double>)->SIMD3<Double>{v/max((v*v).sum().squareRoot(),1e-9)}
    private static func largestGroup(_ pushes:[SIMD3<Double>])->[SIMD3<Double>]{
        let units=pushes.map(unit)
        return units.map{one in units.filter{(one*$0).sum()>=tapsAgree}}.max{$0.count<$1.count} ?? []
    }
}
