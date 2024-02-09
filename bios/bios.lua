local expect,expectfn
do
    local h = fs.open("bios/modules/expect2.lua", "r")
    local f, err = (_VERSION == "Lua 5.1" and loadstring or load)(h.readAll(), "@bios/modules/expect2.lua")
    h.close()
    if not f then error(err) end
    expect = require and require("modules.expect2") or f()
end
local blacklist = expect.blacklist
local expectValue = expect.expectValue
local field = expect.field
expect = expect.expect
---@diagnostic disable-next-line: undefined-global
if tonumber(string.sub(_VERSION,4,#_VERSION)) > 5.2 or _CC_DISABLE_LUA51_FEATURES
then
    function setfenv(fn, env)
        if not debug then error("could not set environment", 2) end
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

    function getfenv(fn)
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
    ---@diagnostic disable-next-line: duplicate-set-field
    function table.maxn(tab)
        local num = 0
        for k in pairs(tab) do
            if type(k) == "number" and k > num then
                num = k
            end
        end
        return num
    end
    -- Historically load/loadstring would handle the chunk name as if it has
    -- been prefixed with "=". We emulate that behaviour here.
    local function prefix(chunkname)
        if type(chunkname) ~= "string" then return chunkname end
        local head = chunkname:sub(1, 1)
        if head == "=" or head == "@" then
            return chunkname
        else
            return "=" .. chunkname
        end
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    math.log10 = function(x) return math.log(x, 10) end
    loadstring = function(string, chunkname) return load(string, prefix(chunkname)) end
    unpack = table.unpack

    -- Inject a stub for the old bit library
    _G.bit = {
        bnot = bit32.bnot,
        band = bit32.band,
        bor = bit32.bor,
        bxor = bit32.bxor,
        brshift = bit32.arshift,
        blshift = bit32.lshift,
        blogic_rshift = bit32.rshift,
    }
end
local native_getmeta = getmetatable
function loadfile(filename,mode,_Env)
    -- Support the previous `loadfile(filename, _Env)` form instead.
    if type(mode) == "table" and _Env == nil then
        mode, _Env = nil, mode
    end
    expect(false,1, filename, "string")
    expect(false,2, mode, "string", "nil")
    if _Env ~= _ENV and _Env ~= _G and not (native_getmeta(_Env) or {})._G
    then
        _Env._ENV = _Env
    end
    _Env = expect(false,3, _Env, "table", "nil") or setmetatable({},{__index = _G})
    local file = fs.open(filename, "r")
    if not file then return ("%s:not found"):format(filename) end
    local _data = file.readAll()
    file.close()
    local fn,err
    if type(_data) == "string"
    then
        fn,err = loadstring(_data,("@%s"):format(filename))
        if not fn then return nil,err end
        setfenv(fn,_Env)
    elseif tonumber(string.sub(_VERSION,4,#_VERSION)) <= 5.2
    then
        fn,err = load(_data,("@%s"):format(filename))
        if not fn then return nil,err end
        setfenv(fn,_Env)
    else
        fn,err = load(_data,("@/%s"):format(filename),mode,_Env)
    end
    return fn,err
end
function dofile(_sFile,_Env)
    expect(false,1, _sFile, "string")
    expect(false,2,_Env,"table","nil")
    local fnFile = loadfile(_sFile, nil,_Env)
    if type(fnFile) == "function" then
        return fnFile()
    else
        error(fnFile, 2)
    end
end
local mReq = require and require("modules.mRequire") or dofile("bios/modules/mRequire.lua")
mReq.Path.Add("bios")
local require = require or mReq.require
mReq.loaded["modules.expect2"] = expectfn
---@diagnostic disable : redundant-parameter
local util = require("modules.utilties",{fs = require("modules.utilties").table.copy(fs)},true)
--before we load the fm API we need a Serialiser and Unserialiser
do
    function Serialise(_data,_Index)
        blacklist(false,1,_data,"thread","function","userdata")
        _Index =  expect(false,2,_Index,"number","nil") or 0
        local indexGag = ("\t"):rep(_Index)
        local handle = {
            ["boolean"] = function ()
                return tostring(_data)
            end,
            ["string"] = function ()
                return "\"".._data.."\""
            end,
            ["table"] = function ()
                local result = "{\n"
                for i,v in pairs(_data) do
                    if type(v) ~= "table" or not util.table.selfReferencing(v)
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
        }
        handle["number"] = handle["boolean"]
        return handle[type(_data)]()
    end
    function Unserialise(_sData)
        expect(false,1, _sData, "string")
        local func,err = load("return " .. _sData, "unserialize","t",{})
        if func then
            local ok, result = pcall(func)
            if ok then
                return result
            end
        end
        return error(err,2)
    end
end
local fm = require("modules.fm",{fs = util.table.copy(fs)})
local log = require("modules.logs")("bios/logs",5)("bios")
---@diagnostic enable : redundant-parameter
os.pullEventRaw = coroutine.yield
-- time to load the critical APIs
do
    local Dir = "rom/apis"
    local function loadAPI(_sFile,keep,retEnv)
        _sFile = fs.combine(Dir,util.file.withoutExtension(fs.getName(_sFile))..".lua")
        log.info(("loading %s"):format(_sFile))
        local ID = util.file.withoutExtension(fs.getName(_sFile))
        local tEnv = {}
        setmetatable(tEnv,{__index = _G})
        dofile(_sFile,tEnv)
        if retEnv
        then
            return tEnv
        end
        if not keep
        then
            _G[ID] = {}
        end
        for i,v in pairs(tEnv) do
            if i ~= "_ENV"
            then
                _G[ID][i] = v
            end
        end
    end
    loadAPI("keys")
    loadAPI("colors")
    loadAPI("colours")
    loadAPI("parallel")
    loadAPI("fs")
    do
        local tEnv = setmetatable({io = loadAPI("io",nil,true)},{__index = _G})
        dofile(fs.combine(Dir,"paintutils.lua"),tEnv)
        for i,v in pairs(tEnv) do
            if i == "loadImage"
            then
                _G.loadImage = v
            end
        end
    end
    Dir = "bios"
    if debug
    then
        loadAPI("db_Protect")
    end
end
local Parent = require("modules.GUI.GUI")
local originalError = error
do -- time to set up the errorhandler
    error = function (_sMessage,_nlevel)
        expect(false,1,_sMessage,"string")
        expect(false,2,_nlevel,"number","nil")
        if _nlevel and _nlevel ~= 0
        then
            _nlevel = _nlevel + 2
        elseif not _nlevel
        then
            _nlevel = 2
        end
        _sMessage = select(2,pcall(originalError,_sMessage,_nlevel))
        if not log.isClosed()
        then
            log.error(_sMessage)
            log.close()
        else
            _sMessage = _sMessage..": log was closed"
        end
        Parent:setVisible(true)
        Parent:setBackgroundColor(colors.green)
        Parent:redraw()
        Parent:make_textBox()
        local border 
        do
            local x = Parent:getSize()
            border = ("="):rep(x).."\n"
        end
        Parent:setTextColor(colors.white)
        Parent:write(border)
        Parent:write(_sMessage.."\n")
        Parent:write(border)
        coroutine.yield("key")
        os.reboot()
        while true do
            coroutine.yield()
        end
    end
end
if not debug
then
    error("debug lib required",0)
end
local message = Parent:create(1,1,select(1,Parent:getSize()),1,true)
message:make_textBox()
do -- print text to the terminal 
    local firstMessage  = "press f4 or f5 or enter to contiune on 5 sec delay"
    message:setBackgroundColor(colors.black)
    message:setTextColor(colors.white)
    local CenterX = select(1,message:getCenter())
    message:setCursorPos(CenterX-#firstMessage/2,1)
    message:write(firstMessage)
end
---@diagnostic disable-next-line: undefined-field
term.setCursorBlink(false)
term = nil
do -- time to load the image if image fits screen size
    local image = loadImage("bios/icon.nfp")
    if not image
    then
        error("bios/icon.nfp:not found",0)
    end
    local centerX,centerY = Parent:getCenter()
    local ImageHight = #image
    local image_width = 0
    ---@diagnostic disable: param-type-mismatch
    for _,obj_depth in pairs(image) do
        local len = #obj_depth
        image_width = len > image_width and len or image_width
    end
    centerY = centerY-ImageHight/2
    centerX = centerX-image_width/2
    local image_term = Parent:create(centerX,centerY,image_width,ImageHight,true)
    image_term:setBackgroundColor(colors.black)
    for index_depth,obj_depth in pairs(image) do
        for index_width,color in pairs(obj_depth) do
            if color > 0
            then
                image_term:setPixel(color,index_width,index_depth)
            end
        end
    end
    image_term:redraw()
    ---@diagnostic enable: param-type-mismatch
end
-- time to get the known OS list
local settings = fs.exists("bios/bios.settings") and fm.readFile("bios/bios.settings") or {}
local OS_list = settings.list or {}
local selected = 1
local function searchDrives()
    local Root_list = util.file.list("",false,true,true)
    do -- gets the drives
        local index = 1
        while index < #Root_list do
            local obj = Root_list[index]
            if string.sub(obj,1,4) ~= "disk"
            then
                table.remove(Root_list,index+1)
            else
                index = index + 1
            end
        end
    end
    for _,v in pairs(Root_list) do
        local Drive_List = util.file.listsubs(v,true)
        for _,_sfile in pairs(Drive_List) do
            if fs.getName(_sfile) == "kernel.lua" or util.file.getExtension(_sfile) == "OSID"
            then
                table.insert(OS_list,_sfile)
            end
        end
    end
end
do -- time to get Usrinput
    local fn
    parallel.waitForAny(function ()
        local ID = os.startTimer(4)
        while true do
            local event = select(2,os.pullEventRaw("timer"))
            if event == ID
            then
                break
            end
        end
    end,function ()
        local key_Handle = {
            [keys.f4] = function ()
                if true
                then
                    local ParentSizeX,ParentSizeY = Parent:getSize()
                    local up,down
                    local previous,next
                    local option_menu = Parent:create(6,2,ParentSizeX-5,ParentSizeY-6,true)
                    do
                        local button_Virt = Parent:create(1,2,5,ParentSizeY-6,true)
                        local Sizex,SizeY = button_Virt:getSize()
                        up = button_Virt:create(1,1,Sizex,SizeY/2,true)
                        down = button_Virt:create(1,ParentSizeY/2+1,Sizex,SizeY/2-1,true)
                        up:make_button()
                        down:make_button()
                        --------------------------------------------
                    end
                    local button_Hert = Parent:create(6,ParentSizeY-4,ParentSizeX-5,5,true)
                    coroutine.yield("key")
                end
                return true
            end,
            [keys.f5] = function ()
                searchDrives()
                if #OS_list > 1
                then
                    local Menu
                    do
                        local centerX,CenterY = Parent:getCenter()
                        Menu = Parent:create(centerX-5,CenterY-2,10,4,true)
                    end
                    selected = Menu:run_list(OS_list,{message = "choose OS"})
                end
                return false
            end
        }
        while true do
            local event = select(2,os.pullEventRaw("key"))
            if event == keys.enter
            then
                Parent:clear(false)
                break
            elseif key_Handle[event]
            then
                Parent:clear(false)
                fn = key_Handle[event]
            end
        end
    end)
    if fn
    then
        if fn()
        then
            os.reboot()
            while true do
                coroutine.yield()
            end
        end
    else
        searchDrives()
    end
    if #OS_list == 0
    then
        error("no OS installed",0)
    end
end
local function proectTBl(TBL)
    for _,v in pairs(TBL) do
        if type(v) == "function"
        then
            debug.protect(v)
        end
    end
end
local class = require("modules.class")
do -- time to add some new features
    ---@diagnostic disable:redundant-parameter,duplicate-set-field
    local Tbl = util.table.copy(table)
    local metaTable = {getmetatable = getmetatable,setmetatable = setmetatable}
    local nativeRawSet = rawset
    getmetatable = function (Table)
        expect(false,1,Table,"table")
        local meta = metaTable.getmetatable(Table) or {}
        if meta.__disabledGetMeta or meta._isReadOnly
        then
            error("getmetatable is disable for table",2)
        end
        return metaTable.getmetatable(Table)
    end
    setmetatable = function (Table,_metaTable)
        expect(false,1,Table,"table")
        expect(false,2,_metaTable,"table","nil")
        local meta = metaTable.getmetatable(Table) or {}
        if meta.__disabledSetMeta
        then
            error("metaTable is disabled for table",2)
        end
        return metaTable.setmetatable(Table,_metaTable)
    end
    DisabledSetMeta = function (Table)
        expect(false,1,Table,"table")
        local meta = metaTable.getmetatable(Table) or {}
        meta.__disabledSetMeta = true
        metaTable.setmetatable(Table,meta)
    end
    DisabledGetMeta = function (Table)
        expect(false,1,Table,"table")
        local meta = metaTable.getmetatable(Table) or {}
        if meta.__disabledSetMeta or meta.__disabledGetMeta
        then
            error("SetmetaTable is disabled for table",2)
        end
        meta.__disabledGetMeta = true
        return metaTable.setmetatable(Table)
    end
    ---comment
    ---@param Table table
    ---@param index number|string
    ---@param value any
    ---@return table|nil
    rawset = function (Table,index,value)
        expect(false,1,Table,"table")
        expect(false,2,index,"number","string")
        local meta = metaTable.getmetatable(Table)
        if meta._isReadOnly
        then
            error("table is ReadOnly",2)
        end
        return nativeRawSet(Table,index,value)
    end
    table.insert = function (_tlist,_nindex ,value)
        expect(false,1,_tlist,"table")
        if value ~= nil
        then
            expect(false,2,_nindex,"number")
        else
            expectValue(2,_nindex)
            value = _nindex
            _nindex = nil
        end
        local meta = metaTable.getmetatable(_tlist) or {}
        if meta._isReadOnly
        then
            error("table isReadOnly",2)
        end
        if value ~= nil
        then
            Tbl.insert(_tlist,_nindex,value)
        else
            Tbl.insert(_tlist,value)
        end
    end
    table.remove = function (_tlist,_nindex)
        expect(false,1,_tlist,"table")
        expect(false,2,_nindex,"number","nil")
        local meta = metaTable.getmetatable(_tlist) or {}
        if meta._isReadOnly
        then
            error("table isReadOnly",2)
        end
        Tbl.remove(_tlist,_nindex)
    end
    table.move = function (_tList1,_nIndex,_nCount,_n2Index,_tList2)
        expect(false,1,_tList1,"table")
        expect(false,2,_nIndex,"number")
        expect(false,3,_nCount,"number")
        expect(false,4,_n2Index,"number")
        expect(false,5,_tList2,"table")
        do
            local mainMeta = metaTable.getmetatable(_tList1) or {}
            local CopyMeta = metaTable.getmetatable(_tList2)  or {}
            if mainMeta._isReadOnly
            then
                error("argument #1 is ReadOnly",2)
            end
            if CopyMeta.__isReadOnly
            then
                error("argument #2 is ReadOnly",2)
            end
        end
        return Tbl.move(_tList1,_nIndex,_nCount,_n2Index,_tList2)
    end
    function table.sort(_tlist,_fnComp)
        expect(false,1,_tlist,"table")
        expect(false,2,_fnComp,"function","nil")
        local meta = metaTable.getmetatable(_tlist)
        if meta.__isReadOnly
        then
            error("table is ReadOnly",2)
        end
        return Tbl.sort(_tlist,_fnComp)
    end
    ---@diagnostic enable:redundant-parameter,duplicate-set-field

    ---comment
    ---@param _tlist table
    ---@return table
    table.setReadOnly = function (_tlist)
        expect(false,1,_tlist,"table")
        local meta = metaTable.getmetatable(_tlist) or {}
        if meta._isReadOnly
        then
            error("table is ReadOnly",2)
        end
        local newMeta = {__index = _tlist,__newindex = function (t, k, v)
            error("table is ReadOnly",2)
        end,_isReadOnly = true}
        local proxy = metaTable.setmetatable({},newMeta)
        if util.table.getType(_tlist) ~= "table"
        then
            util.table.setType(proxy,util.table.getType(_tlist))
        end
        return  proxy
    end
    table.isReadOnly = function (_tlist)
        expect(false,1,_tlist,"table")
        return (metaTable.getmetatable(_tlist) or {})._isReadOnly or false
    end
    proectTBl(table)
    debug.protect(getmetatable)
    debug.protect(setmetatable)
    debug.protect(DisabledGetMeta)
    debug.protect(DisabledSetMeta)
end

local OS = ""
do -- time to add protection to one directory limit
    local Filesystem = util.table.copy(fs)
    local function wrap(_sPath)
        if OS == ""
        then
            return _sPath
        end
        local info = util.string.split(_sPath,"/")
        if table.concat(info,"/",1,2) == "bios/modules" or string.sub(info[1],1,4) == "disk"
        then
            return _sPath
        end
        return Filesystem.combine(OS,_sPath)
    end
    local function checkExist(_sPath)
        local result = wrap(_sPath)
        if not Filesystem.exists(wrap(_sPath))
        then
            error(("%s:not found"):format(result),3)
        end
        return result
    end
    local function unWrap(_sString)
        if OS == ""
        then
            return _sString
        end
        local result = util.string.split(_sString,"/")
        if string.sub(result[1],1,4) == "disk"
        then
            return _sString
        end
        return table.concat(result,"/",2)
    end
    BIOS = {
        install = function (_sfile_doc)
            expect(false,1,_sfile_doc,"string")
            if not Filesystem.exists(wrap(_sfile_doc))
            then
                error(("%s:not found"):format(_sfile_doc),2)
            end
            if util.file.getExtension(_sfile_doc) ~= "OSID"
            then
                error(("wrong file type expected OSID got %s"):format(util.file.getExtension(_sfile_doc)),2)
            end
            --- extracts the data
            local dirs,files,kernel
            do
                local data = fm.readFile(wrap(_sfile_doc))
                if type(data) ~= "table"
                then
                    error("unknown format",2)
                end
                field(1,data,"kernel","string")
                field(1,data,"dirs","table","nil")
                field(1,data,"files","table","nil")
                dirs = data.dirs or {}
                files = data.files
                kernel = data.kernel
            end
            local ID = util.file.withoutExtension(Filesystem.getName(_sfile_doc))
            if fs.exists(ID)
            then
                for _,v in pairs(OS_list) do
                    if v == kernel
                    then
                        error("can't install the same OS twice",2)
                    end
                end
                if not Parent:prompt("OS exists do you want me to reinstate it")
                then
                    error("OS exists",0)
                end
                if not Filesystem.exists(Filesystem.combine(ID,kernel))
                then
                    error("can not resinstate the OS as the kernel has not been found",2)
                end
                table.insert(settings.list,Filesystem.combine(ID,kernel))
                fm.OverWrite("bios/bios.settings",settings,"S")
                os.reboot()
                while true do
                    coroutine.yield()
                end
            end
            -- allacates disk space
            fs.makeDir(ID)
            for _,v in pairs(dirs or {}) do
                Filesystem.makeDir(Filesystem.combine(ID,v))
            end
            for _,v in pairs(files) do
                Filesystem.makeDir(Filesystem.combine(ID,v))
            end
            table.insert(settings.list,Filesystem.combine(ID,kernel))
            fm.OverWrite("bios/bios.settings",settings,"S")
            os.reboot()
            while true do
                coroutine.yield()
            end
        end,
        remove = function (_sOSID)
            expect(false,1,_sOSID,"string")
            _sOSID = util.file.getRoot(_sOSID)
            local index
            for i,v in pairs(OS_list) do
                if util.file.getRoot(v) == _sOSID
                then
                    index = i
                end
            end
            if not index
            then
                error(("no OS known as %s"):format(_sOSID),0)
            end
            local root = util.file.getRoot(OS_list[index])
            if Filesystem.exists(root)
            then
                Filesystem.delete(root)
            end
            table.remove(settings.list,index)
            fm.OverWrite("bios/bios.settings",settings,"S")
            os.reboot()
            while true do
                coroutine.yield()
            end
        end,
    }
    fs.attributes = function (_sPath)
        expect(false,1,_sPath,"string")
        return Filesystem.attributes(checkExist(_sPath))
    end
    fs.complete = function (_sPath,_sLocation,bIncludeFiles,bIncludeDirs)
        expect(false,1,_sPath,"string")
        expect(false,2, _sLocation, "string")
        if type(bIncludeFiles) == "table" then
            field(3,bIncludeFiles, "include_dirs", "boolean", "nil")
            field(3,bIncludeFiles, "include_hidden", "boolean", "nil")
            field(3,bIncludeFiles, "include_files", "boolean", "nil")
        else
            expect(false,3, bIncludeFiles, "boolean", "nil")
            expect(false,4, bIncludeDirs, "boolean", "nil")
        end
        return Filesystem.complete(checkExist(_sPath),checkExist(_sLocation),bIncludeFiles,bIncludeDirs)
    end
    fs.copy = function (_sPath,_sDest)
        expect(false,1,_sPath,"string")
        expect(false,2,_sDest,"string")
        return Filesystem.copy(checkExist(_sPath),wrap(_sDest))
    end
    fs.delete = function (_sPath)
        expect(false,1,_sPath,"string")
        return Filesystem.delete(wrap(_sPath))
    end
    fs.exists = function (_sPath)
        expect(false,1,_sPath,"string")
        return Filesystem.exists(wrap(_sPath))
    end
    fs.find = function (_sPath)
        expect(false,1,_sPath,"string")
        local result = fs.find(wrap(_sPath)) or {}
        for i,v in pairs(result) do
            result[i] = unWrap(v)
        end
        return result
    end
    fs.getCapacity = function (_sPath)
        expect(false,1,_sPath,"string")
        return fs.getCapacity(checkExist(_sPath))
    end
    fs.getDrive = function (_sPath)
        expect(false,1,_sPath,"string")
        return fs.getDrive(checkExist(_sPath))
    end
    fs.getFreeSpace = function (_sPath)
        expect(false,1,_sPath,"string")
        return fs.getFreeSpace(checkExist(_sPath))
    end
    fs.getSize = function (_sPath)
        expect(false,1,_sPath,"string")
        return fs.getSize(checkExist(_sPath))
    end
    fs.isDir = function (_sDir)
        expect(false,1,_sDir,"string")
        return fs.isDir(checkExist(_sDir))
    end
    fs.isDriveRoot = function (_sPath)
        expect(false,1,_sPath,"string")
        return fs.isDriveRoot(checkExist(_sPath))
    end
    fs.isReadOnly = function (_sPath)
        expect(false,1,_sPath,"string")
        return fs.isReadOnly(checkExist(_sPath))
    end
    fs.list = function (_sPath)
        expect(false,1,_sPath,"string")
        return fs.list(checkExist(_sPath))
    end
    fs.makeDir = function (_sDir)
        expect(false,1,_sDir,"string")
        return fs.makeDir(wrap(_sDir))
    end
    fs.move = function (_sPath,_sDest)
        expect(false,1,_sPath,"string")
        return fs.move(checkExist(_sPath),wrap(_sDest))
    end
    fs.open = function (_sPath,_sMode)
        expect(false,1,_sPath,"string")
        expect(false,2,_sMode,"string")
        if string.find(_sMode,"w")
        then
            if fs.isReadOnly(_sPath)
            then
                return nil,("%s:isReadOnly"):format(_sPath)
            end
        end
        return fs.open(wrap(_sPath),_sMode)
    end
    proectTBl(fs)
    proectTBl(BIOS)
end
-- time to load the bootLoader
local errorHandle = error
while true do
    local gloabl = setmetatable(util.table.copy(_G),{_G = true,__disableSetMeta = true})
    local tEnv = setmetatable({util = util,class = class,term = Parent,_G = gloabl},{__index = gloabl})
    local _fnError,_fnKernel,err,_sKernel
    do
        _sKernel = OS_list[selected]
        if util.file.getExtension(_sKernel) == "OSID"
        then
            BIOS.install(_sKernel)
            os.reboot()
            while true do
                coroutine.yield()
            end
        end
        local Dir = util.file.list(util.file.getDir(_sKernel),true,false)
        local _sError = Dir[util.table.find(Dir,"error.lua")]
        if _sError
        then
            _fnError,err = loadfile(_sError,nil,tEnv)
            if not _fnError
            then
                log.error(err)
            end
        end
        _fnKernel,err = loadfile(_sKernel,nil,tEnv)
        if not _fnKernel
        then
            log.error(err)
        end
    end
    if type(_fnKernel) == "function"
    then
        error = originalError
        OS = util.file.withoutExtension(fs.getName(_sKernel))
        xpcall(_fnKernel,type(_fnError) == "function" and _fnError or function (_sMessage)
            log.error(_sMessage)
        end)
        OS = ""
        error = errorHandle
    end
    selected = selected + 1
end
