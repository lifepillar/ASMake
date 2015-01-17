# ASMake: an AppleScript build library

ASMake is an AppleScript script library that aims to provide functionality
similar to Ruby's [rake](http://rake.rubyforge.org)
or GNU [make](https://www.gnu.org/software/make/manual/make.html), but tailored
especially for AppleScript-related tasks.

## Requirements

ASMake requires AppleScript 2.4 or later (OS X 10.10 or later).

## Installation

To install ASMake in `~/Library/Script Libraries`:

    git clone https://github.com/lifepillar/ASMake.git
    cd ASMake
    ./asmake install

It is recommended that you also define an alias in `~/.bashrc`:

    alias asmake='./makefile.applescript'


## Makefiles

Tasks are usually defined in an executable script called `makefile.applescript`
(the script can can have any name, but this is the convention I have adopted).
To make the script executable, open the terminal and type:

    chmod +x makefile.applescript

inside your project directory.

The general structure of a makefile is as follows:

    #!/usr/bin/osascript
    use AppleScript version "2.4"
    property parent : script "com.lifepillar/ASMake"

    on run argv
      continue run argv
    end run

    (* Tasks go here *)

Each task is a script that inherits from `Task(me)`. For example, the following
task can be used to compile `ASMake.applescript` into a run-only script:

    script build
      property parent : Task(me)
      property description : "Build ASMake."
      osacompile("ASMake", "scpt", {"-x"})
    end script

This task can be executed from the terminal with

    asmake build

(remember that `asmake` is just an alias to `./makefile.applescript`).
The list of available tasks can be obtained with

    asmake help

It is possible to explicitly define the name of a task and to provide synonyms,
e.g.:

    script versionTask
      property parent : Task(me)
      property name : "version"
      property synonyms : {"vers", "v"}
      property description : "Print my version and exit."
      property printSuccess : false
      echo("v1.0.0")
    end script

This task can be invoked equivalently with:

    asmake version
    asmake vers
    asmake v

By default, if a task completes successfully, the following message is printed:

    ==> Success!

To suppress this message, set the `printSuccess` property to `false`.

There is a number of handlers that one can use in a task, such as `osacompile()`
and `echo()` shown above. They are all documented in the ASMake's source file.


## Tasks with arguments

Tasks may accept arguments from the command line. Each task defines a
`shift()` handler to help processing a task's arguments: by calling `shift()`
you retrieve the next unprocessed argument, if any. Other than that, however,
it is the responsibility of the task to deal correctly with its arguments.

For example, you may define a `build` task accepting a parameter that
specifies the type of build:

    script build
      property parent : Task(me)
      set target to shift()
      if target is "dev" then
        echo("dev build")
      else if target is "production" then
        echo("production build")
      else
        echo("Default build")
      end if
    end script

You may run this task as follows:

    asmake build dev

You may also call this task without arguments:

    asmake build

In this case, `target` will be set to `missing value`.


## Tasks with dependencies

A task may depend on other tasks. For example, an `install` task may depend on a
`build` task. To specify dependencies, you simply run the dependent scripts
as needed. Although you might use the `run` handler for such purpose, currently
the recommended way is to invoke the `execute` handler, which has a single
optional parameter corresponding to the list (or an object that can be
coerced to a list) of the arguments for the task. For example:

    script build
      property parent : Task(me)
      (* ... *)
    end

    script install
      property parent : Task(me)
      tell build to execute -- Dependent task with no arguments
      -- run build -- equivalent to the above, but not recommended
      (* further commands to install the built product *)
    end

    script productionBuild
      property parent : Task(me)
      tell build to execute given arguments:"production" -- Dependent task with arguments
    end


## Private tasks

Sometimes it is useful to have tasks that are not called directly, but are used
only as dependencies for other tasks. You may define a task as “private”
by setting its `private` property to `true`:

    script PrivateTask
      property parent : Task(me)
      property private : true
      (* ... *)
    end

Private tasks are not shown by `asmake help` and cannot be invoked directly from
the command line, but they can be run from other tasks.


## ASMake options

Currently, ASMake has the following options:

- `--debug` or `-D`: enable debugging output.
- `--dry` or `-n`: do not really execute shell commands.
- `--verbose` or `-v`: be verbose.

Such options must be specified before the name of the task. For example:

    asmake --dry build


## License

Copyright (c) 2014–2015 Lifepillar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
