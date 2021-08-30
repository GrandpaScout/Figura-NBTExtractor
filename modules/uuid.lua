local MODULELOADED = LOADMOD == "uuid"

local util = require "util"
local log = util.log

local this = {
  _i = "%08x",
  _4 = "(%x%x%x%x%x%x%x%x)%-?(%x%x%x%x)%-?(%x%x%x%x)%-?(%x%x%x%x)%-?(%x%x%x%x%x%x%x%x%x%x%x%x)",
  _l = "%016x",
  _capture = {
    uuid4 = "(%x%x%x%x%x%x%x%x%-?%x%x%x%x%-?%x%x%x%x%-?%x%x%x%x%-?%x%x%x%x%x%x%x%x%x%x%x%x)",
    int32 =
      "^%[?I?;?%s*(%-?%d%d?%d?%d?%d?%d?%d?%d?%d?%d?),%s*\z
      (%-?%d%d?%d?%d?%d?%d?%d?%d?%d?%d?),%s*\z
      (%-?%d%d?%d?%d?%d?%d?%d?%d?%d?%d?),%s*\z
      (%-?%d%d?%d?%d?%d?%d?%d?%d?%d?%d?)%s*%]?$",
    msls =
      "^[Mm]?[Oo]?[Ss]?[Tt]?:?(%-?%d%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?)[Ll]?,%s*\z
      [Ll]?[Ee]?[Aa]?[Ss]?[Tt]?:?(%-?%d%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?%d?)[Ll]?$"
  }
}
local _i, _4, _l = this._i, this._4, this._l

---Converts a UUID4 to UUID4Hex
---@param uuid4 string
---@return string UUID4Hex
function this.fromUUID4(uuid4)
  if not uuid4 then return end
  log("Converting UUID4 to UUID4Hex", "uuid", 0)
  local a, b, c, d, e =
    uuid4:match(_4)

  return a .. b .. c .. d .. e
end

---Converts a Int32[] to UUID4Hex
---@param int32 number[]|string[]
---@return string UUID4Hex
function this.fromInt32(int32)
  if type(int32) ~= "table" or #int32 < 4 then return end
  log("Converting Int32[] to UUID4Hex", "uuid", 0)

  return
    _i:format(tonumber(int32[1])%0x100000000) .. _i:format(tonumber(int32[2])%0x100000000) ..
    _i:format(tonumber(int32[3])%0x100000000) .. _i:format(tonumber(int32[4])%0x100000000)
end

---Converts a UUIDMost/Least to UUID4Hex
---@param most number
---@param least number
---@return string UUID4Hex
function this.fromMostLeast(most, least)
  if not (most and least) then return end
  log("Converting UUID4Most/Least to UUID4Hex", "uuid", 0)

  return _l:format(most) .. _l:format(least)
end

---Convert from any format to UUID4Hex
---@param str string
---@return string UUID4Hex
function this.fromAny(str)
  if not str then return end
  str = str:trim()
  log("Finding conversion to UUID4Hex", "uuid", 0)
  return
    this.fromUUID4(str:match(this._capture.uuid4)) or
    this.fromInt32({str:match(this._capture.int32)}) or
    this.fromMostLeast(str:match(this._capture.msls)) or
    log("Failed to find conversion", "uuid", 0)
end

---Converts a UUID4Hex to segments
---@param uhex string
---@return string[] UUID4Seg
function this.toUUID4Seg(uhex)
  if not uhex then return end
  log("Converting UUID4Hex to UUID4Seg", "uuid", 0)
  return {uhex:sub(1,8), uhex:sub(9,12), uhex:sub(13,16), uhex:sub(17, 20), uhex:sub(21)}
end

if MODULELOADED then uuid = this return end

return this

