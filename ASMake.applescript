(*!
 @header ASMake
 	A simple AppleScript build library with capabilities similar to rake.
 @abstract A draft of a primitive replacement for rake, make, etcÉ, in pure AppleScript.
 @author Lifepillar
 @copyright 2014 Lifepillar
 @version 0.0.1
 @charset macintosh
*)
property name : "ASMake"
property version : "0.0.1"
property id : "com.lifepillar.ASMake"

script Stdout
	property parent : AppleScript
	property esc : "\\033["
	property black : esc & "0;30m"
	property blue : esc & "0;34m"
	property cyan : esc & "0;36m"
	property green : esc & "0;32m"
	property magenta : esc & "0;35m"
	property purple : esc & "0;35m"
	property red : esc & "0;31m"
	property yellow : esc & "0;33m"
	property white : esc & "0;37m"
	property reset : esc & "0m"
	
	on col(s, kolor)
		set s to kolor & s & reset
	end col
	
	-- Make color bold
	on bb(kolor)
		esc & "1;" & text -3 thru -1 of kolor
	end bb
	
	on echo(msg)
		set msg to do shell script "echo " & quoted form of msg without altering line endings
		log text 1 thru -2 of msg -- Remove last linefeed
	end echo
	
	on ohai(msg)
		echo(green & "==>" & space & bb(white) & msg & reset)
	end ohai
	
	on ofail(msg, info)
		set msg to red & "Fail:" & space & bb(white) & msg & reset
		if info is not "" then set msg to msg & linefeed & info
		echo(msg)
	end ofail
	
	on owarn(msg)
		echo(red & "Warn:" & space & bb(white) & msg & reset)
	end owarn
	
end script -- Stdout

(*! @abstract The script object common to all tasks. *)
script TaskBase
	property parent : Stdout
	property class : "Task"
	property TASKS : {} -- shared by all tasks, should not be overriden
	property PWD : missing value -- shared by all tasks, should not be overridden
	property synonyms : {} -- Define a task's aliases
	property arguments : {} -- A task's arguments
	property printSuccess : true -- Print success message when a task finishes?
	
	on cp(src, dst) -- src can be a list of POSIX paths
		local cmd
		if src's class is text then
			set src to {src}
		end if
		set cmd to "cp -r"
		repeat with s in src
			set cmd to cmd & space & quoted form of s & space
		end repeat
		sh(cmd & space & quoted form of dst)
	end cp
	
	on mkdir(dirname)
		sh("mkdir -p" & space & quoted form of dirname)
	end mkdir
	
	on osacompile(src)
		if src's class is text then
			set src to {src}
		end if
		repeat with s in src
			sh("osacompile -x -o" & space & Â
				quoted form of (s & ".scpt") & space & Â
				quoted form of (s & ".applescript"))
		end repeat
	end osacompile
	
	on rm(patterns)
		if patterns's class is text then
			set patterns to {patterns}
		end if
		set cmd to ""
		repeat with p in patterns
			set cmd to cmd & "rm -fr" & space & p & ";" & space
		end repeat
		sh(cmd)
	end rm
	
	on sh(command)
		local output
		echo(command)
		-- Execute command in working directory
		set command to Â
			"cd" & space & quoted form of my PWD & ";" & space & command
		set output to (do shell script command & space & "2>&1")
		if output is not equal to "" then echo(output)
	end sh
	
	on which(command)
		try
			do shell script "which" & space & command
			true
		on error
			false
		end try
	end which
end script

on Task(t)
	set the end of TaskBase's TASKS to t -- Register task
	return TaskBase
end Task

-- Predefined tasks
script helpTask
	property parent : Task(me)
	property name : "help"
	property synonyms : {"-help", "--help", "-h"}
	property description : "Show the list of available tasks and exit."
	property printSuccess : false
	repeat with t in my TASKS
		echo(bb(my white) & t's name & my reset & tab & tab & t's description)
	end repeat
end script

script workDir
	property parent : Task(me)
	property name : "pwd"
	property synonyms : {"wd"}
	property description : "Print the path of the working directory and exit."
	property printSuccess : false
	log my PWD
end script


property parent : Stdout

(*!
	@abstract
		A script object representing the command-line arguments.
	@discussion
		This is passed to the task.
*)
script Args
	property parent : AppleScript
	
	(*! @abstract The name of the task to be executed. *)
	property command : ""
	
	(*! @abstract A list of ASMake options. *)
	property options : {}
	(*!
		@abstract
			A list of keys from command-line options.
		@discussion
			This property stores they keys of command-line options of the form <tt>key=value</tt>.
			For flags and command-line switches, it stores their names as they are,
			unless they start with <tt>no-</tt>, <tt>-no-</tt>, or <tt>--no-</tt>, in which case
			such prefix is removed.
	*)
	property keys : {}
	(*!
		@abstract
			A list of values from command-line options.
		@discussion
			This property stores they values of command-line options of the form <tt>key=value</tt>.
			For flags and command-line switches, it stores the value <tt>true</tt> unless the switch
			starts with <tt>no-</tt>, <tt>-no-</tt>, or <tt>--no-</tt>, in which case it stores
			the value <tt>false</tt>.
	*)
	property values : {}
	
	(*! @abstract Returns the number of arguments. *)
	on numberOfArguments()
		my values's length
	end numberOfArguments
	
	(*!
			@abstract
				Retrieves the argument with the given key.
			@return
				The value associated with the key, or the specified default value if the key is not found.
		*)
	on fetch(key, default)
		local i, n
		set n to numberOfArguments()
		repeat with i from 1 to n
			if item i of my keys is key then return item i of my values
		end repeat
		default
	end fetch
	
	(*! @abstract Like @link fetch @/link(), but removes the argument from the list of arguments. *)
	on fetchAndDelete(key, default)
	end fetchAndDelete
	
	(*!
			@abstract
				Retrieves the first argument and removes it from the list of arguments.
			@return
				A pair {key, value}, or {missing value,missing value} if there are no arguments.
		*)
	on shift()
		if num() is 0 then return {missing value, missing value}
		local k, v
		set {k, v} to {the first item of my keys, the first item of my values}
		set {my keys, my values} to {the rest of my keys, the rest of my values}
		{k, v}
	end shift
	
end script

(*! @abstract A script object for collecting and parsing command-line arguments. *)
script CommandLineParser
	property parent : Stdout
	
	(*! @abstract The full command string. *)
	property stream : ""
	
	(*! @abstract The length of the command string. *)
	property streamLength : 0
	
	(*!
		@abstract
			The index of the next character to be read from the command string.
		@discussion
			The invariant for this property is maintained by the @link nextChar@/link() handler.
	*)
	property npos : 1
	
	(*! @abstract The current parsed token. *)
	property currToken : missing value
	
	(*! @abstract The character signalling that the stream has been consumed. *)
	property EOS : ""
	property UNQUOTED : space
	property SINGLE_QUOTED : "'"
	property DOUBLE_QUOTED : quote
	(*! @abstract The state of the lexical analyzer. *)
	property state : my UNQUOTED
	
	(*!
		@abstract
			Sets the stream to be parsed to the given value.
		@param
			newStream <em>[text]</em> The string to be parsed.
	*)
	on setStream(newStream)
		set my stream to newStream
		set my streamLength to the length of newStream
		resetStream()
	end setStream
	
	(*! @abstract Resets the stream to its initial state, ready to be parsed again. *)
	on resetStream()
		set currToken to missing value
		set my npos to 1
		set my state to my UNQUOTED
	end resetStream
	
	(*!
		@abstract
			Parses the given command-line string.
		@discussion
			A command-line string has the following syntax:
			
			<pre>
			[<ASMake options>] <task name> [<key>=<value> ...]
			</pre>
			
			The full grammar for a command-line string is as follows (terminals are enclosed in quotes):
			
			<pre>
			CommandLine ::= OptionList TaskName ArgList
			OptionList ::= Option OptionList | ''
			Option ::= '-<string>' | '--<string>'
			TaskName ::= '<string>'
			ArgList ::= Arg ArgList | ''
			Arg ::= <string>' '=' '<string>' 
			</pre>

			[ | <-- this bar is here because of a bug (#15956484) in AppleScript Editor. Ignore this line. ]

		Since ASMake can accept only a single argument, the whole command line string
		must be enclosed in quotes. Alternatively, ASMake interprets a dot as a space.
		Examples:

			<pre>
			asmake help
			asmake 'footask xyz = a tuv=b'
			asmake footask.xyz=a.tuv=b
			</pre>
	*)
	on parse(commandLine)
		set my stream to commandLine
		set my streamLength to the length of my stream
		set npos to 1
		optionList()
		taskName()
		argList()
	end parse
	
	on optionList()
		nextToken()
		if my currToken starts with "-" then
			set the end of Args's options to my currToken
			optionList()
		end if
	end optionList
	
	on taskName()
		if my currToken is missing value then syntaxError("Missing task name")
		set Args's command to my currToken
	end taskName
	
	on argList()
		nextToken()
		if my currToken is missing value then return -- no arguments
		arg()
		argList()
	end argList
	
	on arg()
		set the end of Args's keys to my currToken
		nextToken()
		if my currToken is not "=" then syntaxError("Arguments must have the form key=value")
		nextToken()
		set the end of Args's values to my currToken
	end arg
	
	on nextToken()
		local c
		repeat -- skip white space
			set c to nextChar()
			if c is not in {space, tab, "."} then exit repeat
		end repeat
		if endOfStream() then
			set my currToken to missing value
			return my currToken
		end if
		set my currToken to c
		if c is "=" then return my currToken
		repeat
			set c to nextChar()
			if my state is UNQUOTED then
				if c is in {space, tab, ".", "=", my EOS} then
					exit repeat
				else
					set my currToken to my currToken & c
				end if
			else if my state is in {SINGLE_QUOTED, DOUBLE_QUOTED} then
				if c is my EOS then
					exit repeat
				else
					set my currToken to my currToken & c
				end if
			end if
		end repeat
		putBack()
		return my currToken
	end nextToken
	
	(*! @abstract Returns true if the end of the stream has been reached; returns false otherwise. *)
	on endOfStream()
		my npos > my streamLength
	end endOfStream
	
	(*!
		@abstract
			Gets the next character from the command string, considering quoted characters.
		@discussion
			Returns the next unread character, taking into account that a character may be <it>quoted</it>
			(that is, made to stand for itself) by preceding it with a <tt>\</tt> (backslash).
			A backslash at the end of the command string is ignored.
			
			All characters enclosed between a pair of single quotes (<tt>'</tt>) are quoted. A single quote
			cannot appear within single quotes. For example, <tt>'\\'</tt> stands for <tt>\\</tt>.
			
			Inside double quotes (<tt>"</tt>), a <tt>\</tt> quotes the characters <tt>\</tt> and <tt>"</tt>.
			That is, <tt>\\</tt> stands for <tt>\</tt> and <tt>\"</tt> stands for <tt>"</tt>.

		@return
			The next unread character, considering escaping. If at the end of the stream, returns the empty string.
	*)
	on nextChar()
		set c to getChar()
		if c is my EOS then return c -- end of stream
		if my state is UNQUOTED then
			if c is "'" then -- enter single-quoted state
				set my state to SINGLE_QUOTED
				return nextChar()
			else if c is quote then -- enter double-quoted state
				set my state to DOUBLE_QUOTED
				return nextChar()
			else if c is "\\" then -- escaped character
				return getChar()
			else
				return c
			end if
		else if my state is SINGLE_QUOTED then
			if c is "'" then -- exit single-quoted state
				set my state to UNQUOTED
				return nextChar()
			else
				return c
			end if
		else if my state is DOUBLE_QUOTED then
			if c is quote then -- exit double-quoted state
				set my state to UNQUOTED
				return nextChar()
			else if c is "\\" then
				set c to getChar()
				if c is in {quote, "\\"} then return c
				putBack()
				return "\\"
			else
				return c
			end if
		end if
		error "nextChar(): Internal error (lexical analyzer)"
	end nextChar
	
	(*!
		@abstract
			Gets a character from the command string.
		@returns
			The next character to be read, or the empty string if the end of the stream has been reached.
	*)
	on getChar()
		if endOfStream() then return my EOS
		set my npos to (my npos) + 1
		character (npos - 1) of my stream
	end getChar
	
	(*!
		@abstract
			Puts the last read character back into the stream.
		@discussion
			If the end of the stream has been reached, this handler is a no-op.
		@return
			The value of @link npos@/link.
	*)
	on putBack()
		if endOfStream() then return my npos
		set my npos to (my npos) - 1
	end putBack
	
	on syntaxError(msg)
		local sp
		set sp to ""
		repeat with i from 1 to npos - (length of my currToken) - 1
			set sp to sp & space
		end repeat
		set sp to sp & "^"
		log stream
		log sp
		log msg
		error msg
	end syntaxError
	
end script

on findTask(action)
	repeat with t in (a reference to TaskBase's TASKS)
		if action = t's name or action is in t's synonyms then return t
	end repeat
	error
end findTask

on runTask(action)
	local t
	set TaskBase's PWD to POSIX path of (path to me) -- path of makefile.applescript
	try
		CommandLineParser's parse(action)
		set t to findTask(Args's command)
	on error errMsg number errNum
		ofail("Wrong task specification: " & action, "")
		error errMsg number errNum
	end try
	set t's arguments to Args
	try
		run t
		if t's printSuccess then ohai("Success!")
	on error errMsg number errNum
		ofail("Task failed", "")
		error errMsg number errNum
	end try
end runTask

on run {action}
	if action is "__ASMAKE__LOAD__" then -- Allow loading ASMake from text format with run script
		return me
	else
		runTask(action)
	end if
end run
