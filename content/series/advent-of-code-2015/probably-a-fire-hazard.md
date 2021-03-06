---
title: "Advent of Code 2015: Probably a Fire Hazard"
date: "2020-04-02T01:06:00Z"
tags: [advent-of-code, ruby]
commit-1: https://github.com/tinychameleon/advent-of-code-2015/blob/6236300f16ad0b5fd4c23e1f9c71f649bda6428b/2015/6
commit-2: https://github.com/tinychameleon/advent-of-code-2015/blob/5a77e4e92bd3a23193c4157993f5a2c874eef77b/2015/6
commit-3: https://github.com/tinychameleon/advent-of-code-2015/blob/f9bb19f28698c63a40c17693bba11545cbd9171f/2015/6
commit-4: https://github.com/tinychameleon/advent-of-code-2015/blob/8096497f1557b3faa8e4186223ac608ecaf98adc/2015/6
commit-5: https://github.com/tinychameleon/advent-of-code-2015/blob/b49a07f4569076e01cf0f90447e649a8532bf214/2015/6
---

The sixth Advent of Code [challenge](https://adventofcode.com/2015/day/6) has some decent complexity compared to the last couple problems.
It gave me a great opportunity to poke at Ruby's class functionality to see how method overrides work and how the language attempts to solve the [expression problem](https://en.wikipedia.org/wiki/Expression_problem).
There is a lot of code in this post making it a fairly dense read, so I would suggest taking it on in two sittings.

## Part A: Large-Scale Lite-Brite
This problem has a longer description to tease requirements from and is a good example of how problem questions can be wrapped in verbiage.
It's great practice for problem statement comprehension because real-world problems rarely have requirements laid out in a directly implementable manner.

> Because your neighbors keep defeating you in the holiday house decorating contest year after year, you've decided to deploy one million lights in a 1000x1000 grid.
>
> Furthermore, because you've been especially nice this year, Santa has mailed you instructions on how to display the ideal lighting configuration.
>
> Lights in your grid are numbered from 0 to 999 in each direction; the lights at each corner are at 0,0, 0,999, 999,999, and 999,0. The instructions include whether to turn on, turn off, or toggle various inclusive ranges given as coordinate pairs. Each coordinate pair represents opposite corners of a rectangle, inclusive; a coordinate pair like 0,0 through 2,2 therefore refers to 9 lights in a 3x3 square. The lights all start turned off.
>
> To defeat your neighbors this year, all you have to do is set up your lights by doing the instructions Santa sent you in order.
>
> After following the instructions, how many lights are lit?
>
> --- _Advent of Code, 2015, Day 6_

That's a lot of text, but I think it's best distilled as the following:

- There are 1,000,000 lights in a 1,000&times;1,000 grid
- There are three instructions: turn on, turn off, and toggle
- The light reference points are zero-based like arrays
- Each light reference point pair represents a rectangle on the grid
- The lights are off by default

If we can implement all of that then we can determine how many lights are lit after following all of the input instructions.
Those input instructions look something like this:

{{< coderef >}}{{< var commit-1 >}}/input#L6{{</ coderef >}}
.input {commit-1}/input#L6[source]
[source]
```
turn off 301,3 through 808,453
turn on 351,678 through 951,908
toggle 720,196 through 897,994
```

My first thought is to turn them into an ordered list of data with a symbol representing the instruction and two points representing the rectangle to act upon.
I've written a few tests to ensure that point parsing and instruction parsing inside the `parse_line` method work correctly.

{{< coderef >}}{{< var commit-1 >}}/solution.rb#L87{{</ coderef >}}
```
def test_parse_line
  assert parse_line('turn on 0,0 through 999,999'), [
    :on, Point.new(0, 0), Point.new(999, 999)
  ]
  assert parse_line('toggle 0,0 through 999,0'), [
    :toggle, Point.new(0, 0), Point.new(999, 0)
  ]
  assert parse_line('turn off 499,499 through 500,500'), [
    :off, Point.new(499, 499), Point.new(500, 500)
  ]
end
```

The `Point` class used here is not very exciting and is implemented in a single statement: `Point = Struct.new(:x, :y)`.
To parse each line a regular expression can be associated to each instruction symbol and the numeric point components can be captured.
The regular expressions turn out to be very legible, if a little verbose.

{{< coderef >}}{{< var commit-1 >}}/solution.rb#L109{{</ coderef >}}
```
MATCHERS = {
  on: /turn on (\d+),(\d+) through (\d+),(\d+)/,
  off: /turn off (\d+),(\d+) through (\d+),(\d+)/,
  toggle: /toggle (\d+),(\d+) through (\d+),(\d+)/
}.freeze
```

All `parse_line` will have to handle is selecting the right regular expression and processing its data.
As soon as we find a regular expression match we return the symbol value from `MATCHERS` with the resultant points from the captured integers.

{{< coderef >}}{{< var commit-1 >}}/solution.rb#115{{</ coderef >}}
```
def parse_line(line)
  MATCHERS.each do |k, re|
    m = line.match(re)
    next unless m
    ps = make_points(m.captures)
    return ps.prepend(k)
  end
end
```

Finally, for parsing the instruction data we need to create the `Point` instances from the given numeric capture data in the `make_points` method; I've chosen to just manually construct the points.

{{< coderef >}}{{< var commit-1 >}}/solution.rb#L124{{</ coderef >}}
```
def make_points(captures)
  ps = captures.map(&:to_i)
  [Point.new(ps[0], ps[1]), Point.new(ps[2], ps[3])]
end
```

The next component of the solution to build is something to handle processing the instructions and manipulating the light grid.
For this I want to base the solution around Ruby's class system, so the tests for the `LightGrid` class, with a grid visualization, exercise each of the issuable instructions.

{{< coderef >}}{{< var commit-1 >}}/solution.rb#L61{{</ coderef >}}
```
def test_lightgrid
  g = LightGrid.new(rows: 2, cols: 2)
  #   0 1
  # 0 - -
  # 1 - -
  assert g.count, 0

  #   0 1
  # 0 + -
  # 1 + -
  g.turn_on(Point.new(0, 0), Point.new(0, 1))
  assert g.count, 2

  #   0 1
  # 0 + -
  # 1 - -
  g.turn_off(Point.new(0, 1), Point.new(1, 1))
  assert g.count, 1

  #   0 1
  # 0 - +
  # 1 + +
  g.toggle(Point.new(0, 0), Point.new(1, 1))
  assert g.count, 3
end
```

Let's start with the `initialize` method for the calls to `LightGrid#new` which need to instantiate our grid to the correct size and ensure the lights are off by default.

{{< coderef >}}{{< var commit-1 >}}/solution.rb#L6{{</ coderef >}}
```
def initialize(rows: 1_000, cols: 1_000)
  @grid = [false] * rows * cols
  @cols = cols
end
```

The next error from the test method indicates that `count` isn't a method on the `LightGrid` class and I want it to return the number of lights which are on.

{{< coderef >}}{{< var commit-1 >}}/solution.rb#L11{{</ coderef >}}
```
def count
  @grid.filter(&:itself).count
end
```

Since I've used `false` to represent a light which is off and `true` to represent a light which is on I can filter the grid of lights using `Object#itself` to keep only the `true` values.
This might be a little confusing, so let's break down what actually happens:

- The `Array#filter` keeps only array values that match the filter block or method
- Matching the filter block or method means the return value is `true`
- The `Object#itself` method returns the object it is called on
- The `@grid` array contains boolean values

I feel like Ruby may have a better method for this, something that is more explicit and easily understood, but I don't currently know it.

The final three instruction methods are all very similar, so I will only show the `turn_on` method here, but you can see the other two by following the source link.

{{< coderef >}}{{< var commit-1 >}}/solution.rb#L15{{</ coderef >}}
```
def turn_on(origin, bound)
  for y in origin.y..bound.y
    offset = @cols * y
    for x in origin.x..bound.x
      @grid[offset + x] = true
    end
  end
end
```

Here's where the two-dimensional coordinates are converted into one-dimensional indexes for the `@grid` array by using two nested for-loops.
If you've never seen a two-dimensional array compressed into a one-dimensional array, just picture all the rows of the two-dimensional array side-by-side within the one-dimensional array.
You navigate to a particular row by moving in multiples of the column count and then navigate the row itself by adding the column.

With the `LightGrid` class complete the last remaining step is to wire everything together in the `solve_a` method.
I want to test the wiring works correctly because there's a decent amount of written code in this solution, with some copy-paste repetition that will eventually need to be cleaned up.

{{< coderef >}}{{< var commit-1 >}}/solution.rb#L99{{</ coderef >}}
```
def test_solve_a
  g = LightGrid.new(rows: 2, cols: 2)
  input = <<~data
    turn on 0,0 through 0,1
    turn off 0,1 through 1,1
    toggle 0,0 through 1,1
  data
  assert solve_a(g, input), 3
end
```

The `solve_a` method should take a `LightGrid` and the instruction input, parse that instruction input, apply the instructions to the `LightGrid`, and return the count of lights which are on.
It sounds like a lot, but it ends up being 11 lines of code.

{{< coderef >}}{{< var commit-1 >}}/solution.rb#L129{{</ coderef >}}
```
def solve_a(grid, input)
  input.split("\n").map { |l| parse_line(l) }.each do |action, origin, bound|
    case action
    when :on
      grid.turn_on(origin, bound)
    when :off
      grid.turn_off(origin, bound)
    when :toggle
      grid.toggle(origin, bound)
    end
  end
  grid.count
end
```

After much work we can now solve the first part of this challenge.

```
$ run -y 2015 -q 6 -a
377891
```

## Making It Better
The solution works, but there are two things that bug me greatly about what I've created, and we're going to fix them before moving onto Part B.
Firstly, there is a large amount of duplication in the `LightGrid` class which exists because I copy-pasted the methods to implement them quickly.
Secondly, the `Point` class is a primary data type for this problem and the way it's instantiated via `Point.new(X, Y)` is a little verbose.
I feel that the `.new` syntax, in this case, takes legibility away from the semantic concept of a point.

To solve the first problem, I consolidated the `@grid` navigation logic within a private method called `change_state` which defers the light manipulation logic to a block using `yield`.

{{< coderef >}}{{< var commit-2 >}}/solution.rb#L29{{</ coderef >}}
```
def change_state(origin, bound)
  for y in origin.y..bound.y
    offset = @cols * y
    for x in origin.x..bound.x
      @grid[offset + x] = yield @grid[offset + x]
    end
  end
end
```

The critical thing to understand in this method is that the `yield` keyword handles the sending and receiving of data for a block.
The instruction handling methods all collapse into a single statement and pass a slightly different block into the `change_state` call.

{{< coderef >}}{{< var commit-2 >}}/solution.rb#L15{{</ coderef >}}
```
def turn_on(origin, bound)
  change_state(origin, bound) { true }
end

def turn_off(origin, bound)
  change_state(origin, bound) { false }
end

def toggle(origin, bound)
  change_state(origin, bound) { |b| !b }
end
```

The second problem is solved by --- at least considered by myself to be -- a very neat Ruby idiom which overrides `[]` via a class method.
Once we've done this a point will no longer have to be constructed using `Point.new(x, y)`, instead we can use the more readable syntax of `Point[x, y]`.

{{< coderef >}}{{< var commit-3 >}}/solution.rb#L3{{</ coderef >}}
```
Point = Struct.new(:x, :y) do
  def self.[](x, y)
    Point.new(x, y)
  end
end
```

You can see that this doesn't actually eliminate the `.new` method, it only hides it behind a better interface for creating such a primary data type.
Maybe you think this is going a bit overboard, but I think that legibility of solutions is something that should not be sacrificed unless absolutely necessary.

## Part B: Bright & Intense
The refactorings are out of the way and we can begin working on the second part of this problem; the second portion is just as verbose which means more practice at problem statement comprehension.

> You just finish implementing your winning light pattern when you realize you mistranslated Santa's message from Ancient Nordic Elvish.
>
> The light grid you bought actually has individual brightness controls; each light can have a brightness of zero or more. The lights all start at zero.
>
> The phrase turn on actually means that you should increase the brightness of those lights by 1.
>
> The phrase turn off actually means that you should decrease the brightness of those lights by 1, to a minimum of zero.
>
> The phrase toggle actually means that you should increase the brightness of those lights by 2.
>
> What is the total brightness of all lights combined after following Santa's instructions?
>
> --- _Advent of Code, 2015, Day 6_

The description indicates that only the instruction meanings have changed, and that we should find the total brightness of all the lights for the solution.
The new instruction meanings, for the specified rectangle, are:

- turn on means increment each light by 1
- turn off means decrement each light by 1, with a lower bound of 0
- toggle means increment each light by 2

Aside from these requirements, we're going to need to create some kind of base class for our solution so that parts A and B can share an interface to pass instructions into a light grid.
I'm going to turn `LightGrid` into the interface class and move its functionality into a class called `SwitchLightGrid` since part A contained lights that could only be on or off.

The first change to make is inside the `LightGrid` initialization method --- I need to remove the hard-coded `false` value from the `@grid` initialization code.
The simplest solution is to push that value into the constructor, which is exactly what I've done.

{{< coderef >}}{{< var commit-4 >}}/solution.rb#L10{{</ coderef >}}
```
def initialize(val, rows: 1_000, cols: 1_000)
  @grid = [val] * rows * cols
  @cols = cols
end
```

The second change is to remove the instruction action method implementations and replace them with a `NotImplementedError`.
This will allow `LightGrid` to effectively function as a base class without the ability to be used as a concrete grid in the rest of the code.

{{< coderef >}}{{< var commit-4 >}}/solution.rb#L15{{</ coderef >}}
```
def turn_on(origin, bound)
  raise NotImplementedError
end

def turn_off(origin, bound)
  raise NotImplementedError
end

def toggle(origin, bound)
  raise NotImplementedError
end
```

All that functionality we just removed gets pushed into the new `SwitchLightGrid` class which extends the `LightGrid` as a base class.
What you should notice is that no functionality has really changed within this new class --- it still calls `change_state` and passes in blocks which work on booleans.

{{< coderef >}}{{< var commit-4 >}}/solution.rb#L39{{</ coderef >}}
```
class SwitchLightGrid < LightGrid
  def initialize(rows: 1_000, cols: 1_000)
    super(false, rows: rows, cols: cols)
  end

  def count
    @grid.filter(&:itself).count
  end

  def turn_on(origin, bound)
    change_state(origin, bound) { true }
  end

  def turn_off(origin, bound)
    change_state(origin, bound) { false }
  end

  def toggle(origin, bound)
    change_state(origin, bound) { |b| !b }
  end
end
```

The flexibility `change_state` has from taking a block argument will help with implementing the grid for the second part of this challenge.
That grid will require the use of integers, instead of booleans, and those blocks will implement slightly different transformations of the light values.

I've decided to call the new grid `DimmableLightGrid` since the instructions increase and decrease the brightness of each light.
The tests for it are identical to the previous grid and highlights how this grid functions in a completely different manner.

{{< coderef >}}{{< var commit-5 >}}/solution.rb#L136{{</ coderef >}}
```
def test_dimmablelightgrid
  g = DimmableLightGrid.new(rows: 2, cols: 2)
  #   0 1
  # 0 0 0
  # 1 0 0
  assert g.brightness, 0

  #   0 1
  # 0 1 0
  # 1 1 0
  g.turn_on(Point[0, 0], Point[0, 1])
  assert g.brightness, 2

  #   0 1
  # 0 1 0
  # 1 0 0
  g.turn_off(Point[0, 1], Point[1, 1])
  assert g.brightness, 1

  #   0 1
  # 0 3 2
  # 1 2 2
  g.toggle(Point[0, 0], Point[1, 1])
  assert g.brightness, 9
end
```

The brightness value changes in ways very different to the on and off states of the previous grid and I have included comments representing the grid for clarity again.

{{< coderef >}}{{< var commit-5 >}}/solution.rb#L167{{</ coderef >}}
```
class DimmableLightGrid < LightGrid
  def initialize(rows: 1_000, cols: 1_000)
    super(0, rows: rows, cols: cols)
  end

  def brightness
    @grid.sum
  end

  def turn_on(origin, bound)
    change_state(origin, bound) { |i| i + 1 }
  end

  def turn_off(origin, bound)
    change_state(origin, bound) { |i| 0.max(i - 1) }
  end

  def toggle(origin, bound)
    change_state(origin, bound) { |i| i + 2 }
  end
end
```

This turned out rather well, without much complexity to creating a new light grid, and it mirrors the requirements list in an explicit fashion.
The one piece of additional complexity is the `Integer#max` method, but I think it pulls its own weight here because without it I would either need an additional line of code within the block to hold the decremented value, or I would need to create an array to call `Array#max`.

This little piece of nice looking code is because Ruby solves the expression problem via open classes --- in true object-oriented style, every single class in Ruby is open for your code to modify.

{{< coderef >}}{{< var commit-5 >}}/solution.rb#L9{{</ coderef >}}
```
class Integer
  def max(i)
    self > i ? self : i
  end
end
```

The other minor trick here is that the method parameter doubles as a storage location for the decremented value which allows the grid code to avoid creating its own temporary storage.

Last, but certainly not least, I've refactored the original `solve_a` method into one called `solve_worker` without changing the implementation at all.
The `solve_a` and our new `solve_b` method both now rely on the `solve_worker` method to drive changes to their grid classes and only return the problem solution.

{{< coderef >}}{{< var commit-5 >}}/solution.rb#L227{{</ coderef >}}
```
def solve_a(grid, input)
  solve_worker(grid, input)
  grid.count
end

def solve_b(grid, input)
  solve_worker(grid, input)
  grid.brightness
end
```

The final thing to do is to run the solution to get our answer to Part B.

```
$ run -y 2015 -q 6 -b
14110788
```

## Not So Light-Weight
This problem involved a lot more testing than previous solutions, but I was also able to explore some pretty fundamental parts of Ruby.
Thankfully the solution was not too complicated even though the write-up was dramatically longer than others.
