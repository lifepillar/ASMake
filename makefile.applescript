#!/usr/bin/osascript
(* Do not compile me into a .scpt file, run me from source! *)

-- Load ASMake from source at compile time
on _setpath()
	if current application's id is "com.apple.ScriptEditor2" then
		(folder of file (document 1's path as POSIX file) of application "Finder") as text
	else if current application's name is in {"osacompile", "osascript"} then
		((POSIX file (do shell script "pwd")) as text) & ":"
	else
		error "This file can be compiled only with AppleScript Editor or osacompile"
	end if
end _setpath
property parent : run script (_setpath() & "ASMake.applescript") as alias Â
	with parameters {"__ASMAKE__LOAD__"}

------------------------------------------------------------------
-- Tasks
------------------------------------------------------------------

script api
	property parent : Task(me)
	property description : "Build the API documentation."
	property dir : "Documentation"
	
	owarn("Building the API with HeaderDoc requires OS X 10.10 (Xcode 6)")
	--Set LANG to get rid of warnings about missing default encoding
	sh("env LANG=en_US.UTF-8 headerdoc2html", {"-q", "-o", dir, "ASMake.applescript"})
	sh("env LANG=en_US.UTF-8 gatherheaderdoc", dir)
	sh("open", dir & "/ASMake_applescript/index.html")
end script

script build
	property parent : Task(me)
	property description : "Build ASMake."
	osacompile("ASMake", "scpt", {"-x"})
end script

script clean
	property parent : Task(me)
	property description : "Remove any generated products."
	rm({"*.scpt", "*.scptd"})
end script

script clobber
	property parent : Task(me)
	property description : "Remove all temporary products."
	run clean
	rm({"Documentation", "README.html"})
end script

script doc
	property parent : Task(me)
	property description : "Compile the README."
	sh("markdown", {"-o", "README.html", "README.md"})
end script

script install
	property parent : Task(me)
	property dir : POSIX path of Â
		((path to library folder from user domain) as text) & "Script Libraries"
	property description : "Install ASMake in" & space & dir & "."
	run build
	mkdir(dir)
	cp("ASMake.scpt", dir)
	ohai("ASMake installed in" & space & (dir as text))
end script

script test
	property parent : Task(me)
	property description : "Run tests."
	property printSuccess : false
	run script "Test ASMake.applescript"
end script

script versionTask
	property parent : Task(me)
	property name : "version"
	property synonyms : {"v"}
	property description : "Print ASMake's version and exit."
	property printSuccess : false
	set {n, v} to {name, version} of Â
		(run script POSIX file (my PWD & "/ASMake.applescript") with parameters "__ASMAKE__LOAD__")
	ohai(n & space & "v" & v)
end script
