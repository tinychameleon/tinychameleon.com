---
title: "Advent of Code 2015: Medicine for Rudolph"
date: "2021-03-28T19:15:35Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/ddae82e3bd6d28bc0660369917565764f2e89fa5/2015/19/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/4602941aa9c8248586fabef7baadb82a12c24790/2015/19/solution.rb
---

The [nineteenth Advent of Code challenge](https://adventofcode.com/2015/day/19) is another problem revolving around large volumes of text replacement.
Like previous solutions, we'll need to rely on `Enumerator` and the bevy of `Enumerable` methods to easily solve it.

Due to my lack of time to dedicate to writing and how long the posts can become this post will be the first with a new format.
Tests will still be visible in the git repository, but I will no longer explicitly call them out within the post.

## Part A: Molecules of Distinction
We're given a file containing a number of replacement pairs of molecules as well as a starting molecule with the goal of finding the number of distinct molecules after a single replacement.

> Your puzzle input describes all of the possible replacements and, at the bottom, the medicine molecule for which you need to calibrate the machine. How many distinct molecules can be created after all the different ways you can do one replacement on the medicine molecule?
>
> --- _Advent of Code, 2015, Day 19_

The first thing I need to do is parse the input file to obtain the starting molecule and all of the possible replacement pairs.
I want to be able to reference these things by name, so I will parse the file into a hash of the form `{ replacements: X, molecule: Y }`, which will also allow me to use the result as keyword arguments to methods which use the data.

{{< coderef >}}{{< var part-a-url >}}#L31{{</ coderef >}}
```
def parse_molecular_data(input)
  replacements = Hash.new { |h, k| h[k] = [] }
  *data, molecule = input.split
  data.each_slice(3) { |k, _, v| replacements[k] << v }
  { replacements: replacements, molecule: molecule }
end
```

As preparation, a `replacements` hash which supplies an empty `Array` as a default value is created, followed by a neat trick using the splat operator, `\*` to extract the molecule separately from all the replacements. 
The replacements inside of the `Array` named `data` are then iterated over in groups of three, with each group being composed of the `String` values for the key, the separating arrow `"=>"`, and the value; the arrow is ignored by the `_` parameter.
Finally, we simply return the hash format I wanted to build.

In order to determine the number of distinct molecules we can create, we need to iterate over all the possible replacements regardless of how many replacements can be done for each key and how many times the replacement can occur within the starting molecule.
This means we will have to flatten the replacements hash created previously, and will need to consider how much memory scanning the starting molecule will consume as we discover unique results.

Let's codify those iteration actions as a method named `distinct_molecules` which will take our parsed input hash and return the number of distinct molecules after checking all single replacements.

{{< coderef >}}{{< var part-a-url >}}#L47{{</ coderef >}}
```
def distinct_molecules(molecule:, replacements:)
  replacements
    .flat_map { |k, vs| [k].product(vs) }
    .flat_map { |k, v| scan_replace(molecule, k, v) }
    .uniq
    .size
end
```

The ending calls to `Enumerable#uniq` and `Enumerable#size` are simple, but the two calls to `Enumerable#flat_map` need a little further explanation for clarity.

- First, each key `k` is associated with each value in `vs` by using `Array#product` to obtain an array like `[[k, v1], [k, v1], ...]`.
- The `flat_map` call turns this into a stream of key-value pairs for all keys and their values.
- Next, the second `flat_map` applies a method we've yet to write, called `scan_replace`, to every key-value pair and also flattens those results into a single dimension array.

So this function handles processing the uniqueness constraint, counting those unique values, and setting up the input so that we can do an effective search and replace inside of `scan_replace`.

The `scan_replace` method is where we will need to leverage Ruby's text replacement facilities, like regular expressions, and the `Enumerator` class to avoid the up-front creation of a large amount of data.

{{< coderef >}}{{< var part-a-url >}}#L38{{</ coderef >}}
```
def scan_replace(str, pattern, replacement)
  str.to_enum(:scan, pattern).map do
    a, b = Regexp.last_match.offset(0)
    s = str.dup
    s[a...b] = replacement
    s
  end
end
```

The first line of this method is something we haven't seen yet: a call to `to_enum` with a keyword representing a method and its arguments.
This is a convenience method to create an `Enumerator` out of an object's method, so we are creating it based on a call to `str.scan` using `pattern` as the regular expression.
Recall from above that we call this method using `scan_replace(molecule, k, v)`, so the created enumerator is based on `molecule.to_enum(:scan, k)`.

The `String#scan` method returns an array of matches for the given pattern, so we iterate over every match and do the replacement by obtaining the beginning and ending positions of each match.
We can do this thanks to the created `Enumerator` since it does not process all of the data at once, but only when we request the next value.

All that's left to do is wire up these parts.

{{< coderef >}}{{< var part-a-url >}}#L55{{</ coderef >}}
```
def solve_a(input)
  distinct_molecules(parse_molecular_data(input))
end
```

We're now ready to run the solution to get our answer.

```
$ run -y 2015 -q 19 -a
518
```

## Part B: Make Me a Molecule Worthy of Mordor
The second part of this challenge is trickier and requires actually building toward the result molecule from the starting molecule `e`.

> Molecule fabrication always begins with just a single electron, e, and applying replacements one at a time, just like the ones during calibration.
>
> ...
>
> How long will it take to make the medicine? Given the available replacements and the medicine molecule in your puzzle input, what is the fewest number of steps to go from e to the medicine molecule?
>
> --- _Advent of Code, 2015, Day 19_

I don't want to build from `e`, rather I want to go from my result molecule backward to `e` so that the molecule string gets shorter as we progress.
This means we'll need to do some post-processing on our parsed input and require a different algorithm to solve the problem.

Since I want to go in the opposite direction, we'll need to flip the replacements hash created by the `parse_molecular_data` method.

{{< coderef >}}{{< var part-b-url >}}#L63{{</ coderef >}}
```
def flip(molecule:, replacements:)
  r = replacements.flat_map { |k, vs| vs.product([k]) }.to_h
  { replacements: r, molecule: molecule }
end
```

Using the same strategy from Part A we can flip all of the key-value pairings into a new hash instance in a single line.[^1]

Next we need to find the minimum number of steps required to go from `e` to the input molecule, but remember, we're going backward.
Now for a leap of faith: replacing the longest match each iteration will yield the fastest reduction to a length of 1, so I will assume that is the optimal solution at each stage and write a short greedy algorithm.
Fingers crossed.

{{< coderef >}}{{< var part-b-url >}}#L68{{</ coderef >}}
```
def min_steps(target:, molecule:, replacements:)
  re = replacements.keys.sort_by { |k| -k.size }.map { |k| Regexp.new(k) }
  (0..).each do |i|
    return i if molecule == target

    molecule.sub!(re.each.lazy.filter { |r| molecule[r] }.first, replacements)
  end
end
```

The first step is to sort the keys by length into descending order and convert them all to regular expression objects to use later for easy matching.
Next is the loop to control the number of replacements made and to return that number when the target is found.
Finally, the actual replacement via our leap of faith: a mutating substitution via `String#sub!` which uses the first, and longest, key found to replace part of the molecule; the `molecule[r]` expression uses `String#[]` with a regular expression argument to check if the regular expression matches.

Each iteration the molecule is compressed further and further until, hopefully, it matches the target.
Let's wire it up to see if it fails.

{{< coderef >}}{{< var part-b-url >}}#L81{{</ coderef >}}
```
def solve_b(input)
  min_steps(target: 'e', **flip(parse_molecular_data(input)))
end
```

The leap of faith worked, and we get the right answer!

```
$ run -y 2015 -q 19 -b
200
```

## A Mole of Fun
This challenge wasn't too difficult, although the greedy algorithm was a guess on my part.
It does highlight that Ruby has a robust standard library around arrays, enumerators, and strings, which is exactly what you want for most business-oriented glue code.

Programming in Ruby is still very fun for me compared to many of the languages I have to use professionally.
I hope that dropping the tests from the format lets me write more about it in the future, because it's a wonderful language that doesn't get nearly enough use.

[^1]: This is only valid because there are no duplicate values within the input.
