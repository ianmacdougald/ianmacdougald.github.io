# Epoch for Digital Petri Dish (2020)

## Links
* [Recording](https://soundcloud.com/ian-macdougald/epoch-for-digital-petri-dish)
* [Source code](https://github.com/ianmacdougald/ianmacdougald.github.io/blob/gh-pages/epoch.scd)

## Description

Epoch for Digital Petri Dish is a fixed-media piece made using [GenOrg](https://github.com/ianmacdougald/GenOrg), a SuperCollider quark I developed for my master's thesis. The quark's core classes provide functionality for dynamically generating [SynthDef](https://doc.sccode.org/Classes/SynthDef.html) objects, for rendering sound files in [non-realtime](https://doc.sccode.org/Guides/Non-Realtime-Synthesis.html), and for providing support for spatialization in mono, stereo, quad, first-order ambisonic, as well as higher-order ambisonic formats. From there, these processes are bundled together to act like organisms that mutate over time as they hunt and starve and mate and die.

Currently, there are two divergent versions of this project. The first, located on its *main* branch, is the work I submitted for my master's thesis, whereas the second, located on the *dev* branch, refactors the library under a framework established in another project of mine called [Codex](https://github.com/ianmacdougald/Codex), which enables the development of classes with modularized scriptable components. In this way, with the second branch, the user gains the ability to arbitrarily specify the processes that generate, mutate, and spatialize sounds.

In its current form, the library is still experimental and subject to ongoing development. Future work will entail increasing stability as well as adding comprehensive documentation. Once this work is complete, I plan to present it at a conference, as I continue to use it to make music.

This piece is an arrangement of many simulations of evolving populations derived from this library. The source code linked above is an example of one such system I used to make the music. 

