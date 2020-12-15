# First Circuit Democracy (2020)

## Links
* [Recording](https://soundcloud.com/ian-macdougald/the-first-circuit-democracy)
* [Source code](https://github.com/ianmacdougald/portfolio/blob/gh-pages/first_circuit_democracy/first_circuit_democracy.scd)

## Description

First Circuit Democracy is a piece for an analogue-digital feedback network consisting of an 8-channel Mackie mixer and a simple process running in SuperCollider. 


The network consists of an 8-channel Mackie mixer and a SuperCollider script. The feedback is formed by patching a stereo output from SuperCollider into the first two channels of the mixer, inputting the two submix outputs of the mixer into its third and fourth channels, and returning the main outputs back into SuperCollider. Subsequently, in SuperCollider, the inputs from the hardware are mixed with a long delay line whose gain is randomly modulated and routed to the system outputs.
