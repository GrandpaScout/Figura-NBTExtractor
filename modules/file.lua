local MODULELOADED = LOADMOD == "file"

local config = require "config"
local util = require "util"
local log = util.log

local this = {}

function this.inpf(str) return config.input_folder .. "/" .. str end
function this.outf(str) return config.output_folder .. "/" .. str end
function this.avaf(str) return config.avatar_folder .. "/" .. str end
function this.logf(str) return "logs/" .. str end

function this.check(file)
  local f = io.open(file)
  if f then f:close() end
  return f
end

function this.copy(f, t)
  log('Copied "' .. f .. '" to "' .. t .. '"', "file", 0)
  return os.execute(config.cmd_copy:subs({from = f, to = t}))
end

function this.makedir(str)
  log('Created directory "' .. str .. '"', "file", 0)
  return os.execute(config.cmd_makedir:subs(str))
end

function this.del(str)
  log('Deleted "' .. str .. '"', "file", 0)
  return os.execute(config.cmd_delete:subs(str))
end

if MODULELOADED then file = this return end

return this
