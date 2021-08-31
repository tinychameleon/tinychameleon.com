---
title: "Advent of Code 2015: Wizard Simulator 20XX"
date: "2021-08-31T03:02:15Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/773ce60bea93a369c988e7bd1c4494190fa3d266/2015/22/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/64a2ce0c54165adc7e10c4aaf4d8c51f2dc9ff0a/2015/22/solution.rb
---

Instead of swords and hand-to-hand combat the [twenty-second Advent of Code challenge](https://adventofcode.com/2015/day/22) has us playing a wizard who casts spells!
This problem will require using depth-first search and pruning spell choices to be effective.

## Part A: Anyway, I Started Blasting
This challenge has many similarities with the prior one, except we do not need to take into account boss armour and our character doesn't get to wear armour.
The important new details are all related to the spells we can choose to cast.

> On each of your turns, you must select one of your spells to cast. If you cannot afford to cast any spell, you lose. Spells cost mana; you start with 500 mana, but have no maximum limit. You must have enough mana to cast a spell, and its cost is immediately deducted when you cast it. Your spells are Magic Missile, Drain, Shield, Poison, and Recharge.
>
> - Magic Missile costs 53 mana. It instantly does 4 damage.
> - Drain costs 73 mana. It instantly does 2 damage and heals you for 2 hit points.
> - Shield costs 113 mana. It starts an effect that lasts for 6 turns. While it is active, your armor is increased by 7.
> - Poison costs 173 mana. It starts an effect that lasts for 6 turns. At the start of each turn while it is active, it deals the boss 3 damage.
> - Recharge costs 229 mana. It starts an effect that lasts for 5 turns. At the start of each turn while it is active, it gives you 101 new mana.
>
> Effects all work the same way. Effects apply at the start of both the player's turns and the boss' turns. Effects are created with a timer (the number of turns they last); at the start of each turn, after they apply any effect they have, their timer is decreased by one. If this decreases the timer to zero, the effect ends. You cannot cast a spell that would start an effect which is already active. However, effects can be started on the same turn they end.
>
> You start with 50 hit points and 500 mana points. The boss's actual stats are in your puzzle input. What is the least amount of mana you can spend and still win the fight? (Do not include mana recharge effects as "spending" negative mana.)
>
> --- _Advent of Code, 2015, Day 22_

There are a lot of details in here about spells, so let's start by codifying them into a database the solution can query for details when running calculations.

{{< coderef >}}{{< var part-a-url >}}#L46{{</ coderef >}}
```
PLAYER = { hp: 50, mana: 500 }.freeze
BOSS = { hp: 55, damage: 8 }.freeze

SPELLS = {
  magic_missile: { mana: 53, damage: 4 },
  drain: { mana: 73, damage: 2, heal: 2 },
  shield: { mana: 113, armor: 7, turns: 6 },
  poison: { mana: 173, damage: 3, turns: 6 },
  recharge: { mana: 229, regen: 101, turns: 5 }
}.freeze
```

As you can see, each spell contains its mana cost and other related mechanics.
We will built the spell selection mechanism by iterating through these spells repeatedly as we attempt to find the minimum amount of mana that can be spent and still win.

Since depth-first search will be used we can start by writing a skeleton of the algorithm and begin deciding on data structures to represent spells and mana costs.

{{< coderef >}}{{< var part-a-url >}}#L117{{</ coderef >}}
```
def solve_a
  mana = Float::INFINITY
  queue = [[]]

  until queue.empty?
    spells = queue.pop
    cost = mana_cost(spells)
    ...
  end

  mana
end
```

We'll use an array of keywords as the spells chosen and continue iterating through those by eventually adding a mechanism to select the next possible spells.
Each time through the loop `spells` holds the history of spell selections.
The `mana` variable will begin at infinity and hold our smallest total mana cost that leads to victory.

First we need a way to compute the cost of the current spells the character has used which is called `mana_cost`.

{{< coderef >}}{{< var part-a-url >}}#L63{{</ coderef >}}
```
def mana_cost(spells)
  spells.reduce(0) { |cost, spell| cost + SPELLS[spell][:mana] }
end
```

Using the `:mana` property of each spell and the `Array#reduce` method to sum all the costs of the current spell history makes this a one-liner.

The next problem to solve is that we lose if we cannot cast a spell, so we must be able to calculate our mana over time including regeneration abilities.
We'll call this method `mana_pool` and it will return the total mana remaining to be spent on spells; when this method returns a negative amount the character does not have enough mana to cast the last spell chosen.

{{< coderef >}}{{< var part-a-url >}}#L98{{</ coderef >}}
```
def mana_pool(spells)
  spells.each_with_index.reduce(PLAYER[:mana]) do |pool, entry|
    k, i = entry
    spell = SPELLS[k]

    regen = spell.fetch(:regen, 0)
    regen *= spell_ticks(spell, spells.size, i) if k == :recharge
    pool - spell[:mana] + regen
  end
end
```

Each time we calculate mana from a list of spells we start from the player's default mana value and subtract for every cast.
If the spell is the Recharge spell we need to determine the number of turns it has been active, which I have called "ticks" as is common in games, and apply that to the reduction as an offset.

The `spell_ticks` method calculates the number of turns the spell has been active based on the given set of spells.

{{< coderef >}}{{< var part-a-url >}}#L67{{</ coderef >}}
```
def spell_ticks(spell, size, index)
  [0, [spell[:turns], 2 * (size - index - 1)].min].max
end
```

It clamps the number of turns between 0, the number of player and boss turns that have occurred, and the number of turns the spell effect lasts using arrays for their `Array#min` and `Array#max` methods.

We also need to be able to determine if the player or boss has died from the choices that have been made over time.
These are simple methods that calculate boss or spell damage and compare it to the player or boss HP value.

{{< coderef >}}{{< var part-a-url >}}#L109{{</ coderef >}}
```
def player_dead?(spells)
  boss_damage(spells) >= PLAYER[:hp]
end

def boss_dead?(spells)
  spell_damage(spells) >= BOSS[:hp]
end
```

Let's start with the `spell_damage` method because it is very similar to the `mana_pool` method.
It iterates over all the chosen spells, sums up the damage values of each one, and applies damage-over-time if a spell lasts a specific number of turns.
Here we re-use the `spell_ticks` method for those damage-over-time effects.

{{< coderef >}}{{< var part-a-url >}}#L71{{</ coderef >}}
```
def spell_damage(spells)
  spells.each_with_index.reduce(0) do |damage, entry|
    k, i = entry
    spell = SPELLS[k]
    next damage unless spell.key?(:damage)

    ticks = spell.key?(:turns) ? spell_ticks(spell, spells.size, i) : 1
    damage + spell[:damage] * ticks
  end
end
```

Boss damage is a bit more complicated to calculate because we have the Shield spell giving the player armour over time as well as the Drain spell which heals the player.
There is also the fact that on the player's first turn the boss has not went.

{{< coderef >}}{{< var part-a-url >}}#L82{{</ coderef >}}
```
def boss_damage(spells)
  return 0 if spells.size < 2

  shield = SPELLS[:shield]
  armor = SPELLS[:shield][:armor]
  armor_reduction = spells.each_with_index
    .filter { |spell, _i| spell == :shield }
    .map { |_, i| armor * spell_ticks(shield, spells.size, i).fdiv(2).ceil }
    .sum

  healing_reduction = spells.map { |s| SPELLS[s].fetch(:heal, 0) }.sum

  max_damage = BOSS[:damage] * [0, spells.size - 1].max
  [1, max_damage - armor_reduction - healing_reduction].max
end
```

A third use of the `spell_ticks` method allows calculating the sum of armour reduction that occurs over the spell history provided as `spells`.
Since the `spell_ticks` method returns the number of turns a spell is active for the player and the boss, to calculate armour reductions we need to divide that result by 2.
The healing reductions are much simpler and the final calculation ensures that the total boss damage minus all reductions stays above 0.

The last component needed for the depth-first search is the ability to choose the next spell to cast!
By choosing another spell we can add the list of spells to the work `queue` created above in the depth-first search skeleton.
Let's call the method `next_spells`.

{{< coderef >}}{{< var part-a-url >}}#L57{{</ coderef >}}
```
def next_spells(prior_spells)
  prior_spells = prior_spells[-2..] if prior_spells.size >= 2
  effects = SPELLS.filter { |_, v| v.key?(:turns) }.keys - prior_spells
  SPELLS.reject { |_, v| v.key?(:turns) }.keys + effects
end
```

Given a list of prior spells and the fact that spell effects occur before the player choice and that they can be started again on the turn they end without any cool-down, we can look at the last two spells to determine if any of the over-time spells qualify for another casting.
We filter the turn-based spells down to only ones that haven't been cast within the last two player turns and then combine those with the instant spells.

Now we can implement the depth-first search body.

{{< coderef >}}{{< var part-a-url >}}#L122{{</ coderef >}}
```
until queue.empty?
  spells = queue.pop
  cost = mana_cost(spells)

  next if cost >= mana || mana_pool(spells).negative?
  next if player_dead?(spells)

  if boss_dead?(spells)
    mana = cost if cost < mana
  else
    next_spells(spells).each { |s| queue << spells + [s] }
  end
end
```

We skip a set of chosen spells if their cost is greater than the current minimum mana cost, if the player doesn't have enough mana to cast them, or if it leads to the player's death.
This lets us short-circuit any choice paths that are undesirable.
When the boss dies to a particular set of spells we record the total mana cost of casting them and no longer need to pursue that chain of spells.
Otherwise we generate the next spell choices and add them to the work queue.

Finally, we can see what the minimum spell cost is for victory.

```
$ run -y 2015 -q 22 -a
953
```

## Part B: I'm Bleeding Out Here
The second part of the challenge increases the game difficulty and applies a permanent damage-over-time effect to the player.

> On the next run through the game, you increase the difficulty to hard.
>
> At the start of each player turn (before any other effects apply), you lose 1 hit point. If this brings you to or below 0 hit points, you lose.
>
> With the same starting stats for you and the boss, what is the least amount of mana you can spend and still win the fight?
>
> --- _Advent of Code, 2015, Day 22_

This requires a small amount of refactoring to our solution for calculating boss damage.
We're going to add two modes to the solution, `:easy` and `:hard`, to differentiate these cases within the damage calculations.

{{< coderef >}}{{< var part-b-url >}}#L114{{</ coderef >}}
```
def player_dead?(spells, mode)
  boss_damage(spells, difficulty: mode) >= PLAYER[:hp]
end
```

The change to the `boss_damage` method is simply adding the `hp_loss` variable to the calculation based on the number of player turns.

{{< coderef >}}{{< var part-b-url >}}#L86{{</ coderef >}}
```
def boss_damage(spells, difficulty: :easy)
  hp_loss = difficulty == :hard ? spells.size : 0
  return hp_loss if spells.size < 2

  shield = SPELLS[:shield]
  armor = SPELLS[:shield][:armor]
  armor_reduction = spells.each_with_index
    .filter { |spell, _i| spell == :shield }
    .map { |_, i| armor * spell_ticks(shield, spells.size, i).fdiv(2).ceil }
    .sum

  healing_reduction = spells.map { |s| SPELLS[s].fetch(:heal, 0) }.sum

  max_damage = BOSS[:damage] * [0, spells.size - 1].max
  hp_loss + [1, max_damage - armor_reduction - healing_reduction].max
end
```

Finally, we refactor the original implementation of `solve_a` out into a new method called `battle` so we can pass the mode in depending on which solution answer is requested.

{{< coderef >}}{{< var part-b-url >}}#L142{{</ coderef >}}
```
def solve_a
  battle(:easy)
end

def solve_b
  battle(:hard)
end
```

Now we can figure out the least mana spent with the damage-over-time debuff.

```
$ run -y 2015 -q 22 -b
1289
```

## Searching For Answers
This problem is pretty long, but knowing depth-first search allows for a fairly easy solution to be implemented that runs without taking too long.
The really tricky bits involve getting the game mechanics correct and I wrote [quite a few tests]({{< var part-b-url >}}#L4) for these solutions to ensure that it worked properly.

I highly recommend writing tests for these kinds of fiddly logic rules.
They helped me solve this and also served as a good refresher for writing.
