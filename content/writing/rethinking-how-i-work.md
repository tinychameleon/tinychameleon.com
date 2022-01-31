---
title: "Rethinking How I Work"
date: "2022-01-31T02:58:20Z"
tags: [programming, tools]
---

I've used many different tools over the years to build a wide variety of systems.
Simple text editors to full IDEs and all the intermediate stages in-between have let me construct typical web applications to petabyte-scale data warehousing solutions.
We've become spoilt for choice when it comes to tools and with new tools emerging every year I've decided that it's time to think about how I work and relate to this changing environment.

I've always been a minimalist at heart and most IDE functionality stays untouched in my hands.
My reasoning has always been that there are better things to do with my time than grapple with the tomes of IDE documentation.
I do appreciate the integration these tools accomplish, but the time I've lost to fixing IDE configuration reminds me that this integration isn't a unification of functionality.
It's merely a well-crafted facade over an existing multi-part tool-chain.

When I say "multi-part tool-chain" I don't mean that programs shouldn't be combined to produce a specific effect.
I mean that the combination shouldn't require complex logic, that wiring up pieces should be as simple as possible.
The more logic needed to combine two pieces the greater the risk of the combined whole breaking.
Extending this to some of the large multi-part tool-chains that exist and it's a small miracle anything works at all.

I realize this is starting to sound like I'm describing some of the [Unix philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) in a round-a-bout manner.
In fact, Doug McIlroy documented the second tenant of the Unix philosophy as follows:

> Expect the output of every program to become the input to another, as yet unknown, program. Don't clutter output with extraneous information. Avoid stringently columnar or binary input formats. Don't insist on interactive input.
>
> --- _Doug McIlroy, Bell System Technical Journal, 1978_

I am going to make a statement with which you may have violent disagreement: the existing Unix tools are bad because they do not prioritize delineating human and computer output consumption.
There are too many tools that disregard what McIlroy has written above, inevitably leading to brittle composition and the growth of the multi-part tool-chain logic I described above.

If the existing multi-part tool-chains are to become unified tool-chains there needs to be orders of magnitude more focus given to stability of output.
When I work I want to focus on the task at hand with tools that stay out of my way and can be relied upon to produce stable output.
The only way I can seemingly accomplish this currently is to reduce the number of tools I use and to reduce their companion extensions.

The easiest way I can see to accomplish this for my base tooling is to select an editor and a shell which require little to no configuration and avoid deluges of plug-ins.
I see no way around the existing Unix tools except to limit myself to a small subset of their functionality for work.

A close approximation could be better than nothing or hinder greatly depending on the work.
I've been thinking about basing my attempt at a unified tool-chain around vanilla vim and bash and throwing away most of my configuration for zsh, Emacs, and other tools I have picked up.
My chosen work hardware being a laptop, vim seems like a decent choice for an editor.
If I used a workstation I would consider Acme, but a mouse-oriented editor is an untenable thought on a trackpad.

I'm hopeful that I will be able to come up with something effective that does not place my productivity in jeopardy.
