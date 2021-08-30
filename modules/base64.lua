local MODULELOADED = LOADMOD == "base64"

local util = require "util"
local log = util.log

local sbyte, srep = string.byte, string.rep

local this = {
  _digit = {
    [0]="A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W",
    "X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u",
    "v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"
  }
}

---Converts text to base64.
---@param str string
---@return string base64
function this.encode(str)
  log("Converting to Base64", "base64", 0)
  local p = 2 - (#str - 1) % 3
  return
    (str .. srep("\0", p))
      :gsub("...", function(chars)
        local c1, c2, c3 = sbyte(chars, 1, 3)
        return
          this._digit[c1>>2] .. this._digit[(c1&3)<<4|c2>>4] ..
          this._digit[(c2&15)<<2|c3>>6] .. this._digit[c3&63]
      end)
      :sub(1, -p-1) .. srep("=", p)
end

if MODULELOADED then base64 = this return end

return this
