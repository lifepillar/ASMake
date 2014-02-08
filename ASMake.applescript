(*!
 @header ASMake
 	A simple AppleScript build library.
 @abstract
 	A draft of a primitive replacement for rake, make, etcÉ, in pure AppleScript.
 @author Lifepillar
 @copyright 2014 Lifepillar
 @version 0.1.0
 @charset macintosh
*)
property name : "ASMake"
property version : "0.1.0"
property id : "com.lifepillar.ASMake"

(*! @abstract A script object to help print colored output to the terminal. *)
script Stdout
	(*! @abstract The parent of this object. *)
	property parent : AppleScript
	(*! @abstract The basic escape sequence. *)
	property esc : "\\033["
	(*! @abstract The escape sequence for black. *)
	property black : esc & "0;30m"
	(*! @abstract The escape sequence for blue. *)
	property blue : esc & "0;34m"
	(*! @abstract The escape sequence for cyan. *)
	property cyan : esc & "0;36m"
	(*! @abstract The escape sequence for green. *)
	property green : esc & "0;32m"
	(*! @abstract The escape sequence for magenta. *)
	property magenta : esc & "0;35m"
	(*! @abstract The escape sequence for purple. *)
	property purple : esc & "0;35m"
	(*! @abstract The escape sequence for red. *)
	property red : esc & "0;31m"
	(*! @abstract The escape sequence for yellow. *)
	property yellow : esc & "0;33m"
	(*! @abstract The escape sequence for white. *)
	property white : esc & "0;37m"
	(*! @abstract The reset escape sequence. *)
	property reset : esc & "0m"
	
	(*!
		@abstract
			Colors the given text using the specified color.
		@param
			s <em>[text]</em> Some text.
		@param
			kolor <em>[text]</em> One of @link Stdout@/link's color constants.
		@return
			<em>[text]</em> The text with suitable ANSI escape codes for the given color.
	*)
	on col(s, kolor)
		set s to kolor & s & reset
	end col
	
	(*!
		@abstract
			Makes a bold color.
		@param
			kolor <em>[text]</em> One of the color constants.
		@return
			<em>[text]</em> The escape sequence for the bold version of the given color.
	*)
	on bb(kolor)
		esc & "1;" & text -3 thru -1 of kolor
	end bb
	
	(*!
		@abstract
			Sends a message to the terminal.
		@discussion
			This is the low-level procedure that is used to print anything.
			It is implemented to support ASCII escape sequences, so that
			colored terminal output can be obtained.
	*)
	on echo(msg)
		set msg to do shell script "echo " & quoted form of msg without altering line endings
		log text 1 thru -2 of msg -- Remove last linefeed
	end echo
	
	(*! @abstract Prints a notice. *)
	on ohai(msg)
		echo(green & "==>" & space & bb(white) & msg & reset)
	end ohai
	
	(*! @abstract Prints a failure message, with details. *)
	on ofail(msg, info)
		set msg to red & "Fail:" & space & bb(white) & msg & reset
		if info is not "" then set msg to msg & linefeed & info
		echo(msg)
	end ofail
	
	(*! @abstract Prints a warning. *)
	on owarn(msg)
		echo(red & "Warn:" & space & bb(white) & msg & reset)
	end owarn
	
end script -- Stdout

(*! @abstract The script object common to all tasks. *)
script TaskBase
	
	(*! @abstract The parent of this object. *)
	property parent : Stdout
	
	(*! @abstract The class of a task object. *)
	property class : "Task"
	
	(*!
		@abstract
			The list of registered tasks.
		@discussion
			This is a read-only property that should not be overridden by inheriting tasks.
			The value of this property is updated automatically at compile-time whenever
			a task script is compiled.
	*)
	property TASKS : {}
	
	(*!
		@abstract
			The POSIX path of the working directory.
		@discussion
			This is a read-only property that should not be overridden by inheriting tasks.
			The value of this property is set automatically when a makefile is executed.
	*)
	property PWD : missing value
	
	(*! @abstract Defines a list of aliases for this task. *)
	property synonyms : {}
	
	(*!
		@abstract
			Stores a reference to the @link TaskArguments @/link script object.
		@discussion
			Tasks that expect arguments can fetch them through this property.
	*)
	property arguments : {}
	
	(*! @abstract A description for this task. *)
	property description : "No description."
	
	(*!
		@abstract
			Flag to determine whether a success message should be printed
			when a tasks completes without error.
	*)
	property printSuccess : true
	
	(*!
		@abstract
			Set this to true for private tasks.
		@discussion
			A private task is not registered (see @link Task @/link()), hence it is not visible to the user.
			If this property is overridden, it must appear <em>before</em> the <code>parent</code> property.
	*)
	property private : false
	
	(*!
		@abstract
			Removes the trailing newline from the text, if present.
		@param
			t <em>[text]</em> A string.
		@return
			<em>[text]</em> The string with the trailing newline removed,
			or <code>t</code> itself if it does not have a trailing newline.
	*)
	on chomp(t)
		if t ends with linefeed then
			if t is linefeed then return ""
			if character -2 of t is return then
				if t is return & linefeed then return ""
				return text 1 thru -3 of t
			end if
			return text 1 thru -2 of t
		end if
		if t ends with return then
			if t is return then return ""
			return text 1 thru -2 of t
		end if
		return t
	end chomp
	
	(*
		@abstract
			Copies one or more files to the specified destination.
		@discussion
			This is an interface to the <code>cp</code> command.
			The arguments may be POSIX paths or HFS+ paths.
			A list of source paths can be used.
		@param
			src <em>[text]</em> or <em>[list]</em>: A path or a list of paths.
				Glob patterns are accepted.
		@param
			dst <em>[text]</em>: the destination path.
	*)
	on cp(src, dst)
		sh("/bin/cp", {"-r"} & normalizePaths(src) & normalizePaths(dst))
	end cp
	
	(* @abstract Returns true if this is a dry run; returns false otherwise. *)
	on dry()
		my arguments's options contains "--dry" or my arguments's options contains "-n"
	end dry
	
	(*!
		@abstract
			Expands a glob pattern.
		@param
			pattern <em>[text]</em> A glob pattern (e.g., "build/*.scpt")
		@return
			<em>[list]</em> The list of paths matching the pattern.
	*)
	on glob(pattern)
		the paragraphs of (do shell script "cd" & space & quoted form of my PWD & Â
			";list=(" & pattern & ");for f in \"${list[@]}\";do echo \"$f\";done")
	end glob
	
	(*!
		@abstract
			Creates one or more folders at the specified path(s).
		@param
			dst <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
	*)
	on mkdir(dst)
		sh("/bin/mkdir", {"-p"} & normalizePaths(dst))
	end mkdir
	
	(*!
		@abstract
			Normalizes paths.
		@discussion
			This handler receives a path or a list of paths, which may be
			POSIX paths, HFS+ paths or glob patterns, and returns a list
			of (absolute or relative) POSIX paths, where glob patterns
			have been expanded to the appropriate paths.
		@param
			src <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@return
			<em>[list]</em> A list of POSIX paths.
	*)
	on normalizePaths(src)
		local res
		set res to {}
		if src's class is not list then set src to {src}
		repeat with s in src
			if s's class is in {file, alias, Çclass furlÈ} then
				set the end of res to POSIX path of s
			else if s contains "*" then -- assume it is a glob pattern
				set res to res & glob(s)
			else
				set the end of res to s
			end if
		end repeat
		return res
	end normalizePaths
	
	(*!
		@abstract
			Compiles one or more scripts.
		@param
			src <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@param
			target <em>[text]</em> The type of the result, which can be <code>scpt</code>, <code>scptd</code>, or <code>app</code>, for a script, script bundle, or applet, respectively.
		@param
			opts <em>[list]</em> A list of <code>osacompile</code> options
			(see <code>man osacompile</code>).
	*)
	on osacompile(src, target, opts)
		local basename
		repeat with s in normalizePaths(src)
			if s ends with ".applescript" then
				set basename to text 1 thru -13 of s -- remove suffix
			else
				set basename to s
			end if
			sh("/usr/bin/osacompile", {"-o", basename & "." & target} & opts & {basename & ".applescript"})
		end repeat
	end osacompile
	
	(*! @abstract Deletes one or more paths. *)
	on rm(dst)
		sh("/bin/rm", {"-fr"} & normalizePaths(dst))
	end rm
	
	(*! @abstract Executes a given command. *)
	on sh(command, opts)
		local output
		if opts's class is not list then set opts to {opts}
		repeat with opt in opts
			set command to command & space & quoted form of opt
		end repeat
		if verbose() then echo(command)
		if dry() then return command
		-- Execute the command in the working directory
		set command to Â
			"cd" & space & quoted form of my PWD & ";" & command & space & "2>&1"
		set output to (do shell script command)
		if verbose() and output is not equal to "" then echo(output)
		return output
	end sh
	
	(*!
		@abstract
			Returns true if the user has requested verbose output;
			returns false otherwise.
	*)
	on verbose()
		my arguments's options contains "--verbose" or my arguments's options contains "-v"
	end verbose
	
	(*! @abstract Interface for the <code>which</code> command. *)
	on which(command)
		try
			sh("/usr/bin/which", command)
		on error
			missing value
		end try
	end which
end script

(*!
	@abstract
		Registers a task.
	@discussion
		This handler is used to register a task at compile-time
		and to set the parent of a script to @link TaskBase @/link.
		Every task script must inherit from <code>Task(me)</code>.
*)
on Task(t)
	try -- t may not define the private property at this time
		if t's private then return TaskBase
	end try
	set the end of TaskBase's TASKS to t
	return TaskBase
end Task

-- Predefined tasks

(*! @abstract Task to print the list of available tasks. *)
script HelpTask
	property parent : Task(me)
	property name : "help"
	property description : "Show the list of available tasks and exit."
	property printSuccess : false
	set nameLen to 0
	repeat with t in my TASKS -- find the longest name
		if the length of t's name > nameLen then set nameLen to the length of t's name
	end repeat
	repeat with t in my TASKS
		set spaces to space & space
		repeat with i from 1 to nameLen - (length of t's name)
			set spaces to spaces & space
		end repeat
		echo(bb(my white) & t's name & my reset & spaces & t's description)
	end repeat
end script

(*! @abstract Task to print the path of the working directory. *)
script WorkDir
	property parent : Task(me)
	property name : "pwd"
	property synonyms : {"wd"}
	property description : "Print the path of the working directory and exit."
	property printSuccess : false
	ohai(my PWD)
end script

(*! @abstract The parent of the top-level script. *)
property parent : Stdout

(*!
	@abstract
		A script object representing the command-line arguments.
	@discussion
		This is passed to the task.
*)
script TaskArguments
	property parent : AppleScript
	
	(*! @abstract The name of the task to be executed. *)
	property command : ""
	
	(*! @abstract A list of ASMake options. *)
	property options : {}
	(*!
		@abstract
			A list of keys from command-line options.
		@discussion
			This property stores they keys of command-line options of the form <code>key=value</code>.
			For flags and command-line switches, it stores their names as they are,
			unless they start with <code>no-</code>, <code>-no-</code>, or <code>--no-</code>, in which case
			such prefix is removed.
	*)
	property keys : {}
	(*!
		@abstract
			A list of values from command-line options.
		@discussion
			This property stores they values of command-line options of the form <code>key=value</code>.
			For flags and command-line switches, it stores the value <code>true</code> unless the switch
			starts with <code>no-</code>, <code>-no-</code>, or <code>--no-</code>, in which case it stores
			the value <code>false</code>.
	*)
	property values : {}
	
	(*! @abstract Returns the number of arguments. *)
	on numberOfArguments()
		my values's length
	end numberOfArguments
	
	(*! @abstract Clears the arguments. *)
	on clear()
		set command to ""
		set options to {}
		set keys to {}
		set values to {}
	end clear
	
	(*!
		@abstract
			Retrieves the argument with the given key.
		@param
			key <em>[text]</em> the key to look up.
		@param
			default <em>[text]</em> The value to be returned if the key is not found.
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
		local i, n
		set n to numberOfArguments()
		repeat with i from 1 to n
			if item i of my keys is key then
				local val
				set val to item i of my values
				if i = 1 then
					set my keys to the rest of my keys
					set my values to the rest of my values
				else if i = n then
					set my keys to items 1 thru (i - 1) of my keys
					set my values to items 1 thru (i - 1) of my values
				else
					set my keys to (items 1 thru (i - 1) of my keys) & (items (i + 1) thru -1 of my keys)
					set my values to (items 1 thru (i - 1) of my values) & (items (i + 1) thru -1 of my values)
				end if
				return val
			end if
		end repeat
		default
	end fetchAndDelete
	
	(*!
		@abstract
			Retrieves the first argument and removes it from the list of arguments.
		@return
			A pair {key, value}, or {missing value,missing value} if there are no arguments.
		*)
	on shift()
		if numberOfArguments() is 0 then return {missing value, missing value}
		local k, v
		set {k, v} to {the first item of my keys, the first item of my values}
		set {my keys, my values} to {the rest of my keys, the rest of my values}
		{k, v}
	end shift
	
end script

(*! @abstract A script object for collecting and parsing command-line arguments. *)
script CommandLineParser
	
	(*! @abstract The parent of this object. *)
	property parent : AppleScript
	
	(*!
		@abstract
			The string to be parsed.
		@discussion
			Typically, this is the full command string. For example, given this command:
			<pre>
			asmake --debug taskname key=value
			</pre>
			
			this property is set to <code>--debug taskname key=value</code>.
	*)
	property stream : ""
	
	(*! @abstract The length of the command string. *)
	property streamLength : 0
	
	(*!
		@abstract
			The index of the next character to be read from the stream.
		@discussion
			This property always points to the next character to be read.
			This invariant for is maintained by @link nextChar@/link().
	*)
	property npos : 1
	
	(*! @abstract A constant denoting the absence of a token. *)
	property NO_TOKEN : ""
	
	(*! @abstract The current token. *)
	property currToken : my NO_TOKEN
	
	(*! @abstract The character signalling that the stream has been consumed. *)
	property EOS : ""
	
	(*! @abstract A constant used by the lexical analyzer to denote an unquoted state. *)
	property UNQUOTED : space
	
	(*! @abstract A constant used by the lexical analyzer to denote a single-quoted state. *)
	property SINGLE_QUOTED : "'"
	
	(*! @abstract A constant used by the lexical analyzer to denote a double-quoted state. *)
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
		set currToken to my NO_TOKEN
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
			
			Only the name of the task is mandatory.
			The full grammar for a command-line string is as follows (terminals are enclosed in quotes):
			
			<pre>
--			CommandLine ::= OptionList TaskName ArgList
--			OptionList ::= Option OptionList | ''
--			Option ::= '-<string>' | '--<string>'
--			TaskName ::= '<string>'
--			ArgList ::= Arg ArgList | ''
--			Arg ::= <string>' '=' '<string>'
			</pre>

		Since ASMake can accept only a single argument, the whole command line string
		must be enclosed in quotes. Alternatively, ASMake interprets a dot as a space.
		Examples:

			<pre>
			asmake help
			asmake "build target=dev"
			asmake build.target=dev
			asmake 'build targets="dev test"'
			</pre>
	*)
	on parse(commandLine)
		set my stream to commandLine
		set my streamLength to the length of my stream
		set currToken to my NO_TOKEN
		set my state to my UNQUOTED
		set my npos to 1
		optionList()
		taskName()
		argList()
	end parse
	
	(*! @abstract Parses a possibly empty list of ASMake options. *)
	on optionList()
		nextToken()
		if my currToken starts with "-" then
			set the end of TaskArguments's options to my currToken
			optionList()
		end if
	end optionList
	
	(*! @abstract Parses a task name. *)
	on taskName()
		if my currToken is my NO_TOKEN then syntaxError("Missing task name")
		if nextChar() is "=" then
			putBack()
			syntaxError("Missing task name")
		end if
		putBack()
		set TaskArguments's command to my currToken
	end taskName
	
	(*! @abstract Parses a possibly empty list of key-value arguments. *)
	on argList()
		nextToken()
		if my currToken is my NO_TOKEN then return -- no arguments
		arg()
		argList()
	end argList
	
	(*! @abstract Parses a key-value argument. *)
	on arg()
		set the end of TaskArguments's keys to my currToken
		nextToken()
		if my currToken is not "=" then syntaxError("Arguments must have the form key=value")
		nextToken()
		set the end of TaskArguments's values to my currToken
	end arg
	
	(*!
		@abstract
			Gets the next token from the stream.
		@return
			<em>[text]</em> The next token or the constant @link NO_TOKEN	@/link no token can be retrieved.
	*)
	on nextToken()
		local c
		repeat -- skip white space
			set c to nextChar()
			if c is not in {space, tab, "."} then exit repeat
		end repeat
		if c is my EOS then
			set my currToken to my NO_TOKEN
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
	
	(*!
		@abstract
			Tests whether the stream has been consumed.
		@return
			<em>[boolean]</em> True if the end of the stream has been reached; false otherwise.
	*)
	on endOfStream()
		my npos > my streamLength
	end endOfStream
	
	(*!
		@abstract
			Gets the next character from the command string, considering quoted characters.
		@discussion
			A character may be <it>quoted</it> (that is, made to stand for itself) by preceding it
			with a <code>\</code> (backslash). A backslash at the end of the command string is ignored.
			
			All characters enclosed between a pair of single quotes (<code>'</code>) are quoted.
			For example, <code>'\\'</code> stands for <code>\\</code>.
			A single quote cannot appear within single quotes.
			
			Inside double quotes (<code>"</code>), a <code>\</code> quotes the characters <code>\</code> and <code>"</code>.
			That is, <code>\\</code> stands for <code>\</code> and <code>\"</code> stands for <code>"</code>.

		@return
			<em>[text]</em> The next unread character (considering escaping)
			or @link EOS @/link if at the end of the stream.
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
		@discussion
			This is the low-level procedure that extracts the next character from the stream.
			This handler treats the stream as a sequence of characters without interpreting them.
			In other words, it does not take quoting into account.
		@returns
			<em>[text]</em> The next unread character,
			or @link EOS @/link if the end of the stream has been reached.
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
	
	(*! @abstract The handler called when a syntax error occurs. *)
	on syntaxError(msg)
		local sp, n
		set sp to ""
		if my currToken is my NO_TOKEN then
			set n to 0
		else
			set n to the length of my currToken
		end if
		repeat with i from 1 to (my npos) - n - 1
			set sp to sp & space
		end repeat
		set sp to sp & "^"
		error msg & linefeed & my stream & linefeed & sp
	end syntaxError
	
end script -- CommandLineParser

(*!
	@abstract
		Retrieves the task specified by the user.
	@param
		taskname <em>[text]</em> The task name.
	@return
		The task specified by the user, if found.
	@throw
		An exception if the task is not found.
*)
on findTask(taskName)
	repeat with t in (a reference to TaskBase's TASKS)
		if taskName = t's name or taskName is in t's synonyms then return t
	end repeat
	error
end findTask

(*!
	@abstract
		Executes a task.
	@param
		action <em>[text]</em> The command-line string.
	@throw
		An error if the command contains syntax error,
		if the task with the specified name does not exist,
		or if the task fails.
*)
on runTask(action)
	local t
	set TaskBase's PWD to do shell script "pwd"
	try
		CommandLineParser's parse(action)
	on error errMsg
		ofail("Syntax error", errMsg)
		error
	end try
	try
		set t to findTask(TaskArguments's command)
	on error errMsg number errNum
		ofail("Unknown task: " & TaskArguments's command, "")
		error errMsg number errNum
	end try
	set t's arguments to TaskArguments
	try
		run t
		if t's printSuccess then ohai("Success!")
		if t's dry() then ohai("(This was a dry run)")
	on error errMsg number errNum
		ofail("Task failed", "")
		error errMsg number errNum
	end try
end runTask

(*! @abstract The handler invoked by <tt>osascript</tt>. *)
on run {action}
	if action is "__ASMAKE__LOAD__" then -- Allow loading ASMake from text format with run script
		return me
	else
		runTask(action)
	end if
end run
