(
//1.0 Set up the server
s.quit;
s.options.memSize = 2.pow(20);
s.options.maxSynthDefs = 2.pow(12).asInteger;
s.waitForBoot({
	fork{
		var buffers0, buffers1;

		Buffer.freeAll;

		//Load Buffers
		buffers0 = "russell_files".ianAudioPath.getBuffers;
		buffers1 = "kitchen_grains".ianAudioPath.getBuffers;

		//Store them in a dictionary
		~buffers = Dictionary.new;

		~buffers.add(\a -> buffers0[0..(buffers0.size - 1 / 2 - 1).floor.asInteger]);
		~buffers.add(\b -> buffers0[(buffers0.size - 1 / 2).floor.asInteger..]);

		~buffers.add(\c -> buffers1[0..(buffers1.size - 1 / 2 - 1).floor.asInteger]);
		~buffers.add(\d -> buffers1[(buffers1.size - 1 / 2).floor.asInteger..]);
		s.sync;

		//Set up recording template
		i = CodexIncrementer("simulation.wav", "simulations".ianAudioPath.mkdir);
		"Ready to go!".postln;
	};
});
)

(
//2.0 Define species
t = GenOrgSpecies().buffers = ~buffers[\a];
t.folder = "mutations".ianAudioPath.mkdir;
t.hungerInterval = 4;
t.maturityRatio = 0.1;
t.matingInterval = 1;
t.starvationPeriod = 2;
t.matingDistance = 2;
t.fitnessMin = 0.3;
t.fitnessMax = 1.0;
t.lifespanMin = 8;
t.lifespanMax = 24;
t.startingPop = 8;
t.maturityRatio = 0;
t.timescaleRatio = 0.2;

u = GenOrgSpecies().buffers = ~buffers[\b];
u.folder = t.folder;
u.hungerInterval = 3;
u.starvationPeriod = 2;
u.startingPop = 32;
u.maturityRatio = 0.1;
u.matingInterval = 2;
u.fitnessMin = 0.3;
u.fitnessMax = 1.0;
u.startingPop = 16;
u.lifespanMin = 8;
u.lifespanMax = 32;
u.matingDistance = 2;
u.prey = t;
u.timescaleRatio = 0.1;
u.mates = [t, u];

v = GenOrgSpecies.new.buffers_(~buffers[\c]);
v.folder = t.folder;
v.startingPop = 16;
v.maturityRatio = 0.5;
v.fitnessMin = 0.05;
v.fitnessMax = 0.1;
v.lifespanMin = 16;
v.lifespanMax = 32;
v.matingDistance = 3;
v.timescaleRatio = 0.5;
v.prey = [u];

w = GenOrgSpecies.new.buffers_(~buffers[\d]);
w.folder = t.folder;
w.startingPop = 64;
w.maturityRatio = 0.2;
w.hungerInterval = 3;
w.starvationPeriod = 1;
w.matingDistance = 3;
w.matingInterval = 3;
w.fitnessMin = 0.8;
w.fitnessMax = 1.0;
w.timescaleRatio = 0.2;
w.mates = [w];
w.prey = [v];

t.prey = [t, u];
)

(
//3.0 Run to make music
fork {
	var count = 3, silence;
	var sim = GenOrgSim([t, u, v, w]);
	count.do { | i |
		format("Waiting: %\n", count - i).postln;
		1.wait;
	};

	s.record(i.increment);
	s.sync;

	silence = {
		DetectSilence.ar(
			In.ar(0, 2),
			time: 1,
			doneAction: 2
		);
		Silent.ar;
	}.play(target:s.defaultGroup, addAction: \addAfter);

	silence.onFree({
		s.stopRecording;
		fork {
			0.1.wait;
			Pdef(\sim).stop;
		};
	});

	s.sync;

	Pdef(\sim).clear;
	Pdef(\sim, Pbind(
		\type, \genOrgSim,
		\sim, sim,
		\dur, p { | ev |
			var pattern;
			loop {
				var n = exprand(2, 8);
				var levels = { exprand(0.1, 1.0) } ! n;
				var times = { exprand(0.01, 1.0) } ! (n - 1) + 2;
				var curves = { rrand(-12, 12) } ! (n - 1);
				if(0.5.coin, { levels = levels.mirror });
				pattern = Pseg(
					Pseq(levels, inf),
					Prand(times.normalizeSum * exprand(2.0, 32.0), inf),
					Pseq(curves, inf)
				);
				ev = pattern.embedInStream(ev);
			}
		} * Pwhite(0.8, 1.2, inf)
	));
	Pdef(\sim).play;
};
)