(*!
 @header ASMake
 @abstract
 	A simple build and task AppleScript script library.
 @author Lifepillar
 @copyright 2014Ð2015 Lifepillar
 @version 0.2.1
 @charset macintosh
*)
use AppleScript version "2.4"
use scripting additions

property name : "ASMake"
property id : "com.lifepillar.ASMake"
property version : "0.2.1"
property parent : AppleScript
(*! @abstract The top-level script object. *)
property ASMake : me

(*! @abstract A script object to help print colored output to the terminal. *)
script Stdout
	(*! @abstract The parent of this object. *)
	property parent : AppleScript
	(*! @abstract The basic escape sequence. *)
	property esc : Çdata utxt001BÈ as Unicode text
	(*! @abstract The escape sequence for black. *)
	property black : esc & "[0;30m"
	(*! @abstract The escape sequence for blue. *)
	property blue : esc & "[0;34m"
	(*! @abstract The escape sequence for cyan. *)
	property cyan : esc & "[0;36m"
	(*! @abstract The escape sequence for green. *)
	property green : esc & "[0;32m"
	(*! @abstract The escape sequence for magenta. *)
	property magenta : esc & "[0;35m"
	(*! @abstract The escape sequence for purple. *)
	property purple : esc & "[0;35m"
	(*! @abstract The escape sequence for red. *)
	property red : esc & "[0;31m"
	(*! @abstract The escape sequence for yellow. *)
	property yellow : esc & "[0;33m"
	(*! @abstract The escape sequence for white. *)
	property white : esc & "[0;37m"
	(*! @abstract The escape sequence for bold type. *)
	property boldType : esc & "[1m"
	(*! @abstract The reset escape sequence. *)
	property reset : esc & "[0m"
	
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
		set s to kolor & s & my reset
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
		my esc & "1;" & text -3 thru -1 of kolor
	end bb
	
	(*! @abstract Prints a notice. *)
	on ohai(msg)
		log col("==>", my green) & space & my boldType & (msg as text) & my reset
	end ohai
	
	(*! @abstract Prints a failure message and exits. *)
	on ofail(msg, info)
		log col("Fail:", my red) & space & my boldType & (msg as text) & my reset
		error info
	end ofail
	
	(*! @abstract Prints a warning. *)
	on owarn(msg)
		log col("Warn:", my red) & space & my boldType & (msg as text) & my reset
	end owarn
	
	(*!
		@abstract
			Prints a debugging message.
		@param
			info <em>[text]</em> or <em>[list]</em>: a message or a list of messages.
	*)
	on odebug(info)
		if class of info is not list then
			log col("DEBUG:", my red) & space & my boldType & (info as text) & my reset
			return
		end if
		set msg to (col("DEBUG:", my red) & space & my boldType & (item 1 of info) as text) & my reset
		repeat with i from 2 to count info
			set msg to msg & linefeed & ((item i of info) as text)
		end repeat
		log msg
	end odebug
	
end script -- Stdout

(*!
	@abstract
		A script object representing the command-line arguments.
	@discussion
		This is passed to the task.
*)
script CommandLine
	property parent : AppleScript
	property availableOptions : {"--debug", "-D", "--dry", "-n", "--verbose", "-v"}
	
	(*! @abstract The name of the task to be executed. *)
	property command : ""
	
	(*! @abstract A list of ASMake options. *)
	property options : {}
	
	(*! @abstract A task's options. *)
	property taskOptions : {}
	
	(*! @abstract Clears the arguments. *)
	on clear()
		set command to ""
		set options to {}
		set taskOptions to {}
	end clear
	
	(*!
	@abstract
		Parses the command-line.
	@discussion
		The general syntax for invoking a task is:
		<pre>
		asmake <options> <task name> <task options>
		</pre>
		where <tt>options</tt> are among the @link availableOptions@/link.
		The <task options> are passed to the task when it is executed.
		It is the task's responsibility to deal with them appropriately.
	@param
		argv <em>[list]</em> The command-line arguments.
	@return
		<em>[list]</em> A (possibly empty) list of arguments for the task.
*)
	on parse(argv)
		local i, argc
		clear()
		set argc to count (argv)
		set i to 1
		-- Process ASMake options
		repeat while i ² argc and item i of argv starts with "-"
			set the end of my options to item i of argv
			set i to i + 1
		end repeat
		verifyOptions()
		-- Process command name
		if i ² argc then
			set my command to item i of argv
			set i to i + 1
		end if
		-- Process task's options
		repeat while i ² argc
			set the end of my taskOptions to item i of argv
			set i to i + 1
		end repeat
		return my taskOptions
	end parse
	
	(*! @abstract Checks whether the user has specified undefined options. *)
	on verifyOptions()
		repeat with opt in (a reference to my options)
			if opt is not in my availableOptions then error "Unknown option: " & opt
		end repeat
	end verifyOptions
	
	(*! @abstract Returns true if debugging is on; returns false otherwise. *)
	on debug()
		my options contains "--debug" or my options contains "-D"
	end debug
	
	(*! @abstract Returns true if the user has requested a dry run, returns false otherwise. *)
	on dry()
		my options contains "--dry" or my options contains "-n"
	end dry
	
	(*! @abstract Returns true if verbose mode is on; returns false otherwise. *)
	on verbose()
		my options contains "--verbose" or my options contains "-v"
	end verbose
end script -- CommandLine


(*! @abstract The script object common to all tasks. *)
script TaskBase
	
	use framework "Foundation"
	use framework "OSAKit"
	
	property NSBundle : a reference to current application's NSBundle
	property NSFileManager : a reference to current application's NSFileManager
	property NSString : a reference to current application's NSString
	property NSURL : a reference to current application's NSURL
	property OSAScript : a reference to current application's OSAScript
	property OSALanguage : a reference to current application's OSALanguage
	property OSALanguageInstance : a reference to current application's OSALanguageInstance
	property OSAStorageScriptType : a reference to current application's OSAStorageScriptType
	property OSAStorageScriptBundleType : a reference to current application's OSAStorageScriptBundleType
	property OSAStorageApplicationType : a reference to current application's OSAStorageApplicationType
	property OSAStorageApplicationBundleType : a reference to current application's OSAStorageApplicationBundleType
	property OSAStorageTextType : a reference to current application's OSAStorageTextType
	property OSANull : a reference to current application's OSANull
	property OSAPreventGetSource : a reference to current application's OSAPreventGetSource
	property OSACompileIntoContext : a reference to current application's OSACompileIntoContext
	property OSADontSetScriptLocation : a reference to current application's OSADontSetScriptLocation
	property OSAStayOpenApplet : a reference to current application's OSAStayOpenApplet
	property OSAShowStartupScreen : a reference to current application's OSAShowStartupScreen
	
	(*! @abstract The parent of this object. *)
	property parent : AppleScript
	
	(*! @abstract The class of a task object. *)
	property class : "Task"
	
	(*!
		@abstract
			The list of registered tasks.
		@discussion
			This is a private property that should not be overridden by inheriting tasks.
			The value of this property is updated automatically at compile-time whenever
			a task script is compiled.
	*)
	property _tasks : {}
	
	(*!
		@abstract
			Task-specific arguments.
		@discussion
			This property should be overridden by inheriting script objects.
	*)
	property argv : {}
	
	(*! @abstract Flag to determine whether debug mode should be turned on *)
	property debug : false
	
	(*! @abstract Flag to determine whether the task should be run in dry mode. *)
	property dry : false
	
	
	(*! @abstract Flag to determine whether verbose mode should be turned on. *)
	property verbose : false
	
	(*! @abstract Defines a list of aliases for this task. *)
	property synonyms : {}
	
	(*! @abstract A description for this task. *)
	property description : "No description"
	
	(*!
		@abstract
			Flag to determine whether a success message should be printed
			to the standard output when a tasks completes without error.
	*)
	property printSuccess : true
	
	(*!
		@abstract
			Set this to true for private tasks.
		@discussion
			A private task is not shown by the `help` task and it cannot be invoked
			directly from the command line, but it can be called by other tasks.
	*)
	property private : false
	
	
	----------------------
	-- Private handlers --
	----------------------
	
	(*!
		@abstract
			Raises an error.
		@param
			customMessage <em>[text]</em> A message to prefix the error description.
		@param
			theError <em>[NSError]</em> an error object.
		@throws
			An error.
	*)
	on _raise(customMessage as text, theError)
		local msg
		
		if customMessage is not "" then
			set msg to customMessage & ":" & space
		else
			set msg to ""
		end if
		
		error msg & (theError's localizedDescription as text) Â
			number (theError's code as integer)
	end _raise
	
	
	-----------------------------------------
	-- Private NSURL manipulation handlers --
	-----------------------------------------
	
	(*!
		@abstract
			Returns the last path component of a NSURL object.
		@param
			aURL <em>[NSURL]</em> An NSURL object.
		@return
			<em>[NSString]</em> The last path component.
	*)
	on _basename(aURL)
		aURL's lastPathComponent
	end _basename
	
	(*!
		@abstract
			Joins two paths.
		@param
			baseURL <em>[NSURL]</em> The base URL.
		@param
			relPath <em>[NSString]</em> or <em>[text]</em> A relative path.
		@return
			<em>[NSURL]</em> The file URL obtained by appending the relative path
			to the base path.
	*)
	on _joinPath(baseURL, relPath)
		baseURL's URLByAppendingPathComponent:relPath
	end _joinPath
	
	(*!
		@abstract
			Removes the last path component from the given URL.
		@param
			aURL <em>[NSURL]</em> An NSURL object.
		@return
			<em>[NSURL]</em> A new NSURL object created by removing
			the last path component from the given URL.
	*)
	on _parentDirectory(aURL)
		aURL's URLByDeletingLastPathComponent
	end _parentDirectory
	
	(*!
		@abstract
			Determines whether the given file URL corresponds to an existing file or directory.
		@param
			aURL <em>[NSURL]</em> An NSURL object.
		@return
			<em>[boolean]</em> A flag indicating whether the given URL points
			to an existing file or directory.
	*)
	on _pathExists(aURL)
		((my NSFileManager)'s defaultManager()'s fileExistsAtPath:(aURL's |path|)) as boolean
	end _pathExists
	
	(*!
		@abstract
			Sets the path extension.
		@discussion
			If the path has no extension, the given extension is added to the path,
			otherwise the existing extension is replaced by the new one.
		@param
			aPath <em>[NSString]</em> A path.
		@param
			newExtension <em>[NSString]</em> or <em>[text]</em> The new extension for the path.
		@return
			<em>[NSString]</em> The path with the modified extension.
	*)
	on _setPathExtension(aPath, newExtension)
		aPath's stringByDeletingPathExtension's stringByAppendingPathExtension:newExtension
	end _setPathExtension
	
	(*! @abstract Returns the path of the working directory as an NSString object. *)
	on _workingDirectory()
		(my NSFileManager)'s defaultManager()'s currentDirectoryPath
	end _workingDirectory
	
	--------------------------------------------
	-- Private file URL manipulation handlers --
	--------------------------------------------
	
	(*!
		@abstract
			Copies the file or directory at the specified URL to a new location.
		@discussion
			If the item at <code>srcURL</code> is a directory, this handler
			copies the directory and all of its contents, including any hidden files.
		@param
			srcURL <em>[NSURL]</em> The file URL that identifies to be copied.
		@param
			destURL <em>[NSURL]</em> The URL at which to place the copy of <code>srcURL</code>.
		@return
			Nothing.
		@throws
			An error if the file cannot be copied.
	*)
	on _copyItem(srcURL, destURL)
		local ok, theError
		
		overb("Copying" & space & (srcURL's |path| as text) & space & Â
			"to" & (destURL's |path| as text))
		if my dry then return
		
		_makePath(_parentDirectory(destURL))
		set {ok, theError} to ((my NSFileManager)'s defaultManager()'s copyItemAtURL:srcURL Â
			toURL:destURL Â
			|error|:(reference))
		if not ok then _raise("Could not copy file", theError)
		
		return
	end _copyItem
	
	(*!
		@abstract
			Returns true if the given path is a directory; returns false otherwise.
		@param
			aURL <em>[NSURL]</em> A file URL.
		@return
			<em>[boolean]</em> A boolean value indicating whether the given path is a directory.
		@throws
			An error if the property cannot be retrieved.
	*)
	on _isDirectory(aURL)
		local ok, isDirectory, theError
		
		set {ok, isDirectory, theError} to aURL's getResourceValue:(reference) Â
			forKey:(current application's NSURLIsDirectoryKey) Â
			|error|:(reference)
		if isDirectory is missing value then _raise("Unexpected error", theError)
		
		isDirectory as boolean
	end _isDirectory
	
	(*!
		@abstract
			Creates a directory at the specified path.
		@discussion
			If the path already exists, does nothing.
		@param
			aURL <em>[NSURL]</em> A file URL that specifies the directory to create.
		@return
			Nothing.
		@throws
			An error if the path cannot be created.
	*)
	on _makePath(aURL)
		local ok, theError
		
		overb("Creating path" & space & (aURL's |path| as text))
		if my dry then return
		
		set {ok, theError} to (my NSFileManager)'s defaultManager()'s createDirectoryAtPath:(aURL's |path|) Â
			withIntermediateDirectories:true Â
			attributes:(missing value) Â
			|error|:(reference)
		if not ok then _raise("Could not create path", theError)
		
		return
	end _makePath
	
	(*!
		@abstract
			Moves the file or directory at the specified URL to a new location.
		@discussion
			If the item at <code>srcURL</code> is a directory, this handler
			moves the directory and all of its contents, including any hidden files.
		@param
			srcURL <em>[NSURL]</em> The file URL that identifies the item to be moved.
		@param
			destURL <em>[NSURL]</em> The new location for the item in <code>srcURL</code>.
			This file URL must include the name of the file or directory in its new location.
		@return
			Nothing.
		@throws
			An error if the file or directory cannot be moved.
	*)
	on _moveItem(srcURL, destURL)
		local ok, theError
		
		overb("Moving" & space & (srcURL's |path| as text) & space & Â
			"to" & (destURL's |path| as text))
		if my dry then return
		
		set {ok, theError} to ((my NSFileManager)'s defaultManager()'s moveItemAtURL:srcURL Â
			toURL:destURL Â
			|error|:(reference))
		if not ok then _raise("Could not move file", theError)
		
		return
	end _moveItem
	
	(*!
		@abstract
			Returns a string created by reading data from the file at a given path.
		@discussion
			This handler attempts to determine the encoding of the file.
		@param
			aURL <em>[NSURL]</em> A file URL.
		@return
			<em>[NSString]</em> The content of the file.
		@throws
			An error if the file cannot be read or there is an encoding error.
	*)
	on _readFile(aURL)
		local theText, theEncoding, theError
		
		overb("Reading" & space & (aURL's |path| as text))
		
		set {theText, theEncoding, theError} to Â
			(my NSString)'s stringWithContentsOfFile:(aURL's |path|) Â
			usedEncoding:(reference) |error|:(reference)
		if theText is missing value then _raise("Could not open file", theError)
		
		return theText
	end _readFile
	
	(*!
		@abstract
			Removes the file or directory at the specified URL.
		@discussion
			If the URL specifies a directory, the contents of that
			directory are recursively removed.
		@param
			aURL <em>[NSURL]</em> A file URL specifying the file or directory to remove.
		@return
			Nothing.
		@throws
			An error if the specified file or directory cannot be removed.
	*)
	on _removeItem(aURL)
		local ok, theError
		
		overb("Deleting" & space & (aURL's |path| as text))
		if my dry then return
		
		set {ok, theError} to (my NSFileManager)'s defaultManager()'s removeItemAtURL:aURL |error|:(reference)
		if not ok then _raise("Could not delete item", theError)
		
		return
	end _removeItem
	
	(*!
		@abstract
			Sets a custom icon for the given file or directory.
		@param
			docURL <em>[NSURL]</em> The location of the document.
		@param
			imgURL <em>[NSURL]</em> The location of the icon file.
		@return
			Nothing.
		@throws
			An error if the icon cannot be set.
	*)
	on _setIcon(docURL, imgURL)
		local ok
		
		overb("Setting icon for" & space & (docURL's |path| as text))
		if my dry then return
		
		set ok to current application's NSWorkspace's sharedWorkspace()'s Â
			setIcon:(current application's NSImage's alloc's initByReferencingURL:imgURL) Â
				forFile:(docURL's |path|) Â
				options:0
		if not ok then error "Could not set icon for " & (docURL's |path| as text)
		
		return
	end _setIcon
	
	(*!
		@abstract
			Creates a symbolic link that points to the specified destination.
		@param
			aURL <em>[NSURL]</em> A file URL specifying the location where
			the symbolic link should be created.
		@param
			destURL <em>[NSURL]</em> A file URL specifying the location
			of the item to be pointed to by the link.
		@return
			Nothing.
		@throws
			An error if the symbolic link cannot be created.
	*)
	on _symlink(aURL, destURL)
		local ok, theError
		
		overb("Creating symbolic link to" & space & (destURL's |path| as text) & space & Â
			"at" & space & (aURL's |path| as text))
		if my dry then return
		
		set {ok, theError} to (my NSFileManager)'s defaultManager()'s createSymbolicLinkAtURL:aURL Â
			withDestinationURL:destURL Â
			|error|:(reference)
		if not ok then _raise("Could not create symlink", theError)
		
		return
	end _symlink
	
	
	------------------------------------------
	-- Private script manipulation handlers --
	------------------------------------------
	
	(*! @abstract Returns an <code>OSALanguageInstance</code> object for the specified language. *)
	on _languageInstanceForName(languageName as text)
		(my OSALanguageInstance)'s languageInstanceWithLanguage:((my OSALanguage)'s languageForName:languageName)
	end _languageInstanceForName
	
	(*!
		@abstract
			Removes the parent of the last path component when its name
			coincides with the name of last path component (without extension).
		@discussion
			This is a helper handler for @link _buildScript() @/link.
			It is used to turn a path of the form <tt>/some/path/to/foo/foo.applescript</tt>
			into a path of the form <tt>/some/path/to/foo.applescript</tt>.
		@param
			aPath <em>[NSString]</em> A path.
		@return
			<em>[NSString]</em> The path with the parent of the last path
			component possibly removed.
	*)
	on _removeParentDirectoryFromPathWhenMatchingScriptName(aPath)
		local theName, theParent
		
		set theName to aPath's lastPathComponent
		set theParent to aPath's stringByDeletingLastPathComponent
		if (theName's stringByDeletingPathExtension) as text Â
			is equal to (theParent's lastPathComponent) as text then
			(theParent's stringByDeletingLastPathComponent)'s Â
				stringByAppendingPathComponent:theName
		else
			aPath
		end if
	end _removeParentDirectoryFromPathWhenMatchingScriptName
	
	(*!
		@abstract
			The low-level handler to compile a source script file into a script,
			a script bundle, or an applet.
		@param
			source <em>[NSString]</em> or <em>[text]</em> The script's source code.
		@param
			fromURL <em>[NSURL]</em> URL argument used to indicate the origin of scripts.
			In AppleScript, for example, this URL may be used for the value of "path to me",
			unless you use the <code>OSADontSetScriptLocation</code> storage option.
			This URL may also be used to specify the location of the script libraries this
			script depends upon.
		@param
			writeURL <em>[NSURL]</em> The location where the compiled script should be saved.
		@param
			storageType A constant specifying the type of object to create:
			one of <code>OSAStorageScriptType</code>, <code>OSAStorageScriptBundleType</code>,
			<code>OSAStorageApplicationType</code>, <code>OSAStorageApplicationBundleType</code>
			or <code>OSAStorageTextType</code>.
		@param
			languageInstance <em>[OSALanguageInstance]</em> The language instance to be used to
			compile the script.
		@param
			storageOptions One ore more of <code>OSANull</code>, <code>OSAPreventGetSource</code>,
			<code>OSACompileIntoContext</code>, <code>OSADontSetScriptLocation</code>,
			<code>OSAStayOpenApplet</code>, or <code>OSAShowStartupScreen</code>.
		@return
			Nothing.
		@throws
			An error if the script cannot be compiled or it cannot be written to disk.
	*)
	on _compile(source, fromURL, writeURL, languageInstance, storageType, storageOptions)
		local theScript, ok, theError
		
		overb("Building" & space & (writeURL's |path| as text))
		
		set theScript to (my OSAScript)'s alloc's Â
			initWithSource:source fromURL:fromURL Â
				languageInstance:languageInstance Â
				usingStorageOptions:storageOptions
		
		set {ok, theError} to theScript's compileAndReturnError:(reference)
		
		if not ok then
			error (theError as record)'s OSAScriptErrorMessageKey as text Â
				number (theError as record)'s OSAScriptErrorNumberKey
		end if
		
		if my dry then return
		
		set {ok, theError} to theScript's writeToURL:writeURL Â
			ofType:storageType Â
			|error|:(reference)
		
		if not ok then
			error (theError as record)'s OSAScriptErrorMessageKey as text Â
				number (theError as record)'s OSAScriptErrorNumberKey
		end if
		
		return
	end _compile
	
	(*!
		@abstract
			Builds a script, script bundle, or applet.
		@discussion
			This handler builds a script bundle or an applet including resources,
			auxiliary scripts and script libraries from source code in a directory
			with a specific layout. (This handler may be used to compile a script
			into a <tt>.scpt</tt> file as a special case, but @link _compile() @/link
			is recommended instead.)

			The <code>sourceURL</code> must point to the main script source file. An optional
			<tt>Info.plist</tt> file and an optional <tt>Resources</tt> folder may be
			placed in the same directory as the the main script. The <tt>Resources</tt>
			folder may contain any required resources, including additional scripts
			(in a <tt>Scripts</tt> subfolder) and embedded script libraries (in a
			<tt>Script Libraries</tt> subfolder). Any scripts and script libraries in
			source form are assumed to be laid out in the same way and are compiled
			recursively. (Compiled scripts and script libraries are simply copied to
			the target bundle.)

			For example, a source directory for an applet may have the following content:
			<pre>
      MyApp
        Info.plist
        MyApp.applescript
        Resources
          applet.icns
          Readme.txt
          Scripts
            helper.applescript
          Script Libraries
            LibOne
              LibOne.applescript
              Resources
                ...
            org.me
              Info.plist
              LibTwo.applescript
              Resources
                ...
			</pre>
			After building the applet, you will get an <tt>.app</tt> folder with the
			following content:
			<pre>
      MyApp.app
        Contents
          Info.plist
          Resources
            applet.icns
            Readme.txt
            Scripts
              main.scpt
              helper.scpt
            Script Libraries
              LibOne.scptd
              org.me
                LibTwo.scptd
			</pre>
			Note that if the name of a script (without extension) is equal to the name of the folder that contains
			that script, such folder is not copied to the target bundle (e.g., <tt>LibOne.scptd</tt> is created
			immediately under <tt>Script Libraries</tt>, while <tt>LibTwo.scptd</tt> is created inside <tt>org.me</tt>).			
		@param
			source <em>[NSString]</em> or <em>[text]</em> The script's source code.
		@param
			fromURL <em>[NSURL]</em> URL argument used to indicate the origin of scripts.
			This URL may be used to specify the location of the script libraries this
			script depends upon.
		@param
			bundleURL <em>[NSURL]</em> The location where the compiled script should be saved.
			It is assumed that this URL has the correct path extension (<tt>.scptd</tt> for
			script bundles and <tt>.app</tt> for applets).
		@param
			storageType A constant specifying the type of object to create:
			one of <code>OSAStorageScriptType</code>, <code>OSAStorageScriptBundleType</code>,
			<code>OSAStorageApplicationType</code>, <code>OSAStorageApplicationBundleType</code>
			or <code>OSAStorageTextType</code>.
		@param
			languageInstance <em>[OSALanguageInstance]</em> The language instance to be used to
			compile the script.
		@param
			storageOptions One ore more of <code>OSANull</code>, <code>OSAPreventGetSource</code>,
			<code>OSACompileIntoContext</code>, <code>OSADontSetScriptLocation</code>,
			<code>OSAStayOpenApplet</code>, or <code>OSAShowStartupScreen</code>.
		@return
			Nothing.
		@throws
			An error if the script cannot be compiled or if it cannot be written to disk.
	*)
	on _buildScript(sourceURL, fromURL, bundleURL, languageInstance, storageType, storageOptions)
		local sourceDirURL, defaultManager, languageInstance
		local srcURL, destURL, filter, scriptList, mainURL
		local fsrc, fdst
		
		set sourceDirURL to _parentDirectory(sourceURL)
		set buildDirURL to _parentDirectory(bundleURL)
		set defaultManager to (my NSFileManager)'s defaultManager()
		
		_makePath(buildDirURL)
		
		if storageType is (my OSAStorageScriptType) then -- .scpt
			_compile(_readFile(sourceURL), fromURL, bundleURL, languageInstance, storageType, storageOptions)
			return
		end if
		
		-- Create an empty bundle
		_compile("", fromURL, bundleURL, languageInstance, storageType, storageOptions)
		
		set filter to current application's NSPredicate's Â
			predicateWithFormat:"(pathExtension='applescript') OR (pathExtension='scpt') OR (pathExtension='scptd')"
		
		-- Build/copy script libraries
		set srcURL to _joinPath(sourceDirURL, "Resources/Script Libraries")
		if _pathExists(srcURL) and _isDirectory(srcURL) then
			set destURL to _joinPath(bundleURL, "Contents/Resources/Script Libraries")
			set dirEnumerator to defaultManager's enumeratorAtPath:(srcURL's |path|)
			set scriptList to (dirEnumerator's allObjects()'s filteredArrayUsingPredicate:filter)
			repeat with f in scriptList
				if f's pathExtension as text is "applescript" then
					_buildScript(_joinPath(srcURL, f), Â
						missing value, Â
						_joinPath(destURL, _setPathExtension(_removeParentDirectoryFromPathWhenMatchingScriptName(f), "scptd")), Â
						languageInstance, my OSAStorageScriptBundleType, storageOptions)
				else
					set fdst to _joinPath(destURL, f)
					if _pathExists(fdst) then _removeItem(fdst)
					_copyItem(_joinPath(srcURL, f), fdst)
				end if
			end repeat
		end if
		
		-- Build/copy auxiliary scripts
		set srcURL to _joinPath(sourceDirURL, "Resources/Scripts")
		if _pathExists(srcURL) and _isDirectory(srcURL) then
			set destURL to _joinPath(bundleURL, "Contents/Resources/Scripts")
			set dirEnumerator to defaultManager's enumeratorAtPath:(srcURL's |path|)
			set scriptList to (dirEnumerator's allObjects()'s filteredArrayUsingPredicate:filter)
			repeat with f in scriptList
				if f's pathExtension as text is "applescript" then
					_buildScript(_joinPath(srcURL, f), Â
						bundleURL, Â
						_joinPath(destURL, _setPathExtension(_removeParentDirectoryFromPathWhenMatchingScriptName(f), "scpt")), Â
						languageInstance, my OSAStorageScriptType, storageOptions)
				else
					set fdst to _joinPath(destURL, f)
					if _pathExists(fdst) then _removeItem(fdst)
					_copyItem(_joinPath(srcURL, f), fdst)
				end if
			end repeat
		end if
		
		-- Build main script
		set mainURL to _joinPath(bundleURL, "Contents/Resources/Scripts/main.scpt")
		_compile(_readFile(sourceURL), bundleURL, mainURL, languageInstance, my OSAStorageScriptType, storageOptions)
		
		-- Copy other resources
		set srcURL to _joinPath(sourceDirURL, "Resources")
		if _pathExists(srcURL) and _isDirectory(srcURL) then
			set destURL to _joinPath(bundleURL, "Contents/Resources")
			set dirEnumerator to defaultManager's enumeratorAtPath:(srcURL's |path|)
			repeat
				set f to dirEnumerator's nextObject()
				if f is missing value then exit repeat
				set fsrc to _joinPath(srcURL, f)
				if f's lastPathComponent is not in {"Scripts", "Script Libraries"} then
					set fdst to _joinPath(destURL, f)
					if _pathExists(fdst) then _removeItem(fdst) -- Overwrite existing item (e.g., applet.icns)
					_copyItem(fsrc, fdst) -- deep copy
				end if
				if _isDirectory(fsrc) then dirEnumerator's skipDescendants()
			end repeat
		end if
		
		-- Copy Info.plist file
		set srcURL to _joinPath(sourceDirURL, "Info.plist")
		if _pathExists(srcURL) then
			set destURL to _joinPath(bundleURL, "Contents/Info.plist")
			if _pathExists(destURL) then _removeItem(destURL)
			_copyItem(srcURL, destURL)
		end if
		
		return
	end _buildScript
	
	
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
			Apart from the <code>for</code> parameter, all other arguments are optional (and may appear in any order).
		@param
			command <em>[text]</em> The command to be executed.
		@param
			options <em>[text]</em> or <em>[list]</em> An argument or a list of arguments
			for the command (internally, the handler always converts this
			to a list). Each option is quoted before the command is executed.
		@param
			privileges <em>[boolean]</em> A flag indicating whether the command should be executed as a different user.
			The default is <code>false</code>.
		@param
			username <em>[text]</em> The username that should execute the command.
			This argument is ignored unless <code>privileges</code> is set to <code>true</code>.
		@param
			pass <em>[text]</em> The password to be authenticated as <code>username</code>.
		@param
			out <em>[text]</em> Redirect the standard output to the specified file.
		@param
			err <em>[text]</em> Redirect the standard error to the specified file.
			Pass <code>&1</code> to redirect to the standard output.
		@param
			ale <em>[boolean]</em> Whether line endings should be changed or not.
			The default is <code>true</code>.
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
		set command to command & space & (join(map(options, my quoteText), space)) & out & err
		overb(command)
		if my dry then return command
		set command to "cd" & space & quoted form of workingDirectory() & ";" & command
		if pass is missing value then
			set output to (do shell script command administrator privileges privileges altering line endings ale)
		else
			if username is missing value then set username to short user name of (system info)
			set output to (do shell script command administrator privileges privileges user name username password pass altering line endings ale)
		end if
		overb(output)
		return output
	end shell
	
	--------------------------------
	-- Path manipulation handlers --
	--------------------------------
	
	(*!
		@abstract
			Converts a path to an absolute POSIX path.
		@discussion
			Relative paths are resolved with respect to the working directory.
			If the path has a trailing slash then it is stripped.
		@param
			aPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A relative or absolute path.
		@return
			<em>[text]</em> A full POSIX path.
	*)
	on absolutePath(aPath)
		toNSURL(aPath)'s URLByStandardizingPath's |path| as text
	end absolutePath
	
	(*!
		@abstract
			Returns the last component of the given path.
		@param
			aPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A path.
		@return
			<em>[text]</em> The last component of the path.
	*)
	on basename(aPath)
		_basename(toNSURL(aPath)) as text
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
			aPath <em>[text]</em> A POSIX path.
		@return
			<em>[text]</em> A copy of <code>aPath</code> without any trailing slash.
	*)
	on deslash(aPath)
		local i, p, pLen
		
		copy aPath to p
		set pLen to count p
		set i to 0
		repeat while pLen - i > 1 and the last character of text 1 thru (pLen - i) of p is "/"
			set i to i + 1
		end repeat
		text 1 thru (pLen - i) of p
	end deslash
	
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
		local res
		
		if the class of pattern is not list then set pattern to {pattern}
		set res to {}
		repeat with p in pattern
			set res to res & the paragraphs of Â
				(do shell script "cd" & space & quoted form of workingDirectory() & Â
					";list=(" & p & ");for f in \"${list[@]}\";do echo \"$f\";done")
		end repeat
		
		return res
	end glob
	
	(*!
	@abstract
		Returns a new POSIX path formed by joining a base path and a relative path.
		If the relative path has a trailing slash, it is stripped.
		The resulting path is relative if base path is relative.
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
		(_joinPath(toNSURL(basePath), posixPath(relPath)))'s relativePath as text
	end joinPath
	
	(*!
		@abstract
			Returns the path of the directory containing the given path.
			If the path has a trailing slash, it is stripped.
		@param
			aPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A path.
		@return
			<em>[text]</em> A POSIX path.
	*)
	on parentDirectory(aPath)
		_parentDirectory(toNSURL(aPath))'s relativePath as text
	end parentDirectory
	
	
	(*!
		@abstract
			Splits the absolute version of the given path into its components.
		@param
			aPath <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			A path.
		@return
			<em>[list]</em> The components of the given paths.
		@seealso
			basename
		@seealso
			directoryPath
	*)
	on pathComponents(aPath)
		toNSURL(aPath)'s pathComponents as list
	end pathComponents
	
	(*!
		@abstract
			Checks whether the given file or directory exists on disk.
			Relative paths are resolved with respect to the working directory.
		@param
			aPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A relative or absolute path.
		@return
			<em>[boolean]</em> <code>true</code> is the path exists, <code>false</code> otherwise.
	*)
	on pathExists(aPath)
		_pathExists(toNSURL(aPath)) as boolean
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
			aPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A path.
		@return
			<em>[text]</em> A POSIX path.
	*)
	on posixPath(aPath)
		considering punctuation
			if aPath's class is text and aPath does not contain ":" then return the contents of aPath
		end considering
		return POSIX path of aPath
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
			Sets the path extension.
		@discussion
			If the path has no extension, the given extension is added to the path,
			otherwise the existing extension is replaced by the new one.
		@param
			aPath <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			A path.
		@param
			newExtension <em>[text]</em> The new extension for the path.
		@return
			<em>[text]</em> A POSIX path with the modified extension.
	*)
	on setPathExtension(aPath, newExtension)
		_setPathExtension((my NSString)'s stringWithString:posixPath(aPath), newExtension) as text
	end setPathExtension
	
	(*!
		@abstract
			Changes the path of the current working directory to the specified path.
		@param
			aPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A path.
		@throws
			An error if the working directory cannot be changed.
		@seealso
			workingDirectory
	*)
	on setWorkingDirectory(aPath)
		set ok to (my NSFileManager)'s defaultManager()'s changeCurrentDirectoryPath:posixPath(aPath)
		if not ok then error "Could not change the path of the working directory."
	end setWorkingDirectory
	
	(*!
		@abstract
			Splits the given path into a directory and a file component.
			If the given path is relative then the directory component is relative, too.
		@param
			aPath <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			A path.
		@return
			<em>[list]</em> A two-element list.
		@seealso
			basename
		@seealso
			directoryPath
	*)
	on splitPath(aPath)
		local base
		
		set base to toNSURL(aPath)
		{base's URLByDeletingLastPathComponent's relativePath as text, base's lastPathComponent as text}
	end splitPath
	
	(*!
		@abstract
			Builds an NSURL object from the given AppleScript path.
		@discussion
			Relative paths are resolved with respect to the working directory.
		@param
			aPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A path.
		@return
			<em>[NSURL]</em> An NSURL object.
		@seealso
			workingDirectory
	*)
	on toNSURL(aPath)
		(my NSURL)'s fileURLWithPath:(((my NSString)'s stringWithString:posixPath(aPath))'s stringByExpandingTildeInPath)
	end toNSURL
	
	(*!
		@abstract
			Returns the POSIX path of the current directory (without a trailing slash).
		@return
			<em>[text]</em> The POSIX path of the working directory.
		@seealso
			setWorkingDirectory
	*)
	on workingDirectory()
		_workingDirectory() as text
	end workingDirectory
	
	
	--------------------------------
	-- File manipulation handlers --
	--------------------------------
	
	(*!
		@abstract
			Copies one or more files or directories to the specified destination.
		@param
			sourcePath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@param
			targetDirPath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>
			The path of the directory where the items should be copied.
		@param
			overwrite <em>[boolean]</em> A flag indicating whether existing files and
			directories in the destination should be overwritten.
		@return
			Nothing.
		@throws
			An error if an item cannot be copied.
		@seealso
			cp
	*)
	on copyItem at sourcePath into targetDirPath given overwriting:overwrite : false
		cp(sourcePath, targetDirPath, overwrite)
	end copyItem
	
	(*!
		@abstract
			Copies one or more files or directories to the specified destination.
		@param
			sourcePath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@param
			targetDirPath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>
			The path of the directory where the items should be copied.
		@param
			overwrite <em>[boolean]</em> A flag indicating whether existing files and
			directories in the destination should be overwritten.
		@return
			Nothing.
		@throws
			An error if an item cannot be copied.
		@seealso
			cp
	*)
	on copyItems at sourcePaths into targetDirPath given overwriting:overwrite : false
		cp(sourcePaths, targetDirPath, overwrite)
	end copyItems
	
	(*!
		@abstract
			Copies one or more files or directories to the specified destination.
		@param
			sourcePath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@param
			targetDirPath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>
			The path of the directory where the items should be copied.
		@param
			overwrite <em>[boolean]</em> A flag indicating whether existing files and
			directories in the destination should be overwritten.
		@return
			Nothing.
		@throws
			An error if an item cannot be copied.
	*)
	on cp(sourcePath, targetDirPath, overwrite)
		local targetDirURL, destURL, srcURL
		
		script Wrapper
			property pathList : {}
		end script
		
		if the class of sourcePath is list then
			set Wrapper's pathList to sourcePath
		else
			set Wrapper's pathList to {sourcePath}
		end if
		
		set targetDirURL to toNSURL(targetDirPath)
		if _pathExists(targetDirURL) then
			if not _isDirectory(targetDirURL) then
				error (targetDirURL's |path| as text) & space & "is not a directory."
			end if
		else
			_makePath(targetDirURL)
		end if
		
		repeat with f in every item of (a reference to Wrapper's pathList)
			set srcURL to toNSURL(contents of f)
			set destURL to _joinPath(targetDirURL, _basename(srcURL))
			if overwrite and _pathExists(destURL) then
				_removeItem(destURL)
			end if
			_copyItem(srcURL, destURL)
		end repeat
		
		return
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
		if my verbose then set the end of flags to "-V"
		shell for "/usr/bin/ditto" given options:flags & posixPaths(src) & posixPaths(dst)
	end ditto
	
	(*!
		@abstract
			Perform a deep search of a given directory to find all the items
			satisfying a given condition.
		@param
			aDir <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			The path of the directory to search.
		@param
			predicate <em>[text]</em> A predicate, specified using the syntax of NSPredicate.
		@return
			<em>[list]</em> The list of the paths satisfying the predicate.
			The paths are relative to <code>aDir</code>.
	*)
	on findItems(aDir, predicate)
		local dirEnumerator, filter
		
		set dirEnumerator to (my NSFileManager)'s defaultManager()'s enumeratorAtPath:(toNSURL(aDir)'s |path|)
		set filter to current application's NSPredicate's predicateWithFormat:predicate
		return (dirEnumerator's allObjects()'s filteredArrayUsingPredicate:filter) as list
	end findItems
	
	(*!
		@abstract
			Returns true if the given path is a directory; returns false otherwise.
		@param
			aPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			A path.
		@return
			<em>[boolean]</em> A boolean value indicating whether the given path is a directory.
		@throws
			An error if the property cannot be retrieved, for example because the path does not exist.
	*)
	on isDirectory(aPath)
		_isDirectory(toNSURL(aPath))
	end isDirectory
	
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
		
		set src to absolutePath(source)
		set tgt to absolutePath(target)
		set {dir, base} to splitPath(tgt)
		overb("Creating alias at" & space & (dir as text) & space & Â
			"to" & space & (src as text) & space & Â
			"with name" & space & (base as text))
		if not my dry then
			tell application "Finder"
				make new alias file at POSIX file dir to POSIX file src with properties {name:base}
			end tell
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
	on makePath(dst as list)
		repeat with p in dst
			_makePath(toNSURL(p))
		end repeat
	end makePath
	
	(*!
		@abstract
			Moves one or more files or directories to the specified destination.
		@param
			sourcePath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@param
			targetDirPath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>
			The path of the directory where the items should be moved.
		@param
			overwriting <em>[boolean]</em> A flag indicating whether the destination path
			should be overwritten.
		@return
			Nothing.
		@throws
			An error if an item cannot be moved.
		@seealso
			mv
	*)
	on moveItem at sourcePath into targetDirPath given overwriting:overwrite : false
		mv(sourcePath, targetDirPath, overwrite)
	end moveItem
	
	(*!
		@abstract
			Moves one or more files or directories to the specified destination.
		@param
			sourcePath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@param
			targetDirPath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>
			The path of the directory where the items should be moved.
		@param
			overwriting <em>[boolean]</em> A flag indicating whether the destination path
			should be overwritten.
		@return
			Nothing.
		@throws
			An error if an item cannot be moved.
		@seealso
			mv
	*)
	on moveItems at sourcePaths into targetDirPath given overwriting:overwrite : false
		mv(sourcePaths, targetDirPath, overwrite)
	end moveItems
	
	(*!
		@abstract
			Moves one or more files or directories to the specified destination.
		@discussion
			Do not use this handler to rename a file or directory!
		@param
			sourcePath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a ist of paths.
		@param
			targetDirPath <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>
			The path of the directory where the items should be moved.
		@param
			overwrite <em>[boolean]</em> A flag indicating whether the destination path
			should be overwritten.
		@return
			Nothing.
		@throws
			An error if an item cannot be moved.
	*)
	on mv(sourcePath, targetDirPath, overwrite)
		local targetDirURL, destURL, srcURL
		
		script Wrapper
			property pathList : {}
		end script
		
		if the class of sourcePath is list then
			set Wrapper's pathList to sourcePath
		else
			set Wrapper's pathList to {sourcePath}
		end if
		
		set targetDirURL to toNSURL(targetDirPath)
		if _pathExists(targetDirURL) then
			if not _isDirectory(targetDirURL) then
				error (targetDirURL's |path| as text) & space & "is not a directory."
			end if
		else
			_makePath(targetDirURL)
		end if
		
		repeat with f in every item of (a reference to Wrapper's pathList)
			set srcURL to toNSURL(contents of f)
			set destURL to _joinPath(targetDirURL, _basename(srcURL))
			if overwrite and _pathExists(destURL) then
				_removeItem(destURL)
			end if
			_moveItem(srcURL, destURL)
		end repeat
		
		return
	end mv
	
	(*! @abstract TODO *)
	on readFile(aPath)
		_readFile(toNSURL(aPath)) as text
	end readFile
	
	(*!
		@abstract
			Reads the content of the given file as UTF8-encoded text.
		@param
			filename <em>[text]</em> or <em>[file]</em> or <em>[alias]</em>: the file to read.
		@return
			<em>[text]</em> The content of the file.
	*)
	on readUTF8(fileName)
		set ff to posixPath(fileName)
		overb("Reading" & space & ff)
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
			Deletes one or more files or directories (with their content).
		@see
			rm
	*)
	on removeItem at somePath given forcing:force : false
		rm(somePath, force)
	end removeItem
	
	(*!
		@abstract
			Deletes one or more files or directories (with their content).
		@see
			rm
	*)
	on removeItems at somePaths given forcing:force : false
		rm(somePaths, force)
	end removeItems
	
	(*!
		@abstract
			Deletes one or more files or directories (with their content).
		@param
			somePaths <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths.
		@param
			force <em>[boolean]</em> A flag indicating whether an error should be raised
			when an item cannot be deleted. When set to <code>true</code>,
			no errors are reported.
		@return
			Nothing.
		@throws
			Only if <code>force</code> is <code>false</code>. In such a case,
			an error is thrown when an item cannot be deleted, for example because it does not exist.
	*)
	on rm(somePaths, force as boolean)
		local theURL, forbiddenPaths, errMessage
		
		script Wrapper
			property pathList : {}
		end script
		
		if the class of somePaths is list then
			set Wrapper's pathList to somePaths
		else
			set Wrapper's pathList to {somePaths}
		end if
		
		-- Some safety net...
		set forbiddenPaths to {"/", workingDirectory(), toNSURL("~")'s |path| as text}
		repeat with f in every item of (a reference to Wrapper's pathList)
			set theURL to toNSURL(contents of f)
			if (theURL's |path| as text) is in forbiddenPaths then
				error "ASMake is not allowed to delete" & space & (theURL's |path| as text)
			end if
			try
				_removeItem(theURL)
			on error errMsg
				if not force then error errMsg
			end try
		end repeat
	end rm
	
	(*!
		@abstract
			Sets a custom icon for the given file or directory.
		@param
			docPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			The location of the document.
		@param
			imgPath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			The location of the icon file.
		@return
			Nothing.
		@throws
			An error if the icon cannot be set.
	*)
	on setIcon(docPath, imgPath)
		_setIcon(toNSURL(docPath), toNSURL(imgPath))
	end setIcon
	
	(*!
		@abstract
			Creates a symbolic link.
		@param
			aPath <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			The symbolic link to be created.
		@param
			destPath <em>[text]</em>, <em>[file]</em> or <em>[alias]</em>
			The path to the item to be pointed to by the link.
	*)
	on symlink(aPath, destPath)
		_symlink(toNSURL(aPath), toNSURL(destPath))
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
		set ff to posixPath(fileName)
		
		overb("Writing" & space & ff)
		if my dry then return
		
		set fp to open for access POSIX file ff with write permission
		try
			write content to fp as Çclass utf8È
			close access fp
		on error errMsg number errNum
			close access fp
			error errMsg number errNum
		end try
	end writeUTF8
	
	
	----------------------------------
	-- Script manipulation handlers --
	----------------------------------
	
	(*!
		@abstract
			Builds a script bundle from source, including resources and
			embedded script libraries.
		@param
			sourcePath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			path to the source file (a file with <code>.applescript</code> suffix).
		@param
			buildLocation <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			The path of the directory in which the script bundle should be built.
			This argument is optional: when omitted, the script bundle is saved
			in a <tt>build</tt> directory in the same folder as the source script.
		@param
			overwrite <em>[boolean]</em> An optional flag indicating whether an existing build
			location should be overwritten (default: <code>false</code>).
		@return
			Nothing
		@throws
			An error if the build process fails.
		@seealso
			_buildScript()
	*)
	on makeScriptBundle from sourcePath at buildLocation : missing value given overwriting:overwrite : false
		local sourceURL, sourceDirectoryURL, scriptBundleName, buildURL, bundleURL, languageInstance
		
		set sourceURL to toNSURL(sourcePath)
		set sourceDirectoryURL to _parentDirectory(sourceURL)
		set scriptBundleName to _setPathExtension(_basename(sourceURL), "scptd")
		if buildLocation is missing value then
			set buildURL to _joinPath(sourceDirectoryURL, "build")
		else
			set buildURL to toNSURL(buildLocation)
		end if
		
		set bundleURL to _joinPath(buildURL, scriptBundleName)
		if overwrite then
			if _pathExists(bundleURL) then _removeItem(bundleURL)
		else
			if _pathExists(bundleURL) then error (bundleURL's |path| as text) & space & "already exists."
		end if
		
		set languageInstance to _languageInstanceForName("AppleScript")
		_buildScript(sourceURL, missing value, _joinPath(buildURL, scriptBundleName), Â
			languageInstance, my OSAStorageScriptBundleType, my OSANull)
	end makeScriptBundle
	
	
	(*!
		@abstract
			Builds an application from a source script, including resources and
			embedded script libraries.
		@param
			sourcePath <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			path to the source file (a file with <code>.applescript</code> suffix).
		@param
			buildLocation <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			The path of the directory in which the script bundle should be built.
			This argument is optional: when omitted, the script bundle is saved
			in a <tt>build</tt> directory in the same folder as the source script.
		@param
			overwrite <em>[boolean]</em> An optional flag indicating whether an existing build
			location should be overwritten (default: <code>false</code>).
		@return
			Nothing
		@throws
			An error if the build process fails.
		@seealso
			_buildScript()
	*)
	on makeApplication from sourcePath at buildLocation : missing value given overwriting:overwrite : false
		local sourceURL, sourceDirectoryURL, scriptBundleName, buildURL, bundleURL, languageInstance
		
		set sourceURL to toNSURL(sourcePath)
		set sourceDirectoryURL to _parentDirectory(sourceURL)
		set scriptBundleName to _setPathExtension(_basename(sourceURL), "app")
		if buildLocation is missing value then
			set buildURL to _joinPath(sourceDirectoryURL, "build")
		else
			set buildURL to toNSURL(buildLocation)
		end if
		
		set bundleURL to _joinPath(buildURL, scriptBundleName)
		if overwrite then
			if _pathExists(bundleURL) then _removeItem(bundleURL)
		else
			if _pathExists(bundleURL) then error (bundleURL's |path| as text) & space & "already exists."
		end if
		
		set languageInstance to _languageInstanceForName("AppleScript")
		_buildScript(sourceURL, missing value, _joinPath(buildURL, scriptBundleName), Â
			languageInstance, my OSAStorageApplicationType, my OSANull)
	end makeApplication
	
	(*!
		@abstract
			Creates an empty script bundle.
		@param
			buildLocation <em>[text]</em>, <em>[file]</em>, or <em>[alias]</em>
			The path where the script bundle should be created.
			The path must include the name of the script bundle.
	*)
	on emptyScriptBundle(buildLocation)
		_compile("", missing value, toNSURL(buildLocation), Â
			_languageInstanceForName("AppleScript"), my OSAStorageScriptBundleType, my OSANull)
	end emptyScriptBundle
	
	(*!
		@abstract
			Compiles one or more scripts.
		@param
			sources <em>[text]</em>, <em>[file]</em>, <em>[alias]</em>, or <em>[list]</em>
			A path or a list of paths to the scripts to be compiled.
		@param
			target <em>[text]</em> The type of the result, which can be <code>scpt</code>,
			<code>scptd</code>, or <code>app</code>, for a script, script bundle, or applet, respectively.
		@param
			options <em>[list]</em> A list of <code>osacompile</code> options
			(see <code>man osacompile</code>).
	*)
	on osacompile(sources, target, options)
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
			otherwise, returns <code>missing value</code>.		
	*)
	on which(command)
		try
			shell for "/usr/bin/which" given options:command
		on error
			missing value
		end try
	end which
	
	
	----------------------
	-- Utility handlers --
	---------------------- 
	
	(*!
		@abstract
			Filters the elements of a list using a boolean predicate.
		@discussion
			Returns a new list containing all and only the elements of the original list
			for which the predicate returns <code>true</code>. The original list remains unchanged.
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
		script Functor
			property apply : unaryHandler
		end script
		set theResult to {}
		repeat with e in every item of aList
			copy Functor's apply(the contents of e) to the end of theResult
		end repeat
		theResult
	end map
	
	(*! @abstract A wrapper around <code>quoted form of</code>. *)
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
	
	(*!
		@abstract
			Applies a unary handler to every element of a list, replacing the element with the result.
		@discussion
			For optimal performance, the list should be passed by reference, e.g.:
			<pre>
			transform(a reference to myList, myHandler)
			</pre>
	*)
	on transform(aList, unaryHandler as handler)
		script Functor
			property apply : unaryHandler
		end script
		local n
		set n to count aList
		repeat with i from 1 to n
			set item i of aList to Functor's apply(item i of aList)
		end repeat
	end transform
	
	
	----------------------
	-- Sorting handlers --
	----------------------
	
	(*!
		@abstract
			Sorts a list in-place.
		@discussion
			This handler sorts a list in-place. Call it as follows:
			<pre><code>
      set myList to {4,2,6,3}
      insertionSort(a reference to myList)
      myList -- {2,3,4,6}
			</code></pre>
		@param
			x <em>[reference]</em> A reference to a list.
		@param
			compareHandler <em>[handler]</em> A comparator, that is,
			a handler with two parameters <code>x</code> and <code>y</code>,
			which returns <code>-1</code> if <code>x</code> is less than <code>y</code>,
			returns <code>1</code> if <code>x</code> is greater than <code>y</code>,
			and returns <code>0</code> if <code>x</code> and <code>y</code> are equal.
			To use the default semantics for comparison, pass <code>missing value</code>.
		@return
			Nothing.
	*)
	on insertionSort(x, compareHandler)
		local i, j, key
		
		script comparator
			property compare : compareHandler
			
			on defaultComparison(x, y)
				if x < y then return -1
				if x > y then return 1
				0
			end defaultComparison
		end script
		
		if comparator's compare is missing value then
			set comparator's compare to comparator's defaultComparison
		end if
		
		repeat with j from 2 to (count x)
			set key to item j of x
			set i to j - 1
			repeat while i > 0 and comparator's compare(item i of x, key) = 1
				set item (i + 1) of x to item i of x
				set i to i - 1
			end repeat
			set item (i + 1) of x to key
		end repeat
	end insertionSort
	
	
	---------------------------
	-- Task-related handlers --
	---------------------------
	
	(*! @abstract Registers a task. *)
	on addTask(t)
		set the end of my _tasks to t
	end addTask
	
	(*! @abstract Returns the list of non-private tasks. *)
	on tasks()
		local tl
		
		set tl to {}
		repeat with t in every item of (a reference to my _tasks)
			if not t's private then
				set the end of tl to t
			end if
		end repeat
		
		return tl
	end tasks
	
	(*!
		@abstract
			Returns the first non-processed option from the list of options.
		@discussion
			The returned option is removed from the list of options.
	*)
	on shift()
		if my argv is {} then
			return missing value
		end if
		
		local v
		set {v, my argv} to {the first item of my argv, the rest of my argv}
		return v
	end shift
	
	(*!
		@abstract
			Executes this task.
		@param
			args <em>[list]</em> The arguments to pass to this task.
		@return
			Nothing.
		@throws
			An error if the task cannot be run or the task fails.
	*)
	on exec:(args as list)
		odebug("Executing" & space & (my name) & space & "task with arguments:" & Â
			space & join(args, space))
		set my argv to args
		run me
	end exec:
	
	on _iamhereonlyforheaderdocnottoscrewup()
	end _iamhereonlyforheaderdocnottoscrewup
	
	-----------------------------
	-- Output-related handlers --
	-----------------------------
	
	(*! @abstract TODO. *)
	on ofail(s)
		log "Fail:" & space & s
	end ofail
	
	(*! @abstract TODO. *)
	on ohai(s)
		log "==>" & space & s
	end ohai
	
	(*! @abstract TODO. *)
	on odebug(s)
		if my debug then log "DEBUG:" & space & s
	end odebug
	
	(*! @abstract Logs a message only in verbose mode. *)
	on overb(s as text)
		if my verbose and s is not "" then log s
	end overb
	
	(*! @abstract TODO. *)
	on owarn(s)
		log "Warn:" & space & s
	end owarn
end script -- TaskBase

(*!
	@abstract
		Registers a task.
	@param
		t <em>[script]</em> A task script.
	@discussion
		This handler is used to register a task at compile-time
		and to set the parent of a script to @link TaskBase @/link.
		Every task script should inherit from <code>Task(me)</code>.
*)
on Task(t)
	TaskBase's addTask(t)
	
	script
		property parent : TaskBase
		property argv : {} -- Overrides parent property
		
		on ofail(s)
			Stdout's ofail(s)
		end ofail
		
		on ohai(s)
			Stdout's ohai(s)
		end ohai
		
		on odebug(info)
			if my debug then Stdout's odebug(info)
		end odebug
		
		on owarn(s)
			Stdout's owarn(s)
		end owarn
	end script
	
	return the result
end Task

-- Predefined tasks

(*! @abstract Task to print the list of the available tasks. *)
script HelpTask
	property parent : Task(me)
	property name : "help"
	property synonyms : {"h", "?"}
	property description : "Show the list of available tasks and exit"
	property printSuccess : false
	property maxWidth : 0
	property boldType : Stdout's boldType
	property reset : Stdout's reset
	
	script TaskList
		property content : {}
	end script
	
	on padding(taskName)
		local spaces
		
		set spaces to space & space
		repeat with i from 1 to (my maxWidth) - (length of taskName)
			set spaces to spaces & space
		end repeat
		
		return spaces
	end padding
	
	on compareTaskNames(t1, t2)
		if t1's name < t2's name then return -1
		if t1's name > t2's name then return 1
		0
	end compareTaskNames
	
	set TaskList's content to tasks()
	-- Sort tasks alphabetically
	insertionSort(a reference to TaskList's content, compareTaskNames)
	local t, tc, desc
	-- Find the longest name (for correct alignment)
	repeat with t in every item of (a reference to TaskList's content)
		set tc to contents of t
		if the length of tc's name > maxWidth then set maxWidth to the length of tc's name
	end repeat
	
	-- Print help message
	repeat with t in every item of (a reference to TaskList's content)
		set tc to contents of t
		set desc to my boldType & tc's name & my reset & padding(tc's name)
		if {tc's name} & tc's synonyms contains ASMake's defaultTask then
			set desc to desc & "(Default)" & space
		end if
		set desc to desc & tc's description
		if tc's synonyms is not {} then
			set desc to desc & space & "(Synonyms:" & space & my boldType & join(tc's synonyms, "," & space) & my reset & ")"
		end if
		log desc & "."
	end repeat
end script

(*! @abstract Task to print the path of the working directory. *)
script WorkDir
	property parent : Task(me)
	property name : "wd"
	property description : "Print the path of the working directory and exit"
	property printSuccess : false
	
	ohai(workingDirectory())
end script

(*! @abstract The name of the default task. *)
property defaultTask : "help"

(*!
	@abstract
		Retrieves the task specified by the user.
	@param
		taskName <em>[text]</em> The task name.
	@return
		The task specified by the user, if found.
	@throws
		An exception if the task is not found.
*)
on findTask(taskName)
	if taskName is in {missing value, ""} then
		set taskName to my defaultTask
	end if
	
	script
		property tasks : TaskBase's tasks()
	end script
	
	repeat with t in every item of (a reference to the result's tasks)
		if taskName = (contents of t)'s name or taskName is in (contents of t)'s synonyms then return t
	end repeat
	
	error "Wrong task name"
end findTask

(*! @abstract The handler invoked by <tt>osascript</tt>. *)
on run argv
	CommandLine's parse(argv)
	tell TaskBase
		setWorkingDirectory((folder of file (path to me) of application "Finder") as text)
		set its debug to CommandLine's debug()
		set its dry to CommandLine's dry()
		set its verbose to CommandLine's verbose()
	end tell
	-- Allow loading ASMake from text format with run script
	if CommandLine's command is "__ASMAKE__LOAD__" then return me
	runTask(CommandLine's taskOptions)
end run

(*!
	@abstract
		Executes a task.
	@param
		taskOptions <em>[list]</em> A (possibly empty) list of arguments for the task.
	@throws
		An error if the command contains a syntax error,
		if the task with the specified name does not exist,
		or if the task fails.
*)
on runTask(taskOptions)
	local t
	
	try
		set t to findTask(CommandLine's command)
	on error errMsg
		Stdout's ofail("Unknown task: " & CommandLine's command, errMsg)
	end try
	
	try
		t's exec:taskOptions
		if t's printSuccess then Stdout's ohai("Success!")
		if t's dry then Stdout's ohai("(This was a dry run)")
	on error errMsg
		Stdout's ofail("Task failed", errMsg)
	end try
end runTask
