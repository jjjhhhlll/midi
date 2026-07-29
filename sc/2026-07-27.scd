// from https://www.youtube.com/watch?v=7vwksSWMSIM&list=PLELlGNnfZwb24FQv4nWhczfj0dWvn1EzM&index=38
(
s.quit;
s.options.memSize = 65536;
s.boot;
)

(
SynthDef(\kick, {
	var snd;
	snd = SinOsc.ar(Env.perc(0, 0.1).ar.linexp(0, 1, 40, 700) * XLine.ar(2, 1, 0.01));
	snd = snd * Env.perc(0.001, 0.6).ar;
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar + [0, 1]), 6120, 0.3) * Env.perc(0.02, 0.01).ar * -1.dbamp);
	snd = snd * (1 + Env.perc(0.001, 0.1).ar);
	snd = snd.tanh;

	snd = snd * -3.dbamp;
	snd = snd * Env.linen(0.0, 0.5, 0.1, curve: -4).ar(Done.freeSelf);
	Out.ar(\out.kr(0), snd);
}).add;


SynthDef(\snare, {
	var snd;
	snd = SinOsc.ar(Env.perc(0, 0.1).ar.linexp(0, 1, 230, 400) * XLine.ar(1.3, 1, 0.01) * [1, 2.3, 5.7]);
	snd = snd * Env.perc(0.001, [0.1, 0.05, 0.02]).ar;
	snd = snd * [0, -8, -12].dbamp;
	snd = snd.sum;
	snd = snd.tanh;
	snd = snd + (SinOsc.ar(XLine.ar(3000, 100, 0.01)) * Env.perc(0.001, 0.01).ar * 3.dbamp);
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar + [0, 1]), 1220, 0.5) * Env.perc(0.01, 0.03).ar * -3.dbamp);
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar + [0, 1]), 2520, 0.5) * Env.perc(0.05, 0.1).ar * -3.dbamp);
	snd = snd + GVerb.ar(snd.sum * -30.dbamp, 30, 1);
	snd = snd + PitchShift.ar(snd, 0.053, 1.5);
	snd = snd * 1.dbamp;
	snd = snd * Env.linen(0.0, 0.5, 0.1, curve: -4).ar(Done.freeSelf);
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\hat, {
	var snd;
	snd = { WhiteNoise.ar } ! 5;
	snd = CombC.ar(snd, 0.2, 1 / [123, 234, 42, 66], 1.0).sum;
	snd = LeakDC.ar(snd);
	snd = FreqShift.ar(snd, 45);
	snd = snd * Env.perc(0.001, 1.0).ar;
	snd = LPF.ar(snd, XLine.ar(16e3, 1e3, 5.0));
	snd = BPF.ar(snd, (0..20).pow(0.5).normalize.linexp(0, 1, 1000, 8000), 0.05).sum;
	snd = BHiShelf.ar(snd, 4334, 0.3, -3);
	snd = snd + (SinOsc.ar(XLine.ar(16000, 1000, 0.005)) * Env.perc(0.001, 0.005).ar * 3.dbamp);
	snd = snd + GVerb.ar(snd, 30, 3);

	snd = snd * -26.dbamp;

	snd = snd * Env.linen(0.0, 5.5, 0.1, curve: -4).ar(Done.freeSelf);
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\fx, {
	var snd, wet, fb, trigger;
	snd = In.ar(\out.kr(0), 2);
	trigger = T2A.ar(\trigger.tr);
	wet = snd;
	fb = LocalIn.ar(2);
	fb = DelayC.ar(fb, 1.0, TRand.ar(0, 0.2, trigger).lag(0.5));
	// fb = fb * -10.dbamp;
	fb = fb * MouseX.kr(-10, 10, 0).dbamp;
	fb = LeakDC.ar(fb);
	fb = Limiter.ar(fb);
	wet = wet + fb;
	wet = wet + GVerb.ar(wet.sum * -15.dbamp, 30, MouseY.kr(1, 5, 1));
	wet = wet + PitchShift.ar(wet, 0.1, SinOsc.ar(TExpRand.ar(0.3, 6, trigger)).linexp(-1, 1, 0.5, 3));
	wet = wet + PitchShift.ar(wet, 0.05, TExpRand.ar(0.5, 2, trigger));
	LocalOut.ar(wet);

	wet = SelectX.ar((TRand.ar(0, 1, trigger) < 0.3), [wet, RLPF.ar(wet, LFNoise2.ar(0.3).linexp(-1, 1, 100, 8000), 0.3)]);

	wet = wet * (1 - (0.5 * Env.perc(0.01, 0.2, curve: 4 ).ar(gate: trigger)));
	snd = snd + wet;
	snd = LeakDC.ar(snd);
	snd = Limiter.ar(snd);
	snd = snd * -4.dbamp;
	ReplaceOut.ar(\out.kr(0), snd);
}).add;
)

(
var s, beat, play, playP;
s = Server.default;
beat = 60 / 140;

playP = { |synthDef, duration, args = #[]|
	s.bind { Synth(synthDef, [duration: duration * beat]) };
};

play = { |synthDef, duration, args = #[]|
	playP.(synthDef, duration, args);
	(duration * beat).wait;
};

Routine({
	var fx, trigger;
	s.bind {
		fx = Synth.tail(nil, \fx, [out: 0]);
	};
	trigger = {
		s.bind {
			fx.set(\trigger, 1)
		};
	};
	loop {
		trigger.();
		play.(\kick, [1, 2].choose);
		play.(\kick, [1, 2].choose);
		play.(\kick, [1, 4].choose);

		trigger.();
		play.(\snare, [1, 5 ].choose);

		trigger.();
		play.(\hat, [1 / 2, 1 / 3].choose);
	};
}).play;
)