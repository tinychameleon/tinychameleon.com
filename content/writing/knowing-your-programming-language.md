---
title: "Knowing Your Programming Language"
date: "2020-10-17T20:54:12Z"
tags: [programming, python, c++]
---

The tech industry has a large number of people from varying backgrounds working together to create great products and wonderful tools.
We've got a diverse set of education facilities from MOOCs to boot-camps to university programmes.
These options are fantastic, but tend to approach the practice of programming from different, and sometimes conflicting, perspectives.
Universities tend to focus on Computer Science theory, boot-camps focus on application of languages and frameworks, and MOOCs range a wide gamut of topics.
While I do think more Computer Science theory could be taught in more arenas, I don't think it is particularly helpful for the majority of the industry.

Computer Science theory topics, like time complexity analysis, or more esoteric data-structures, are necessary tools for building very specific infrastructure-level software.
Data stores, load balancers, and many other components rely heavily on more advanced data-structures and algorithms.
But what about the ever increasing amount of business-domain code that exists?
Is Computer Science theory useful across this kind of code?

Theory is helpful to guide you, but there is no constraint aligning it with reality and the reality is that hardware and runtime implementations almost always win.
Processor cache line speed has allowed dynamic arrays to usurp many of the places a linked list would have been effective in the past.
Garbage collection algorithms determine when all execution threads are paused, and sometimes changes how we structure code so that we avoid placing pressure on the collector.
It turns out that knowing your platform and your language matter a lot when it comes to performance, and can often supersede the theory you know. 

I want to focus on a simple example, dynamic allocation and pre-allocation of arrays, and answer the question "Which is better for a known array size?" for two languages.
We will need to dig below the syntax surface and delve into the assembly and byte-code instructions that are generated for the loops we will build.

Let's start with a fairly efficient language like C++, and using the `std::vector` class, implement pre-allocation and dynamic allocation functions which build an array from 0 to some maximum integer.[^1]

```
std::vector<int> preallocate(int max) {
    std::vector<int> v(max);
    for (int i = 0; i < max; i++)
        v[i] = i;
    return v;
}

std::vector<int> dynamic_allocate(int max) {
    std::vector<int> v;
    for (int i = 0; i < max; i++)
        v.push_back(i);
    return v;
}
```

These should be pretty legible to anyone, using classic for-loop syntax, with the only differences being how `v` is constructed and what happens in the loop body.
There is a major difference in the running time for these two pieces of code, and with the value of `max` pinned to 100,000, the `preallocate` function is approximately 13x faster when run via [Quick Bench](https://quick-bench.com/) using optimization level `-O2`.
We shouldn't assume that pre-allocation is faster because dynamic allocation requires increasing capacity as we iterate, so lets find out why by looking at the disassembly output. 

The `dynamic_allocate` assembly is quite long, but we only need to worry about understanding a high-level view of the code within the loop body.

```
.L41:
        mov     DWORD PTR [rsi], eax
        mov     eax, DWORD PTR [rsp+12]
        add     rsi, 4
        mov     QWORD PTR [r12+8], rsi
        add     eax, 1
        mov     DWORD PTR [rsp+12], eax
        cmp     eax, ebx
        jge     .L29
.L42:
        mov     rsi, QWORD PTR [r12+8]
        mov     rdx, QWORD PTR [r12+16]
.L33:
        cmp     rsi, rdx
        jne     .L41
        lea     rdx, [rsp+12]
        mov     rdi, r12
        call    void std::vector<int, std::allocator<int> >::_M_realloc_insert<int const&>(__gnu_cxx::__normal_iterator<int*, std::vector<int, std::allocator<int> > >, int const&)
        mov     eax, DWORD PTR [rsp+12]
        add     eax, 1
        mov     DWORD PTR [rsp+12], eax
        cmp     eax, ebx
        jl      .L42
```

You don't need to understand this, what is important is the label `.L33`.
This point in the code does a comparison, `cmp`, to see if the vector's underlying array is at-capacity, and if it is, it continues toward the `call` instruction which does the re-allocation.
If it is not at-capacity, the `jne .L41` instruction hops to the `.L41` label at the top.
All this code maps to the `v.push_back(i)` call in the for-loop, which deals directly with the underlying components of the `std::vector` class and the loop conditional and increment steps.
It's a decent amount of code to be executing in a loop, but because the re-allocation step does not occur often, it is still fairly quick.

Now let's look at the `preallocate` loop body assembly.

```
.L8:
        mov     DWORD PTR [rcx+rax*4], eax
        add     rax, 1
        cmp     rbx, rax
        jne     .L8
```

Only the single `mov` instruction represents the loop body of `v[i] = i`.
Without needing to worry about dynamic allocation, the implementation of subscripting is capable of being exactly as efficient as directly assigning the value of `i` to the underlying array.
For C++, following Computer Science theory tends to pay off as the code you write translates to machine code instead of some other intermediate byte-code.

Let's switch gears and look at the same functions, but in Python.
We'll use all the same constraints as the C++ code, but use more Pythonic list comprehensions instead of the `push_back` calls.

```
def preallocate(max):
	l = [None] * max
	for i in range(max):
		l[i] = i
	return l

def list_comprehension(max):
	return [i for i in range(max)]
```

It may surprise you to know that the `list_comprehension` function is about 15% faster[^2] than the `preallocate` function, which directly contradicts what we saw with C++.
In order to understand this we need to once again look at the disassembled code, and with Python we have the `dis` library for this purpose.

Let's take a peek at the byte-code for the `preallocate` function to see what happens in the loop body.

```
20 FOR_ITER                12 (to 34)
22 STORE_FAST               2 (i)
24 LOAD_FAST                2 (i)
26 LOAD_FAST                1 (l)
28 LOAD_FAST                2 (i)
30 STORE_SUBSCR
32 JUMP_ABSOLUTE           20
```

Each iteration of the loop, the value of `i` is stored into the second local variable slot, and then we load three values onto the stack to finally call the `STORE_SUBSCR` instruction.
Having to load the reference to the list `l` and the reference to the value `i` twice in order to issue the subscript assignment means our single statement of `l[i] = i` ends up taking 4 byte-code instructions.

Perhaps `list_comprehension` does something better?

```
4 FOR_ITER                 8 (to 14)
6 STORE_FAST               1 (i)
8 LOAD_FAST                1 (i)
10 LIST_APPEND              2
12 JUMP_ABSOLUTE            4
```

The loop body for `list_comprehension` only needs to store the value of `i` and then place one value onto the stack representing the value to append to the list.
Python has a special byte-code operation for appending to a list which uses the value at the top of the stack and list reference already on the stack.
The list comprehension loop gets to the `LIST_APPEND` instruction quicker than the pre-allocation loop gets to the `STORE_SUBSCR` instruction, which allows `LIST_APPEND` to spend a bit of extra time re-allocating the array and still be faster.

It's important to understand the language you're using, because the run-time can create different constraints than Computer Science theory alone considers.
Just because something appears to be more efficient does not mean it is so in reality.
In fact, the `list_comprehension` speed-up is maintained at smaller sizes too.

|     max | preallocate | list_comprehension |
|--------:|------------:|-------------------:|
|      10 |       2.9ms |              2.5ms |
|     100 |      12.5ms |              7.9ms |
|    1000 |     102.9ms |             74.4ms |
|   10000 |    1308.6ms |           1007.7ms |
|  100000 |   13143.7ms |          10942.1ms |

So make sure you understand your tools when you need to work on performance.
Know your language, your runtime, and your debugging tools, and you won't be taken by surprise when applying theory in practice.

[^1]: I am ignoring integer sign and other more subtle details for this.
[^2]: As measured by the `timeit` library using Python 3.7.7, over 2000 runs.