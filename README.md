# Figura-NBTExtractor
An almost pure Lua way to extract source data from a compressed NBT
[Figura](https://modrinth.com/mod/figura) avatar from cache.
### **This tool is meant to work on avatars from Figura 0.0.6**

&nbsp;
### Contents
~~[What's New?](#whats-new)~~  
[What Is This?](#what-is-this)  
[Why Is This Useful?](#why-is-this-useful)  
[Usage](#usage)  
&emsp;[Requirements](#requirements)  
&emsp;[Running](#running)  
&emsp;&emsp;[Interactive Mode](#interactive-mode)  
&emsp;[Using the Extractor](#using-the-extractor)  
[Configuration](#configuration)  
[Other Information](#other-information)
***
&nbsp;
# What Is This?  
This is a tool used for extracting the source model, texture, and script from a compressed NBT
[Figura](https://modrinth.com/mod/figura) avatar found in the `figura/cache` folder.

&nbsp;
# Why Is This Useful?  
This can be used to extract the data that your game cached from the Figura backend in the case that
you lose your avatar and don't have a local backup of it.

&nbsp;
# Usage  
## Requirements
**This tool is made to be run on Windows. It will not run on other systems without some config
tweaking!**

This requires Lua version `5.3.x`/`5.4.x` to run and will not run with any other version of Lua.  
(Because I said so, that's why.)

You will also need a Minecraft server jar. The latest can be downloaded from the Minecraft launcher
by selecting the latest version installation and clicking the *SERVER* button above the version
dropdown. Place the downloaded `server.jar` into the same folder with `main.lua`  
&nbsp;  
## Running
Open a command prompt in the folder where `main.lua` sits and run `path/to/lua.exe main.lua` to
start the extractor.

You can optionally use `path/to/lua.exe main.lua -f "DRIVE://path/to/avatar.nbt"` to directly
extract a file without going through the file selection steps.

### Interactive mode
Running `path/to/lua.exe -i main.lua modulename` will cause the module to be loaded standalone into
interactive mode. This will allow you to play around with the module in a (sort-of) sandbox.  
The following modules can be loaded into interactive mode:
> `base64`, `bbmodel`, `file`, `json`, `png`, `prompt`, `snbt`, `util`, `uuid`

The following modules cannot be loaded into interactive mode:
> `main`, `cfgw`, `config`, `extractor`

You can use `util.printTable` (you may need to `util = require "util"`) to print the contents of a
table if needed.  
&nbsp;
## Using the extractor
The extractor will first ask you for the cache folder (it will instead ask you if you want to to use
the last used cache folder if you have already used the extractor, saying no will then ask you for
the cache folder.)  
Put in the path for the cache folder.

It will then ask you for the UUID of a player, if you have not seen this player wearing an avatar,
the tool will not work. You can use `UUID4`, `Int32[]`, or `UUIDMost/Least` for the UUID.

The NBT extractor will run automatically after you enter the UUID.  
If the extractor prompts you, answer the prompt.

When the extractor completes successfully, the extracted files will appear in the avatar folder as
set by the config.

&nbsp;
# Configuration
A reduced version of the default config without any type annotations or %replacement descriptions is
below:
```lua
return {
  ---===[[PATHS]]===---

  ---The cache folder. This will not exist if you have not run the extractor yet.
  cache_folder = nil,

  ---The path to java.exe. This will not exist if you have not run the extractor yet.  
  ---Despite this being the Java "path" this can actually be any command that starts java.
  java_path = nil,

  ---The minecraft server jar.
  server_jar = "server.jar",

  ---The character that seperates folders and files.
  path_seperator = "\\",

  ---The converter input folder
  input_folder = "input",

  ---The converter output folder
  output_folder = "output",

  ---The recovered avatar folder
  avatar_folder = "avatar",


  ---===[[LOGGING]]===---

  ---The minimum log level to log to the console (The data converter does not follow this value.)
  min_log_level = 1,

  ---Output raw lua tables to the output folder
  full_debug = false,


  ---===[[COMMANDS]]===---

  ---The string to cause a sound to be made in the command prompt.  
  ---Empty this string to make prompts silent or if your command prompt does not support bells.
  cmd_bell = "\a\a",

  ---The command to run to confirm java is in the path.  
  ---This command should return exit code 0 on success and 1 on failure.  
  ---If you do not want this command to run, set `java_path`.
  cmd_where_java = "WHERE java /Q",

  ---The command to run to get the current directory.  
  ---If your system does not support `io.popen()`, setting this to `nil` will disable it.
  cmd_cd = "CD",

  ---The command to run to copy a file.
  cmd_copy = "COPY /Y \"%from\" \"%to\">NUL",

  ---The command to run to make a directory.
  cmd_makedir = "IF NOT EXIST \"%%\" (MD \"%%\")>NUL",

  ---The command to run to delete a file.
  cmd_delete = "DEL /Q \"%%\"",

  ---The command to run to get the user's choice.  
  ---This command should return exit code 1 on the yes key, and exit code 2 on the no key.  
  ---This command should refuse to end unless one of the keys are pressed.
  cmd_confirm = "CHOICE /C \"%yes%no\" /N /M \"%bell\"",

  ---The command to run the converter.
  ---In the default Windows command, the @ stops cmd from breaking the line.
  cmd_run_converter = "@\"%java\" -cp \"%server\" net.minecraft.data.Main --dev --input \"%input\" --output \"%output\"",

  ---The command to use to wait a certain amount of time.  
  ---The reason this exists is because Lua will always "busy wait" which wastes CPU time.
  cmd_timeout = "TIMEOUT /T %% /NOBREAK>NUL",

  ---===[[ADVANCED]]===---

  ---Sets protected mode.  
  ---If protected mode is on, an error during extraction will not throw a Lua error and will
  ---instead cause the extractor to end early and show a message detailing how to get help.
  protected = true,
}
```
If the extractor changes the config for any reason, the changes will be written to the file.

&nbsp;
# Other Information
The extractor will ask you if a model is a `player_model` type model if it finds a keyword belonging
to it. If you say yes to the prompt, the parts will automatically move to the correct positions in
the resulting Blockbench model. If you say no, the pivot points of those keywords will be set to
`0,0,0` and the parts will be positioned around that pivot.

Rotated parts are tricky since Figura can not tell between rotations from Lua and rotations from
Blockbench, because of that, the resulting model of any avatar that uses Lua to rotate parts will
have the rotations that were applied to them the very tick it was uploaded. This usually will not
cause problems unless you check the rotation of a part at the beginning of a script before rotating
it in Lua.
