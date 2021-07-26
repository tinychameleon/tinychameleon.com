---
title: "Advent of Code 2015: RPG Simulator 20XX"
date: "2021-07-26T00:58:51Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/671609d31b1e4b31d8c1363420db98f427ed101a/2015/21/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/2c7fbb778e1059a081bec7385798987f38075c98/2015/21/solution.rb
---

The [twenty-first Advent of Code challenge](https://adventofcode.com/2015/day/21) is about min-maxing an RPG character build to get the best results for the fewest resources.
There are a few ways to solve this one efficiently, and we'll be taking the lazy approach.

## Part A: Power Overwhelming
The description for this one is very long, so here are some excerpts from the entire problem which go over the important requirements.

> In this game, the player (you) and the enemy (the boss) take turns attacking. The player always goes first. Each attack reduces the opponent's hit points by at least 1. The first character at or below 0 hit points loses.
>
> ...
>
> Your damage score and armor score both start at zero. They can be increased by buying items in exchange for gold. You start with no items and have as much gold as you need. Your total damage or armor is equal to the sum of those stats from all of your items. You have 100 hit points.
>
> ...
>
> You must buy exactly one weapon; no dual-wielding. Armor is optional, but you can't use more than one. You can buy 0-2 rings (at most one for each hand). You must use any items you buy. The shop only has one of each item, so you can't buy, for example, two rings of Damage +3.
>
> ...
>
> You have 100 hit points. The boss's actual stats are in your puzzle input. What is the least amount of gold you can spend and still win the fight?
>
> --- _Advent of Code, 2015, Day 21_

With this much prose it's useful to extract the requirements:

- The player always attacks first.
- Attacks do a minimum of 1 damage.
- The first combatant at or below 0HP loses.
- The player starts with damage and armour stats of 0.
- There is no spending limit.
- The sum of item stats equals the player's stats.
- The player has 100HP.
- The player must have exactly 1 weapon.
- The player can have 0 or 1 piece of Armour.
- The player can have 0, 1, or 2 rings.
- There is only one of each item.
- The boss stats are your puzzle input.

Quite a few requirements, but they will be implemented in few methods so that we can figure out the least amount of gold to spend in order to win the fight.
The first step is to codify some data structures and constants representing the different items and stats associated with the player and the boss.

{{< coderef >}}{{< var part-a-url >}}#L48{{</ coderef >}}
```
PLAYER_HP = 100
BOSS = { hp: 103, damage: 9, armor: 2 }.freeze

SHOP = {
  weapons: [
    { cost: 8, damage: 4, armor: 0 },
    { cost: 10, damage: 5, armor: 0 },
    { cost: 25, damage: 6, armor: 0 },
    { cost: 40, damage: 7, armor: 0 },
    { cost: 74, damage: 8, armor: 0 }
  ],
  armor: [
    { cost: 0, damage: 0, armor: 0 },
    { cost: 13, damage: 0, armor: 1 },
    { cost: 31, damage: 0, armor: 2 },
    { cost: 53, damage: 0, armor: 3 },
    { cost: 75, damage: 0, armor: 4 },
    { cost: 102, damage: 0, armor: 5 }
  ],
  rings: [
    { cost: 0, damage: 0, armor: 0 },
    { cost: 25, damage: 1, armor: 0 },
    { cost: 50, damage: 2, armor: 0 },
    { cost: 100, damage: 3, armor: 0 },
    { cost: 20, damage: 0, armor: 1 },
    { cost: 40, damage: 0, armor: 2 },
    { cost: 80, damage: 0, armor: 3 }
  ]
}.freeze
```

I've chosen to represent items as a simple hash-map and separate them by kind since there are different requirements based on the kind of gear.
You should note that I haven't bothered to transcribe the actual item names, since we only care about the total cost, and that I have added a zero-cost piece of armour and ring to the list to represent the player skipping that purchase.

This kind of problem can generally be solved by using a graph search algorithm like depth-first search with the ability to backtrack to prior states.
We're not going to do that; we're going to brute-force it by checking every solution because the search space isn't that big.
There are 5 weapons, of which exactly 1 must be chosen, 6 armours, 5 of them plus no armour, of which exactly 1 must be chosen, and 6 rings, of which 0, 1, or 2 must be chosen without duplicates.
If we were selecting just weapons and armour there would be _5 * 6 = 30_ pairs, but we also need to factor in ring selections.

Ring selections can be determined by summing the total choices for 0, 1, or 2 rings.
There is only 1 way to choose zero rings and there are 6 ways to choose one ring for a total of 7 choices so far.
Choosing 2 rings from the 6 options yields 15 different pairs via the [binomial coefficient equation](https://en.wikipedia.org/wiki/Binomial_coefficient).
Calculating it is simply a matter of plugging numbers in and solving the equation _6! / (2! * 4!)_.
This means there is a total of 22 possible choices for rings.

Multiplying these numbers together, _5 * 6 * 22_, yields 660 total combinations of gear.
This is not a very large number, which is why brute-forcing will be quick enough for us.

To calculate the least amount of gold we can spend, we'll need to generate those 660 combinations of gear, combine the gear choices into something that represents a geared up player, determine which gear sets result in the player winning, and choose the minimum cost among the winning sets.

{{< coderef >}}{{< var part-a-url >}}#L104{{</ coderef >}}
```
def solve_a
  item_combinations(**SHOP)
    .map { |gear| suit_up(gear) }
    .filter { |_cost, player| fight_victor(player, BOSS) == :player }
    .map { |cost, _player| cost }
    .min
end
```

I've transcribed this directly into a solution method and made a few decision around data types and method names.
From the shop we generate the item combinations, then we suit up the player, find the winner, and obtain the smallest cost.

First let's implement the `item_combinations` method, which is very similar to the breakdown we previously did to determine the total number of combinations.

{{< coderef >}}{{< var part-a-url >}}#L86{{</ coderef >}}
```
def item_combinations(weapons:, armor:, rings:)
  no_ring = rings[0]
  ring_choices = [[no_ring, no_ring]].chain(rings.combination(2)).to_a
  weapons.product(armor).product(ring_choices).map(&:flatten)
end
```

The zero ring choice is explicit, and the 1 and 2 ring choices are made via the call to `Array#combination`, then we generate products for all the different pieces of gear.
That `Array#flatten` call changes the elements from `[weapon, armor, [ring1, ring2]]` into `[weapon, armor, ring1, ring2]`.

With item combinations available the next step is to decide on the player representation generated by the `suit_up` method.
What I would like is a similar representation to the constant boss data, but also associated with a total cost.
A simple array containing two elements will work just fine for this.

{{< coderef >}}{{< var part-a-url >}}#L96{{</ coderef >}}
```
def suit_up(gear)
  cost = sum_stat(gear, :cost)
  damage = sum_stat(gear, :damage)
  armor = sum_stat(gear, :armor)
  player = { hp: PLAYER_HP, damage: damage, armor: armor }
  [cost, player]
end
```

Given an array of gear, there are several sums that must be calculated by a particular key, but the rest of the method is rather simple.

{{< coderef >}}{{< var part-a-url >}}#L92{{</ coderef >}}
```
def sum_stat(gear, stat)
  gear.reduce(0) { |sum, item| sum + item[stat] }
end
```

The `sum_stat` helper method is pretty simple and calculates sums by the stat key and gear it is given.
This feels like something Ruby might have a built-in method for, but I am not sure what it is called if it does exist.

With player representations, we now need to figure out if the player or the boss will win the fight.
The `fight_victor` method will return either the symbol `:player` or `:boss` to indicate who has one.
At this point we stop and think about the turn-based combat system.
There is no reason to simulate the actual combat because the combatant to hit zero or less HP in the fewest turns loses.
The `fight_victor` method can calculate the number of turns for the player to lose and the number of turns for the boss to lose, and if the boss loses in fewer or equal turns, the player wins.
Fewer or equal is necessary because the player always moves first.

{{< coderef >}}{{< var part-a-url >}}#L82{{</ coderef >}}
```
def fight_victor(player, boss)
  turns_to_kill(player, boss) <= turns_to_kill(boss, player) ? :player : :boss
end
```

The `turns_to_kill` method takes the attacker and the target and just calculates the number of turns required to reduce HP to less than or equal to zero.

{{< coderef >}}{{< var part-a-url >}}#L78{{</ coderef >}}
```
def turns_to_kill(attacker, target)
  target[:hp].fdiv([1, attacker[:damage] - target[:armor]].max).ceil
end
```

The calculation here is where the minimum of 1 damage per attack is enforced, as well as ensuring that turns are whole numbers.
Any fractional result implies an additional turn, which the `Float#ceil` method handles.

With all that done, we can figure out what the least amount of gold to win the fight is.

```
$ run -y 2015 -q 21 -a
121
```

## Part B: Fleeced by Charisma
The second part of this challenge twists the shopkeeper into a charismatic minion that deceives the player into spending as much gold as possible while still losing the fight.

> Turns out the shopkeeper is working with the boss, and can persuade you to buy whatever items he wants. The other rules still apply, and he still only has one of each item.
>
> What is the most amount of gold you can spend and still lose the fight?
>
> --- _Advent of Code, 2015, Day 21_

This change requires a bit of refactoring to support choosing the minimum or maximum cost associated with the player representation.
It will also require choosing the winner instead of only checking player victories.

The original `solve_a` method content has to be extracted into a reusable `solve` method which accepts a `winner` to filter for and should return the costs of each player representation.

{{< coderef >}}{{< var part-b-url >}}#L104{{</ coderef >}}
```
def solve(winner)
  item_combinations(**SHOP)
    .map { |gear| suit_up(gear) }
    .filter { |_cost, player| fight_victor(player, BOSS) == winner }
    .map(&:first)
end
```

There are few changes here: the `:player` symbol check has been replaced by a variable, and the call to `Array#min` over costs has been replaced by a call to get the first element of each player representation.
That first element is the cost.

Now the `solve_a` and `solve_b` methods can be written simply to use the more generic `solve` and each of them encodes the minimum and maximum logic and winner state they require.

{{< coderef >}}{{< var part-b-url >}}#L111{{</ coderef >}}
```
def solve_a
  solve(:player).min
end

def solve_b
  solve(:boss).max
end
```

Running the solution shows the maximum gold we can spend and still lose to the boss.

```
$ run -y 2015 -q 21 -b
201
```

## Confidence Through Math
Two challenges in a row have been made easier by using some mathematics before diving into a solution.
Aside from the entertaining problem context I like this problem set up because it demonstrates that brute-force solutions don't have to be slow or bad.
As long as you can prove your solution has a rather small search space more complex algorithms can be avoided entirely.
