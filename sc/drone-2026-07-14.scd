(
SynthDef(\guitar, {
	var snd, fb;

	snd = Pluck.ar(
		PinkNoise.ar,
		Dust.ar(8) + Impulse.ar(10), 0.5,
		TWChoose.kr(Impulse.ar(20),
			[2, 1, 0.5],
			[
				Line.kr(1.0, 0.5, 30.0),
				Line.kr(0.0, 0.25, 30.0),
				Line.kr(0.0, 0.25, 30.0)
		]) / Line.kr(8, 100, 20.0),
		XLine.kr(8.0, 10.0, 70.0),
		Line.kr(0.7, 0.0001, 60.0)
	);
	snd = snd ! 2;

	fb = LocalIn.ar(2);
	fb = DelayC.ar(fb, 0.2, 0.03);
	fb = fb * Line.kr(0, 0.4, 60) * -5.dbamp;
	fb = LPF.ar(fb, Line.kr(200, 350, 60));
	snd = snd + fb;

	snd = snd * -4.dbamp;


	snd = LeakDC.ar(snd);

	snd = BLowShelf.ar(snd, 200, 0.8, -10);
	snd = BHiShelf.ar(snd, Line.kr(4000, 3000, 20.0), 1, -10);
	snd = (snd * Line.kr(2, 40, 90.0)).tanh;
	snd = BLowShelf.ar(snd, 200, 1, 3);
	snd = BHiShelf.ar(snd, Line.kr(3000, 5000, 25.0), 1, 3);

	snd = snd + GVerb.ar(snd.sum * -10.dbamp, Line.kr(50, 10, 66));



	snd = LPF.ar(snd, XLine.kr(4000, 2, 120));
	LocalOut.ar(snd);


	snd = snd * -18.dbamp;

	snd = Limiter.ar(snd);
	Out.ar(\out.kr(0), snd);
}).play;
)