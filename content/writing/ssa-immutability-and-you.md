---
title: "SSA, Immutability, and You"
date: "2021-01-10T00:55:10Z"
tags: [programming, erlang, java, c++]
---

Building any successful software system comes with years of maintenance that outstrips the original effort of creating the system.
It's natural that many people are interested in ways to decrease this monumental effort, with functional programming techniques soaring in mind-share.
I don't think shifting semantic constructions toward functional programming is necessary in most cases to achieve large improvements to long-term maintenance efforts, in fact, I think these kinds of re-writes are negative ROI in the majority of cases.
For long-term maintenance, you can obtain huge benefits from focusing solely on immutability and single static assignment (SSA).

SSA and immutability are intertwined, but not the same thing. It is possible to have one without the other, neither, or both.
The better your language, or your discipline, supports these concepts, the easier your long-term maintenance and debugging will become.
Immutability is something most programmers understand: a data type is created in some special manner and consequently cannot be changed afterwards.
If immutability was one side of the assignment coin, SSA is the other.
While immutability focuses on value changes, SSA focuses on referential changes; enforced SSA requires that a name is given a value exactly once.

These are the possibilities for your language when looking at immutability and SSA, and I want to take a tour of these to show the differences and what is gained as you obtain them.

|            | No Immutability                | Immutability                    |
|------------|--------------------------------|---------------------------------|
| **No SSA** | mutation and re-assignment     | read-only and re-assignment     |
| **SSA**    | mutation and single-assignment | read-only and single-assignment |

## Neither Immutability Nor SSA
Without immutability and SSA you live in a world where anything can change at almost any time without informing you.
There is a lot of software that exists in this space, and it does not imply anything about the value of the software, but it does become hard to maintain large systems written in this fashion.

Imagine a piece of code written in C++, where you have some important value that needs to be passed into a sub-system, maybe it's a game engine or a network load balancer.

```
auto& important_thing = obtain_important_value();
// any number of intermediate lines
subsystem_action(important_thing);
```

Let's ignore stickier concepts like the kinds of constructors that could be called for argument passing and ownership and simply assume that the subsystem takes a constant reference.
This code seems to display immutability and SSA on the surface, but C++ does not guarantee either.
Should the sub-system receive a bad value all the intermediate lines need to be understood to determine what the value of `important_thing` is and more importantly why it was incorrect.

C++ goes a step further into long-term maintenance pain: you must understand all of the code under `subsystem_action` to guarantee what the value of `important_thing` will be after that call even though we said it is a constant reference.
Any code underneath that call could issue a `const_cast<T&>(important_thing)` and wipe away your guarantee.

For example, here is a small program that over-writes a constant reference to a simple struct; a simple example, but real systems are never this easily laid out.

```
#include <iostream>

struct Data {
    int x;
};

std::ostream& operator<<(std::ostream& out, const Data& d) {
    out << "Data{x: " << d.x << "}\n";
    return out;
}

void weep(const Data& a) {
    const_cast<Data&>(a).x = 23;
}

int main(int argc, char** argv) {
    const Data& d = Data{1};
    std::cout << d;
    weep(d);
    std::cout << d;
    return 0;
}
```

Running it quickly yields this depressing output.

```
$ g++ -std=c++17 test.cpp && ./a.out
Data{x: 1}
Data{x: 23}
```

In C++ you need to understand all code to determine what anything does; this makes it harder to prevent bugs and increases long-term maintenance effort.

## Either Immutability Or SSA
The next step toward easier long-term maintenance and higher quality software is to introduce immutability or SSA to data type instantiations.
Ensuring changes cannot happen to values or names allows many lines of code to be skipped when attempting to track down a problem.

An easy way to demonstrate these features in isolation is to look at objects used within a class.
C# provides a simple mechanism to obtain read only collections, so to achieve immutability for a collection field one could do something like this:

```
class Thing
{
    public IReadOnlyList<int> Data { get; private set; }

    Thing() {
        Data = new List<int>{1, 2, 3}.AsReadOnly();
    }

    void ChangeIt() {
        Data = new List<int>{4, 5, 6}.AsReadOnly();
    }
}
```

No class methods or external code would be able to mutate the list, however, the class itself can still re-assign to the backing field of the `Data` property, so this is immutability without SSA.

It is also possible to do the opposite, having SSA without immutability:

```
class Thing
{
    public IList<int> Data { get; }

    Thing() {
        Data = new List<int>{1, 2, 3}.AsReadOnly();
    }

    void ChangeIt() {
        Data.Add(4);
    }
}
```

You can combine both to achieve immutability and SSA by using the `IReadOnlyList<int>` type in the previous example.
Each of these allows you to avoid looking for specific kinds of code when tracking down bugs.
In C#, immutability lets you avoid looking at method calls, and SSA lets you avoid looking for assignments, and when you have both, they let you avoid looking at everything.

## Both Immutability and SSA
We're going to look at Erlang for code with both properties, because up until this point I have used static languages, and I do not want you to think that immutability and SSA are only available to static languages.

Erlang is a dynamic, functional language which supports immutability and SSA directly.
There is no way to re-assign[^1] to a name, and you cannot change the value a name refers to once it is assigned, which sounds restricting, but allows for a great debugging experience.

Let's re-write the original C++ example in Erlang.

```
ImportantThing = obtain_important_value(),
%% any number of intermediate lines,
subsystem_action(ImportantThing).
```

Remember that in C++, we needed to understand every line to know precisely what the value of `ImportantThing` would be after the sub-system call.
In a language that supports immutability and SSA directly we can immediately say that `ImportantThing` is exactly what the `obtain_important_value()` function returned to us because the name `ImportantThing` cannot change after being assigned and the value `ImportantThing` has cannot itself change.

If the value is incorrect, it must come from the `obtain_important_value()` function, and we can skip over all of the intervening lines.
It doesn't matter if `ImportantThing` is used on 500 lines between the assignment and the sub-system call; you always go directly to the single location the name can be given a value.

## Long-Term Software Maintenance
The ability to reason about data-flow within software is greatly improved when you have immutability and SSA because every data error becomes a local reasoning problem.
No longer do you need to understand what every line of code between the first assignment and the point of error.

The best part about these concepts is that you don't need to initiate a large-scale re-write of your software to gain the benefits.
Immutability and SSA can be slowly added into existing systems in an incremental way to reduce risk and ensure improvements can fit into any road-map.

[^1]: Erlang technically does not have assignment. You "bind" values to names in Erlang via pattern matching, but for clarity and consistency I refer to it as assignment.
