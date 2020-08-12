---
title: "Advent of Code 2015: Knights of the Dinner Table"
date: "2020-08-12T03:12:36Z"
tags: [advent-of-code, ruby]
fileurl: https://github.com/tinychameleon/advent-of-code-2015/blob/3c24e9df8f1932c96db0c1400b191559f75c3886/2015/13/solution.rb
---

The [thirteenth Advent of Code challenge](https://adventofcode.com/2015/day/13) is about constructing and traversing a graph to find the optimal value.
Graph traversal can be tricky, but in this case we will exhaustively check the graph to find the correct answers, and this makes it a little easier.

## Part A: Avoiding Family Drama

Let's look at a simplified version of the problem text, with the long examples cut, to determine the requirements.

> In years past, the holiday feast with your family hasn't gone so well. Not everyone gets along! This year, you resolve, will be different. You're going to find the optimal seating arrangement and avoid all those awkward conversations.
>
> You start by writing up a list of everyone invited and the amount their happiness would increase or decrease if they were to find themselves sitting next to each other person. You have a circular table that will be just big enough to fit everyone comfortably, and so each person will have exactly two neighbors.
>
> What is the total change in happiness for the optimal seating arrangement of the actual guest list?
>
> --- _Advent of Code, 2015, Day 13_

The problem requires that we be able to parse a list of happiness values associated with a pairing of family members, and that we must use those pairing-to-happiness-values to determine the best seating arrangement for the family.

The first step is defining our test data, from the challenge text, which defines a happiness graph in a line-based format.

{{< coderef >}}{{< var fileurl >}}#L5{{</ coderef >}}
```
TEST_INPUT = <<~DATA.freeze
  Alice would gain 54 happiness units by sitting next to Bob.
  Alice would lose 79 happiness units by sitting next to Carol.
  Alice would lose 2 happiness units by sitting next to David.
  Bob would gain 83 happiness units by sitting next to Alice.
  Bob would lose 7 happiness units by sitting next to Carol.
  Bob would lose 63 happiness units by sitting next to David.
  Carol would lose 62 happiness units by sitting next to Alice.
  Carol would gain 60 happiness units by sitting next to Bob.
  Carol would gain 55 happiness units by sitting next to David.
  David would gain 46 happiness units by sitting next to Alice.
  David would lose 7 happiness units by sitting next to Bob.
  David would gain 41 happiness units by sitting next to Carol.
DATA
```

To create a graph data-structure we can use to solve the problem, we need to be able to do two things:

- parse each line into a reasonable format
- build the graph from the results of each parsed line

Since parsing each line is easier, we will start there and define some tests which validate the format that I want to emit.
A `parse_line` method will return a tuple of family member names and the happiness value for a given input line.

{{< coderef >}}{{< var fileurl >}}#L21{{</ coderef >}}
```
assert parse_line(
  'Alice would gain 54 happiness units by sitting next to Bob.'
), [%w[Alice Bob], 54]
assert parse_line(
  'Alice would lose 79 happiness units by sitting next to Carol.'
), [%w[Alice Carol], -79]
```

If we split each line on white-space characters, we can easily pull the required data out by position without needing to resort to regular expressions or any kind of complicated parsing:

- family member names are the first and last positions;
- the sign of the happiness value is either `"gain"` or `"lose"` in the 3{{< sup rd >}} position;
- and the happiness value is in the 4th position.

{{< coderef >}}{{< var fileurl >}}#L49{{</ coderef >}}
```
def parse_line(line)
  from, _, sign, delta, *rest = line.split
  to = rest[-1][0..-2]
  [[from, to], (sign == 'gain' ? 1 : -1) * delta.to_i]
end
```

By using destructuring assignment we can pull most of the values directly out of the call to `line.split`.
One tricky bit is that though the second family member name is the last element, it also contains a period character which needs to be stripped out, which is what the `rest[1][0..-2]` expression does.

The second task is to use these line results of `[[from, to], happiness]` tuples to create the graph, so let's write a test that creates a graph from the entire `TEST_INPUT` string using a method named `parse_graph`.

{{< coderef >}}{{< var fileurl >}}#L27{{</ coderef >}}
```
assert parse_graph(TEST_INPUT), {
  %w[Alice Bob] => 83 + 54,
  %w[Alice Carol] => -79 + -62,
  %w[Alice David] => -2 + 46,
  %w[Bob Carol] => -7 + 60,
  %w[Bob David] => -63 + -7,
  %w[Carol David] => 55 + 41
}
```

Since `parse_graph` is going to expect the input text as an argument it will need to iterate over the input lines and aggregate the happiness value between the two family members.
To ensure that each family member pair exists in the graph exactly once, we can sort the family member names.

{{< coderef >}}{<< var fileurl >}}#L55{{</ coderef >}}
```
def parse_graph(input)
  input.lines.each_with_object(Hash.new { |h, k| h[k] = 0 }) do |line, graph|
    key, delta = parse_line(line)
    graph[key.sort] += delta
  end
end
```

We use `Enumerable#each_with_object` to pass around a `Hash` which defaults any new keys to the value `0`; a block passed to `Hash#new` will run to initialize any new key added to the hash.
The rest is easy: we parse the line, sort the family member names key, and aggregate the happiness values using `+=`.

Now we have a graph data-structure and we need to solve the more difficult portion: finding the optimial seating positions.
Thankfully, the challenge example provides the answer for the test input, so lets write a test for our `seating_happiness` method.

{{< coderef >}}{{< var fileurl >}}#L35{{</ coderef >}}
```
assert seating_happiness(parse_graph(TEST_INPUT)), 330
```

The challenge doesn't ask us to print the optimal seating position, so we only need to keep track of the largest happiness sum for each seating order.
To find the maximum happiness sum for a seating order we can start from any family member and calculate the happiness sum for every order of the remaining family members.
We also need to remember that the table is a circle, so we must include the happiness values from our starting family member to the first and last family members in the current order.


{{< coderef >}}{{< var fileurl >}}#L63{{</ coderef >}}
```
def seating_happiness(graph)
  friends = graph.keys.flatten.uniq.sort
  origin = friends.first
  friends[1..].permutation.map do |ordering|
    graph[[origin, ordering.last]] +
      graph[[origin, ordering.first]] +
      ordering.each_cons(2).map { |a, b| graph[[a, b].sort] }.sum
  end.max
end
```

This is a bit hairy, so let's step through it:

- First we get the list of family members from the graph and pick the smallest family member to use as the starting point
- Next we iterate over all the permuations of the remaining family members via `friends[1..].permutation.map`
- For every ordering we calculate the sum of...
	- the total happiness value between our starting family member and the first and last family members in the ordering
	- the total happiness value between each of the family members in the ordering using `ordering.each_cons(2)` to get the pairs
- Finally, we find the maximum of all those happiness sums.

One trick here is that the `friends` list is sorted, so the `origin` family member will always be the smallest.
This means we can construct the first and last family member ordering comparisons directly like `graph[[origin, ordering.first]]` without violating the sorted-key invariant we implemented in `parse_graph`.

Now we can figure out the maximum happiness value for the question.

```
$ run -y 2015 -q 13 -a
618
```

## Part B: But Where Will I Sit?

The second part of this challenge expands the graph with you. We forgot to seat ourselves... Whoops.

> In all the commotion, you realize that you forgot to seat yourself. At this point, you're pretty apathetic toward the whole thing, and your happiness wouldn't really go up or down regardless of who you sit next to. You assume everyone else would be just as ambivalent about sitting next to you, too.
>
> So, add yourself to the list, and give all happiness relationships that involve you a score of 0.
>
> What is the total change in happiness for the optimal seating arrangement that actually includes yourself?
>
> --- _Advent of Code, 2015, Day 13_

There are no code changes necessary for this part --- the question even tells you to just add yourself to the input file!
I've added myself like this, but for every family member:

```
I would gain 0 happiness units by sitting next to X.
```

Wiring up the new input file and running the solution yields the answer.

```
$ run -y 2015 -q 13 -b
601
```

Seating ourselves lowers the total happiness value at the table. Ouch.

## Traversing Family Dinners
Learning to create graphs is important to becoming a better programmer because they pop up in a surprising number of places.
You don't need to create a fancy graph type to use them --- many times a simple `Hash` or `Dictionary` type can fulfill the role well enough.

They won't help you out with awkard family dinners though.