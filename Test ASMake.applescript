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
end script -- Test task

script |Test command line parsing|
	property parent : TestSet(me)
	property parser : missing value
	property backslash : "\\"
	
	on setUp()
		set parser to a reference to ASMake's CommandLineParser
	end setUp
	
	script |Test setStream()|
		property parent : UnitTest(me)
		parser's setStream("abcde")
		assertEqual("abcde", parser's stream)
		assertEqual(5, parser's streamLength)
		assertEqual(1, parser's npos)
	end script
	
	script |Test getChar()|
		property parent : UnitTest(me)
		parser's setStream("a" & backslash & "'")
		assertEqual("a", parser's getChar())
		assertEqual(backslash, parser's getChar())
		assertEqual("'", parser's getChar())
		assertEqual(parser's EOS, parser's getChar())
		parser's setStream(backslash & backslash)
		assertEqual(backslash, parser's getChar())
		assertEqual(backslash, parser's getChar())
		assertEqual(parser's EOS, parser's getChar())
		assertEqual(parser's EOS, parser's getChar())
	end script
	
	script |Test nextChar() with empty stream|
		property parent : UnitTest(me)
		parser's setStream("")
		assertEqual(parser's EOS, parser's nextChar())
		assertEqual(parser's EOS, parser's nextChar())
	end script
	
	script |Test nextChar() with backslash|
		property parent : UnitTest(me)
		parser's setStream(backslash & backslash & backslash & space)
		assertEqual(backslash, parser's nextChar())
		assertEqual(space, parser's nextChar())
		assertEqual(parser's EOS, parser's nextChar())
	end script
	
	script |Test nextChar() with single-quoted string|
		property parent : UnitTest(me)
		parser's setStream("'" & backslash & space & backslash & quote & backslash & "'")
		assertEqual(backslash, parser's nextChar())
		assertEqual(space, parser's nextChar())
		assertEqual(backslash, parser's nextChar())
		assertEqual(quote, parser's nextChar())
		assertEqual(backslash, parser's nextChar())
		assertEqual(parser's EOS, parser's nextChar())
	end script
	
	script |Test nextChar() with double-quoted string|
		property parent : UnitTest(me)
		parser's setStream(quote & backslash & quote & backslash & backslash & backslash & space & quote)
		assertEqual(quote, parser's nextChar())
		assertEqual(parser's DOUBLE_QUOTED, parser's state)
		assertEqual(backslash, parser's nextChar())
		assertEqual(backslash, parser's nextChar())
		assertEqual(parser's DOUBLE_QUOTED, parser's state)
		assertEqual(space, parser's nextChar())
		assertEqual(parser's EOS, parser's nextChar())
	end script
	
	script |Test nextChar() with key and double-quoted value|
		property parent : UnitTest(me)
		parser's setStream("k =" & quote & "x y" & quote)
		assertEqual("k", parser's nextChar())
		assertEqual(space, parser's nextChar())
		assertEqual("=", parser's nextChar())
		assertEqual("x", parser's nextChar())
		assertEqual(space, parser's nextChar())
		assertEqual("y", parser's nextChar())
		assertEqual(parser's EOS, parser's nextChar())
	end script
	
	script |Test nextChar() with mixed quoting|
		property parent : UnitTest(me)
		parser's setStream("a" & quote & "'" & quote & "'" & quote & "'" & backslash & quote & backslash)
		assertEqual("a", parser's nextChar())
		assertEqual("'", parser's nextChar()) -- single quote between double quotes
		assertEqual(quote, parser's nextChar()) -- double quote between single quotes
		assertEqual(quote, parser's nextChar()) -- escaped double quote
		assertEqual(parser's EOS, parser's nextChar()) -- The single backslash at the end is ignored
	end script
	
	script |Test resetStream()|
		property parent : UnitTest(me)
		script Wrapper
			parser's resetStream()
		end script
		shouldNotRaise({}, Wrapper, "resetStream() should not raise.")
		parser's setStream("abc")
		parser's nextChar()
		parser's nextChar()
		parser's resetStream()
		assertEqual(1, parser's npos)
		assertEqual(parser's UNQUOTED, parser's state)
	end script
	
	script |Test nextToken() with no escaping|
		property parent : UnitTest(me)
		parser's setStream("--opt cmd key=value")
		assertEqual(1, parser's npos)
		assertEqual("--opt", parser's nextToken())
		assertEqual("cmd", parser's nextToken())
		assertEqual("key", parser's nextToken())
		assertEqual("=", parser's nextToken())
		assertEqual("value", parser's nextToken())
		assertEqual(missing value, parser's nextToken())
		assertEqual(missing value, parser's nextToken())
	end script
	
	script |Test nextToken() with double-quoted string|
		property parent : UnitTest(me)
		parser's setStream("key =" & quote & "val ue" & quote)
		assertEqual("key", parser's nextToken())
		assertEqual("=", parser's nextToken())
		assertEqual("val ue", parser's nextToken())
		assertEqual(missing value, parser's nextToken())
		assertEqual(parser's UNQUOTED, parser's state)
	end script
	
end script -- Test command line parsing
