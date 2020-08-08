---
title: "Advent of Code 2015: All in a Single Night"
date: "2020-05-22T01:26:04Z"
tags: [advent-of-code, ruby]
part-a1-url: https://github.com/tinychameleon/advent-of-code-2015/blob/afc05188dbe34955b46eb0c23fdec0132c344ea0/2015/9/solution.rb
part-a2-url: https://github.com/tinychameleon/advent-of-code-2015/commit/ef30998225c194362c68330c689af94ba3b51368
part-a3-url: https://github.com/tinychameleon/advent-of-code-2015/commit/fb2d2bc7a8e600a9ffc149e808133008ba291e8b
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/32016006ac8dee53118554f4863ad99d39c800b7/2015/9/solution.rb
---

The ninth [Advent of Code challenge](https://adventofcode.com/2015/day/9) involves traversing a graph of distances between cities and can be a bit difficult if you are unfamiliar with graph data structures.
It also provides an opportunity to talk about some very basic profiling techniques using wall-clock times.

## Part A: Shortest Distances
The description for this part is rather short, and contains mostly example data which we will use to create some tests.
When you dig into the description, you may recognize [the Travelling Salesman problem](https://en.wikipedia.org/wiki/Travelling_salesman_problem).

> Every year, Santa manages to deliver all of his presents in a single night.
>
> This year, however, he has some new locations to visit; his elves have provided him the distances between every pair of locations. He can start and end at any two (different) locations he wants, but he must visit each location exactly once. What is the shortest distance he can travel to achieve this?
>
>  --- _Advent of Code, 2015, Day 9_

If you did think of the Travelling Salesman problem, you've been fooled!
This is actually a [Hamiltonian Path problem](https://en.wikipedia.org/wiki/Hamiltonian_path) because the start and end locations do not have to be the same.
Unfortunately, the Hamiltonian Path problem is NP-Complete, so there are no fast and correct solutions.
This isn't going to deter us from solving the problem though, so lets write some tests for parsing the input data.

{{< coderef >}}{{< var part-a1-url >}}#L4{{</ coderef >}}
```
TEST_INPUT = <<~DATA
  London to Dublin = 464
  London to Belfast = 518
  Dublin to Belfast = 141
DATA

def tests
  distances = parse_distances(TEST_INPUT)
  assert distances, {
    ['Belfast', 'London'] => 518,
    ['Belfast', 'Dublin'] => 141,
    ['Dublin', 'London'] => 464
  }
  :ok
end
```

As you can see from `TEST_DATA` the input is a series of lines indicating a starting location, an ending location, and the distance between the two.
The approach will be to use a sorted array of starting and ending locations to reference the distance values, so that we avoid creating an entry for every direction; for example, `London -> Belfast` and `Belfast -> London`.

{{< coderef >}}{{< var part-a1-url >}}#L31{{</ coderef >}}
```
def parse_distances(input)
  input.split.each_slice(5).each_with_object({}) do |line, atlas|
    origin, _to, destination, _eq, distance = line
    atlas[[origin, destination].sort] = distance.to_i
  end
end
```

The first line of this method does quite a lot, and requires the reader to understand the default operation of `String#split`.

- The `String#split` call splits on any white-space characters, yielding an array of strings
- Then `Array#each_slice(5)` enumerates those strings in 5 element chunks
- Which get fed through `Enumerable#each_with_object({})` to provide a hash-map as state we can manipulate with each 5 element chunk

For each line, Ruby's array decomposition functionality is used to pull out the locations and distance in a legible manner.
Finally, we store the distance between sorted locations in the hash-map, which is fittingly named `atlas`.
The benefit of using `Enumerable#each_with_object` here is two-fold:

- There is no need to explicitly return the `atlas` inside the block for each iteration
- The final `atlas` value is returned from `Enumerable#each_with_object`

With distance parsing from input text complete, it's time to implement a method to find the shortest path given a hash-map of distances.
The test for this is a simple one line change:

{{< coderef >}}{{< var part-a1-url >}}#L17{{</ coderef >}}
```
assert shortest_path(distances), 605
```

The implementation code is inefficient, but it's a straight-forward way to determine the shortest path: find the total distance for every ordering of locations and return the minimum value.

{{< coderef >}}{{< var part-a1-url >}}#L38{{</ coderef >}}
```
def shortest_path(distances)
  cities = distances.keys.flatten.uniq
  cities.permutation.map do |ordering|
    ordering.each_cons(2).reduce(0) { |sum, k| sum + distances[k.sort] }
  end.min
end
```

Recall that each key of the `distances` hash-map are two-element arrays of locations, so that `distances.keys` is an enumeration of arrays.
The call to `Array#flatten` turns the nested two-element arrays into a single larger array, and the call to `Array#uniq` eliminates any duplicate entries.
Then we calculate the distance total for every permutation by looking up pairs using the `Enumerable#each_cons` method and finally take the minimum value via `Enumerable#min`.
There are two "tricks" at play here:

- Remember that distance keys are sorted, so `k.sort` is required
- The `each_cons(2)` call pairs up consecutive elements, so `[1, 2, 3].each_cons(2) == [[1, 2], [2, 3]]`

The `shortest_path` method now allows us to calculate the answer to part A:

```
$ run -y 2015 -q 9 -a
207
```

## Improving Performance
The current solution is clear, concise, and doesn't perform very well.
On small data-sets it can spend close to one second simply enumerating the location permutations.
Using the `time` command to judge wall-clock times, the `real` row in the output, for the simple input for part A yields the following profile:

```
$ time run -y 2015 -q 9 -a
207

real    0m0.705s
user    0m0.632s
sys     0m0.006s
```

For larger input sets this performance would not be acceptable because the algorithm we have implemented involves calculating the total distance for every permutation then finding the minimum.
Determining how badly our algorithm performs can be done using [Big-O Notation](https://en.wikipedia.org/wiki/Big_O_notation), which allows us to describe the order of the algorithm as a worst-case.

Our shortest path algorithm does the following:

- Determines the cities by `distances.keys.flatten.uniq`
- Calculates the total distance for every permutation of cities
- Finds the minimum total distance

The minimum total distance can be found in linear time because you only need to look at the elements of an array once to determine the minimum, which means we can express its complexity in Big-O notation as `O(n)`.
Determining the cities is trickier and depends on how `uniq` is implemented, so	I will hand-wave here and say it uses additional memory to achieve linear performance and can be expressed as `O(n)`.

The problem is point #2 because for an array with `n` elements, the number of permutations of those elements is equal to `n!`; we also do a linear operation for each of those orderings to find the individual distance totals, but that doesn't change the factorial performance profile.
This means that our algorithm is dominated by the middle section and can be expressed as `O(n!)`.

To improve performance we need to do less work, so lets think about how to eliminate work earlier in the process.
We can't eliminate enumerating all the permutations, but we can maintain a current minimum and exit earlier in the distance total calculation if we exceed that value.

{{< coderef >}}{{< var part-a2-url >}}{{</ coderef >}}
```
def shortest_path(distances)
  cities = distances.keys.flatten.uniq
  cities.permutation.reduce(Float::INFINITY) do |answer, ordering|
    ordering.each_cons(2).reduce(0) do |sum, k|
      sum += distances[k.sort]
      break answer if sum > answer
      sum
    end
  end
end
```

With this implementation we keep track of our current minimum as `answer` and reduce from a maximum answer of infinity to something more reasonable and correct.
For each ordering we short-circuit using `break` when our current distance `sum` exceeds our current `answer`.
It's important to notice that `break` takes a value: we maintain `answer` when we exit the total distance calculation early because the value passed to `break` becomes the value of the reduce expression.

What do we gain by re-organizing our algorithm like this?

```
$ time run -y 2015 -q 9 -a
207

real    0m0.499s
user    0m0.420s
sys     0m0.006s
```

A 29% performance improvement, which isn't too bad for such a small change.
Since this problem is NP-Complete, it is not possible to find the correct minimum unless all `n!` permutations are considered, which means our algorithm will always be of the order `O(n!)`.
However, there are still improvements we can make to reduce other factors which slow down the algorithm.

## Sacrificial Memory
The second, and final, optimization we'll make to the algorithm will trade memory usage for computation speed.
It's a strategy that doesn't necessarily work for all input sizes, since the larger the input size the more memory will be utilized.
Our optimization is going to remove the sorting requirement on distance keys and migrate the hash-map toward a nested hash-map of locations; let's modify the tests to get a better picture of what the result will be.

{{< coderef >}}{{< var part-a3-url >}}{{</ coderef >}}
```
def tests
  distances = parse_distances(TEST_INPUT)
  assert distances, {
    'London' => { 'Belfast' => 518, 'Dublin' => 464 },
    'Belfast' => { 'London' => 518, 'Dublin' => 141 },
    'Dublin' => { 'Belfast' => 141, 'London' => 464 }
  }
  assert shortest_path(distances), 605
  :ok
end
```

The parsed distance values now reflect the bi-directional travel between locations by duplicating the distance information across each key.
The `parse_distances` method changes a little, but there are still some familiar aspects remaining, like the `split.each_slice(5)` method chain.

{{< coderef >}}{{< var part-a3-url >}}{{</ coderef >}}
```
def parse_distances(input)
  atlas = Hash.new { |h, k| h[k] = {} }
  input.split.each_slice(5) do |origin, _to, destination, _eq, distance|
    d = distance.to_i
    atlas[origin][destination] = d
    atlas[destination][origin] = d
  end
  atlas
end
```

The array decomposition for each line is promoted into the block arguments of `Enumerable#each_slice` and the body of the block writes the distance into the atlas for both location directions.
At this point the tests are broken because the `shortest_path` method still expects the original distances data structure; that is the next thing to modify.

{{< coderef >}}{{< var part-a3-url >}}{{</ coderef >}}
```
def shortest_path(distances)
  cities = distances.keys
  cities.permutation.reduce(Float::INFINITY) do |answer, ordering|
    ordering.each_cons(2).reduce(0) do |sum, k|
      sum += distances.dig(*k)
      break answer if sum > answer
      sum
    end
  end
end
```

The calls to `flatten.uniq` disappear since our distances hash-map now enforces that for us, and the only other change is `distances[k.sort]` became `distances.dig(*k)`.
That particular line represented a sizable amount of work and reduces computation costs considerably because direct hash-map look-ups are more predictable for the CPU than sorting and a hash-map look-up.

```
$ time run -y 2015 -q 9 -a
207

real    0m0.298s
user    0m0.214s
sys     0m0.006s
```

This change gives us another 40% speed-up and brings the total time down to something I consider more reasonable, which means we can move on to solving part B.

## Part B: The Scenic Route
The second part of the challenge requires us to calculate the exact opposite: the longest path.

> The next year, just to show off, Santa decides to take the route with the longest distance instead.
>
> He can still start and end at any two (different) locations he wants, and he still must visit each location exactly once.
>
> What is the distance of the longest route?
>
> --- _Advent of Code, 2015, Day 9_

Tests are a good starting point for our `longest_path` method, so lets add the example provided by the challenge as a test.

{{< coderef >}}{{< var part-b-url >}}#L18{{</ coderef >}}
```
assert longest_path(distances), 982
```

Similar to the `shortest_path` implementation, there is no avoiding checking every permutation of the locations; that makes our `longest_path` implementation also `O(n!)` in Big-O notation.
The code is simpler because finding the maximum distance precludes an early exit --- the sum of distances between all locations in an ordering must be calculated to know if it is larger than the current maximum.

{{< coderef >}}{{< var part-b-url >}}#L53{{</ coderef >}}
```
def longest_path(distances)
  distances.keys.permutation.reduce(0) do |answer, ordering|
    sum = ordering.each_cons(2).reduce(0) { |sum, k| sum + distances.dig(*k) }
    sum > answer ? sum : answer
  end
end
```

One detail to highlight is that we reduce starting from zero instead of infinity to represent the fact that our `answer` is increasing instead of decreasing.
With that we can find the solution for the longest distance:

```
$ run -y 2015 -q 9 -b
804
```

## Graphs and Data Structures
Ruby's hash-map and array data structures offer a wide feature set that helps write algorithms succinctly.
It's wonderful to be able to access permutations, consecutive pairings, and slices without any ceremony or manual implementation work.
Array decomposition also helps create legible code when dealing with tuple-style array usage.

This challenge is also useful to displaying how machine-friendly optimizations can still be applied to improve performance when faced with an NP-Complete problem.
Our original `shortest_path` solution was improved by approximately 57% through better organization of data and using additional memory to avoid computational work.
