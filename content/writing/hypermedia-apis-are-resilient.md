---
title: "Hypermedia APIs Are Resilient"
date: "2022-04-13T16:06:40Z"
tags: [programming]
---

Hypermedia APIs have been on my mind.
They're not very popular at the moment, but I think they make some interesting trade-offs compared to typical Data APIs[^1].

Frontends that display data mutations will always need an API to persist changes and receive updates.
The current zeitgeist achieves this by creating Data APIs which consume and produce JSON.
These APIs work fine, but their API surface area is tied to the complexity of the frontends they power.
As frontend complexity increases, so to does the API complexity.

Development teams begin to consider solutions to the API surface area complexity issue at different points in measured complexity, but the solution tends to be GraphQL.
This has an important trade-off: API surface area complexity vs API flexibility security.
GraphQL reduces the API surface area to a constant -- great for frontends -- and pushes the complexity of piecing together aggregate responses to the GraphQL backend.

The flexibility of a frontend to issue any kind of query also means that attackers have that same power.
The trade of API surface area for maintaining query allow lists and graph-based authorization mechanisms is one that few companies have the resources to make.

Hypermedia APIs provide an alternative.
By returning HTML any API changes are included within the payload, so there is no API query growth within the frontend.
Further mutations also return HTML and benefit from this.
The API surface area still grows, but the frontend logic remains simple and the backend can use typical authorization mechanisms which would already be in place.

I think Hypermedia APIs are going to be a great middle-ground to avoid the complexity associated with other APIs.
Libraries like [htmx](https://htmx.org) and [hotwire](https://hotwired.dev) are already displaying good examples of this complexity reduction.

[^1]: Data APIs range from consuming and producing JSON via RPC to things like GraphQL.
