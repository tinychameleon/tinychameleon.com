---
title: "Advent of Code 2015: No Such Thing as Too Much"
date: "2020-11-01T00:35:19Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/bd20816a8d663399ed15f62a66f59ba11502527c/2015/17/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/0c93992826fb16bd257dd29bf892e99aca6ead08/2015/17/solution.rb
---

The [seventeenth Advent of Code challenge](https://adventofcode.com/2015/day/17) is another challenge involving iterating over combinations.
These kinds of problems can be tricky to solve when they appear in the wild, requiring insight into the problem domain to avoid work.
Not much optimization work will happen here; instead I will try to keep the solution as simple as possible to show that it is entirely possible to solve, for smaller data-sets, without needing deep algorithms knowledge.

## Part A: It's Halloween and There's Already Eggnog... 🎄 

Finally, a problem with a shorter description; the entirety is below, but there are quite a few requirements hidden in it.

> The elves bought too much eggnog again - 150 liters this time. To fit it all into your refrigerator, you'll need to move it into smaller containers. You take an inventory of the capacities of the available containers.
>
> For example, suppose you have containers of size 20, 15, 10, 5, and 5 liters. If you need to store 25 liters, there are four ways to do it:
>
> - 15 and 10
> - 20 and 5 (the first 5)
> - 20 and 5 (the second 5)
> - 15, 5, and 5
>
> Filling all containers entirely, how many different combinations of containers can exactly fit all 150 liters of eggnog?
>
> --- _Advent of Code, 2015, Day 17_

From this we know, the input will be a set of container sizes and we must fill any used container fully, plus there may be many similar sized containers.
We need to store 150 litres of eggnog, which means we need to find every combination of containers with sizes that sum to 150.

Let's begin by writing some code to parse the input file by creating test file contents based on the problem statement, and a parsing method called `parse_containers`.

{{< coderef >}}{{< var part-a-url >}}#L4{{</ coderef >}}
```
TEST_INPUT = <<~DATA.freeze
  20
  15
  10
  5
  5
DATA
```

I think the `parse_containers` method should simply return an array of integers based on the line-oriented input file.
This data representation will make it easy to use Ruby's `Array` functionality, like `map` and `combination`.
Let's codify that as a test.

{{< coderef >}}{{< var part-a-url >}}#L13{{</ coderef >}}
```
assert parse_containers(TEST_INPUT), [20, 15, 10, 5, 5]
```

Now, to parse a line-oriented string we can convert each line to an integer.

{{< coderef >}}{{< var part-a-url >}}#L28{{</ coderef >}}
```
def parse_containers(input)
  input.lines.map(&:to_i)
end
```

So far, so good, but now we come to the crux of the problem: how to determine the total number of possible ways to store a given number of litres of eggnog?
From the example, we know that there should be 4 combinations, so let's write a test for a method called `storage_ways` which, given the array of integers of container sizes and a total amount to store, will return the number of ways the amount can be stored.

{{< coderef >}}{{< var part-a-url >}}#L14{{</ coderef >}}
```
assert storage_ways([20, 15, 10, 5, 5], 25), 4
```

Thinking about how to accomplish this, we can start by realizing that the containers could theoretically be larger than, or smaller than, or equal to the amount we need to store[^1].
That means we can check from using one container to using all of the containers.
Next, for each number of containers we want to check, we need to be able to iterate over all the combinations of that many containers.
Finally, we will need to check the sum of the selected containers to see if they're equal to the amount provided and count the number of times this is true.

{{< coderef >}}{{< var part-a-url >}}#L32{{</ coderef >}}
```
def storage_ways(containers, amount)
  (1..containers.size).map do |s|
    containers.combination(s).count { |c| c.sum == amount }
  end.sum
end
```

The `count` method will count the number of entries in a given array where the predicate is true, and the `combination` method will return an array containing all the possible combinations of containers for the given size `s`.

The last piece of code we need to write is something to wire together our pieces and litre constant; that's the `solve_a` method.

{{< coderef >}}{{< var part-a-url >}}#L38{{</ coderef >}}
```
def solve_a(input)
  storage_ways(parse_containers(input), 150)
end
```

Now when we run the code, we can figure out how many ways we can store 150 litres of eggnog with our given container data-set.

```
$ run -y 2015 -q 17 -a
1304
```

## Part B: There is No Halloween, Only Eggnog

Now there is an extra requirement placed upon us which will require more stringent pruning of combinations.

> While playing with all the containers in the kitchen, another load of eggnog arrives! The shipping and receiving department is requesting as many containers as you can spare.
>
> Find the minimum number of containers that can exactly fit all 150 liters of eggnog. How many different ways can you fill that number of containers and still hold exactly 150 litres?
>
> In the example above, the minimum number of containers was two. There were three ways to use that many containers, and so the answer there would be 3.
>
> --- _Advent of Code, 2015, Day 17_

We must find the minimum number of containers that can hold 150 litres of eggnog and then determine the total combinations of that number of containers which can hold 150 litres.
This will require a little refactoring, so let's define some additional test data for re-use as well as a few more methods.

{{< coderef >}}{{< var part-b-url >}}#L12{{</ coderef >}}
```
TEST_DATA = [20, 15, 10, 5, 5].freeze

def tests
  assert parse_containers(TEST_INPUT), TEST_DATA
  assert minimum_containers(TEST_DATA, 25), 2
  assert storage_ways(TEST_DATA, 2, 25), 3
  assert all_storage_ways(TEST_DATA, 25), 4
  :ok
end
```

The new functionality will exist in `minimum_containers`, but before we get to that I want to break apart the previously defined `storage_ways` method.
We can split the concept of looking for all combinations, the iteration portion, from the concept of finding the combinations for a specific amount of containers, the action portion.

{{< coderef >}}{{< var part-b-url >}}#L36{{</ coderef >}}
```
def storage_ways(containers, choose, amount)
  containers.combination(choose).count { |c| c.sum == amount }
end
```

Now `storage_ways` will take a `choose` parameter to indicate how many containers will be chosen when finding the number of ways to hold `amount` litres, but we need to fix Part A.

{{< coderef >}}{{< var part-b-url >}}#L46{{</ coderef >}}
```
def all_storage_ways(containers, amount)
  (1..containers.size).map { |s| storage_ways(containers, s, amount) }.sum
end

def solve_a(input)
  all_storage_ways(parse_containers(input), 150)
end
```

The iteration portion we simply move to a new method named `all_storage_ways` and the solution remains the same; the body of the `map` call has just transformed into a call to the new `storage_ways` definition.
Now we can discuss the `minimum_containers` method, which will require similar code to the original `storage_ways` method, but with a twist: we just want to return the minimum number of containers that can hold the given amount of litres.

{{< coderef >}}{{< var part-b-url >}}#L40{{</ coderef >}}
```
def minimum_containers(containers, amount)
  (1..containers.size).each do |s|
    return s if containers.combination(s).any? { |c| c.sum == amount }
  end
end
```

It is almost identical to our prior code, but instead of worrying about the sum of combinations equalling 150 litres, we return the number of containers immediately once we find a match.
The `minimum_containers` method will now give us a value that we can use as the `choose` argument for the `storage_ways` method we just wrote.

{{< coderef >}}{{< var part-b-url >}}#L54{{</ coderef >}}
```
def solve_b(input)
  containers = parse_containers(input)
  storage_ways(containers, minimum_containers(containers, 150), 150)
end
```

And with that, we can figure out how many combinations of the minimum number of containers that can store 150 litres exist for our data-set.

```
$ run -y 2015 -q 17 -b
18
```

## Algorithm Eggnogstic[^2]

A pretty simple challenge, but hopefully I've demonstrated that you don't necessarily need a deep background in algorithms to solve smaller problems.
For larger data-sets this approach would begin to take a lot more time to complete, so I would look at possible speed-ups involving data pruning or dynamic programming.
Anyone can get to the point where they can begin to optimize these types of problems, but it's important to build confidence in yourself first, and these types of solutions can help you along that path.

[^1]: This problem says that we're moving everything into _smaller_ containers, but in the general case you wouldn't necessarily make that assumption.
[^2]: Sorry. Also, if English isn't your first language, "Eggnogstic" is a bad pun because it sort of sounds like "agnostic".
