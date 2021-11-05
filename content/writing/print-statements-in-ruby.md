---
title: "Print Statements in Ruby"
date: "2021-11-05T03:58:10Z"
tags: [ruby]
---

A multitude of ways to print information to the screen exist in Ruby.
At 9,029,850[^1] results the most popular seems to be `puts`.
Nothing wrong with `puts` --- it's a solid way to print out strings:

```
irb(main):010:0> puts 23, 42.0, "hello", {a: 1}
23
42.0
hello
{:a=>1}
=> nil
```

Well, until you try to print an `Array`.

```
irb(main):011:0> puts 23, 42.0, "hello", {a: 1}, [1, 2, 3]
23
42.0
hello
{:a=>1}
1
2
3
=> nil
```

Why does this happen?
Thankfully Ruby comes with a built-in documentation command for methods.
It's aptly named `help`.
If we ask Ruby to tell us about `puts`...

```
irb(main):012:0> help 'puts'
=> nil
```

Nothing.
Ruby allows implicit calls to `Kernel` module procedures by your program, so we asked the wrong thing.
Trying again we get something more useful.

```
irb(main):013:0> help 'Kernel#puts'
= Kernel#puts

(from ruby core)
------------------------------------------------------------------------
  puts(obj, ...)    -> nil

------------------------------------------------------------------------

Equivalent to

  $stdout.puts(obj, ...)
```

Well, marginally more useful anyway.
At least we know it's equal to `$stdout.puts(obj, ...)` now though, but what's `$stdout`?
Let's ask!

```
irb(main):014:0> $stdout.class
=> IO
```

An instance of the `IO` class.
Now we can ask about `IO#puts`.

```
irb(main):015:0> help 'IO#puts'
= IO#puts
...
Writes the given object(s) to ios. Writes a newline after any that
do not already end with a newline sequence. Returns nil.

The stream must be opened for writing. If called with an array argument,
writes each element on a new line. Each given object that isn't a string
or array will be converted by calling its to_s method. If called without
arguments, outputs a single newline.
```

Here we are: iterate over arrays to print each element and everything else receives a `to_s` call.[^2]
These make `puts` decent for quick scripts, but not so great for print debugging.

For debugging replace `puts` with `p`.
It's shorter to type and works the same way as `puts` except it calls the `inspect` method instead of `to_s`.

```
irb(main):016:0> p 23, 42.0, "hello", {a: 1}, [1, 2, 3]
23
42.0
"hello"
{:a=>1}
[1, 2, 3]
=> [23, 42.0, "hello", {:a=>1}, [1, 2, 3]]
```

If you've got a sharp eye you'll have noticed `p` returned an array of the values it received.
It handles a single value too.

```
irb(main):017:0> help 'Kernel#p'
= Kernel#p

(from ruby core)
------------------------------------------------------------------------
  p(obj)              -> obj
  p(obj1, obj2, ...)  -> [obj, ...]
  p()                 -> nil

------------------------------------------------------------------------

For each object, directly writes obj.inspect followed by a newline
to the program's standard output.
```

Pass it a single object and it returns it after printing the representation.
Debugging the return values of method calls or expressions is as simple as placing `p` in front.

```
irb(main):018:0> n = p rand(1..100)
29
=> 29
irb(main):019:0> n + 1
=> 30
```

Superbly unobtrusive.

[^1]: Using [this search](https://github.com/search?q=puts&type=code&l=Ruby) at the time of writing.
[^2]: Neat! It also avoids writing a newline if the object's string representation ends in one. I didn't know this.
