---
title: "From Promises to Messages"
date: "2020-08-16T03:53:57Z"
tags: [programming, concurrency, csharp]
---

In a previous post, [From Callbacks to Promises]({{< ref from-callbacks-to-promises.md >}}), I discussed the positive aspects of transitioning from callbacks to `Promise` types: how they enable programming with values and provide compilers with the opportunity to transform calls to keywords like `await` into continuation-passing style.
Promises are the penultimate step on a journey to well-designed code which can take advantage of concurrent execution.
They are the building block which makes it easier to implement message-passing runtimes.

The transition to message-passing from promise-based code is concerned with one high-level goal: extracting the asynchronous concurrency mechanisms from code.
All of the remaining message-passing code is sequential and clear, but could be a smidgen longer.
To offset the verbosity increase, gains in local reasoning and unit-of-work delineation provide ample benefit to large projects. 

Before getting to the Holy Grail of concurrency mechanisms we need to divert into the mire of design problems promises cause; it's rather hard to sell you a solution without you knowing the problem it solves.
We're going to focus on C#, because it has all the components of a promise-oriented concurrency mechanism: the keywords `async` and `await`, and the `Task<T>` type to delay delivery of a value `T`.

So, why are promises bad?
For starters, they cause you to mix asynchronous and synchronous code in a single method.
Once you've accepted the mixture of semantics, you're forced to mark methods as asynchronous via some kind of syntax[^1].
You begin wrapping your domain types in things like `Task<T>` to support language syntax for passing data around in a secondary manner to normal returns.
Call-site semantics get discarded in favour of called methods dictating how code should be run.
Many of these problems overlap, and provide a large surface area for bad design.

When you accept mixing asynchronous and synchronous code you end up with sequential-looking code that isn't.
Different execution mechanisms should have sufficient contrast to their syntax, but the promise-based fail in this regard.
The `await` keyword is a reasonable marker for identifying a line of asynchronous code, but it falls short when working with that asynchronously executing code.
While the compiler transformation of `await` focuses on unwrapping data types and capturing exceptions it ignores trickier parts like cancellation.
When a time-out or state-based cancellation is required, you must manually implement it around the calls to `await`.
The sequential code is smothered by the details of asynchronous communication and the sequential-looking mask dissolves.

The rest of your synchronous code will be affected by the viral nature of asynchronous keywords.
A single method marked `async` will poison everything north of it in the call-stack and pushes irrelevant details about execution semantics from lower-level code into your higher-level APIs.
You can avoid the spread by avoiding `await` and writing continuation-passing style code against a returned promise value while delaying a method return until the promise has delivered a result --- it's not pretty and can be easy to get wrong when using locks.

These viral keywords cause programmers to practice some kind of apologetic Hungarian-notation by postfixing methods containing the viral `async` keyword with "Async".
Now the method name has joined the viral keyword in leaking execution information to the world. 

Fuelled by the propagation of viral keywords, your domain types are subsumed by the concurrency mechanism data types in what can only be considered a design catastrophe.
Types like `Task<T>` represent the concurrency mechanism first and what value is delivered second.
With your domain types relegated to generic parameters for the concurrency framework you have little recourse for changing execution semantics and all require large-scale, sweeping modifications.

As you traverse up your call-stack marking methods `async` and placing `await` within method bodies you take all autonomy of execution away from every call-site.
Choosing manual continuation-passing style code to maintain call-site semantics or the convenience of the compiler transformations is a losing game, but every programmer picks the latter because callbacks are what they fled to promises from.
The asynchronous transformation begins to jump into separate assemblies as it reaches a public API.
Tests are the first victim, requiring much marking to become asynchronous themselves.
Eventually you may wonder if it's not easier to simply mark everything as asynchronous.

Promise-based APIs seem pretty dire, but the solution is simple: message-passing.
With message-passing your domain code is always synchronous and you have no worries about anyone ever accidentally mixing in asynchronous code because you can't[^2].
You can return domain types directly and pass them around as messages.
This transformation to message-passing is what we're going to look at.

A few notes before we begin.
The message-passing library I threw together for this is incredibly rough and is missing many features you would get from a production-quality implementation.
It's missing things like robust error handling (outside of printing dispatching errors), stopping processes, supervising processes, receive time-outs, and sophisticated message reception.
It has _just enough_ functionality for pedagogical purposes.

Both systems pass data around in similar ways: promise-based code has `Task<T>` and message-passing code has the `Message` type.
These things are very similar in a superficial way since they both carry around data.
The critical difference is that `Message` does not encode any details about the mechanism of concurrency; there is no API like `ContinueWith` because it is a value-type[^3].

With promise-based code and pushed down domain types a lot of asynchronous code ends up looking similar to this example from Microsoft:

{{< coderef >}}https://github.com/tinychameleon/csharp-message-passing/blob/4b30952cb85653375af54417df3ba049de647c79/AsyncBreakfast/Program.cs#L77{{</ coderef >}}
```
private static async Task<Bacon> FryBaconAsync(int slices)
{
    Console.WriteLine($"putting {slices} slices of bacon in the pan");
    Console.WriteLine("cooking first side of bacon...");
    await Task.Delay(3000);
    for (int slice = 0; slice < slices; slice++)
    {
        Console.WriteLine("flipping a slice of bacon");
    }
    Console.WriteLine("cooking the second side of bacon...");
    await Task.Delay(3000);
    Console.WriteLine("Put bacon on plate");

    return new Bacon();
}
```

It contains all of the problems mentioned above and the spread of `async` to the `Main` method causes further problems due to a `Task` based API.

{{< coderef >}}https://github.com/tinychameleon/csharp-message-passing/blob/4b30952cb85653375af54417df3ba049de647c79/AsyncBreakfast/Program.cs#L10{{</ coderef >}}
```
static async Task Main(string[] args)
{
    ...

    var baconTask = FryBaconAsync(3);

    var breakfastTasks = new List<Task> { ..., baconTask, ... };
    while (breakfastTasks.Count > 0)
    {
        Task finishedTask = await Task.WhenAny(breakfastTasks);
        if (finishedTask == ...)
        {
            ...
        }
        else if (finishedTask == baconTask)
        {
            Console.WriteLine("bacon is ready");
        }
        else if (finishedTask == ...)
        {
            ...
        }
        breakfastTasks.Remove(finishedTask);
    }

    ...
}
```
The API based on `Task` implements C-style procedural code using reference equality to compare each individually saved `Task` against the finished one and run a specific block.
Using method overloading could improve the isolation of this code, but it can't fix the `Task` oriented nature of the design and the potential for semantic comparison errors.

The alternative is to use a process oriented design consisting of runnable work-units, inheriting from a `Runnable` class in these examples, that accomplish the individual actions.
Processes are spawned through a runtime capable of handling unit-of-work classes directly as well as wrapping things like lambdas and methods.
The best part about these unit-of-work definitions is that they can encapsulate work-state in a thread-safe manner without any locking because messages are processed in sequential order and one-at-a-time.
To handle messages, overloaded `Receive` methods are called, so there is no casting between types, code for each message is isolated, and there is no chance of semantic matching errors.

Here is an example method duplicating the `FryBaconAsync` method from above which can be spawned by the message-passing library:

{{< coderef >}}https://github.com/tinychameleon/csharp-message-passing/blob/4b30952cb85653375af54417df3ba049de647c79/MessageBreakfast/Program.cs#L126{{</ coderef >}}
```
private static BreakfastItem<Bacon> BaconFryer(int slices)
{
    Console.WriteLine($"putting {slices} slices of bacon in the pan");
    Console.WriteLine("cooking first side of bacon...");
    Thread.Sleep(3000);
    for (int slice = 0; slice < slices; slice++)
    {
        Console.WriteLine("flipping a slice of bacon");
    }
    Console.WriteLine("cooking the second side of bacon...");
    Thread.Sleep(3000);
    Console.WriteLine("Put bacon on plate");

    return new BreakfastItem<Bacon>(new Bacon());
}
```

You should notice that it looks very similar, but it's not marked using `async` and returns a message type called `BreakfastItem<T>` which is used to communicate with a cook process shown later.
The calls to `Thread.Sleep` are simply because I was too lazy to implement a process-based sleep method and can be ignored for our purposes.

{{< coderef >}}https://github.com/tinychameleon/csharp-message-passing/blob/4b30952cb85653375af54417df3ba049de647c79/MessageBreakfast/Program.cs#L8{{</ coderef >}}
```
class BreakfastItem<T> : Message
{
    public T Item { get; }
    public BreakfastItem(T item) => Item = item;
}
```

This generic message type is used to communicate with the cook to provide that process with every completed breakfast item.
In a production-quality system, `Message` would most likely be an interface so that you could directly pass your domain types around, but for this I want to highlight that the message types you make can be their own distinct objects.

The spawning process is simple, taking a process ID for the cook and sending it the return value of the second argument.

{{< coderef >}}https://github.com/tinychameleon/csharp-message-passing/blob/4b30952cb85653375af54417df3ba049de647c79/MessageBreakfast/Program.cs#L108{{</ coderef >}}
```
rt.Spawn(cook, () => BaconFryer(3));
```

Finally, the cook process defines overloaded `Receive` methods for every message type it expects, updates the encapsulated work state, and continues to receive messages from its mailbox until the breakfast actions are complete.

{{< coderef >}}https://github.com/tinychameleon/csharp-message-passing/blob/4b30952cb85653375af54417df3ba049de647c79/MessageBreakfast/Program.cs#L58{{</ coderef >}}
```
class Cook : Runnable
{
    private bool doneBacon = false, ...;

    public override void Invoke(MessagingRuntime rt, Mailbox mbox)
    {
        ...
        
        while (... || !doneBacon || ...)
        {
            mbox.Receive();
        }

        ...
    }

    public void Receive(BreakfastItem<Bacon> bacon)
    {
        Console.WriteLine("bacon is ready");
        doneBacon = true;
    }

    ...
}
```

One thing to highlight here is that the calls to `mbox.Receive()` don't just spin and eat CPU time --- underneath the hood the `Mailbox` class uses a condition variable to wait for a message delivery and wakes up only once there is a message to process.

This style of communication oriented design focuses on smaller building blocks which work together in distributed fashion to create a system.
Messages can be your domain types, but do not have to be; they can be explicitly designed to represent the communication concepts which occur in a system.
This first-class approach to messages gives them all the benefits of your normal domain types, and in particular, they can have access control applied which allows for assemblies to define privileged messages for internal interactions.

Fundamentally message-passing is a higher-level abstraction where your code is focused on handling different inputs instead of being embedded inside a concurrency mechanism.
Each of the processes is isolated from other processes and also has decoupled logic which only deals with expected messages.
The code is all written synchronously and there is no need to worry about concurrent state modification.
None of the code has to worry about calling a method causing its execution properties to change --- whether spawned or called manually a method acts the same way.

Promises make all this easier to implement within a message-passing library, so they by no means useless.
The spawn, send, and receive primitives are simply a cleaner, better API to build concurrent code.
The message-passing library I hacked together isn't the prettiest in its current form, but it does provide some good design improvements.
Hopefully it sparked enough curiosity that you look into a production-quality message-passing library for your own technical stack.

[^1]: Technically this is only true if you are using a language, like C#, that has better promise support and can hide continuation-passing style from you via compiler transforms.

[^2]: This is not true because it's highly language dependent. For example, nothing stops a co-worker from adding `async` and `await` to message-passing oriented code in C#, though they may have to fix a large number of compiler errors. As a counter example, Erlang simply does not allow code to be asynchronous; you can spawn a process which runs code concurrently, but your code will continue running and must purposefully communicate with that process to wait for a response.

[^3]: I didn't actually bother to make `Message` a real C# value-type using the `struct` syntax, but in a real system you would want value-type semantics for messages. Like I said earlier, this library is rough.