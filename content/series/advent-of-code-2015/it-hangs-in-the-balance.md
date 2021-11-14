---
title: "Advent of Code 2015: It Hangs in the Balance"
date: "2021-11-14T05:31:35Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/1acf4abb93d652d12f007130e22a747a2d741a27/2015/24/solution.rb
---

The [twenty-fourth Advent of Code challenge](https://adventofcode.com/2015/day/24) involves optimizing data groupings based on a set of conditions.
Ruby makes implementing the backtracking functionality necessary for this solution terse and legible.

## Part A: Equal Weight Distribution

The prose is long, so I've cut out the majority to focus on the parts that define the problem to solve.

> Santa has provided you a list of the weights of every package he needs to fit on the sleigh. The packages need to be split into three groups of exactly the same weight, and every package has to fit.
>
> ...
>
> Furthermore, Santa tells you, if there are multiple ways to arrange the packages such that the fewest possible are in the first group, you need to choose the way where the first group has the smallest quantum entanglement to reduce the chance of any "complications". The quantum entanglement of a group of packages is the product of their weights, that is, the value you get when you multiply their weights together. Only consider quantum entanglement if the first group has the fewest possible number of packages in it and all groups weigh the same amount.
>
> What is the quantum entanglement of the first group of packages in the ideal configuration?
>
> --- _Advent of Code, 2015, Day 24_

We're given a list of weights for each package and need to partition them into three groups of equal total weight.
Of those groups we must find the smallest quantum entanglement value of the smallest group.

To start with something easy, let's build a function to read the package weights into an array of `Integer` values.

{{< coderef >}}{{< var part-a-url >}}#L37{{</ coderef >}}
```
def read_package_weights(input)
  input.lines.map(&:to_i)
end
```

To solve for the quantum entanglement values of the three groups I want to write a recursive method.
This method should take an array of package weights and the number of groups to split the array into.
It will look something like this.

```
def entanglement(arr, num_groups)
  return base_case
  calculate_entanglement_for_subset_of_array
  recurse_on_remaining_array_and_one_less_group
end
```

For the base case, when `num_groups == 1`, we can return the quantum entanglement of the `arr` value wrapped in an array to maintain a consistent data type across all values of `num_groups`.
Why an array?
We need to retrieve the first value of a group of three, and the first value will be the smallest.

```
def entanglement(arr, num_groups)
  return [arr.mul] if num_groups == 1

  calculate_entanglement_for_subset_of_array
  recurse_on_remaining_array_and_one_less_group
end
```

With the base case done, we can create the `arr.mul` method by opening up the `Array` class[^1].

{{< coderef >}}{{< var part-a-url >}}#L3{{</ coderef >}}
```
class Array
  def mul
    reduce(1, &:*)
  end
end
```

The next step is to determine the way to recurse.
We want to step through possible first groups from smallest to largest and to do that we need to be able to create groups of the same total package weights.
Calculating the combinations of package weights in a group with a target total weight is a task for `Array#combination` and `Array#sum`.

{{< coderef >}}{{< var part-a-url >}}{{</ coderef >}}
```
class Array
  def combinations_with_sum(size, sum)
    combination(size).lazy.filter { |c| c.sum == sum }
  end
end
```

Given a particular group size and the sum the group must equal we can apply a filter to each set of combinations.
Since this can potentially be a large list of combinations a lazy `Enumerable` protects against high volumes of memory use.

We can now find all possible groups with a particular size, but the `entanglement` method will need to determine what size to supply.

```
def entanglement(arr, num_groups)
  return [arr.mul] if num_groups == 1

  target = arr.sum / num_groups
  maximum = arr.size / num_groups - 1
  (1..maximum).lazy.flat_map do |size|
    arr.combinations_with_sum(size, target)
    ...
  end
end
```

Calculating the target weight is simple: if you have _N_ groups that must be equal weight, the target weight is the total weight of all packages divided by _N_.
The size is subtle as it relates to the number of groups: with _N_ groups, the smallest group must have fewer packages than if packages were spread across groups in equal amount.

Next to figure out how to recurse into smaller group numbers we need to figure out how to remove combinations with the correct weight that do not have equal weights of other groups.

```
def entanglement(arr, num_groups)
  return [arr.mul] if num_groups == 1

  target = arr.sum / num_groups
  maximum = arr.size / num_groups - 1
  (1..maximum).lazy.flat_map do |size|
    arr.combinations_with_sum(size, target)
	   .reject { |c| entanglement(arr - c, num_groups - 1).first.nil? }
       .map(&:mul)
  end
end
```

To recurse we want to remove the combination of packages with the given weight from the array and to use one less number of groups.
Essentially, we want to find the quantum entanglement of the remaining packages and groups.

If those remaining groups cannot satisfy the weight requirement then there will be no combinations returned from the `Array#combinations_with_sum` method we created.
When this happens, the resulting `Enumerable` will be empty, but lazy `Enumerable` objects do not have an `empty?` method.
Using the `.first.nil?` method chain works to resolve this issue.

By doing this in order from a size of 1 to the `maximum` we remove combinations from smallest to largest ensuring that we get a group of the smallest possible size.
Calculating the quantum entanglement of that group gives us the answer.

{{< coderef >}}{{< var part-a-url >}}{{</ coderef >}}
```
def solve_a(input)
  entanglement(read_package_weights(input), 3).first
end
```

By taking the first entry of the lazy enumerable we stop after finding the smallest possible grouping that passes the requirements.

```
$ run -y 2015 -q 24 -a
11266889531
```

## Part B: Fill the Trunk

As it turns out, making the number of groups a parameter of the `entanglement` method was a good idea.

> Balance the sleigh again, but this time, separate the packages into four groups instead of three. The other constraints still apply.
>
> --- _Advent of Code, 2015, Day 24_

There's no work to do for this part, a minor change to the solution method is necessary.

```
def solve_b(input)
  entanglement(read_package_weights(input), 4).first
end
```

Running the solution we get the answer.

```
$ run -y 2015 -q 24 -b
77387711
```

## Backtracking is Handy

Being able to create algorithms that can backtrack is important to solving a wide range of problems.
Iterating toward a solution, stopping once deemed incorrect, and starting again with previous state can be confusing to understand at first, but it's a valuable strategy to master.

[^1]: Generally, adding methods to the standard library classes is not recommended, since there is a chance they will collide with future additions. There's no harm in these small challenges.
