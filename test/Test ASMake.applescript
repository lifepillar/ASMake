(*!
	@header
	@abstract
		Unit tests for ASMake.
	@charset macintosh
*)
use AppleScript version "2.4"
use scripting additions
use ASUnit : script "com.lifepillar/ASUnit" version "1.2.4"
use ASMake : script "com.lifepillar/ASMake"

property parent : ASUnit
property TOPLEVEL : me
property suite : makeTestSuite("Suite of unit tests for ASMake")

log "Testing ASMake v" & ASMake's version
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

###################################################################################
script TestSetCoreASMake
	property name : "Core ASMake"
	property parent : TestSet(me)
	
	---------------------------------------------------------------------------------
	script TestASMakeClass
		property name : "Check ASMake's class"
		property parent : UnitTest(me)
		
		assertInstanceOf(script, ASMake)
	end script
	
	---------------------------------------------------------------------------------
	script TestASMakeName
		property name : "Check ASMake's name"
		property parent : UnitTest(me)
		
		assertEqual("ASMake", ASMake's name)
	end script
	
	---------------------------------------------------------------------------------
	script TestASMakeId
		property name : "Check ASMake's id"
		property parent : UnitTest(me)
		
		assertEqual("com.lifepillar.ASMake", ASMake's id)
	end script
	
	---------------------------------------------------------------------------------
	script TestASMakeDataStructures
		property name : "Check ASMake's data structures"
		property parent : UnitTest(me)
		
		assertInstanceOf(script, ASMake's Stdout)
		assertInstanceOf("Task", ASMake's TaskBase)
		assertKindOf(script, ASMake's TaskBase)
		assertInstanceOf(script, ASMake's CommandLine)
	end script
end script -- TestSetCoreASMake

###################################################################################
script TestSetToNSURL
	use framework "Foundation"
	
	property name : "Internals"
	property parent : TestSet(me)
	property aTask : missing value
	
	on setUp()
		script
			property name : "EmptyTask"
			property parent : ASMake's TaskBase
		end script
		set aTask to the result
	end setUp
	
	---------------------------------------------------------------------------------
	script TestFileURLAbsPath
		property name : "toNSURL() with absolute path"
		property parent : UnitTest(me)
		
		assertEqual("/", aTask's toNSURL("/")'s relativePath as text)
		assertEqual("/a/b/c", aTask's toNSURL("/a/b/c")'s relativePath as text)
		assertEqual("/", aTask's toNSURL("/")'s |path| as text)
		assertEqual("/a/b/c", aTask's toNSURL("/a/b/c")'s |path| as text)
	end script
	
	---------------------------------------------------------------------------------
	script TestFileURLRelPath
		property name : "toNSURL() with relative path"
		property parent : UnitTest(me)
		
		assertEqual("a/b/c", aTask's toNSURL("a/b/c")'s relativePath as text)
		assertEqual(aTask's workingDirectory() & "/a/b/c", aTask's toNSURL("a/b/c")'s |path| as text)
	end script
	
	---------------------------------------------------------------------------------
	script TestFileURLPathWithTilde
		property name : "toNSURL() with path with tilde"
		property parent : UnitTest(me)
		
		assertEqual(POSIX path of (path to home folder), Â
			(aTask's toNSURL("~")'s relativePath as text) & "/") -- relativePath strips trailing slash
		assertEqual(POSIX path of (path to home folder), Â
			(aTask's toNSURL("~")'s |path| as text) & "/") -- |path| strips trailing slash
		assertEqual(POSIX path of (path to home folder), Â
			(aTask's toNSURL("~/")'s relativePath as text) & "/")
		assertEqual(POSIX path of (path to home folder), Â
			(aTask's toNSURL("~/")'s |path| as text) & "/")
		assertEqual(POSIX path of (path to home folder) & "xyz", Â
			aTask's toNSURL("~/xyz/")'s relativePath as text)
		assertEqual(POSIX path of (path to home folder) & "xyz", Â
			aTask's toNSURL("~/xyz/")'s |path| as text)
	end script
	
	---------------------------------------------------------------------------------
	script TestFileURLPathWithDots
		property name : "toNSURL() with path with dots"
		property parent : UnitTest(me)
		
		assertEqual(".", aTask's toNSURL("./")'s relativePath as text)
		assertEqual("..", aTask's toNSURL("./..")'s relativePath as text)
		assertEqual(aTask's workingDirectory(), Â
			aTask's toNSURL("./")'s |path| as text)
		assertEqual(aTask's workingDirectory(), Â
			aTask's toNSURL(".")'s |path| as text)
		assertEqual(aTask's workingDirectory(), Â
			aTask's toNSURL("./foobar/..")'s |path| as text)
		assertEqual(aTask's workingDirectory(), Â
			aTask's toNSURL("./foobar/..")'s |path| as text)
	end script
	
	script TestFileURLStandardization
		property name : "toNSURL()'s |path| is not standardized"
		property parent : UnitTest(me)
		
		assertEqual("/a/../b/./c", aTask's toNSURL("/a/../b/./c")'s |path| as text)
		assertEqual("/a/../b/./c", aTask's toNSURL("/a/../b/./c")'s relativePath as text)
		assertEqual("/./a/b/../b/./c/d/..", aTask's toNSURL("/./a/b/../b/./c/d/../")'s |path| as text)
		assertEqual("/./a/b/../b/./c/d/..", aTask's toNSURL("/./a/b/../b/./c/d/../")'s relativePath as text)
		assertEqual("/./a/b/../b/./c/d/..", aTask's toNSURL("/./a/b/../b/./c/d/..")'s |path| as text)
		assertEqual("/./a/b/../b/./c/d/..", aTask's toNSURL("/./a/b/../b/./c/d/..")'s relativePath as text)
	end script
end script -- TestSetASMakeInternals


###################################################################################
script TestSetEmptyTask
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
	script TestTaskClass
		property name : "Task's class"
		property parent : UnitTest(me)
		
		assertInstanceOf("Task", aTask)
	end script
	
	---------------------------------------------------------------------------------
	script TestTaskName
		property name : "Task's name"
		property parent : UnitTest(me)
		
		assertEqual("EmptyTask", aTask's name)
	end script
	
	---------------------------------------------------------------------------------
	script TestaskSynonyms
		property name : "Task's synonyms"
		property parent : UnitTest(me)
		
		assertEqual({}, aTask's synonyms)
	end script
	
	---------------------------------------------------------------------------------
	script TestTaskPrintSuccess
		property name : "Task's printSuccess"
		property parent : UnitTest(me)
		
		ok(aTask's printSuccess)
	end script
end script -- TestSetEmptyTask


###################################################################################
script TestSetWorkingDirectory
	property name : "Working directory"
	property parent : TestSet(me)
	property aTask : missing value
	
	on setUp()
		script
			property name : "EmptyTask"
			property parent : ASMake's TaskBase
		end script
		set aTask to the result
	end setUp
	
	---------------------------------------------------------------------------------
	script TestWorkingDirectoryDefined
		property name : "Working directory is set before running task"
		property parent : UnitTest(me)
		
		refuteNil(aTask's workingDirectory())
	end script
	
	---------------------------------------------------------------------------------
	script TestWorkingDirectoryPosix
		property name : "Working directory path is of class text"
		property parent : UnitTest(me)
		
		assertInstanceOf(text, aTask's workingDirectory())
	end script
	
	---------------------------------------------------------------------------------
	script TestTaskWorkingDirectoryAbsolute
		property name : "Working directory path is absolute"
		property parent : UnitTest(me)
		
		assert(aTask's workingDirectory() starts with "/", Â
			"Working directory path is not an absolute path")
	end script
	
	---------------------------------------------------------------------------------
	script TestTaskWorkingDirectoryTrailingSlash
		property name : "Working directory path has no trailing slash"
		property parent : UnitTest(me)
		
		assert(aTask's workingDirectory() does not end with "/", Â
			"Working directory path has a trailing slash")
	end script
	
	---------------------------------------------------------------------------------
	script TestChangeWorkingDirectory
		property name : "Change working directory"
		property parent : UnitTest(me)
		
		aTask's setWorkingDirectory("/tmp")
		assertEqual("/private/tmp", aTask's workingDirectory())
	end script
end script -- TestSetWorkingDirectory


###################################################################################
script TestSetNonEmptyTask
	property name : "Task properties"
	property parent : TestSet(me)
	property aTask : missing value
	
	on setUp()
		script
			property parent : ASMake's TaskBase
			property name : "myTask"
			property synonyms : {"yourTask"}
			property printSuccess : false
		end script
		set aTask to the result
	end setUp
	
	---------------------------------------------------------------------------------
	script TestTaskClass
		property name : "Task's class"
		property parent : UnitTest(me)
		
		assertInstanceOf("Task", aTask)
	end script
	
	---------------------------------------------------------------------------------
	script TestTaskName
		property name : "Task's name"
		property parent : UnitTest(me)
		
		assertEqual("myTask", aTask's name)
	end script
	
	---------------------------------------------------------------------------------
	script TestTaskSynonyms
		property name : "Task's synonyms"
		property parent : UnitTest(me)
		
		assertEqual({"yourTask"}, aTask's synonyms)
	end script
	
	---------------------------------------------------------------------------------
	script TestTaskPrintSuccess
		property name : "Task's printSuccess"
		property parent : UnitTest(me)
		
		notOk(aTask's printSuccess)
	end script
end script -- TestSetNonEmptyTask


###################################################################################
script TestSetShellCommands
	property name : "Shell commands"
	property parent : TestSet(me)
	property tb : missing value
	
	on setUp()
		ASMake's CommandLine's clear()
		set my tb to a reference to ASMake's TaskBase
	end setUp
	
	---------------------------------------------------------------------------------
	script TestShell
		property name : "shell()"
		property parent : UnitTest(me)
		
		fail("TODO")
	end script
end script -- TestSetShellCommands


###################################################################################
script TestSetPathHandlers
	property name : "Path manipulation"
	property parent : TestSet(me)
	property tb : missing value
	
	on setUp()
		set my tb to a reference to ASMake's TaskBase
		my tb's setWorkingDirectory("/tmp/") -- Is OS X, /tmp is a symbolic link to /private/tmp
	end setUp
	
	---------------------------------------------------------------------------------
	script TestPosixAbsolutePathNoSlash
		property name : "posixPath() with absolute POSIX path without trailing slash"
		property parent : UnitTest(me)
		
		assertEqual("/a/b/c", tb's posixPath("/a/b/c"))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixRelativePathNoSlash
		property name : "posixPath() with relative POSIX path without trailing slash"
		property parent : UnitTest(me)
		
		assertEqual("a/b/c", tb's posixPath("a/b/c"))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixAbsolutePathWithSlash
		property name : "posixPath() with absolute POSIX path with trailing slash"
		property parent : UnitTest(me)
		
		assertEqual("/a/b/c/", tb's posixPath("/a/b/c/"))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixRelativePathWithSlash
		property name : "posixPath() with relative POSIX path with trailing slash"
		property parent : UnitTest(me)
		
		assertEqual("a/b/c/", tb's posixPath("a/b/c/"))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixAbsoluteHFSPathNoColon
		property name : "posixPath() with absolute HFS path without trailing colon"
		property parent : UnitTest(me)
		
		assertEqual("/a/b/c", tb's posixPath("a:b:c"))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixAbsoluteHFSPathWithColon
		property name : "posixPath() with absolute HFS path with trailing colon"
		property parent : UnitTest(me)
		
		assertEqual("/a/b/c/", tb's posixPath("a:b:c:"))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixRelativeHFSPathNoColon
		property name : "posixPath() with relative POSIX path without trailing colon"
		property parent : UnitTest(me)
		
		assertEqual("a/b/c", tb's posixPath(":a:b:c"))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixRelativeHFSPathWithColon
		property name : "posixPath() with relative HFS path with trailing colon"
		property parent : UnitTest(me)
		
		assertEqual("a/b/c/", tb's posixPath(":a:b:c:"))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixAlias
		property name : "posixPath() with alias"
		property parent : UnitTest(me)
		
		set res to POSIX path of (path to library folder from user domain as alias)
		assertEqual(res, tb's posixPath(path to library folder from user domain as alias))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixFile
		property name : "posixPath() with file"
		property parent : UnitTest(me)
		
		assertEqual("/System/Library", tb's posixPath(POSIX file "/System/Library"))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixReference
		property name : "posixPath() with reference to a POSIX path"
		property parent : UnitTest(me)
		
		assertEqual("a/b/c", tb's posixPath(a reference to "a/b/c"))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixPaths
		property name : "posixPaths()"
		property parent : UnitTest(me)
		
		set res to POSIX path of (path to library folder from user domain as alias)
		assertEqual({res}, tb's posixPaths(path to library folder from user domain as alias))
		set res to POSIX path of (path to library folder from user domain as text)
		assertEqual({res}, tb's posixPaths(path to library folder from user domain as text))
	end script
	
	---------------------------------------------------------------------------------
	script TestPosixPathsAbsolutePath
		property name : "posixPaths() with POSIX absolute path"
		property parent : UnitTest(me)
		
		set res to "/a/b/c"
		set v to item 1 of tb's posixPaths(res)
		assertEqual(res, v)
	end script
	
	---------------------------------------------------------------------------------
	script TestGlob
		property name : "glob()"
		property parent : UnitTest(me)
		
		assertInstanceOf(list, tb's glob({"*.scpt", "*.scptd"}))
		assertInstanceOf(list, tb's glob("abc.scpt"))
		fail("TODO")
	end script
	
	---------------------------------------------------------------------------------
	script TestAbsolutePathWithRelativePath
		property name : "absolutePath() with relative path"
		property parent : UnitTest(me)
		
		assertKindOf(text, tb's absolutePath("a/b/c"))
		assertEqual(tb's workingDirectory() & "/a/b/c", tb's absolutePath("a/b/c"))
		assertEqual(tb's workingDirectory() & "/d/e/f", tb's absolutePath("d/e/f/"))
		assertEqual(tb's workingDirectory() & "/g/h/i", tb's absolutePath(":g:h:i"))
		assertEqual(tb's workingDirectory() & "/j/k/l", tb's absolutePath(":j:k:l:"))
		-- Why does NSURL's URLByStandardizingPath remove /private here,
		-- but not earlier (it should always remove it)?
		assertEqual(tb's workingDirectory(), "/private" & tb's absolutePath("."))
	end script
	
	---------------------------------------------------------------------------------
	script TestAbsolutePathWithAbsolutePath
		property name : "absolutePath() with absolute path"
		property parent : UnitTest(me)
		
		assertKindOf(text, tb's absolutePath("/a/b/c"))
		assertEqual("/a/b/c", tb's absolutePath("/a/b/c"))
		assertEqual("/a/b/c", tb's absolutePath("/a/b/c/"))
		assertEqual("/a/b/c", tb's absolutePath("a:b:c"))
		assertEqual("/a/b/c", tb's absolutePath("a:b:c:"))
	end script
	
	---------------------------------------------------------------------------------
	script TestAbsolutePathWithPathWithTilde
		property name : "absolutePath() with path with tilde"
		property parent : UnitTest(me)
		
		assertEqual((POSIX path of (path to home folder)) & "a/d", tb's absolutePath("~/a/d"))
		assertEqual((POSIX path of (path to home folder)) & "a/d", tb's absolutePath("~/a/d/"))
	end script
	
	---------------------------------------------------------------------------------
	script TestAbsolutePathStandardization
		property name : "absoloutePath() standardizes its argument"
		property parent : UnitTest(me)
		
		assertEqual("/b/c", tb's absolutePath("/a/../b/./c"))
		assertEqual(tb's workingDirectory() & "/a/d", tb's absolutePath("a/./b/../d"))
		assertEqual("/a/b/c", tb's absolutePath("/./a/b/../b/./c/d/../"))
		assertEqual("/a/b/c", tb's absolutePath("/./a/b/../b/./c/d/.."))
		assertEqual((POSIX path of (path to home folder)) & "a/b/c", tb's absolutePath("~/./a/b/../b/./c/d/../."))
	end script
	
	---------------------------------------------------------------------------------
	script TestBasename
		property name : "basename()"
		property parent : UnitTest(me)
		
		assertEqual("c", tb's basename("a/b/c"))
		assertEqual("c", tb's basename("/a/b/c"))
		assertEqual("c", tb's basename("a:b:c"))
		assertEqual("c", tb's basename("a:b:c:"))
	end script
	
	---------------------------------------------------------------------------------
	script TestBasenameTrailingSlash
		property name : "basename() with trailing slash"
		
		property parent : UnitTest(me)
		assertEqual("c", tb's basename("a/b/c/"))
		assertEqual("c", tb's basename("a/b/c//"))
	end script
	
	---------------------------------------------------------------------------------
	script TestDeslash
		property name : "deslash()"
		property parent : UnitTest(me)
		
		assertEqual("a", tb's deslash("a"))
		assertEqual("ab", tb's deslash("ab"))
		assertEqual("/a", tb's deslash("/a"))
		assertEqual("a", tb's deslash("a/"))
		assertEqual("a", tb's deslash("a//"))
		assertEqual("/a/a", tb's deslash("/a/a//"))
		assertEqual("/", tb's deslash("/"))
		assertEqual("/", tb's deslash("//"))
		assertEqual("/", tb's deslash("///"))
	end script
	
	---------------------------------------------------------------------------------
	script TestParentDirectory
		property name : "parentDirectory()"
		property parent : UnitTest(me)
		
		assertEqual("a/b", tb's parentDirectory("a/b/c"))
		assertEqual("a/b", tb's parentDirectory("a/b/c/"))
		assertEqual("/a/b", tb's parentDirectory("/a/b/c"))
		assertEqual("/a/b", tb's parentDirectory("/a/b/c/"))
		assertEqual("/a/b", tb's parentDirectory("a:b:c"))
		assertEqual("/a/b", tb's parentDirectory("a:b:c:"))
	end script
	
	---------------------------------------------------------------------------------
	script TestJoinPathText
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
	script TestJoinPathAlias
		property name : "joinPath() with aliases"
		property parent : UnitTest(me)
		
		set p to path to library folder from user domain as alias
		assertEqual(POSIX path of p & "Scripts", tb's joinPath(p, "Scripts"))
		assertEqual(POSIX path of p & "Scripts", tb's joinPath(p, ":Scripts"))
	end script
	
	---------------------------------------------------------------------------------
	script TestChomp
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
	script TestPathComponents
		property name : "pathComponents()"
		property parent : UnitTest(me)
		
		assertInstanceOf(list, tb's pathComponents("a/b"))
		assertEqual({"/", "a", "b"}, tb's pathComponents("/a/b"), "Absolute path decomposed incorrectly")
		assertEqual({"/", "private", "tmp", "a", "b"}, tb's pathComponents("a/b"), "Relative path decomposed incorrectly")
		assertEqual({"/", "private", "tmp", "a", "b"}, tb's pathComponents("a/b/"), "Relative path with trailing slash decomposed incorrectly")
	end script
	
	---------------------------------------------------------------------------------
	script TestPathExistsAbsPath
		property name : "pathExists() with absolute paths"
		property parent : UnitTest(me)
		
		assert(tb's pathExists("/Users"), "The /Users folder should exist")
		refute(tb's pathExists("/IdOnTeXisTs"), "The path should not exist!")
	end script
	
	---------------------------------------------------------------------------------
	script TestPathExistsRelPath
		property name : "pathExists() with relative paths"
		property parent : UnitTest(me)
		
		tb's setWorkingDirectory((folder of file (path to me) of application "Finder") as alias)
		assert(tb's pathExists("."), "The working directory should exist")
		refute(tb's pathExists("I/d/on/tex/i/sts"), "The path should not exist!")
	end script
	
	---------------------------------------------------------------------------------
	script TestRelativizePathAbsPath
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
	script TestRelativizePathRelPath
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
	script TestSplitPath
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
	script TestSplitPathShort
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
	script TestWhich
		property name : "which()"
		property parent : UnitTest(me)
		
		assertNil(tb's which("A-command-that-does-not-exist"))
		assertEqual("/bin/bash", tb's which("bash"))
	end script
	
end script -- TestSetTaskbase


###################################################################################
script TestSetFileHandlers
	property name : "File manipulation"
	property parent : TestSet(me)
	property tb : missing value
	
	on setUp()
		set ASMake's CommandLine's options to {}
		set my tb to a reference to ASMake's TaskBase
		--my tb's setWorkingDirectory(TOPLEVEL's workingDir)
	end setUp
	
	---------------------------------------------------------------------------------
	script TestCopy
		property name : "Copy items"
		property parent : UnitTest(me)
		
		fail("TODO")
	end script
	
	---------------------------------------------------------------------------------
	script TestDitto
		property name : "ditto()"
		property parent : UnitTest(me)
		
		fail("TODO")
	end script
	
	---------------------------------------------------------------------------------
	script TestMakeAlias
		property name : "Create alias"
		property parent : UnitTest(me)
		
		fail("TODO")
	end script
	
	---------------------------------------------------------------------------------
	script TestMakePath
		property name : "Create path"
		property parent : UnitTest(me)
		
		fail("TODO")
	end script
	
	---------------------------------------------------------------------------------
	script TestMove
		property name : "Move items"
		property parent : UnitTest(me)
		
		fail("TODO")
	end script
	
	---------------------------------------------------------------------------------
	script TestRemove
		property name : "Remove items"
		property parent : UnitTest(me)
		
		fail("TODO")
	end script
	
	---------------------------------------------------------------------------------
	script TestSymlink
		property name : "symlink()"
		property parent : UnitTest(me)
		
		fail("TODO")
	end script
end script -- TestSetFileHandlers


###################################################################################
script TestScriptHandlers
	property name : "Script manipulation"
	property parent : TestSet(me)
	property tb : missing value
	
	on setUp()
		set my tb to a reference to ASMake's TaskBase
	end setUp
	
	---------------------------------------------------------------------------------
	script TestOsacompile
		property name : "osacompile()"
		property parent : UnitTest(me)
		
		fail("TODO")
	end script
end script -- TestScriptBundles


###################################################################################
script TestSetFunctionalHandlers
	property name : "Functional handlers"
	property parent : TestSet(me)
	property TS : me
	property tb : missing value
	
	on setUp()
		set my tb to a reference to ASMake's TaskBase
	end setUp
	
	on increment(x)
		x + 1
	end increment
	
	on mirror(x)
		local res
		set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, ""}
		try
			set res to ((text items of x)'s reverse) as text
		on error
			set res to x
		end try
		set AppleScript's text item delimiters to tid
		return res
	end mirror
	
	on isEven(x)
		x mod 2 = 0
	end isEven
	
	---------------------------------------------------------------------------------
	script TestFilter
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
	script TestMap
		property name : "map()"
		property parent : UnitTest(me)
		property pList : {"now", "here"}
		
		assertEqual({13, 2}, tb's map({12, 1}, TS's increment))
		assertEqual({"won", "ereh"}, tb's map({"now", "here"}, TS's mirror))
		assertEqual(tb's map(my pList, TS's mirror), tb's map(a reference to my pList, TS's mirror))
	end script
	
	---------------------------------------------------------------------------------
	script TestTransform
		property name : "transform()"
		property parent : UnitTest(me)
		property l1 : {1, 5, 3}
		
		tb's transform(l1, TS's increment)
		assertEqual({2, 6, 4}, l1)
		tb's transform(a reference to l1, TS's increment)
		assertEqual({3, 7, 5}, l1)
	end script
	
	---------------------------------------------------------------------------------
	script TestJoin
		property name : "Join list"
		property parent : UnitTest(me)
		
		assertInstanceOf(text, tb's join({12}, ""))
		assertEqual("", tb's join({}, "--"))
		assertEqual("12", tb's join({12}, "--"))
		assertEqual("nowhere", tb's join({"now", "here"}, ""))
		assertEqual("now and here", tb's join({"now", "here"}, " and "))
	end script
	
	---------------------------------------------------------------------------------
	script TestSplit
		property name : "Split as inverse of join"
		property parent : UnitTest(me)
		
		assertEqual("This:is:a:path", tb's join(tb's split("This:is:a:path", ":"), ":"))
		assertEqual({"now", "here"}, tb's split(tb's join({"now", "here"}, "/"), "/"))
	end script
end script -- TestSetFunctionalHandlers
