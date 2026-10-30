s.boot;

(
SynthDef(\fmbell, {
	var freq, index, amp, pan, cRatio, mRatio, mod, car, env, indexEnv;
	freq = \freq.kr(500);
	index = \index.kr(8);
	amp = \amp.kr(0.3);
	pan = \pan.kr(0);
	cRatio = \cRatio.kr(1);
	mRatio = \mRatio.kr(2.45);

	env = Env.perc(0.005, 2.5).kr(Done.freeSelf);
	indexEnv = Env.perc(0.001, 1.5).kr * index;
	mod = SinOsc.ar(freq * mRatio) * (freq * indexEnv);
	car = SinOsc.ar((freq * cRatio) + mod) * env * amp;
	car = car + PitchShift.ar(car, 0.02, 2, 0.007, 0.1);
	car = car * 0.5.dbamp;
	Out.ar(0, Pan2.ar(car, pan));
}).add;
)

Synth(\fmbell, [freq: 800, mRatio: 2.45, index: 10]);

Synth(\fmbell, [freq: 400, mRatio: 3.45, index: 9]);
