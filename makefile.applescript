#!/usr/bin/osascript
use AppleScript version "2.4"
use scripting additions

property ASMake : missing value

on run argv
	set ASMake to run script Â
		(((folder of file (path to me) of application "Finder") as text) & "ASMake.applescript") as alias Â
		with parameters {"__ASMAKE__LOAD__"}
	
	tasks() -- Register tasks at runtime to be able to inherit from source code
	
	tell ASMake
		set taskOptions to its CommandLine's parse(argv)
		runTask(taskOptions)
	end tell
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
	
	script build
		property parent : Task(me)
		property description : "Build ASMake."
		makeScriptBundle from "ASMake.applescript"
	end script
	
	script clean
		property parent : Task(me)
		property description : "Remove any generated products."
		rm_f(glob({"*.scpt", "*.scptd"}))
	end script
	
	script clobber
		property parent : Task(me)
		property description : "Remove all temporary products."
		run clean
		rm_f({"Documentation", "README.html"})
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
		rm_f(joinPath(dir, "ASMake.scptd"))
		cp("build/ASMake.scptd", joinPath(dir, "ASMake.scptd"))
		
		ohai("ASMake installed in" & space & (dir as text))
	end script
	
	script test
		property parent : Task(me)
		property description : "Run tests."
		property printSuccess : false
		osacompile from "Test ASMake"
		set testSuite to load script POSIX file (my workingDirectory() & "/Test ASMake.scpt")
		run testSuite
	end script
	
	script versionTask
		property parent : Task(me)
		property name : "version"
		property synonyms : {"v"}
		property description : "Print ASMake's version and exit."
		property printSuccess : false
		set {n, v} to {name, version} of Â
			(run script POSIX file (my workingDirectory() & "/ASMake.applescript") with parameters "__ASMAKE__LOAD__")
		ohai(n & space & "v" & v)
	end script
	
	script args
		property parent : Task(me)
		property description : "Print the task's arguments and exit."
		property printSuccess : false
		
		repeat until my argv is {}
			ohai(shift())
		end repeat
	end script
end tasks
