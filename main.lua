if LOADMOD == "main" then error("this module cannot be loaded in interactive mode", 2) end

--================================================================================================--
--=====  INIT  ===================================================================================--
--#region ========================================================================================--

local MAJOR, MINOR = _VERSION:match("^Lua (%d+)%.(%d+)")
MAJOR, MINOR = tonumber(MAJOR), tonumber(MINOR)
if not (MAJOR == 5 and MINOR >= 2 and MINOR <= 5) then
  error("requires Lua 5.3.x or 5.4.x to run", 2)
end
if not os.execute() then error("failed to find shell for the script to use", 2) end
package.path = "./?.lua;./modules/?.lua"
_G.PATH_SEPERATOR = package.config:sub(1,1)

_G.LOADMOD = arg[1]
if LOADMOD == "-f" then
  _G.LOADMOD, _G.LOADFILE = nil, arg[2]
elseif LOADMOD then
  LOADMOD = LOADMOD:match("%.?([^%.]+)$")
  local foundiflag, argi = false, 0
  while not foundiflag do
    argi = argi - 1
    if arg[argi] == "-i" then
      foundiflag = true break
    elseif not arg[argi] then
      break
    end
  end
  if not foundiflag then
    error("modules can only be loaded standalone if interactive mode (`-i`) is enabled", 0)
  end
  _G._PROMPT, _G._PROMPT2 = ">>> ", "∙∙∙ "
  require(LOADMOD)
  return
end

--#endregion


--================================================================================================--
--=====  MAIN  ===================================================================================--
--#region ========================================================================================--

_G.MAINLOADED = true

local config = require "config"
local file = require "file"
os.execute(config.cmd_makedir:subs("logs"))
if file.check("logs" .. PATH_SEPERATOR .. "latest.log") then
  os.execute(config.cmd_delete:gsub("%%%%", "logs" .. PATH_SEPERATOR .. "latest.log"))
end
os.execute(config.cmd_timeout:gsub("%%%%", "1"))

local cfgw = require "cfgw"
local prompt = require "prompt"
local uuid = require "uuid"
local util = require "util"
local log = util.log

local mcserver = io.open(config.server_jar, "rb")
if mcserver then
  mcserver:close()
else
  log(
    string.subs('Minecraft server jar missing ("%%")', config.server_jar) ..
    string.indent(
      "\nYou can get a server jar from the Minecraft Launcher by editing a Minecraft" ..
      "\ninstallation and clicking the SERVER button above the version dropdown." ..
      "\nWhen you download the server, place it in the same folder as `main.lua`.", 2
    ), "main", 3)
end

--#endregion

--================================================================================================--
--=====  USER INPUT  =============================================================================--
--#region ========================================================================================--

io.stdout:write(string.indent(
  "\nThis file was made with Windows in mind.\n" ..
  "I have no idea if this script will work on other systems, probably won't.\n", 2
))

local cache_file
if LOADFILE then
  cache_file = LOADFILE
else
  if not config.java_path then
    local _, _, c = os.execute(config.cmd_where_java)
    if c == 0 then
      config.java_path = "java"
    end
    if not config.java_path then
      config.java_path = prompt.read(
        "\n------------------------------\n" ..
        "Java is missing from the path!" ..
        'Where is "bin' .. PATH_SEPERATOR .. 'java.exe"?\n' ..
        "(You can drag it into this window if your prompt supports it.)"
      ):gsub('^"', ""):gsub('"$', "")
    end
  end

  do
    if config.cache_folder then
      if not prompt.choice(
        "\n---------------------------------------------\n" ..
        "Do you want to use the previous cache folder?"
      ) then
        config.cache_folder = prompt.read(
          "\n------------------------------------\n" ..
          'Where is your "figura' .. PATH_SEPERATOR .. 'cache" folder?\n' ..
          "(You can drag it into this window if your prompt supports it.)"
        )
      end
    else
      config.cache_folder = prompt.read(
        "\n------------------------------------\n" ..
        'Where is your "figura' .. PATH_SEPERATOR .. 'cache" folder?\n' ..
        "(You can drag it into this window if your prompt supports it.)"
      ):gsub('^"', ""):gsub('"$', "")
    end
  end
  cache_file = config.cache_folder

  local player_uuid = prompt.read(
    "\n---------------------------------------------------\n" ..
    "What is the UUID of the player you want to extract?\n" ..
    "UUID4, Int32[], and UUIDMost/Least are supported."
  ):trim()
  print()
  local seg
  do
    --UUID4
    seg = uuid.toUUID4Seg(uuid.fromAny(player_uuid))
    if not seg then log("Could not determine if a UUID was given", "main", 4) end
  end
  cache_file = cache_file .. PATH_SEPERATOR .. table.concat(seg, PATH_SEPERATOR) .. ".nbt"
end

--#endregion

--================================================================================================--
--=====  PREPARE  ================================================================================--
--#region ========================================================================================--

log("Cleaning workspace", "main", 1)
file.makedir(config.input_folder)
file.makedir(config.output_folder)
file.makedir(config.avatar_folder)
file.del(util.path(config.input_folder, "*.*"))
file.del(util.path(config.output_folder, "*.*"))
file.del(util.path(config.avatar_folder, "*.*"))

log("Copying NBT File to workspace", "main", 1)
do
  local s = file.copy(cache_file, file.inpf("avatar.nbt"))

  if not s then log('Could not find file "' .. cache_file .. '"', "main", 4) end
end

cfgw.write()
cfgw.save()

log("Running Data Converter", "main", 1)

os.execute(config.cmd_run_converter:subs(
  {
    java = (config.java_path or "java"),
    server = config.server_jar,
    input = config.input_folder,
    output = config.output_folder
  }
))

if not file.check(file.outf "avatar.snbt") then
  log("The data converter failed to create an SNBT file", "main", 4)
end

--#endregion

--================================================================================================--
--=====  EXTRACTOR  ==============================================================================--
--#region ========================================================================================--

local exs, exe
if config.protected then
  log("Running extractor a protected call", "main", 0)
  exs, exe = pcall(require, "extractor")
else
  log("Running extractor unprotected", "main", 0)
  exs = true
  require "extractor"
end

if not exs then
  util.cleanup(true)
  log(
    "ENCOUNTERED AN EXTRACTION ERROR: " .. tostring(exe) .. string.indent(
      "\nPlease report this to Grandpa Scout along with the log file at" ..
      '\n  "logs' .. PATH_SEPERATOR .. 'extractor.log"' ..
      "\nand the nbt file at" ..
      '\n  "' .. cache_file .. '"', 2
    ) .. "\n", "main", 3
  )
  return
end

util.cleanup(false)

--#endregion
