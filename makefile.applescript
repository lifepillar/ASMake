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
		--set my defaultTask to "test/run"
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
		property description : "Build the API documentation"
		property dir : "Documentation"
		
		ohai("Running HeaderDoc, please wait...")
		--Set LANG to get rid of warnings about missing default encoding
		shell for "env LANG=en_US.UTF-8 headerdoc2html" given options:{"-q", "-o", dir, "ASMake.applescript"}
		shell for "env LANG=en_US.UTF-8 gatherheaderdoc" given options:dir
	end script
	
	script clean
		property parent : Task(me)
		property description : "Remove any generated products"
		
		removeItems at glob({"**/*.scpt", "**/*.scptd"}) & {"build"} with forcing
	end script
	
	script clobber
		property parent : Task(me)
		property description : "Remove all temporary products"
		
		tell clean to exec:{}
		removeItems at {"README.html", "example/SampleApp.app"} with forcing
	end script
	
	script build
		property parent : Task(me)
		property description : "Build ASMake"
		
		makeScriptBundle from "ASMake.applescript" at "build" with overwriting
	end script
	
	script doc
		property parent : Task(me)
		property description : "Compile the README"
		
		shell for "markdown" given options:{"-o", "README.html", "README.md"}
	end script
	
	script install
		property parent : Task(me)
		property dir : my parent's joinPath(path to library folder from user domain, "Script Libraries")
		property description : "Install ASMake in" & space & dir
		
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
		
		copyItem at "build/ASMake.scptd" into targetDir with overwriting
		ohai("ASMake installed at" & space & targetPath)
	end script
	
	script BuildTests
		property parent : Task(me)
		property name : "test/build"
		property description : "Build tests, but do not run them"
		
		makeScriptBundle from "test/Test ASMake.applescript" at "test" with overwriting
	end script
	
	script uninstall
		property parent : Task(me)
		property dir : my parent's joinPath(path to library folder from user domain, "Script Libraries")
		property description : "Remove ASMake from" & space & dir
		
		set targetPath to joinPath(dir, "com.lifepillar/ASMake.scptd")
		if pathExists(targetPath) then
			removeItem at targetPath
		end if
		ohai(targetPath & space & "deleted.")
	end script
	
	script RunTests
		property parent : Task(me)
		property name : "test/run"
		property description : "Build and run tests"
		property printSuccess : false
		
		tell BuildTests to exec:{}
		ohai("Tests built")
		owarn("Due to bugs in OS X Yosemite, tests cannot be run from the makefile.")
		owarn("Please run the tests with `osascript 'test/Test ASMake.scptd'`")
		-- This method causes a segfault unless ASMake is installed in a shared location:
		--local t
		--set t to load script POSIX file (workingDirectory() & "/test/Test ASMake.scptd")
		--run t
		-- This method does not output anything (and needs ASMake installed):
		--run script POSIX file (workingDirectory() & "/test/Test ASMake.applescript")
	end script
	
	script VersionTask
		property parent : Task(me)
		property name : "version"
		property description : "Print ASMake's version and exit"
		property printSuccess : false
		
		set {n, v} to {name, version} of Â
			(run script POSIX file (joinPath(workingDirectory(), "ASMake.applescript")) Â
				with parameters "__ASMAKE__LOAD__")
		ohai(n & space & "v" & v)
	end script
	
	script ArgsExample
		property parent : Task(me)
		property name : "example/args"
		property description : "Print the task's arguments and exit"
		property synonyms : {"exarg", "exargs"}
		property printSuccess : false
		
		if my debug or my dry or my verbose then log "ASMake options:"
		if my debug then ohai("Debug")
		if my dry then ohai("Dry run")
		if my verbose then ohai("Verbose")
		if my argv is not {} then log "Task arguments:"
		repeat until my argv is {}
			ohai(shift())
		end repeat
	end script
	
	script EmptyScriptBundleExample
		property parent : Task(me)
		property name : "example/bundle"
		property description : "Create an empty script bundle"
		emptyScriptBundle("example/Empty.scptd")
	end script
	
	script SampleAppExample
		property parent : Task(me)
		property name : "example/app"
		property description : "Build the sample app in the example/ folder"
		property synonyms : {"exapp"}
		makeApplication from "example/SampleApp/SampleApp.applescript" at "example" with overwriting
	end script
end tasks
