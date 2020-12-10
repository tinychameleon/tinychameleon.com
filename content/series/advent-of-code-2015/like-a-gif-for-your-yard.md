---
title: "Advent of Code 2015: Like a GIF for Your Yard"
date: "2020-12-10T05:45:22Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/ba5ab294081401067507472cd7b7c52d3bea4b8a/2015/18/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/fe6833b3d099eb7216a4ea1267fb7185eff25e80/2015/18/solution.rb
---

The [eighteenth Advent of Code challenge](https://adventofcode.com/2015/day/18) is a twist on a [prior day's challenge]({{< ref "series/advent-of-code-2015/probably-a-fire-hazard.md" >}}).
We'll tackle this one similarly, using a class to contain the grid logic.

## Part A: Game of Lights
The problem statement for this challenge is _very_ long; take a read and then we'll create a set of requirements. 

> After the million lights incident, the fire code has gotten stricter: now, at most ten thousand lights are allowed. You arrange them in a 100x100 grid.
>
> Start by setting your lights to the included initial configuration (your puzzle input). A # means "on", and a . means "off".
>
> Then, animate your grid in steps, where each step decides the next configuration based on the current one. Each light's next state (either on or off) depends on its current state and the current states of the eight lights adjacent to it (including diagonals). Lights on the edge of the grid might have fewer than eight neighbors; the missing ones always count as "off".
>
> The state a light should have next is based on its current state (on or off) plus the number of neighbors that are on:
>
> - A light which is on stays on when 2 or 3 neighbors are on, and turns off otherwise.
> - A light which is off turns on if exactly 3 neighbors are on, and stays off otherwise.
>
> All of the lights update simultaneously; they all consider the same current state before moving to the next.
>
> In your grid of 100x100 lights, given your initial configuration, how many lights are on after 100 steps?
>
> --- _Advent of Code, 2015, Day 18_

The goal is to determine how many lights are on, and so we need to be able to calculate that somehow.
There are other requirements too, but they reduce to [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life).

We'll start with the important task of counting how many lights are on and loading the input data.
The test data will come from the example in the challenge.

{{< coderef >}}{{< var part-a-url >}}#L50{{</ coderef >}}
```
TEST_INPUT = <<~DATA.freeze
  .#.#.#
  ...##.
  #....#
  ..#...
  #.#..#
  ####..
DATA
```

To load this data, a `load_grid` method will suffice, and I want to access all this as a single array eventually instead of using a multi-dimensional array.

{{< coderef >}}{{< var part-a-url >}}#L60{{</ coderef >}}
```
assert load_grid(".#\n..\n"), '.#..'
```

The `load_grid` method itself is rather simple: read the lines and join them all together into one large string for further processing later.

{{< coderef >}}{{< var part-a-url >}}#L78{{</ coderef >}}
```
def load_grid(input)
  input.lines.map(&:chomp).join
end
```

The next step will be to create our `Grid` class which will deal with counting the number of lights that are on and eventually will implement the step logic for changing the state of lights.
A `lights_on` method will do nicely, but we also must create a constructor for the `Grid` class.

{{< coderef >}}{{< var part-a-url >}}#L61{{</ coderef >}}
```
g = Grid.new(6, 6, load_grid(TEST_INPUT))
assert g.lights_on, 15
```

To initialize a `Grid`, we'll need to store the dimensions and prepare the state of all lights.
I've decided to use the symbols `:on` and `:off` to represent the state of each light.

{{< coderef >}}{{< var part-a-url >}}#L3{{</ coderef >}}
```
class Grid
  attr_reader :lights

  def initialize(rows, cols, input)
    @rows = 0...rows
    @cols = 0...cols
    @memo = {}
    @lights = input.each_char.map { |c| c == '.' ? :off : :on }
  end
```

Here, the rows and column values are stored as half-open ranges via the `...` range syntax; a half-open range excludes the final value.
After that I convert each character in the input string from `load_grid` to the symbol representing its state, and I've also prepared an instance variable `@memo` to hold neighbour calculations which we will see later.

With the initialization of the class completed, writing the `lights_on` method becomes a matter of counting the number of `:on` symbols within the `@lights` array.

{{< coderef >}}{{< var part-a-url >}}#L21{{</ coderef >}}
```
def lights_on
  @lights.count(:on)
end
```

The next thing to implement is the step logic, which we can add to the `Grid` class as a method named `step`.
If we take four steps from the example grid state, we should end up with four lights on, so let's write a test to verify that.


{{< coderef >}}{{< var part-a-url >}}#L63{{</ coderef >}}
```
4.times { g.step }
assert g.lights_on, 4
```

However, in order to successfully step to the next state of the grid, we need a few things:

- the ability to determine the number of neighbours which are `:on`
- the transition logic to determine if a light should turn on or off
- and the step processing logic

All of these helper methods will be tested by the higher-level `lights_on` assertion after running `step`.
Let's start with the transition logic by implementing `Grid#transition`

{{< coderef >}}{{< var part-a-url >}}#L41{{</ coderef >}}
```
def transition(state, neighbouring_ons)
  return :off if state == :on && !(2..3).include?(neighbouring_ons)
  return :on if state == :off && neighbouring_ons == 3

  state
end
```

By taking a number of neighbouring lights which are on and the current state of a light we can decide what the next state should be by transcribing the bullet points from the example.

To determine the number of neighbours which are `:on` we need to check around each light by its row and column index, which means we need to be able to calculate those neighbouring row and column values.

{{< coderef >}}{{< var part-a-url >}}#L27{{</ coderef >}}
```
DELTAS = [
  [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]
].freeze

def neighbour_states(x, y)
  k = [x, y]
  unless @memo.key?(k)
    @memo[k] = DELTAS.map { |dx, dy| [dx + x, dy + y] }.filter do |nx, ny|
      @cols.member?(nx) && @rows.member?(ny)
    end
  end
  @memo[k].map { |nx, ny| @lights[nx + ny * @cols.end] }
end
```

The `DELTAS` array holds all the different ways we can modify the current row and column positions to move to a neighbour and determining those neighbours happens once for each row and column by storing the result into `@memo`.
Let's look at the calculation for neighbours more closely and pick apart what each bit does:

- The result of the calculation is stored into `@memo[k]` where `k` is the array `[x, y]` which represents the column and the row value.
- The `DELTAS` are mapped to apply them to the row and column value to get all the neighbouring positions.
- The array of neighbouring positions is sent through `filter` to remove any out-of-bound values, like `[-1, -1]` for the light at `[0, 0]`.

All of this is only done one time and skipped if we already have calculated the neighbours for this row and column.
Afterwards we pull the valid neighbours out of `@memo[k]` and translate them into light states.

Now we're ready to write the `step` method logic which can convert a one-dimensional array to row and column values and apply the transition of states to move to the next grid state.

{{< coderef >}}{{< var part-a-url >}}#L13{{</ coderef >}}
```
def step
  @lights = @lights.map.with_index do |state, i|
    y = i / @cols.end
    x = i % @cols.end
    transition(state, neighbour_states(x, y).count(:on))
  end
end
```

We combine the helper methods to determine the new state of the light at index `i` by counting the number of `:on` lights are present.
Now the test we wrote for four steps passes and the last thing to do is to wire up the `solve_a` method to determine how many lights are on after one hundred steps.

{{< coderef >}}{{< var part-a-url >}}#L82{{</ coderef >}}
```
def solve_a(input)
  g = Grid.new(100, 100, load_grid(input))
  100.times { g.step }
  g.lights_on
end
```

When we run the solution, we get our answer.

```
$ run -y 2015 -q 18 -a
768
```

## Part B: Defective Lights
According to the second part, it turns out that we're rather cheap and bought some lights that don't work properly; some of the lights are stuck in the `:on` state.

> At least, it was, until you notice that something's wrong with the grid of lights you bought: four lights, one in each corner, are stuck on and can't be turned off.
>
> In your grid of 100x100 lights, given your initial configuration, but with the four corners always in the on state, how many lights are on after 100 steps?
>
> --- _Advent of Code, 2015, Day 18_

To implement this defect, I'd like to extend the solution with a parameter that takes an array of positions indicating which lights are stuck.
Let's start with some test data from the example.

{{< coderef >}}{{< var part-b-url >}}#L61{{</ coderef >}}
```
TEST_STUCK_INPUT = <<~DATA.freeze
  ##.#.#
  ...##.
  #....#
  ..#...
  #.#..#
  ####.#
DATA
```

Let's also extend our tests with a new `Grid` instance that takes advantage of this new, optional parameter, which I've named `always_on`.

{{< coderef >}}{{< var part-b-url >}}#L77{{</ coderef >}}
```
g = Grid.new(6, 6, load_grid(TEST_STUCK_INPUT),
             always_on: [[0, 0], [5, 0], [0, 5], [5, 5]])
5.times { g.step }
assert g.lights_on, 17
```

The first thing to change is the `Grid` constructor, since we need to take that new parameter and store it for use.

{{< coderef >}}{{< var part-b-url >}}#L6{{</ coderef >}}
```
def initialize(rows, cols, input, always_on: [])
  @rows = 0...rows
  @cols = 0...cols
  @memo = {}
  @always_on = always_on
  @lights = input.each_char.map { |c| c == '.' ? :off : :on }
end
```

Not much has changed here; just storing the parameter.
The `transition` method will need to change though --- we need to ensure it always returns `:on` for any stuck light.

{{< coderef >}}{{< var part-b-url >}}#L42{{</ coderef >}}
```
def transition(state, coords, neighbouring_ons)
  return :on if @always_on.include?(coords)
  return :off if state == :on && !(2..3).include?(neighbouring_ons)
  return :on if state == :off && neighbouring_ons == 3

  state
end
```

We've changed the method to also take the `coords` that we are currently examining, and to check if that `coords` position is present in the `@always_on` array that we initialized the `Grid` with.
Since `transition` has changed its parameter list we will need to also update the `step` method that uses it.

{{< coderef >}}{{< var part-b-url >}}#L14{{</ coderef >}}
```
def step
  @lights = @lights.map.with_index do |state, i|
    y = i / @cols.end
    x = i % @cols.end
    transition(state, [x, y], neighbour_states(x, y).count(:on))
  end
end
```

The only change here is to pass the correct position as `[x, y]`.
Now we can determine the result by wiring up the `solve_b` method similarly to the first part and find the answer.

```
$ run -y 2015 -q 18 -b
781
```

## Light Shows Must Go On
This problem was a very fun extension of the earlier one, and allowed for some simple optimization passes for calculating neighbours.
Sometimes these kinds of memory and compute trade-offs are useful in applications, so it's always nice to be able to practice implementing them.
