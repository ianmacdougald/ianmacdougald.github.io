s.quit;
//To play the piece, you must follow to steps:
//Step 1--initialize the piece. To do this, first make sure that the name of your interface is an uncommented string (i.e. grey, not red like this text); second, click anywhere in the big chunk of code that takes up most of this file and hit "enter"/CMD+return.
//Step2--notice where it says ~piece[patterned_landscapes].fork? Hit that and the piece will start.


//piece
~piece[\patterned_landscapes].fork;

//initialization code
(
//1. server config
s = Server.local;
s.options.outDevice_(
	// "Built-in Output"
	//"Soundflower (2ch)"
	//"MOTU UltraLite mk3 Hybrid"
	// "UltraLite AVB"
	"Duet USB"
);
s.options.numOutputBusChannels_(
	2
	// 18
);
s.options.inDevice_(
	// "Built-in Microph"
	// "UltraLite AVB"
	"Duet USB"

);
s.options.numInputBusChannels_(
	2
	// 18
);
s.options.sampleRate_(44100);
s.options.memSize_(2.pow(21));
s.newBusAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;

//2. initialize global variables
~out = 0;
~soundInChan = 0;
~trigThreshold = 0.2875;
~path = PathName(thisProcess.nowExecutingPath).parentPath++"RussellFiles/";
~clock = ClockFace.new;

//3. define piece-specific functions
~makeBuffers = {
	d = Dictionary.new;
	PathName(~path).entries.do{
		arg subfolder;
		d.add(
			subfolder.folderName.asSymbol ->
			Array.fill(
				subfolder.entries.size,
				{
					arg i;
					Buffer.read(s, subfolder.entries[i].fullPath);
				}
			)
	)};
};

~makeRelevantBufnums = {
	~bufnum = Dictionary.new;
	~bufnum.add(\1 -> Pbind(\bufnum, Pfunc({d[\MarimbaHits][5]})));
	~bufnum.add(\2 -> Pbind(\bufnum, Pfunc({d[\WoodBlockFun1][6]})));
	~bufnum.add(\3 -> Pbind(\bufnum, Pfunc({d[\MarimbaHits][4]})));
	~bufnum.add(\4 -> Pbind(\bufnum, Pfunc({d[\WoodBlockFun1][4]})));
	~bufnum.add(\5 -> Pbind(\bufnum, Pfunc({d[\WoodBlockFun1][(1..10)].flatten.choose})));
	~bufnum.add(\6 -> Pbind(\bufnum, Pfunc({d[\WoodBlockFun1][(17..21)].flatten.choose})));
	~bufnum.add(\7 -> Pbind(\bufnum, Pfunc({d[\CrotaleFun][(0..7)].flatten.choose})));
	~bufnum.add(\8 -> Pbind(\bufnum, Pfunc({d[\CrotaleFun][(9..14)].flatten.choose})));
	~bufnum.add(\9 -> Pbind(\bufnum, Pfunc({d[\CymbalFun][(0..40)].flatten.choose})));
};

~makeBusses = {
	~bus = Dictionary.new;
	~bus.add(\limitLeft -> Bus.audio(s, 1));
	~bus.add(\limitRight -> Bus.audio(s, 1));
	~bus.add(\leftVerb -> Bus.audio(s, 1));
	~bus.add(\stereoVerb -> Bus.audio(s, 1));
	~bus.add(\rightVerb -> Bus.audio(s, 1));
	~bus.add(\mixBus -> Bus.control(s, 1));
	~bus.add(\roomBus -> Bus.control(s, 1));
	~bus.add(\dampBus -> Bus.control(s, 1));
};

~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
	~clock.stop;
};

~makeNodes = {
	s.bind({
		~mainGroup = Group.new;
		~controlGroup = Group.new(~mainGroup);
		~sourceGroup = Group.after(~controlGroup);
		~audioInGroup = Group.new(~sourceGroup);
		~soundGroup = Group.new(~sourceGroup);
		~fxGroup = Group.after(~sourceGroup);
		~reverbGroup = Group.new(~fxGroup);
		~limiterGroup = Group.before(~reverbGroup);

		~leftVerbSynth = Synth.new(\freeVerb, [
			\inchan, ~bus[\leftVerb],
			\outchan, ~out,
			\amp, 1,
			\inchan_mix, ~bus[\mixBus],
			\inchan_room, ~bus[\roomBus],
			\inchan_damp, ~bus[\dampBus]
		], ~reverbGroup);

		~rightVerbSynth = Synth.new(\freeVerb, [
			\inchan, ~bus[\rightVerb],
			\outchan, ~out + 1,
			\amp, 1,
			\inchan_mix, ~bus[\mixBus],
			\inchan_room, ~bus[\roomBus],
			\inchan_damp, ~bus[\dampBus]
		], ~reverbGroup);

		~stereoVerb = Synth.new(\freeVerb, [
			\inchan, ~bus[\stereoVerb],
			\outchan, ~out,
			\amp, 1,
			\inchan_mix, ~bus[\mixBus],
			\inchan_room, ~bus[\roomBus],
			\inchan_damp, ~bus[\dampBus]
		], ~reverbGroup);

		~soundInLeftSynth = Synth.new(\soundIn, [
			\inchan, ~soundInChan,
			\outchan, ~bus[\limitLeft],
			\amp, 0.75
		], ~audioInGroup);

		~soundInRightSynth = Synth.new(\soundIn, [
			\inchan, ~soundInChan + 1,
			\outchan, ~bus[\limitRight],
			\amp, 0.75
		], ~audioInGroup);

		~limiterLeftSynth = Synth.new(\limiter, [
			\inchan, ~bus[\limitLeft],
			\outchan, ~bus[\leftVerb],
			\level, 0.89075
		], ~limiterGroup);

		~limiterRightSynth = Synth.new(\limiter, [
			\inchan, ~bus[\limitRight],
			\outchan, ~bus[\rightVerb],
			\level, 0.9075
		], ~limiterGroup);

		~room_ctrl = Synth.new(\roomBus, [
			\outchan, ~bus[\roomBus]
		], ~controlGroup);

		~damp_ctrl = Synth.new(\dampBus, [
			\outchan, ~bus[\dampBus]
		], ~controlGroup);

		~mix_ctrl = Synth.new(\mixBus, [
			\outchan, ~bus[\mixBus]
		], ~controlGroup);

		~trigSynth = Synth.new(\sendingTrig,
			target: ~controlGroup);

	})
};

~makePatterns = {
	~pattern = Dictionary.new;

	~pattern.add(\1 -> Pbind(
		\instrument, \concrete,
		\rate, Pseq([
			Pseq([
				Pn(0.95, 20),
				Pn(1.00, 27),
				Pn(1.5, 27)
			], 2),
			Pn(1.5, 10),
			Pseq([
				Pn(2.0, 15),
				Pn(2.5, 12),
				Pn(2.95, 5),
			], 3),
			Pseq([
				Pn(0.95, 10),
				Pn(1.00, 10),
				Pn(1.5, 10)
			], 7)
		], inf),
		\impulserate, Pkey(\rate),
		\atk, Pwhite(0.001, 0.1, inf),
		\decay, Pkey(\atk),
		\sustain, 1,
		\release, 1,
		\sustainTime, 1.5,
		\startPos, 0,
		\loop, 1,
		\amp, Pwhite(3.00, 8.00, inf),
		\outchan, Pseq([~bus[\limitLeft], ~bus[\limitRight]], inf),
		\dur, Pkey(\rate)/10,
		\group, ~soundGroup
	));

	~pattern.add(\alt1A -> Pbind(
		\instrument, \concrete,
		\rate, Pseq([
			Pn(0.95, 20),
			Pn(1.00, 27),
			Pn(1.5, 27)
		], 1),
		\impulserate, Pkey(\rate),
		\atk, Pwhite(0.001, 0.1, inf),
		\decay, Pkey(\atk),
		\sustain, 1,
		\release, 1,
		\sustainTime, 1.5,
		\startPos, 0,
		\loop, 1,
		\amp, Pwhite(3.00, 8.00, inf)/2,
		\outchan, Pseq([~bus[\limitLeft], ~bus[\limitRight]], inf),
		\dur, Pkey(\rate)/10,
		\group, ~soundGroup
	));

	~pattern.add(\alt1B -> Pbind(
		\instrument, \concrete,
		\rate, Pseq([
			Pn(2.0, 15),
			Pn(2.5, 12),
			Pn(2.95, 5),
		], 4),
		\impulserate, Pkey(\rate),
		\atk, Pwhite(0.001, 0.1, inf),
		\decay, Pkey(\atk),
		\sustain, 1,
		\release, 1,
		\sustainTime, 1.5,
		\startPos, 0,
		\loop, 1,
		\amp, Pwhite(3.00, 8.00, inf)/2,
		\outchan, Pseq([~bus[\limitLeft], ~bus[\limitRight]], inf),
		\dur, Pkey(\rate)/10,
		\group, ~soundGroup
	));

	~pattern.add(\2 -> Pbind(
		\instrument, \concrete,
		\rate, Pwhite(0.95, 2.95, inf),
		\impulserate, Pkey(\rate),
		\atk, Pwhite(0.001, 0.2, inf),
		\deecay, Pkey(\atk),
		\sustain, 1,
		\release, 1,
		\sustainTime, 1.5,
		\startPos, 0,
		\loop, 1,
		\amp, Pwhite(3.00, 7.00, inf)/2.0,
		\outchan,  Pseq([~bus[\limitLeft],~bus[\limitRight]], inf),
		\dur, Pkey(\rate)/10,
		\group, ~soundGroup
	));

	~pattern.add(\3 -> Pbind(
		\instrument, \sineVibe,
		\freq, Pwhite(100, 1000, inf) + [0.25, -0.25, 0.5, -0.5, 1.0, -1.0],
		\freqratio, Pwhite(0.1, 2.0, inf),
		\strum, Pwhite(10, 50)/Pwhite(100, 500, inf),
		\atk, Pwhite(0.01, 0.15, inf),
		\release, Pwhite(2, 7.5, inf),
		\amp, Pwhite(0.05, 0.125)/1.5,
		\dur, Pwhite(0.25, 3.95, inf) * 2,
		\outchan, Prand([~bus[\limitLeft], ~bus[\limitRight]], inf),
		\group, ~soundGroup
	));

	~pattern.add(\4 -> Pbind(
		\instrument, \sineVibe,
		\freq, 750 * Pseq([
			Pn(0.95, 1),
			Pn(1.00, 2),
			Pn(1.5, 2)
		], 2)++Pn(1.5, 3)++Pseq([
			Pn(2.0, 1),
			Pn(2.5, 2),
			Pn(2.95, 2),
		], 2),
		\detune, [0.1, -0.1, 0.2, -0.2, 0.4, -0.4, 0.8, -0.8, 1.6, -1.6],
		\freqratio, Pkey(\freq)/900,
		\strum, 20/750,
		\atk, Pwhite(0.01, 0.15, inf),
		\release, Pwhite(2, 7.5, inf),
		\amp, Pwhite(0.1, 0.225)/1.5,
		\dur, Pwhite(3.0, 5.0, inf)/2,
		\outchan, Prand([~bus[\limitLeft], ~bus[\limitRight]], inf),
		\group, ~soundGroup
	));

	~pattern.add(\5 -> Pbind(
		\instrument, \concrete_cymbal,
		\bufnum, Pfunc({ var num;
			num = (0..29).choose;
			d[\CymbalFun][num]}),
		\rate, Pexprand(0.0751, 1.500, inf),
		\atk, Pwhite(0.0875, 0.101, inf),
		\release, Pwhite(6, 15, inf),
		\amp, 20.0,
		\dur, Pexprand(0.1, 3.000, inf),
		\outchan, Prand([~bus[\limitLeft], ~bus[\limitRight]], inf),
		\group, ~soundGroup,
	));

	~pattern.add(\b1 -> {
		Synth.new(\concrete, [
			\bufnum, [d[\WoodBlockFun1][(0..20)].flatten.choose,
				d[\MarimbaHits][(0..20)].flatten.choose,
				d[\CrotaleFun][(0..20)].flatten.choose].choose,
			\outchan, [~bus[\limitLeft], ~bus[\limitRight]].choose,
			\rate, {rrand(0.25, 2.0)},
			\impulserate, {rrand(2.0, 3.0)},
			\startPos, 250,
			\loop, 1,
			\amp, 3.25,
			\atk, 0.2,
			\decay, 0.01,
			\sustain, 0.99,
			\release, 0.5,
			\sustainTime, {exprand(0.1, 1.5)}
		],~soundsGroup)
	});

	~pattern.add(\b2a -> {
		{
			rrand(2, 3).do{
				[
					Synth.new(\delayout, [\outchan, ~bus[\leftVerb], \amp, 0.35], ~audioInGroup),
					Synth.new(\delayout, [\outchan, ~bus[\rightVerb], \amp, 0.35], ~audioInGroup),
					Synth.new(\kick, [
						\outchan, ~bus[\leftVerb], \freq, {rrand(80, 200)},
						\amp, 0.1, \release, {rrand(0.5, 1.5)}], ~soundGroup),
					Synth.new(\kick, [
						\outchan, ~bus[\rightVerb], \freq, {rrand(80, 200)},
						\amp, 0.1, \release, {rrand(0.5, 1.5)}], ~soundGroup)
				].choose;
				rrand(1, 3).wait;
			}
		}.fork
	});

	~pattern.add(\b2b -> {
		{
			rrand(2, 3).do{
				[
					Synth.new(\delayout, [\outchan, ~bus[\leftVerb], \amp, 0.01], ~audioInGroup),
					Synth.new(\delayout, [\outchan, ~bus[\rightVerb], \amp, 0.01], ~audioInGroup),
					Synth.new(\kick, [
						\outchan, ~bus[\leftVerb], \freq, {rrand(1000, 4000)},
						\amp, 0.01, \release, {rrand(0.5, 1.5)}], ~soundGroup),
					Synth.new(\kick, [
						\outchan, ~bus[\rightVerb], \freq, {rrand(980, 4200)},
						\amp, 0.01, \release, {rrand(0.5, 1.5)}], ~soundGroup)
				].choose;
				rrand(1, 3).wait;
			}
		}.fork
	});

	~pattern.add(\b3 -> {
		Synth.new(\concrete, [
			\bufnum, d[\CymbalHits][(0..7)].flatten.choose,
			\outchan, [~bus[\limitLeft], ~bus[\limitRight]].choose,
			\rate, {rrand(1, 2.0)},
			\impulserate, {rrand(2.0, 3.0)},
			\startPos, 250,
			\loop, 1,
			\amp, 4,
			\atk, 0.01,
			\decay, 0.01,
			\sustain, 0.99,
			\release, 0.5,
			\sustainTime, {exprand(0.1, 1.5)}
		],~soundGroup)
	});
};

~makeEvents = {
	e = Dictionary.new;

	e.add(\event_a ->Ppar([
		Pchain(~pattern[\1], ~bufnum[\1]),
		Pchain(~pattern[\1], ~bufnum[\2]),
		Pchain(~pattern[\1], ~bufnum[\3]),
		Pchain(~pattern[\1], ~bufnum[\4])
	], 100));

	e.add(\event_aPrime1 -> Ppar([
		Pchain(~pattern[\1], ~bufnum[\5]),
		Pchain(~pattern[\1], ~bufnum[\6]),
		Pchain(~pattern[\1], ~bufnum[\7]),
		Pchain(~pattern[\1], ~bufnum[\8])
	], 100));

	e.add(\event_aPrime2 -> Ppar([
		Pchain(~pattern[\2], ~bufnum[\1]),
		Pchain(~pattern[\2], ~bufnum[\2]),
		Pchain(~pattern[\2], ~bufnum[\7]),
		Pchain(~pattern[\2], ~bufnum[\8]),
		Pchain(~pattern[\2], ~bufnum[\9])
	], 100));

	e.add(\event_aPrime3 -> ~a_prime_material3 = ~pattern[\3]);

	e.add(\event_aPrime4 -> 	~a_prime_material4 = ~pattern[\4]);

	e.add(\event_aPrime5 -> ~a_prime_material5 = ~pattern[\5]);

	e.add(\event_aPrime6 -> ~a_prime_material6 = ~pattern[\5]);

	e.add(\event_b1-> {
		OSCFunc({arg msg, time;
			[time, msg].postln;
			~pattern[\b1].value
	}, '/tr', s.addr)});

	e.add(\event_b2 -> {

		e[\event_b1].remove;
		OSCFunc({arg msg, time;
			[time, msg].postln;
			[~pattern[\b2a].value, ~pattern[\b2b].value].choose
	}, '/tr', s.addr)});

	e.add(\event_b3 -> {

		e[\event_b2].remove;
		OSCFunc({arg msg, time;
			[time, msg].postln;
			~pattern[\b3].value
	}, '/tr', s.addr)});


	e.add(\event_c1 ->Ppar([
		Pchain(~pattern[\alt1A], ~bufnum[\1]),
		Pchain(~pattern[\alt1A], ~bufnum[\2]),
		Pchain(~pattern[\alt1A], ~bufnum[\3]),
		Pchain(~pattern[\alt1A], ~bufnum[\4])
	], 25));

	e.add(\event_c2 ->Ppar([
		Pchain(~pattern[\alt1B], ~bufnum[\1]),
		Pchain(~pattern[\alt1B], ~bufnum[\2]),
		Pchain(~pattern[\alt1B], ~bufnum[\3]),
		Pchain(~pattern[\alt1B], ~bufnum[\4])
	], 25));

	e.add(\d1 -> {Synth.new(\panSines, [
		\outchan, ~bus[\stereoVerb], \rate, {rrand(0.1, 3.0)},
		\pantime, {rrand(7.00, 11.00)}, \amp, 0.5, \gate, 1
	],
	target: ~soundGroup)});
};

~makeMusic ={
	~music = Dictionary.new;
	~music.add(\aSection ->	{
		//A
		~a_material = e[\event_a].play;
		41.wait;
		//A'—A prime
		~a_prime_material1 = e[\event_aPrime1].play;
		25.wait;
		~a_material.stop;
		"a_material.stop".postln;
		30.wait;
		~a_prime_material2 = e[\event_aPrime2].play;
		20.wait;
		~a_prime_material1.stop;
		"~a_prime_material1.stop".postln;
		//sine vibe plays
		~a_prime_material3 = e[\event_aPrime3].play;
		5.wait;
		//another sine vibe
		~a_prime_material4 = e[\event_aPrime4].play;
		4.0.wait;
		~a_prime_material5 = e[\event_aPrime5].play;
		//long section of cymbal stuff
		30.wait;
		~a_prime_material6 = e[\event_aPrime6].play;
		25.wait;
		~a_material = e[\event_a].play;
		15.wait;
		~a_prime_material3.stop;
		"~a_prime_material3.stop".postln;
		~a_prime_material4.stop;
		"~a_prime_material4.stop".postln;
		15.wait;
		~a_prime_material5.stop;
		"~a_prime_material5.stop".postln;
		25.wait;
		~a_prime_material3.stop;
		"~a_prime_material3.stop".postln;
		~a_prime_material6.stop;
		"~a_prime_material6.stop".postln;
		25.wait;
		~a_material.stop;
		"a_material.stop".postln;
		10.wait;
	});

	~music.add(\bSection -> {
			25.wait;
		"wait is over".postln;

		2.do{
			~b_material1 = OSCFunc({arg msg, time;
				[time, msg].postln;
				~pattern[\b1].value
			}, '/tr', s.addr);

			20.wait;
			~a_prime_material2.stop;

			20.wait;

			~b_material1.remove;
			"~b_material1.remove".postln;
			~b_material2 = OSCFunc({arg msg, time;
				[time, msg].postln;
				[~pattern[\b2a].value,
					~pattern[\b2b].value
				].choose
			}, '/tr', s.addr);

			30.wait;

			~b_material2.remove;
			"~b_material2.remove;".postln;
			~b_material3 = OSCFunc({arg msg, time;
				[time, msg].postln;
				~pattern[\b3].value
			}, '/tr', s.addr);

			30.wait;
			~b_material3.remove;
			"~b_material3.remove".postln;

		};
		~c_material3 = e[\event_c1].play;
		4.wait;
		~c_material3.stop;
		~c_material4 = e[\event_c2].play;
		5.wait;
		~c_material4.stop;
	});

	~music.add(\cSection -> {
		~d_material1 = e[\d1].value;
		~d_material2 = e[\d1].value;
		~d_material3 = e[\d1].value;
		2.wait;
		~d_material4 = e[\d1].value;
		~d_material5 = e[\d1].value;
		~d_material6 = e[\d1].value;
		5.wait;
		~trigSynth.free;
		"trigfree".postln;
		"the triggers should stop".postln;
		"if not, free the trig synth manually".postln;
		~d_material7 = e[\d1].value;
		~d_material8 = e[\d1].value;
		~d_material9 = e[\d1].value;
		10.wait;
		~d_material10 = e[\d1].value;
		~d_material11 = e[\d1].value;
		~d_material12 = e[\d1].value;
		20.wait;
		~d_material13 = e[\d1].value;
		~d_material14 = e[\d1].value;
		~d_material15 = e[\d1].value;
		2.wait;
		~d_material16 = e[\d1].value;
		~d_material17 = e[\d1].value;
		~d_material18 = e[\d1].value;
		5.wait;
		~d_material19 = e[\d1].value;
		~d_material20 = e[\d1].value;
		~d_material21 = e[\d1].value;
		10.wait;
		~c_material1 = e[\event_c1].play;

		7.wait;
		~c_material1.stop;

		30.wait;
		~d_material1.free; ~d_material2.free;~d_material3.free;
		~d_material4.free; ~d_material5.free;~d_material6.free;
		~d_material7.free;~d_material8.free;~d_material9.free;
		~d_material10.free;~d_material11.free;~d_material12.free;
		5.2.wait;
		~c_material3 = e[\event_c1].play;
		4.wait;
		~c_material3.stop;
		~c_material4 = e[\event_c2].play;
		3.wait;
		~c_material4.stop;
		4.wait;
		~d_material13.free; ~d_material14.free;~d_material15.free;
		~d_material16.free; ~d_material17.free;~d_material18.free;
		~d_material19.free;~d_material20.free;~d_material21.free;
	});

	~music.add(\dSection ->{
		//A
		~a_material = e[\event_a].play;
		41.wait;
		//A'—A prime
		~a_prime_material1 = e[\event_aPrime1].play;
		25.wait;
		~a_material.stop;
		"a_material.stop".postln;
		30.wait;
		~a_prime_material1.stop;
		"a_prime_material1.stop".postln;
		~a_material = e[\event_a].play;
		41.wait;
	})
};

~makePiece = {
	~piece = Dictionary.new;
	~piece.add(\patterned_landscapes -> {
		~clock.play;
		~music[\aSection].fork; (41+25+30+20+5+4+30+25+15+15+25+25+10).wait;
		"b section starts".postln;
		~music[\bSection].fork; (25 + 210 + 9).wait;
		"c section starts".postln;
		~music[\cSection].fork; (2 + 5 + 7 + 10 + 20 + 2 +5 + 10 + 7 + 30 +4 + 5.2).wait;
		"d section starts".postln;
		~music[\dSection].fork; (41 + 25 + 30 + 4).wait;
		~mainGroup.release(41);
		50.wait;
		~clock.stop;
		"all done".postln;
	});
};

//4. register functions with ServerBoot/Quit/Tree
ServerBoot.add(~makeBuffers);
ServerBoot.add(~makeBusses);
ServerQuit.add(~cleanup);


//5. boot server
s.waitForBoot({

	s.sync;

	//6a. define SynthDefs

	SynthDef.new(\concrete, {
		arg bufnum, outchan, rate,
		impulserate, atk, release,
		startPos, loop, amp,
		decay, sustain, sustainTime;
		var out, env, impulse;
		env = Env.new([0, 1, sustain, 0], [atk, decay, sustainTime, release]);
		impulse = Impulse.kr(impulserate);
		out = PlayBuf.ar(1, bufnum, rate, startPos, loop);
		out = out * amp * EnvGen.kr(env, doneAction: 2);
		Out.ar(outchan, out);
	}).add;

	SynthDef.new(\concrete_cymbal, {
		arg bufnum, outchan, rate,
		amp, atk, release;
		var out, env;
		env = EnvGen.kr(Env.perc(atk, release), doneAction: 2);
		out = PlayBuf.ar(1, bufnum, rate, 1, 0, 0);
		out = out * amp  * env;
		Out.ar(outchan, out);
	}).add;

	SynthDef.new(\soundIn, {
		arg inchan, outchan, amp;
		var out;
		out = SoundIn.ar(inchan, amp);
		Out.ar(outchan, out);
	}).add;

	SynthDef.new(\sineVibe, {
		arg outchan, amp, freq,
		freqratio, atk, release, detune;
		var out, env;
		env = Env.perc(atk, release);
		out = SinOsc.ar((freq + detune)
			* SinOsc.ar((freq + detune)
				* freqratio, { rrand(0, pi/2) } )
			+ (freq+detune), { rrand(0, pi/2)});
		out = out * amp * EnvGen.kr(env, doneAction: 2);
		Out.ar(outchan, out);
	}).add;

	SynthDef.new(\mixBus, {
		arg outchan;
		Out.kr(outchan, {LFNoise2.kr(
			LFNoise1.kr(rrand(0.1, 0.575)).range(1/40, 0.575)
		).range(0.001, 0.750)})
	}).add;

	SynthDef.new(\limiter, {
		arg inchan, outchan, level = 0.9000;
		var out;
		out = Limiter.ar(
			In.ar(inchan),
			level);
		Out.ar(outchan, out);
	}).add;

	SynthDef.new(\roomBus, {
		arg outchan;
		Out.kr(
			outchan,
			{ LFNoise2.kr(
				LFNoise1.kr(rrand(0.1, 0.575)
		).range(1/40, 0.575)).exprange(0.5, 5.0) })
	}).add;

	SynthDef.new(\dampBus, {
		arg outchan;
		Out.kr(outchan,
			{ LFNoise1.kr(
				LFNoise1.kr(rrand(0.1, 0.575)).range(1/40, 0.575)
			).range(0.1, 1.0) }
		);
	}).add;

	SynthDef.new(\freeVerb, {
		arg inchan, outchan, amp,
		inchan_mix, inchan_room, inchan_damp,
		gate = 1, release = 10;
		var mix, room, damp, out;
		mix = In.kr(inchan_mix);
		room = In.kr(inchan_room);
		damp = In.kr(inchan_damp);
		out = FreeVerb.ar(In.ar(inchan), mix, room, damp, amp);
		Out.ar(outchan, out
			* EnvGen.kr(
				Env.adsr(1, 0.1, 0.999, release),
				gate, doneAction: 2));
	}).add;

	SynthDef(\sendingTrig, {
		arg inchan;
		var b, sig, chain, onsets, threshold, trigger;
		b.clear;
		b = Buffer.alloc(s, 512);
		sig = SoundIn.ar(0);
		chain = FFT(b, sig);
		threshold = ~trigThreshold;
		// SinOsc.kr(0.1);
		onsets = Onsets.kr(chain, threshold, \complex);
		trigger = SendTrig.kr(onsets);
	}).add;

	SynthDef(\delayout, {
		arg outchan, amp;
		var out, in;
		in = WhiteNoise.ar;
		out = RLPF.ar(in, {LFNoise1.kr(LFNoise1.kr(0.25).range(0.1, 1.0)).range(200, 5000)},
			{LFNoise1.kr(LFNoise1.kr(0.25).range(0.05, 1.25)).range(0.125, 0.5)},
			EnvGen.kr(Env.perc({rrand(0.001, 0.1)}, {rrand(0.01, 0.5)})))
		* Env.perc({rrand(0.01, 0.2)}, {rrand(0.25, 2.0)}).kr(doneAction: 2);
		Out.ar(outchan, out * amp);
	}).add;

	SynthDef.new(\kick, {
		arg outchan, amp, freq, release;
		var sig, out;
		sig = Mix.ar([SinOsc.ar(freq) * 0.75, LFTri.ar(freq) * 0.25]);
		out = sig * Env.perc(0.001, release).kr(doneAction: 2);
		out = out * amp;
		Out.ar(outchan, out);
	}).add;

	SynthDef.new(\panSines, {
		arg outchan, amp = 0.75, atk = 1, sustain = 0.75,
		decay = 0.25, release = 5, rate, modfreq = 600,
		modamp = 2, pantime = 9, trigwait = 2, gate = 0;
		var out, carrier, modulator, pan_env,
		local_env, main_env, trigger;
		trigger = Impulse.kr((pantime + trigwait).reciprocal);
		main_env = EnvGen.kr(Env.adsr(atk, decay, sustain, release), gate, doneAction: 2);
		local_env = EnvGen.kr(Env.triangle(pantime), trigger);
		pan_env = EnvGen.kr(Env.new([-1, 0, 1, 0, -1, -1],
			[pantime/4.5, pantime/4.5, pantime/4, pantime/4]), trigger);
		carrier = PlayBuf.ar(1, d[\CymbalFun][20], rate, trigger, 0) * 75;
		out = Pan2.ar(
			// PinkNoise.ar
			HPF.ar(carrier, 100)
			* local_env * main_env * amp, pan_env);
		Out.ar(outchan, out);
	}).add;

	s.sync;

	//6b. register remaining functions
	ServerTree.add(~makeRelevantBufnums);
	ServerTree.add(~makePatterns);
	ServerTree.add(~makeNodes);
	ServerTree.add(~makeEvents);
	ServerTree.add(~makeMusic);
	ServerTree.add(~makePiece);
	s.freeAll;

	s.sync;

	"done".postln;

});
);


s.plotTree;
s.quit;




