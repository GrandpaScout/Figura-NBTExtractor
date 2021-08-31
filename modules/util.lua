local MODULELOADED = LOADMOD == "util"

local config = require "config"

local this = {
  _logcount = 0,
  _cleanup = {}
}

local levels = {[0] = "DEBUG", "INFO", "WARN", "ERROR"}

function this.addCleanup(func)
  this._cleanup[#this._cleanup+1] = func
end

function this.cleanup(errored)
  for _,f in ipairs(this._cleanup) do f() end
  os.exit(not errored)
end

---@param str string
---@return string
function string.subs(str, rep)
  if type(rep) == "table" then
    str = str:gsub("%%(%a+)", rep)
  else
    str = str:gsub("%%%%", rep)
  end
  return str
end

---@param str string
function string.indent(str, ind)
  str = str:gsub("\n", "\n" .. string.rep(" ", ind))
  return str
end

function string.trim(str)
  return str:gsub("^(%s+)", ""):gsub("(%s+)$", "")
end

function this.list(tbl)
  tbl["\0type"] = "list"
  return tbl
end

function this.dict(tbl)
  tbl["\0type"] = "dict"
  return tbl
end

if not LOADMOD then
  this._logfile = io.open("logs/extractor.log", "w")
  function this.log(str, module, level)
    level = level or 1
    local line
    if level >= config.min_log_level and level < 3 then
      line =
        ("[%s] [%s/%s]: %s"):format(os.date("%X", os.time()), module, levels[level], str)
      this._logfile:write(line .. "\n")
      print(line)
    elseif level >= 3 then
      line =
        ("[%s] [%s/%s]: %s\n  %s")
          :format(
            os.date("%X", os.time()),
            module, levels[3], str,
            debug.traceback(nil, 2)):indent(2)
      this._logfile:write(line .. "\n")
      if level ~= 5 then
        print(line)
        if level == 4 then this.cleanup() end
      else
        error(str, 2)
      end
    end
    this._logcount = this._logcount + 1
    if this._logcount >= 50 then
      this._logfile:flush()
      this._logcount = 0
    end
  end
else
  function this.log() end
end

local stresc = {
  ["\a"] = [[\a]], ["\b"] = [[\b]], ["\f"] = [[\f]], ["\n"] = [[\n]], ["\r"] = [[\r]],
  ["\t"] = [[\t]], ["\v"] = [[\v]], ["\\"] = [[\\]], ["\""] = [[\"]],
}

function this.printTable(tbl, indent, done)
  local lastloglevel
  if not done then
    lastloglevel = config.min_log_level
    config.min_log_level = 2
  end
  local str, keys = "", {}
	done, indent = done or {}, indent or 0
  for k in pairs(tbl) do if k ~= "\0type" then keys[#keys+1] = k end end
	table.sort(keys, function(a, b)
		if (type(a) == "number") and (type(b) == "number") then return a < b end
		return tostring(a) < tostring(b)
	end)

	done[tbl] = true

	for i=1,#keys do
		local key = keys[i]
		local value = tbl[key]
		str = str .. string.rep(" ", indent)
		if (type(value) == "table") and not done[value] then
      local typ = value["\0type"]
      typ = (typ and (": " .. typ:sub(1,1):upper() .. typ:sub(2)) or "") .. "\n"
      if type(key) == "string" then
        str = str .. '["' .. key:gsub("([\a\b\f\n\r\t\v\\\"])", stresc) .. '"]'
      else
        str = str .. '["' .. tostring(key) .. '"]'
      end
			done[value] = true
			str = str .. typ .. this.printTable(value, indent+2, done)
			done[value] = nil
		else
      if type(key) == "string" then
        str = str .. '["' .. key:gsub("([\a\b\f\n\r\t\v\\\"])", stresc) .. '"] = '
      else
        str = str .. '["' .. tostring(key) .. '"] = '
      end
      if type(value) == "string" then
        str = str .. '"' .. value:gsub("([\a\b\f\n\r\t\v\\\"])", stresc) .. '"\n'
      else
        str = str .. tostring(value) .. "\n"
      end
		end
	end
  if lastloglevel then config.min_log_level = lastloglevel end
  return str
end

function this.path(...)
  return
    table.concat({...}, PATH_SEPERATOR)
      :gsub("[\\/]", PATH_SEPERATOR)
      :gsub(PATH_SEPERATOR:rep(2), PATH_SEPERATOR)
end

if config.cmd_cd then
  local s, cwd = pcall(io.popen(config.cmd_cd))
  if s then
    this._cwd = cwd:read("l")
    cwd:close()
  else
    this.log("Your system does not support `io.open` or the cmd_cd command failed so config.cmd_cd has been cleared", "util", 2)
    config.cmd_cd = nil
  end
end

if MODULELOADED then util = this return end

return this
