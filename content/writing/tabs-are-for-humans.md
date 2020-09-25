---
title: "Tabs are for Humans"
date: "2020-09-25T01:59:47Z"
tags: [programming]
---

People have a lot of preferences when it comes to writing programs.
Should braces go on their own lines?
Should private member names begin with an underscore?
What order should method modifiers appear in?
Arguments about how to write code are common enough that many companies have published style guides for certain languages.
I would hazard a guess that most programmers interact with some sort of style guide tool on a daily basis.

All this effort ensuring code is written properly, for some definition of "properly" which few people seem to agree on.
Automation and tools are brought out to verify code and attach check-marks to pull requests.
All this is good --- we should definitely let computers verify more things --- but so little thought or effort has been put into the humanitarian side of code.

The oft-quoted phrase, "code is read more often than it is written", is a popular aphorism, probably bandied about on every programming forum ever created, and is generally the limit of the discussion around the people interacting with code.
Rarely are there topics surrounding the readability of code, and when a topic arises it is normally about some new mono-space font.

Many people have one or more favourite type-faces, it's true, but font-families are only one dimension of readability.
We regularly ignore the readability benefits brought by point sizes improving reading error rates by disambiguating character runes.
Line heights are barely mentioned when they make following lines easier on a person's eyes.
We are, however, gluttons for colour themes.

Each of these things can contribute greatly to how readable code is to a person.
People are different and each of the previously mentioned properties can and should be tweaked to best suit the individual because everyone has their own preference.
If someone finds the [Cobalt2](https://marketplace.visualstudio.com/items?itemName=wesbos.theme-cobalt2) highly readable, then that's wonderful for them, but it may not suit you or I.
Almost every textual property of code we read and write can be changed to suit the readability requirements of the reader.

Except one.
It's the topic of this work.
Leading white-space.

People have an idea stuck in their head, that leading white-space must absolutely look identical across everyone's displays.
We've flocked to using the space character as the indentation character and enforced indentation width sizes on projects.
It's considered a great readability victory that indentation and alignment can co-exist within a given file.
As long as your readability preference isn't hurt by whatever indentation width is chosen.
We can change many properties for displaying code in ways that are beneficial to the human reader, but not this critical piece related to readability.
This is something that should change, and certain languages, like Go, are leading the way.

The first step is to deal with the fixation on identical leading white-space by recognizing it for what it is: a bike-shedding topic.
All discussions about the number of spaces to insert as an indentation level are worthless because they preclude the human side of the discussion by assuming a specific indentation width works for all.
There is only one choice to resolve this first step: use tabs.

The second step, which I briefly alluded to above, is to rid your brain of the idea that alignment is a high-value property of code layout.
The argument that tabs break alignment no longer matters when alignment has little value.
Stop aligning code, it makes what you've written less readable.
Alignment pushes code off to the right-hand side of the display, farther away from the natural left-hand side flow.

We can quantify the readability of a statement and show that indentation leads to better quality.
Of course, this is not a scientific experiment and so you may be left unconvinced, but read on and I think you will, at the least, agree that the choices are reasonable.

To quantify the readability of a statement based on indentation and alignment, we're going to use vectors to represent distances that a person's eye needs to traverse.
One vector, V*{{< sub lines >}}*, represents the distance necessary to recognize boundaries and extends from the beginning of the first line of the statement to the beginning of the last line of the statement.
A second vector, V*{{< sub next >}}*, represents the distance necessary to jump to the next statement and extends from the end of the last line of the statement to the beginning of the next statement.
Finally the third vector, V*{{< sub long >}}*, represents the effort to read the longest sub-statement and extends from the X coordinate of the beginning of the statement to the end X coordinate of the longest line.

Total distance is what matters for these vectors, so the directional component is not important.
This is about representing, in a numeric format, the distance a person's eyes have to travel to read a piece of code.
The final operations to generate a score are the summation of the three vectors, obtaining V*{{< sub sum >}}*, and finding the magnitude of V*{{< sub sum >}}*.

The above description, can be succinctly written algebraically, for a score *S*, as:

> V*{{< sub sum >}}* = V*{{< sub lines >}}* + V*{{< sub next >}}* + V*{{< sub long >}}*
>
> S = |V*{{< sub sum >}}*|

Theorizing about this equation, I would expect that minimizing the score maximizes readability.
Shorter eye-travel distances should yield less strain and less overall physical reading effort.
I would also expect accuracy and understanding to improve as total invested reading effort decreases.
A corollary to these statements is that indent-oriented code should produce smaller distances whereas alignment-oriented code should be greater.

To test out the equation I've [randomly selected a lengthy statement from Jon Skeet's NodaTime library](https://github.com/nodatime/nodatime/blob/2ec2b8fc3ec0cfe97f8129931d0b12c0c01662ed/src/NodaTime/CalendarSystem.cs#L761).
This line was chosen for the following reasons:

- it has a long line of 163 characters
- it is character dense, having 218 characters over 2 lines
- it can be easily formatted idiomatically via indentation and alignment
- it's from a production library

There wasn't much to the discovery process other than filtering for long lines; also, the `nextStatement;` code is simply a stand-in for what would generally be a following statement.

Now let's analyse the code using the distance-based equation.
It's a pretty long statement, using only indentation, so this is going to be penalized heavily by V*{{< sub long >}}*.
For distance units, we'll use the number of fixed-width characters for simplicity, we will also assume the common tab-width of 4 space characters.

```
internal static readonly CalendarSystem Astronomical =
    new CalendarSystem(CalendarOrdinal.PersianAstronomical, PersianAstronomicalId, PersianName, new PersianYearMonthDayCalculator.Astronomical(), Era.AnnoPersico);

nextStatement;
```

From the beginning of `internal` to the beginning of `new` is 4 characters over and 1 character down, so V{{< sub lines >}} = (4, 1).
From the `;` at the end of the second line, to the beginning of the next statement is 162 characters over and 2 characters down, so V*{{< sub next >}}* = (162, 2).
From the beginning of the second line to its end is 162 characters, so V*{{< sub long >}}* = (162, 0).

Calculating the sum, V*{{< sub lines >}}* + V*{{< sub next >}}* + V*{{< sub long >}}*, is (4 + 162 + 162, 1 + 2 + 0) so V*{{< sub sum >}}* = (328, 3).
The score, *S*, is calculated by √(V*{{< sub "sum x" >}}*{{< sup 2 >}} + V*{{< sub "sum y" >}}*{{< sup 2 >}}), so *S* = √(328{{< sup 2 >}} + 3{{< sup 2 >}}) = 328.01.

So, the original code has a score approximately equal to 328, and the equation can be skewed by very long horizontal or vertical entries.
This is good because statements or blocks containing many lines should be penalized for complexity.

Let's look at a typical alignment-oriented layout of the code and see how the score improves.
We should expect the horizontal penalization to decrease dramatically and the V*{{< sub lines >}}* distance to increase relative to the alignment depth.

```
internal static readonly CalendarSystem Astronomical =
    new CalendarSystem(CalendarOrdinal.PersianAstronomical, PersianAstronomicalId,
                       PersianName, new PersianYearMonthDayCalculator.Astronomical(),
                       Era.AnnoPersico);

nextStatement;
```

From the beginning of `internal` to the beginning of `Era.AnnoPersico` is 23 characters over and 3 characters down, so V*{{< sub lines >}}* = (23, 3).
From the `;` at the end of the 4{{< sup th >}} line to the beginning of the next statement is 39 characters over and 2 characters down, so V*{{< sub next >}}* = (39, 2).
From the beginning of the 3{{< sup rd >}} line to its end is 84 characters, so V*{{< sub long >}}* = (84, 0).

The sum of these vectors is, V*{{< sub sum >}}* = (23 + 39 + 84, 3 + 2 + 0) = (146, 5) and the score is *S* = √(146{{< sup 2 >}} + 5{{< sup 2 >}}) = 146.08.
This is around a 55% reduction in score from the original code, which makes it a little over 2*x* as readable.

Now let's look at an typical indent-oriented layout.
Indentation-based layouts group code via nesting and provide highly visible end-of-statement/block delimiters, so V*{{< sub next >}}* should decrease dramatically.

```
internal static readonly CalendarSystem Astronomical =
    new CalendarSystem(
        CalendarOrdinal.PersianAstronomical, PersianAstronomicalId, PersianName,
        new PersianYearMonthDayCalculator.Astronomical(), Era.AnnoPersico
    );

nextStatement;
```
From the beginning of `internal` to the beginning of `);` is 4 characters over and 4 characters down, so V*{{< sub lines >}}* = (4, 4).
From the `;` at the end of the 5{{< sup th >}} line to the beginning of the next statement is 5 characters over and 2 characters down, so V*{{< sub next >}}* = (5, 2).
From the beginning of the 3{{< sup rd >}} line to its end is 79 characters, so V*{{< sub long >}}* = (79, 0).

The sum of these vectors is, V*{{< sub sum >}}* = (4 + 5 + 79, 4 + 2 + 0) = (88, 6) and the score is *S* = √(88{{< sup 2 >}} + 6{{< sup 2 >}}) = 88.2.
This is around a 40% reduction in score from the alignment-oriented code, which makes it a little over 1.6*x* as readable.

This means that the indent-oriented code allows for the shortest eye-travel distances and by using tab characters for indentation you support the legibility requirements of every person.
Someone who uses larger tab-widths will necessarily increase eye-travel distance, but that distance increase can be easily offset by the accuracy gains they receive from being able to use their preferred spacing distances.

So the next time you're having a tabs-v.s.-spaces or tab-width debate, remember that using spaces doesn't matter.
Obsessing over a fixed indentation width doesn't matter.
Let go of alignment.
What matters is improving everyone's reading accuracy, and tab characters are the solution.
