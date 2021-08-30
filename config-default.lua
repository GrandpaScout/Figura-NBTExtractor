return {
  ---===[[PATHS]]===---

  ---The cache folder. This will not exist if you have not run the extractor yet.
  ---@type string?
  cache_folder = nil,

  ---The path to java.exe. This will not exist if you have not run the extractor yet.  
  ---Despite this being the Java "path" this can actually be any command that starts java.
  ---@type string?
  java_path = nil,

  ---The minecraft server jar.
  ---@type string
  server_jar = "server.jar",

  ---The character that seperates folders and files.
  ---@type string
  path_seperator = "\\",

  ---The converter input folder
  ---@type string
  input_folder = "input",

  ---The converter output folder
  ---@type string
  output_folder = "output",

  ---The recovered avatar folder
  ---@type string
  avatar_folder = "avatar",


  ---===[[LOGGING]]===---

  ---The minimum log level to log to the console (The data converter does not follow this value.)
  ---@type
  ---| "0" #DEBUG
  ---| "1" #INFO
  ---| "2" #WARN
  ---| "3" #ERROR
  min_log_level = 1,

  ---Output raw lua tables to the output folder
  ---@type boolean
  full_debug = false,


  ---===[[COMMANDS]]===---

  ---The string to cause a sound to be made in the command prompt.  
  ---Empty this string to make prompts silent or if your command prompt does not support bells.
  ---@type string
  cmd_bell = "\a\a",

  ---The command to run to confirm java is in the path.  
  ---This command should return exit code 0 on success and 1 on failure.  
  ---If you do not want this command to run, set `java_path`.
  ---@type string
  cmd_where_java = "WHERE java /Q",

  ---The command to run to get the current directory.  
  ---If your system does not support `io.popen()`, setting this to `nil` will disable it.
  ---@type string?
  cmd_cd = "CD",

  ---The command to run to copy a file.
  ---```
  ---%from -- The file to copy from
  ---%to   -- The file to copy to
  ---```
  ---@type string
  cmd_copy = "COPY /Y \"%from\" \"%to\">NUL",

  ---The command to run to make a directory.
  ---```
  ---%% -- The directory to make
  ---```
  ---@type string
  cmd_makedir = "IF NOT EXIST \"%%\" (MD \"%%\")>NUL",

  ---The command to run to delete a file.
  ---```
  ---%% -- The directory to make
  ---```
  ---@type string
  cmd_delete = "DEL /Q \"%%\"",

  ---The command to run to get the user's choice.  
  ---This command should return exit code 1 on the yes key, and exit code 2 on the no key.  
  ---This command should refuse to end unless one of the keys are pressed.
  ---```
  ---%yes  -- The key to press to confirm the choice.
  ---%no   -- The key to press to deny the choice.
  ---%bell -- Used to place the bell noise.
  ---```
  ---@type string
  cmd_confirm = "CHOICE /C \"%yes%no\" /N /M \"%bell\"",

  ---The command to run the converter.
  ---In the default Windows command, the @ stops cmd from breaking the line.
  ---```
  ---%java   -- The java executable.
  ---%server -- The Minecraft server jar
  ---%input  -- The dircetory to use as input.
  ---%output -- The dircetory to use as output.
  ---```
  ---@type string
  cmd_run_converter = "@\"%java\" -cp \"%server\" net.minecraft.data.Main --dev --input \"%input\" --output \"%output\"",

  ---The command to use to wait a certain amount of time.  
  ---The reason this exists is because Lua will always "busy wait" which wastes CPU time.
  ---```
  ---%% -- Seconds to wait for.
  ---```
  ---@type string
  cmd_timeout = "TIMEOUT /T %% /NOBREAK>NUL",

  ---===[[ADVANCED]]===---

  ---Sets protected mode.  
  ---If protected mode is on, an error during extraction will not throw a Lua error and will
  ---instead cause the extractor to end early and show a message detailing how to get help.
  ---@type boolean
  protected = true,
}
