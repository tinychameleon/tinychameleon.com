---
title: "Advent of Code 2015: Perfectly Spherical Houses in a Vacuum"
date: "2020-03-11T02:22:24Z"
tags: ["advent-of-code", "ruby"]
part-a-url: "https://github.com/tinychameleon/advent-of-code-2015/blob/246e3d7758c5cd2e02c41c47a6792075fd7a77a7/2015/3/solution.rb"
part-b-url: "https://github.com/tinychameleon/advent-of-code-2015/blob/c21e517aa4c96b4b69390ccca766aaa4cad90c88/2015/3/solution.rb"
---

The third Advent of Code [problem](https://adventofcode.com/2015/day/3) is pretty fun, involving translating directions and maintaining a record of previous locations.
In this solution I've decided to explore and learn Ruby's standard `Set` data structure, even though it's completely unnecessary to solve the problem.
I've used sets in other languages, but not in Ruby, so it's time to see what's on offer.

## Part A: The Santa Tracker
Once again, let's begin by breaking down the problem statement into a simple, digestible list of points.

> Santa is delivering presents to an infinite two-dimensional grid of houses.
>
> He begins by delivering a present to the house at his starting location, and then an elf at the North Pole calls him via radio and tells him where to move next. Moves are always exactly one house to the north (^), south (v), east (>), or west (<). After each move, he delivers another present to the house at his new location.
>
> However, the elf back at the north pole has had a little too much eggnog, and so his directions are a little off, and Santa ends up visiting some houses more than once. How many houses receive at least one present?
>
> --- _Advent of Code, 2015, Day 3_

The last sentence is what I need to solve for, the count of houses that receive ≥ 1 present, but there's lots here which makes our code easier to write.
I see these important requirements to keep in mind for the solution:

- There are no bounds on the housing grid
- Santa always moves 1 unit of distance, no matter the direction
- Directions are given as input using simple arrow-like characters
- One present is delivered on arrival to a location Santa visits

I will start with some tests to lay out what I expect as output from the `santa_tracker` method because this one is going to be a bit more complex.
For the method I want to return a `Hash` where the keys are `X` coordinates and the values are a `Set` of `Y` coordinates.
This will represent all the `(X, Y)` coordinates that Santa has visited and will allow me to figure out how many houses were visited at least once.

{{< coderef >}}{{< var part-a-url >}}#L6{{</ coderef >}}
```
assert santa_tracker('>'), { 0 => Set[0], 1 => Set[0] }
assert santa_tracker('^>v<'), { 0 => Set[0, 1], 1 => Set[1, 0] }
assert santa_tracker('^v^v^v^v^v'), { 0 => Set[0, 1] }
```

Before I start implementing the `santa_tracker` method there are a few things I want to codify to make my life easier for the core of the implementation.
I want to represent the directional characters of the input as coordinate-pair deltas, so that I can simply add that difference to the current position of Santa.

{{< coderef >}}{{< var part-a-url >}}#L33{{</ coderef >}}
```
DELTAS = {
  '>' => Point.new(1, 0),
  '<' => Point.new(-1, 0),
  '^' => Point.new(0, 1),
  'v' => Point.new(0, -1)
}.freeze
```

Now when I encounter a "move south" `v` character I know that the `X` coordinate will remain the same and the `Y` coordinate will be decreased by 1.
Following this, I need define the `Point` class and give it an `add` method to support the strategy I want to take for processing the challenge input.

{{< coderef >}}{{< var part-a-url >}}#L26{{</ coderef >}}
```
Point = Struct.new(:x, :y) do
  def add(other)
    self.x += other.x
    self.y += other.y
  end
end
```

Nothing too fancy --- just a simple `Struct` with some method definitions; if you're not used to doing algebra try to recall that adding a negative number is the same as subtracting the positive number.
With these pieces set up I'm ready to begin implementing the `santa_tracker`.

{{< coderef >}}{{< var part-a-url >}}#L46{{</ coderef >}}
```
def santa_tracker(directions)
  houses = new_house_map
  pos = Point.new(0, 0)
  directions.each_char do |c|
    pos.add(DELTAS[c])
    houses[pos.x].add(pos.y)
  end
  houses
end
```

This function is just a loop over each direction character to apply the position update and record visiting the house; I think it's pretty simple at heart.
So what's up with that `new_house_map` method?
Well, if you look closely at the code you will notice I never check if an `X` coordinate key exists in the `Hash` before adding the `Y` coordinate.
This requires a `Hash` which sets a default value for newly added keys, which I have encapsulated in the `new_house_map` method.

{{< coderef >}}{{< var part-a-url >}}#L40{{</ coderef >}}
```
def new_house_map
  map = Hash.new { |h, k| h[k] = Set.new }
  map[0].add(0)
  map
end
```

Whenever I add a new key to the `Hash` it will run the block to provide a default value for my code to immediately use; I've also been a little sneaky and added the coordinate-pair `(0, 0)` to it.
With all of this in place I can wire together everything to solve part A.

{{< coderef >}}{{< var part-a-url >}}#L56{{</ coderef >}}
```
def solve_a(input)
  santa_tracker(input).values.map(&:count).sum
end
```

Remember, I said each value stored in the `Hash` are `Set` instances containing `Y` coordinates for each `X` coordinate key.
By counting the number of elements in each `Set` then adding those counts together I find the number of houses with at least 1 gift.

```
$ run -y 2015 -q 3 -a
2565
```

## Part B: The Duo Tracker
The second portion of this challenge sees Santa get a little help from [Robo-Santa](https://www.youtube.com/watch?v=iWxsK3uvkYc).

> The next year, to speed up the process, Santa creates a robot version of himself, Robo-Santa, to deliver presents with him.
>
> Santa and Robo-Santa start at the same location (delivering two presents to the same starting house), then take turns moving based on instructions from the elf, who is eggnoggedly reading from the same script as the previous year.
>
> This year, how many houses receive at least one present?
>
> --- _Advent of Code, 2015, Day 3_

This time I still have to answer the same question, but the catch is that Santa and Robo-Santa both utilize the same input with each of them consuming half.
The tests I wrote for `duo_tracker` use almost identical input to the `santa_tracker` tests, so it is obvious how the output changes because of Santa's helper.

{{< coderef >}}{{< var part-b-url >}}#L14{{</ coderef >}}
```
assert duo_tracker('^v'), { 0 => Set[0, 1, -1] }
assert duo_tracker('^>v<'), { 0 => Set[0, 1], 1 => Set[0] }
assert duo_tracker('^v^v^v^v^v'), { 0 => Set[*(-5..5)] }
```

The change is particularly dramatic for the third test, where instead of two houses receiving gifts, eleven do.
The implementation is nearly identical in semantics, but differs in the details while using some pretty interesting features.

{{< coderef >}}{{< var part-b-url >}}#L64{{</ coderef >}}
```
def duo_tracker(directions)
  houses = new_house_map
  duo = [Point.new(0, 0), Point.new(0, 0)]
  directions.each_char.zip(duo.cycle).each do |c, pos|
    pos.add(DELTAS[c])
    houses[pos.x].add(pos.y)
  end
  houses
end
```

The body of the loop in this solution is identical, I'm still tracking the `X` and `Y` coordinates in the same `Hash` from part A, but the values being iterated over have changed.
The `Array#cycle` method is a really neat way to repeat the contents of the given array infinitely, so that `[A, B, C].cycle` is equivalent to `[A, B, C, A, B, C, A, B, C, ...]`.
The `zip` method pairs each character from the directions with one of the duo's infinitely cycled `Point` values and ends when we've exhausted the directions.

With that implemented, the `solve_b` method is identical to `solve_a` except that it calls `duo_tracker` instead.

```
$ run -y 2015 -q 3 -b
2639
```

## Santa Wants to Know Your Location
Challenge 2015-3 was fun to solve and it let me explore Ruby's standard `Set`, so I can't really ask for more.
I may not use `Set` very often going forward, but now I have a feel for it when I do need it in the future.

The `Set` class highlighted something important to me: Ruby supports creating your own syntax for data type literals.
Creating a `Set` object using `Set[1, 2, 3]` is almost as nice as a language with built-in syntax to create sets.
I think the ability to define the `self.[]` method on a class is a major benefit, since it dramatically reduces the friction of defining and using data types.
