---
title: "Advent of Code 2015: Science for Hungry People"
date: "2020-09-13T00:40:19Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/2709a4da0ee7d21cb80ac60bec3f2fdeaffe037b/2015/15/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/18a177b07f62893395f50e3467b8487903d22923/2015/15/solution.rb
---

The [fifteenth Advent of Code challenge](https://adventofcode.com/2015/day/15) is about finding an optimal solution in a large search space.
We'll be using Ruby's `Enumerator` class to keep some of the memory utilization constrained as we deal with the combinations of choices present in the problem definition.

## Part A: The Ultimate Cookie
Let's analyse the problem to understand what needs to be done.

> Your recipe leaves room for exactly 100 teaspoons of ingredients. You make a list of the remaining ingredients you could use to finish the recipe (your puzzle input) and their properties per teaspoon:
>
> - capacity (how well it helps the cookie absorb milk)
> - durability (how well it keeps the cookie intact when full of milk)
> - flavor (how tasty it makes the cookie)
> - texture (how it improves the feel of the cookie)
> - calories (how many calories it adds to the cookie)
>
> You can only measure ingredients in whole-teaspoon amounts accurately, and you have to be accurate so you can reproduce your results in the future. The total score of a cookie can be found by adding up each of the properties (negative totals become 0) and then multiplying together everything except calories.
>
> Given the ingredients in your kitchen and their properties, what is the total score of the highest-scoring cookie you can make?
>
> --- _Advent of Code, 2015, Day 15_

Here's the requirements I pulled out of that text:

- One hundred teaspoons must be split across each ingredient
- Each ingredient's traits added up with negative values becoming 0, and then multiplied together is the cookie recipe score
- Calories are excluded from calculations
- Find the highest score

What's not stated is that the actual ingredient names and traits don't matter, as long as we can add the traits for each ingredient together.

As always, we're going to start with creating some test input from the challenge and begin by parsing the input into a format we want to work with.
Here's the first bit of testing data.

{{< coderef >}}{{< var part-a-url >}}#L4{{</ coderef >}}
```
TEST_INPUT = <<~DATA.freeze
  Butterscotch: capacity -1, durability -2, flavor 6, texture 3, calories 8
  Cinnamon: capacity 2, durability 3, flavor -2, texture -1, calories 3
DATA

TEST_DATA = [
  [-1, -2, 6, 3],
  [2, 3, -2, -1]
].freeze
```

The `TEST_DATA` is what we expect from the `parse_ingredients` method we will write, and it will be used to test our score calculations later.
You should notice that the calorie values are not present in the `TEST_DATA` because it's not needed.
To achieve this without specializing the parsing code, I want to add a keyword parameter, which we can test simultaneously.

{{< coderef >}}{{< var part-a-url >}}#L15{{</ coderef >}}
```
assert parse_ingredients(TEST_INPUT, max_traits: 4), TEST_DATA
```

To implement this method we need to convert each ingredient line into an array of the trait values, which means we're going to be pruning a large amount of the text from each line and the code is a little less clear for it.

{{< coderef >}}{{< var part-a-url >}}#L37{{</ coderef >}}
```
def parse_ingredients(input, max_traits:)
  input.lines.each_with_object([]) do |line, ingredients|
    _, traits = line.split(':')
    ingredients << traits.scan(/-?\d+/).map(&:to_i)[0...max_traits]
  end
end
```

If we ignore the `traits.scan` portion of the code and focus on the flow of the method, we can explain it as follows:

- Iterate over each line of the input with a shared mutable array via `input.lines.each_with_object([])`
- Remove the ingredient name by splitting the line at the colon character
- Push _something_ onto the end of the shared `ingredients` array
- Let `each_with_object` return the shared array as the method result

The _something_ that gets pushed onto the end of the array relies on understanding what the `String#scan` method does.
This method takes a regular expression and returns an array containing all matches within the string it is called upon.
So `traits.scan(/-?\d+/)` returns an array containing each of the trait values as strings, then we issue a `map(&:to_i)` to convert them to integers, and finally take the first N trait values by slicing from zero to `max_traits` via `[0...max_traits]`.

I think it's important to note that this strategy only works because the input traits are always in the same order.
By taking advantage of this, we know that each trait value is at the same index in every line's array, which will make the calculation process a little easier.
So let's write a test for the score calculation process now.

{{< coderef >}}{{< var part-a-url >}}#L16{{</ coderef >}}
```
assert calculate_score(TEST_DATA, [44, 56]), 62_842_880
```

The `calculate_score` method requires two things: the array of trait value arrays and the amounts of each ingredient to use.
The calculation is going to multiply each ingredient's trait values by the amount of the ingredient, add the traits across ingredients, and multiply everything together by using some functional programming concepts.

{{< coderef >}}{{< var part-a-url >}}#L44{{</ coderef >}}
```
def calculate_score(ingredients, amounts)
  scores = ingredients.zip(amounts).map do |traits, amount|
    traits.map { |v| v * amount }
  end
  scores[0].zip(*scores[1..]).map { |xs| [0, xs.sum].max }.reduce(1, &:*)
end
```

Since our ingredients and amount arrays are in the same order, we can use `Array#zip`[^1] to associate the values at each index and loop over both simultaneously.
Then it's pretty easy to multiply every trait value for an ingredient by its associated amount --- we just need to `map`.
At that point we have the scores associated with each individual ingredient, but we still need to combine them by adding each trait together and multiplying those sums.

We use `zip` again for this, but the clever bit is that we zip the first scores entry with the remaining ones by using the `*` spread operator.
The spread operator allows you to use an array of values as individual parameters to a method, so a method `M(a, b, c)` could be called as `M(1, 2, 3)` or as `M(*[1, 2, 3])`.
The result of this is each `xs` value is an array containing the values present at each index _across_ all the `scores` elements.
So the first value `xs` represents will be an array containing all the `[0]` index values across `scores`, the second will be the `[1]` index values, etc.

For each of the traits we need to add all the values together, but if it's negative we need to make it a 0.
We achieve that via the `map { |xs| [0, xs.sum].max }` expression, and the intermediate result is an array of integers representing the sums of each trait.
Finally, we need to multiply these together, so we call `reduce(1, &:*)` to start at one and consecutively multiply by each value.

Now that we can calculate scores, we need to be able to iterate over all the possible ingredient amounts.
This is where the code gets a bit trickier, as we're going to use recursion to represent generating the combinations.
First, lets write some tests so we can validate what we're doing is correct.

{{< coderef >}}{{< var part-a-url >}}#L17{{</ coderef >}}
```
assert combinations(sum: 4, terms: 1).to_a, [[4]]
assert combinations(sum: 4, terms: 3).to_a, [
  [0, 0, 4], [0, 1, 3], [0, 2, 2], [0, 3, 1], [0, 4, 0],
  [1, 0, 3], [1, 1, 2], [1, 2, 1], [1, 3, 0], [2, 0, 2],
  [2, 1, 1], [2, 2, 0], [3, 0, 1], [3, 1, 0], [4, 0, 0]
]
```

These tests represent the things you will need to write recursive algorithms: a base case and the recurring case.
The base case is when we only have 1 term remaining: there's only one way to split a remaining amount one way.
The recurring case is to split the remainder in N ways, but without the currently used amount, because we are restricted to 100 teaspoons.
Let's look at the code, and brace yourself as it's different from a lot of the code we've seen so far in Advent of Code challenges.

{{< coderef >}}{{< var part-a-url >}}#L51{{</ coderef >}}
```
def combinations(sum:, terms:)
  return [[sum]].to_enum if terms == 1

  Enumerator.new do |yielder|
    (0..sum).each do |i|
      prefix = [i]
      combinations(sum: sum - i, terms: terms - 1).each do |combo|
        yielder << prefix + combo
      end
    end
  end
end
```

Right at the beginning is our base case: when terms is one, we return an `Enumerator` over one possible result.
It's written as `[[sum]]` because each element needs to be an array.

The remainder of the method body is more complex, so lets focus on the `Enumerator.new` bit first.
This allows the code to return combinations one-at-a-time instead of creating them all at once, which would take up a large amount of memory.
The `yielder` is an object provided by Ruby that makes this happen, and is out-of-scope for the current discussion; just think of it as something that pauses the looping code until the yielded value has been used.

The main algorithm is this: for each possible value from zero until the remaining sum, treat that value as the first entry of the rest of the ingredient amounts, then calculate any remaining ingredient combinations minus the amount chosen as the first value.
By calling `combinations` recursively we can utilize the same algorithm for each of the remaining ingredients, just with fewer teaspoons remaining.
So, the external `combinations` call iterates over the first ingredient, the first recursive call iterates over the second ingredient, and finally when there is only one ingredient left it hits the base case.

In this algorithm, `terms` represents the number of ingredients remaining, because we do not care about the actual ingredients.
We only care about splitting 100 teaspoons across however many ingredients, or `terms`, that are necessary.

The last component of the challenge algorithm is to find the maximum score, which is just glueing together the pieces we've already made.
Let's write a test against our data to ensure we implement it correctly. 

{{< coderef >}}{{< var part-a-url >}}#L23{{</ coderef >}}
```
assert max_score(TEST_DATA), 62_842_880
```

This `max_score` method is pretty simple: find the maximum score of all combinations for the ingredients.

{{< coderef >}}{{< var part-a-url >}}#L64{{</ coderef >}}
```
def max_score(ingredients)
  combinations(sum: 100, terms: ingredients.size).map do |combo|
    calculate_score(ingredients, combo)
  end.max
end
```

We set up the call to `combinations` correctly by using one-hundred for the sum and the number of ingredients for the terms and calculate the score of each combination, then we just call `Array#max`.
All that's left is to wire things up in the `solve_a` method.

{{< coderef >}}{{< var part-a-url >}}#L70{{</ coderef >}}
```
def solve_a(input)
  max_score(parse_ingredients(input, max_traits: 4))
end
```

With this implemented, we can wire up the solution and run it to get the answer.

```
$ run -y 2015 -q 15 -a
222870
```

## Part B: The Precision Diet Cookie
The second portion of this challenge makes things a little bit more interesting by restricting the acceptable solutions based on the calorie sum.

> Your cookie recipe becomes wildly popular! Someone asks if you can make another recipe that has exactly 500 calories per cookie (so they can use it as a meal replacement). Keep the rest of your award-winning process the same (100 teaspoons, same ingredients, same scoring system).
>
> Given the ingredients in your kitchen and their properties, what is the total score of the highest-scoring cookie you can make with a calorie total of 500?
>
> --- _Advent of Code, 2015, Day 15_

So after determining the total trait value for each recipe, we need to discard it if the calorie total is precisely `500`.
Let's write a small method that represents that logic.

{{< coderef >}}{{< var part-b-url >}}#L69{{</ coderef >}}
```
def calorie_conscious(traits)
  traits.last == 500
end
```

To integrate this, I think it will be cleanest at the solution level for `solve_b`, so let's write that code now, and keep in mind that we do not want to break any of the prior implementation work.

{{< coderef >}}{{< var part-b-url >}}#L83{{</ coderef >}}
```
def solve_b(input)
  ingredients = parse_ingredients(input, max_traits: 5)
  max_score(ingredients, keep: ->(x) { calorie_conscious(x) })
end
```

The first thing is to increase `max_traits` to `5` so that we also get calorie values from parsing the ingredients list.
The second thing is to add a predicate argument to the `max_score` method so that we can discard things by providing a configurable condition similar to `Array#filter`.
Let's thread that predicate through `max_score` now.

{{< coderef >}}{{< var part-b-url >}}#L73{{</ coderef >}}
```
def max_score(ingredients, keep: nil)
  combinations(sum: 100, terms: ingredients.size).map do |combo|
    calculate_score(ingredients, combo, keep: keep)
  end.max
end
```

As you can see the method is very similar and we're just threading the `keep` predicate into `calculate_score` so that we can discard the score value if necessary.
The `keep` parameter defaults to `nil` so that we do not need to change the `solve_a` method.
So, what does `calculate_score` look like?

{{< coderef >}}{{< var part-b-url >}}#L46{{</ coderef >}}
```
def calculate_score(ingredients, amounts, keep: nil)
  scores = ingredients.zip(amounts).map do |traits, amount|
    traits.map { |v| v * amount }
  end
  totals = scores[0].zip(*scores[1..]).map { |xs| [0, xs.sum].max }
  return 0 if keep && !keep.call(totals)

  totals[0...CALORIE_INDEX].reduce(1, &:*)
end
```

It's quite similar --- the major difference is that we've split the call to `reduce` from the summation and have an early return statement.
That early return statement simply returns `0` for the score, effectively eliminating the recipe from contention, if the call to `keep` returns `false`.
There is also a new constant, `CALORIE_INDEX`, which is set such that it stops the multiplication from including the calorie values.

Now we can figure out the answer to part B.

```
$ run -y 2015 -q 15 -b
117936
```

## A Delicious Treat
Any chance I get to program with `Enumerator`, in any language, is always fun --- the ability to create infinite, or very large, sequences that use a constant amount of memory is a powerful tool.
We didn't take full advantage of them in this challenge, but hopefully you can experiment with them yourself to learn something new.

I didn't start out expecting to write a recursive `combinations` method, these kinds of algorithms can certainly be difficult to understand, but practising them is always useful as some algorithms have dramatically better clarity when written recursively.

[^1]: If you've forgotten what `Array#zip` does, [the Ruby documentation has a nice example](https://ruby-doc.org/core-2.7.0/Array.html#method-i-zip).