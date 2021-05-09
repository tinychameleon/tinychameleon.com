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
interface IRemoteDataAccessor {}

interface IResourceDataAccessor<TResource> : IRemoteDataAccessor
{
    TResource Data { get; }
}

interface IResourceCollectionDataAccessor<TResource> : IRemoteDataAccessor
{
    TResource[] Data { get; }
}
```

Now the project can create behaviours based on the two sub-type interfaces and can still store a heterogeneous set of accessors into a homogeneous list using `IRemoteDataAccessor`.

```
IRemoteDataAccessor[] accessors = {
    new SomeResource(),
    new SomeResourceCollection()
};
```

Everything works just fine until the project needs to _do something_ with those accessors.
With no behaviour defined on `IRemoteDataAccessor` the compiler can do nothing to help you utilize the instances stored in the array and you must resort to down-casting and if-statements to achieve anything.
The project becomes littered with code similar to the following example, which attempts to extract all the data out of the accessors[^2].

```
var elements = new List<object>();
foreach (IRemoteDataAccessor accessor in accessors)
{
    if (accessor is IResourceDataAccessor<object> d)
    {
        elements.Append(d.Data);
    }
    else if (accessor is IResourceCollectionDataAccessor<object> d)
    {
        elements.AddRange(d.Data);
    }
    else
    {
        throw new Exception("Unexpected data accessor type");
    }
}
```

This code is not type-safe and that else-block is a time-bomb waiting to explode; anybody can create a new accessor, add it to the list, and this code would have no idea what to do about it because `IRemoteDataAccessor` has no behavioural definition.
All you can do with an instance of `IRemoteDataAccessor` is assign it to an `object` or safely down-cast it, to some other type.

## Behavioural Refactoring
The sample above represents a structural archetype that occurs in projects where concrete functionality evolves over time without reevaluating the behaviours exposed by the project.
It has very little to do with programmer ability and everything to do with deadlines, pressure, and all the other surrounding and confounding events of a professional software product.
For many domains, the above solution _works_ and is good enough to sell the product, but there are products where this kind of approach will not scale for customers.

The root of the problem is that the super-type has no behaviour, but the project _needs_ behaviour to be available on collections of the super-type.
Related sub-type interfaces provide behaviour for individual instances of a concept, in this case fetching a resource or a collection of a resource.
In fact, this example is describing a third possibility: no resource at all.
If the problem of "obitain 0, 1, or many instances of a resource" is modelled via existing abstractions, like `IEnumerable<T>`, then the behavioural definitions become much clearer.

```
interface IRemoteDataAccessor<TResource>
{
    IEnumerable<TResource> Data { get; }
}
```

This interface now has behaviour, still provides type-safety within collections, and causes the sub-type interfaces to vanish, since they can be expressed using the `IEnumerable<T>` API.

```
IRemoteDataAccessor<object>[] accessors = {
    new SomeResource(),
    new SomeResourceCollection()
};
```

With a stable data access API and behaviour attached to the interface there is little complexity to writing that extraction for-loop above.

```
var elements = new List<object>();
foreach (IRemoteDataAccessor<object> accessor in accessors)
{
    elements.AddRange(accessor.Data);
}
```

This code is resilient to newly created sub-types of `IRemoteDataAccessor<T>` and does not rely on down-casting to access specific functionality to fulfill its goal.

## Avoid Super-Type Markers
It's easy to tell someone to avoid these kinds of architectural structures, but much harder to do in practice.
Keeping an eye out for this is easy, but the refactoring that is required could span a large amount of code.
Still, I think it is a useful change to make to reduce code size and improve the abstraction semantics of a project.

Of course, there are legitimate use-cases for marker interfaces, but these are generally restricted to component-oriented architectures where querying a set of assigned components is necessary[^3].

[^1]: Marker interfaces are also sometimes referred to as "interface tags".
[^2]: I've avoided attaching additional generic constraints to the actual `TResource` types here for simplicity. Please don't actually use `List<object>` unless you really know that you require it.
[^3]: An example of this is the Unity `GetComponent<T>` functionality, which allows you to pull a particular component off of a game object at run-time.
