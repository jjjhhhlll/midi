(
SynthDef(\guitar, {
	var snd;

	snd = Pluck.ar(
		PinkNoise.ar,
		Dust.ar(8) + Impulse.ar(4), 0.5,
		TWChoose.kr(Impulse.ar(1/10),
			[1, 2, 3],
			[
				Line.kr(1.0, 0.5, 30.0),
				Line.kr(0.0, 0.25, 30.0),
				Line.kr(0.0, 0.25, 60.0)
		]) / 100,
		XLine.kr(0.5, 10.0, 70.0),
		Line.kr(0.7, 0.0001, 60.0)
	);
	snd = snd ! 2;

	snd = LeakDC.ar(snd);

	snd = BLowShelf.ar(snd, 200, 1, -10);
	snd = BHiShelf.ar(snd, Line.kr(8000, 3000, 20.0), 1, -10);
	snd = (snd * Line.kr(2, 40, 90.0)).tanh;
	snd = BLowShelf.ar(snd, 200, 1, 3);
	snd = BHiShelf.ar(snd, Line.kr(3000, 5000, 25.0), 1, 3);

	snd = snd + GVerb.ar(snd.sum * -10.dbamp, Line.kr(50, 10, 66));


	snd = LPF.ar(snd, XLine.kr(16000, 0.1, 180));

	snd = snd * -15.dbamp;

	snd = Limiter.ar(snd);
	Out.ar(\out.kr(0), snd);
}).play;
)