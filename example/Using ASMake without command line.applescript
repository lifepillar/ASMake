(*
	This script shows how to use ASMake in a script run from Script Editor,
	or from the script menu, or whatever.
*)

use AppleScript version "2.4"
use scripting additions

property ASMake : script "com.lifepillar/ASMake"
property parent : ASMake's TaskBase

-- Here you have the full power of ASMake at your disposal!

on alert(descr, msg)
	display alert descr message msg as informational Â
		buttons {"Cancel", "OK"} default button "OK" cancel button "Cancel"
end alert

alert("You may get the working directory:", workingDirectory())
set p to choose file with prompt "You may easily work with paths. Choose a file:"
alert("Last path component:", basename(p))
alert("Parent:", parentDirectory(p))
alert("Path components:", join(pathComponents(p), return))
alert("You may join and split lists:", join(split("A sentence split and recomposed", space), " - "))
alert("And much more!", "You may move, copy and delete files and folders, run shell commands, build applications from source, etc.." & return & return & "Read the documentation.")

return
