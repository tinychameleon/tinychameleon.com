---
title: "Advent of Code 2015: Aunt Sue"
date: "2020-10-10T01:53:57Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/58a446481bd88943e1d74aa86bc14944c6ce61b4/2015/16/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/bb71f4e1f091c0a87af6b3b728dd874d4e3c046b/2015/16/solution.rb
---

The [sixteenth Advent of Code challenge](https://adventofcode.com/2015/day/16) is about pruning data-sets based on known details.
If you've ever had to clean data before using it for a problem, you'll be right at home.

## Part A: Which Sue?
This one is a long problem statement, which I have trimmed below.
The gist is that there are certain attributes each Aunt Sue has, and you are given some known attributes to match against.

> Your Aunt Sue has given you a wonderful gift, and you'd like to send her a thank you card. However, there's a small problem: she signed it "From, Aunt Sue".
>
> You have 500 Aunts named "Sue".
>
> ...
>
> You make a list of the things you can remember about each Aunt Sue. Things missing from your list aren't zero - you simply don't remember the value.
>
> What is the number of the Sue that got you the gift?
>
> --- _Advent of Code, 2015, Day 16_

You'll see the attributes as we write out some tests, so let's get started by defining some test data.

{{< coderef >}}{{< var part-a-url >}}#L4{{</ coderef >}}
```
TEST_INPUT = <<~DATA.freeze
  Sue 1: cars: 9, akitas: 3, goldfish: 0
  Sue 2: akitas: 9, children: 3, samoyeds: 9
DATA

TEST_DATA = [
  { sue: 1, cars: 9, akitas: 3, goldfish: 0 },
  { sue: 2, akitas: 9, children: 3, samoyeds: 9 }
].freeze
```

The `TEST_INPUT` constant represents the problem input and the `TEST_DATA` constant represents the format I want to use to solve the problem.
Our first test is to parse the input and make sure we get the expected data structure; I've called this method `parse_sues`.

{{< coderef >}}{{< var part-a-url >}}#L15{{</ coderef >}}
```
assert parse_sues(TEST_INPUT), TEST_DATA
```

The test input is regular, with each attribute being followed by a colon and its value, which means we can use a regular expression over each line to obtain the attributes, then process them to create a dictionary per line.

{{< coderef >}}{{< var part-a-url >}}#L43{{</ coderef >}}
```
def parse_sues(input)
  input.lines.map { |l| l.scan(/(\w+): (\d+)/) }.map.with_index do |pairs, i|
    pairs.each_with_object({ sue: i + 1 }) do |kv, h|
      detail, value = kv
      h[detail.to_sym] = value.to_i
    end
  end
end
```

This has two major components: the inner `each_with_object` loop and the outer `map.with_index` loop.
The inner loop is responsible for converting the individual attribute representing a detail about an aunt into a symbol type for the dictionary key, and making sure the value is an integer.

The outer loop is trickier because each line of the input file is transformed into an array containing individual `["attribute", "value"]` pairs.
This is done by `l.scan(...)` which returns every match of the given regular expression.

Before solving the problem, we also need to codify the known Aunt Sue attribute details from the problem.
We'll be filtering through all 500 Sues by using these.

{{< coderef >}}{{< var part-a-url >}}#L30{{</ coderef >}}
```
KNOWN_DETAILS = {
  children: 3,
  cats: 7,
  samoyeds: 2,
  pomeranians: 3,
  akitas: 0,
  vizslas: 0,
  goldfish: 5,
  trees: 3,
  cars: 2,
  perfumes: 1
}.freeze
```

So, to solve the problem, we need to take the input and the known values, parse the input into the dictionary format above, and then filter out all the Sues that don't match our known details.
Importantly, we need to make sure that any unknown details about an Aunt Sue don't disqualify the match, since an unknown value isn't zero.

{{< coderef >}}{{< var part-a-url >}}#L52{{</ coderef >}}
```
def solve_a(input, knowns)
  knowns.reduce(parse_sues(input)) do |sues, kv|
    detail, limit = kv
    sues.filter { |s| s.fetch(detail, limit) == limit }
  end.first[:sue]
end
```

This code begins the reduce by using the entire set of Sues, which might be a little different than what you're used to seeing if you generally use reduce to construct something from an empty state.
For each known attribute-value pair, called `kv`, we go on to filter out any Sues that do not match the limit.
Finally, we just take the remaining Sue.

That's pretty much it; let's find out which Aunt Sue sent us the gift.

```
$ run -y 2015 -q 16 -a
373
```

## Part B: Lacking Precision 
The second part throws a small wrench into the plan by suggesting some attributes are not meant to be compared via equality.

> In particular, the `cats` and `trees` readings indicates that there are _greater than_ that many (due to the unpredictable nuclear decay of cat dander and tree pollen), while the `pomeranians` and `goldfish` readings indicate that there are _fewer than_ that many (due to the modial interaction of magnetoreluctance).
>
> --- _Advent of Code, 2015, Day 16_

Now we need to change the `solve_a` method to take custom comparison functions; it's a small change to the reduction block.

{{< coderef >}}{{< var part-b-url >}}#L53{{</ coderef >}}
```
def solve(input, knowns, **comparers)
  knowns.reduce(parse_sues(input)) do |sues, kv|
    detail, limit = kv
    pred = comparers.fetch(detail, ->(v, limit) { v == limit })
    sues.filter { |s| s.key?(detail) ? pred.call(s[detail], limit) : true }
  end.first[:sue]
end
```

I've chosen to take the compare functions as a named argument dictionary, and pull out the predicate comparision function using the attribute name; if there isn't a comparison function for the attribute name it defaults to equality.
I changed up the `filter` block conditional to make it more explicit that missing attributes do not get pruned by directly returning `true`.

Now, to implement `solve_b` all that is needed is to provide customizations for the attributes that require different comparison functions.

{{< coderef >}}{{< var part-b-url >}}#L65{{</ coderef >}}
```
def solve_b(input, knowns)
  gt = ->(v, limit) { v > limit }
  lt = ->(v, limit) { v < limit }
  solve(input, knowns, cats: gt, trees: gt, goldfish: lt, pomeranians: lt)
end
```

We can finally find out which Aunt Sue really sent that gift.

```
$ run -y 2015 -q 16 -b
260
```

## Big Family, Short Problem
This one was pretty quick to solve, but it did highlight the usefulness of being able to provide specific comparison operations for selection-oriented programming tasks.
Higher-order functions are a great way to provide this kind of functionality, and if you don't have access to them, the [Strategy Pattern](https://en.wikipedia.org/wiki/Strategy_pattern) can help.
