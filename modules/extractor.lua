if LOADMOD == "extractor" then error("this module cannot be loaded in interactive mode", 2) end

local bbmodel = require "bbmodel"
local config = require "config"
local file = require "file"
local json = require "json"
local png = require "png"
local snbt = require "snbt"
local util = require "util"
local log, outf, avaf = util.log, file.outf, file.avaf

local f = {}

util.addCleanup(function()
  for _,fl in ipairs(f) do if io.type(fl) == "file" then fl:close() end end
end)

if config.full_debug then
  log("Full debug mode is on: extra files will be sent to the output folder.", "extractor", 2)
  os.execute(config.cmd_timeout:subs("1"))
end

f.snbt = io.open(outf "avatar.snbt")
local snbtstring = f.snbt:read("a")
f.snbt:close()

log("Reading SNBT data", "extractor", 1)
snbt._data = snbtstring
local avatardata = snbt.readCompound()

if config.full_debug then
  log("Exporting Avatar Data", "extractor", 0)
  f.avatardebug = io.open(outf "avatardata.luatable", "w")
  f.avatardebug:write(util.printTable(avatardata))
  f.avatardebug:close()
end

log("Creating Blockbench data", "extractor", 1)
for i,v in ipairs(avatardata.model.parts) do
  bbmodel._data.outliner[i] = bbmodel.convertGroup(v)
end

log("Converting texture array", "extractor", 1)
local pngdata = png.convertArray(avatardata.texture.img2)
bbmodel.createTexture(pngdata)

local epngdata = {}
if avatardata.exTexs then
  log("Converting other texture arrays", "extractor", 1)
  for i,t in ipairs(avatardata.exTexs) do
    log("Converting texture" .. (t.type or i) .. " array", "extractor", 1)
    epngdata[i] = {
      type = t.type,
      img2 = png.convertArray(t.img2)
    }
    bbmodel.createTexture(epngdata[i].img2, epngdata[i].type)
  end
end

if config.full_debug then
  log("Exporting Blockbench Data", "extractor", 0)
  f.outlinerdebug = io.open(outf "bboutliner.luatable", "w")
  f.outlinerdebug:write(util.printTable(bbmodel._data))
  f.outlinerdebug:close()
end

log("Converting Blockbench data to JSON", "extractor", 1)
local jsondata = json.writeObject(bbmodel._data)

log("Saving Blockbench model", "extractor", 1)
f.bbmodel = io.open(avaf((bbmodel._type or "model") .. ".bbmodel"), "w")
f.bbmodel:write(jsondata)
f.bbmodel:close()

log("Saving texture", "extractor", 1)
f.png = io.open(avaf "texture.png", "wb")
f.png:write(pngdata)
f.png:close()

if avatardata.exTexs then
  log("Saving other textures", "extractor", 1)
  for i,d in ipairs(epngdata) do
    log("Saving texture" .. (d.type or i), "extractor", 1)
    local fname = "png" .. (d.type or i)
    f[fname] = io.open(avaf("texture" .. (d.type or i) .. ".png"), "wb")
    f[fname]:write(d.img2)
    f[fname]:close()
  end
end

if avatardata.script then
  log("Exporting script", "extractor", 1)
  f.script = io.open(avaf "script.lua", "w")
  f.script:write(avatardata.script.src)
  f.script:close()
end

log("Extraction done! Check the avatar folder for the extracted avatar.", "extractor", 1)
