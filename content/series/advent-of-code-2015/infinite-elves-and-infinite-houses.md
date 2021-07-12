---
title: "Advent of Code 2015: Infinite Elves and Infinite Houses"
date: "2021-07-12T02:30:46Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/d7443f09e27d2110f161e799cfbf3f3ab2fb5a54/2015/20/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/9f70e53bf06919ce3366137d8f0ef07ff70bb256/2015/20/solution.rb
---

In the [twentieth Advent of Code challenge](https://adventofcode.com/2015/day/20) there is a journey into some simple mathematics.
Using knowledge of multiplication and factors we can arrive at a simple solution to the problems at hand.

## Part A: Presents Straight to Your Door
The problem begins by laying out how the elves deliver presents and from this you can see that each elf is responsible for its own multiples.

> To keep the Elves busy, Santa has them deliver some presents by hand, door-to-door. He sends them down a street with infinite houses numbered sequentially: 1, 2, 3, 4, 5, and so on.
>
> Each Elf is assigned a number, too, and delivers presents to houses based on that number:
>
> - The first Elf (number 1) delivers presents to every house: 1, 2, 3, 4, 5, ....
> - The second Elf (number 2) delivers presents to every second house: 2, 4, 6, 8, 10, ....
> - Elf number 3 delivers presents to every third house: 3, 6, 9, 12, 15, ....
>
> There are infinitely many Elves, numbered starting with 1. Each Elf delivers presents equal to ten times his or her number at each house.
>
> ...
>
> What is the lowest house number of the house to get at least as many presents as the number in your puzzle input?
>
> --- _Advent of Code, 2015, Day 20_

It's important to note that each elf delivers 10 times its number of presents at each house and that we're trying to find the house that gets at least as many presents as the puzzle input because this will be the first optimization added to the solution.
With each elf delivering 10 times the number of presents to each house visited we can divide the input by 10 instead of multiplying the elf numbers repeatedly.
To see why this works, think back to algebra courses where you worked with inequalities like _x + 1 >= 3_.
This same approach can be used here.

```
10 * A + 10 * B + ... >= INPUT
10 * (A + B + ...) >= INPUT
A + B + ... >= INPUT / 10
```

With this in mind we can begin to build out the solution method using an infinite `Range#each` call to find the house number that equals or exceeds the input.
The house numbers will have their factors calculated because those factors indicate which elves visit; this is the reverse of the challenge question which showed elves and their multiples.

{{< coderef >}}{{< var part-a-url >}}#L36{{</ coderef >}}
```
def solve_a(input)
  target = input / 10
  (1..).each do |house|
    return house if target < factors(house).sum
  end
end
```

The last thing that needs to be done is to create the `factors` method to find the factors of a given number.
This can consume large amounts of time if you do not know how to calculate factors reasonably quickly.
The biggest trick to reducing computation time for calculating factors is to realize that you only need to check until the square root of the number.
Numbers larger than the square root which are also a factor will be paired up with a number smaller than the square root: for example, _sqrt(10) ~= 3.16_ but 5 is a factor of 10 which is paired with 2.

{{< coderef >}}{{< var part-a-url >}}#L25{{</ coderef >}}
```
def factors(n)
  fs = [1, n]
  (2..Math.sqrt(n)).each do |i|
    next if n % i != 0

    fs << i
    fs << n / i
  end
  fs.uniq
end
```

The rest of the method is rather simple and computes the pairs of factors in the same iteration.
Of note is that I've chosen to call `Array#uniq` at the end instead of checking the parameter `n` for values of 1 and 2 to avoid duplicates.

Let's run the code and see the answer.

```
$ run -y 2015 -q 20 -a
665280
```

## Part B: There Will Be Fewer Presents This Year
The second part changes things around a bit with the elves delivering 11 times the presents to a maximum of 50 houses.

> The Elves decide they don't want to visit an infinite number of houses. Instead, each Elf will stop after delivering presents to 50 houses. To make up for it, they decide to deliver presents equal to eleven times their number at each house.
>
> With these changes, what is the new lowest house number of the house to get at least as many presents as the number in your puzzle input?
>
> --- _Advent of Code, 2015, Day 20_

This changes our math a little bit; we can divide the input number by 11 this time instead of 10 and we will need to make sure the factors paired with numbers below or equal to 50 are used in the sum.
The reason for this again rooted in the elf numbers: if the elf number needs to be multiplied by 51 or greater to equal the house number, then it is the 51st house or greater.
If you picture a multiplication table, this one cuts off aggressively at 50.

Our solution is very similar to the prior part, with changes in only 3 places.

{{< coderef >}}{{< var part-b-url >}}#L43{{</ coderef >}}
```
def solve_b(input)
  target = input / 11
  (665_281..).each do |house|
    return house if target < factors(house).filter { |f| house / f <= 50 }.sum
  end
end
```

There are the changes we just discussed to divide by 11 and to filter the elf number out should it be too large, and there is also an oddity in the `Range#each` loop.
Since we're only taking the 50 closest factors to the house number, I've started at the previous solution to avoid repeating work which will not yield a correct answer.

Now we can run part be and see the solution.

```
$ run -y 2015 -q 20 -b
705600
```

## Mathematics Can Save Time
This challenge could be rather difficult if you do not recognize that factors can be used to build the solution and I think this highlights an important consequence of the industry.
People can find mathematics easy to shrug off with large portions of software development rarely explicitly needing it, yet here a solution was simple to implement and extend through mathematics.

It might be worthwhile to refresh my memory on mathematics I haven't touched since university.
