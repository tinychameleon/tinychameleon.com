---
title: "Advent of Code 2015: Preparatory Tools"
date: "2020-02-13T06:06:27Z"
tags: ["advent-of-code", "ruby"]
baseurl: "https://github.com/tinychameleon/advent-of-code-2015/blob/a8141af2967b4c82fa39c2e14ab829c8c37858b9"
---

Problem solving is really hard; it's difficult enough that many people struggle approaching the process, before even beginning to attempt a solution.
I don't think that's surprising at all: the journey an idea must take from thought to a rough draft to iterating toward final working solution is intimidating.
The blank canvas awaiting a solution from your mind invites a personal connection between the problem and you; if you're not careful it's easy to treat failing to find an answer as a personal shortcoming.
Even with my experience, I still occasionally suffer this paralysis when faced with a problem's blank canvas, but with practice this fear is conquerable by everyone; "burden" doesn't need to be synonymous with "problem solving" for anyone.

This series of posts will practice problem solving and highlight the process and approaches used to create working solutions using challenges from [Advent of Code](https://adventofcode.com/).
Through practice you will improve at following your own process and become adept at recognizing patterns within the challenges you encounter.
Each challenge consists of two parts, the first part unlocks the second, but before we begin, I would like to walk you through a self-made problem: creating a tool to ease our problem solving process.
Once we're comfortable with this tool, and the process it implements, we can start solving the challenges.

## Making Custom Jigs
You may not be convinced that we need a purpose-built tool for solving these problems, and if you're not used to creating jigs you might even consider it a waste of time when you can simply run code directly from the terminal.
There's nothing wrong with avoiding creating custom tools, but if our goal is to focus on solving Advent of Code challenges we shouldn't reinvent common functionality for every challenge.
Bespoke structure can be liberating, but formalizing a way to represent and interact with our solutions will provide a solid foundation for our problem solving practice by making the structural decisions once.
The resultant foundation will give us consistent solution structure, provide a framework for our thoughts to slot into, allow us to easily interact with our solutions consistently, and of course, allow us to run tests.

Ideally, all these requirements will be delivered in as minimal a package as possible, because we don't want to dedicate brain-space to complex user interfaces or libraries.
This custom tool might seem like a daunting task to you, it definitely sounds like a larger undertaking, but know that you're not alone in that feeling --- many people struggle with breaking down large problems into smaller, manageable chunks.
I also want you to know up-front that this tool is much easier to build than you may think; we're going to walk through all 109 lines of it in the remainder of this post.
Seriously, it's only 109 lines total; you're gonna be just fine.

## Advent of Code Runner
Let's start at the top-level of our tool, the user interface, and work our way down to the actual solution runner, because top-down design works really well for the majority of problems.
We're going to build a tool that operates based on command-line flags using only the Ruby[^1] standard library, and it will expose this interface:

```
Required flags:
    -y, --year YEAR                  The problem-set year (2015)
    -q, --question QUESTION          The problem-set question (1..25)

Run Choice flags:
    -t, --tests                      Run test inputs
    -a, --partA                      Run question part A
    -b, --partB                      Run question part B

Common flags:
    -h, --help                       Display this help message
```

My solution is split up into three components, each of which provides a specific piece of functionality to the tool:

- a driver class which glues user input, options, and solution running together;
- an options class which handles parsing and validating command-line flags;
- and a utility file that contains useful methods.

### The Driver
We'll start with the top-level component: the `Driver` class; as mentioned above it's responsible for gluing together all of our components, which means it has little functionality itself.
In fact, it only has two very short, static methods called `launch` and `run_solution`:

{{< coderef >}}{{< var "baseurl" >}}/main.rb{{</ coderef >}}
```
require './options'

class Driver
  def self.launch(args)
    options = Options.new.parse(args)
    workdir = "./#{options.year}/#{options.question}"
    require "#{workdir}/solution"
    run_solution(workdir, options)
  end

  def self.run_solution(pwd, options)
    Dir.chdir(pwd)
    if options.tests
      Solution.new.tests
    elsif options.part_a
      Solution.new.part_a
    else
      Solution.new.part_b
    end
  end
end

puts Driver.launch ARGV
```

There are a few things to notice about this piece of code:

- No "main" function, only a line to print results
- The `launch` method is our glue
- There is dynamic code loading, via `require`, but it's not a security exploit

As you can see, our `Driver` class is sparse, and the two static methods aren't complicated; `launch` handles command-line flags and loading solutions based on those values and `run_solution` runs the challenge part or tests based on a dynamically loaded `Solution` class which we'll see later on.

While building this I originally had the `Driver` and option parsing class in the same file, but decided to split them apart to maintain separation of concerns once the options parsing grew.
You're going to read a lot of code, but never assume what you're seeing is a first-cut; in fact, I added the `Dir.chdir` call later when I realized it was handy to read files from individual solution directories.
This driver isn't perfect, but it _is_ good enough for my purposes, and that's the most important thing about building personal tooling: arriving at "good enough".

### Program Options via Command-Line Flags
The second, and largest, piece we'll look at is the `Options` class that the `Driver` class uses; it comprises 79 of the 109 lines of code within the tool.
If you recall, I mentioned the dynamic code loading is not a security exploit, which is due to the validation `Options` applies to the inputs it's given.
My `Options` class achieves this validation, and command-line flag parsing, by leaning heavily on the `optparse` library that ships with Ruby.
We're going to do a class tear-down of `Options` covering static constants, initialization, flag definitions, and validations, and while the code segments presented will not reference or be indented they are all part of the `Options` class.

{{< coderef >}}{{< var "baseurl" >}}/options.rb#L3{{</ coderef >}}
```
require 'optparse'

class Options
  YEARS = %w[2015].freeze
  QUESTIONS = ('1'..'25').to_a.freeze
  QUESTION_MESSAGE = 'The problem-set question (1..25)'.freeze

  attr_reader :year, :question, :tests, :part_a, :part_b

  # All other methods snipped out
end
```

The years and question numbers are frozen here, which we will use to validate input to ensure nothing silly can happen, like passing `..` as part of one of the parameters.
You can see that the basic structure of the constants in this class is rather simple: we just create groups of allowed values to eventually pass into the `OptionParser` class.[^2]

{{< coderef >}}{{< var "baseurl" >}}/options.rb#L10{{</ coderef >}}
```
def initialize
  @tests = @part_a = @part_b = false

  @parser = OptionParser.new do |opt|
    required_flags(opt)
    choice_flags(opt)
    common_flags(opt)
  end
end
```

The initialization of the `Options` class should be easy to understand: explicitly give the read-only attributes we defined their initial values, create a new `OptionParser` instance and set up different types of flags on it.
Our required flag set-up is a bit more interesting because I set up validation to avoid security issues in the `Driver` class; don't expect anything too amazing though, `OptionParser` makes it trivial.

{{< coderef >}}{{< var "baseurl" >}}/options.rb#L20{{</ coderef >}}
```
def required_flags(opt)
  opt.separator "\nRequired flags:"

  year_msg = "The problem-set year (#{YEARS.join ', '})"
  opt.on('-y', '--year YEAR', YEARS, year_msg) { |y| @year = y }

  opt.on('-q', '--question QUESTION', QUESTIONS, QUESTION_MESSAGE) do |q|
    @question = q
  end
end
```

At this point you might be thinking, "I don't think I could come up with this option-parser code so easily...", but you would be selling yourself short.
The fact you don't know what the arguments to `on` are doesn't matter, because those kinds of detail are more about familiarity than problem solving.
In case you really want to know, the positional arguments mean the following things:

- short flag,
- long flag with optional or mandatory value,
- allowed flag values,
- help message,
- and assignment block.

If you attempt building a personal tool in the future, make sure you refrain from judging your progress by how much time that first attempt takes.

{{< coderef >}}{{< var "baseurl" >}}/options.rb#L31{{</ coderef >}}
```
def choice_flags(opt)
  opt.separator "\nRun Choice flags:"
  opt.on('-t', '--tests', 'Run test inputs') { @tests = true }
  opt.on('-a', '--partA', 'Run question part A') { @part_a = true }
  opt.on('-b', '--partB', 'Run question part B') { @part_b = true }
end
```

You should be able to speed-read the `choice_flags` method at this point because it's basically the same thing as the `required_flags` method, but with less going on.
This method is important though, because it's setting up our run choice flags for tests and the two parts of each challenge.

{{< coderef >}}{{< var "baseurl" >}}/options.rb#L38{{</ coderef >}}
```
def common_flags(opt)
  opt.separator "\nCommon flags:"
  opt.on_tail('-h', '--help', 'Display this help message') do
    puts @parser
    exit
  end
end
```

My `common_flags` implementation should be equally easy to understand; hopefully your confidence in reading Ruby and understanding the tool is increasing.
I think the critical realization you should be working toward is that solutions don't have to be fancy, and actually, I prefer these boring solutions because they require less brain-space.
There's only four small methods remaining in this class, and three of them are related to validating input, so lets look at `parse` first since it's used by the `Driver` class.

{{< coderef >}}{{< var "baseurl" >}}/options.rb#L46{{</ coderef >}}
```
def parse(args)
  parse_or_fail(args)
  validate_mandatory_flags
  validate_run_flags
  self
end
```

Very little about `parse` can be considered intriguing and that's exactly how I like my methods: unimaginatively boring.
The remaining methods are all about validating input and producing decent error messages, which is a task many people choose to avoid when creating their own tools.
I think it's important to always handle errors in a graceful manner because firstly, it helps me in the future, and secondly, it allows me practice at solving error cases for more important code-bases I work within.

{{< coderef >}}{{< var "baseurl" >}}/options.rb#L55{{</ coderef >}}
```
def parse_or_fail(args)
  @parser.parse!(args)
rescue OptionParser::MissingArgument, OptionParser::InvalidArgument => e
  puts e
  puts "\n", @parser
  exit 1
end
```

Ruby has a neat trick for eliminating a level of nesting in method definitions: the catch clause can be attached to the `def` level.
Essentially, all `parse_or_fail` does is ask the `OptionParser` instance to parse the given arguments and print out our help message if there is a failure of any kind.

{{< coderef >}}{{< var "baseurl" >}}/options.rb#L63{{</ coderef >}}
```
def validate_mandatory_flags
  return unless @year.nil? || @question.nil?

  puts "Both the --year and --question flags must be specified\n\n"
  puts @parser
  exit 2
end
```

The `validate_mandatory_flags` method just checks that year and question flags are both provided and prints a nice error message otherwise.

{{< coderef >}}{{< var "baseurl" >}}/options.rb#L71{{</ coderef >}}
```
def validate_run_flags
  active = [@tests, @part_a, @part_b].map { |b| b ? 1 : 0 }.sum
  return unless active != 1

  puts "Exactly one of --tests, --part_a, or --part_b must be specified\n\n"
  puts @parser
  exit 3
end
```

The one tricky thing about `validate_run_flags` is how I've decided to verify only one is given by taking the sum of boolean values converted into a 0 or 1.
That way any result not equal to 1 implies that zero or more than one of the flags were passed to the program.
With that, we're done looking at the `Options` class, so it might be a good time to take a break, maybe grab a drink.

### Testing Utilities
Well now, `Options` was quite a trek, so as a cool-down let's think about how we can implement tests for our challenge solutions without having to learn a full testing library.
Keeping the tests alongside the solution code is important to me to minimize context switching while problem solving, and while Ruby does have many good production-ready testing frameworks, they're all too verbose for our purposes here.
May I present to you, a nano-framework for testing consisting of a single `assert` method:

{{< coderef >}}{{< var "baseurl" >}}/utils.rb{{</ coderef >}}
```
class AssertionFailure < RuntimeError; end

def assert(got, want)
  return if got ## want

  raise AssertionFailure, "Got #{got.inspect}, want #{want.inspect}"
end
```

Now this method doesn't have a lot of the niceties that you expect, it's the definition of bare-bones; no beautiful test output, no back-tracking to find the correct line numbers, nothing.
Raising an exception will point out the failing test immediately above the message output, and there's no brain-space wasted to learn anything: just call `assert` a bunch of times and keep going.

### Solution Template
The final piece of our tool is a completely separate piece of not-quite-code, which resides in a `.template` file, because no one likes rewriting the same boilerplate.
Not very exciting, right?
I think it's an important piece of tooling, since you can simply `cp` it into the correct position and immediately begin work on a new challenge with almost zero friction.
The solution interface is laid out for us without needing to ever think about it again.

{{< coderef >}}{{< var "baseurl" >}}/solution.rb.template{{</ coderef >}}
```
require './utils'

class Solution
  def tests
    assert true, true
    :ok
  end

  def part_a
    raise NotImplementedError
  end

  def part_b
    raise NotImplementedError
  end

  private

  def solve_a(input)
    raise NotImplementedError
  end

  def solve_b(input)
    raise NotImplementedError
  end
end
```

Explaining each part of this tool makes it seem much larger than 109 lines, but I want to show how low the barrier to entry is for creating personal tools and problem solving.
This tool leans heavily on the Ruby standard library and that's perfectly okay, better even, than building everything from scratch because you know that the standard libraries work.

Without much fanfare we've built a fully functional program to help us as we begin attempting Advent of Code challenges and I think that's pretty great.
You don't need perfect code to create useful things, you don't need fancy algorithms, you don't need advanced mathematics, all you need is a bit of patience and the desire to learn.

## Code Style & Static Analysis
I've glossed over static analysis tools so far even though they are a major component of most projects because for personal tools you really don't need any of them.
However, I find it much easier to learn languages with a decent code style tool, so for the Advent of Code challenges I've used [Rubocop](https://www.rubocop.org).

It ships with fairly decent defaults for most projects, but for my purposes some of those defaults are unacceptable and will need tweaking.
The YAML configuration Rubocop uses is very legible and since I prefer to comment styling rules, I will simply reproduce the file below and avoid unnecessary explanations.

{{< coderef >}}{{< var "baseurl" >}}/.rubocop.yml{{</ coderef >}}
```
# For tests, having braces around the expected value helps
# with clarity:
#
#   assert solve('question'), { a: [1, 2, 3] }
#
Style/BracesAroundHashParameters:
  Enabled: false

# Documentation on classes is great, if this were a realistic
# production product.
Style/Documentation:
  Enabled: false

# Frozen-by-default string literals are also great in production
# products; but the magic comment detracts from solutions.
Style/FrozenStringLiteralComment:
  Enabled: false

# While this metric can be useful for other methods, it will report
# failures for our testing methods.
Metrics/AbcSize:
  Enabled: false

# We want our test methods to be self-contained, so we can simply exclude
# them from method length checks.
Metrics/MethodLength:
  ExcludedMethods:
    - tests
```

You should always consider the default configuration of any external tool you use for projects because your motivation is more important than obeying every default someone else has decided to ship.
It's impossible for defaults, no matter how reasonable, to be correct for every project, so don't feel bad for changing them.

## Tools are Important
Hopefully you made it through unscathed, with new appreciation for tools and how easy it can be to create them.
Every profession has tools-of-the-trade and as software developers, or even software enthusiasts, we're in the lucky position of being able to easily invent tools for any situation we face.
I think it helps to reflect on how impossible creating tools like the solution runner above is for so many other professions; it's kind of a software superpower.

Next time, we're going to dive into the first Advent of Code challenge.

[^1]: I'm using Ruby 2.6.5.
[^2]: Ruby is dynamic and calling `freeze` on an object stops it from changing.
