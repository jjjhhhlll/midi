SuperDirt.start;

MIDIClient.init;

// fluid synth example...
(
~midiOut = MIDIOut.newByName("FLUID Synth (10947)", "Synth input port (10947:0)");
~dirt.soundLibrary.addMIDI(\fluid, ~midiOut);
)

// mouse control adapted from https://gist.github.com/dqgorelick/3726d556a5200b752b811ab88155232b
// note: only works with X11 based scide and only in the scide window
(
~tidal = NetAddr.new("127.0.0.1", 6010);
~tidal.sendMsg('/ctrl', "hello", 2.0);

~trigAmount = 60;
~mouseY = SynthDef("sendMouseY", {
	SendTrig.kr(Impulse.kr(~trigAmount), 0, MouseY.kr(0, 1));
}).add;

~mouseX = SynthDef("sendMouseX", {
	SendTrig.kr(Impulse.kr(~trigAmount), 1, MouseX.kr(0, 1));
}).add;

~lastMouseY = -1;
~lastMouseX = -1;

o = OSCFunc({ arg msg;
	switch (msg[2])
	{0} {
		if (~lastMouseY == msg[3], {}, {
			~tidal.sendMsg('/ctrl', "mousey", msg[3]);
			~lastMouseY = msg[3];
		});
	}
	{1} {
		if (~lastMouseX == msg[3], {}, {
			~tidal.sendMsg('/ctrl', "mousex", msg[3]);
			~lastMouseX = msg[3];
		});
	}
}, '/tr', s.addr);
)

(
Synth("sendMouseY");
Synth("sendMouseX");
)

(
~mouseY.free;
~mouseX.free;
)