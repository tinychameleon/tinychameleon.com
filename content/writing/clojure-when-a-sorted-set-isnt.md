---
title: "When a Sorted Set Isn't"
date: "2021-12-16T02:47:38Z"
tags: [programming, clojure]
---

I thought I knew enough about Clojure to avoid datatype issues, but I was wrong.
I've learned through an hour-long debugging session that there is more to learn before I can say I know Clojure idioms.

While constructing Dijkstra's algorithm I chose to capture work items using a sorted set.
This worked well until I tried to pull a work item off the set and fell into a pit.
The algorithm's performance cratered because I assumed destructuring would maintain the datatype of a rest binding.

I realized later this is false, Clojure's destructuring mechanism converts your datatype into a `seq`.
The code for this pitfall looks innocent.

```
user=> (type (sorted-set 1 2 3))
clojure.lang.PersistentTreeSet
```

An unsurprising result, the type is `PersistentTreeSet`, yet with destructuring I can make it disappear.

```
user=> (let [[x & xs] (sorted-set 1 2 3)]
  #_=>   {:x (type x) :xs (type xs)})
{:x java.lang.Long, :xs clojure.lang.APersistentMap$KeySeq}
```

`Long` is reasonable type for `x`, but `xs` is no longer a `PersistentTreeSet`.
Now I have to work with a type, `APersistentMap$KeySeq`, with different semantics from a set.

The solution I've come to is to avoid the `seq` abstraction by manually extracting data from the set object.

```
user=> (let [s (sorted-set 1 2 3)]
  #_=>   (type (disj s (first s))))
clojure.lang.PersistentTreeSet
```

Its elegance isn't on par with destructuring, but it's no worse than mutation in other languages.