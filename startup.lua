-- UnBIOS by JackMacWindows
-- modifed by wendell_parham for BIOS-CC needs 

assert(debug,"requires debug")

---checks to see if a table is selfReferencing
---@param base table
---@return boolean
---@diagnostic disable-next-line: lowercase-global
function selfReferencing(base)
    local stack = {{base, select(2, pcall(getmetatable, base))}}
    local seen = {}
    local firstLoop = true
    while true do
        local current = table.remove(stack)
        if not current then
            break
        end
        local tbl, mt = current[1], current[2]
        if tbl == base and not firstLoop then
            return true
        end
        seen[tbl] = true
        -- Iterate through the current table's values
        for _, v in pairs(tbl) do
            if v == base then
                return true
            end
            if type(v) == "table" and not seen[v] then
                table.insert(stack, {v, select(2, pcall(getmetatable, v))})
            end
        end
        -- Check the metatable's __index field if it's a table
        if type(mt) == "table" and mt.__index then
            local meta_index = mt.__index
            if type(meta_index) == "function" then
                meta_index = meta_index(tbl)
            end
            if type(meta_index) == "table" and not seen[meta_index] then
                table.insert(stack, {meta_index, select(2, pcall(getmetatable, meta_index))})
            end
        end
        firstLoop = false
    end
    return false
end

local load = load
---custom built Serialiser design to handle selfReferencing tables and functions (using string.dump)
---@param _data any
---@param _Index any
---@return string|unknown
function Serialise(_data,_Index)
    _Index = _Index or 0
    local indexGag = ("\t"):rep(_Index)
    local actions = {
          ["boolean"] = function ()
                return tostring(_data)
          end,
          ["string"] = function ()
                return "\"".._data.."\""
          end,
          ["table"] = function ()
                local result = "{\n"
                for i,v in pairs(_data) do
                      if type(v) ~= "table" or not selfReferencing(v)
                      then
                            if type(i) == "string"
                            then
                                  if string.find(i,"%p") ~= nil
                                  then
                                        result = result.."\t"..indexGag..("[\"%s\"] = "):format(i)..Serialise(v,_Index+1)..",\n"
                                  else
                                        result = result.."\t"..indexGag..("%s = "):format(i)..Serialise(v,_Index+1)..",\n"
                                  end
                            else
                                  result = result.."\t"..indexGag..Serialise(v,_Index+1)..",\n"
                            end
                      end
                end
                return result..indexGag.."}"
          end,
          ["function"] = function ()
                return string.dump(_data)
          end
    }
    actions["number"] = actions["boolean"]
    local action = actions[type(_data)]
    return action and action() or error("unknown type",2)
end
---custom text loader 
---@param _sData string
---@return unknown
function Unserialise(_sData)
    if tonumber(string.sub(_VERSION,4)) <= 5.1
    then
        ---@diagnostic disable-next-line: cast-local-type
        _ENV.load = loadstring
    end
    local func,err = load("return " .. _sData, "unserialize","t",{})
    if func then
          local ok, result = pcall(func)
          if ok then
                return result
          end
    end
    return error(err,2)
end



local open = fs.open
local exists = fs.exists
local fm = {}
local term = term
---wrapped file writer
---@param sPath string
---@param data any
---@param mode string|nil
---@return boolean|string
---@return string|nil
function fm.OverWrite(sPath,data,mode)
    mode = mode or "S"
    if mode ~= "S" and mode ~= "R"
    then
        error("Invalid mode",2)
    end
    local file,mess = open(sPath,"w")
    if file == nil then
        return false,mess
    end
    if mode == "R"
    then
        file.write(data)
    else
        file.write(Serialise(data))
    end
    file.close()
    return true
end
---wrapped file reader
---@param sPath string
---@param mode string|nil
---@return string|boolean
---@return string|nil
function fm.readFile(sPath,mode)
    mode = mode or "S"
    if mode ~= "S" and mode ~= "R"
    then
        error("Invalid mode",2)
    end
    if not exists(sPath) then
        error("Invalid path "..sPath.." dose not exist",0)
    end
    local file,mess = open(sPath,"r")
    if file == nil then
        return false,mess
    end
    local data
    if mode == "R"
    then
        data = file.readAll()
    else
        data = Unserialise(file.readAll())
    end
    file.close()
    return data
end
do
    local args = {...}
    if args[1] == "true"
    then
        settings.set("customBoot",true)
    end
end
if not settings.get("customBoot",true)
then
    printError("customBoot disabed")
    return 1
end
settings.set("shell.allow_disk_startup",false)
settings.save(".settings")
-- UnBIOS by JackMacWindows
-- This will undo most of the changes/additions made in the BIOS, but some things may remain wrapped if `debug` is unavailable
-- To use, just place a `bios.lua` in the root of the drive, and run this program
-- Here's a list of things that are irreversibly changed:
-- * both `bit` and `bit32` are kept for compatibility
-- * string metatable blocking (on old versions of CC)
-- In addition, if `debug` is not available these things are also irreversibly changed:
-- * old Lua 5.1 `load` function (for loading from a function)
-- * `loadstring` prefixing (before CC:T 1.96.0)
-- * `http.request`
-- * `os.shutdown` and `os.reboot`
-- * `peripheral`
-- * `turtle.equip[Left|Right]`
-- Licensed under the MIT license







if _HOST:find("UnBIOS") then return end
local keptAPIs = {bit32 = true, bit = true, ccemux = true, config = true, coroutine = true, debug = true, fs = true, http = true, mounter = true, os = true, periphemu = true, peripheral = true, redstone = true, rs = true, term = true, utf8 = true, _HOST = true, _CC_DEFAULT_SETTINGS = true, _CC_DISABLE_LUA51_FEATURES = true, _VERSION = true, assert = true, collectgarbage = true, error = true, gcinfo = true, getfenv = true, getmetatable = true, ipairs = true, __inext = true,load = true, loadstring = true, math = true, newproxy = true, next = true, pairs = true, pcall = true, rawequal = true, rawget = true, rawlen = true, rawset = true, select = true, setfenv = true, setmetatable = true, string = true, table = true, tonumber = true, tostring = true, type = true, unpack = true, xpcall = true, turtle = true, pocket = true, commands = true, _G = true}
local t = {}
for k in pairs(_G) do if not keptAPIs[k] then table.insert(t, k) end end
for _,k in ipairs(t) do _G[k] = nil end
local native = _G.term.native()
for _, method in ipairs {"nativePaletteColor", "nativePaletteColour", "screenshot"} do native[method] = _G.term[method] end
_G.term = native
_G.http.checkURL = _G.http.checkURLAsync
_G.http.websocket = _G.http.websocketAsync
if _G.commands then _G.commands = _G.commands.native end
if _G.turtle then _G.turtle.native, _G.turtle.craft = nil end
local delete = {os = {"version", "pullEventRaw", "pullEvent", "run", "loadAPI", "unloadAPI", "sleep"}, http = {"get", "post", "put", "delete", "patch", "options", "head", "trace", "listen", "checkURLAsync", "websocketAsync"}, fs = {"complete", "isDriveRoot"}}
for k,v in pairs(delete) do for _,a in ipairs(v) do _G[k][a] = nil end end
_G._HOST = _G._HOST .. " (UnBIOS)"
_G.HardWare = os
-- Set up TLCO
-- This functions by crashing `rednet.run` by removing `os.pullEventRaw`. Normally
-- this would cause `parallel` to throw an error, but we replace `error` with an
-- empty placeholder to let it continue and return without throwing. This results
-- in the `pcall` returning successfully, preventing the error-displaying code
-- from running - essentially making it so that `os.shutdown` is called immediately
-- after the new BIOS exits.

-- From there, the setup code is placed in `term.native` since it's the first
-- thing called after `parallel` exits. This loads the new BIOS and prepares it
-- for execution. Finally, it overwrites `os.shutdown` with the new function to
-- allow it to be the last function called in the original BIOS, and returns.
-- From there execution continues, calling the `term.redirect` dummy, skipping
-- over the error-handling code (since `pcall` returned ok), and calling
-- `os.shutdown()`. The real `os.shutdown` is re-added, and the new BIOS is tail
-- called, which effectively makes it run as the main chunk.
local olderror = error
_G.error = function() end
_G.term.redirect = function() end
function _G.term.native()
    _G.term.native = nil
    _G.term.redirect = nil
    _G.error = olderror
    term.setBackgroundColor(32768)
    term.setTextColor(1)
    term.setCursorPos(1, 1)
    term.setCursorBlink(true)
    term.clear()
    local file = fs.open("/bios/bios.lua", "r")
    if not file then
        term.setCursorBlink(false)
        term.setTextColor(16384)
        term.write("Could not find /bios/bios.lua. UnBIOS cannot continue.")
        term.setCursorPos(1, 2)
        term.write("Press any key to continue")
        local data = fs.exists(".settings") and fm.readFile(".settings") or {}
        if not data
        then
            ---@diagnostic disable-next-line: cast-local-type
            data = {}
        end
        data.customBoot = false
        fm.OverWrite(".settings",data)
        coroutine.yield("key")
        os.shutdown()
    end
    local Env = setmetatable({},{__index = _G})
    local load = load
    if tonumber(string.sub(_VERSION,4)) <= 5.1
    then
        ---@diagnostic disable-next-line: cast-local-type
        load = loadstring
        Env._ENV = Env
        Env._G = _G
    end
    ---@diagnostic disable-next-line: need-check-nil
    local bios, err = load(file.readAll(), "@bios",nil,Env)
    file.close()
    if bios == nil then
        term.setCursorBlink(false)
        term.setTextColor(16384)
        term.write("Could not load /bios/bios.lua. UnBIOS cannot continue.")
        term.setCursorPos(1, 2)
        term.write(err)
        term.setCursorPos(1, 3)
        term.write("Press any key to continue")
        local data = fs.exists(".settings") and fm.readFile(".settings") or {}
        data.customBoot = false
        fm.OverWrite(".settings",data)
        coroutine.yield("key")
        os.shutdown()
    end
    if tonumber(string.sub(_VERSION,4)) <= 5.1
    then
        setfenv(fn,Env)
    end
    local reboot = os.reboot
    local oldshutdown = os.shutdown
    os.shutdown = function()
        local info = fs.exists(".settings") and fm.readFile(".settings") or {}
        os.shutdown = oldshutdown
        ---@diagnostic disable-next-line: param-type-mismatch
        local bool,message = pcall(bios)
        if not bool and info.bios_update and fs.exists("restore_point.old_bios")
        then
            local restore_data = fm.readFile("restore_point.old_bios")
            for _,v in pairs(restore_data) do
                fm.OverWrite(v.path,v.fn,"r")
            end
        elseif not bool
        then
            term.setTextColor(16384)
            term.write(message)
            local config = fm.readFile(".settings")
            config.customBoot = false
            fm.OverWrite(".settings",config)
            coroutine.yield("key")
            reboot()
            while true do
                coroutine.yield()
            end
        end
    end
end
-- Restore functions that were overwritten in the BIOS
-- Apparently this has to be done *after* redefining term.native
local function restoreValue(tab, idx, name, hint)
    local i, key, value = 1, debug.getupvalue(tab[idx], hint)
    while key ~= name and key ~= nil do
        key, value = debug.getupvalue(tab[idx], i)
        i=i+1
    end
    tab[idx] = value or tab[idx]
end
restoreValue(_G, "loadstring", "nativeloadstring", 1)
restoreValue(_G, "load", "nativeload", 5)
restoreValue(http, "request", "nativeHTTPRequest", 3)
restoreValue(os, "shutdown", "nativeShutdown", 1)
restoreValue(os, "reboot", "nativeReboot", 1)
if turtle then
    restoreValue(turtle, "equipLeft", "v", 1)
    restoreValue(turtle, "equipRight", "v", 1)
end
do
    local i, key, value = 1, debug.getupvalue(peripheral.isPresent, 2)
    while key ~= "native" and key ~= nil do
        key, value = debug.getupvalue(peripheral.isPresent, i)
        i=i+1
    end
    _G.peripheral = value or peripheral
end
coroutine.yield()
