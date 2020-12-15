(
//1.0 Set up server
s.options.memSize = 2.pow(20); 
s.options.numInputBusChannels = 1; 
s.options.numOutputBusChannels = 2; 
s.options.sampleRate = 48e3; 
s.quit.boot;
)

//2.0 Run this.
CodexSonataViewer(\temporalityStreams);
