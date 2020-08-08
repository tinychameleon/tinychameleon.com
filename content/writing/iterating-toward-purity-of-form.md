---
title: "Iterating Toward Purity of Form"
date: "2020-05-05T05:02:27Z"
tags: ["programming", "gaming"]
---

All really good programs ever built focus intensely on a core set of features, which inevitably become associated properties.
Modal editing in vim, flexibility in Emacs, and the illegibility of Perl are all great examples of this effect.
In fact, philosopher's even have their own variant of the editor war, revolving around the [existence of properties](https://en.wikipedia.org/wiki/Problem_of_universals).

One theory in particular fits very nicely into the creation and maintenance of software, which I've hinted at in the title of this post: Plato's Theory of Forms.
But in order to continue, you need to understand the Theory of Forms... a bit, so I'm going to summarize, and butcher it, until it fits into a single sentence.
Here's Plato's Theory of Forms: each concept has a pure essence --- a Form, like Emacs' flexibility --- and impure physical manifestations, like your IDE.
That's all you need to know for the remainder of this essay, which is going to focus on how Purity of Form relates to one of my favourite games, Doom 3, and eventually your own code.

The development of Doom 3 and the subsequent Doom 3: BFG Edition remastering gives us an interesting lens to analyze Purity of Form and how it can improve software.
To start, we really need to discuss the elephant in the room: what the heck is Doom 3 really about?
There's no way we can effectively determine if the BFG Edition was worth the effort without arriving at some kind of definition for the Form of "Doom-ness".
So what's Doom 3 made of then?
Well, it's an action-horror title, and it has guns, running, a blander-than-white-bread villain, explosions, and demons.
Really, when you get right down to it, the entire game is about shootin' demons --- it doesn't even have subtitles --- and I'm satisfied with this as a definition of "Doom-ness".

Right, so how does the original release of Doom 3 stack up against our Form of "Doom-ness"?
Not particularly well, I'm afraid.
You see, id Software made some interesting design choices in the original release which attempted to flip the genre to horror-action.
As a starter, the locations were extraordinarily dark --- apparently ambient light sources don't exist on Mars --- and this is quite bad because you can't be shootin' demons when your screen is mostly black pixels, almost all of the time.
The second, and more serious, issue was the flashlight mechanic --- see, the character you play can carry a battalion's worth of guns and ammunition, but can't duct tape a flashlight to a weapon.
The original incarnation of the game forced you to use a flashlight to see, or have a weapon out to shoot.
Between these two problems, most of the game was actively working against our definition of "Doom-ness" --- we're not shootin' demons because we're blind or weaponless.

Then in 2012, the BFG Edition sauntered into my heart, all because the designers recognized Purity of Form and "Doom-ness".
The remastering banishes the flashlight, instead giving the player a shoulder-mounted light, and takes a giant leap toward "Doom-ness" by allowing a gun to always be at the ready for shootin' demons.
Unfortunately, even in 2012, ambient lighting sources still do not exist on Mars, but the shoulder-mounted light does partially solve the darkness issue.
Since you always have a gun out, there's little reason to ever have the shoulder-mounted light off, which means your screen is no longer dominated by black pixels.
Changes like this, ones that make huge strides in quality-of-life, are always due to iterating toward Purity of Form.
It's safe to say that Doom 3 BFG Edition is much closer to "Doom-ness" than the original, and was worth the cost of remastering.

Your programs are like this too --- maybe they're not about shootin' demons, but they have a kernel of "Doom-ness".
Finding that Purity of Form probably requires a bit more effort than Doom 3, since I cheated and picked an example where the only feedback loop is literally shootin' demons.
Think about your critical features, about your error kernels, about the things your program could not do without.
Part of this process is recognizing things your software really doesn't need --- cut those features out, or minimize them, if you can.
Grasp at those pure Forms, iterate toward them, and build great software.
