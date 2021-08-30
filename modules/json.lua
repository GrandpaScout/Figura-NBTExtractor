local MODULELOADED = LOADMOD == "json"

local util = require "util"
local log = util.log
local this = {
  _stringEscapes = {
    ["\b"] = [[\b]],
    ["\f"] = [[\f]],
    ["\n"] = [[\n]],
    ["\r"] = [[\r]],
    ["\t"] = [[\t]],
    ["\\"] = [[\\]],
    ['"'] = [[\"]]
  },
  _stringEscapesEx = {
    ["\a"] = [[\a]],
    ["\v"] = [[\v]]
  },
  convert = {},
  Null = {}
}

function this.null() return this.Null end

function this.writeNull()
  log("Writing null <null>", "json", 1)
  return "null"
end

function this.writeBoolean(bool)
  local str = bool and "true" or "false"
  log("Writing boolean <" .. str .. ">", "json", 1)
  return str
end

function this.writeString(str, ex)
  str = str:gsub("([\b\f\n\r\t\\\"])", this._stringEscapes)
  if ex then str = str:gsub("([\a\v])", this._stringEscapesEx) end
  log(
    'Writing string <"' .. (#str > 128 and (str:sub(1,125) .. "...") or str:sub(1,128)) .. '">',
    "json", 1
  )
  return '"' .. str .. '"'
end

function this.writeNumber(num)
  log("Writing number <" .. tostring(num) .. ">", "json", 1)
  return tostring(num)
end

function this.writeList(tbl)
  log("Writing list", "json", 1)
  local strs = {}
  for _,v in ipairs(tbl) do
    strs[#strs+1] = (this.convert[type(v)] or this.convert.default)(v)
  end
  log("End of list", "json", 0)
  return "[" .. table.concat(strs, ",") .. "]"
end

function this.writeObject(tbl)
  log("Writing object", "json", 1)
  local strs = {}
  for k,v in pairs(tbl) do
    if k ~= "\0type" then
      strs[#strs+1] =
        this.writeString(tostring(k)) .. ":" .. (this.convert[type(v)] or this.convert.default)(v)
    end
  end
  log("End of object", "json", 0)
  return "{" .. table.concat(strs, ",") .. "}"
end

this.convert.default = function(v) return this.writeString(tostring(v)) end
this.convert.boolean = this.writeBoolean
this.convert.string = this.writeString
this.convert.number = this.writeNumber
this.convert.table = function(v)
  if v == this.Null then
    return this.writeNull()
  elseif v["\0type"] == "list" then
    return this.writeList(v)
  elseif v["\0type"] == "dict" then
    return this.writeObject(v)
  else
    return this.writeString(tostring(v))
  end
end

if MODULELOADED then json = this return end

return this
