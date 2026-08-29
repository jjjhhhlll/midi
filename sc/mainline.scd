(
s.options.memSize = 8192 * 4;
s.boot;
)

(
Buffer.freeAll;
b = ();

PathName("samples/".resolveRelative).entries.do({ |pn|
	b.put(pn.fileNameWithoutExtension.asSymbol, Buffer.read(s, pn.fullPath));
});
)

(

SynthDef(\bass, {
	var snd, freq, buzz, exciter, gate, fb, fbDamp;

	gate = \gate.kr(1);
	freq = \freq.kr(38.midicps) * (1 + Env([0, 0.2, 0], [TRand.kr(0.001, 0.06, gate), 0.1], [0, -4]).ar);
	fbDamp = \fbDamp.kr(-16.dbamp);

	exciter = SinOsc.ar(Env.perc(0, 0.01).ar(gate: gate).linexp(0, 1, 100, 7000)) * Env.perc(0.0, 0.05).ar(gate: gate);

	snd = Pluck.ar(exciter, gate, 2.0, 1 / (freq * [
		(TWChoose.kr(gate, [ 1, 0.5, 2 ], [0.4, 0.3, 0.3])),
		(TWChoose.kr(gate, [ 1, 0.5, 2 ], [0.3, 0.3, 0.4]))
	]), 4.0, TRand.kr(0.3, 0.8, gate));

	fb = LocalIn.ar(2);
	fb = DelayC.ar(fb, 0.3, 0.003);

	fb = fb * SinOsc.ar(70/140);
	fb = BPF.ar(fb, [146, 293]);
	fb = fb * fbDamp;

	snd = snd + fb;

	snd = snd + LFTri.ar(freq * TWChoose.kr(gate, [0.5, 1, 3], [0.97, 0.02, 0.01])) * LFNoise2.kr(60/140).range(-10, -2).dbamp;

	buzz = snd;

	buzz = buzz + (BPF.ar( { WhiteNoise.ar } ! 2, 8210, 0.3) * -20.dbamp);
	buzz = (buzz + 0.3).sign - buzz;
	buzz = buzz + DelayC.ar(buzz, 0.2, SinOsc.ar(0.3, [0, pi]).linlin(-1, 1, 0, 1) * 1e-3);
	buzz = buzz * Env.asr(0, 1, 0.5).ar(Done.none, gate);


	buzz = (buzz * 6).wrap2;
	buzz = LeakDC.ar(buzz);
	buzz = HPF.ar(buzz, LFNoise2.kr(5/140).range(600, 800)) * -14.dbamp;
	buzz = BPeakEQ.ar(buzz, 3120, 0.3, 3);
	buzz = GVerb.ar(buzz, 5, TRand.kr(0, 10, gate)) * -10.dbamp;


	snd = BLowShelf.ar(snd, 300, 1, 10);
	snd = BHiShelf.ar(snd, 4186*1.5, 0.9, -10);
	snd = (snd * 5 * [1, -1]).tanh + buzz;
	snd = BLowShelf.ar(snd, 300, 1, 10);
	snd = BHiShelf.ar(snd, 4186*1.5, 1, 5);

	snd = LeakDC.ar(snd);
	snd = BPeakEQ.ar(snd, 293*2, 1.0, 4);
	snd = TWChoose.ar(gate, [LPF.ar(snd, LFNoise2.kr(140/60).clip2.range(200, 18000)), RLPF.ar(snd, LFNoise2.kr(140/30).clip2.range(200, 4000), 0.6)], [0.95, 0.05]);
	LocalOut.ar(snd);
	snd = HPF.ar(snd, Line.ar(80, 60, 10/140));
	snd = LPF.ar(snd, Line.ar(8000, 1500, 30/140));

	snd = snd * Env.asr(0, 1, 0.15, curve: 4).ar(Done.freeSelf, Impulse.kr(0) + gate);
	snd = snd * \amp.kr(1) * -26.dbamp;
	snd = Limiter.ar(snd);
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\gun, {
	var snd, fb, delayTime;


	delayTime = 60/140;

	snd = SinOsc.ar(60 * [1, 1.1001]);
	snd = snd + Hasher.ar(Sweep.ar);

	fb = (LocalIn.ar(2) * -10.dbamp);
	fb = DelayC.ar(fb, 1.0, delayTime - ControlDur.ir);

	snd = snd + (fb * -5.dbamp);

	snd = snd + PitchShift.ar(snd, 1.3, 0.01);

	snd = BLowShelf.ar(snd, 300, 1, 30);
	snd = BHiShelf.ar(snd, 4000, 1, 16);
	snd = snd + (snd * 5).tanh;
	snd = BLowShelf.ar(snd, 300, 1, -10);
	snd = BHiShelf.ar(snd, 4000, 1, -10);


	LocalOut.ar(snd);

	snd = snd * Env.perc(0.0, 1.0).ar(Done.freeSelf);
	snd = snd * \amp.kr(1) * -15.dbamp;

	Out.ar(\out.kr(0), snd);
}).add;


SynthDef(\gun2, {
	var snd, buf;
	buf = b.gun;

	snd = PlayBuf.ar(
		numChannels: 1,
		bufnum: buf,
		rate: BufRateScale.ir(buf) * \rate.ir(1),
	);

	snd = snd + (GVerb.ar(snd, 10, 3) * -20.dbamp);
	snd = BLowShelf.ar(snd, 300, 1, 19);
	snd = BHiShelf.ar(snd, 4000, 1, 10);
	snd = snd + (snd * 2).tanh;
	snd = BLowShelf.ar(snd, 300, 1, -10);
	snd = BHiShelf.ar(snd, 4000, 1, -10);
	snd = snd ! 2;
	snd = snd * \amp.kr(1) * -12.dbamp;
	Out.ar(\out.kr(0), snd);
}).add;


SynthDef(\kick, {
	var snd, clickDuration;
	clickDuration = 2e-3;

	snd = SinOsc.ar(65 * [-1, 1].midiratio * (1 + (7 * Env.perc(0.001, 0.03).ar))
		* (1 + (0.5 * Env.perc(0.001, 0.5).ar)));

	snd = Select.ar(Sweep.ar > clickDuration, [ Hasher.ar(Sweep.ar), DelayC.ar(snd, clickDuration, clickDuration)]);

	snd = snd + (GVerb.ar(snd.sum, 12, 3, damping: 0.3) * -21.dbamp);

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
	var snd, fb, delayTime;
	delayTime = \delay.kr(20/140);
	snd = SinOsc.ar(Env.perc(0, 0.1).ar.linexp(0, 1, 40, 440) * XLine.ar(1.3, 1, 0.01));

	fb = (LocalIn.ar(2) * -5.dbamp);
	fb = DelayC.ar(fb, 1.0, delayTime - ControlDur.ir);

	snd = snd + (fb * -3.dbamp);

	snd = snd.tanh;
	snd = snd + (SinOsc.ar(XLine.ar(3000, 100, 0.01)) * Env.perc(0.001, 0.01).ar * 3.dbamp);
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar + [0, 1]), 1220, 0.5) * Env.perc(0.01, 0.03).ar * -3.dbamp);
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar + [0, 1]), 2520, 0.5) * Env.perc(0.05, 0.1).ar * -3.dbamp);
	snd = snd + GVerb.ar(snd.sum * -25.dbamp, 30, 2);
	snd = snd + PitchShift.ar(snd, 0.053, 1.5);
	snd = snd + PitchShift.ar(snd, 1.03, 0.05);

	snd = RHPF.ar(snd, 200 * XLine.ar(1, 3, 0.01));

	LocalOut.ar(snd);

	snd = snd * \amp.kr(1) * -5.dbamp;
	snd = snd * Env.linen(0.0, \duration.kr(2.5 * (60/140)), 0.1, curve: -4).ar(Done.freeSelf);
	Out.ar(\out.kr(0), snd);
}).add;


SynthDef(\guitar, {
	var snd, fb, gate, dur;

	gate = \gate.kr(1);
	dur  = \duration.kr(1);

	snd = Pluck.ar(
		PinkNoise.ar * Env.asr(0.0001, 1.0, 0.1).ar(Done.freeSelf, Impulse.kr(0) + gate),
		Impulse.ar(140/30) + Dust.ar(1),
		1,
		\freq.kr(293).reciprocal,
		18.0,
		XLine.kr(0.85, 0.45, dur)
	);

	fb = LocalIn.ar(2);
	fb = DelayC.ar(fb, 0.2, 0.03);
	fb = fb * -9.dbamp;
	fb = LPF.ar(fb, 349);
	snd = snd + fb;

	snd = snd * -4.dbamp;

	snd = LeakDC.ar(snd);

	snd = BLowShelf.ar(snd, 293, 0.8, -10);
	snd = BHiShelf.ar(snd, 2349, 1, -10);
	snd = (snd * 6).tanh;
	snd = BLowShelf.ar(snd, 293, 1, 3);
	snd = BHiShelf.ar(snd, 2349, 1, 3);

	snd = snd + (GVerb.ar(snd.sum, 22, 0.2, damping:0.001) * -18.dbamp);

	snd = RLPF.ar(snd, XLine.kr(698, 4186, dur) + (3 * SinOsc.ar(15/140)), XLine.kr(0.8, 0.4, dur));
	snd = HPF.ar(snd, 123);
	LocalOut.ar(snd);

	snd = snd * -14.dbamp;
	snd = Limiter.ar(snd);
	Out.ar(\out.kr(0), snd);
}).add;

)

Synth(\guitar, [ freq: 38.midicps, dur: 3.0 ]);
Synth(\kick);
Synth(\kick2);
Synth(\snare);
Synth(\gun);
Synth(\gun2);

(
var s, bpm, beat, root, play, section1, section2;
s = Server.default;
bpm = 140;
beat = 60 / bpm;

root = 38; // d0


play = { |synthDef, duration, args|
	var synth;
	s.bind { synth = Synth(synthDef, args ++ [duration: duration]) };
	duration.wait;
	s.bind { synth.set(\gate, 0) };

};

section1 = Routine({
	var bass, drums, gun, guitar;

	bass = {
		Routine({
			// m1
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

			// m2
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

			// m3
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

			// m4
			play.(\bass, beat * 1, [ freq: root.midicps ]);
			play.(\bass, beat * 0.5, [ freq: root.midicps ]);
			(beat* 0.5).wait;
			play.(\bass, beat * 1.5, [ freq: (root + 3).midicps, fbDamp: -13.dbamp ]);
			play.(\bass, beat * 0.75, [ freq: root.midicps ]);
			(beat * 0.25).wait;
			play.(\bass, beat * 0.5, [ freq: root.midicps ]);
			play.(\bass, beat * 1, [ freq: (root + 5).midicps, fbDamp: -12.dbamp ]);
			play.(\bass, beat * 0.45, [ freq: (root + 3).midicps, amp:0.9 ]);
			(beat * 0.05).wait;
			play.(\bass, beat * 0.45, [ freq: (root + 5).midicps, amp:0.85 ]);
			(beat * 0.05).wait;

			// m5
			play.(\bass, beat * 1, [ freq: root.midicps, amp: 0.9 ]);
			play.(\bass, beat * 0.5, [ freq: root.midicps, amp: 0.9 ]);
			(beat* 0.5).wait;
			play.(\bass, beat * 1.5, [ freq: (root + 3).midicps, amp: 0.9, fbDamp: -12.dbamp ]);
			play.(\bass, beat * 0.75, [ freq: root.midicps, amp: 0.9 ]);
			(beat * 0.25).wait;
			play.(\bass, beat * 0.5, [ freq: root.midicps, amp: 0.9 ]);
			play.(\bass, beat * 0.70, [ freq: (root + 3).midicps, amp: 0.9, fbDamp: -14.dbamp ]);
			(beat * 0.30).wait;
			play.(\bass, beat * 1, [ freq: (root + 3).midicps, amp: 0.9, fbDamp: -14.dbamp]);

			// m6
			play.(\bass, beat * 1, [ freq: root.midicps ]);
			play.(\bass, beat * 0.5, [ freq: root.midicps ]);
			(beat* 0.5).wait;
			play.(\bass, beat * 1.5, [ freq: (root + 3).midicps, fbDamp: -12.dbamp ]);
			play.(\bass, beat * 0.75, [ freq: root.midicps ]);
			(beat * 0.25).wait;
			play.(\bass, beat * 0.5, [ freq: root.midicps ]);
			play.(\bass, beat * 0.45, [ freq: (root + 5).midicps ]);
			(beat * 0.05).wait;
			play.(\bass, beat * 0.45, [ freq: (root + 3).midicps ]);
			(beat * 0.05).wait;
			play.(\bass, beat * 0.45, [ freq: (root + 5).midicps ]);
			(beat * 0.05).wait;
			play.(\bass, beat * 0.47, [ freq: (root + 7).midicps ]);
			(beat * 0.03).wait;

			// m7
			play.(\bass, beat * 1, [ freq: root.midicps, amp: 0.9 ]);
			play.(\bass, beat * 0.5, [ freq: root.midicps, amp: 0.9 ]);
			(beat* 0.5).wait;
			play.(\bass, beat * 1.5, [ freq: (root + 3).midicps, amp: 0.9, fbDamp: -11.dbamp ]);
			play.(\bass, beat * 0.75, [ freq: root.midicps, amp: 0.9 ]);
			(beat * 0.25).wait;
			play.(\bass, beat * 0.5, [ freq: root.midicps, amp: 0.9 ]);
			play.(\bass, beat * 0.70, [ freq: (root + 3).midicps, amp: 0.9 ]);
			(beat * 0.30).wait;
			play.(\bass, beat * 1, [ freq: (root + 3).midicps, amp: 0.9 ]);

			// m8
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
		});
	};

	drums = {
		Routine({
			// m1
			s.bind { Synth(\kick2) };
			(beat * 2).wait;
			s.bind { Synth(\snare, [  delay: 30/140  ]) };
			(beat * 0.5).wait;
			s.bind { Synth(\snare, [ delay: 0, amp: 0.2 ]) };
			(beat * 1.0).wait;
			s.bind { Synth(\kick, [ delay: 0, amp: 0.4 ]) };
			(beat * 0.5).wait;
			s.bind { Synth(\kick2, [ delay: 0, amp: 0.3 ]) };
			s.bind { Synth(\kick, [ amp: [0.4, 0.1, 0.5].choose ]) };
			(beat * 0.5).wait;
			s.bind { Synth(\kick, [ amp: [0.8, 0.6, 0].choose ]) };
			(beat * 0.5).wait;
			(beat * 1).wait;
			s.bind { Synth(\snare, [ delay: 30/140 ]) };
			beat.wait;

			// m2
			s.bind { Synth(\kick) };
			(beat * 2).wait;
			s.bind { Synth(\snare, [ delay: 25/140 ]) };
			(beat * 2).wait;
			s.bind { Synth(\kick2) };
			(beat * 2.5).wait;
			s.bind { Synth(\snare, [ delay: 10/140 ]) };
			(beat * 0.5).wait;

			// m3
			s.bind { Synth(\kick2) };
			(beat * 2).wait;
			s.bind { Synth(\snare, [ delay: 20/140 ]) };
			(beat * 2).wait;
			s.bind { Synth(\kick, [ amp: [0.4, 0.1, 0.5].choose ]) };
			(beat * 0.5).wait;
			s.bind { Synth(\kick, [ amp: [0.8, 0.6, 0].choose ]) };
			(beat * 0.5).wait;
			(beat * 1).wait;
			s.bind { Synth(\snare, [ delay: 30/140 ]) };
			beat.wait;

			// m4
			s.bind { Synth(\kick) };
			(beat * 2).wait;
			s.bind { Synth(\snare, [ delay: 25/140 ]) };
			(beat * 2).wait;
			s.bind { Synth(\kick2) };
			(beat * 2.5).wait;
			s.bind { Synth(\snare, [ delay: 10/140 ]) };
			(beat * 0.5).wait;

			// m5
			s.bind { Synth(\kick) };
			(beat * 2).wait;
			s.bind { Synth(\snare, [ delay: 25/140 ]) };
			(beat * 2).wait;
			s.bind { Synth(\kick2) };
			(beat * 2.5).wait;
			s.bind { Synth(\snare, [ delay: 10/140 ]) };
			(beat * 0.5).wait;

			// m6
			s.bind { Synth(\kick) };
			(beat * 2).wait;
			s.bind { Synth(\snare, [ delay: 25/140 ]) };
			(beat * 2).wait;
			s.bind { Synth(\kick2) };
			(beat * 2.5).wait;
			s.bind { Synth(\snare, [ delay: 10/140 ]) };
			(beat * 0.5).wait;

			// m7
			s.bind { Synth(\kick) };
			(beat * 2).wait;
			s.bind { Synth(\snare, [ delay: 25/140 ]) };
			(beat * 2).wait;
			s.bind { Synth(\kick2) };
			(beat * 2.5).wait;
			s.bind { Synth(\snare, [ delay: 10/140 ]) };
			(beat * 0.5).wait;

			// m8
			s.bind { Synth(\kick) };
			(beat * 2).wait;
			s.bind { Synth(\snare, [ delay: 25/140 ]) };
			(beat * 2).wait;
			s.bind { Synth(\kick2) };
			(beat * 2.5).wait;
			s.bind { Synth(\snare, [ delay: 20/140 ]) };
			(beat * 0.5).wait;
		});
	};


	gun = {
		Routine({
			// m1
			s.bind { Synth(\gun2, [ rate: 0.55, amp: 0.6 ]) };
			(beat * 14).wait;

			// m3
			s.bind { Synth(\gun2, [ rate: 0.6, amp: 0.6 ]) };
			(beat * 14).wait;

			// m5
			s.bind { Synth(\gun2, [ rate: 0.4444, amp: 0.7 ]) };
			(beat * 14).wait;

			// m7
			s.bind { Synth(\gun2, [ rate: 0.625, amp: 0.7 ]) };
		});
	};

	guitar = {
		Routine({
			// m1 - m4
			(beat * 28).wait;

			// m5
			play.(\guitar, beat*6.9, [ freq: root.midicps ]);
			(beat * 0.1).wait;

			// m6
			play.(\guitar, beat*6.9, [ freq: (root + 2).midicps ]);
			(beat * 0.1).wait;

			// m7
			play.(\guitar, beat*6.9, [ freq: (root + 3).midicps ]);
			(beat * 0.1).wait;

			// m8
			play.(\guitar, beat*6.9, [ freq: (root + 5).midicps ]);
			(beat * 0.1).wait;
		});
	};

	bass.().play;
	drums.().play;
	gun.().play;
	guitar.().play;
});

section2 = Routine({
	var bass;

	bass = {
		Routine({
			// m9
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 5).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 3).midicps ]);

			// m10
			play.(\bass, beat * 1.0, [ freq: (root - 2).midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 5).midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 7).midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root - 5).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 5).midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 3).midicps ]);

			// m11
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 5).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 3).midicps ]);

			// m12
			play.(\bass, beat * 1.0, [ freq: (root - 2).midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 5).midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 7).midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root - 5).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 7).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 5).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 3).midicps ]);


			// m13
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root - 5).midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root - 2).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root - 5).midicps ]);

			// m14
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 12).midicps ]);
			play.(\bass, beat * 0.5, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 5).midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 7).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 7).midicps ]);
			(beat * 0.5).wait;
			play.(\bass, beat * 1.0, [ freq: (root + 7).midicps ]);
			(beat * 0.5).wait;

			// m15
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 5).midicps ]);
			play.(\bass, beat * 0.5, [ freq: root.midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root - 5).midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root - 2).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 3).midicps ]);

			// m16
			play.(\bass, beat * 1.0, [ freq: (root - 2).midicps ]);
			play.(\bass, beat * 1.0, [ freq: root.midicps ]);
			play.(\bass, beat * 1.0, [ freq: (root + 3).midicps ]);
			play.(\bass, beat * 0.5, [ freq: (root + 5).midicps ]);
			play.(\bass, beat * 1.5, [ freq: (root + 7).midicps ]);
			(beat * 0.5).wait;
			play.(\bass, beat * 0.5, [ freq: (root + 7).midicps ]);
			(beat * 0.5).wait;
			play.(\bass, beat * 0.5, [ freq: (root + 7).midicps ]);
		});
	};

	bass.().play;
});

Routine({

	//section2.play;
	//(beat * (7 * 8)).wait;
	section1.play;
	(beat * (7 * 8)).wait;
	section1.reset;
	section2.play;
}).play;
)
