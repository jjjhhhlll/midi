

(

var lfo;

lfo = { |rate|
	LFNoise2.kr(rate) + LFNoise2.kr(rate * 2) + TRand.kr(-1, 1, Dust.kr(rate)).lag(0.01);
};


SynthDef(\bass, {
	var snd, freq, buzz, exciter, gate, fb;

	gate = \gate.kr(1);
	freq = \freq.kr(38.midicps) * (1 + Env([0, 0.2, 0], [TRand.kr(0.001, 0.06, gate), 0.1], [0, -4]).ar);

	exciter = SinOsc.ar(Env.perc(0, 0.01).ar(gate: gate).linexp(0, 1, 100, 7000)) * Env.perc(0.0, 0.05).ar(gate: gate);

	snd = Pluck.ar(exciter, gate, 2.0, 1 / (freq * [
		(TWChoose.kr(gate, [ 1, 0.5, 2 ], [0.4, 0.3, 0.3])),
		(TWChoose.kr(gate, [ 1, 0.5, 2 ], [0.3, 0.3, 0.4]))
	]), 4.0, TRand.kr(0.3, 0.8, gate));

	fb = LocalIn.ar(2);
	fb = DelayC.ar(fb, 0.3, 0.003);

	fb = fb * SinOsc.ar(60/140);
	fb = BPF.ar(fb, [146, 293]);
	fb = fb * -10.dbamp;

	snd = snd + fb;

	snd = snd + LFTri.ar(freq * 0.5) * LFNoise2.kr(60/140).range(-10, -2).dbamp;



	buzz = snd;

	buzz = buzz + (BPF.ar( { WhiteNoise.ar } ! 2, 8210, 0.3) * -20.dbamp);
	buzz = (buzz + 0.3).sign - buzz;
	buzz = buzz + DelayC.ar(buzz, 0.2, SinOsc.ar(0.3, [0, pi]).linlin(-1, 1, 0, 1) * 1e-3);
	buzz = buzz * Env.asr(0, 1, 0.5).ar(Done.none, gate);


	buzz = (buzz * 6).wrap2;
	buzz = LeakDC.ar(buzz);
	buzz = HPF.ar(buzz, LFNoise2.kr(5/140).range(600, 800)) * -14.dbamp;
	buzz = BPeakEQ.ar(buzz, 3120, 0.3, 3);
	buzz = GVerb.ar(buzz, 20, TRand.kr(0, 10, gate)) * -10.dbamp;


	snd = BLowShelf.ar(snd, 300, 1, 10);
	snd = BHiShelf.ar(snd, 4186, 0.9, -10);
	snd = (snd * 5 * [1, -1]).tanh + buzz;
	snd = BLowShelf.ar(snd, 300, 1, 10);
	snd = BHiShelf.ar(snd, 4186, 1, 5);

	snd = LeakDC.ar(snd);

	snd = LPF.ar(snd, LFNoise2.kr(140/60).clip2.range(200, 18000));
	LocalOut.ar(snd);

	snd = snd * Env.asr(0, 1, 0.15, curve: 4).ar(Done.freeSelf, Impulse.kr(0) + gate);
	snd = snd * \amp.kr(1) * -19.dbamp;
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\gun, {
	var snd, fb;

	snd = Pluck.ar(SinOsc.ar(Env.perc(0, 0.001).ar));
	snd = snd + PinkNoise.ar * Env.perc(0.001, (60/140)*6.85, 1, 1, -8).ar(Done.freeSelf);
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
	snd = GVerb.ar(snd, 1, 1);

	snd = snd ! 2;
	snd = snd * -28.dbamp;

	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\kick, {
	var snd, clickDuration;
	clickDuration = 2e-3;

	snd = SinOsc.ar(65 * [-1, 1].midiratio * (1 + (7 * Env.perc(0.001, 0.03).ar))
		* (1 + (0.5 * Env.perc(0.001, 0.5).ar)));

	snd = Select.ar(Sweep.ar > clickDuration, [ Hasher.ar(Sweep.ar), DelayC.ar(snd, clickDuration, clickDuration)]);

	//snd = snd + (GVerb.ar(snd.sum, 12, 3, damping: 0.3) * -21.dbamp);

	snd = (snd * (1 + (0.3 * Env.perc(0, 0.1).ar))).tanh;

	snd = snd * Env.perc(0.0, 0.5).ar(Done.freeSelf);
	snd = snd * \amp.kr(1) * -2.dbamp;
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\kick2, {
	var snd;
	snd = SinOsc.ar(Env.perc(0, 0.1).ar.linexp(0, 1, 40, 700) * XLine.ar(2, 1, 0.01));
	snd = snd * Env.perc(0.001, 0.6).ar;
	snd = snd * Env.linen(0.0, 0.5, 0.1, curve: -4).ar(Done.freeSelf);
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar + [0,1]), 6120, 0.3) * Env.perc(0.02, 0.01).ar * -1.dbamp);
	snd = snd * (1 + Env.perc(0.001, 0.1).ar);
	snd = snd.tanh;
	snd = BLowShelf.ar(snd, 200, 0.3, 5);

	snd = snd * \amp.kr(1) * -2.dbamp;
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\snare, {
	var snd;
	snd = SinOsc.ar(Env.perc(0, 0.1).ar.linexp(0, 1, 40, 440) * XLine.ar(1.3, 1, 0.01));


	snd = snd.tanh;
	snd = snd + (SinOsc.ar(XLine.ar(3000, 100, 0.01)) * Env.perc(0.001, 0.01).ar * 3.dbamp);
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar + [0, 1]), 1220, 0.5) * Env.perc(0.01, 0.03).ar * -3.dbamp);
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar + [0, 1]), 2520, 0.5) * Env.perc(0.05, 0.1).ar * -3.dbamp);
	snd = snd + GVerb.ar(snd.sum * -25.dbamp, 30, 8);
	snd = snd + PitchShift.ar(snd, 0.053, 1.5);

	snd = snd * \amp.kr(1) * -5.dbamp;
	snd = snd * Env.linen(0.0, \duration.kr(0.5), 0.1, curve: -4).ar(Done.freeSelf);
	Out.ar(\out.kr(0), snd);
}).add;

)

Synth(\kick2);
Synth(\snare);

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
		});

		Routine({
			s.bind { Synth(\kick2) };
			(beat * 2).wait;
			s.bind { Synth(\snare) };
			(beat * 2).wait;
			s.bind { Synth(\kick) };
			(beat * 2).wait;
			s.bind { Synth(\snare) };
			beat.wait;
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
		});

		Routine({
			s.bind { Synth(\kick) };
			(beat * 2).wait;
			s.bind { Synth(\snare) };
			(beat * 2).wait;
			s.bind { Synth(\kick2) };
			(beat * 2.5).wait;
			s.bind { Synth(\snare) };
			(beat * 0.5).wait;
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