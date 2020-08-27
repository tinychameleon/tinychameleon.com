---
title: "Advent of Code 2015: Reindeer Olympics"
date: "2020-08-27T03:37:41Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/76c4e2953bd4eb0ea85a231b0eb95e9dd8ddf8bd/2015/14/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/a69ed0c7aaebc47a763546ec5dfb1073eb42a0d2/2015/14/solution.rb
---

The [fourteenth Advent of Code challenge](https://adventofcode.com/2015/day/14) involves computing periodic values similar to measuring frequency using [Hertz](https://en.wikipedia.org/wiki/Hertz).
It is a short problem, but let's us practice thinking about frequencies and how to operate on them.

## Part A: Farthest Reindeer 

This problem has a long description, but can be summarized tersely.

> This year is the Reindeer Olympics! Reindeer can fly at high speeds, but must rest occasionally to recover their energy. Santa would like to know which of his reindeer is fastest, and so he has them race.
>
> Reindeer can only either be flying (always at their top speed) or resting (not moving at all), and always spend whole seconds in either state.
>
> For example, suppose you have the following Reindeer:
>
> - Comet can fly 14 km/s for 10 seconds, but then must rest for 127 seconds.
> - Dancer can fly 16 km/s for 11 seconds, but then must rest for 162 seconds.
>
> Given the descriptions of each reindeer (in your puzzle input), after exactly 2503 seconds, what distance has the winning reindeer traveled?
>
> --- _Advent of Code, 2015, Day 14_

We need to find the maximum distance travelled by any reindeer, and to do so we can use the following reindeer movement rules:

- Reindeer only move in whole seconds
- Reindeer are moving at full speed or resting

First, we'll create a piece of test input based off of the given example and a data fixture representing the information format we wish to work with.

{{< coderef >}}{{< var part-a-url >}}#L4{{</ coderef >}}
```
TEST_INPUT = <<~DATA.freeze
  Comet can fly 14 km/s for 10 seconds, but then must rest for 127 seconds.
DATA

TEST_DATA = { velocity: 14, duration: 10, resting: 127 }.freeze
```

Now we need a method to extract the velocity, movement duration, and resting duration from that input; I will call the method `parse_line` and write a test for it.

{{< coderef >}}{{< var part-a-url >}}#L11{{</ coderef >}}
```
assert parse_line(TEST_INPUT), TEST_DATA
```

Since all the velocity data is in km/s, the durations are all in seconds, and the values are all integers, we can scan the input line and pull out only these integer values.

{{< coderef >}}{{< var part-a-url >}}#L30{{</ coderef >}}
```
def parse_line(line)
  v, d, r = line.scan(/\d+/).map(&:to_i)
  { velocity: v, duration: d, resting: r }
end
```

Once we've found the textual integer values from the line we can convert them to integers and build the `Hash` structure we want to work with to solve the problem.

Solving the problem requires thinking about how frequencies work via cycles; to create a method named `distance` which can return the kilometres travelled by a reindeer it must know how to use the `Hash` we've built to calculate the total distance based on the movement and resting cycle.
Let's write some tests to verify different time values reflect the correct distances based on the reindeer's movement cycle.

{{< coderef >}}{{< var part-a-url >}}#L12{{</ coderef >}}
```
assert distance(TEST_DATA, 1), 14
assert distance(TEST_DATA, 10), 140
assert distance(TEST_DATA, 11), 140
assert distance(TEST_DATA, 138), 154
assert distance(TEST_DATA, 1000), 1120
```

Let's look at the code for distance and then break down what it does and how it works.

{{< coderef >}}{{< var part-a-url >}}#L35{{</ coderef >}}
```
def distance(reindeer, seconds)
  timespan = reindeer[:duration] + reindeer[:resting]
  cycles = seconds / timespan
  remainder = [reindeer[:duration], seconds % timespan].min
  reindeer[:velocity] * (cycles * reindeer[:duration] + remainder)
end
```

Treating the reindeer's movement and resting durations as a full cycle allows us to calculate the `timespan` of a full cycle by adding the durations.
With the `timespan` known, we can calculate the number of full cycles possible in a given time-frame using division, which is stored as `cycles`.

Now the trickier bit: the remainder of `seconds / timespan` is an integer which is less than `timespan` and in the range `0` to `timespan - 1`.
If you are not convinced about the remainder being less than `timespan`, think about the remaining cases:

- when `remainder == timespan` we would have had `cycles + 1` and remainder of `0`
- when `remainder > timespan` we would have had `cycles + 1`[^1] and a remainder of `remainder - timespan`

Since the remaining time is not enough to complete a full cycle the reindeer can only move once more for a given amount of time.
The remaining seconds is somewhere between `0` and `timespan - 1`, which means it could be less than the reindeer's movement duration.
That is why we take the minimum value between the movement duration and remaining time to assign `remainder`.

The last bit is simple: we multiply the reindeer's velocity by the total number of seconds it spends moving as defined by the number of full cycles and the remainder.

What remains is to wire everything together to find the maximum distance travelled by a reindeer during the 2503 second race.
For this we must parse each line and use the `distance` method.

{{< coderef >}}{{< var part-a-url >}}#L42{{</ coderef >}}
```
def solve_a(input)
  input.lines.map { |l| parse_line(l) }.map { |r| distance(r, 2503) }.max
end
```

Now we can find the answer.

```
$ run -y 2015 -q 14 -a
2660
```

## Part B: Leading the Most

The second part of the challenge mixes things up by asking for a different scoring system to determine the winning number of points.

> Seeing how reindeer move in bursts, Santa decides he's not pleased with the old scoring system.
> 
> Instead, at the end of each second, he awards one point to the reindeer currently in the lead. (If there are multiple reindeer tied for the lead, they each get one point.) He keeps the traditional 2503 second time limit, of course, as doing otherwise would be entirely ridiculous.
>
> Again given the descriptions of each reindeer (in your puzzle input), after exactly 2503 seconds, how many points does the winning reindeer have?
>
> --- _Advent of Code, 2015, Day 14_

Now we must award one point per second to each reindeer tied for the lead, and the answer is the maximum number of points accumulated by a reindeer.
To solve this problem we need a method `simulate` which can generate the distance a reindeer has travelled for each second in a race, then we can compare across all reindeer and award leader points.

If the `simulate` method is working well, we should be able to get the same answers as a call to `distance`, so we call `Array#last` in our tests.

{{< coderef >}}{{< var part-b-url >}}#L20{{</ coderef >}}
```
assert simulate(TEST_DATA, 10).last, 140
assert simulate(TEST_DATA, 138).last, 154
assert simulate(TEST_DATA, 1000).last, 1120
```

The `simulate` method itself is rather simple: map the range of seconds into an array of distance values.

{{< coderef >}}{{< var part-b-url >}}#L48{{</ coderef >}}
```
def simulate(reindeer, seconds)
  (1..seconds).map { |s| distance(reindeer, s) }
end
```

Solving the problem involves generating the distance values for every reindeer across the time-frame, assigning leader points, and figuring out the maximum.

{{< coderef >}}{{< var part-b-url >}}#L56{{</ coderef >}}
```
def solve_b(input, seconds)
  reindeer = input.lines.map { |l| simulate(parse_line(l), seconds) }
  (0...seconds).each do |i|
    leader = reindeer.map { |km| km[i] }.max
    reindeer.each { |km| km[i] = km[i] == leader ? 1 : 0 }
  end
  reindeer.map(&:sum).max
end
```

There are some data-type subtleties to this code that are worth highlighting.

- the `reindeer` variable is an array of arrays, because `simulate` returns an array
- the `leader` score is determined by checking the same index across all the interior arrays[^2]
- the distance values within the array are replaced by leader point values
- each reindeer's leader points can then be summed and the maximum found

With that implemented we can figure out the maximum leader points obtained by a reindeer.

```
$ run -y 2015 -q 14 -b
1256
```

## Nobody Got Hertz

The terseness of Ruby and the feature-rich collection classes helped greatly with keeping code concise in this challenge, but extra care does need to be taken to ensure you know which types are available within a method.
Aside from type awareness, it's very useful to be able to represent things as a frequency, since it makes calculating how often things occur, or total side-effects from the action occurring, very easy.


[^1]: Technically, we would have `cycles + N` where `N = remainder / timespan` since if the remainder is greater than the timespan it could be much larger than it.
[^2]: This is not optimal for memory access. The optimal memory solution would be to pack all the distance values for each second into the same array, which would allow for better CPU cache usage. The implemented solution does allow for a simple summation and max call to find the answer.