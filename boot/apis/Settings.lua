local utils = require and require("modules.utilities") or dofile("boot/modules/utilities.lua")
local class = require and require("modules.class") or dofile("boot/modules/class.lua")
local fm = require and require("modules.fm") or dofile("boot/modules/fm.lua")
settings_init = class:SubClass("Settings")
function settings_init:set(key,value)
end
function settings_init.get(key)
    
end

local settings = settings_init()
BIOS.Settings = settings:Create_Object("Settings",{
    
})