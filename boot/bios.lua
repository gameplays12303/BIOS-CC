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
        local file,mess = fs.open("boot/modules/expect2.lua","r")
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
        if not debug then error("could not get environment", 2) end
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
        local file,mess = fs.open("boot/modules/utilities.lua","r")
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
        fn,mess = loadstring(data,"@utilities")
        if fn
        then
            setfenv(fn,_Env)
        end
    else
        fn,mess = load(data,"@utilities","bt",_Env)
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
    util = result[2] or require and require("modules.utilities")
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
                            env._ENV = env
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
                            env._ENV = env
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
    _ENV.loadfile = function (sPath,mode,_Env)
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
                logFile:Warn(("failed_to_open:%s:reason:%s"):format(sPath,mess))
                return false,mess
            end
            chunk = file.readAll()
            file.close()
        end
        if _Env
        then
            _Env.loadfile = loadfile
            _Env.dofile = dofile
            _Env.hardWare = hardWare
            _Env.BIOS = BIOS
        end
        if not chunk
        then
            if logFile
            then
                logFile:warn(("%s:no data"):format(sPath))
            end
            return false,("%s:no data"):format(sPath)
        end
        if not string.find(sPath,"^@") then
            sPath = "@" .. sPath
        end
        fn,mess = BIOS.load(chunk,sPath,mode,_Env)
        if not fn and logFile
        then
            logFile:Warn(("%s:file_failed_to_load:%s"):format(sPath,mess))
        end
        return fn or false,mess
    end
    ---runs a file
    ---@param sPath string
    ---@param _Env table|nil
    ---@diagnostic disable-next-line: duplicate-set-field
    _ENV.dofile = function (sPath,_Env)
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
        local fn,mess = loadfile(sPath,"bt",_Env or setmetatable({},{__index = _G}))
        if not fn
        then
            error(mess,3)
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        local result = table.pack(pcall(fn))
        if not result[1]
        then
            if logFile then
                logFile:Error(result[2])
            end
            error(result[2],0)
        end
        return table.unpack(result,2)
    end
    BIOS.dofile = dofile
    BIOS.loadfile = loadfile
end



BIOS.pullEventRaw = coroutine.yield
---reincludes the terminate function
---@param sfilter string|nil
BIOS.pullEvent = function (sfilter)
    expect(false,1,sfilter,"string","nil")
    local results = table.pack(coroutine.yield(sfilter))
    if results[1] == "Terminate"
    then
        error("terminated",0)
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
    local os = util.table.copy(hardWare)
    for i,v in pairs(BIOS) do
        os[i] = v
    end
    original = setmetatable({coroutine = coroutine,dofile = dofile,loadfile = loadfile,load = BIOS.load,loadstring = BIOS.loadstring,getmetatable = getmetatable, setmetatable = setmetatable,os = os,BIOS = BIOS,hardWare = hardWare},{__index = _G,__disabledGetMeta = true,access = {util}})
end

---time to build the api loader we put it into os for backwards capablity reasons 
--- once all apis are loaded it is destoryed
---@param sPath string
---@diagnostic disable-next-line: duplicate-set-field
function BIOS.loadAPI(sPath)
    expect(false,1,sPath,"string")
    sPath = util.file.withoutExtension(sPath)..".lua"
    if logFile
    then
        local info = getNearestValidFile()
        if info 
        then
            logFile:Info(("api load request: %s : %s "):format((info.source and info.source ~= "=[C]" and info.source) or info.name or info.namewhat ,sPath))
        else
            logFile:Info(("api load request: %s"):format(sPath))
        end
    end
    local _tEnv = util.table.copy(original,true)
    local mess
    local fn
    fn,mess = loadfile(sPath,"bt",_tEnv)
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
    local name = util.file.withoutExtension(fs.getName(sPath))
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
        if not util.table.find(original,v)
        then
            _G[name][i] = v
        end
    end
    if logFile
    then
        logFile:Info(("successfully loaded %s:API"):format(sPath))
    end
end

dofile("boot/apis/db_Protect.lua") -- run this because the debug libary is a exists
dofile("boot/apis/Tbl_protect.lua") -- loads up table protect system

_ENV.mRequire = dofile("boot/modules/mRequire.lua",_ENV)
if mRequire
then
    mRequire.Path.Add("boot")
    mRequire.Path.Add("boot/modules")
    ---@class function
    _ENV.require = require or mRequire.require
end

do -- loads the logging system
    local log_system = require and require("boot/modules/logs.lua",_ENV) or dofile("boot/modules/logs.lua",_ENV)
    local Dir = log_system:Directory("boot/bios_logs",4)
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
        if not logFile:isClosed()
        then
            logFile:Error(mess)
        end
        return nativeError(sMessage,nlevel)
    end
end

logFile:Info("loading apis")
BIOS.loadAPI("rom/apis/colors")
_G.colors = table.setReadOnly(colors)
BIOS.loadAPI("rom/apis/keys")
BIOS.loadAPI("rom/apis/parallel")
logFile:Info("all apis loaded")




_ENV.GUI  = require("modules.GUI.GUI",_ENV)
GUI:setBackgroundColor(colors.black)
local fm = require("modules.fm",_ENV)
local bugCheck
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
    bugCheck = function (sMessage,nlevel)
        expect(false,1,sMessage,"string")
        expect(false,2,nlevel,"number","nil")
        if nlevel and nlevel ~= 0
        then
            nlevel = nlevel + 2
        elseif nlevel == nil
        then
            nlevel = 3
        end
        local mess = select(2,pcall(nativeError,sMessage,nlevel))
        if nativeError == _G.error
        then
            logFile:Fatal(mess)
            logFile:Close()
        end
        local bounds = ("="):rep(SizeX).."\n"
        ErrorScreen:write(bounds)
        ErrorScreen:write(mess.."\n")
        ErrorScreen:write(bounds)
        ErrorScreen:write("press key to reboot")
        coroutine.yield("key")
        reboot()
        while true do
            coroutine.yield()
        end
    end
end
mRequire.setErrorHandler(bugCheck)
local fileselect = require("modules.GUI.fileselect")

_ENV.bugCheck = bugCheck
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
    local image = GUI.loadImage("boot/icon.nfp")
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
        logMessage(("OS not installed;%s"):format(fs.getName(config.default_OS)))
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

--- time to load the configuration if their is one
local program,mess
if not default_OS
then
    program,mess = loadfile("boot/menu.lua","bt",_ENV)
    if not program
    then
        ---@diagnostic disable-next-line: param-type-mismatch
        error(mess,0)
    end
else
    local key = {
        [keys.f5] = function ()
            local file
            file,mess = loadfile("boot/menu.lua","bt",setmetatable({require = require,BIOS = BIOS,GUI = GUI},{__index = _G}))
            if not file
            then
                ---@diagnostic disable-next-line: param-type-mismatch
                bugCheck(mess,0)
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            local result = table.pack(pcall(file))
            if not result
            then
                bugCheck(result[2],0)
            end
            return result[2]
        end,
        [keys.f6] = function ()
            local fileParent = GUI:create(1,1,GUI:getSize())
            fileParent:upDate(true)
            local option = fileselect(fileParent,"","choose OS",true,false,"kern")
            default_OS = option or default_OS
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
        bugCheck(reboot,0)
    end
    if reboot
    then
        hardWare.reboot()
        while true do
            coroutine.yield()
        end
    end
end

dofile("boot/apis/BiosFile_protect.lua",_ENV)
-- loads up the choosen OS (will shutdown if the OS fails to load)
local kernel_environment = setmetatable({BIOS = BIOS,hardWare = hardWare,error = nativeError},{__index = _G})
local kernel_fn
kernel_fn,mess = loadfile(default_OS,"bt",kernel_environment)
if kernel_fn == false or kernel_fn == nil
then
    bugCheck("kernelError:"..mess,0)
end
_G.error = nativeError
---@diagnostic disable-next-line: param-type-mismatch
local bool,err = pcall(kernel_fn)
if not bool
then
    if kernel_environment.PANIC
    then
        bool = pcall(kernel_environment.PANIC,err or "unknown fault system Crash")
        if bool 
        then
            hardWare.shutdown()
            coroutine.yield(".............................................................................")
        end
    end
    bugCheck(err or "unknown fault system Crash",0)
end
logFile:close()
hardWare.shutdown()
coroutine.yield("............................................................................................")