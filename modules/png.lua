local MODULELOADED = LOADMOD == "png"

local util = require "util"
local log = util.log

local this = {}

function this.convertArray(tbl)
  log("Converting byte array to png", "png", 1)
  local str = ""
  local chars = {}
  for _,n in ipairs(tbl) do
    chars[#chars+1] = n%256
    if #chars == 512 then
      log("Storing chunk", "png", 0)
      str = str .. string.char(table.unpack(chars))
      chars = {}
    end
  end

  if #chars > 0 then
    log("Storing chunk", "png", 0)
    str = str .. string.char(table.unpack(chars))
  end

  log("Conversion finished", "png", 1)
  return str
end

if MODULELOADED then png = this return end

return this
