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
	snd = BLowShelf.ar(snd, 200, 0.3, 5);
	snd = snd * 5.dbamp;
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
	snd = snd + GVerb.ar(snd.sum * -25.dbamp, 30, 3);
	snd = snd + PitchShift.ar(snd, 0.053, 1.5);
	snd = snd * 1.dbamp;
	snd = snd * Env.linen(0.0, \duration.kr(0.5), 0.1, curve: -4).ar(Done.freeSelf);
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
	snd = BPF.ar(snd, (0..20).pow(0.5).normalize.linexp(0, 1, 3000, 8000), 0.05).sum;
	snd = BHiShelf.ar(snd, 4334, 0.3, -3);
	snd = snd + (SinOsc.ar(XLine.ar(16000, 1000, 0.005)) * Env.perc(0.001, 0.005).ar * 3.dbamp);
	snd = snd + GVerb.ar(snd, 30, 3);
	snd = snd * -32.dbamp;
	snd = snd * Env.linen(0.0, 5.5, 0.1, curve: -4).ar(Done.freeSelf);
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\clank, {
	var snd;
	snd = SinOsc.ar(\freq.kr(2620) * [0.673, 1, 1.234, 1.667] * XLine.ar(1.3, 1, 0.002));
	snd = snd * Env.perc(0.001, [0.05, 0.3, 0.15, 0.05]).ar;
	snd = snd * ({ Rand(0.5, 1) } ! snd.size);
	snd = snd.sum;
	snd = snd * (1 + (Env.perc(0, 0.01).ar * Rand(0, 1)));
	snd = snd * (1 + (SinOsc.ar(534) * Env.perc(0, 0.1).ar * Rand(0, 1)));
	snd = snd.tanh;
	snd = snd + GVerb.ar(snd * -10.dbamp, 10, 3);
	snd = Balance2.ar(snd[0], snd[1], \pan.kr(0));
	snd = snd + PitchShift.ar(snd, 0.03, 1.5);
	snd = snd * -17.dbamp;
	snd = snd * Env.linen(0.0, 3.5, 1.0, curve: -4).ar(Done.freeSelf);
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\fx, {
	var snd, wet, fb, trigger;
	snd = In.ar(\out.kr(0), 2);
	trigger = T2A.ar(\trigger.tr);
	wet = snd;
	fb = LocalIn.ar(2);
	fb = DelayC.ar(fb, 1.0, TExpRand.ar(0.02, 0.1, trigger).lag(0.05));
	fb = fb * TRand.ar(0, -20, trigger).dbamp.lag(0.01);
	fb = BLowShelf.ar(fb, 200, 0.3, -5);
	fb = BHiShelf.ar(fb, 2000, 0.3, -5);
	fb = LeakDC.ar(fb);
	fb = Limiter.ar(fb);
	wet = wet + fb;
	wet = wet + GVerb.ar(wet.sum * -25.dbamp, 30, 1);
	wet = wet + PitchShift.ar(wet, 0.1, SinOsc.ar(TExpRand.ar(0.3, 6, trigger)).linexp(-1, 1, 0.5, 3));
	wet = wet + PitchShift.ar(wet, 0.05, TExpRand.ar(0.5, 2, trigger));
	LocalOut.ar(wet);

	wet = SelectX.ar((TRand.ar(0, 1, trigger) < 0.3), [wet, RLPF.ar(wet, LFNoise2.ar(0.3).linexp(-1, 1, 100, 8000), 0.5)]);

	wet = wet * (1 - (0.5 * Env.perc(0.01, 0.2, curve: 4 ).ar(gate: trigger)));

	snd = BLowShelf.ar(snd, 200, 0.3, -3);
	snd = BHiShelf.ar(snd, 2000, 0.3, -3);
	snd = (snd * 3).tanh + snd.fold2;
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
var s, beat, play, playP;
s = Server.default;
beat = 60 / 140;

playP = { |synthDef, duration, args = #[]|
	s.bind { Synth(synthDef, [duration: duration * beat] ++ args) };
};

play = { |synthDef, duration, args = #[]|
	playP.(synthDef, duration, args);
	(duration * beat).wait;
};

Routine({
	var fx, trigger;
	s.bind { fx = Synth.tail(nil, \fx, [out: 0]); };
	trigger = {
		s.bind { fx.set(\trigger, 1); };
	};
	loop {
		if (0.5.coin) {
			playP.(\clank, 1, [ freq: 440 ] );
		};
		(3..5).choose.do {
			trigger.();
			play.(\kick, [1, 1/2, 2/3, 1/4].choose);
		};

		trigger.();
		play.(\snare, [3, 2].choose);

		[2, (3..5).choose].choose.do { |i|
			trigger.();
			play.(\clank, [1/2, 1/3, 1/4].choose, [ freq: [123, 2623, 1440, 7230].choose, pan: [-1, 1].wrapAt(i) * 0.7 ] );
		};

		trigger.();
		play.(\hat, [1 / 2, 1 / 3].choose);
	};
}).play;
)