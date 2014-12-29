(*!
 @header ASMake
 	A simple AppleScript build library.
 @abstract
 	A draft of a primitive replacement for rake, make, etcÉ, in pure AppleScript.
 @author Lifepillar
 @copyright 2014 Lifepillar
 @version 0.2.1
 @charset macintosh
*)
use AppleScript version "2.4"
use scripting additions

property name : "ASMake"
property id : "com.lifepillar.ASMake"
property version : "0.2.1"

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
	(*! @abstract The escape sequence for bold type. *)
	property boldType : esc & "1m"
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
		echo(col("==>", green) & space & boldType & (msg as text) & reset)
	end ohai
	
	(*! @abstract Prints a failure message, with details. *)
	on ofail(msg, info)
		set msg to col("Fail:", red) & space & boldType & (msg as text) & reset
		if info as text is not "" then set msg to msg & linefeed & (info as text)
		echo(msg)
	end ofail
	
	(*! @abstract Prints a warning. *)
	on owarn(msg)
		echo(col("Warn:", red) & space & boldType & (msg as text) & reset)
	end owarn
	
	(*!
		@abstract
			Prints a debugging message.
		@param
			info <em>[text]</em> or <em>[list]</em>: a message or a list of messages.
	*)
	on odebug(info)
		if class of info is not list then
			echo(col("DEBUG:", red) & space & boldType & (info as text) & reset)
			return
		end if
		set msg to (col("DEBUG:", red) & space & boldType & (item 1 of info) as text) & reset
		repeat with i from 2 to count info
			set msg to msg & linefeed & ((item i of info) as text)
		end repeat
		echo(msg)
	end odebug
	
end script -- Stdout

(*! @abstract The script object common to all tasks. *)
script TaskBase
	
	use framework "Foundation"
	use framework "OSAKit"
	
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
			A private task is not registered (see @link Task() @/link), hence it is not visible to the user.
			If this property is overridden, it must appear <em>before</em> the <code>parent</code> property.
	*)
	property private : false
	
	(*!
		@abstract
			Builds an NSURL object from the given path.
		@discussion
			This handler assumes that <tt>somePath</tt> is a directory if its POSIX version ends with a slash.
			If it does not end with a slash, the handler examines the file system to determine
			if <tt>somePath</tt> is a file or a directory. If <tt>somePath</tt> exists in the
			file system and is a directory, the method appends a trailing slash.
			If <tt>somePath</tt> does not exist in the file system, the handler assumes that
			it represents a file and does not append a trailing slash.
			This handler also removes all instances of <tt>.</tt> and <tt>..</tt>.

			This handler is used internally by ASMake to build an NSURL. User code
			should never call this directly.
		@param
			somePath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A relative or absolute path.
		@return
			<em>[current application's NSURL]</em> An NSURL object.
	*)
	on _fileURL(somePath)
		(current application's NSURL's fileURLWithPath:(my posixPath(somePath)))'s standardizedURL
	end _fileURL
	
	(*!
		@abstract
			Returns true if the user has requested debugging output;
			returns false otherwise.
	*)
	on debug()
		my arguments's options contains "--debug" or my arguments's options contains "-D"
	end debug
	
	(*! @abstract Returns true if this is a dry run; returns false otherwise. *)
	on dry()
		my arguments's options contains "--dry" or my arguments's options contains "-n"
	end dry
	
	(*!
		@abstract
			Returns true if the user has requested verbose output;
			returns false otherwise.
	*)
	on verbose()
		my arguments's options contains "--verbose" or my arguments's options contains "-v"
	end verbose
	
	
	---------------------------------------------------------------------------------------
	-- Shell commands
	---------------------------------------------------------------------------------------
	
	(*!
		@abstract
			Executes a shell command.
		@discussion
			This handler provides an interface to run a shell script via
			<code>do shell script</code>. All the features of <code>do shell script</code>
			are supported, including running a command with administrator privileges.
			For example, a command run as <code>nick</code>
			with password <code>xyz123</code> may look as follows:
			<pre>
			shell for "mycmd" with privileges given options:{"--some", "--options"},
			  username:"nick", |password|:"xyz123"
			</pre>
			Output redirection is supported, too, as well as altering line endings, e.g.:
			<pre>
			shell for "mycmd" given out:"/some/file", err:"&1", alteringLineEndings:false
			</pre>
			This handler uses the syntax introduced is OS X 10.10 (Yosemite) for optional labeled parameters. 
			Apart from the <tt>for</tt> parameter, all other arguments are optional (and may appear in any order).
		@param
			command <em>[text]</em> The command to be executed.
		@param
			options <em>[text]</em> or <em>[list]</em> An argument or a list of arguments
			for the command (internally, the handler always converts this
			to a list). Each option is quoted before the command is executed.
		@param
			privileges <em>[boolean]</em> A flag indicating whether the command should be executed as a different user.
			The default is <tt>false</tt>.
		@param
			username <em>[text]</em> The username that should execute the command.
			This argument is ignored unless <tt>privileges</tt> is set to <tt>true</tt>.
		@param
			pass <em>[text]</em> The password to be authenticated as <tt>username</tt>.
		@param
			out <em>[text]</em> Redirect the standard output to the specified file.
		@param
			err <em>[text]</em> Redirect the standard error to the specified file.
			Pass <tt>&1</tt> to redirect to the standard output.
		@param
			ale <em>[boolean]</em> Whether line endings should be changed or not.
			The default is <tt>true</tt>.
		@return
			<em>[text]</em> The output of the command.
			If ASMake is run with <code>--dry</code>, returns the text of the command.
		@throws
			An error if the shell script exits with non-zero status.
			The error number is the exit status of the command.
	*)
	on shell for command given options:options : {}, privileges:privileges : false, username:username : missing value, |password|:pass : missing value, out:out : "", err:err : "", alteringLineEndings:ale : true
		if options's class is not list then set options to {options}
		if out is not "" then set out to space & ">" & quoted form of out
		if err is not "" then
			if err is "&1" then -- Allow redirecting stderr to stdout
				set err to space & "2>&1"
			else
				set err to space & "2>" & quoted form of err
			end if
		end if
		set command to command & space & (my join(my map(options, my quoteText), space)) & out & err
		if my verbose() then my echo(command)
		if my dry() then return command
		set command to "cd" & space & quoted form of my PWD & ";" & command
		if pass is missing value then
			set output to (do shell script command administrator privileges privileges altering line endings ale)
		else
			if username is missing value then set username to short user name of (system info)
			set output to (do shell script command administrator privileges privileges user name username password pass altering line endings ale)
		end if
		if my verbose() and output is not "" then my echo(output)
		return output
	end shell
	
	
	---------------------------------------------------------------------------------------
	-- Path manipulation
	---------------------------------------------------------------------------------------
	
	(*!
		@abstract
			Converts a path to an absolute POSIX path. An existing trailing slash is stripped.
		@param
			somePath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A relative or absolute path.
		@return
			<em>[text]</em> A full POSIX path.
	*)
	on absolutePath(somePath)
		(my _fileURL(somePath))'s |path| as text
	end absolutePath
	
	(*!
		@abstract
			Returns the last component of the given path.
		@param
			somePath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A path.
		@return
			<em>[text]</em> The last component of the path.
	*)
	on basename(somePath)
		(my _fileURL(somePath))'s lastPathComponent as text
	end basename
	
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
	
	(*!
		@abstract
			Removes a trailing slash from a POSIX path.
		@param
			p <em>[text]</em> A POSIX path.
		@return
			<em>[text]</em> A copy of <code>p</code> with the trailing slash removed,
			or <code>p</code> itself if not trailing slash is present.
	*)
	on deslash(p)
		if the last character of p is not "/" then return p
		local i
		set i to 0
		repeat while the last character of text 1 thru ((count p) - i) of p is "/"
			set i to i + 1
		end repeat
		text 1 thru ((count p) - i) of p
	end deslash
	
	(*!
		@abstract
			Returns the absolute path of the directory containing the given path.
			If the path has a trailing slash, it is stripped.
		@param
			somePath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A path.
		@return
			<em>[text]</em> A POSIX path.
	*)
	on directoryPath(somePath)
		(my _fileURL(somePath))'s URLByDeletingLastPathComponent's relativePath as text
	end directoryPath
	
	(*!
		@abstract
			Expands a glob pattern.
		@discussion
			Returns a list of POSIX paths obtained by expanding a glob pattern
			according to the rules of the shell. Note that the argument of this
			handler is not quoted: if quoting is necessary, it must be applied by
			the caller (e.g., <code>glob("/some/'path with spaces'/*")</code>.
		@param
			pattern <em>[text]</em> or <em>[list]</em> A glob pattern (e.g., "build/*.scpt")
			or a list of glob patterns.
		@return
			<em>[list]</em> The list of paths matching the pattern.
	*)
	on glob(pattern)
		if the class of pattern is not list then set pattern to {pattern}
		local res
		set res to {}
		repeat with p in pattern
			set res to res & the paragraphs of (do shell script "cd" & space & quoted form of my PWD & Â
				";list=(" & p & ");for f in \"${list[@]}\";do echo \"$f\";done")
		end repeat
		return res
	end glob
	
	(*!
	@abstract
		Returns a new POSIX path formed by joining a base path and a relative path.
		If the relative path has a trailing slash, it is stripped.
		The resulting path is relative is base path is relative.
	@param
		basePath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
		A path.
	@param
		relPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
		A relative path.
	@return
		<em>[text]</em> A POSIX path.
	*)
	on joinPath(basePath, relPath)
		((my _fileURL(basePath))'s URLByAppendingPathComponent:(my posixPath(relPath)))'s relativePath as text
	end joinPath
	
	(*!
		@abstract
			Splits the absolute version of the given path into its components.
		@param
			somePath <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			A path.
		@return
			<em>[list]</em> The components of the given paths.
		@seealso
			basename
		@seealso
			directoryPath
	*)
	on pathComponents(somePath)
		(my _fileURL(somePath))'s pathComponents as list
	end pathComponents
	
	(*!
		@abstract
			Checks whether the given file or directory exists on disk.
			Relative paths are resolved with respect to the working directory.
		@param
			somePath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A relative or absolute path.
		@return
			<em>[boolean]</em> <tt>true</tt> is the path exists, <tt>false</tt> otherwise.
	*)
	on pathExists(somePath)
		try
			(my absolutePath(somePath) as POSIX file) as alias
			true
		on error
			false
		end try
	end pathExists
	
	(*!
		@abstract
			Turns (almost) any path specification into a POSIX path.
		@discussion
			This handler receives a path, in text form or as a file object or an alias,
			and returns it as a (relative or absolute) POSIX path.
			It does <em>not</em> perform any glob expansion
			(cf. @link glob()@/link).
			This handler generalizes AppleScript's <code>POSIX path of</code>:
			in particular, it can be safely applied to relative POSIX paths
			(for example, <code>POSIX path of "."</code> is <code>"/./"</code>,
			but <code>posixPath(".")</code> is still <code>"."</code>).
		@seealso
			posixPaths
		@param
			src <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A path.
		@return
			<em>[text]</em> A POSIX path.
	*)
	on posixPath(src)
		considering punctuation
			if src's class is text and src does not contain ":" then return the contents of src
		end considering
		return POSIX path of src
	end posixPath
	
	(*!
		@abstract
			Returns one or more paths as POSIX paths.
		@discussion
			This handler receives a path or a list of paths, which may be
			POSIX paths or HFS+ paths, and returns a list
			of (absolute or relative) POSIX paths. Nested lists of paths are also
			accepted, and they are flattened.
		@seealso
			posixPath
		@param
			src <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@return
			<em>[list]</em> A list of POSIX paths.
	*)
	on posixPaths(src)
		local res
		set res to {}
		if src's class is not list then set src to {src}
		repeat with s in src
			if the class of s is list then
				set res to res & posixPaths(s)
			else
				set the end of res to posixPath(s)
			end if
		end repeat
		return res
	end posixPaths
	
	(*!
		@abstract
			Splits the given path into a directory and a file component.
			If the given path is relative then the directory component is relative, too.
		@param
			somePath <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			A path.
		@return
			<em>[list]</em> A two-element list.
		@seealso
			basename
		@seealso
			directoryPath
	*)
	on splitPath(somePath)
		local base
		set base to my _fileURL(somePath)
		{base's URLByDeletingLastPathComponent's relativePath as text, base's lastPathComponent as text}
	end splitPath


	---------------------------------------------------------------------------------------
	-- File manipulation
	---------------------------------------------------------------------------------------
	
	(*!
		@abstract
			Copies one or more files to the specified destination.
		@discussion
			This is an interface to the <code>cp</code> command.
			The arguments may be POSIX paths or HFS+ paths.
			A list of source paths can be used.
		@param
			src <em>[text]</em> or <em>[list]</em>: A path or a list of paths.
		@param
			dst <em>[text]</em>: the destination path.
	*)
	on cp(src, dst)
		shell for "/bin/cp" given options:{"-r"} & posixPaths(src) & posixPaths(dst)
	end cp
	
	(*!
		@abstract
			Copies one or more source files or directories to a destination directory,
			or a source file to a destination file.
		@discussion
			This handler uses <code>ditto</code> to copy directory hierarchies.
			See <code>man ditto</code> for further information.
			Note that <code>ditto</code> does not copy items the same way as
			<code>cp</code> does. In particular, <code>ditto("foo", "bar")</code>
			will copy the contents of directory <code>foo</code> into <code>bar</code>,
			whereas <code>cp("foo", "bar")</code> will copy <code>foo</code> itself
			into <code>bar</code>.
		@param
			src <em>[text]</em> or <em>[list]</em>: A path or a list of paths.
		@param
			dst <em>[text]</em>: the destination path.
	*)
	on ditto(src, dst)
		set flags to {}
		if verbose() then set the end of flags to "-V"
		shell for "/usr/bin/ditto" given options:flags & posixPaths(src) & posixPaths(dst)
	end ditto
	
	(*!
		@abstract
			Creates a Finder alias.
		@param
			source <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			The source path.
		@param
			target <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			The path to the Finder alias to be created.
	*)
	on makeAlias(source, target)
		local src, tgt, dir, base
		set src to my absolutePath(source)
		set tgt to my absolutePath(target)
		set {dir, base} to my splitPath(tgt)
		if verbose() then Â
			echo("Make alias at" & space & (dir as text) & space & Â
				"to" & space & (src as text) & space & Â
				"with name" & space & (base as text))
		if not dry() then
			tell application "Finder" to make new alias file at POSIX file dir to POSIX file src with properties {name:base}
		else
			return {src, dir, base}
		end if
	end makeAlias
	
	(*!
		@abstract
			Creates one or more folders at the specified path(s).
		@param
			dst <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
	*)
	on mkdir(dst)
		shell for "/bin/mkdir" given options:{"-p"} & posixPaths(dst)
	end mkdir
	
	(*!
		@abstract
			Moves one or more files to the specified path.
		@discussion
			This handler does not overwrite the target if it exists.
		@param
			src <em>[text]</em> or <em>[list]</em>: A path or a list of paths.
				Glob patterns are accepted.
		@param
			dst <em>[text]</em>: the destination path.
	*)
	on mv(src, dst)
		local dest
		set dest to posixPath(dst)
		shell for "/bin/mv" given options:posixPaths(src) & dest
	end mv
	
	(*!
		@abstract
			Reads the content of the given file as UTF8-encoded text.
		@param
			filename <em>[text]</em> or <em>[file]</em> or <em>[alias]</em>: the file to read.
		@return
			<em>[text]</em> The content of the file.
	*)
	on readUTF8(fileName)
		set ff to my posixPath(fileName)
		set fp to open for access POSIX file ff without write permission
		try
			read fp as Çclass utf8È
			close access fp
		on error errMsg number errNum
			close access fp
			error errMsg number errNum
		end try
	end readUTF8
	
	(*!
		@abstract
			Deletes one or more paths.
		@param
			somePaths <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@throws
			An error if a file cannot be deleted, for example because it does not exist.
		@seealso
			rm_f
	*)
	on rm(somePaths)
		script PathWrapper
			property paths : my posixPaths(somePaths)
		end script
		
		if my dry() then
			return "Deleting" & space & my join(my map(a reference to PathWrapper's paths, my quoteText), ", ")
		end if
		
		local fileManager
		set fileManager to current application's NSFileManager's defaultManager()
		repeat with p in every item of (a reference to PathWrapper's paths)
			if verbose() then echo("Deleting" & space & p)
			set {succeeded, theError} to (fm's removeItemAtPath:(contents of p) |error|:(reference))
			if not succeeded then
				error (theError's localizedDescription as text) number (theError's code as integer)
			end if
		end repeat
	end rm
	
	(*!
		@abstract
			Deletes one or more paths, suppressing errors.
		@param
			somePaths <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@seealso
 			rm
	*)
	on rm_f(somePaths)
		try
			rm(somePaths)
		end try
	end rm_f

	(*!
		@abstract
			Creates a symbolic link.
		@param
			source <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			The source path.
		@param
			target <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			The symbolic link to be created.
	*)
	on symlink(source, target)
		set src to posixPath(source)
		set tgt to posixPath(target)
		shell for "/bin/ln" given options:{"-s"} & src & tgt
	end symlink
	
	(*!
		@abstract
			Writes the specified UTF8-encoded content to the given file.
		@param
			fileName <em>[text]</em> or <em>[file]</em> or <em>[alias]</em>: the file to write.
		@param
			content <em>[text]</em> The content to write.
	*)
	on writeUTF8(fileName, content)
		set ff to my posixPath(fileName)
		set fp to open for access POSIX file ff with write permission
		try
			write content to fp as Çclass utf8È
			close access fp
		on error errMsg number errNum
			close access fp
			error errMsg number errNum
		end try
	end writeUTF8


	---------------------------------------------------------------------------------------
	-- Script manipulation
	---------------------------------------------------------------------------------------
	
	(*
		@abstract
			Creates an empty script bundle.
		@param
			buildPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			The directory where the script bundle should be created.
		@param
			name <em>[text]</em> The name of the script bundle (with or without suffix).
	*)
	on emptyBundle at buildPath given name:bundleName : text
		local scriptPath, dummyScript, didSucceed, theError
		if bundleName does not end with ".scptd" then set bundleName to bundleName & ".scptd"
		set scriptPath to current application's NSURL's fileURLWithPath:(my joinPath(my posixPath(buildPath), bundleName))
		set dummyScript to current application's OSAScript's alloc's Â
			initWithSource:"" fromURL:(missing value) Â
				languageInstance:(current application's OSALanguage's defaultLanguage()'s sharedLanguageInstance()) Â
				usingStorageOptions:(current application's OSANull)
		set {didSucceed, theError} to dummyScript's compileAndReturnError:(reference)
		if not didSucceed then error theError
		set {didSucceed, theError} to dummyScript's Â
			writeToURL:scriptPath ofType:(current application's OSAStorageScriptBundleType) Â
				usingStorageOptions:(current application's OSANull) |error|:(reference)
		if not didSucceed then error theError
	end emptyBundle
	
	(*!
		@abstract
			Builds a script bundle from source, including resources and script libraries.
		@discussion
			TODO
		@param
			sourceFile <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>:
			path to the source file (a file with <code>.applescript</code> suffix).
	*)
	on makeScriptBundle(sourceFile)
		set sharedLibFolder to joinPath(path to library folder from user domain, "Script Libraries")
		set sourcePath to absolutePath(posixPath(sourceFile))
		set {sourceFolder, scriptName} to splitPath(sourcePath)
		set scriptLibrariesFolder to POSIX file joinPath(sourceFolder, "Resources/Script Libraries")
		set scriptLibraries to {}
		set compiledScriptLibraries to {}
		odebug("Shared Folder: " & sharedLibFolder)
		odebug("Project: " & projectFolder)
		odebug("Name: " & scriptName)
		odebug("Script Libraries folder: " & scriptLibrariesFolder)
		-- Search for script libraries and build them recursively
		odebug("Searching for script libraries...", "")
		try
			alias scriptLibrariesFolder -- does it exist?
			set folderExists to true
		on error
			odebug("Folder does not exist")
			set folderExists to false
		end try
		if folderExists then
			tell application "Finder"
				set scriptLibraries to Â
					(every file of (entire contents of folder (scriptLibrariesFolder)) Â
						whose name ends with ".applescript") as alias list
			end tell
			repeat with libSource in scriptLibraries
				odebug("Building " & (libSource as text))
				makeScriptBundle(libSource)
			end repeat
			odebug("Searching for compiled script libraries...")
			tell application "Finder"
				set compiledScriptLibraries to Â
					(every file of (entire contents of folder (scriptLibrariesFolder)) Â
						whose name ends with ".scptd" or name ends with ".scpt") as alias list
			end tell
		end if
		odebug({"compiledScriptLibraries: ", compiledScriptLibraries})
		try
			-- Alias each script library in a shared Script Libraries folder
			repeat with lib in compiledScriptLibraries
				makeAlias(lib, joinPath(sharedLibFolder, basename(lib)))
			end repeat
			-- Compile the script bundle
			osacompile(joinPath(projectFolder, scriptName & ".applescript"), "scptd", {"-x"})
			-- Remove the aliases
			repeat with lib in compiledScriptLibraries
				rm(joinPath(sharedLibFolder, basename(lib)))
			end repeat
		on error errMsg number errNum
			repeat with lib in compiledScriptLibraries
				rm(joinPath(sharedLibFolder, basename(lib)))
			end repeat
			error errMsg number errNum
		end try
		-- Move the script libraries in the bundle's Script Libraries folder
		repeat with lib in compiledScriptLibraries
			set {dir, base} to splitPath(lib)
			mv(joinPath(dir, base & ".scptd"), scriptLibrariesFolder)
		end repeat
		-- Prepare Info.plist (use PlistBuddy?)
		-- Copy other resources
		-- Move the built product one level up
	end makeScriptBundle
	
	(*!
		@abstract
			Compiles one or more scripts.
		@param
			src <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@param
			target <em>[text]</em> The type of the result, which can be <code>scpt</code>,
			<code>scptd</code>, or <code>app</code>, for a script, script bundle, or applet, respectively.
		@param
			options <em>[list]</em> A list of <code>osacompile</code> options
			(see <code>man osacompile</code>).
	*)
	on osacompile from sources given target:target : "scpt", options:options : {}
		local basename, paths
		set paths to posixPaths(sources)
		if class of options is not list then set options to {options}
		repeat with p in paths
			if p ends with ".applescript" then
				set basename to text 1 thru -13 of s -- remove suffix
			else
				set basename to p
			end if
			shell for "/usr/bin/osacompile" given options:{"-o", basename & "." & target} & options & {basename & ".applescript"}
		end repeat
	end osacompile
	
	(*!
		@abstract
			Wrapper around the Unix program <code>which</code>.
		@param
			command <em>[text]</em> The name of a command.
		@return
			<em>[text]<em> The POSIX path of the executable, if found;
			otherwise, returns <tt>missing value</tt>.		
	*)
	on which(command)
		try
			shell for "/usr/bin/which" given options:command
		on error
			missing value
		end try
	end which


	---------------------------------------------------------------------------------------
	-- Utility handlers
	---------------------------------------------------------------------------------------
	
	(*
		@abstract
			Filters the elements of a list using a boolean predicate.
		@discussion
			Returns a new list containing all and only the elements of the original list
			for which the predicate returns <tt>true</tt>. The original list remains unchanged.
			A predicate is a unary handler that returns a boolean value.
			
			For optimal performance, the list should be passed by reference, e.g.:
			<pre>
			set filteredList to filter(a reference to myList, myPredicate)
			</pre>
	*)
	on filter(aList, predicate as handler)
		script theFunctor
			property apply : predicate
		end script
		set theResult to {}
		repeat with e in aList
			if theFunctor's apply(the contents of e) then
				copy the contents of e to the end of theResult
			end if
		end repeat
		theResult
	end filter
	
	(*!
		@abstract
			Joins the elements of a list separating them with the given delimiter.
		@param
			aList <em>[list]</em> A list.
		@param
			aDelimiter <em>[text]</em> A delimiter.
		@return
			<em>[text]</em> The string formed by concatenating the elements of the list,
			separated by the given delimiter.
	*)
	on join(aList, aDelimiter)
		set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, aDelimiter}
		set theResult to aList as text
		set AppleScript's text item delimiters to tid
		return theResult
	end join
	
	(*!
		@abstract
			Applies a unary handler to every element of a list, returning a new list with the result.
			The original list remains unchanged.
		@discussion
			For optimal performance, the list should be passed by reference:
			<pre>
			set myNewList to map:(a reference to myList) byApplying:myHandler
			</pre>
		@param
			aList <em>[list]</em> (A reference to) a list.
		@param
			unaryHandler <em>[text]</em> A handler with a single positional parameter.
		@return
			<em>[list]</em> A new list obtained by applying the handler to each element
			of the original list.
	*)
	on map(aList, unaryHandler as handler)
		script theFunctor
			property apply : unaryHandler
		end script
		set theResult to {}
		repeat with e in every item of aList
			copy theFunctor's apply(the contents of e) to the end of theResult
		end repeat
		theResult
	end map
	
	(* @abstract A wrapper around <tt>quoted form of</tt>. *)
	on quoteText(s)
		quoted form of s
	end quoteText
	
	(*!
		@abstract
			Splits a string at the given delimiter.
		@param
			theText <em>[text]</em> A string.
		@param
			aDelimiter <em>[text]</em> A delimiter.
		@return
			<em>[list]</em> The list formed by splitting the string.
	*)
	on split(theText, aDelimiter)
		-- TODO: NSArray* components = [urlAsString componentsSeparatedByString:@"#"];
		set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, aDelimiter}
		set theResult to the text items of theText
		set AppleScript's text item delimiters to tid
		return theResult
	end split
	
	(*
		@abstract
			Applies a unary handler to every element of a list, replacing the element with the result.
		@discussion
			For optimal performance, the list should be passed by reference, e.g.:
			<pre>
			transform(a reference to myList, myHandler)
			</pre>
	*)
	on transform(aList, unaryHandler as handler)
		script theFunctor
			property apply : unaryHandler
		end script
		local n
		set n to count aList
		repeat with i from 1 to n
			set item i of aList to theFunctor's apply(item i of aList)
		end repeat
	end transform
end script -- TaskBase

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
	-- TODO: sort tasks alphabetically
	repeat with t in my TASKS -- find the longest name
		if the length of t's name > nameLen then set nameLen to the length of t's name
	end repeat
	repeat with t in my TASKS
		set spaces to space & space
		repeat with i from 1 to nameLen - (length of t's name)
			set spaces to spaces & space
		end repeat
		echo(my boldType & t's name & my reset & spaces & t's description)
	end repeat
end script

(*! @abstract Task to print the path of the working directory. *)
script WorkDir
	property parent : Task(me)
	property name : "wd"
	property synonyms : {"pwd"}
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
			A list of task options.
		@discussion
			This property stores the values of the command-line options after the task name.
	*)
	property taskOptions : {}
	
	(*! @abstract Returns the number of task arguments. *)
	on numberOfArguments()
		my taskOptions's length
	end numberOfArguments
	
	(*! @abstract Clears the arguments. *)
	on clear()
		set command to ""
		set options to {}
		set taskOptions to {}
	end clear
	
	(*!
		@abstract
			Retrieves the first task argument and removes it from the list of arguments.
		@return
			A pair {key, value}, or {missing value,missing value} if there are no arguments.
		*)
	on shift()
		local v
		if my numberOfArguments() is 0 then return missing value
		set {v, my taskOptions} to {the first item of my taskOptions, the rest of my taskOptions}
		v
	end shift
	
end script

(*!
	@abstract
		Retrieves the task specified by the user.
	@param
		taskName <em>[text]</em> The task name.
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
on runTask()
	set TaskBase's PWD to do shell script "pwd"
	-- Allow loading ASMake from text format with run script
	if TaskArguments's command is "__ASMAKE__LOAD__" then return me
	local t
	try
		set t to findTask(TaskArguments's command)
	on error errMsg number errNum
		ofail("Unknown task: " & TaskArguments's command, "")
		error errMsg number errNum
	end try
	set t's arguments to TaskArguments -- TODO: move inside Task()?
	try
		run t
		if t's printSuccess then ohai("Success!")
		if t's dry() then ohai("(This was a dry run)")
	on error errMsg number errNum
		ofail("Task failed", "")
		error errMsg number errNum
	end try
end runTask


(*!
	@abstract
		Parses the command-line.
	@discussion
		The general syntax for invoking a task is:
		<pre>
		asmake <options> <task name> <task options>
		</pre>
		where <tt>options</tt> can be one of the following:
		<ul>
			<li><tt>-v</tt> or <tt>--verbose</tt>: be verbose;</li>
			<li><tt>-n</tt><tt>--dry</tt>: dry run.</li>
		</ul>
		The <task options> are made available to the task
		through its <tt>arguments</tt> property.
		It is the task's responsibility to deal with them
		appropriately.
	@param
		argv <em>[list]</em> The command-line arguments.
*)
on parseCommandLineOptions(argv)
	local i, argc
	TaskArguments's clear()
	set argc to count (argv)
	set i to 1
	-- Process ASMake options
	repeat while i ² argc and item i of argv starts with "-"
		set the end of TaskArguments's options to item i of argv
		set i to i + 1
	end repeat
	-- Process command name
	if i ² argc then
		set TaskArguments's command to item i of argv
		set i to i + 1
	end if
	-- Process task's options
	repeat while i ² argc
		set the end of TaskArguments's taskOptions to item i of argv
		set i to i + 1
	end repeat
end parseCommandLineOptions

(*! @abstract The handler invoked by <tt>osascript</tt>. *)
on run argv
	parseCommandLineOptions(argv)
	runTask()
end run
