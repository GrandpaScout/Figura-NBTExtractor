local MODULELOADED = LOADMOD == "bbmodel"

local base64 = require "base64"
local config = require "config"
local json = require "json"
local prompt = require "prompt"
local util = require "util"
local ul, ud, log = util.list, util.dict, util.log
local null = json.null()

local this = {
  _existingguids = {},
  _currentpath = {},
  _type = false,
  _playeroffsets = {
    {n = "Head", 0, 24, 0},
    {n = "Body", 0, 24, 0},
    {n = "RightArm", 5, 22, 0},
    {n = "LeftArm", -5, 22, 0},
    {n = "RightLeg", 2, 12, 0},
    {n = "LeftLeg", -2, 12, 0},
  },
  _data = {
    meta = ud{
      format_version = "3.6",
      creation_time = os.time(),
      model_format = "free",
      box_uv = false
    },
    name = "recovered_model",
    geometry_name = "[RECOVERED MODEL] || Recovery script by @Grandpa Scout#5292",
    visible_box = ul{1, 1 ,0},
    resolution = false,
    elements = ul{},
    outliner = ul{},
    textures = ul{}
  }
}

---Creates a GUID for use in blockbench.
---***
---*Dev notes:*  
---This is (almost) how Blockbench creates GUIDs.  
---I changed the function to use one random function per part, instead of combining 8 2-byte pieces.
---It also retries if it finds a GUID it already created because I am not about to deal with the
---dumb shit that the rare chance of a GUID conflict would do.
---
---Blockbench creates GUIDs with
---```js
---function guid() {
---  function s4() {
---    return Math.floor((1 + Math.random()) * 0x10000)
---      .toString(16)
---      .substring(1);
---  }
---  return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
---    s4() + '-' + s4() + s4() + s4();
---}
---```
---@return string guid
function this.generateGUID()
  local guid = {}
  while true do
    guid = ("%08x-%04x-%04x-%04x-%012x"):format(
      math.random(0, 0xFFFFFFFF), math.random(0, 0xFFFF), math.random(0, 0xFFFF),
      math.random(0, 0xFFFF), math.random(0, 0xFFFFFFFFFFFF)
    )
    if not this._existingguids[guid] then
      this._existingguids[guid] = true
      break
    end
  end
  log('Generated GUID "' .. guid .. '"', "bbmodel", 0)
  return guid
end

---Gets a random color index for the parts and groups in blockbench.
---@return "1"|"2"|"3"|"4"|"5"|"6"|"7" colorIndex
function this.randomColor() return math.random(0, 7) end

---Gets the model path for use in logging.
---@return string path
function this.getPath() return table.concat(this._currentpath, ".") end

---Asks the user if a model is a `player_model` file.
function this.askForType()
  this._type = prompt.choice(
    "\n--------------------------------------------------------\n" ..
    "A `player_model` keyword has been detected in the model.\n" ..
    "Is this model a `player_model.bbmodel`?"
  ) and "player_model" or "model"
end

---Converts a Lua table `cub` into a BBModel `Element`.
---@param c table
---@param o table
---@return string guid
function this.convertCube(c, o)
  this._currentpath[#this._currentpath+1] = c.nm
  local p = c.props
  log('Getting contents of cube "' .. this.getPath() .. '"', "bbmodel", 1)
  local tbl = ud{
    name = c.nm,
    visibility = c.vsb ~= 1,
    from = ul{p.f[1], p.f[2], p.f[3]}, to = ul{p.t[1], p.t[2], p.t[3]},
    rotation = c.rot and ul{c.rot[1], c.rot[2], c.rot[3]} or ul{0, 0, 0},
    origin = c.piv and ul{c.piv[1], c.piv[2], -c.piv[3]} or ul{0, 0, 0},
    color = this.randomColor(),
    uuid = this.generateGUID(),
    inflate = p.inf,
    export = true, locked = false, autouv = 0, rescale = false,
    uv_offset = ul{
      math.min(
        p.n.texture and p.n.uv[1] or math.huge, p.e.texture and p.e.uv[1] or math.huge,
        p.s.texture and p.s.uv[1] or math.huge, p.w.texture and p.w.uv[1] or math.huge,
        p.u.texture and p.u.uv[1] or math.huge, p.d.texture and p.d.uv[1] or math.huge
      ),
      math.min(
        p.n.texture and p.n.uv[2] or math.huge, p.e.texture and p.e.uv[2] or math.huge,
        p.s.texture and p.s.uv[2] or math.huge, p.w.texture and p.w.uv[2] or math.huge,
        p.u.texture and p.u.uv[2] or math.huge, p.d.texture and p.d.uv[2] or math.huge
      ),
    },
    faces = ud{
      north = ud{
        uv = ul{p.n.uv[1], p.n.uv[2], p.n.uv[3], p.n.uv[4]}, texture = p.n.texture or null
      },
      east = ud{
        uv = ul{p.e.uv[1], p.e.uv[2], p.e.uv[3], p.e.uv[4]}, texture = p.e.texture or null
      },
      south = ud{
        uv = ul{p.s.uv[1], p.s.uv[2], p.s.uv[3], p.s.uv[4]}, texture = p.s.texture or null
      },
      west = ud{
        uv = ul{p.w.uv[1], p.w.uv[2], p.w.uv[3], p.w.uv[4]}, texture = p.w.texture or null
      },
      up = ud{
        uv = ul{p.u.uv[1], p.u.uv[2], p.u.uv[3], p.u.uv[4]}, texture = p.u.texture or null
      },
      down = ud{
        uv = ul{p.d.uv[1], p.d.uv[2], p.d.uv[3], p.d.uv[4]}, texture = p.d.texture or null
      }
    }
  }
  tbl.uv_offset[1] = tbl.uv_offset[1] == math.huge and 0 or tbl.uv_offset[1]
  tbl.uv_offset[2] = tbl.uv_offset[2] == math.huge and 0 or tbl.uv_offset[2]

  if not this._data.resolution and p.tw and p.th then
    log("Found texture resolution <" .. p.tw .. ", " .. p.th .. ">", "bbmodel", 1)
    this._data.resolution = ud{width = p.tw, height = p.th}
  end

  if o then
    log('  Cube has an offset "' .. o.n .. '"', "bbmodel", 0)
    tbl.origin[1] = tbl.origin[1] + o[1]
    tbl.origin[2] = tbl.origin[2] + o[2]
    tbl.origin[3] = tbl.origin[3] + o[3]
    tbl.from[1] = tbl.from[1] + o[1]
    tbl.from[2] = tbl.from[2] + o[2]
    tbl.from[3] = tbl.from[3] + o[3]
    tbl.to[1] = tbl.to[1] + o[1]
    tbl.to[2] = tbl.to[2] + o[2]
    tbl.to[3] = tbl.to[3] + o[3]
  end

  this._currentpath[#this._currentpath] = nil
  this._data.elements[#this._data.elements+1] = tbl
  return tbl.uuid
end

---Converts a Lua table `na` into a BBModel `Group`.
---@param g table
---@param o table
---@return table group
function this.convertGroup(g, o)
  this._currentpath[#this._currentpath+1] = g.nm
  log('Getting contents of group "' .. this.getPath() .. '"', "bbmodel", 1)
  local tbl = ud{
    name = g.nm,
    visibility = g.vsb ~= 1,
    rotation = g.rot and ul{g.rot[1], g.rot[2], g.rot[3]} or ul{0, 0, 0},
    origin = g.piv and ul{g.piv[1], g.piv[2], -g.piv[3]} or ul{0, 0, 0},
    color = this.randomColor(),
    uuid = this.generateGUID(),
    export = true, isOpen = false, locked = false, autouv = 0,
    children = ul{}
  }

  if not o and this._type ~= "model" then
    for _,v in ipairs(this._playeroffsets) do
      if tbl.name:find(v.n) then
        if not this._type then this.askForType() if this._type == "model" then break end end
        log('  Setting offset of group to "' .. v.n .. '"', "bbmodel", 0)
        o = v
      end
    end
  end
  if o then
    log('  Group has an offset "' .. o.n .. '"', "bbmodel", 0)
    tbl.origin[1] = tbl.origin[1] + o[1]
    tbl.origin[2] = tbl.origin[2] + o[2]
    tbl.origin[3] = tbl.origin[3] + o[3]
  end

  if g.chld then
    log("  Getting children of group...", "bbmodel", 0)
    for i,v in ipairs(g.chld) do
      tbl.children[i] =
        (v.pt == "na" and this.convertGroup(v, o)) or
        (v.pt == "cub" and this.convertCube(v, o)) or
        error(
          "failed to determine type '" .. tostring(v.pt) .. "' of part at" ..
          this.getPath() .. "." .. v.nm
        )
    end
  end

  this._currentpath[#this._currentpath] = nil
  return tbl
end


function this.createTexture(pngd, ext)
  ext = ext and tostring(ext)
  log("Creating texture entry <" .. (ext and ext or "DEFAULT") .. ">", "bbmodel", 1)
  local texname = "texture" .. (ext or "") .. ".png"
  this._data.textures[#this._data.textures+1] = ud{
    path = util._cwd and util.path(util._cwd, config.avatar_folder, texname) or nil,
    name = texname,
    folder = config.avatar_folder,
    namespace = "",
    id = #this._data.textures,
    particle = false,
    render_mode = "normal",
    visible = true,
    mode = "bitmap",
    saved = true,
    uuid = this.generateGUID(),
    relative_path = "../" .. texname,
    source = pngd and ("data:image/png;base64," .. base64.encode(pngd)) or nil
  }
end

if MODULELOADED then bbmodel = this return end

return this
