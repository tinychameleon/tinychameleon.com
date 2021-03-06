---
title: "From Callbacks to Promises"
date: "2020-06-07T05:36:31Z"
tags: ["programming", "concurrency", "javascript"]
---

During a recent code review I made a suggestion to re-write callback-oriented code using Promise objects.
Part of the suggestion included an example, which prompted a question about what benefits are gained by migrating away from callbacks.
This good question has a surprisingly long answer because you need to understand how code execution can be made a parameter and how expressivity changes with implemented language features.

## Functions as Objects
The first idea to understand in order to successfully parametrize code with code is that all function calls need to be able to refer to their parameters.
Any piece of data passed to a function is capable of being referred to in some manner, so if we want pass code to a function it needs to also exist in an addressable manner.
Programming languages differ on precisely how to address code, but generally functions themselves are capable of being referred to in a manner that is acceptable to pass to other functions.

When a kind of thing is able to be referred to it is given the status of a "first-class value" in a programming language.
With first-class functions, you can write functions that have functions-as-parameters and functions-as-results, but for our purposes here we only care about functions-as-parameters.
Functions-as-parameters will be our critical building block for everything to come.

## Callbacks
Once you can pass a function as a parameter almost any piece of logic can be configured via a callback.
When you need to execute an action, but the next thing to execute is contextually different, a callback is a simple way to obtain re-usable code.

```
function writeRow(file, row, callback) {
    write(file, row);
    callback(row);
}
```

These kinds of programs employ similar code structure to GUI-based event programming where functions are created to handle button clicks and other similar events.
Callback-oriented programs are event-driven programs --- functions encapsulate a particular set of actions and defer the next step to a callback.

The downside to this kind of program structure is the nesting and fragmentation that can occur depending on the programming language and programmer discipline.
An undisciplined programmer may write callback-oriented code using deeply nested logic and many in-line function definitions.

```
queryDatabase(sqlQuery, function (rows) {
    console.log(`Writing ${rows.length} rows to disk');
    fs.open('results', 'w', function (err, file) {
        rows.forEach(function (row) {
            fs.write(file, row, function (err, bytesWritten, buffer) {
                console.log(`Wrote ${bytesWritten} bytes`);
            });
        });
    });
});
```

That code writes each row of the SQL query to a file named "result"; error handling is removed for brevity.
This kind of nesting leads to dense code which doesn't scale out to more complicated work.
Each new action to execute requires more and longer functions.

Let's add some discipline and remove all the in-line, anonymous function definitions --- this is a very easy change to implement and should enhance legibility by decreasing the density of the code.

```
function writtenRow(err, bytesWritten, buffer) {
    console.log(`Wrote ${bytesWritten} bytes`);
}

function writeRow(row) {
    fs.write(file, row, writtenRow);
}

function writeRowsToFile(err, file) {
    rows.forEach(writeRow);
}

function saveQueryResult(rows) {
    console.log(`Writing ${rows.length} rows to disk');
    fs.open('results', 'w', writeRowsToFile);
}

queryDatabase(sqlQuery, saveQueryResult);
```

Every function is easier to digest in this version, but the algorithm is now split over four function definitions.
Nothing binds these definitions together and a "don't-repeat-yourself" style refactor could easily migrate a piece of our logic into some kind of utility file.
These two implementations display tension between algorithm legibility and cohesion; the first is illegible yet cohesive while the second is legible with poor cohesion.

This tension is present in all code that is written in [Continuation-Passing Style](https://en.wikipedia.org/wiki/Continuation-passing_style#Examples).
The examples shown via that link should look familiar in structure --- callback-oriented code, like our above example, is actually Continuation-Passing Style.

## Promises
If Continuation-Passing Style causes problems for long-term maintenance there needs to be some other mechanism for parametrizing next execution steps, otherwise expressing ourselves this way will be unpalatable.
Promises, or Futures, are the answer and solve the problem by means of a trick --- the Continuation-Passing Style code is hidden inside a re-usable container.

```
function writtenRow(bytesWritten, buffer) {
    console.log(`Wrote ${bytesWritten} bytes`);
}

function writeRow(row) {
    return fs.writeAsync(file, row).then(writtenRow);
}

function writeRowsToFile(err, file) {
    return rows.forEach(writeRow);
}

function saveQueryResultAsync(rows) {
    console.log(`Writing ${rows.length} rows to disk');
    return fs.openAsync('results', 'w').then(writeRowsToFile);
}

queryDatabase(sqlQuery).then(saveQueryResult);
```

You may not be very impressed with this change to use Promise objects because it hasn't cleaned up the code, but there is a large change present in this example: we're programming with values.
By returning Promise objects which we can call methods on, like `then`, we have decoupled the algorithm logic from individual function parameters.
Sending the query results to a another function is now a matter of adding another `then` invocation instead of modifying the existing function.

## Await
With value-oriented code using the consistent API provided by Promise objects there is one final expressivity change to unlock.
By relying on the Promise API a programming language compiler can transform the `await` keyword into Continuation-Passing Style code while the programs remain succinct and legible to humans.

```
let rows = await queryDatabase(sqlText);
console.log(`Writing ${rows.length} rows to disk');

let file = await fs.openAsync('results', 'w');
rows.forEach(function(row) {
    let bytesWritten, buffer = await fs.writeAsync(file, row);
    console.log(`Wrote ${bytesWritten} bytes`);    
});
```

This code reads as if there is no next execution step parametrization --- the nesting and tension between legibility and cohesion is gone.
This is the reason to prefer Promise objects to callbacks.

