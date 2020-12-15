# Epoch for Digital Petri Dish (2020)

## Links
* [Recording](https://soundcloud.com/ian-macdougald/epoch-for-digital-petri-dish)
* [Source code](https://github.com/ianmacdougald/portfolio/blob/gh-pages/epoch.scd)

## Description

Epoch for Digital Petri Dish is a fixed-media piece made using [GenOrg](https://github.com/ianmacdougald/GenOrg), an experimental SuperCollider quark I developed for my master's thesis. The core classes in the quark provide functionality for dynamically generating [SynthDef](https://doc.sccode.org/Classes/SynthDef.html) objects, for rendering sound files in [non-realtime](https://doc.sccode.org/Guides/Non-Realtime-Synthesis.html), and for providing support for spatialization in mono, stereo, quad, first order ambisonic, as well as higher ambisonic formats. From there, these processes are bundled together into individual entities, which in turn are collected within entire populations, mutating over time as they hunt and starve and mate and die. 

Currently, there are two divergent versions of this project. The first, located on its *main* branch, is the work I submitted for my Master's thesis, whereas the second, located on the *dev* branch, refactors the library's classes under a framework established in another project of mine called [CodexIan](https://github.com/ianmacdougald/CodexIan), which enables the development of classes with modularized scriptable components. In this way, with the second branch, the user gains the ability to arbitrarily specify the processes that generate, mutate, and spatialize sounds, altering the musical fate of the sonic populations over time.
