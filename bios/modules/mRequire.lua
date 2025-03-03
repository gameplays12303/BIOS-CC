-- Modified from original GeneralModules, licensed under MIT
-- These modifications were made by [Your Name or Organization] for the project
-- For full license information, see LICENSE file in the modules directory.


-- this is degined to replace the require API so modules can be reloaded as needed
-- this module minics the require system in that once loaded it simply just calleds the module once more
-- unless the reload boolean is set to true then it will simply reload it 
-- if the module fails to load it will not save it in the loaded Table unlike the actual require
local expect = require and require("modules.expect2") or BIOS.dofile("bios/modules/expect2.lua")
local util = require and require("modules.utilties") or BIOS.dofile("bios/modules/utilties.lua")
---@diagnostic disable-next-line: cast-local-type
expect = expect.expect
local handle = {path = {}}
handle.Path = {Paths = util.file.list("rom/modules",false,true,true)}
table.insert(handle.Path.Paths,"")
handle.loaded = {}
-- adds a LoadPath to the loadPaths Table
---comment
---@param _sPath string
---@param priority number|nil
function handle.Path.Add(_sPath,priority)
    expect(false,1,_sPath,"string")
    expect(false,2,priority,"number","nil")
    _sPath = string.gsub(_sPath,"%.","/")
    if not fs.exists(_sPath)
    then
        error(("%s:not found"):format(_sPath),0)
    end
    if priority
    then
        table.insert(handle.Path.Paths,priority,_sPath)
    else
        table.insert(handle.Path.Paths,_sPath)
    end
    
end
-- removes a loadPath from the loadPaths Table
---comment
---@param _sPath string
---@return boolean
function handle.Path.Remove(_sPath)
    expect(false,1,_sPath,"string")
    local i = util.table.find(handle.Path.Paths,_sPath)
    if i
    then
        table.remove(handle.Path.Paths,i)
    end
    return true
end

---loads up the api
--- unlike normal require it can take a environment table and reload a api
---@param _sPath string
---@param _Env table|nil
---@param bReload boolean|nil
---@return table|unknown
function handle.require(_sPath,_Env,bReload)
    expect(false,1,_sPath,"string")
    expect(false,2,_Env,"table","nil")
    expect(false,3,bReload,"boolean","nil")
    -- backwards support for require
    -- turns the '.' into "/" then adds
    -- .lua to the end of the string
    if util.file.getExtension(_sPath) ~= "lua"
    then
        _sPath = string.gsub(_sPath,"%.","/")..".lua"
    end
    
    -- checks to see if the modules exists
    -- in the Paths written in the Path Table
    local Path
    for _,v in pairs(handle.Path.Paths) do
        local Tem = fs.combine(v,_sPath)
        if fs.exists(Tem)
        then
            Path = Tem
            break
        end
    end
    -- if not found then
    -- returns error code simular format 
    -- to the  old require API
    if not Path
    then
        local err = _sPath.."\n"
        for _,v in pairs(handle.Path.Paths) do
            err = err..fs.combine(v,_sPath)..": not found".."\n"
        end
        error(err,2)
    end
    -- if found then it checks to see if it is already loaded 
    -- is so it simply calleds the module once again and returns the APIS the module returns 
    -- unless he reload boolean is true
    -- which then it will reload and replace the module completelly 
    if not bReload
    then
        for i,v in pairs(handle.loaded) do
            if i == _sPath
            then
                -- i don't bother to put it in a pcall
                -- because it work the first time
                -- for proformace reasons
                return v()
            end
        end
    end
    _Env = _Env or _ENV
    if not _Env["mRequire"] or not _Env["require"]
    then
        _Env["require"] = handle.require
        _Env["mRequire"] = handle
    end
    do
        local meta = getmetatable(_Env) or {}
        meta.__index = _G
        setmetatable(_Env,meta)
    end
    local fn,err = BIOS.loadfile(Path,"bt",_Env)
    if not fn
    then
        error(err,0)
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    local ok = table.pack(pcall(fn))
    if not ok[1]
    then
        error(ok[2],0)
    end
    handle.loaded[_sPath] = fn
    return table.unpack(ok,2)
end
--- reloads the all the apis
function handle.reLoadAll()
    for i, v in pairs(handle.loaded) do
        local Env = getfenv(v)
        handle.require(i,Env,true)
    end
end
return handle
