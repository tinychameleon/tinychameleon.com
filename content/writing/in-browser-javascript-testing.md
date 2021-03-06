---
title: "In-Browser Javascript Testing"
date: "2020-05-14T01:48:03Z"
tags: ["programming", "testing", "javascript"]
---

While starting some work on Javascript code I was attempting to set up in-browser testing, and to my great surprise, it's still a complicated maze of configuration.
The last time I worked full-time on front-end code was over 5 years ago; back then setting up Karma was a chore and many of the options available today simply didn't exist.
Yet here we are, with no visible improvement to the state-of-the-art when it comes to actually testing your front-end code inside browsers.

I spent a good chunk of time attempting to get Karma, with preprocessor and adapter plugins, to _Do The Right Thing_, time that I will never be able to recover.
Failed change detection, tests running multiple times, and poor configuration discoverability are a few of the issues I ran into; maybe they sound familiar to you too.
I was frustrated with the experience and had to set my project aside, but it did get me thinking about what exactly is wrong.

Karma is only an example of the disastrous problem that is plaguing the Javascript community, and worryingly it seems to have become an ingrained part of life.
The problem is this: integrating numerous small packages to get disparate tools to work together.
When you follow this path you inevitably end with tools experiencing configuration bloat because it's the only way to combine operations.
Each tool sprouts plugin configuration and adapter packages appear, so that tools may work together, and everyone gets their own Rube Goldberg machine of configuration and package versions.
The Javascript community, in their zeal to create better tooling, has [thrown out the Unix Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy).

## js-test-kit
This recent experience sent me flying to find simple, composition oriented tools to use for in-browser testing.
Things with minimal, easily understandable configuration and things that work together without requiring numerous plugins and adapters.
The result is [a starter-kit named js-test-kit](https://github.com/tinychameleon/js-test-kit) which combines a few tools in meaningful ways via Docker and Docker Compose.

Three tasks are necessary for an acceptable reactive, in-browser testing experience:

- Compiling and bundling test and source files
- Watching for changes and automatically reloading
- Serving the HTML, CSS, and Javascript necessary to run the test page

These are the only tasks that js-test-kit implements -- it is up to the user to blend it into their project by tailoring it to their individual needs.

The compilation and bundling is done via Babel and Rollup, both with simple configuration; file watching and reloading is handled by Livereload; and serving files is done by nginx.
Simplicity, not purity, is the important thing in js-test-kit -- there is a plugin to allow Rollup to run Babel because it works well.
Each of the Javascript tools is run on an LTS version of node and all are run inside of containers via Docker Compose.

Through Docker Compose, all containers share a node_modules installation via volume mounting, Livereload and Rollup compose without fiddling with nvm, and nginx is made available with ease.
The nginx container serves the HTML, CSS, and Javascript required by a simple `test_runner.html` file and multi-browser testing is as simple as opening the file in the necessary browser.
All steps are separated and compose together to provide a fairly seamless experience that is understandable and approachable -- no magic configuration.

Regardless of the appeal of js-test-kit to you, I think you should consider the composition of tools you choose.
So take a look, you may find an idea to pilfer.
