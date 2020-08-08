---
title: "Advent of Code 2015: JSAbacusFramework.io"
date: "2020-07-03T01:34:51Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/d90a5d74f87798a1837a28741f6b57d1768c5d15/2015/12/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/5ef9a32c753a6d4de8aa440f36e5c38f33c73057/2015/12/solution.rb
---

The [twelfth Advent of Code challenge](https://adventofcode.com/2015/day/12) focuses on how to navigate an object structure containing different types.
Many times these kinds of problems can be solved using [Tagged Unions](https://en.wikipedia.org/wiki/Tagged_union) by viewing each potential element of the structure as a particular type.

## Part A: Sum All The Things
The much larger problem here is that Santa's elves seem to haphazardly store financial data, but thankfully, we're only asked to figure out a sum of numbers and not to fix the North Pole accounting department.

> They have a JSON document which contains a variety of things: arrays, objects, numbers, and strings. Your first job is to simply find all of the numbers throughout the document and add them together. For example:
>
> - [1,2,3] and {"a":2,"b":4} both have a sum of 6.
> - [[[3]]] and {"a":{"b":4},"c":-1} both have a sum of 3.
> - {"a":[-1,1]} and [-1,{"a":1}] both have a sum of 0.
> - [] and {} both have a sum of 0.
>
> You will not encounter any strings containing numbers.
>
> What is the sum of all numbers in the document?
>
> --- _Advent of Code, 2015, Day 12_

From the description, it looks like we need to ensure that every number we encounter in the JSON document, no matter where it appears or how deeply it is nested, is included in our final sum.
Importantly, there won't be any numbers hiding in strings, so we only need to focus on finding number types.
I am taking an educated guess here that all numbers will be integers, since that would avoid language-based floating-point rounding errors.

With those requirements, like always, we begin with some tests, but we're only going to need to exercise a single method this time, `sum`:

{{< coderef >}}{{< var part-a-url >}}#L5{{</ coderef >}}
```
def tests
  assert sum([1, 2, 3]), 6
  assert sum({ "a": 2, "b": 4 }), 6
  assert sum([[[3]]]), 3
  assert sum({ "a": { "b": 4 }, "c": -1 }), 3
  assert sum({ "a": [-1, 1] }), 0
  assert sum([-1, { "a": 1 }]), 0
  assert sum([]), 0
  assert sum({}), 0
  :ok
end
```

Numbers can appear at any depth in these JSON objects, so let's enumerate possible situations for each JSON value we can encounter:

- The current value is an integer, so we add it to the sum.
- The current value is an array, so we try to call `sum` on each element.
- The current value is an object, so we try to call `sum` on each value.
- The current value is anything else, so we add zero to the sum.

Why do we try to call `sum` on the elements of an array or the values of an object?
Each of those elements or values could themselves be arrays or objects, so we want to make sure we're applying our zero-or-integer-value addition operation to any possible depth.

Since the JSON object is already reified as instantiated Ruby classes, we can treat each type as a tag in a tagged union, and the `sum` function reduces in complexity to a single `case` expression over a handful of those types.

{{< coderef >}}{{< var part-a-url >}}#L27{{</ coderef >}}
```
def sum(obj)
  case obj
  when Integer
    obj
  when Array
    obj.map { |v| sum(v) }.sum
  when Hash
    obj.values.map { |v| sum(v) }.sum
  else
    0
  end
end
```

We apply some simple map operations to the array or object representations, here `Array` and `Hash` as Ruby data structures, and otherwise we return the integer or zero.
All addition happens via the `.sum` calls when there is an `Array` or a `Hash`, because without either of those types the integer values have nowhere to be defined in JSON.

The set-up for calling our `sum` method is simple, we parse the input as JSON and provide it as the parameter:

{{< coderef >}}{{< var part-a-url >}}#L40{{</ coderef >}}
```
def solve_a(input)
  sum(JSON.parse(input))
end
```

Now lets find out what the answer is:

```
$ run -y 2015 -q 12 -a
119433
```

## Part B: Avoiding the Red
Now there is an additional check we need to make to ensure that we get the right answer: excluding any object that has a property with the value `"red"`.

> Uh oh - the Accounting-Elves have realized that they double-counted everything red.
>
> Ignore any object (and all of its children) which has any property with the value "red". Do this only for objects ({...}), not arrays ([...]).
>
> - [1,2,3] still has a sum of 6.
> - [1,{"c":"red","b":2},3] now has a sum of 4, because the middle object is ignored.
> - {"d":"red","e":[1,2,3,4],"f":5} now has a sum of 0, because the entire structure is ignored.
> - [1,"red",5] has a sum of 6, because "red" in an array has no effect.
>
> --- _Advent of Code, 2015, Day 12_

We already are parsing the input as JSON from the first part of this challenge, so there's not much to do other than add a bit of conditional logic.
Ruby has first-class functions, so let's parametrize the `sum` method with something that can have a default which works for Part A.

{{< coderef >}}{{< var part-b-url >}}#L27{{</ coderef >}}
```
def sum(obj, cond: ->(_) { false })
  case obj
  when Integer
    obj
  when Array
    obj.map { |v| sum(v, cond: cond) }.sum
  when Hash
    return 0 if cond.call(obj)
    obj.map { |_k, v| sum(v, cond: cond) }.sum
  else
    0
  end
end
```

The `cond: ->(_) { false }` keyword parameter creates an anonymous function that always returns `false`, and we will use it to determine if an object should be **excluded**.
If we're dealing with a `Hash` object, and the `cond` function returns `true`, we add zero instead of looking at its values to successfully exclude it and all of its children.

The remaining task is to pass in an anonymous function which correctly identifies objects with properties that have the value `"red"`.
For this we can use the `Hash#any?` method, which applies a block to each key-value pair of the hash and returns `true` if any of blocks return `true`.

{{< coderef >}}{{< var part-b-url >}}#L46{{</ coderef >}}
```
def solve_b(input)
  sum(JSON.parse(input), cond: ->(h) { h.any? { |_k, v| v == 'red' } })
end
```

The `h.any? { |_k, v| v == 'red' }` expression achieves this nicely, since we can encode the requirement in a fairly succinct manner.
Now, without any "red" objects our answer is:

```
$ run -y 2015 -q 12 -b
68466
```

## Short & Sweet
This challenge was pretty short, but it does provide a nice opportunity to learn about, or practice using, Tagged Unions.
Not every challenge needs to be incredibly difficult, and this one was fun regardless of length.
