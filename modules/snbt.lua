local MODULELOADED = LOADMOD == "snbt"

local util = require "util"
local log = util.log

local this = {
  _stringEscapes = {
    ["a"] = "\a",
    ["b"] = "\b",
    ["f"] = "\f",
    ["n"] = "\n",
    ["r"] = "\r",
    ["t"] = "\t",
    ["v"] = "\v",
    ["\\"] = "\\",
    ["\""] = '"',
    ["\'"] = "'"
  },
  _seek = 1
}

function string.seek(s, pattern)
  local seekto = s:match(pattern, this._seek)
  if seekto and type(seekto) ~= "number" then
    log("Attempted to seek to a non-number match", "snbt", 2)
  end
  this._seek = seekto or this._seek
  if seekto then log("Seeking to character " .. tostring(this._seek), "snbt", 0) end
  return not not seekto
end

function this.readName()
  log("Reading name at character " .. tostring(this._seek), "snbt", 0)
  if this._data:match("^\"", this._seek) then
    local startseek, str = this._seek, this.readString()
    if not this._data:match("^:", this._seek) then
      log("Failed to find name at character " .. startseek, "snbt", 5)
    end
    this._seek = this._seek + 1
    return str
  else
    local name, seekto = this._data:match("([^:]+):()", this._seek)
    if not name then log("Failed to find name at character " .. this._seek, "snbt", 5) end
    this._seek = seekto
    return name
  end
end

function this.readTag(hasName)
  log("Reading tag at character " .. tostring(this._seek), "snbt", 1)
  local name, didseek
  this._data:seek('^,?%s*()')
  if hasName then
    name = this.readName()
  end

  didseek = this._data:seek("^%s*()%[[BbIiLl];")
  if didseek then return "readArray", name end

  didseek = this._data:seek("^%s*()%[")
  if didseek then return "readList", name end

  didseek = this._data:seek("^%s*(){")
  if didseek then return "readCompound", name end

  didseek = this._data:seek("^%s*()[\"']")
  if didseek then return "readString", name end

  didseek = this._data:seek("^%s*()[%-%d%.]")
  if didseek then return "readNumber", name end

  log("Failed to get type at character " .. this._seek, "snbt", 5)
end

function this.readArray()
  log("Reading array at character " .. tostring(this._seek), "snbt", 1)
  local tbl, data = {["\0type"] = "list"}
  local startseek = this._seek
  data, this._seek = this._data:match("^(%b[])()", this._seek)
  if not data then log("Failed to read array at character" .. startseek, "snbt", 5) end

  for number in data:gmatch("(-?%d+)") do
    tbl[#tbl+1] = tonumber(number)
  end
  return tbl
end

function this.readList()
  log("Reading list at character " .. tostring(this._seek), "snbt", 1)
  local tbl = {["\0type"] = "list"}
  this._seek = this._seek + 1

  local method = this.readTag(false)
  method = this[method]
  while true do
    tbl[#tbl+1] = method()
    if not this._data:seek("^,%s*()") then
      if this._data:seek("^%s*]()") then
        break
      else
        log("Failed to read list at character " .. this._seek, "snbt", 5)
      end
    end
  end
  return tbl
end

function this.readCompound()
  log("Reading compound at character " .. tostring(this._seek), "snbt", 1)
  local tbl = {["\0type"] = "dict"}
  this._seek = this._seek + 1

  local method, name
  while true do
    method, name = this.readTag(true)
    tbl[name] = this[method]()
    if not this._data:seek("^,%s*()") then
      if this._data:seek("^%s*}()") then
        break
      else
        log("Failed to read compound at character " .. this._seek, "snbt", 5)
      end
    end
  end
  return tbl
end

function this.readString()
  log("Reading string at character " .. tostring(this._seek), "snbt", 1)
  local endchar = this._data:sub(this._seek, this._seek)
  if endchar ~= '"' and endchar ~= "'" then
    log("Failed to read string at character " .. this._seek, "snbt", 5)
  end
  local tbl, escapeNext, ret = {}, false, ""
  while true do
    this._seek = this._seek + 1
    local char = this._data:sub(this._seek, this._seek)
    if escapeNext then
      if not this._stringEscapes[char] then
        log("Invalid escape \"\\" .. char .. "\" in string at character " .. this._seek, "snbt", 5)
      end
      tbl[#tbl+1] = this._stringEscapes[char]
      escapeNext = false
    elseif char == "\\" then
      escapeNext = true
    elseif char == endchar then
      log("  Saving chunk to string", "json", 0)
      ret = ret .. table.concat(tbl, "")
      break
    else
      tbl[#tbl+1] = char
    end
    if #tbl == 1024 then
      log("  Saving chunk to string", "json", 0)
      ret = ret .. table.concat(tbl, "")
      tbl = {}
    end
  end
  this._seek = this._seek + 1
  return ret
end

function this.readNumber()
  log("Reading number at character " .. tostring(this._seek), "snbt", 1)
  local num, seekend = this._data:match("^(%-?%d+%.?%d*[Ee]%-?%d+)[BbSsIiLlFfDd]?()", this._seek)
  if not num then
    num, seekend = this._data:match("^(%-?%d+%.?%d*)[BbSsIiLlFfDd]?()", this._seek)
    if not num then
      log("Failed to read number at character " .. this._seek, "snbt", 5)
    end
  end
  this._seek = seekend
  return tonumber(num)
end

if MODULELOADED then snbt = this return end

return this
