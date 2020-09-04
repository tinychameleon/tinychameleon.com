---
title: "The Pokémon Experience"
date: "2020-09-04T18:47:50Z"
tags: ["gaming"]
---

The Pokémon franchise has been available in North America for around 22 years and recently its received a lot of criticism.
Some of that criticism is warranted, but this is not about newer titles like Sword and Shield; this is about travelling backward in time to think about why Pokémon works so well as a formula, about what makes it tick.
We're going to travel back to Generation 1, to Pokémon Yellow, and poke at the design philosophy of the game.

If you're old like me, you can probably recall how excited you were to begin your journey to become a Pokémon Master, learning how to throw Poké Balls from a grumpy elderly fellow.[^1]
You may have even begun with Pokémon Yellow, seeing all those glorious colours for each town, taking advantage of the technology leap within the Game Boy Color.
Those fond memories are rooted in a wonderful combination of design ideas that I think still out-compete many currently popular games.

When I think back to my time playing Pokémon Yellow, I think about the world itself, the gyms, the routes, the caves.
I think about my first time making it through Mt. Moon and arriving in Cerulean City; about how badly Misty's Starmie crushed me.
As a child, I didn't recognize a skill check for what it was, my only thought was to make my Pokémon stronger.
It was cool that each town's gym was a different theme, in type and in aesthetic, and the challenge of overcoming a gym leader was a motivating goal.

This hidden-in-plain-sight nature of the Pokémon Gym skill checks provides the formula with a super-power: the ability to decouple local and global game progression.[^2]
This is something I think is critical to why the Pokémon games are so memorable, because the design naturally causes this separation of local autonomy and global progression.
As a player, you have complete local autonomy, and the Pokémon gyms mostly stop you from progressing too far forward.

Local autonomy isn't something a kid thinks about, but the game's designers sure did, because there are almost no prescribed orderings to any encounters in the game.
I think most people can recognize the random wild Pokémon encounters as something unique to their own experience.
Randomizing these encounters was a fabulous way to help ensure that every player had a unique experience[^3] on any given route without having to add much complexity.
Hunting down specific Pokémon, the exhilaration brought forth from the silhouette sliding onto the screen, the anxiety while whittling Hit Points, and finally the satisfaction of catching the prize all hinge on random encounters.
It wouldn't be memorable if you could predetermine what kind of Pokémon appear.

Something that I think people miss about local autonomy is that Pokémon Trainer encounters are also largely ordered at the player's discretion.
From routes to caves, the order which you battle Pokémon Trainers is not prescribed by the designers.
Without a specific order or knowing what Pokémon will oppose you these battle experiences are largely unique across players.
You can follow the hints associating Pokémon types with particular Pokémon Trainer sprites or not; you can avoid certain Pokémon Trainers entirely or not.
You battle your way through the world however you see fit.

Exploring the world is a major part of the game and rewards you with legendary Pokémon, if you can solve the dungeon puzzles and are strong enough competition.
These areas, off the path, the Power Plant, Seafoam Islands, are a break from the normal formula and tend to lean towards pure exploration.
I still remember looting the plant, wondering what kinds of goodies I would find, only to be surprised by the Voltorb and Electrode encounters through fake items.
These types of fun encounters are scripted, but can change how you approach the remainder of the area.[^4]

All of these preceding design components are changed by the largest piece of the game's mechanics: training your Pokémon.[^5]
It's a simple thing, choosing four moves for each Pokémon, but it defines your time and experience in the world.
There are a vast number of combinations of Pokémon and moves which makes player experiences unique, and to prove it we're going to figure out approximately how many possibilities exist.

A quick search tells me there are around 165 moves in Pokémon Yellow, and of course, 151 Pokémon to choose from, but not all Pokémon are available and we should assume that some are unviable to use.
Likewise, we should assume that most moves are unavailable to any given Pokémon or simply unviable.
I think 50% of all Pokémon is a good estimate for viability, and that around 12.5% of moves should be available to any Pokémon based on their level-up progression and TM access.
That gives us 76 Pokémon to choose from and around 21 moves per Pokémon; those numbers feel like they're acceptable.

Things are about to get a bit math heavy, so the following text has many footnotes indicating how things are calculated to avoid saturating the explanation with equations.

Calculating the combinations of moves from the move pool will tell us how many possible move-sets any Pokémon has; I am defining a "move-set" to be a choice of 4 moves.
Choosing move-sets out of a 21 move pool gives us 5,985[^6] different move-sets.
That's _one_ Pokémon, our party has _six_ Pokémon with independent move-sets.
Independent events can be calculated by exponentiation, so the total number of possible party move-sets is 4.6×10{{< sup 22 >}}[^7], approximately.

How many different parties of 6 Pokémon can we use?
Choosing a party out of the 76 viable Pokémon, including repetition for the people who want to use multiples, gives us 192,699,928,576[^8] possible parties.
I am going to represent that as 1.9×10{{< sup 11 >}}.

Each possible party has an equivalent number of possible party move-sets, so to get the total possible viable parties across move-sets we simply multiply them together.
That multiplication tells us that approximately 8.74×10{{< sup 33 >}} unique, viable party-and-move-set combinations exist.
To put this into perspective, the observable universe has a diameter of roughly 8.8×10{{< sup 26 >}}m, 7 zeroes _less_ than the total number of combinations of viable Pokémon Yellow parties!

That's a lot of choice for a hand-held game from the late 90s.
It's a lot of possibilities and potential for unique experiences even compared to games today.
Everything I've mentioned contributes to these unique player experiences.
Your adventure will be different from my adventure and every adventure is organic, stemming from your autonomous exploration in each area and choice of Pokémon and moves.
This is why the Pokémon formula works, why it's memorable, and why it's always going to be popular.
The Pokémon experience is here to stay and it's depth of choice is measurably universal.

[^1]: In the Japanese version he's passed-out, drunk. I guess that was too risqué for the North American market, but it raises the question: were Japanese children, at the time, familiar with drunkards passed-out on the street?

[^2]: Obviously, as a child, I recognized this great design immediately, lauded it, and proceeded to use my amazing intellectual abilities to repeatedly lose to nearly every gym leader.

[^3]: Well, mostly unique. I'm sure there are some people out there who have had identical encounter experiences on certain routes.

[^4]: Particularly if you end up tanking Self-Destructs with your face.

[^5]: Later titles attempted to make this a bit more interesting with IVs and natures, but ultimately these mechanics do not make as large a difference. The focus on more types and more moves is what really pushes forward.

[^6]: Choosing `k` items out of a set of `n` items can be calculated using `n! / k!(n - k)!`. In our case `k` is 4 and `n` is 21.

[^7]: 6 Pokémon, 5,985 move-sets. 5,985{{< sup 6 >}} ≅ 4.6×10{{< sup 22 >}}.

[^8]: Similar to the move-sets: 6 party members, 76 choices. 76{{< sup 6 >}} = 192,699,928,576.
