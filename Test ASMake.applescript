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
		property parent : UnitTest(me)
		assertInstanceOf(script, ASMake's Stdout)
		assertInstanceOf("Task", ASMake's TaskBase)
		assertKindOf(script, ASMake's TaskBase)
		assertInstanceOf(script, ASMake's TaskArguments)
		assertInstanceOf(script, ASMake's CommandLineParser)
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

script |Test lexical analyzer|
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
		assertEqual(parser's NO_TOKEN, parser's nextToken())
		assertEqual(parser's NO_TOKEN, parser's nextToken())
	end script
	
	script |Test nextToken() with double-quoted string|
		property parent : UnitTest(me)
		parser's setStream("key =" & quote & "val ue" & quote)
		assertEqual("key", parser's nextToken())
		assertEqual("=", parser's nextToken())
		assertEqual("val ue", parser's nextToken())
		assertEqual(parser's NO_TOKEN, parser's nextToken())
		assertEqual(parser's UNQUOTED, parser's state)
	end script
	
	script |Test nextToken() with one-letter tokens|
		property parent : UnitTest(me)
		parser's setStream("x")
		assertEqual("x", parser's nextToken())
		assertEqual(parser's NO_TOKEN, parser's nextToken())
		parser's setStream("y.a = b")
		assertEqual("y", parser's nextToken())
		assertEqual("a", parser's nextToken())
		assertEqual("=", parser's nextToken())
		assertEqual("b", parser's nextToken())
		assertEqual(parser's NO_TOKEN, parser's nextToken())
	end script
	
end script -- Test command line parsing

script |Test parser|
	property parent : TestSet(me)
	property parser : missing value
	property argObj : missing value
	property backslash : "\\"
	
	on setUp()
		set parser to a reference to ASMake's CommandLineParser
		set argObj to a reference to ASMake's TaskArguments
		argObj's clear()
	end setUp
	
	
	script |Test simple parsing|
		property parent : UnitTest(me)
		parser's parse("--opt1 -o2 cmd key= value")
		assertEqual("cmd", argObj's command)
		assertEqual({"--opt1", "-o2"}, argObj's options)
		assertEqual({"key"}, argObj's keys)
		assertEqual({"value"}, argObj's values)
	end script
	
	script |Test parse command with option and task name|
		property parent : UnitTest(me)
		parser's parse("-n install")
		assertEqual("install", argObj's command)
		assertEqual({"-n"}, argObj's options)
		assertEqual({}, argObj's keys)
		assertEqual({}, argObj's values)
	end script
	
	script |Test parsing quoted string|
		property parent : UnitTest(me)
		parser's parse("taskname k1=" & quote & backslash & quote & "=" & quote & "'a b'c")
		assertEqual("taskname", argObj's command)
		assertEqual({}, argObj's options)
		assertEqual({"k1"}, argObj's keys)
		assertEqual({quote & "=a bc"}, argObj's values)
	end script
	
	script |Parse and retrieve arguments|
		property parent : UnitTest(me)
		parser's parse("--opt1 -o2 taskname k1=v1 k2=v2")
		assertEqual("v2", argObj's fetch("k2", "Not found"))
		assertEqual("Not found", argObj's fetch("v2", "Not found"))
		assertEqual("v1", argObj's fetchAndDelete("k1", "Not found"))
		assertEqual("Not found", argObj's fetchAndDelete("k1", "Not found"))
		assertEqual("v2", argObj's fetchAndDelete("k2", "Not found"))
		assertEqual("Not found", argObj's fetchAndDelete("k2", "Not found"))
	end script
end script

script |Test TaskBase|
	property parent : TestSet(me)
	property tb : missing value
	
	on setUp()
		set opts to {"--dry"}
		set ASMake's TaskArguments's options to opts
		set tb to a reference to ASMake's TaskBase
		set tb's PWD to POSIX path of ((folder of file (path to me) of application "Finder") as alias)
		set tb's arguments to ASMake's TaskArguments
	end setUp
	
	script |Test normalizePaths()|
		property parent : UnitTest(me)
		set res to POSIX path of (path to library folder from user domain as alias)
		assertEqual({res}, tb's normalizePaths(path to library folder from user domain as alias))
		set res to POSIX path of (path to library folder from user domain as text)
		assertEqual({res}, tb's normalizePaths(path to library folder from user domain as text))
	end script
	
	script |Test normalizePaths() with POSIX absolute path|
		property parent : UnitTest(me)
		set res to "/a/b/c"
		set v to item 1 of tb's normalizePaths(res)
		assertEqual(res, v)
	end script
	
	script |Test glob()|
		property parent : UnitTest(me)
		assertEqual({"ASMake.applescript"}, tb's glob("ASM*.applescript"))
		assertEqual({"I/dont/exist/foobar"}, tb's glob("I/dont/exist/foobar"))
	end script
	
	script |Test sh()|
		property parent : UnitTest(me)
		set expected to "cmd" & space & "'-x' 2>&1"
		assertEqual(expected, tb's sh("cmd", {"-x", {redirect:"2>&1"}}))
	end script
	
	script |Test absolutePath()|
		property parent : UnitTest(me)
		assertEqual(tb's PWD & "a/b/c", tb's absolutePath("a/b/c"))
		assertEqual(tb's PWD & "a/b/c", tb's absolutePath(":a:b:c"))
		assertKindOf(text, tb's absolutePath("/a/b/c"))
		assertEqual("/a/b/c/", tb's absolutePath("a:b:c:"))
	end script
	
	script |Test absolutePath() with absolute POSIX path|
		property parent : UnitTest(me)
		assertEqual("/a/b/c", tb's absolutePath("/a/b/c"))
	end script
	
	
	script |Test basename()|
		property parent : UnitTest(me)
		assertEqual("c", tb's basename("a/b/c"))
		assertEqual("c", tb's basename("/a/b/c"))
		assertEqual("c", tb's basename("a:b:c"))
		assertEqual("c", tb's basename("a:b:c:"))
	end script
	
	script |Test cp()|
		property parent : UnitTest(me)
		set res to tb's cp({"AS*.applescript", POSIX file "doc/foo.txt", "examples/bar"}, "tmp/cp")
		set expected to "/bin/cp" & space & quoted form of "-r" & space & Â
			quoted form of "ASMake.applescript" & space & Â
			quoted form of "doc/foo.txt" & space & Â
			quoted form of "examples/bar" & space & Â
			quoted form of "tmp/cp"
		assertEqual(expected, res)
	end script
	
	script |Test dirname()|
		property parent : UnitTest(me)
		assertEqual("a/b", tb's dirname("a/b/c"))
		assertEqual("/a/b", tb's dirname("/a/b/c"))
		assertEqual("/a/b", tb's dirname("a:b:c"))
		assertEqual("/a/b", tb's dirname("a:b:c:"))
	end script
	
	script |Test ditto()|
		property parent : UnitTest(me)
		set res to tb's ditto({"AS*.applescript", POSIX file "doc/foo.txt", "examples/bar"}, "tmp/ditto", {"-X", "--rsrc"})
		set expected to "/usr/bin/ditto" & space & Â
			quoted form of "-X" & space & Â
			quoted form of "--rsrc" & space & Â
			quoted form of "ASMake.applescript" & space & Â
			quoted form of "doc/foo.txt" & space & Â
			quoted form of "examples/bar" & space & Â
			quoted form of "tmp/ditto"
		assertEqual(expected, res)
	end script
	
	script |Test joinPath() with text arguments|
		property parent : UnitTest(me)
		assertEqual("abc/defg", tb's joinPath("abc", "defg"))
		assertEqual("abc/defg", tb's joinPath("abc/", "defg"))
		assertEqual("abc/defg/", tb's joinPath("abc/", "defg/"))
		assertEqual("/abc/defg", tb's joinPath("abc:", "defg"))
		assertEqual("abc/defg", tb's joinPath(":abc:", "defg"))
		assertEqual("abc/defg", tb's joinPath(":abc:", ":defg"))
		assertEqual("abc/defg/", tb's joinPath(":abc:", ":defg:"))
	end script
	
	script |Test joinPath() with aliases|
		property parent : UnitTest(me)
		set p to path to library folder from user domain as alias
		assertEqual(POSIX path of p & "Scripts", tb's joinPath(p, "Scripts"))
		assertEqual(POSIX path of p & "Scripts", tb's joinPath(p, ":Scripts"))
	end script
	
	script |Test mkdir()|
		property parent : UnitTest(me)
		set res to tb's mkdir({"a", "b/c", POSIX file "d/e"})
		set expected to "/bin/mkdir" & space & quoted form of "-p" & space & Â
			quoted form of "a" & space & Â
			quoted form of "b/c" & space & Â
			quoted form of "d/e"
		assertEqual(expected, res)
		set expected to "/bin/mkdir '-p' 'foo bar'"
		assertEqual(expected, tb's mkdir("foo bar"))
	end script
	
	script |Test mv()|
		property parent : UnitTest(me)
		set res to tb's mv({"foo", "examples/bar"}, "tmp/mv")
		set expected to "/bin/mv" & space & Â
			quoted form of "foo" & space & Â
			quoted form of "examples/bar" & space & Â
			quoted form of "tmp/mv"
		assertEqual(expected, res)
	end script
	
	script |Test rm()|
		property parent : UnitTest(me)
		set res to tb's rm({"a", "b/c", POSIX file "d/e"})
		set expected to "/bin/rm" & space & quoted form of "-fr" & space & Â
			quoted form of "a" & space & Â
			quoted form of "b/c" & space & Â
			quoted form of "d/e"
		assertEqual(expected, res)
	end script
	
	script |Test chomp()|
		property parent : UnitTest(me)
		assertEqual("", tb's chomp(""))
		assertEqual("", tb's chomp(return))
		assertEqual("", tb's chomp(linefeed))
		assertEqual("", tb's chomp(return & linefeed))
		assertEqual(linefeed, tb's chomp(linefeed & return))
		assertEqual("z", tb's chomp("z" & linefeed))
		assertEqual("z", tb's chomp("z" & return))
		assertEqual("z", tb's chomp("z" & return & linefeed))
		assertEqual("yz", tb's chomp("yz" & linefeed))
		assertEqual("yz", tb's chomp("yz" & return))
		assertEqual("yz", tb's chomp("yz" & return & linefeed))
		assertEqual("yz", tb's chomp("yz"))
		assertEqual("xywz", tb's chomp("xywz"))
	end script
	
	script |Test osacompile()|
		property parent : UnitTest(me)
		set expected to "/usr/bin/osacompile '-o' 'ASMake.scpt' '-x' 'ASMake.applescript'"
		assertEqual(expected, tb's osacompile("ASMake", "scpt", {"-x"}))
	end script
	
	script |Test splitPath()|
		property parent : UnitTest(me)
		assertEqual({"a/b", "c"}, tb's splitPath("a/b/c"))
		assertEqual({"/a/b", "c"}, tb's splitPath("/a/b/c"))
		assertEqual({"/a/b", "c"}, tb's splitPath("a:b:c"))
		assertEqual({"/a/b", "c"}, tb's splitPath("a:b:c:"))
	end script
	
	script |Test splitPath() with a single component|
		property parent : UnitTest(me)
		assertEqual({"", "c"}, tb's splitPath("c"))
	end script
	
	script |Test symlink()|
		property parent : UnitTest(me)
		set expected to "/bin/ln '-s' 'foo' 'bar'"
		assertEqual(expected, tb's symlink("foo", "bar"))
	end script
	
	script |Test which()|
		property parent : UnitTest(me)
		set ASMake's TaskArguments's options to {} -- remove --dry
		assertNil(tb's which("A-command-that-does-not-exist"))
		assertEqual("/bin/bash", tb's which("bash"))
	end script
end script
