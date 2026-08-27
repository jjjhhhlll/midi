// from https://www.youtube.com/watch?v=Cwr3VhDG7Kw&list=PLELlGNnfZwb24FQv4nWhczfj0dWvn1EzM&index=27

(
SynthDef(\kick, {
	var snd;
	snd = SinOsc.ar(Env.perc(0, 0.2, curve: -8).ar.linexp(0, 1, 60, 300) * Env.perc(0, 0.1).ar.linexp(0, 1, 1, 2) * XLine.ar(1, 0.7, 1));
	snd = snd * (1 + Env.perc(0, 0.1).ar);
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar), 8320, 0.3) * Env.perc(0.001, 0.02).ar);
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar), 4320, 0.3) * Env.perc(0.001, 0.01).ar  * 5.dbamp);
	snd = snd + (BPF.ar(Hasher.ar(Sweep.ar), 10320, 0.3) * Env.perc(0.05, 0.3).ar  * -10.dbamp);
	snd = snd.tanh + ((snd * 3).fold2 * Env.perc(0, 0.02).ar);
	snd = snd * Env.perc(0.001, 1.0).ar;
	snd = snd + HPF.ar(LPF.ar(DelayC.ar(snd * -15.dbamp, 0.1, [30e-3, 45e-3]), 2000), 100);
	snd = snd.tanh * 3.dbamp;

	snd = snd * Env.linen(0, 1.0, 0.1, curve: -4).ar(Done.freeSelf);
	snd = snd * -8.dbamp;
	Out.ar(\out.kr(0), snd)
}).add;

SynthDef(\rumble, {
	var snd, duration;
	duration = \duration.kr(1.0);
	snd = SinOsc.ar(60 * (LFNoise2.ar(5 ! 12) * 5).midiratio);
	snd = Splay.ar(snd) *  -10.dbamp;
	snd = snd.tanh;
	snd = snd + PitchShift.ar(snd, 0.03, 14);
	snd = snd * Line.ar(0, 1, 0.1);
	snd = snd * Env.linen(0, duration, 1.0, curve: -4).ar(Done.freeSelf);
	snd = snd * -8.dbamp;
	Out.ar(\out.kr(0), snd)
}).add;

SynthDef(\reverbFx, {
	var snd;
	snd = In.ar(\in.kr(0), 2);
	snd = snd + GVerb.ar(snd.sum * -25.dbamp, 60, 3);
	snd = snd * -8.dbamp;
	Out.ar(\out.kr(0), snd)
}).add;
)

Synth(\kick);
Synth(\rumble);

(
var s;
s = Server.default;

Routine({
	var reverbBus;
	s.bind {
		reverbBus = Bus.audio(nil, 2);
		Synth.tail(nil, \reverbFx, [in: reverbBus, out: 0]);
	};
	s.bind { Synth(\kick, [out: reverbBus]); };
	s.bind { Synth(\rumble, [ duration: 5, out: reverbBus]) };
}).play;
)