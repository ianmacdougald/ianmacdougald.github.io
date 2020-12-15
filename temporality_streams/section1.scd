{ | modules, proxySpace |
	var factories = modules.factories;
	proxySpace.use({
		/********************************
		0. Allocate buffers for section
		********************************/
		var buffer = factories.alloc(16.0, 1);

		/********************************
		1. Define NodeProxies
		********************************/
		//Writes signal to buffer and granulates it
		~phasor_meta0 = factories.phasor(buffer);
		~toBuffer_meta0 = factories.toBuffer(buffer);
		~grains_meta0 = factories.grains(buffer);

		//Sums grains0 to mono
		~sumGrains0 = { ~grains0.ar.sum.tanh };

		//Encapsulates the peaks feature within a lag UGen
		~lag_peaks0 = {
			~peaks0.kr.lag(\lag.kr(0.2));
		};

		/********************************
		2. Map NodeProxies together
		********************************/
		~toBuffer_meta0.map(
			\phasor, ~phasor_meta0,
			\input, ~sumGrains0
		);

		~grains_meta0.map(
			\phasor, ~phasor_meta0,
			\x, ~pitch0,
			\y, ~amplitude0,
			\z, ~lag_peaks0
		);

		/********************************
		3. Sets NodeProxies' values
		********************************/
		~phasor_meta0.set(
			\limit, 1/8,
			\rate, 1
		);

		~phasor.set(\limit, 1/8);

		~peaks_meta0.set(\scaling, 2.0);

		/********************************
		4. Rout NodeProxies to output
		********************************/
		~output[0] = factories.output(
			~instrument,
			~grains0,
			~grains_meta0
		);

		/********************************
		5. Scales output values
		********************************/
		~output.fadeTime = 8.0;
		~output.set(
			//fromInterface,
			\amp0, 0.1,
			//grains0
			\amp1, 1.0,
			//grains_meta0
			\amp2, 1.0,
		);

	});

	nil;
}
