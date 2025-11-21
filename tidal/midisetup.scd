SuperDirt.start;

MIDIClient.init;

~midiOut = MIDIOut.newByName("FLUID Synth (10947)", "Synth input port (10947:0)");

~dirt.soundLibrary.addMIDI(\fluid, ~midiOut);