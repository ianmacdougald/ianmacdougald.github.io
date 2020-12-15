{ | modules, proxySpace |
	proxySpace.use({
		/********************************
		3. Sets NodeProxies' values
		********************************/
		~phasor0.set(
			\limit, 1/4,
			\rate, 0.9
		);

		~phasor_meta0.set(
			\limit, 1/4,
			\rate, 0.9
		);

		~phasor_meta1.set(
			\limit, 1/16,
			\rate, 0.9
		);
	});
}
