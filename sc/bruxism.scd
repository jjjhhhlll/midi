(
SynthDef(\lead1, {
	var snd, freq, amp, duration;

	freq = \freq.kr(440);
	amp = \amp.kr(0.2);
	duration = \duration.kr(1);

	duration = MouseY.kr(duration + (duration / 3), 0);
	amp = LFNoise2.kr(0.05).clip(0.1, 0.4);

	snd = Pulse.ar(freq, 0.5);
	snd = RLPF.ar(snd, MouseX.kr(200, 10000), [0.1, 0.1, 0.1, 0.1, 0.2].choose);
	snd = snd * Env.linen(0.01, duration,  0.2).ar(Done.freeSelf) * amp;
	snd = snd * -5.dbamp;
	Out.ar(\out.kr(0), Pan2.ar(snd, \pan.kr(0)));
}).add;

SynthDef(\fx, {
	var snd, wet, fb, trigger;
	snd = In.ar(\out.kr(0), 2);

	wet = snd;
	fb = LocalIn.ar(2);
	fb = DelayC.ar(fb, 1.0, 0.1).lag(0.05);
	fb = BLowShelf.ar(fb, 200, 0.3, -5);
	fb = BHiShelf.ar(fb, 2000, 0.3, -5);
	fb = LeakDC.ar(fb);
	fb = Limiter.ar(fb);
	wet = wet + fb;
	wet = wet + GVerb.ar(wet.sum * -25.dbamp, 30, 1);
	LocalOut.ar(wet);

	snd = BLowShelf.ar(snd, 200, 0.3, -3);
	snd = BHiShelf.ar(snd, 2000, 0.3, -3);
	snd = (snd * 30).tanh + snd.fold2;
	snd = BLowShelf.ar(snd, 400, 0.3, 3);
	snd = BHiShelf.ar(snd, 2000, 0.3, 3);
	snd = snd + wet;

	snd = LeakDC.ar(snd);
	snd = Limiter.ar(snd);
	snd = snd * -4.dbamp;
	ReplaceOut.ar(\out.kr(0), snd);
}).add;
)

(
var s;
s = Server.default;
Routine({
	s.bind { fx = Synth.tail(nil, \fx, [ out: 0 ]) };
	loop {
		s.bind { Synth(\lead1, [ freq: notes1.next, duration: 60/90/4 ]) };
		(60/90/4).wait;
	}
}).play;
)

(
var s, beat, beat4, bpm, notes, notes1, notes2, tempo2;
s = Server.default;
bpm = 90;
beat = 60/bpm;
beat4 = beat / 4;

notes = [ 41, 45, 47, 41, 45, 47, 48, 41, 47, 48, 41, 45, 41, 40];

notes1 = Pseq(notes.midicps, inf).asStream;
notes2 = Pseq(notes.midicps, inf).asStream;

tempo2 = Pseq([
	Pseq([Pseq([1 * beat4], notes.size)], 3),
	Pseq([(12/13) * beat4 ], 2)], inf).asStream;

Routine({
	var fx;
	s.bind { fx = Synth.tail(nil, \fx, [out: 0]); };
	fork {
		loop {
			s.bind { Synth(\lead1, [ freq: notes1.next, duration: beat4, pan: -0.7 ]) };
			beat4.wait;
		};
	};

	loop {
		var accel;
		accel = tempo2.next;
			s.bind { Synth(\lead1, [ freq: notes2.next, duration: accel, pan: 0.7 ]) };
			accel.wait;
	};


}).play;
)