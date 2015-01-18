#!/usr/bin/osascript
use AppleScript version "2.4"
use scripting additions

property ASMake : missing value
property dir : missing value

on run argv
	set my dir to (folder of file (path to me) of application "Finder") as text
	set ASMake to run script (my dir & "ASMake.applescript") as alias Â
		with parameters {"__ASMAKE__LOAD__"}
	
	tasks() -- Register tasks at runtime to be able to inherit from source code
	
	script
		property parent : ASMake
		set my defaultTask to "test"
		continue run argv
	end script
	
	run the result
end run

on Task(t) -- Make Task() visible to nested scripts
	ASMake's Task(t)
end Task

on tasks()
	script api
		property parent : Task(me)
		property description : "Build the API documentation."
		property dir : "Documentation"
		
		owarn("Building the API with HeaderDoc requires OS X 10.10 (Xcode 6)")
		--Set LANG to get rid of warnings about missing default encoding
		shell for "env LANG=en_US.UTF-8 headerdoc2html" given options:{"-q", "-o", dir, "ASMake.applescript"}
		shell for "env LANG=en_US.UTF-8 gatherheaderdoc" given options:dir
		shell for "open" given options:(dir & "/ASMake_applescript/index.html")
	end script
	
	script clean
		property parent : Task(me)
		property description : "Remove any generated products."
		
		removeItems at glob({"**/*.scpt", "**/*.scptd"}) & {"build"} with forcing
	end script
	
	script clobber
		property parent : Task(me)
		property description : "Remove all temporary products."
		
		tell clean to exec:{}
		removeItem at "README.html" with forcing
	end script
	
	script build
		property parent : Task(me)
		property description : "Build ASMake."
		
		tell clean to exec:{}
		makeScriptBundle from "ASMake.applescript" at "build"
	end script
	
	script doc
		property parent : Task(me)
		property description : "Compile the README."
		
		shell for "markdown" given options:{"-o", "README.html", "README.md"}
	end script
	
	script install
		property parent : Task(me)
		property dir : POSIX path of Â
			((path to library folder from user domain) as text) & "Script Libraries"
		property description : "Install ASMake in" & space & dir & "."
		
		tell build to exec:{}
		
		set targetDir to joinPath(dir, "com.lifepillar")
		set targetPath to joinPath(targetDir, "ASMake.scptd")
		if pathExists(targetPath) then
			display alert Â
				"A version of ASMake is already installed." message targetPath & space & Â
				"exists. Overwrite?" as warning Â
				buttons {"Cancel", "OK"} Â
				default button "Cancel" cancel button "Cancel"
		end if
		
		moveItem at "build/ASMake.scptd" into targetDir with overwriting
		ohai("ASMake installed at" & space & targetPath)
	end script
	
	script test
		property parent : Task(me)
		property description : "Build and run tests."
		property printSuccess : false
		
		makeScriptBundle from "test/Test ASMake.applescript" at "test"
		set testSuite to load script POSIX file (my workingDirectory() & "/test/Test ASMake.scptd")
		run testSuite
	end script
	
	script versionTask
		property parent : Task(me)
		property name : "version"
		property synonyms : {"v"}
		property description : "Print ASMake's version and exit."
		property printSuccess : false
		
		set {n, v} to {name, version} of Â
			(run script POSIX file (workingDirectory() & "/src/ASMake.applescript") with parameters "__ASMAKE__LOAD__")
		ohai(n & space & "v" & v)
	end script
	
	script args_example
		property parent : Task(me)
		property name : "example/args"
		property description : "Print the task's arguments and exit."
		property printSuccess : false
		
		if my debug or my dry or my verbose then echo("ASMake options:")
		if my debug then ohai("Debug")
		if my dry then ohai("Dry run")
		if my verbose then ohai("Verbose")
		if my argv is not {} then echo("Task arguments:")
		repeat until my argv is {}
			ohai(shift())
		end repeat
	end script
end tasks
