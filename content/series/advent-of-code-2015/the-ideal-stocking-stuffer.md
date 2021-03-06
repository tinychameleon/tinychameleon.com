---
title: "Advent of Code 2015: The Ideal Stocking Stuffer"
date: "2020-03-13T15:28:25Z"
tags: [advent-of-code, ruby]
part-a-url: "https://github.com/tinychameleon/advent-of-code-2015/blob/c4c7dd872f847b163daa1f45291cc73ed6497e42/2015/4/solution.rb"
part-b-url: "https://github.com/tinychameleon/advent-of-code-2015/blob/0fc0e3b48899df2f5c7feba7c026d7cd04040a37/2015/4/solution.rb"
---

The fourth Advent of Code [challenge](https://adventofcode.com/2015/day/4) is a simple one based around repeated hashing of an input to find a prefix match.
It might not be the most complicated puzzle, but it's a good opportunity for me to learn a bit about what kinds of hashing functionality ships in Ruby's standard library.

## Part A: To The Moon
Let's look at the problem statement to see precisely what is necessary.

> Santa needs help mining some AdventCoins (very similar to bitcoins) to use as gifts for all the economically forward-thinking little girls and boys.
>
> To do this, he needs to find MD5 hashes which, in hexadecimal, start with at least five zeroes. The input to the MD5 hash is some secret key (your puzzle input, given below) followed by a number in decimal. To mine AdventCoins, you must find Santa the lowest positive number (no leading zeroes: 1, 2, 3, ...) that produces such a hash.
>
> --- _Advent of Code, 2015, Day 4_

I think the easiest solution for this challenge is going to be a simple loop repeating the digest calculation; it should be a small amount of code.
Still, I want to list out the important information in this description to aid the implementation:

- Use MD5 to calculate hexadecimal digests
- Concatenate the puzzle input with a positive integers
- The smallest integer where the hex digest begins with 5 zeroes is the solution

{{< coderef >}}{{< var part-a-url >}}#L6{{</ coderef >}}
```
assert solve('abcdef'), 609_043
```

I've decided that I may be able to get away with eliminating the part A and B distinctions for the solve methods in this question, and I've written a singular `solve` method test based on the given challenge example.
The API is simple: provide a secret and get back the smallest positive integer which leads to a digest beginning with 5 zeroes.
The implemenation is also simple, consisting of a single loop and some minor supporting functionality for matching the prefix.

{{< coderef >}}{{< var part-a-url >}}#L22{{</ coderef >}}
```
def solve(input)
  prefix = '0' * 5
  (1..).each do |i|
    hex = Digest::MD5.hexdigest "#{input}#{i}"
    return i if hex.start_with? prefix
  end
end
```

Ruby has allowed me to do something particularly interesting here due to the nature of block scopes; a block in this case is the `do ... end` bit following `each`.
Though the `each` method is responsible for running the given block on every iteration, the `return` call is capable of exiting the block's enclosing scope.
This means the block can cause the `solve` method to exit by returning a value without any additional coordination between the generic `each` method and my code!
I think this is a really intriguing Ruby feature -- blocks take parameters like functions and can be stored in variables, yet they can also act as if they execute within their caller's scope.

With that blocking[^1] work out of the way, the first part of this challenge is solved.

```
$ run -y 2015 -q 4 -a
254575
```

## Part B: To The Moon, And Beyond
The second part ups the ante by requesting the same thing, but find the first positive integer that yields a digest starting with 6 zeroes.

> Now find one that starts with six zeroes.
>
> --- _Advent of Code, 2015, Day 4_

I've modified the tests to display an improved version of the `solve` API which provides enough flexibility for it to solve both challenge parts; I've also added a second, more computationally expensive test.

{{< coderef >}}{{< var part-b-url >}}#L6{{</ coderef >}}
```
assert solve('abcdef', zeroes: 5), 609_043
assert solve('pqrstuv', zeroes: 5), 1_048_970
```

This is going to be a very easy change to make to the `solve` method because I am only replacing the originally hard-coded `5` value with a parameter.
These situations are always a great feeling, since it shows the original strategy is malleable enough to avoid major redesign work.

{{< coderef >}}{{< var part-b-url >}}#L23{{</ coderef >}}
```
def solve(input, zeroes:)
  prefix = '0' * zeroes
  (1..).each do |i|
    hex = Digest::MD5.hexdigest "#{input}#{i}"
    return i if hex.start_with? prefix
  end
end
```

The only two lines that change are the first two -- adding the new parameter and using it to generate the prefix I need to match against.
Now let's get the answer to part B.

```
$ run -y 2015 -q 4 -b
1038736
```

## No Rollercoasters Here
This challenge was pretty straightforward, lacking many of the ups and downs of some cryptocurrencies.
Even with the overall simplicity of this challenge a couple positive learning experiences came out of it.
The standard library digest methods in Ruby are pleasant to use and require almost no set-up, and learning a bit more about how blocks work is a wonderful bonus.

[^1]: I'm not sorry for this pun.
