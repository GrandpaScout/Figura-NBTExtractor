if LOADMOD == "cfgw" then error("this module cannot be loaded in interactive mode", 2) end

local config = require "config"
local file = require "file"
local json = require "json"
local util = require "util"
local log = util.log

local this = {
  _read = io.open("config.lua", "r"),
  _write = io.open("config.lua.tmp", "w")
}

util.addCleanup(function()
  if io.type(this._read) == "file" then this._read:close() end
  if io.type(this._write) == "file" then this._write:close() end
end)

function this.write()
  log("Writing config file data", "cfgw", 1)
  local line, var, value, vtype
  while true do
    line = this._read:read("l")
    log('Reading line "' .. (line or "<EMPTY>") .. '"', "cfgw", 0)
    if not line then break end
    var = line:match("^%s+([%a_][%w_]*) =")
    if var then
      log('Line matched "' .. var .. '", writing update to file', "cfgw", 0)
      value = config[var]
      vtype = type(value)
      if vtype == "string" then
        this._write:write("  " .. var .. " = " .. json.writeString(value, true) .. ",\n")
      elseif vtype == "number" then
        this._write:write("  " .. var .. " = " .. json.writeNumber(value) .. ",\n")
      elseif vtype == "boolean" then
        this._write:write("  " .. var .. " = " .. json.writeBoolean(value) .. ",\n")
      else
        this._write:write("  " .. var .. " = " .. tostring(value) .. ",\n")
      end
    else this._write:write(line .. "\n") end
  end
  this._write:flush()
end

function this.save()
  log("Saving config file", "cfgw", 1)
  this._read:close()
  this._write:close()

  file.copy("config.lua.tmp", "config.lua")
  file.del("config.lua.tmp")
end

return this

