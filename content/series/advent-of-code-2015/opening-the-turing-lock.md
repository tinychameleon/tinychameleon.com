---
title: "Advent of Code 2015: Opening the Turing Lock"
date: "2021-09-29T02:16:51Z"
tags: [advent-of-code, ruby]
part-a-url: https://github.com/tinychameleon/advent-of-code-2015/blob/d332c627a92b06f68cff7ddb983c8ff2ae6201ad/2015/23/solution.rb
part-b-url: https://github.com/tinychameleon/advent-of-code-2015/blob/6418f21cee6c5169ce629b4903424fda5d14fd5c/2015/23/solution.rb
---

We get to build a little assembly language in the [twenty-third Advent of Code challenge](https://adventofcode.com/2015/day/23).
This one might be interesting to solve using an object-oriented approach.

## Part A: Booting Up
This challenge centres around translating a set of instructions into a computation.
Registers, a program counter, and instruction definitions will all be necessary, as described by the problem.

> The manual explains that the computer supports two registers and six instructions (truly, it goes on to remind the reader, a state-of-the-art technology). The registers are named a and b, can hold any non-negative integer, and begin with a value of 0. The instructions are as follows:
>
> - hlf r sets register r to half its current value, then continues with the next instruction.
> - tpl r sets register r to triple its current value, then continues with the next instruction.
> - inc r increments register r, adding 1 to it, then continues with the next instruction.
> - jmp offset is a jump; it continues with the instruction offset away relative to itself.
> - jie r, offset is like jmp, but only jumps if register r is even ("jump if even").
> - jio r, offset is like jmp, but only jumps if register r is 1 ("jump if one", not odd).
>
> All three jump instructions work with an offset relative to that instruction. The offset is always written with a prefix + or - to indicate the direction of the jump (forward or backward, respectively). For example, jmp +1 would simply continue with the next instruction, while jmp +0 would continuously jump back to itself forever.
>
> The program exits when it tries to run an instruction beyond the ones defined.
> What is the value in register b when the program in your puzzle input is finished executing?
>
> --- _Advent of Code, 2015, Day 23_

This solution will depend on a `Program` and a `Register` class to maintain the state of the computation as instructions are executed.
The `Register` class will have methods equivalent to the instruction names, so to parse the program we simply need to translate the written words into method calls.
Let's start by creating that `Register` class.

{{< coderef >}}{{< var part-a-url >}}#L3{{</ coderef >}}
```
class Register < Numeric
  def initialize(val = 0)
    @val = val
  end

  def <=>(other)
    @val <=> other
  end

  def inc
    @val += 1
  end

  def hlf
    @val /= 2
  end

  def tpl
    @val *= 3
  end

  def even?
    @val.even?
  end

  def one?
    @val == 1
  end

  def to_i
    @val
  end
end
```

It's a bit long since I haven't used single-line methods, but it's rather simple: each method which matches a program instruction performs the associated action.
The jump instructions are part of the program itself.

Now that there's a `Register` class we can begin to parse the program input into register names and statements.
The register names will be associated with an instance of each `Register` class and the statements will contain references to the registers, instructions, and arguments.

{{< coderef >}}{{< var part-a-url >}}#L137{{</ coderef >}}
```
def read_program(input)
  register_names = []
  statements = []
  input.lines.map { |l| l.chomp.split(/[, ]+/) }.each do |parts|
    register, statement = parse_statement(*parts)
    register_names << register unless register.nil?
    statements << statement
  end
  [register_names.sort.uniq, statements]
end
```

There's a decent amount of work occurring in this method, but the main input transformations are:

- obtaining each line from the program input and splitting it on commas and spaces;
- parsing the register name and statement out of the parts of the line;
- returning a list of the register names and all the program statements.

The `parse_statement` method is responsible for dealing with all the individual parts of a given program instruction line.
It is a a typical switch statement that transforms each result into the `[register name, [operation, arguments...]]` structure that we'll use within the program to execute statements.

{{< coderef >}}{{< var part-a-url >}}#L124{{</ coderef >}}
```
def parse_statement(opstr, arg1, arg2 = nil)
  case opstr
  when 'inc', 'hlf', 'tpl'
    r = arg1.to_sym
    [r, [opstr.to_sym, r]]
  when 'jmp'
    [nil, [opstr.to_sym, arg1.to_i]]
  when 'jio', 'jie'
    r = arg1.to_sym
    [r, [opstr.to_sym, r, arg2.to_i]]
  end
end
```

Of note here is that the string operation names are being converted into symbols and the arguments are converted to their integer representations.
After parsing we are no longer dealing with the text-based program that was given as input.

Now that parsing the input program is completed we can construct the `Program` class to take the registers and statements, set up the necessary state, provide a mechanism to run the program, and to access register values.

{{< coderef >}}{{< var part-a-url >}}#L37{{</ coderef >}}
```
class Program
  attr_reader :instruction_counter

  def initialize(register_names, statements)
    @instruction_counter = 0
    @registers = register_names.each_with_object({}) do |name, rs|
      rs[name] = Register.new
    end
    @statements = statements
  end
...
```

Creating the `Program` instance and the necessary state is easy: the instruction counter will keep track of where the program is, the `Register` instances get created and associated with their textual name, and the statements are saved to access during execution.

We will need a way to access the numeric value of a register to determine what the value of `b` is at the end of the program.

{{< coderef >}}{{< var part-a-url >}}#L56{{</ coderef >}}
```
def register(name)
  @registers[name].to_i
end
```

The `Program` exposes a method that looks up the `Register` by name and returns the integer value stored within it.
The last thing necessary is the ability to run the program.
The `run!` method will need to execute until the program attempts to read past the last statement and execute each statement including jumps.

{{< coderef >}}{{< var part-a-url >}}#L49{{</ coderef >}}
```
def run!
  until (statement = @statements[@instruction_counter]).nil?
    op, *args = statement
    execute(op, args)
  end
end
```

Recall from above that each statement is of the form `[operation, arguments...]`, so we split that array here to pass each part into a private method called `execute` which does the heavy lifting.

{{< coderef >}}{{< var part-a-url >}}#L62{{</ coderef >}}
```
def execute(op, args)
  case op
  when :inc, :tpl, :hlf
    @registers[args[0]].send(op)
    jump(1)
  when :jmp
    jump(args[0])
  when :jie, :jio
    reg, offset = args
    pred = op == :jie ? :even? : :one?
    jump(@registers[reg].send(pred) ? offset : 1)
  end
end
```

The `execute` method is another typical switch like the `parse_statement` method above.
For instructions the `Register` can implement it uses `send` to execute the instruction and moves the instruction counter by 1 using `jump(1)`.
The `jmp` instruction simply calls `jump()` to move the instruction counter.
Finally, the jumping if even and jumping if one instructions call different predicates on the `Register` instance and jump by the offset given or 1 otherwise.

The `jump` method is very simple.

{{< coderef >}}{{< var part-a-url >}}#L76{{</ coderef >}}
```
def jump(offset)
  @instruction_counter += offset
end
```

With all this in place we can write the `solve_a` method by using `Program` and `read_program`.

{{< coderef >}}{{< var part-a-url >}}#L148{{</ coderef >}}
```
def solve_a(input)
  program = Program.new(*read_program(input))
  program.run!
  program.register(:b)
end
```

Finally, we can run the solution to part A and find out what value register `b` holds.

```
$ run -y 2015 -q 23 -a
184
```

## Part B: Initialize the System
The second component of the challenge requires being able to set specific initialized program state.

> ... what is the value in register b after the program is finished executing if register a starts as 1 instead?
>
> --- _Advent of Code, 2015, Day 23_

To solve this, let's migrate the `Register` creation and the program parsing into a `Compiler` class that can handle initializing registers with a value prior to the program executing.
The `Compiler` can return a `Program` for the solution to use while taking the necessary register state.

{{< coderef >}}{{< var part-b-url >}}#L166{{</ coderef >}}
```
def solve_a(input)
  program = Compiler.new(input).program
  program.run!
  program.register(:b)
end

def solve_b(input)
  program = Compiler.new(input).program(a: 1)
  program.run!
  program.register(:b)
end
```

The `Compiler` class will take on the functionality of `read_program` and `parse_statement`, so those get moved into the new `Compiler` class, with `read_program` becoming the `Compiler#initialize` method.

{{< coderef >}}{{< var part-b-url >}}#L37{{</ coderef >}}
```
class Compiler
  attr_reader :registers, :statements

  def initialize(input)
    # nearly identical to read_program from part A.
  end

  private

  def parse_statement(opstr, arg1, arg2 = nil)
    # identical to parse_statement from part A.
  end
end
```

The difference is in the `Compiler#program` method which we used twice above: it has to take register state and return a `Program` for use.

{{< coderef >}}{{< var part-b-url >}}#L53{{</ coderef >}}
```
def program(**initial_registers)
  rs = registers.each_with_object({}) do |name, regs|
    regs[name] = initial_registers.fetch(name, 0)
  end
  Program.new(rs, statements)
end
```

When provided with a keyword argument for register values it will use the passed in value, or otherwise default to 0.
The `Program` class also needs to change slightly as instead of register names it is now receiving pairs of register names with values.

{{< coderef >}}{{< var part-b-url >}}#L76{{</ coderef >}}
```
class Program
  attr_reader :instruction_counter

  def initialize(registers, statements)
    @instruction_counter = 0
    @registers = registers.transform_values { |v| Register.new(v) }
    @statements = statements
  end
  ...
```

The registers passed in have their values mapped to a new instance of `Register` including the value that must be their initial state.
That's the last change and we can figure out what the value of register `b` is when register `a` is initialized to 1.

```
$ run -y 2015 -q 23 -b
231
```

## Some Assembly Required
The object-oriented solution is fairly simple and I'm sort-of happy with the separation of concerns though it could likely be better had I put more thought into it.

I think the entertaining thing about this challenge is it's essentially the beginning of an incredibly simple, interpreted, assembly scripting language.
That's just fun.
