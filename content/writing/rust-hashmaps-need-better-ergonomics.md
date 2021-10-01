---
title: "Rust Hash-Maps Need Better Ergonomics"
date: "2021-10-01T04:35:46Z"
tags: [rust]
gist-url: https://gist.github.com/tinychameleon/b5ab8158c5eb094205b40c9d37b3b4e3
---

I'm making my way through [The Rust Programming Language](https://doc.rust-lang.org/book/) and I find that my largest annoyance coming from other languages is the syntax for constructing an instance of `HashMap<K, V>`.
What I feel should be a simple syntax, considering the prevalence of hash-map usage, is mired in boilerplate.

There are a few ways of constructing a `HashMap<K, V>` prior to the 1.56-beta, but I don't particularly like any of them.

{{< coderef >}}{{< var gist-url >}}#file-hashmap_macro-rs-L19{{</ coderef >}}
```
// Mutable to insert, but m1 is mutable in this scope now.
let mut m1 = HashMap::new();
m1.insert("one", 1);
m1.insert("two", 2);

// Immutable using a nested block. Kinda ugly.
let m2 = {
    let mut m = HashMap::new();
    m.insert("one", 1);
    m.insert("two", 2);
    m
};

// Can be collected from an iterator. Also ugly, especially with the type
// annotation using _.
let m3: HashMap<_, _> = [
    ("one", 1),
    ("two", 2),
].iter().cloned().collect();
```

Things are a little better in 1.56-beta with the `From` trait implementation, but this still requires an array of tuples to be created, regardless of whether or not they are optimized away.

{{< coderef >}}{{< var gist-url >}}#file-hashmap_macro-rs-L39{{</ coderef >}}
```
// In the 1.56 beta there is From support.
let m4 = HashMap::from([
    ("one", 1),
    ("two", 2),
]);
```

I'd really prefer something similar to `vec!`, ideally with emphasis on ergonomics and legibility as I don't really consider Rust's syntax to be the easiest to read at a glance.
Something like this:

{{< coderef >}}{{< var gist-url >}}#file-hashmap_macro-rs-L45{{</ coderef >}}
```
// A macro like "vec!". No array or tuples. Abstracts inserts in block.
let m5 = hashmap![
    "one" => 1,
    "two" => 2,
];

// Also looks better on 1 line.
let m6 = hashmap!["one" => 1, "two" => 2];
```

The following macro, hopefully better prepared for production than my quick write-up, within the standard library would go a long way to fixing my annoyance.

{{< coderef >}}{{< var gist-url >}}#file-hashmap_macro-rs-L3{{</ coderef >}}
```
macro_rules! hashmap {
  () => (
    HashMap::new();
  );
  ( $( $k:expr => $v:expr ),+ $(,)? ) => (
    {
      let mut temp_map = HashMap::new();
      $(
        temp_map.insert($k, $v);
      )*
      temp_map
    }
  );
}
```

I do think that the absence of a macro like `hashmap!` highlights that the language has not been focused on ergonomics.
Common things should be trivial to express and I shouldn't need to create explicit nested blocks, expose a mutable value to a larger scope, or construct arrays of tuples in order to build common data structures.
