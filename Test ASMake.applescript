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
		& "ASMake.applescript") as alias Â
	with parameters {"__ASMAKE__LOAD__"}

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

script |Test empty task|
	property parent : TestSet(me)
	property aTask : missing value
	
	on setUp()
		script emptyTask
			property parent : ASMake's Task(me)
		end script
		set aTask to the result
	end setUp
	
	script |Task's class|
		property parent : UnitTest(me)
		assertInstanceOf("Task", aTask)
	end script
	
	script |Task's name|
		property parent : UnitTest(me)
		assertEqual("emptyTask", aTask's name)
	end script
	
	script |Task's synonyms|
		property parent : UnitTest(me)
		assertEqual({}, aTask's synonyms)
	end script
	
	script |Task's printSuccess|
		property parent : UnitTest(me)
		ok(aTask's printSuccess)
	end script
end script

script |Test task|
	property parent : TestSet(me)
	property aTask : missing value
	
	on setUp()
		script
			property parent : ASMake's Task(me)
			property name : "myTask"
			property synonyms : {"yourTask"}
			property printSuccess : false
		end script
		set aTask to the result
	end setUp
	
	script |Task's class|
		property parent : UnitTest(me)
		assertInstanceOf("Task", aTask)
	end script
	
	script |Task's name|
		property parent : UnitTest(me)
		assertEqual("myTask", aTask's name)
	end script
	
	script |Task's synonyms|
		property parent : UnitTest(me)
		assertEqual({"yourTask"}, aTask's synonyms)
	end script
	
	script |Task's printSuccess|
		property parent : UnitTest(me)
		notOk(aTask's printSuccess)
	end script
end script
