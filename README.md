# ASMake: an AppleScript build library

TODO

## Sample makefile

If you use OS X 10.9 or later (AppleScript 2.3 or later), then your makefile
should look like this:

    use AppleScript version "2.3"
    use scripting additions
    use ASMake : script "ASMake"
    property parent : ASMake

    on run {action}
      runTask(action)
    end run

    (* Tasks go here *)

On the other hand, if you need compatibility with older systems, your makefile
should look like this:

    property parent : ¬
      load script (((path to library folder from user domain) as text) ¬
        & "Script Libraries:ASMake.scpt") as alias

    (* Tasks go here *)

A task is a script that inherits from `Task(me)`. For example, the following
task is used to compile `ASMake.applescript` into a run-only script:

    script build
      property parent : Task(me)
      property description : "Build ASMake."
      osacompile("ASMake", "scpt", {"-x"})
    end script

TODO
