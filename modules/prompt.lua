local MODULELOADED = LOADMOD == "prompt"

local config = require "config"

local this = {}

function this.read(msg)
  io.write(string.indent(msg .. "\n  > ", 2))
  return io.read()
end

---@return boolean
function this.choice(msg, y, n)
  local tbl = {yes = y or "y", no = n or "n", bell = config.cmd_bell}
  io.write(string.indent(msg .. string.subs("\n  [%yes/%no]>", tbl):upper(), 2))
  local _, _, exitcode = os.execute(config.cmd_confirm:subs(tbl))
  return exitcode == 1
end

if MODULELOADED then prompt = this return end

return this
