(*!
	@header
	@abstract
		Unit tests for ASMake.
	@charset macintosh
*)
use AppleScript version "2.3"
use script "ASUnit" version "1.2.2"
use scripting additions
property parent : script "ASUnit"
property suite : makeTestSuite("Suite of unit tests for ASMake")
property ASMake : missing value -- The variable holding the script to be tested

set ASMake to run script Â
	((folder of file (path to me) of application "Finder" as text) Â
		& "ASMake.applescript") as alias

autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

script |ASMake core|
	property parent : TestSet(me)
	
	script |Check script name, id|
		property parent : UnitTest(me)
		assertInstanceOf(script, ASMake)
		assertEqual("ASMake", ASMake's name)
		assertEqual("com.lifepillar.ASMake", ASMake's id)
	end script
	
	script |Check script data structures|
		assertInstanceOf(script, ASMake's Stdout)
		assertInstanceOf(list, ASMake's tasks)
		assertEqual({}, ASMake's tasks)
		assertEqual(missing value, pwd)
	end script
	
end script -- ASMake core

script |Test Tasks|
	property parent : TestSet(me)
	property aTask : missing value
	
	on setUp()
		script emptyTask
			property parent : ASMake's Task(me)
		end script
		set aTask to the result
	end setUp
	
	script |Empty task|
		property parent : UnitTest(me)
		assertInstanceOf("Task", aTask)
		assertEqual("emptyTask", aTask's name)
		assertEqual({}, aTask's synonyms)
		ok(aTask's printSuccess)
	end script
end script
