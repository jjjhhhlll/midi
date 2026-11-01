// suspicious key
(
s.options.memSize = 8192 * 4;
s.boot;
)

(
SynthDef(\fmbell, {
	var freq, duration, index, amp, pan, cRatio, mRatio, mod, car, env, indexEnv;
	freq = \freq.kr(500);
	duration = \duration.kr(60/88);
	index = \index.kr(8);
	amp = \amp.kr(0.5);
	pan = \pan.kr(-0.4);
	cRatio = \cRatio.kr(1);
	mRatio = \mRatio.kr(2.45);

	env = Env.perc(0.005, duration * 2.5).kr(Done.freeSelf);
	indexEnv = Env.perc(0.001, (duration * 2.5)/2).kr * index;
	mod = SinOsc.ar(freq * mRatio) * (freq * indexEnv);
	car = SinOsc.ar((freq * cRatio) + mod) * env * amp;
	car = car + (PitchShift.ar(car, duration/3, 2.04, 0.03, 0) * -27.dbamp);
	car = car + (GVerb.ar(car * -8.dbamp, 20, 3) * -5.dbamp).sum;
	car = car * -10.dbamp;
	car = Pan2.ar(car, pan);
	Out.ar(\out.kr(0), car);
}).add;

SynthDef(\woodblock, {
	var freq, duration, snd, env, pan, mix;

	freq = \freq.kr(400);
	duration = \duration.kr(60/88);
	pan = \pan.kr(0);
	mix = [1.0, 1.0, 0.07];

	snd = Hasher.ar(Sweep.ar + [0, 1]) * Env.perc(0.001, 0.117, 1, -4).ar;

	snd = BPF.ar(snd, [921, 2156].choose, [0.3, 0.5].choose);
	snd = snd + SinOsc.ar(freq * [1.0, 1.01, 4.0]) * mix * Env.perc([0.001, 0.0111, 0.05], [duration/4, duration/3.9, duration/12], 1, -4).kr();
	snd = snd.sum;
	snd = (snd * 5.dbamp).tanh;

	snd = snd + ((GVerb.ar(snd * -8.dbamp, 20, 4)).sum * Env.perc(0, duration, 1, -4).kr(Done.freeSelf));

	snd = snd * -29.dbamp;

	snd = Pan2.ar(snd, pan);
	Out.ar(\out.kr(0), snd);
}).add;
)

(
SynthDef(\synthbass, {
	var freq, amp, duration, pan, gate, attackEnv, attack, snd;

	freq = \freq.kr(440);
	amp = \amp.kr(1.0);
	duration = \duration.kr(60/88);
	pan = \pan.kr(0);
	gate = \gate.kr(1);

	attackEnv = Env.perc(0, 60/88/12, 1.0, -4).ar;
	attack = freq + (freq * 20 * attackEnv);
	snd = Mix.new([
		Saw.ar(attack * 0.5, 0.6),
		Pulse.ar(attack, Line.ar(0.5, 0.01, duration/3), 0.4)
	]);
	snd = RLPF.ar(snd, XLine.ar(8000, 100, duration),  XLine.ar(1.0, 0.3, duration));
	snd = snd * amp;
	snd = (snd * 10).tanh;
	snd = snd * -15.dbamp;
	snd = snd * Env.linen(0.01, (duration/3)*2, duration/3).ar(Done.freeSelf);
	snd = snd + (GVerb.ar(snd * -25.dbamp, 20, 3));

	Out.ar(\out.kr(0), Pan2.ar(snd, pan));

}).add;
)

Synth(\synthbass, [ freq: 42.midicps, duration: (60/88)*4, amp: 0.1 ]);
Synth(\synthbass, [ freq: 35.midicps, duration: (60/88)*4 ]);
Synth(\synthbass, [ freq: 41.midicps, duration: (60/88)*4 ]);
Synth(\synthbass, [ freq: 38.midicps, duration: (60/88)*4 ]);

(
Routine({
	var s;
	s = Server.default;
	loop {
		s.bind { Synth(\woodblock, [freq: 800, duration: (60/88) ]) };
		(60/88).wait;
		s.bind { Synth(\woodblock, [freq: 1574, duration: (60/88)*2]) };
		(60/88).wait;
	};
}).play;
)

Synth(\fmbell, [freq: 76.midicps, mRatio: 3.45, index: 1, pan: -1]);
Synth(\fmbell, [freq: 93.midicps, mRatio: 3.45, index: 10, amp: 0.08 ]);


Synth(\fmbell, [freq: 400, mRatio: 3.45, index: 9]);


(
var s, bpm, beat, beat3, play;
s = Server.default;
bpm = 88;
beat = 60 / bpm;
beat3 = beat / 3;


play = { |synthDef, duration, args = #[]|
	s.bind { Synth(synthDef, args ++ [duration: duration]) };
	duration.wait;
};

Routine({

	fork {
		// celesta
		var highi, lowi, mratio;
		highi = { [26, 28, 32].choose };
		lowi = { [44, 46, 26, 50].choose };
		mratio = { rrand(10.1, 16.1) };

		// m1
		play.(\fmbell, beat3 * 2, [ freq: 76.midicps, mRatio: mratio.(), index: highi.() ]);
		play.(\fmbell, beat3, [ freq: 67.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3 * 2, [ freq: 76.midicps, mRatio: mratio.(), index: highi.() ]);
		play.(\fmbell, beat3, [ freq: 67.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3 * 2, [ freq: 78.midicps, mRatio: mratio.(), index: highi.(), amp:0.2 ]);
		play.(\fmbell, beat3, [ freq: 67.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3 * 2, [ freq: 78.midicps, mRatio: mratio.(), index: highi.(), amp: 0.2]);
		play.(\fmbell, beat3, [ freq: 67.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		// m2
		play.(\fmbell, beat3*2,  [ freq: 74.midicps, mRatio: mratio.(), index: highi.()]);
		play.(\fmbell, beat3, [ freq: 67.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3*2,  [ freq: 73.midicps, mRatio: mratio.(), index: highi.()]);
		play.(\fmbell, beat3, [ freq: 66.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3*2,  [ freq: 71.midicps, mRatio: mratio.(), index: highi.()]);
		play.(\fmbell, beat3, [ freq: 67.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3*2,  [ freq: 70.midicps, mRatio: mratio.(), index: highi.()]);
		play.(\fmbell, beat3, [ freq: 69.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		// m3
		play.(\fmbell, beat3*2,  [ freq: 76.midicps, mRatio: mratio.(), index: highi.() ]);
		play.(\fmbell, beat3, [ freq: 67.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3*2,  [ freq: 76.midicps, mRatio: mratio.(), index: highi.() ]);
		play.(\fmbell, beat3, [ freq: 67.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3*2,  [ freq: 78.midicps, mRatio: mratio.(), index: highi.() ]);
		play.(\fmbell, beat3, [ freq: 66.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3*2,  [ freq: 78.midicps, mRatio: mratio.(), index: highi.()]);
		play.(\fmbell, beat3, [ freq: 69.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		// m4
		play.(\fmbell, beat3*2,  [ freq: 74.midicps, mRatio: mratio.(), index: highi.()]);
		play.(\fmbell, beat3, [ freq: 67.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3*2,  [ freq: 70.midicps, mRatio: mratio.(), index: highi.()]);
		play.(\fmbell, beat3, [ freq: 69.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3*2,  [ freq: 73.midicps, mRatio: mratio.(), index: highi.() ]);
		play.(\fmbell, beat3, [ freq: 67.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);

		play.(\fmbell, beat3*2,  [ freq: 71.midicps, mRatio: mratio.(), index: highi.()]);
		play.(\fmbell, beat3, [ freq: 70.midicps, mRatio: mratio.(), index: lowi.(), amp: 0.1 ]);
	};
	fork {
		// bell
		var index = { [5, 7, 9, 15].choose };
		var mratio = { [1.45, 2.45, 3.45 ].choose };

		// m1
		beat3.wait;
		play.(\fmbell, beat3, [freq: 93.midicps, mRatio: mratio.(), index: index.(), amp: 0.015, pan: 0.5]);

		(beat3*2).wait;
		play.(\fmbell, beat3, [freq: 93.midicps, mRatio: mratio.(), index: index.(), amp: 0.015, pan: 0.5]);

		(beat3*2).wait;
		play.(\fmbell, beat3, [freq: 93.midicps, mRatio: mratio.(), index: index.(), amp: 0.015, pan: 0.5]);

		(beat3*2).wait;
		play.(\fmbell, beat3, [freq: 93.midicps, mRatio: mratio.(), index: index.(), amp: 0.015, pan: 0.5]);
		(beat3).wait;

		// m2
		beat3.wait;
		play.(\fmbell, beat3*2, [freq: 90.midicps, mRatio: mratio.(), index: index.(), amp: 0.015, pan: 0.5]);

		(beat3).wait;
		play.(\fmbell, beat3*2, [freq: 91.midicps, mRatio: mratio.(), index: index.(), amp: 0.015, pan: 0.5]);

		(beat3).wait;
		play.(\fmbell, beat3*2, [freq: 90.midicps, mRatio: mratio.(), index: index.(), amp: 0.015, pan: 0.5]);

		(beat3).wait;
		play.(\fmbell, beat3, [freq: 90.midicps, mRatio: mratio.(), index: index.(), amp: 0.015, pan: 0.5]);
		(beat3).wait;

		// m3
		beat3.wait;
		play.(\fmbell, beat3, [freq: 93.midicps, mRatio: mratio.(), index: index.(), amp: 0.018, pan: 0.5]);

		(beat3*2).wait;
		play.(\fmbell, beat3, [freq: 93.midicps, mRatio: mratio.(), index: index.(), amp: 0.018, pan: 0.5]);

		(beat3*2).wait;
		play.(\fmbell, beat3, [freq: 94.midicps, mRatio: mratio.(), index: index.(), amp: 0.018, pan: 0.5]);

		(beat3*2).wait;
		play.(\fmbell, beat3, [freq: 94.midicps, mRatio: mratio.(), index: index.(), amp: 0.018, pan: 0.5]);
		beat3.wait;

		// m4
		beat3.wait;
		play.(\fmbell, beat3, [freq: 95.midicps, mRatio: mratio.(), index: index.(), amp: 0.02, pan: 0.5]);

		(beat3*2).wait;
		play.(\fmbell, beat3, [freq: 90.midicps, mRatio: mratio.(), index: index.(), amp: 0.02, pan: 0.5]);

		(beat3*2).wait;
		play.(\fmbell, beat3, [freq: 95.midicps, mRatio: mratio.(), index: index.(), amp: 0.018, pan: 0.5]);

		(beat3*2).wait;
		play.(\fmbell, beat3, [freq: 95.midicps, mRatio: mratio.(), index: index.(), amp: 0.018, pan: 0.5]);
		beat3.wait;
	};
	fork {
		// woodblock

		// m1
		(beat * 3).wait;
		beat3.wait;
		play.(\woodblock, beat3, [ freq: 800 ]);
		beat3.wait;

		// m2
		play.(\woodblock, beat3, [ freq: 800 ]);
		(beat3 *2).wait;
		(beat * 2).wait;
		beat3.wait;
		play.(\woodblock, beat3, [ freq: 800 ]);
		beat3.wait;

		// m3
		play.(\woodblock, beat3, [ freq: 800 ]);
		(beat3 *2).wait;
		(beat * 2).wait;
		play.(\woodblock, beat3, [ freq: 800 ]);
		(beat3 * 2).wait;

		// m4
		play.(\woodblock, beat3, [ freq: 800 ]);
		(beat3 *2).wait;
		(beat * 2).wait;
		beat3.wait;
		play.(\woodblock, beat3, [ freq: 800 ]);
		beat3.wait;
	};
	fork {
		// synthbass
		// todo: put in rests once other stuff is synced up
		// m5
		play.(\synthbass, beat*4, [ freq: 42.midicps, amp: 0.7 ]);
		play.(\synthbass, beat*4, [ freq: 35.midicps, amp: 0.75 ]);
		play.(\synthbass, beat*4, [ freq: 41.midicps, amp: 0.7 ]);
		play.(\synthbass, beat*4, [ freq: 38.midicps, amp: 0.7 ]);
	}

}).play;
)
