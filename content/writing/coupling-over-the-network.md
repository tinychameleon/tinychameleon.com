---
title: "Coupling Over The Network"
date: "2021-05-09T23:42:25Z"
tags: [programming]
---

Recently I've been thinking about some of the tools available to create web applications and how they work together to provide a better maintenance story.
Things with current mindshare like Vue, and things that are less fashionable like Ruby on Rails.
Plenty has been written on the great things both kinds of approaches provide, but what I've been thinking about is the network: the requests that traverse it, and how the distributed system of clients and services interact.

Everyone involved in web development today knows that customers want smooth experiences and the community has responded to that by expending large amounts of engineering time on front end frameworks.
The rise of Single Page Applications, and of their hit-and-miss implementation quality, started an age of instantaneous[^1] customer actions and hidden network requests.
It was no longer acceptable to do round-trips to the server while the customer waited and web applications began to require complex state management to facilitate this demand.

Whose demand this actually was, the customer or the developer or the project manager or the UX designer, is a question never pondered, because the age of the RPC[^2] API is here.
The idea of the Majestic Monolith was put aside in favour of decoupling the front end from the back end, because this is a good thing and will therefore make any project better.
A tragic irony is at play in the tech community, where implementation merit is extrapolated to include product success and customer enjoyment.
The town criers exulting the praise of front end frameworks as proper decoupling of systems to ensure better customer experiences is one such example in many.

To an extent, these people are correct, there is a decoupling present in these thick client and API partitions.
Yet I can't help feel that it is an unsatisfying correctness about it; a bland technical correctness that ignores the larger view.
The chatter involves rendering the front end on the client for speed, quick customer actions, and state management, but this is a misnomer.
What needs to be highlighted is not the front end rendering, which has always happened on the client, not the state management, which needs to happen somewhere anyway, but the logic and creation of UI components on the client.
The shipping of responsibility for constructing the presented user interface to the client is the change: nothing more or less.
The people who enjoy front end frameworks are still right: it is a decoupling, but of UI responsibility.

This responsibility does nothing to actively improve the situation of maintaining a web application.
Where the UI is created does not make maintaining a web application easier, but the abstractions around how UI creation happens can.
What shipping the UI creation responsibility to the client does accomplish is adding network coupling to the web application.
The thick-client needs to obtain data from an API, and I would hazard a guess that those request end points are hard-coded in 99.9% of cases.
These front ends and back ends are still two sides of the same coin: the back end must ensure that changes to the API structure doesn't break the front end client, and the front end cannot stop using the precise end points without breaking.

This is high coupling distributed across network calls, with all the problems network calls bring.
I'm not sure this is a good trade-off for the majority of applications.
Think of the number of actions a web application needs to take: from editing to creating to updating to persisted orders to deletion.
Each of these requires some kind of communication mechanism that must be programmed into the front end, and at the very least you have a request end point and an HTTP verb.
A front end thick-client that has not been updated, perhaps due to caching, may not be able to communicate with a newer version of your back end service.
Contrasted with server created HTML, this is quite the mess.
Server created UI via HTML contains every up to date action a customer can take on any resource, with no worries of caching.
Something has been lost here in the transition to increased front end responsibility and replaced with a brittle, partial solution.

[^1]: Who cares what physics says.
[^2]: Sometimes misspelled as REST.
