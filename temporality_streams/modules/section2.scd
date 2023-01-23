{ | modules, proxySpace |
	var cleanup = modules.cleanup;
	var factories = modules.factories;
	proxySpace.use({
		//0. Allocate buffers for section
		var buffer = factories.alloc(8.0, 1);

		//1. Define NodeProxies
		//Writes signal to buffer and granulates it
		~phasor_meta1 = factories.phasor(buffer);
		~toBuffer_meta1 = factories.toBuffer(buffer);
		~grains_meta1 = factories.grains(buffer);

		//Sums all grains together
		~sumGrains_meta = {
			(~grains_meta0.ar.sum + ~sumGrains0.ar).tanh;
		};

		//Tracks features of inputs
		~amplitude_meta1 = factories.amplitude();
		~pitch_meta1 = factories.pitch();
		~peaks_meta1 = factories.peaks();

		//2. Map NodeProxies together
		~amplitude_meta1.map(\input, ~sumGrains_meta);
		~pitch_meta1.map(\input, ~sumGrains_meta);
		~peaks_meta1.map(\input, ~sumGrains_meta);

		~toBuffer_meta1.map(
			\phasor, ~phasor_meta1,
			\input, ~sumGrains_meta
		);

		~grains_meta1.map(
			\phasor, ~phasor_meta1,
			\x, ~pitch_meta1,
			\y, ~amplitude_meta1,
			\z, ~peaks_meta1
		);

		//3. Sets NodeProxies' values
		~phasor_meta1.set(
			\limit, 1/16,
			\rate, 1
		);

		~peaks_meta1.set(\scaling, 2.0);

		//4. Rout NodeProxies to output
		~output[0] = factories.output(
			~instrument,
			~grains0,
			~grains_meta0,
			~grains_meta1
		);

		//5. Scales output values
		~output.set(
			//instrument,
			\amp0, 0.1,
			//grains0
			\amp1, 0.2,
			//grains_meta0
			\amp2, 0.2,
			//grains_meta1
			\amp3, 0.2
		);

	});
}
