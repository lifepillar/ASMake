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

Tasks are defined in an executable script conventionally called `makefile.applescript`
(the script can be named as you like, but this is the convention I have adopted).
To make the script executable, open the terminal and type:

    chmod +x makefile.applescript

inside your project directory.

The general structure of a makefile is as follows:

    #!/usr/bin/osascript
    use AppleScript version "2.4"
    use scripting additions
    use ASMake : script "ASMake"
    property parent : ASMake

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


## Tasks with dependencies

A task may depend on other tasks. For example, an `install` task may depend on a
`build` task. To specify dependencies, simply run the dependent scripts as needed.
For example:

    script build
      property parent : Task(me)
      (* ... *)
    end

    script install
      property parent : Task(me)
      run build -- Dependent task
      (* other commands *)
    end


## Tasks with arguments

Tasks may accept arguments from the command line. The arguments are automatically
made available to every task through their `arguments` property, whose value is the `TaskArguments`
script object defined in `ASMake.applescript`. The `TaskArguments` script defines a
`shift()` handler to help processing the arguments (see the source code for the details),
but other than that it is the responsibility of the task to deal correctly with its arguments.

For example, you may define a `build` task that accepts a parameter that
specifies the type of build:

    script build
      property parent : Task(me)
      set tgt to my arguments's shift()
      if tgt is "dev" then
        echo("dev build")
      else if tgt is "production" then
        echo("production build")
      else
        echo("Default build")
      end if
    end script

For example, you may run this task as follows:

    asmake build dev

You may also call this task without arguments:

    asmake build

In this case, the `tgt` variable will be `missing value`.


## Private tasks

Sometimes it is useful to have tasks that are not called directly, but are used
only as dependencies for other tasks. You may define a task as private by setting
its `private` property to `true`:

    script PrivateTask
      property private : true
      property parent : Task(me)
      (* ... *)
    end

Note that the order in which the properties are specified is important: you must
put the `private` property _before_ the `parent` property, otherwise it will be
ignored.

Private tasks are not shown by `asmake help`.


## ASMake options

Currently, ASMake has the following options:

- `--dry` or `-n`: do not really execute shell commands.
- `--verbose` or `-v`: be verbose.

Unknown options are silently ignored.
Options are specified between `asmake` and the name of the task. For example:

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
