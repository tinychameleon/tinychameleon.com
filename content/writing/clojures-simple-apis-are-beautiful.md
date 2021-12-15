---
title: "Clojure's Simple APIs are Beautiful"
date: 2021-12-14T17:35:13-08:00
tags: [programming, clojure]
---

Over the last couple weeks, I've re-discovered Clojure because I felt the itch to try some functional programming.
I've encountered to Clojure's immutable data-structures and a bit of its standard library during this time.
What strikes me as part of the language's true beauty is the cohesion within individual functions.

Take the [zip function](https://docs.python.org/3/library/functions.html#zip) from Python as an example.
It does it's job and does it well.
I went looking for `zip` in Clojure and faced disappointment.
There is no `zip` function.
"How can there be no zip?", I wondered.
Of course I can implement `zip`, so I did.

```
(defn zip
  [& colls]
  (let [items (map first colls)]
    (if (some nil? items)
      nil
      (lazy-seq (cons (into [] items) (apply zip (map rest colls)))))))

(zip [1 2 3] [:a :b :c :d] [\A \B])
;; => ([1 :a \A] [2 :b \B])
```

Days later I realized Clojure provides `zip`, in a way I did not expect, through `map`.
The `map` API supports providing more than one collection, so `zip` is a `map` with a container creation function.

```
(map vector [1 2 3] [:a :b :c :d] [\A \B])
;; => ([1 :a \A] [2 :b \B])
```

This is beautiful.
This is a cohesive API.
Extending `map` to support multiple collections makes so much sense.
It's more general and still has one purpose.