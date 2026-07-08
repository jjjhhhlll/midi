s.boot;

(
var lfo;

lfo = { |rate|
	LFNoise2.kr(rate) + LFNoise2.kr(rate * 2) + TRand.kr(-1, 1, Dust.kr(rate)).lag(0.01);
};

SynthDef(\guitar, {
	var snd, fb, trigger, exciter;
	trigger = Impulse.ar(Line.kr(2, 20, 600) * (2 ** (LFNoise2.kr(3) * Line.kr(0, 0.3, 60))));
	//trigger = Impulse.ar(2);
	exciter = SinOsc.ar(Env.perc(0, 0.01).ar(gate: trigger).linexp(0, 1, 100, TExpRand.ar(3000,16000, trigger))) * Env.perc(0.0, 0.05).ar(gate: trigger);

	snd = Pluck.ar(exciter, trigger, 0.2, 1 / (\freq.kr(50) * [1, 2, 3] * (({ lfo.(1) } ! 3) * 0.1).midiratio), Line.kr(0.01, 10.0, 60), 0.95);
	snd = snd.sum;

	snd = snd ! 2;

	fb = LocalIn.ar(2);
	fb = DelayC.ar(fb, 0.2, 0.003 * (lfo.(1) * 10).midiratio * ExpRand(0.1, 1.0));
	fb = fb * lfo.(1).linlin(-1, 1, -20, -40).dbamp;

	snd = snd + fb;

	snd = LeakDC.ar(snd);
	snd = snd * Line.ar(0, 1, 30).squared;

	snd = BLowShelf.ar(snd, 200 * ExpRand(0.7, 1.0), 1, -5 + lfo.(0.1));
	snd = BHiShelf.ar(snd, 3200 * ExpRand(0.7, 1.0), 1, -5 + lfo.(0.1));

	// 60
	snd = (snd * MouseY.kr(1, 80)).tanh;

	snd = BLowShelf.ar(snd, 200 * ExpRand(0.7, 1.0), 1, 3 + lfo.(0.1));
	snd = BHiShelf.ar(snd, 3000 * ExpRand(0.7, 1.0), 1, 5 + lfo.(0.1));

	snd = DelayC.ar(snd, 0.2, LFNoise2.kr(3 ! 2).linlin(-1, 1, 0, 1) * 1e-3 * ExpRand(0.7, 1.0)) + GVerb.ar(snd.sum * -10.dbamp, ExpRand(10, 20), 3, 0.7);
	LocalOut.ar(snd);

	snd = BHiShelf.ar(snd, 3200, 1, -10);

	snd = LPF.ar(snd, Line.kr(16000, 10, 600));

	snd = Balance2.ar(snd[0], snd[1], \pan.kr(0));

	snd = snd * -9.dbamp;

	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\fx, {
	var snd;
	snd = In.ar(\out.kr(0), 2);
	snd = LeakDC.ar(snd);
	snd = snd + GVerb.ar(snd.sum * -30.dbamp, 60, 1, damping: 0.7);
	snd = Limiter.ar(snd, MouseX.kr(0.7, 1.0));

	ReplaceOut.ar(\out.kr(0), snd);

}).add;
)

(
var s;
s = Server.default;

Routine({
	s.bind { Synth.tail(nil, \fx) };
	(0..4).normalize.linlin(0, 1, -0.7, 0.7).do { |pan, i|
		s.bind { Synth(\guitar, [pan: pan, freq: 25 * [4, 2, 1, 2, 4][i]]) };
	}
}).play;
)