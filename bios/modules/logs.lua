
local fm = require("modules.fm")
local expect = require and require("modules.expect2") or BIOS.dofile("bios/modules/expect2.lua")
---@diagnostic disable-next-line: cast-local-type
expect = expect.expect
local util = require and require("modules.utilties") or BIOS.dofile("bios/modules/utilties.lua")
local fs = fs
local handle = {}

function handle:Open_Dir(_sDir,limit)
    expect(false,1,_sDir,"string")
    limit =  expect(false,2,limit,"number","nil") or 4
    if not fs.isDir(_sDir) and fs.exists(_sDir)
    then
        error(("%s:is not a directory"):format(_sDir))
    end
    local managment = _sDir.."/logsman.settings"
    ---@class logDir
    local Dir = setmetatable({
        managment = fs.exists(managment) and fm.readFile(managment) or {},
        managment_dir = _sDir.."/logsman.settings",
        directory = _sDir,
        limit = limit
    },{__index = handle})
    util.Table.setType(Dir,"logDir")
    return Dir
end
function handle:Open_Log(_sName)
    expect(true,0,self,"logDir")
    expect(false,1,_sName,"string")
    local path
    local limit = self.limit
    if limit
    then
        local info = self.managment and self.managment[_sName]
        if not info
        then
            self.managment[_sName] = {
                created = 0,
                count = 0,
            }
            info = self.managment[_sName]
        end
        info.count = info.count + 1
        if info.created == self.limit
        then
            if info.count == info.created
            then
                info.count = 0
            else
                info.count = info.count + 1
            end
            if info.count > 0
            then
                path = fs.combine(self.directory,util.File.withoutExtension(fs.getName(_sName))..("(%s).log"):format(info.count))
            else
                path = fs.combine(self.directory,util.File.withoutExtension(fs.getName(_sName))..".log")
            end
        else
            info.created = info.created + 1
            if info.created > 1
            then
                path = fs.combine(self.directory,util.File.withoutExtension(fs.getName(_sName))..("(%s).log"):format(info.created))
            else
                path = fs.combine(self.directory,util.File.withoutExtension(fs.getName(_sName))..".log")
            end
        end
    else
        local count = 0
        path = fs.combine(self.directory,util.File.withoutExtension(fs.getName(_sName))..".log")
        repeat
            count = count + 1
            path = fs.combine(self.directory,util.File.withoutExtension(fs.getName(_sName))..("(%s).log"):format(count))
        until not fs.exists(path)
    end
    local file,err = fs.open(path,"w")
    if not file
    then
        error(err,0)
    end
    ---@class logFile
    local logFile = setmetatable({
        file = file,
        closed = false,
    },{__index = handle})
    util.Table.setType(logFile,("logFile"):format(_sName))
    return logFile
end
---comment
---@param info string
function handle:Info(info)
    expect(true,0,self,"logFile")
    expect(false,1,info,"string")
    if self:isClosed()
    then
        error("log_file is closed",2)
    end
    self.file.write(("Info:%s:%s\n"):format(hardWare.date(),info))
end
---comment
---@param info string
function handle:Warn(info)
    expect(true,0,self,"logFile")
    expect(false,1,info,"string")
    if self:isClosed()
    then
        error("log_file is closed",2)
    end
    self.file.write(("Warn:%s:%s\n"):format(hardWare.date(),info))
end
---comment
---@param err string
---@diagnostic disable-next-line: redefined-local
function handle:Error(err)
    expect(true,0,self,"logFile")
    expect(false,1,err,"string")
    if self:isClosed()
    then
        error("log_file is closed",2)
    end
    self.file.write(("Error:%s:%s\n"):format(hardWare.date(),err))
end
---comment
---@param info string
function handle:Fatal(info)
    expect(true,0,self,"logFile")
    expect(false,1,info,"string")
    if self:isClosed()
    then
        error("log_file is closed",2)
    end
    self.file.write(("Fatal:%s:%s\n"):format(hardWare.date(),info))
end
function handle:isClosed()
    return self.closed
end
function handle:close()
    self.file.close()
    self.closed = true
end
return handle
