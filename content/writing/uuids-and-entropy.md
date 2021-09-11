---
title: "UUIDs and Entropy"
date: "2021-09-11T19:47:30Z"
tags: [programming]
---

UUIDs are 128-bit numbers and are frequently compared to 64-bit and 32-bit numbers in databases for key data types.
I haven't ever seen the collision rate framed within the context of the reality of high-volume distributed systems.

When UUIDs are discussed for keys it is likely that UUIDv4 is the version discussed; a UUIDv4 is made of 122 bits of randomness and 6 bits of UUID information.
Inevitably, the fact that around 5.1 million entries is enough to hit the 50% collision rate for randomized 64-bit integers will surface yet there will be individuals who still defend 32-bit and 64-bit keys.
Sometimes the objections are valid, like needing data locality for faster index updates, but I think if this is critical then you need an isolated solution where you can optimize for that write volume.

The reality of working on high-volume distributed systems is that you don't care about the number of entities required to hit 50% probability of collision.
You care about the 0.1% probability of collision because your system is generating millions of entries per day and that means thousands of errors.
At billions of entries you need to care about even smaller probabilities.
Collision errors become performance bottlenecks in a similar way that branch mispredictions do for processors.

A 64-bit number yields 1.9×10{{< sup 8 >}} (190,000,000) entries before reaching the 0.1% probability of collision.
At 1 million entries generated per day this rate will be reached in 190 days or ~0.52 years.
Thousands of errors per day in half a year.

A 122-bit[^1] number yields ~1.03×10{{< sup 17 >}} (103,000,000,000,000,000)[^2] entries before reaching that probability threshold.
That's 103,000,000,000 days at a rate of 1 million entries per day or ~282,191,780 years.

Just use UUIDs for your distributed systems, especially if they're going to grow in traffic volume.
Obtaining more storage is an easier problem to solve than migrating to a UUID.

[^1]: Remember, UUIDv4 uses 6 bits for the UUID format and 122 bits for randomness.
[^2]: 103 quadrillion, or 103 million sets of 1 billion.
