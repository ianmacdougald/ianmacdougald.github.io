{ | modules, proxySpace |
	//The server object attached to the proxySpace.
	var server = proxySpace.server;

	//A list for storing functions that cleanup the server
	var cleanup = modules.cleanup;

	//An interface for messaging the performer
	var prompter = modules.panel.modules.prompter;

	//A collection of functions for creating NodeProxies
	modules.add(\factories -> (
		//Allocates a buffer for recording and playback
		alloc: { | ev, seconds(1), channels(1) |
			var bufnum = server.nextBufferNumber(channels);
			server.sendMsg(
				'/b_alloc',
				bufnum,
				server.sampleRate * seconds,
				channels
			);
			cleanup.add({
				server.sendMsg('/b_free', bufnum);
			});
			bufnum;
		},

		read: { | ev, path, channels(1) |
			var bufnum = server.nextBufferNumber(channels);
			server.sendMsg(
				'/b_allocRead',
				bufnum,
				path,
			);
			cleanup.add({
				server.sendMsg('/b_free', bufnum);
			});
			bufnum;
		},

		phasor: { | ev, buffer |
			{
				Phasor.ar(
					0,
					BufRateScale.kr(buffer) * \rate.kr(1, 0.1),
					0,
					BufFrames.kr(buffer) * \limit.kr(1, 0.1);
				);
			};
		},

		//Writes signal to buffer
		toBuffer: { | ev, buffer |
			{
				var timescale = BufDur.ir(buffer);
				var frames = BufFrames.ir(buffer);
				var input = \input.ar(0);
				var phasor = \phasor.ar(0);
				var env = Env(
					[0, 1, 1, 0],
					[0.1, 1, 0.1].normalizeSum
				).kr(
					gate: Impulse.kr(timescale.reciprocal),
					timeScale: timescale
				);
				BufWr.ar(input, buffer, phasor, 1);
				Silent.ar;
			};
		},

		toBuffer_stereo: { | ev, buffer |
			{
				var timescale = BufDur.ir(buffer);
				var frames = BufFrames.ir(buffer);
				var input = \input.ar(0!2);
				var phasor = \phasor.ar(0);
				var env = Env(
					[0, 1, 1, 0],
					[0.1, 1, 0.1].normalizeSum
				).kr(
					gate: Impulse.kr(timescale.reciprocal),
					timeScale: timescale
				);
				BufWr.ar(input, buffer, phasor, 1);
				Silent.ar;
			};
		},

		//Granularizes the buffer in a stream
		grains: { | ev, buffer |
			{
				var frames = BufFrames.ir(buffer);
				var bufdur = frames / SampleRate.ir;
				var x = \x.kr(0).clip(-1.0, 1.0);
				var y = \y.kr(0).clip(-1.0, 1.0);
				var impulserate = y.linexp(
					-1.0,
					1.0,
					64.0,
					256.0
				);
				var impulse = Impulse.ar(impulserate);
				var phasor = \phasor.kr(0);
				var pos = (
					x.wrap(0.0, 1.0)
					+ y.abs
					+ TRand.kr(0.0, 0.1, impulse)
					* bufdur
				).wrap(
					0,
					(
						(phasor - ControlRate.ir)
						* frames.reciprocal
					).wrap(0.0, 1.0) * bufdur
				);
				var rate = x
				.clip(-1.0, 1.0)
				.linexp(
					-1.0,
					1.0,
					8.0,
					0.2
				) / (y * 2 - 1 * 4 + 1).abs;
				var graindur = ((y * 2) / (x.abs + 1))
				.wrap(-1.0, 1.0)
				.linexp(
					-1.0,
					1.0,
					2.56,
					0.32
				) * LFNoise2.kr(
					LFNoise1.kr(1.0)
					.exprange(2.0, 8.0)
				).exprange(0.5, 2.0);
				var sig = TGrains.ar(
					2,
					impulse,
					buffer,
					rate,
					pos,
					graindur,
					TRand.kr(-1.0, 1.0, impulse),
					graindur / impulserate
				).flat;
				sig = HPF.ar(
					sig,
					// LeakDC.ar(sig),
					60
				);
				(sig * \z.ar(1)).tanh * \ampDb.kr(0).dbamp;
			};
		},

		output: { | ev ... items |
			{
				var inputs = items.flat;
				var sigs = inputs.collect({ | item, index |
					var amp = format("amp%", index).asSymbol;
					amp = amp.kr(2/inputs.size);
					item.ar * amp;
				});
				Splay.ar(
					sigs,
					\spread.kr(0.05, 1),
				).sum.tanh * \ampDb.kr(-12).dbamp;
			};
		},

		amplitude: {
			{
				Latch.kr(
					A2K.kr(\input.ar(0)),
					Impulse.kr(16.0)
				);
			};
		},

		pitch: {
			{
				Pitch.kr(
					(\input.ar(0) * 1.5).tanh
				).at(0).clip(125.0, 7200)
				.expexp(
					\pitchLo.kr(20.0),
					\pitchHi.kr(12000.0),
					1.0,
					2.0
				) - 1 * 2 - 1
			};
		},

		peaks: {
			{
				PeakFollower.ar(
					(\input.ar(0) * 8).tanh,
					0.999
				) * \scaling.kr(175);
			};
		},

		input: { | ev, bus(0) |
			{
				var sig = SoundIn.ar(bus);
				sig = LeakDC.ar(sig);
				sig = HPF.ar(sig, 60);
				sig = LPF.ar(sig, 12000);
				SoftClipAmp4.ar(sig, 1.05).tanh;
			};
		},

		playbuf: { | ev, buffer |
			{
				var sig = PlayBuf.ar(
					1,
					buffer,
					BufRateScale.kr(buffer) * \rate.kr(1, 0.1),
					1,
					0,
					\loop.kr(1),
					doneAction: Done.freeSelf
				);
				sig = LeakDC.ar(sig);
				sig = HPF.ar(sig, 60);
				sig = LPF.ar(sig, 12000);
				SoftClipAmp4.ar(sig, 1.05).tanh * \ampDb.kr(0).dbamp;
			};
		}
	));

	//Specs for the arguments of the factories
	Spec.add(\input, [-1.0, 1.0].asSpec);
	Spec.add(\rate, [0.01, 8.0, \exp].asSpec);
	Spec.add(\x, [-1.0, 1.0].asSpec);
	Spec.add(\y, [-1.0, 1.0].asSpec);
	Spec.add(\z, [-1.0, 1.0, \exp].asSpec);
	Spec.add(\ampDb, [-999, 12.0].asSpec);

	//Clears the ProxySpace in the first section
	proxySpace.clear;

	//Manipulates NodeProxies in the ProxySpace
	proxySpace.use({
		//References the factories
		var factories = modules.factories;

		/********************************
		0. Allocate buffers for section
		********************************/
		var instrument_file0 = factories.read(
			"violin_scrapes/violin_scrapes0.wav"
			.ianAudioPath
		);
		var instrument_file1 = factories.read(
			"violin_scrapes/violin_scrapes1.wav"
			.ianAudioPath
		);
		var buffer = factories.alloc(32.0, 1);

		/********************************
		1. Define NodeProxies
		********************************/
		//Inputs sound from the interface
		~playbuf0 = factories.playbuf(instrument_file0);
		~playbuf1 = factories.playbuf(instrument_file1);
		~mixer_left = factories.input(2);
		~mixer_right = factories.input(3);

		//Sums both playbufs together
		~instrument = {
			(~playbuf0.ar + ~playbuf1.ar * 2).tanh * 2;
		};

		//Sums both mixer mixer inputs together
		~mixer_sum = {
			var sig = ~mixer_left.ar + ~mixer_right.ar;
			sig = sig.sum.tanh;
			sig = sig * \ampDb.kr(-16, 0.2).dbamp;
			sig;
		};

		~instrument_mixer_sum = {
			(~mixer_sum.ar + ~instrument.ar).tanh;
		};

		//Writes signal to buffer and granulates it
		~phasor = factories.phasor(buffer);
		~toBuffer = factories.toBuffer(buffer);
		~grains = factories.grains(buffer);

		//Tracks features of inputs
		~amplitude = factories.amplitude();
		~pitch = factories.pitch();
		~peaks = factories.peaks();

		/********************************
		2. Map NodeProxies together
		********************************/
		//Conects phasor and interface to buffer writer
		~toBuffer.map(
			\phasor, ~phasor,
			\input, ~instrument_mixer_sum
		);

		//Connects phasor and feature modules to granulator
		~grains.map(
			\phasor, ~phasor,
			\x, ~pitch,
			\y, ~amplitude,
			\z, ~peaks
		);

		//Connects the interface signal to the feature modules
		~amplitude.map(\input, ~instrument_mixer_sum);
		~pitch.map(\input, ~instrument_mixer_sum);
		~peaks.map(\input, ~instrument_mixer_sum);

		/********************************
		3. Sets NodeProxies' values
		********************************/
		~phasor.set(\limit, 1/64);
		~instrument.set(\ampDb, 6.0);

		/********************************
		4. Rout NodeProxies to output
		********************************/
		//Defines output NodeProxy
		~output.fadeTime_(2.0).play(0);

		//Collects signals in stereo field
		~output[0] = factories.output(
			~instrument,
/*			~mixer_left,
			~mixer_right,*/
			~grains,
			~mixer_sum
		);

		//Adds fx to output
		~output[1] = \filter -> { | in |
			var sig = DelayN.ar(
				in,
				12/1000,
				12/1000,
				\inputScale.kr(1)
			);
			LeakDC.ar(sig);
		};

		//Adds some distortion
		~output[2] = \filter -> { | in |
			var makeSig = {
				var rate = ExpRand(0.05, 0.1);
				var min = rate * 2;
				var max = min * ExpRand(4.0, 16.0);
				LFNoise2.kr(
					LFNoise1.kr(rate).exprange(min, max)
				);
			};
			var modSig = {
				makeSig.value.unipolar(1);
			};
			var sig = OSFold4.ar(
				in * makeSig.value.exprange(1.0, 1.5),
				modSig.value.linlin(0.0, 1, -0.125, -1.0),
				modSig.value.linlin(0.0, 1, 0.125, 1.0);
			);
			LeakDC.ar(sig);
		};

		//Defines an output to be routed to mixer
		~output_toMixer.fadeTime_(2.0).play(2);

		//Collects signals in stereo field
		~output_toMixer[0] = factories.output(
			~mixer_left,
			~mixer_right,
			~instrument,
			~output
		);

		//Puts a short delay on the signal to alter feedback
		~output_toMixer[1] = \filter -> { | in |
			var sig = DelayN.ar(
				in.tanh,
				5/1000,
				5/1000
			);
			LeakDC.ar(sig);
		};

		/********************************
		5. Scales output values
		********************************/
		~output.set(
			//instrument
			\amp0, 1.0,
	/*		//mixer_left
			\amp1, 0.5,
			//mixer_right,
			\amp2, 0.5,*/
			//grains,
			\amp1, 4.0,
			//mixer_sum,
			\amp2, 1.0,
			//the wets
			\wet1, 1.0,
			\wet2, 0.875
		);

		~output_toMixer.set(
			//mixer_left,
			\amp0, 1.0,
			//mixer_right,
			\amp1, 1.0,
			//instrument,
			\amp2, 1.0,
			//output,
			\amp3, 1.0,
			//the wets
			\wet1, 1.0
		);

		/********************************
		6. Record sections
		********************************/
		prompter.string = "Scrape and scratch the violin";

		/********************************
		P.S. Other stuff...
		********************************/
		//Records first four sections into a buffer
		//Allocates a buffer for the sections' cumulative length
		modules.add(
			//60 + 60 + 60 + 30 + 30 + 30 + 30
			\sectionBuffer -> factories.alloc(300, 1)
		);

/*		//Writes signal to buffer
		~sectionPhasor = factories.phasor(
			modules[\sectionBuffer]
		);

		~sectionWriter = factories.toBuffer(
			modules[\sectionBuffer]
		);

		//Maps NodeProxies together
		~sectionWriter.map(
			\input, ~output,
			\phasor, ~sectionPhasor
		);*/

	});

	//Returns no value to end the section manually
	nil;
}