--[[
    because the expect module is a API we will have to load it up 
    we will have to load it up mannualy

    we will load up the other apis latter using  bios.loadAPI but that isn't declared yet
]]
local getmetatable,setmetatable = getmetatable,setmetatable
local expect,util

do -- loads up the expect api

    local _Env = setmetatable({getmetatable = getmetatable,setmetatable = setmetatable},{__index = _ENV})
    local data
    do -- opens the file
        local file,mess = fs.open("bios/modules/expect2.lua","r")
        if not file
        then
            error(mess,0)
        end
        data = file.readAll()
        file.close()
    end
    local fn,mess
    if tonumber(string.sub(_VERSION,4)) <=5.1
    then
        fn,mess = loadstring(data,"@expect2")
        if fn
        then
            setfenv(fn,_Env)
        end
    else
        fn,mess = load(data,"@expect2","bt",_Env)
    end
    if not fn
    then
        error(mess,0)
    end
    local result = table.pack(pcall(fn))
    if not result[1]
    then
        error(result[2],0)
    end
    expect = result[2] or require and require("modules.expect2")
end

if not setfenv then
    -- setfenv/getfenv replacements from https://leafo.net/guides/setfenv-in-lua52-and-above.html
    ---@diagnostic disable-next-line: duplicate-set-field
    function _G.setfenv(fn, env)
        if not debug then error("could not set environment", 2) end
        if type(fn) == "number" then fn = debug.getinfo(fn + 1, "f").func end
        local i = 1
        while true do
            local name = debug.getupvalue(fn, i)
            if name == "_ENV" then
                debug.upvaluejoin(fn, i, (function()
                    return env
                end), 1)
                break
            elseif not name then
                break
            end

            i = i + 1
        end

        return fn
    end
end
if not getfenv then
    ---@diagnostic disable-next-line: duplicate-set-field
    function _G.getfenv(fn)
        if not debug then error("could not set environment", 2) end
        if type(fn) == "number" then fn = debug.getinfo(fn + 1, "f").func end
        local i = 1
        while true do
            local name, val = debug.getupvalue(fn, i)
            if name == "_ENV" then
                return val
            elseif not name then
                break
            end
            i = i + 1
        end
    end
end

do -- loads up the utilties api
    local _Env = setmetatable({getmetatable = getmetatable,setmetatable = setmetatable,expect = expect},{__index = _ENV})
    local data
    do -- opens the file
        local file,mess = fs.open("bios/modules/utilties.lua","r")
        if not file
        then
            error(mess,0)
        end
        data = file.readAll()
        file.close()
    end
    local fn,mess
    if tonumber(string.sub(_VERSION,4)) <=5.1
    then
        fn,mess = loadstring(data,"@utilties")
        if fn
        then
            setfenv(fn,_Env)
        end
    else
        fn,mess = load(data,"@utilties","bt",_Env)
    end
    if not fn
    then
        error(mess,0)
    end
    local result = table.pack(pcall(fn))
    if not result[1]
    then
        error(result[2],0)
    end
    util = result[2] or require and require("modules.utilties")
end
expect = expect.expect
---@class table
_ENV.BIOS = {}
_ENV.hardWare = os
hardWare.getmetatable = getmetatable
hardWare.setmetatable = setmetatable

_G.os = nil

local function getNearestValidFile()
    local level = 3
    while true do
        local info = debug.getinfo(level, "S") -- Get source info (file name)
        if not info then
            break
        end
        -- Check if the source is a file path (starts with '@' or not)
        local source = info.short_src
        if source then
            -- Check if the file exists on the filesystem using fs.exists
            if fs.exists(source) then
                return info -- Return the debug info of the nearest valid file
            end
        end
        level = level + 1
    end
    return debug.getinfo(4)
end


hardWare.load = load
hardWare.loadstring = loadstring
_G.load = nil
_G.loadstring = nil
do -- sets up required basic functions 
    local native_getmetatable = getmetatable
    function BIOS.makeEnv(env)
        env._ENV = env
        local meta = native_getmetatable(env) or {}
        env._G = meta.__index
    end
    if tonumber(string.sub(_VERSION,4)) <= 5.1
    then
        ---@diagnostic disable-next-line: duplicate-set-field
        function BIOS.load(x, name, mode, env)
            expect(false,1, x, "function", "string")
            expect(false,2, name, "string", "nil")
            expect(false,3, mode, "string", "nil")
            expect(false,4, env, "table", "nil")
            local ok, p1, p2 = pcall(function()
                if type(x) == "string" then
                    local result, err = hardWare.loadstring(x, name)
                    if result then
                        if env then
                            BIOS.makeEnv(env)
                            setfenv(result,env)
                        end
                        return result
                    else
                        return nil, err
                    end
                else
                    local result, err = hardWare.load(x, name)
                    if result then
                        if env then
                            BIOS.makeEnv(env)
                            setfenv(result,env)
                        end
                        return result
                    else
                        return nil, err
                    end
                end
            end)
            if ok then
                return p1, p2
            else
                error(p1, 2)
            end

        end
        BIOS.loadstring = hardWare.loadstring
    else
        ---@diagnostic disable-next-line: duplicate-set-field
        BIOS.loadstring = function(string, chunkname) return HardWare.load(string, chunkname) end
        BIOS.load = hardWare.load
        -- setfenv/getfenv replacements from https://leafo.net/guides/setfenv-in-lua52-and-above.html
        ---@diagnostic disable-next-line: duplicate-set-field
        function _G.setfenv(fn, env)
            if not debug then error("could not set environment", 2) end
            if type(fn) == "number" then fn = debug.getinfo(fn + 1, "f").func end
            local i = 1
            while true do
                local name = debug.getupvalue(fn, i)
                if name == "_ENV" then
                    debug.upvaluejoin(fn, i, (function()
                        return env
                    end), 1)
                    break
                elseif not name then
                    break
                end

                i = i + 1
            end

            return fn
        end
        ---@diagnostic disable-next-line: duplicate-set-field
        function _G.getfenv(fn)
            if not debug then error("could not set environment", 2) end
            if type(fn) == "number" then fn = debug.getinfo(fn + 1, "f").func end
            local i = 1
            while true do
                local name, val = debug.getupvalue(fn, i)
                if name == "_ENV" then
                    return val
                elseif not name then
                    break
                end
                i = i + 1
            end
        end
    end
    _G.bit = {
        bnot = bit32.bnot,
        band = bit32.band,
        bor = bit32.bor,
        bxor = bit32.bxor,
        brshift = bit32.arshift,
        blshift = bit32.lshift,
        blogic_rshift = bit32.rshift,
    }
    ---loads a lua file , returns false it fails to load
    ---@param sPath string
    ---@param mode string|nil
    ---@param _Env table|nil
    ---@return function|boolean
    ---@return string|nil
    ---@diagnostic disable-next-line: duplicate-set-field
    BIOS.loadfile = function (sPath,mode,_Env)
        expect(false,1,sPath,"string")
        expect(false,2,mode,"string")
        expect(false,3,_Env,"table","nil")
        if logFile
        then
            local info = debug.getinfo(2)
            if info
            then
                logFile:Info(("loadfile request: %s: %s"):format((info.source and info.source ~= "=[C]" and info.source) or info.name or info.namewhat ,sPath))
            end
        end
        local chunk,fn,mess
        do -- reads the file
            local file
            file,mess = fs.open(sPath,"r")
            if not file
            then
                return false,mess
            end
            chunk = file.readAll()
            file.close()
        end
        if _Env
        then
            _Env.loadfile = BIOS.loadfile
            _Env.dofile = BIOS.dofile
            _Env.hardWare = hardWare
            _Env.BIOS = BIOS
        end
        fn,mess = BIOS.load(chunk,sPath,mode,_Env)
        return fn or false,mess
    end
    ---runs a file
    ---@param sPath string
    ---@param _Env table|nil
    BIOS.dofile = function (sPath,_Env)
        expect(false,1,sPath,"string")
        expect(false,2,_Env,"table","nil")
        if logFile
        then
            local info = debug.getinfo(2)
            if info
            then
                logFile:Info(("exe request: %s: %s"):format((info.source and info.source ~= "=[C]" and info.source) or info.name or info.namewhat ,sPath))
            end
        end
        local fn,mess = BIOS.loadfile(sPath,"bt",_Env or setmetatable({},{__index = _G}))
        if not fn
        then
            error(mess,3)
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        local result = table.pack(pcall(fn))
        if not result[1]
        then
            error(result[2],0)
        end
        return table.unpack(result,2)
    end
end



BIOS.pullEventRaw = coroutine.yield
---reincludes the terminate function
---@param sfilter string|nil
BIOS.pullEvent = function (sfilter)
    expect(false,1,sfilter,"string","nil")
    local results = table.pack(coroutine.yield(sfilter))
    if results[1] == "Terminate"
    then
        _G.error("terminated",0)
    end
    return table.unpack(results)
end

BIOS.sleep = function (t)
    expect(false,1,t,"number")
    local ID = hardWare.startTimer(t)
    while true do
        local event = select(2,BIOS.pullEventRaw("timer"))
        if event == ID
        then
            break
        end
    end
end
local original
do-- makes the loadapi Envirement blueprint table
    local os = util.Table.copy(hardWare)
    for i,v in pairs(BIOS) do
        os[i] = v
    end
    original = setmetatable({coroutine = coroutine,dofile = BIOS.dofile,loadfile = BIOS.loadfile,load = BIOS.load,loadstring = BIOS.loadstring,getmetatable = getmetatable, setmetatable = setmetatable,os = os,BIOS = BIOS,hardWare = hardWare},{__index = _G,__disabledGetMeta = true,access = {util}})
end

---time to build the api loader we put it into os for backwards capablity reasons 
--- once all apis are loaded it is destoryed
---@param sPath string
---@diagnostic disable-next-line: duplicate-set-field
function BIOS.loadAPI(sPath)
    expect(false,1,sPath,"string")
    sPath = util.File.withoutExtension(sPath)..".lua"
    if logFile
    then
        local info = getNearestValidFile()
        logFile:Info(("api load request: %s : %s "):format((info.source and info.source ~= "=[C]" and info.source) or info.name or info.namewhat ,sPath))
    end
    local _tEnv = util.Table.copy(original,true)
    local mess
    local fn
    fn,mess = BIOS.loadfile(sPath,"bt",_tEnv)
    if not fn
    then
        if logFile
        then
            logFile:Error(("failed to load API:[%s]:%s"):format(sPath,mess))
        end
        return false,mess
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    local result =  table.pack(pcall(fn))
    if not result[1]
    then
        if logFile
        then
            logFile:Error(result[2])
        end
        return false,result[2]
    end
    local name = util.File.withoutExtension(fs.getName(sPath))
    _G[name] = {}
    if result[2] and type(result[2]) == "table"
    then
        setmetatable(_G[name],result[2])
    elseif result[2] and type(result[2]) ~= "table"
    then
        mess = ("API returned %s expected table or nil; used for setting the meta_data"):format(type(result[2]))
        logFile:Error(mess)
        return false,mess
    end
    for i,v in pairs(_tEnv) do
        if not util.Table.find(original,v)
        then
            _G[name][i] = v
        end
    end
    if logFile
    then
        logFile:Info(("successfully loaded %s:API"):format(sPath))
    end
end

if debug
then
    BIOS.dofile("bios/apis/db_Protect.lua") -- run this because the debug libary is a exists
end
BIOS.dofile("bios/apis/Tbl_protect.lua") -- loads up table protect system

_ENV.mRequire = BIOS.dofile("bios/modules/mRequire.lua")
if mRequire
then
    mRequire.Path.Add("bios")
    mRequire.Path.Add("bios/modules")
    ---@class function
    _ENV.require = require or mRequire.require
end

do -- loads the logging system
    local log_system = require and  require("bios/modules/logs.lua",_ENV) or BIOS.dofile("bios/modules/logs.lua",_ENV)
    local Dir = log_system:Open_Dir("bios/bios_logs",4)
    _ENV.logFile = Dir:Open_Log("bios")
end
logFile:Info("starting logging")
local nativeError = _G.error
do -- wraps the _Env Errorhandler (this will one will not only draw it to the screen but log it)
    ---@param sMessage string
    ---@param nlevel number|nil
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.error = function (sMessage,nlevel)
        expect(false,1,sMessage,"string")
        expect(false,2,nlevel,"number","nil")
        if nlevel and nlevel ~= 0
        then
            nlevel = nlevel + 1
        elseif nlevel == nil
        then
            nlevel = 3
        end
        local mess = select(2,pcall(nativeError,sMessage,nlevel))
        logFile:Fatal(mess)
        nativeError(sMessage,nlevel)
    end
end


logFile:Info("loading color api and GUI")
BIOS.loadAPI("rom/apis/colors")
_ENV.GUI  = require("GUI.GUI",_ENV)
local fileselect = require("GUI.fileselect")
GUI:setBackgroundColor(colors.black)

local fm = require("fm",_ENV)

do -- wraps the _Env Errorhandler (this will one will not only draw it to the screen but log it)
    ---@type function
    local reboot = hardWare.reboot
    local ErrorScreen = GUI:create(1,1,GUI:getSize())
    ErrorScreen:upDate(true)
    ErrorScreen:make_textBox(true)
    local SizeX = GUI:getSize()
    ---@param sMessage string
    ---@param nlevel number|nil
    ---@diagnostic disable-next-line: duplicate-set-field
    _ENV.error = function (sMessage,nlevel)
        expect(false,1,sMessage,"string")
        expect(false,2,nlevel,"number","nil")
        if nlevel and nlevel ~= 0
        then
            nlevel = nlevel + 1
        elseif nlevel == nil
        then
            nlevel = 3
        end
        local mess = select(2,pcall(nativeError,sMessage,nlevel))
        if nativeError == _G.error
        then
            logFile:Fatal(mess)
        end
        local bounds = ("="):rep(SizeX).."\n"
        ErrorScreen:write(bounds)
        ErrorScreen:write(mess.."\n")
        ErrorScreen:write(bounds)
        ErrorScreen:write("press key to reboot")
        coroutine.yield("key")
        reboot()
    end
end


local messageScreen
do -- builds a message screen
    local _,termSizeY = GUI:getSize()
    local centerX = GUI:getCenter()
    if centerX > 20
    then
        messageScreen = GUI:create(centerX-20,termSizeY-1,centerX+10,1,true)
        messageScreen:redraw()
        messageScreen:make_textBox()
        messageScreen:setTextColor(colors.black)
    else
        logFile:Warn("failed to build the messageScreen")
    end
end

if messageScreen
then
    _ENV.logMessage = function (message)
        expect(false,1,message,"string")
        messageScreen:clear()
        messageScreen:setCursorPos()
        if string.find(message,"%c")
        then
            logFile:Warn(("%s:tried to use control-chars"):format(getNearestValidFile()))
            return false,"control chars not allowed"
        end
        if #message > messageScreen:getSize()
        then
            logFile:Warn(("%s:message too big"):format(getNearestValidFile()))
            return false,"message too big"
        end
        messageScreen:write(message)
        BIOS.sleep(2) -- don't like it but no other way
        return true
    end
else
    _ENV.logMessage = function (message) -- 
        expect(false,1,message,"string")
        logFile:Warn("messageScreen_Missing: "..message)
    end
end

logFile:Info("loading icon")
do -- draws a icon to the screen -- incase loading takes longer then normal
    local centerX,centerY = GUI:getCenter()
    local image = GUI.loadImage("bios/icon.nfp")
    local length,depth = image.Size.x,image.Size.y
    local SizeX,SizY = GUI:getSize()
    if image.Size.x <= SizeX and image.Size.y < SizY+1
    then
        local paintWindow = GUI:create(centerX-(length/2),centerY-(depth/2),length,depth,true)
        paintWindow:makeCanv()
        paintWindow:setBackgroundColor(colors.black)
        paintWindow:drawImage(image,1,1)
        logFile:Info("icon loaded")
    else
        logFile:Warn("icon not loaded")
    end
end

--- time to load up the configuration
local default_OS
local config
if fs.exists(".settings")
then
    local mess
    ---@class table
    config,mess = fm.readFile(".settings","S")
    if not config
    then
        logMessage("missing config data entering boot menu")
        logFile:Warn((mess or "noData").."; entering menu; expected behavior if first time boot")
    elseif config.default_OS == nil
    then
        logMessage("no Os selected")
        logFile:Warn("no Os selected; entering menu")
    elseif not fs.exists(config.default_OS)
    then
        logMessage("OS not installed")
        logFile:Warn(("%s:not installed; entering boot_menu"):format(config.default_OS))
    else
        ---@type string
        ---@diagnostic disable-next-line: cast-local-type
        default_OS = config.default_OS
    end
else
    logMessage("missing config file")
    logFile:Warn(".setting file missing entering first time boot; expected behavior if first time boot")
end


-- time to load up some old but critical CraftOS apis
logFile:Info("loading remaining apis")
BIOS.loadAPI("rom/apis/parallel")
if fs.exists("rom/apis/fs.lua")
then
    BIOS.loadAPI("rom/apis/fs")
end
BIOS.loadAPI("rom/apis/keys")

--- time to load the configuration if their is one
local program,mess
if not default_OS
then
    program,mess = BIOS.loadfile("bios/menu.lua","bt",_ENV)
    if not program
    then
        ---@diagnostic disable-next-line: param-type-mismatch
        error(mess,0)
    end
else
    local key = {
        [keys.f5] = function ()
            local file
            file,mess = BIOS.loadfile("bios/menu.lua","bt",_ENV)
            if not file
            then
                ---@diagnostic disable-next-line: param-type-mismatch
                error(mess,0)
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            local result = table.pack(pcall(file))
            if not result
            then
                error(result[2],0)
            end
            return result[2]
        end,
        [keys.f6] = function ()
            local fileParent = GUI:create(1,1,GUI:getSize())
            fileParent:upDate(true)
            local option = fileselect(fileParent,"","choose OS",true,false,"boot_record")
            default_OS = option
        end
    }
    parallel.waitForAny(function ()
        local Id = hardWare.startTimer(config.bios_timer or 5)
        while true do
            local time = select(2,BIOS.pullEventRaw("timer"))
            if time == Id
            then
                break
            end
        end
    end,function ()
        local sel
        while not program do
            sel = select(2,BIOS.pullEventRaw("key"))
            program = key[sel]
        end
        logFile:Info(("running %d"):format(sel))
    end)
end
if type(program) == "function"
then
    if config.pin and messageScreen
    then
        while true do
            messageScreen:clear()
            local pin = tonumber(messageScreen:Chat_Prompt("pin>"))
            if pin ~= config.pin
            then
                messageScreen:clear()
                messageScreen:write("wrong pin")
                BIOS.pullEvent("key")
            else
                messageScreen:clear()
                break
            end
        end
    end
    local bool,reboot = pcall(program)
    if not bool
    then
        error(reboot,0)
    end
    if reboot
    then
        hardWare.reboot()
        while true do
            coroutine.yield()
        end
    end
end


_G.error = nativeError
BIOS.dofile("bios/apis/BiosFile_protect.lua",_ENV)

-- loads up the choosen OS (will shutdown if the OS fails to load)
local kernel_environment,kernel_error,kernel_location
do -- sets up kernel_environment
    local OSConfig = fm.readFile(default_OS)
    kernel_environment = OSConfig.kernel_environment
    if not kernel_environment
    then
        error("missing kernel_environment",0)
    end
    setmetatable(kernel_environment,{__index = _G})
    kernel_environment.BIOS = BIOS
    kernel_environment.hardWare = hardWare
    kernel_error = OSConfig.kernel_error
    kernel_location = OSConfig.kernel
end

local kernel_error_fn,kernel_fn
if kernel_error
then
    kernel_error_fn,mess = BIOS.loadfile(kernel_error,"bt",kernel_environment)
    if not kernel_error_fn
    then
        logFile:Warn(mess)
    else
        kernel_environment.error = kernel_error_fn
    end
end
if not kernel_location
then
    error(("no kernel location %s"):format(default_OS),0)
end
kernel_fn,mess = BIOS.loadfile(kernel_location,"bt",kernel_environment)
if kernel_fn == false or kernel_fn == nil
then
    logFile:Fatal("kernel:"..mess)
    if kernel_error_fn
    then
        kernel_error_fn(mess,1)
    else
        ---@diagnostic disable-next-line: param-type-mismatch
        error(mess,2)
    end
end
kernel_error = nil
kernel_location = nil
default_OS = nil
config = nil
---@diagnostic disable-next-line: param-type-mismatch
local results = table.pack(pcall(kernel_fn))
if not results[1]
then
    error(results[2],0)
end
logFile:close()
hardWare.shutdown()
coroutine.yield("....")