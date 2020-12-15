(
//1.0 Set up server
s.options.numInputBusChannels = 4;
s.options.numOutputBusChannels = 4;
s.options.memSize = 2.pow(20);
s.quit.boot;
)

(
//2.0 Initialize ProxySpace
p = ProxySpace.push; 
p.fadeTime = 0.2;
)

(
//3.0 Define NodeProxies
~input.clear;
~output.clear;
~to_mixer.clear;

~output.play;
~to_mixer.play(2);

//Create input
~input[0] = { 
	var sig, amp; 
	//Input from 3rd and 4th channels of interface
	sig = SoundIn.ar([2, 3]) * 8; 
	amp = PeakFollower.ar(sig.sum / 2);
	sig.tanh * amp;
}; 

//Add a delay
~input[1] = \filter -> { | in |
	DelayN.ar(
		in, 
		32.0, 
		LFNoise2.kr(ExpRand(1/32, 1/16))
		.exprange(24, 32)
	); 
}; 

//Modulate wet value of delay
~input_wet1_map = { 
	LFNoise2.kr(
		LFNoise1.kr(ExpRand(0.005, 0.05))
		.exprange(0.1, 0.8)
	).unipolar;
}; 

~input.map(\input, ~input_wet1_map);

//Create output
~output[0] = { 
	CompanderD.ar(
		(~input.ar * 2).tanh
		0.5, 
		1.0, 
		1/4, 
		0.005, 
		0.1
	) ;
}; 

//Send output to mixer
~to_mixer[0] = { ~output.ar };
)
