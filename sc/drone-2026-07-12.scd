(
SynthDef(\guitar, {
	var snd;

	snd = Pluck.ar(PinkNoise.ar, Dust.ar(8) + Impulse.ar(10), 0.5, TChoose.kr(Impulse.ar(1/10), [1, 2, 3]) / 100, 2.0, Line.kr(0.7, 0.0001, 60.0));
	snd = snd ! 2;

	snd = LeakDC.ar(snd);

	snd = BLowShelf.ar(snd, 200, 1, -10);
	snd = BHiShelf.ar(snd, Line.kr(8000, 3000, 20.0), 1, -10);
	snd = (snd * Line.kr(2, 20, 45.0)).tanh;
	snd = BLowShelf.ar(snd, 200, 1, 3);
	snd = BHiShelf.ar(snd, 3000, 1, 3);

	snd = LPF.ar(snd, XLine.kr(16000, 10, 180));

	snd = snd * -10.dbamp;
	Out.ar(\out.kr(0), snd);
}).play;
)