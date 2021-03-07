---
title: "Behaviour Driven APIs"
date: "2021-03-07T22:41:17Z"
tags: [programming, csharp]
---

At some point every project requires a bit of thought about how to store heterogeneous data-types.
Lists of objects pop up constantly and there are several ways to deal with it, but my preferred way is to create behavioural super-type abstractions.
My least favourite way, and the topic of this post, is using marker interfaces[^1].

## Marker Interface Induced Pain
A general pattern I often see repeated with marker interfaces is to create an empty super-type interface so that specific sub-type interfaces can all be stored in a single container, like a `List<T>`.
If this interface is meant to provide access to data from somewhere, the pattern might look like this:

```
interface IAnyDataAccessor {}

interface ISingleDataAccessor<TData> : IAnyDataAccessor
{
    TData Data { get; }
}

interface IMultipleDataAccessor<TData> : IAnyDataAccessor
{
    TData[] Data { get; }
}
```

Now the project can create behaviours based on the two sub-type interfaces and can still store a heterogeneous set of accessors into a homogeneous list using `IAnyDataAccessor`.

```
IAnyDataAccessor[] accessors = {
    new SomeSingleDataProvider(),
    new SomeMultipleDataProvider()
};
```

Everything works just fine until the project needs to _do something_ with those accessors.
With no behaviour defined on `IAnyDataAccessor` the compiler can do nothing to help you utilize the instances stored in the array and you must resort to down-casting and if-statements to achieve anything.
The project becomes littered with code similar to the following example, which attempts to extract all the data out of the accessors[^2].

```
var elements = new List<object>();
foreach (IAnyDataAccessor accessor in accessors)
{
    if (accessor is ISingleDataAccessor<object> d)
    {
        elements.Append(d.Data);
    }
    else if (accessor is IMultipleDataAccessor<object> d)
    {
        elements.AddRange(d.Data);
    }
    else
    {
        throw new Exception("Unexpected data accessor type");
    }
}
```

This code is not type-safe and that else-block should make you feel rather uncomfortable; anybody could create a new accessor, add it to the list, and this code would have no idea what to do about it because `IAnyDataAccessor` has no behavioural definition.
The compiler will only let you use it as an `object` or down-cast it to some other type.

## Behavioural Refactoring
The sample above represents a structural archetype that occurs in projects where concrete functionality evolves over time without reevaluating the behaviours exposed by the project.
It has very little to do with programmer ability and everything to do with deadlines, pressure, and all the other surrounding and confounding events of a professional software product.
For many domains, the above solution _works_ and is good enough to sell the product, but there are products where this kind of approach will not scale for customers.

The root of the problem is that the super-type has no behaviour, but the project _needs_ behaviour to be available on collections of the super-type.
Related interfaces that provide behaviour for single and multiple objects of a particular type are describing a behaviour to obtain "0, 1, or many items" from a particular source.
Reconsidering the interface hierarchy to take this into account by utilizing existing APIs, like `IEnumerable<T>`, unlocks an implementation that provides clarity.

```
interface IDataAccessor<TData>
{
    IEnumerable<TData> Data { get; }
}
```

This interface now has behaviour, and crucially, it also ensures that you don't mix completely different data-types in collections.
The single and multiple variants collapse into this one behavioural interface definition, because they can both be expressed by the API `IEnumerable<T>` exposes.

```
IDataAccessor<object>[] accessors = {
    new SomeSingleDataProvider(),
    new SomeMultipleDataProvider()
};
```

With a stable data access API and behaviour attached to the interface there is little complexity to writing that extraction for-loop above.

```
var elements = new List<object>();
foreach (IDataAccessor<object> accessor in accessors)
{
    elements.AddRange(accessor.Data);
}
```

This code is resilient to newly created sub-types of `IDataAccessor<T>` and does not rely on down-casting to access specific functionality to fulfill its goal.

## Avoid Super-Type Markers
It's easy to tell someone to avoid these kinds of architectural structures, but much harder to do in practice.
Keeping an eye out for this is easy, but the refactoring that is required could span a large amount of code.
Still, I think it is a useful change to make to reduce code size and improve the abstraction semantics of a project.


[^1]: Marker interfaces are also sometimes referred to as "interface tags".
[^2]: I've avoided attaching additional generic constraints to the actual `TData` types here for simplicity. Please don't actually use `List<object>` unless you really know that you require it.
