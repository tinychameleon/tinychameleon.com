---
title: "Advent of Code 2015: Not Quite Lisp"
date: "2020-02-19T05:12:04Z"
tags: ["advent-of-code", "ruby"]
baseurl: "https://github.com/tinychameleon/advent-of-code-2015/blob"
---

Before I begin going through Advent of Code challenges, I would like to suggest that you personally attempt them before reading ahead.
You can still learn a lot by reading the code written by others, but first-hand practice has no substitute when building skills.
Your solution may dramatically differ from my own, but the multitude of possible solutions is one of the wonderful things about programming.
Try to see the spectrum of possible answers as an opportunity for exploring strategies instead of the daunting task of picking the perfect solution.
Finding a perfect solution should never be your goal when there are numerous "good enough" solutions immediately available.

Previously I created a small program for running Advent of Code solutions and today I'm going to start with the very first Advent of Code challenge from 2015: [Not Quite Lisp](https://adventofcode.com/2015/day/1); it's ancient at this point in time, but it can still be a great learning experience.
To begin, I like to determine what restrictions a problem imposes, so let's look at the provided problem description.

> Santa is trying to deliver presents in a large apartment building, but he can't find the right floor --- the directions he got are a little confusing. He starts on the ground floor (floor 0) and then follows the instructions one character at a time.
> 
> An opening parenthesis, (, means he should go up one floor, and a closing parenthesis, ), means he should go down one floor.
>
> The apartment building is very tall, and the basement is very deep; he will never find the top or bottom floors.
>
> --- _Advent of Code, 2015 Day 1_

If I condense the information present in this description, I end up with these four important statements:

* begin on the ground floor, which is considered 0;
* only process a single input character at a time;
* a `(` means up one floor and a `)` means down one floor;
* and there are no boundary conditions on the floor value.

From these statements, I've decided to pursue a simple solution relying on a single integer to track Santa's current floor.
The requirements map nicely to an integer initialized to 0 and adjusted by ±1 depending on the input character.

## Part A: Destination Floor
The first part of this challenge is to determine which floor Santa ends up on by following all of the input instructions.
Using the examples provided within the challenge I have implemented a simple `tests` method which will crash if an assertion fails.
The stack trace produced by such a crash will highlight the failed assertion and provide a legible comparison message; if all tests pass the output will simply be "ok".

{{< coderef >}}{{< var "baseurl" >}}/e4951228497fb3f027364d39c3661445f56a96ae/2015/1/solution.rb#L4{{</ coderef >}}
```
def tests
  assert solve_a('(())'), 0
  assert solve_a('()()'), 0
  assert solve_a('((('), 3
  assert solve_a('(()(()('), 3
  assert solve_a('))((((('), 3
  assert solve_a('())'), -1
  assert solve_a('))('), -1
  assert solve_a(')))'), -3
  assert solve_a(')())())'), -3
  :ok
end
```

If I make a mistake implementing the solution and run the tests, an error like the following will appear:

```
$ run -y 2015 -q 1 -t
Traceback (most recent call last):
	4: from main.rb:23:in `<main>'
	3: from main.rb:8:in `launch'
	2: from main.rb:14:in `run_solution'
	1: from /Users/srt/Projects/advent-of-code/2015/1/solution.rb:7:in `tests'
/Users/srt/Projects/advent-of-code/utils.rb:6:in `assert': Got 0, want 3 (AssertionFailure)
```

It's not going to win any awards for beauty, but I  don't have to choose and learn a full testing framework for what amounts to a series of small challenges.
Now that our `tests` method is working we can begin implementing a solution for part A of the challenge; my first cut is a simple loop over every character within the given input.

{{< coderef >}}{{< var "baseurl" >}}/e4951228497fb3f027364d39c3661445f56a96ae/2015/1/solution.rb#L27{{</ coderef >}}
```
def solve_a(input)
  floor = 0
  input.each_char do |c|
    floor += c == '(' ? 1 : -1
  end
  floor
end
```

There are two things to recognize about this solution:

- With `input` as a `String` we need to use `String#each_char` instead of a normal `each`
- By adding `-1` when `c != '('` here we don't need multiple statements changing `floor`

One thing I've had to remind myself of is that Ruby favours methods on objects instead of directly writing explicit loops, which is very different from many other object-oriented languages.
Aside from that, I think what I've come up with is easy to understand, fairly fast, and importantly it calculates the correct answer.
I'm not finished this solution though, I want to improve the legibility of the solution by eliminating the external `floor` variable using the `reduce` method.

{{< coderef >}}{{< var "baseurl" >}}/4012fa0a5093b53cbbfadbd3089038d731746eb9//2015/1/solution.rb#L27{{</ coderef >}}
```
def solve_a(input)
  input.each_char.reduce(0) do |floor, c|
    floor += c == '(' ? 1 : -1
  end
end
```

This solution is compact and made the method implementation a single chain of calls; removing of the bare `floor` reference to return the result has greatly improved legibility.
I think this is a "good enough" solution, it's fairly memory efficient, is decently legible, has few focal points vying for attention, and running it yields the correct answer:

```
$ run -y 2015 -q 1 -a
138
```

### Generalized Temptation
One thing to note about my solution is the hard-coded assumption that `floor` will always be an integer value; the assumption leads to the implementation involving addition of ±1 values.
The implementation can have those assumptions removed by using a sequence interface making successor and predecessor values available.

```
def solve_a(input, start = 0)
  input.each_char.reduce(start) do |floor, c|
    c == '(' ? floor.succ : floor.pred
  end
end
```

I find this too generic for the challenge, but it's useful to know about the `succ` and `pred` methods for cases where they do help create better solutions.

## Interlude: Reading Input
I'd like to take a moment before beginning part B to discuss how I'm reading input for the challenge because this can be a large bottleneck in many programs.

{{< coderef >}}{{< var "baseurl" >}}/4012fa0a5093b53cbbfadbd3089038d731746eb9//2015/1/solution.rb#L17{{</ coderef >}}
```
def part_a
  solve_a(File.read('input'))
end
```

I've decided to read the entire file into memory, which in the general case is a bad idea, but for Advent of Code it works reasonably well.
It works because I know the input file for the challenge is not large enough to cause out-of-memory or garbage collection issues.
In your own work, make sure that you know your data set sizes before reading files, and when those files are large utilize available streaming methods to read them in smaller chunks.

## Part B: 1{{< sup st >}} Basement Visit
The second part of this challenge slightly changes the requirements: we need to track the position of each processed instruction and stop when one sends Santa to the basement for the first time.

> Now, given the same instructions, find the position of the first character that causes him to enter the basement (floor -1).
> The first character in the instructions has position 1, the second character has position 2, and so on.
>
> --- _Advent of Code, 2015 Day 1_

Again, I'm beginning by updating the `tests` method to include assertions for solving part B; the challenge gives a few examples that I can add without much effort.

{{< coderef >}}{{< var "baseurl" >}}/bf8eae05654c37ba38a6198b0c25191ebaf4e587/2015/1/solution.rb#L15{{</ coderef >}}
```
def tests
  ...
  assert solve_b(')'), 1
  assert solve_b('()())'), 5
  assert solve_b('(()))(('), 5
  :ok
end
```

You may object to mixing the tests for each part of the challenge and you're not entirely wrong to do so; I don't think these are complicated enough to warrant individual methods, but the refactoring is easy to do and doesn't make the code worse.
To easily solve part B, I'm about to make my implementation a bit worse by rolling back the improvement I made by using `reduce`; keeping it would lead to poor legibility using nested arrays.

{{< coderef >}}{{< var "baseurl" >}}/bf8eae05654c37ba38a6198b0c25191ebaf4e587/2015/1/solution.rb#L37{{</ coderef >}}
```
def solve_b(input)
  floor = 0
  input.each_char.with_index(1) do |c, pos|
    floor += c == '(' ? 1 : -1
    return pos if floor ## -1
  end
end
```

Using `Enumerable#with_index(1)` allows us to start `pos` at the value of one and immediately return its value should the floor match.
This solution still avoids a bare variable as the last expression of the method, but for legibility the `floor` variable must be declared outside of the enumerable block.
Maintaining the `reduce` call would have let me keep `floor` scoped to the enumerable block, but the nested arrays I mentioned previously would have a structure similar to `[floor, [c, pos]]`.
That kind of nested structure would lead to either legibility assignments or direct index accesses within the enumerable block; I don't consider either of those options great for long-term maintainability.
Extracting `floor` out gives us a simple enumerable block for the small sacrifice of increasing the scope of `floor` to the entire method; it's a trade-off I'm willing to make.
Of course, once I run this, the right answer pops up almost immediately thanks to returning early:

```
$ run -y 2015 -q 1 -b
1771
```

## Challenge Completed
We've completed the first Advent of Code challenge without much fanfare and the solutions turned out to be pretty simple.
I think an important lesson to learn from this first challenge is to avoid over-thinking because more complicated solutions are possible.
Remember the purpose of these challenges is to have a learning-experience and practice problem solving skills, so don't get discouraged if you flounder.
Even if you don't get the right answer the first time around, you can end up learning things about Ruby's `Enumerable` class, like the `with_index` method; improvement, however small, is what this is really about.
