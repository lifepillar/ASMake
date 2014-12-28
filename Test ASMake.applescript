(*!
	@header
	@abstract
		Unit tests for ASMake.
	@charset macintosh
*)
on _wd()
	if current application's id is "com.apple.ScriptEditor2" or Â
		current application's name starts with "Script Debugger" then
		(folder of file (document 1's path as POSIX file) of application "Finder") as text
	else if current application's name is in {"osacompile", "osascript"} then
		((POSIX file (do shell script "pwd")) as text) & ":"
	else
		error "This file cannot be compiled with this application: " & current application's name
	end if
end _wd

property TOPLEVEL : me
-- We assume that either this script is run from source, or it is run
-- from the same directory where it is compiled.
property workingDir : _wd()
-- Run ASMake from source at compile time
property ASMakePath : _wd() & "ASMake.applescript"
property ASMake : run script (ASMakePath as alias) with parameters {"__ASMAKE__LOAD__"}

use AppleScript version "2.4"
use scripting additions
use ASUnit : script "ASUnit" version "1.2.3"
property parent : ASUnit
property suite : makeTestSuite("Suite of unit tests for ASMake")

log "Testing ASMake v" & ASMake's version
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

###################################################################################
script test_set_core_asmake
	property name : "Core ASMake"
	property parent : TestSet(me)
	
	---------------------------------------------------------------------------------
	script test_asmake_class
		property name : "Check ASMake's class"
		property parent : UnitTest(me)
		assertInstanceOf(script, ASMake)
	end script
	
	---------------------------------------------------------------------------------
	script test_asmake_name
		property name : "Check ASMake's name"
		property parent : UnitTest(me)
		assertEqual("ASMake", ASMake's name)
	end script
	
	---------------------------------------------------------------------------------
	script test_asmake_id
		property name : "Check ASMake's id"
		property parent : UnitTest(me)
		assertEqual("com.lifepillar.ASMake", ASMake's id)
	end script
	
	---------------------------------------------------------------------------------
	script test_asmake_data_structures
		property name : "Check ASMake's data structures"
		property parent : UnitTest(me)
		assertInstanceOf(script, ASMake's Stdout)
		assertInstanceOf("Task", ASMake's TaskBase)
		assertKindOf(script, ASMake's TaskBase)
		assertInstanceOf(script, ASMake's TaskArguments)
	end script
end script -- test_set_core_asmake


###################################################################################
script test_set_empty_task
	property name : "Empty task"
	property parent : TestSet(me)
	property aTask : missing value
	
	on setUp()
		script
			property name : "EmptyTask"
			property parent : ASMake's Task(me)
		end script
		set aTask to the result
	end setUp
	
	---------------------------------------------------------------------------------
	script test_task_class
		property name : "Task's class"
		property parent : UnitTest(me)
		assertInstanceOf("Task", aTask)
	end script
	
	---------------------------------------------------------------------------------
	script test_task_name
		property name : "Task's name"
		property parent : UnitTest(me)
		assertEqual("EmptyTask", aTask's name)
	end script
	
	---------------------------------------------------------------------------------
	script test_task_synonyms
		property name : "Task's synonyms"
		property parent : UnitTest(me)
		assertEqual({}, aTask's synonyms)
	end script
	
	---------------------------------------------------------------------------------
	script test_task_printSuccess
		property name : "Task's printSuccess"
		property parent : UnitTest(me)
		ok(aTask's printSuccess)
	end script
end script -- test_set_empty_task


###################################################################################
script test_set_non_empty_task
	property name : "Set task properties"
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
	
	---------------------------------------------------------------------------------
	script test_task_class
		property name : "Task's class"
		property parent : UnitTest(me)
		assertInstanceOf("Task", aTask)
	end script
	
	---------------------------------------------------------------------------------
	script test_task_name
		property name : "Task's name"
		property parent : UnitTest(me)
		assertEqual("myTask", aTask's name)
	end script
	
	---------------------------------------------------------------------------------
	script test_task_synonyms
		property name : "Task's synonyms"
		property parent : UnitTest(me)
		assertEqual({"yourTask"}, aTask's synonyms)
	end script
	
	---------------------------------------------------------------------------------
	script test_task_printSuccess
		property name : "Task's printSuccess"
		property parent : UnitTest(me)
		notOk(aTask's printSuccess)
	end script
end script -- test_set_non_empty_task


on BaseTestSet(aTestSet)
	script
		property parent : TestSet(aTestSet)
		
		on setUp()
			set ASMake's TaskArguments's options to {"--dry"}
			set my tb to a reference to ASMake's TaskBase
			set my tb's PWD to POSIX path of TOPLEVEL's workingDir
			set my tb's arguments to ASMake's TaskArguments
		end setUp
	end script
end BaseTestSet


###################################################################################
script test_set_taskbase
	property name : "TaskBase"
	property parent : BaseTestSet(me)
	property tb : missing value
	
	---------------------------------------------------------------------------------
	script test_posix_absolute_path_no_slash
		property name : "posixPath() with absolute POSIX path without trailing slash"
		property parent : UnitTest(me)
		assertEqual("/a/b/c", tb's posixPath("/a/b/c"))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_relative_path_no_slash
		property name : "posixPath() with relative POSIX path without trailing slash"
		property parent : UnitTest(me)
		assertEqual("a/b/c", tb's posixPath("a/b/c"))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_absolute_path_with_slash
		property name : "posixPath() with absolute POSIX path with trailing slash"
		property parent : UnitTest(me)
		assertEqual("/a/b/c/", tb's posixPath("/a/b/c/"))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_relative_path_with_slash
		property name : "posixPath() with relative POSIX path with trailing slash"
		property parent : UnitTest(me)
		assertEqual("a/b/c/", tb's posixPath("a/b/c/"))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_absolute_hfs_path_no_colon
		property name : "posixPath() with absolute HFS path without trailing colon"
		property parent : UnitTest(me)
		assertEqual("/a/b/c", tb's posixPath("a:b:c"))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_absolute_hfs_path_with_colon
		property name : "posixPath() with absolute HFS path with trailing colon"
		property parent : UnitTest(me)
		assertEqual("/a/b/c/", tb's posixPath("a:b:c:"))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_relative_hfs_path_no_colon
		property name : "posixPath() with relative POSIX path without trailing colon"
		property parent : UnitTest(me)
		assertEqual("a/b/c", tb's posixPath(":a:b:c"))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_relative_hfs_path_with_colon
		property name : "posixPath() with relative HFS path with trailing colon"
		property parent : UnitTest(me)
		assertEqual("a/b/c/", tb's posixPath(":a:b:c:"))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_alias
		property name : "posixPath() with alias"
		property parent : UnitTest(me)
		set res to POSIX path of (path to library folder from user domain as alias)
		assertEqual(res, tb's posixPath(path to library folder from user domain as alias))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_file
		property name : "posixPath() with file"
		property parent : UnitTest(me)
		assertEqual("/System/Library", tb's posixPath(POSIX file "/System/Library"))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_reference
		property name : "posixPath() with reference to a POSIX path"
		property parent : UnitTest(me)
		assertEqual("a/b/c", tb's posixPath(a reference to "a/b/c"))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_paths
		property name : "posixPaths()"
		property parent : UnitTest(me)
		set res to POSIX path of (path to library folder from user domain as alias)
		assertEqual({res}, tb's posixPaths(path to library folder from user domain as alias))
		set res to POSIX path of (path to library folder from user domain as text)
		assertEqual({res}, tb's posixPaths(path to library folder from user domain as text))
	end script
	
	---------------------------------------------------------------------------------
	script test_posix_paths_absolute_path
		property name : "posixPaths() with POSIX absolute path"
		property parent : UnitTest(me)
		set res to "/a/b/c"
		set v to item 1 of tb's posixPaths(res)
		assertEqual(res, v)
	end script
	
	---------------------------------------------------------------------------------
	script test_glob
		property name : "glob()"
		property parent : UnitTest(me)
		assertInstanceOf(list, tb's glob({"*.scpt", "*.scptd"}))
		assertInstanceOf(list, tb's glob("abc.scpt"))
		assert(tb's glob({"*.applescript"})'s length > 2, "Once there was a bug causing glob() to collapse its arguments")
		assertEqual({"ASMake.applescript"}, tb's glob("ASM*.applescript"))
		assertEqual({"I/dont/exist/foobar"}, tb's glob("I/dont/exist/foobar"))
	end script
	
	---------------------------------------------------------------------------------
	script test_shell
		property name : "shell()"
		property parent : UnitTest(me)
		set expected to "cmd" & space & "'-x' 2>&1"
		assertEqual(expected, shell of tb for "cmd" without executing given options:"-x", err:"&1")
	end script
	
	---------------------------------------------------------------------------------
	script test_absolutePath
		property name : "absolutePath()"
		property parent : UnitTest(me)
		assertEqual(tb's PWD & "a/b/c", tb's absolutePath("a/b/c"))
		assertEqual(tb's PWD & "a/b/c", tb's absolutePath("a/b/c/"))
		assertEqual(tb's PWD & "a/b/c", tb's absolutePath(":a:b:c"))
		assertKindOf(text, tb's absolutePath("/a/b/c"))
		assertEqual("/a/b/c", tb's absolutePath("a:b:c:"))
	end script
	
	---------------------------------------------------------------------------------
	script test_absolutePath_with_abs_posix_path
		property name : "Test absolutePath() with absolute POSIX path"
		property parent : UnitTest(me)
		assertEqual("/a/b/c", tb's absolutePath("/a/b/c"))
	end script
	
	---------------------------------------------------------------------------------
	script test_basename
		property name : "basename()"
		property parent : UnitTest(me)
		assertEqual("c", tb's basename("a/b/c"))
		assertEqual("c", tb's basename("/a/b/c"))
		assertEqual("c", tb's basename("a:b:c"))
		assertEqual("c", tb's basename("a:b:c:"))
	end script
	
	---------------------------------------------------------------------------------
	script test_basename_trailing_slash
		property name : "basename() with trailing slash"
		property parent : UnitTest(me)
		assertEqual("c", tb's basename("a/b/c/"))
	end script
	
	---------------------------------------------------------------------------------
	script test_cp
		property name : "cp()"
		property parent : UnitTest(me)
		set res to tb's cp({tb's glob("AS*.applescript"), POSIX file "doc/foo.txt", "examples/bar"}, "tmp/cp")
		set expected to "/bin/cp" & space & quoted form of "-r" & space & Â
			quoted form of "ASMake.applescript" & space & Â
			quoted form of "doc/foo.txt" & space & Â
			quoted form of "examples/bar" & space & Â
			quoted form of "tmp/cp"
		assertEqual(expected, res)
	end script
	
	---------------------------------------------------------------------------------
	script test_deslash
		property name : "deslash()"
		property parent : UnitTest(me)
		assertEqual("a", tb's deslash("a"))
		assertEqual("a", tb's deslash("a/"))
		assertEqual("a", tb's deslash("a//"))
	end script
	
	---------------------------------------------------------------------------------
	script test_directoryPath
		property name : "directoryPath()"
		property parent : UnitTest(me)
		assert(tb's directoryPath("a/b/c") ends with "a/b", "Assertion 1")
		assert(tb's directoryPath("/a/b/c") ends with "/a/b", "Assertion 2")
		assert(tb's directoryPath("a:b:c") ends with "/a/b", "Assertion 3")
		assert(tb's directoryPath("a:b:c:") ends with "/a/b", "Assertion 4")
	end script
	
	---------------------------------------------------------------------------------
	script test_ditto
		property name : "ditto()"
		property parent : UnitTest(me)
		set res to tb's ditto({tb's glob("AS*.applescript"), POSIX file "doc/foo.txt", "examples/bar"}, "tmp/ditto")
		set expected to "/usr/bin/ditto" & space & Â
			quoted form of "ASMake.applescript" & space & Â
			quoted form of "doc/foo.txt" & space & Â
			quoted form of "examples/bar" & space & Â
			quoted form of "tmp/ditto"
		assertEqual(expected, res)
	end script
	
	---------------------------------------------------------------------------------
	script test_joinPath_text
		property name : "joinPath() with text arguments"
		property parent : UnitTest(me)
		assertEqual("abc/defg", tb's joinPath("abc", "defg"))
		assertEqual("abc/defg", tb's joinPath("abc/", "defg"))
		assertEqual("abc/defg", tb's joinPath("abc/", "defg/"))
		assertEqual("/abc/defg", tb's joinPath("abc:", "defg"))
		assertEqual("abc/defg", tb's joinPath(":abc:", "defg"))
		assertEqual("abc/defg", tb's joinPath(":abc:", ":defg"))
		assertEqual("abc/defg", tb's joinPath(":abc:", ":defg:"))
	end script
	
	---------------------------------------------------------------------------------
	script test_joinPath_alias
		property name : "joinPath() with aliases"
		property parent : UnitTest(me)
		set p to path to library folder from user domain as alias
		assertEqual(POSIX path of p & "Scripts", tb's joinPath(p, "Scripts"))
		assertEqual(POSIX path of p & "Scripts", tb's joinPath(p, ":Scripts"))
	end script
	
	---------------------------------------------------------------------------------
	script test_makeAlias
		property name : "makeAlias()"
		property parent : UnitTest(me)
		set p to "/a/b/c"
		set q to "/x/y"
		set r to q & "/SomeAlias"
		assertEqual({p, q, "SomeAlias"}, tb's makeAlias(p, r))
	end script
	
	---------------------------------------------------------------------------------
	script test_mkdir
		property name : "mkdir()"
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
	
	---------------------------------------------------------------------------------
	script test_mv
		property name : "mv()"
		property parent : UnitTest(me)
		set res to tb's mv({"foo", "examples/bar"}, "tmp/mv")
		set expected to "/bin/mv" & space & Â
			quoted form of "foo" & space & Â
			quoted form of "examples/bar" & space & Â
			quoted form of "tmp/mv"
		assertEqual(expected, res)
	end script
	
	---------------------------------------------------------------------------------
	script test_dry_rm
		property name : "Dry rm()"
		property parent : UnitTest(me)
		set res to tb's rm({"a", "b/c", POSIX file "d/e"})
		set expected to "Deleting" & space & Â
			quoted form of "a" & ", " & Â
			quoted form of "b/c" & ", " & Â
			quoted form of "d/e"
		assertEqual(expected, res)
	end script
	
	---------------------------------------------------------------------------------
	script test_chomp
		property name : "chomp()"
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
	
	---------------------------------------------------------------------------------
	script test_osacompile
		property name : "osacompile()"
		property parent : UnitTest(me)
		set expected to "/usr/bin/osacompile '-o' 'ASMake.scpt' '-x' 'ASMake.applescript'"
		assertEqual(expected, osacompile of tb from "ASMake" given target:"scpt", options:"-x")
	end script
	
	---------------------------------------------------------------------------------
	script test_pathComponents
		property name : "pathComponents()"
		property parent : UnitTest(me)
		assertInstanceOf(list, tb's pathComponents("a/b"))
		assert(tb's pathComponents("a/b") ends with {"a", "b"}, "Path decomposed incorrectly")
	end script
	
	---------------------------------------------------------------------------------
	script test_pathExists_abs_path
		property name : "pathExists() with absolute paths"
		property parent : UnitTest(me)
		assert(tb's pathExists(tb's PWD), "The working directory should exist")
		assert(tb's pathExists(tb's PWD & "ASMake.applescript"), "ASMake.applescript should exist")
		refute(tb's pathExists(tb's PWD & "Idontexists"), "The file should not exist!")
	end script
	
	---------------------------------------------------------------------------------
	script test_pathExists_rel_path
		property name : "pathExists() with relative paths"
		property parent : UnitTest(me)
		assert(tb's pathExists("."), "The working directory should exist")
		assert(tb's pathExists("ASMake.applescript"), "ASMake.applescript should exist")
		refute(tb's pathExists("Idontexists"), "The file should not exist!")
	end script
	
	---------------------------------------------------------------------------------
	script test_relativizePath_abs_path
		property name : "relativizePath() with absolute paths"
		property parent : UnitTest(me)
		skip("Not implemented yet")
		assertEqual("/a/b/c", tb's relativizePath("/a/b/c", ""))
		assertEqual("a/b/c", tb's relativizePath("/a/b/c", "/"))
		assertEqual("b/c", tb's relativizePath("/a/b/c", "/a"))
		assertEqual("b/c", tb's relativizePath("/a/b/c", "/a/"))
		assertEqual("c", tb's relativizePath("/a/b/c", "/a/b"))
		assertEqual("c", tb's relativizePath("/a/b/c", "/a/b/"))
		assertEqual(".", tb's relativizePath("/a/b/c", "/a/b/c"))
		assertEqual(".", tb's relativizePath("/a/b/c", "/a/b/c/"))
		assertEqual("./..", tb's relativizePath("/a/b/c", "/a/b/c/d"))
		assertEqual("./..", tb's relativizePath("/a/b/c", "/a/b/c/d/"))
		assertEqual("./../..", tb's relativizePath("/a/b/c", "/a/b/c/d/e"))
		assertEqual("./../..", tb's relativizePath("/a/b/c", "/a/b/c/d/e/"))
	end script
	
	---------------------------------------------------------------------------------
	script test_relativizePath_rel_path
		property name : "relativizePath() with relative paths"
		property parent : UnitTest(me)
		skip("Not implemented yet")
		assertEqual("a/b/c", tb's relativizePath("a/b/c", ""))
		assertEqual("a/b/c", tb's relativizePath("a/b/c", "."))
		assertEqual("b/c", tb's relativizePath("a/b/c", "a"))
		assertEqual("b/c", tb's relativizePath("a/b/c", "a/"))
		assertEqual("c", tb's relativizePath("a/b/c", "a/b"))
		assertEqual("c", tb's relativizePath("a/b/c", "a/b/"))
		assertEqual(".", tb's relativizePath("a/b/c", "a/b/c"))
		assertEqual(".", tb's relativizePath("a/b/c", "a/b/c/"))
		assertEqual("./..", tb's relativizePath("a/b/c", "a/b/c/d"))
		assertEqual("./..", tb's relativizePath("a/b/c", "a/b/c/d/"))
		assertEqual("./../..", tb's relativizePath("a/b/c", "a/b/c/d/e"))
		assertEqual("./../..", tb's relativizePath("a/b/c", "a/b/c/d/e/"))
	end script
	
	---------------------------------------------------------------------------------
	script test_splitPath
		property name : "splitPath()"
		property parent : UnitTest(me)
		assertEqual({"a/b", "c"}, tb's splitPath("a/b/c"))
		assertEqual({"a/b", "c"}, tb's splitPath("a/b/c/"))
		assertEqual({"/a/b", "c"}, tb's splitPath("/a/b/c"))
		assertEqual({"/a/b", "c"}, tb's splitPath("/a/b/c/"))
		assertEqual({"/a/b", "c"}, tb's splitPath("a:b:c"))
		assertEqual({"/a/b", "c"}, tb's splitPath("a:b:c:"))
	end script
	
	---------------------------------------------------------------------------------
	script test_splitPath_short
		property name : "splitPath() with short paths"
		property parent : UnitTest(me)
		assertEqual({".", "c"}, tb's splitPath("c"))
		assertEqual({".", "c"}, tb's splitPath("c/"))
		assertEqual({".", "c"}, tb's splitPath(":c"))
		assertEqual({".", "c"}, tb's splitPath(":c:"))
		assertEqual({"/", "c"}, tb's splitPath("/c"))
		assertEqual({"/", "c"}, tb's splitPath("/c/"))
		assertEqual({"/", "c"}, tb's splitPath("c:"))
	end script
	
	---------------------------------------------------------------------------------
	script test_symlink
		property name : "symlink()"
		property parent : UnitTest(me)
		set expected to "/bin/ln '-s' 'foo' 'bar'"
		assertEqual(expected, tb's symlink("foo", "bar"))
	end script
	
	---------------------------------------------------------------------------------
	script test_which
		property name : "Test which()"
		property parent : UnitTest(me)
		set ASMake's TaskArguments's options to {} -- remove --dry
		assertNil(tb's which("A-command-that-does-not-exist"))
		assertEqual("/bin/bash", tb's which("bash"))
	end script
	
end script -- test_set_taskbase


###################################################################################
script test_set_functional_handlers
	property name : "Functional handlers"
	property parent : BaseTestSet(me)
	property TS : me
	property tb : missing value
	
	on increment(x)
		x + 1
	end increment
	
	on mirror(x)
		set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ""}
		try
			return ((text items of x)'s reverse) as text
		end try
		set AppleScript's text item delimiters to tid
		return x
	end mirror
	
	on isEven(x)
		x mod 2 = 0
	end isEven
	
	---------------------------------------------------------------------------------
	script test_filter
		property name : "filter()"
		property parent : UnitTest(me)
		property pList : {1, 2, 3, 4, 6, 9, 13}
		
		copy pList to listCopy
		set evenList to tb's filter(my pList, TS's isEven)
		assertEqual(listCopy, pList) -- Original list should not change
		assertEqual({2, 4, 6}, evenList)
		set evenList to tb's filter(a reference to my pList, TS's isEven)
		assertEqual(listCopy, pList) -- Original list should not change
		assertEqual({2, 4, 6}, evenList)
	end script
	
	---------------------------------------------------------------------------------
	script test_map
		property name : "map()"
		property parent : UnitTest(me)
		property pList : {"now", "here"}
		
		assertEqual({13, 2}, tb's map({12, 1}, TS's increment))
		assertEqual({"won", "ereh"}, tb's map({"now", "here"}, TS's mirror))
		assertEqual(tb's map(my pList, TS's mirror), tb's map(a reference to my pList, TS's mirror))
	end script
	
	---------------------------------------------------------------------------------
	script test_transform
		property name : "transform()"
		property parent : UnitTest(me)
		property l1 : {1, 5, 3}
		
		tb's transform(l1, TS's increment)
		assertEqual({2, 6, 4}, l1)
		tb's transform(a reference to l1, TS's increment)
		assertEqual({3, 7, 5}, l1)
	end script
	
	---------------------------------------------------------------------------------
	script test_join
		property name : "Join list"
		property parent : UnitTest(me)
		
		assertInstanceOf(text, tb's join({12}, ""))
		assertEqual("", tb's join({}, "--"))
		assertEqual("12", tb's join({12}, "--"))
		assertEqual("nowhere", tb's join({"now", "here"}, ""))
		assertEqual("now and here", tb's join({"now", "here"}, " and "))
	end script
	
	---------------------------------------------------------------------------------
	script test_split
		property name : "Split as inverse of join"
		property parent : UnitTest(me)
		
		assertEqual("This:is:a:path", tb's join(tb's split("This:is:a:path", ":"), ":"))
		assertEqual({"now", "here"}, tb's split(tb's join({"now", "here"}, "/"), "/"))
	end script
	
end script -- test_set_functional_handlers
