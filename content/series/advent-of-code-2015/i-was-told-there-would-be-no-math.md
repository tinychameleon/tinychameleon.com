---
title: "Advent of Code 2015: I Was Told There Would Be No Math"
date: "2020-02-26T01:41:47Z"
tags: ["advent-of-code", "ruby"]
part-a-url: "https://github.com/tinychameleon/advent-of-code-2015/blob/1290c96e09bea366d6478f1afb28b860873370de/2015/2"
part-b-url: "https://github.com/tinychameleon/advent-of-code-2015/blob/adae192b731eeb0e40886ed4c2ba3846d4284b23/2015/2/solution.rb"
---

Now that the first challenge is behind us and we've built up a little experience, we're going to jump right into the second Advent of Code 2015 [problem](https://adventofcode.com/2015/day/2).
This one does require a bit of math, but it's all laid out by the challenge problem and doesn't require you to actually know any of the equations.

## Part A: Wrapping Paper by the Foot{{< sup 2 >}}
The first problem statement is fairly dense, so I want to take some time to distil it into easily digestible points; I encourage you to try this for yourself before reading on because it's an important skill to practice.

> The elves are running low on wrapping paper, and so they need to submit an order for more. They have a list of the dimensions (length l, width w, and height h) of each present, and only want to order exactly as much as they need.
>
> Fortunately, every present is a box (a perfect right rectangular prism), which makes calculating the required wrapping paper for each gift a little easier: find the surface area of the box, which is 2lw + 2wh + 2hl. The elves also need a little extra paper for each present: the area of the smallest side.
>
> All numbers in the elves' list are in feet. How many total square feet of wrapping paper should they order?
>
> --- _Advent of Code, 2015, Day 2_

When I look at this problem statement there are five things that stand out to me, yours may be slightly different and that's okay.
I noticed that:

- I will need to parse a list of dimensions
- I need to calculate the surface area of each item in the list
- I need to add the area of the smallest side of each item in the list
- I do not need to worry about unit conversions
- I need to find the total of every item's total as the answer

This kind of terse requirements list is great to work from while solving a problem because it's easy to scan for information.

I have to parse a list of gift dimensions, so to start I like to peek at the input format and decide how parsing responsibilities should be split between potential components.
Looking at the input file, it's made up of line-wise descriptions of gifts using a simple `LxWxH` format.

{{< coderef >}}{{< var part-a-url >}}/input{{</ coderef >}}
```
4x23x21
22x29x19
11x4x11
8x10x5
...
```

Thinking a little, I've decided that the parsing of an individual line should be done by whatever method is responsible for returning the area value.
To me, this presents a nice interface where I can input a `String` like `"2x3x4"` and get back the area as an `Integer` like `58`, and allows me to easily iterate over the lines in the file without a discrete parsing step.
I'm going to begin with creating a few tests for the `necessary_paper` method I will create.
Please be aware that in order to save space I am not showing the surrounding `tests` method, so click through to the source to see the full implementation.

{{< coderef >}}{{< var part-a-url >}}/solution.rb#L5{{</ coderef >}}
```
assert necessary_paper('2x3x4'), 58
assert necessary_paper('1x1x10'), 43
assert necessary_paper('1x1x1'), 7
```

Now, I don't think `necessary_paper` really needs to have the parsing for the `LxWxH` values in-line; I would prefer a separate class to have the responsibility of calculating geometry equations and the line parsing can be folded into that class.
Taking these things into account, I've implemented the `necessary_paper` method as follows:

{{< coderef >}}{{< var part-a-url >}}/solution.rb#L33{{</ coderef >}}
```
def necessary_paper(dimensions)
  b = Box.from(dimensions)
  b.areas.min + b.areas.sum * 2
end
```

If you recall from the list of requirements I made above, the total paper for a given gift is the sum of the smallest side's area and the surface area of the gift.
The `Box#areas` method returns the areas of the three distinct faces as an array, so we can easily use it to find the smallest area and the total surface area.
One subtlety to this implementation is that I am returning the three distinct faces in `areas`, but each of these faces occurs twice since rectangular prisms have 6 sides, hence the multiplying by 2.
If that doesn't make sense to you, here is a short set of algebraic transformations that should be fairly easy to follow along with.

```
2*L*W + 2*W*H + 2*H*L = b.areas.sum * 2
                      = (L*W + W*H + H*L) * 2
                      = 2*L*W + 2*W*H + 2*H*L
```

With the `necessary_paper` method complete, I'm ready to start working on the supporting `Box` class, which I've decided to implement as a value-type using Ruby's `Struct` class.

{{< coderef >}}{{< var part-a-url >}}/solution.rb#L23{{</ coderef >}}
```
Box = Struct.new(:l, :w, :h) do
  def self.from(str)
    Box.new(*str.split('x').map(&:to_i))
  end

  def areas
    [l * w, l * h, w * h]
  end
end
```

The static method `from` is where I have chosen to push the line parsing responsibility, but it doubles as a very readable way of constructing a `Box` instance --- I think `Box.from(dimensions)` reads beautifully.
The interior call to `Box.new` might be difficult to understand, so I want to break it down for clarity.

The `&ast;` syntax at the beginning allows the individual parameters of a method to come from an array; if I had a method call `m(1, 2, 3)` this could also be written as `m(&ast;[1, 2, 3])`.
When you're building parameters dynamically this syntax is incredibly useful!
Next there is the `str.split('x')` expression to turn the `"LxWxH"` entries into arrays like `["L", "W", "H"]`.
Finally `map` is called on that array and applies the `to_i` method to each `String` within it resulting in an array of `Integer` values for each dimension of the gift.

The tests I wrote pass now that the `Box` class implementation is complete, and as the next step we can start implementing the `solve_a` method.
I will start by writing a test for the method, keeping in mind that I previously decided this function will take multiple lines of input.

{{< coderef >}}{{< var part-a-url >}}/solution.rb#L9{{</ coderef >}}
```
assert solve_a("2x3x4\n1x1x1"), 65
```

From this test, the implementation of `solve_a` seems obvious to me; I know the input must be split line-wise, that each line needs its necessary paper area calculated, and a sum of those areas is the result.

{{< coderef >}}{{< var part-a-url >}}/solution.rb#L38{{</ coderef >}}
```
def solve_a(input)
  input.split.map { |d| necessary_paper(d) }.sum
end
```

Very quickly my solution is complete and highlights Ruby's potential for writing succinct, left-to-right expressions which solve problems elegantly.
This is also the reason I have enjoyed learning Ruby over the last few weeks --- it's uncanny ability to stay out of my way.

If I run the solution for part A, I get the correct answer.

```
$ run -y 2015 -q 2 -a
1598415
```

## Part B: Ending with a Bow
The second part of this challenge is a similar task involving finding the length of ribbon required for each gift.

> The elves are also running low on ribbon. Ribbon is all the same width, so they only have to worry about the length they need to order, which they would again like to be exact.
>
> The ribbon required to wrap a present is the shortest distance around its sides, or the smallest perimeter of any one face. Each present also requires a bow made out of ribbon as well; the feet of ribbon required for the perfect bow is equal to the cubic feet of volume of the present. Don't ask how they tie the bow, though; they'll never tell.
>
> How many total feet of ribbon should they order?
>
> --- _Advent of Code, 2015, Day 2_

Again, I am going to condense this description into a set of bullet points to ensure I understand the requirements.
The important bits I see are:

- I only need to consider length
- I need to find the smallest perimeter of the gift faces
- I need to find the volume of the gift
- I need to sum all of these to find the answer

The implementation I created for pat A will help immensely now, I can extend the `Box` class to include methods for these new requirements.
First, I want to create some tests for a new method called `necessary_ribbon` which will follow the same interface as `necessary_paper`: it will take a `String` and return the total length as an `Integer`.

{{< coderef >}}{{< var part-b-url >}}#L11{{</ coderef >}}
```
assert necessary_ribbon('2x3x4'), 34
assert necessary_ribbon('1x1x10'), 14
assert necessary_ribbon('1x1x1'), 5
```

These are nearly identical to the prior tests we've written --- it's very easy to hammer out new tests to ensure we're implementing things correctly when we follow a similar interface for each method.
The body of `necessary_ribbon` will also look familiar because of that interface similarity.

{{< coderef >}}{{< var part-b-url >}}#L55{{</ coderef >}}
```
def necessary_ribbon(dimensions)
  b = Box.from(dimensions)
  b.perimeters.min + b.volume
end
```

I had to make an interesting decision regarding whether `Box` should know about the ribbon requirements and return the minimum perimeter directly, or if it should simply return the face perimeters.
I've opted for the latter because I consider it cleaner for `Box` to avoid knowledge of the challenge requirements, it mirrors the `areas` implementation nicely, and I feel that it's not too inefficient to call `min` on a 3 element array.

{{< coderef >}}{{< var part-b-url >}}#L38{{</ coderef >}}
```
def volume
  l * w * h
end
```

I began by implementing `volume` since it's trivial to complete, but do allow yourself to enjoy the simplicity and low ceremony of Ruby here, as I did, before progressing to the `perimeters` method.

{{< coderef >}}{{< var part-b-url >}}#L42{{</ coderef >}}
```
def perimeters
  ll = l + l
  ww = w + w
  hh = h + h
  [ll + ww, ll + hh, ww + hh]
end
```

One thing of minor interest with `perimeters` is I've chosen to cache the reusable, partial perimeter sums to improve the legibility of the final array expression.
With these two methods complete, I can move on to writing tests and code for the `solve_b` method.

{{< coderef >}}{{< var part-b-url >}}#L15{{</ coderef >}}
```
assert solve_b("2x3x4\n1x1x1"), 39
```

I used identical test input again for quickly implementing the new assertions; having a similar interface is really great.
I'm sorry to say that `solve_b` is really not interesting --- it's almost identical to `solve_a`.

{{< coderef >}}{{< var part-b-url >}}#L64{{</ coderef >}}
```
def solve_b(input)
  input.split.map { |d| necessary_ribbon(d) }.sum
end
```

Of course, now I run the solution to get the correct answer for part B.

```
$ run -y 2015 -q 2 -b
3812909
```

## All Wrapped Up
With that done challenge 2015-2 is complete and it was really pretty simple, but it still gave me an opportunity to learn about the `Struct` class which Ruby offers.
In my opinion that's a win, and proof that a challenge doesn't have to be very difficult to provide a valuable learning experience.
