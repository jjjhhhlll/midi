

(
SynthDef(\bass, {
	var snd, freq, buzz, gate;

	gate = \gate.kr(1);
	freq = \freq.kr(38.midicps) * (1 + Env([0, 0.2, 0], [TRand.kr(0.001, 0.06, gate), 0.1], [0, -4]).ar);

	snd = SinOsc.ar(freq);
	snd = snd + LFTri.ar(freq * 0.5) * LFNoise2.kr(60/140).range(-10, -2).dbamp;
	buzz = snd;

	buzz = buzz + (BPF.ar( { WhiteNoise.ar } ! 2, 8210, 0.3) * -20.dbamp);
	buzz = (buzz + 0.3).sign - buzz;
	buzz = buzz + DelayC.ar(buzz, 0.2, SinOsc.ar(0.3, [0, pi]).linlin(-1, 1, 0, 1) * 1e-3);
	buzz = buzz * Env.asr(0, 1, 0.5).ar(Done.none, gate);


	buzz = (buzz * 6).wrap2;
	buzz = LeakDC.ar(buzz);
	buzz = HPF.ar(buzz, LFNoise2.kr(5/140).range(600, 800)) * -12.dbamp;
	buzz = BPeakEQ.ar(buzz, 3120, 0.3, 3);
	buzz = GVerb.ar(buzz, 10, TRand.kr(0, 10, gate)) * -10.dbamp;


	snd = (snd * 5 * [1, -1]).tanh + buzz;

	snd = LPF.ar(snd, LFNoise2.kr(140/60).clip2.range(200, 18000));


	snd = snd * Env.asr(0, 1, 0.15, curve: 4).ar(Done.freeSelf, Impulse.kr(0) + gate);
	snd = snd * \amp.kr(1) * -15.dbamp;
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\gun, {
	var snd, fb;

	snd = Pluck.ar(SinOsc.ar(Env.perc(0, 0.001).ar));
	snd = snd + PinkNoise.ar * Env.perc(0.001, (60/140)*6.85).ar(Done.freeSelf);
	snd = HPF.ar(snd, 3000);


	snd = snd + Resonz.ar(WhiteNoise.ar, XLine.kr(1900, 200, 0.15), 1.1);

	fb = LocalIn.ar(2);
	fb = DelayC.ar(fb, 0.25, 0.05);

	fb = fb * MouseX.kr(-80, -10).dbamp;

	snd = snd + fb;
	snd = snd + PitchShift.ar(snd, 0.15, 0.7);

	snd = BHiShelf.ar(snd, 4000, 1, -20);
	snd = BLowShelf.ar(snd, 200, 1, -5);
	snd = (snd * 10).tanh;
	snd = BHiShelf.ar(snd, 4000, 1, 5);
	snd = BLowShelf.ar(snd, 200, 1, 10);

	snd = LeakDC.ar(snd);


	LocalOut.ar(snd);
	snd = GVerb.ar(snd, 10, 1);

	snd = snd ! 2;
	snd = snd * -28.dbamp;

	Out.ar(\out.kr(0), snd);
}).add

)

var synth = Synth(\bass, [ freq: 38.midicps ]);

(
var s, bpm, beat, root;
s = Server.default;
bpm = 140;
beat = 60 / bpm;

root = 38; // d0

Routine({
	var play;

	play = { |synthDef, duration, args|
		var synth;
		s.bind { synth = Synth(synthDef, args ++ [duration: duration]) };
		duration.wait;
		s.bind { synth.set(\gate, 0) };
	};
	loop {
		// 7/4
		Routine({
			s.bind { Synth(\gun) };
		}).play;

		play.(\bass, beat * 1, [ freq: root.midicps ]);
		play.(\bass, beat * 0.5, [ freq: root.midicps ]);
		(beat* 0.5).wait;
		play.(\bass, beat * 1.5, [ freq: (root + 3).midicps ]);
		play.(\bass, beat * 0.75, [ freq: root.midicps ]);
		(beat * 0.25).wait;
		play.(\bass, beat * 0.5, [ freq: root.midicps ]);
		play.(\bass, beat * 0.70, [ freq: (root + 3).midicps ]);
		(beat * 0.30).wait;
		play.(\bass, beat * 1, [ freq: (root + 3).midicps ]);

		Routine({
			s.bind { Synth(\gun) };
		}).play;

		play.(\bass, beat * 1, [ freq: root.midicps ]);
		play.(\bass, beat * 0.5, [ freq: root.midicps ]);
		(beat* 0.5).wait;
		play.(\bass, beat * 1.5, [ freq: (root + 3).midicps ]);
		play.(\bass, beat * 0.75, [ freq: root.midicps ]);
		(beat * 0.25).wait;
		play.(\bass, beat * 0.5, [ freq: root.midicps ]);
		play.(\bass, beat * 0.45, [ freq: (root + 5).midicps ]);
		(beat * 0.05).wait;
		play.(\bass, beat * 0.45, [ freq: (root + 3).midicps ]);
		(beat * 0.05).wait;
		play.(\bass, beat * 0.45, [ freq: (root + 5).midicps ]);
		(beat * 0.05).wait;
		play.(\bass, beat * 0.45, [ freq: (root + 3).midicps ]);
		(beat * 0.05).wait;
	}

}).play;
)

Synth(\bass);