# Epoch for Digital Petri Dish (2020)

## Links
* [Recording](https://soundcloud.com/ian-macdougald/epoch-for-digital-petri-dish)
* [Source code](https://github.com/ianmacdougald/portfolio/blob/gh-pages/epoch.scd)

## Description

Epoch for Digital Petri Dish is a fixed-media piece made using [GenOrg](https://github.com/ianmacdougald/GenOrg), an experimental SuperCollider quark I developed for my master's thesis. The core classes in the quark provide functionality for dynamically generating [SynthDef](https://doc.sccode.org/Classes/SynthDef.html) objects, for rendering sound files in [non-realtime](https://doc.sccode.org/Guides/Non-Realtime-Synthesis.html), and for providing support for spatialization in mono, stereo, quad, first order ambisonic, as well as higher ambisonic formats. From there, these processes are bundled together to act like organisms, which in turn are collected within entire populations, that mutate over time as they hunt and starve and mate and die. 

Currently, there are two divergent versions of this project. The first, located on its *main* branch, is the work I submitted for my Master's thesis, whereas the second, located on the *dev* branch, refactors the library under a framework established in another project of mine called [CodexIan](https://github.com/ianmacdougald/CodexIan), which enables the development of classes with modularized scriptable components. In this way, with the second branch, the user gains the ability to arbitrarily specify the processes that generate, mutate, and spatialize sounds.

The current piece is an arrangement of many simulations of evolving populations derived from this library. The source code linked above is an example of one such system I used to make the music. The piece itself is divided into two sections. In the first, large, slow-moving organisms establish a harmonious environment as many families of other musical creatures emerge and subsequently decline. In this period, the musical language is sparse but peaceful. However, in the second section, increasing populations of noisy organisms alter the dynamic at play, displacing statis with disruption, as they fight for continuously diminishing resources. The piece concludes with the collapse of these societies, allowing for the original community of organisms to begin thriving once more. To this end, the music uses the ecologically inspired nature of its tools to suggest a statement about the environment itself. 

In its current form, these tools are still experimental and subject to ongoing development. Future work will entail increasing stability as well as adding comprehensive documentation. Once it is complete, I plan to present it at a conference, as I continue to use it to make music.
