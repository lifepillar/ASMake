(*!
	@header
	@abstract
		Unit tests for ASMake.
	@charset macintosh
*)
use scripting additions
property parent : script "ASUnit"
---------------------------------------------------------------------------------------
property suitename : "Suite of unit tests for ASMake"
property scriptName : "ASMake" -- The name of the script to be tested
global ASMake -- The variable holding the script to be tested
---------------------------------------------------------------------------------------

property TopLevel : me
property suite : makeTestSuite(suitename)

(*
-- Optional: choose loggers
set suite's loggers to {AppleScriptEditorLogger, ConsoleLogger}
*)
(*
-- Optional: customize colors for AS Editor output
tell AppleScriptEditorLogger
	set its defaultColor to {256 * 1, 256 * 102, 256 * 146}
	set its successColor to {256 * 0, 256 * 159, 256 * 120}
	set its defectColor to {256 * 137, 256 * 89, 256 * 168}
end tell
*)
(*
-- Optional: customize colors for terminal output (osascript)
tell StdoutLogger
	set its defaultColor to its blue
	set its successColor to bb(its green) -- bold green
	set its defectColor to bb(its red) -- bold red
end tell
*)
autorun(suite)

---------------------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------------------

-- Don't change this test case if you are testing an external script
-- in the same folder as this test script! We load the script in a test case, because
-- this will work when all the tests in the current folder are run together using loadTestsFromFolder().
-- Besides, this will make sure that we are using the latest version of the script
-- to be tested even if we do not recompile this test script.
script |Load script|
	property parent : TestSet(me)
	script |Loading the script|
		property parent : UnitTest(me)
		set ASMake to run script Â
			((folder of file (path to me) of application "Finder" as text) Â
				& scriptName & ".applescript") as alias
		assertInstanceOf(script, ASMake)
	end script
end script


script |A test set|
	property parent : TestSet(me)
	
	on setUp()
	end setUp
	
	on tearDown()
	end tearDown
	
	script |test something|
		property parent : UnitTest(me)
		assertInheritsFrom(current application, ASMake)
	end script
	
end script
