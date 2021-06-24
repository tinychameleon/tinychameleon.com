---
title: "Multi-Page Single-Page Applications"
date: "2021-06-24T15:56:46Z"
tags: [programming]
---

I keep thinking about the nature of multi-page and single-page applications and of the advice that is offered up when someone asks when to choose one or the other.
A lot of the time the advice is nebulous and alludes to some theoretical interactivity threshold where the only compass is an instinctive "you'll know it when you see it".
My experience with single-page applications leads me to a different conclusion surrounding when the technology should be utilized and is based on application data.

I don't think interactivity itself factors into the equation at all because even multi-page applications can embed a view framework, like React, into a page when necessary.
Rather, I think the threshold lies elsewhere in how the application obtains the necessary data to function.
When I think of the best experiences I've had with single-page applications I do not think of the myriad of businesses that implement forms with them.
I think of applications like Google Sheets.

The major difference that I see involves how the application obtains data.
Google Sheets will download the necessary data to use the application as it loads and during use there are no loading animations.
All data that needs to be saved is saved in the background; it feels like using a native application in this respect.
Typical business single-page applications are mired in loading spinners as they grapple with their user interfaces rendering much faster than the network can deliver data.

These single-page applications are really multi-page single-page applications.
They use URL-based routing to determine what to display and fetch data accordingly which is unlike their good single-page application counterparts.
When I use these applications, increasingly on mobile devices, they do not feel effective.
I lose requests regularly as cell towers prioritize other requests, I sit waiting for loading spinners.

There are no good choices to fix these problems for multi-page single-page applications.
You could implement a caching layer via service workers or the application directly, but then you have the problem of distributed cache-busting.
You also have the problem of ensuring your updates are compatible with your cache, or at the very least that your services are capable of withstanding a thundering herd as cache flushes sweep through your user-base when you release a new version.

I really don't like the user experience these multi-page single-page applications provide to me.
Multi-page single-page applications, like the new version of Reddit, come with so many annoyances to me as a user.
It's a shame that these solutions have taken hold instead of embedding view frameworks where necessary.
