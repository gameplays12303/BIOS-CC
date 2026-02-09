local expect = (require and require("modules.expect2") or dofile("boot/modules/expect2.lua")).expect
local util = require and require("modules.utilities") or dofile("boot/modules/utilities.lua")
local class = require and require("modules.class") or dofile("boot/modules/class.lua")
local fm = require and require("modules.fm") or dofile("boot/modules/fm.lua")
local fs = fs
local open_Dirs = setmetatable({},{__mode = "v"})
local log,log_init,logHandler_init,logHandler
log_init = class:SubClass("log")
function log_init:Directory(_sDir,limit)
    self:isClass(true)
    expect(false,1,_sDir,"string")
    if open_Dirs[_sDir]
    then
        return open_Dirs[_sDir]
    end
    limit =  expect(false,2,limit,"number","boolean","nil") or 4
    if not fs.isDir(_sDir) and fs.exists(_sDir)
    then
        error(("%s:is not a directory"):format(_sDir))
    end
    local managment = _sDir.."/logsman.settings"
    ---@class Dir
    local Dir = log:Create_Object("logDir")
    Dir.management = fs.exists(managment) and fm.readFile(managment) or {}
    Dir.management_dir = _sDir.."/logsman.settings"
    Dir.directory = _sDir
    Dir.limit = limit or 4
    --- store it so we don't have fighting dirs
    open_Dirs[_sDir] = Dir
    return Dir
end

function log_init:Open_Log(_sName)
    self:isObject(false)
    self:isNamed("logDir",true)
    expect(false,1,_sName,"string")
    local path
    _sName = util.file.withoutExtension(fs.getName(_sName))
    local limit,count = self.limit,(self.management[_sName] or 0)
    if count == limit
    then
        count = 0
    end
    if count ~= 0
    then
        count = count + 1
        path = fs.combine(self.directory,_sName)..("(%d).log"):format(count)
    else
        path = fs.combine(self.directory,_sName)..".log"
        count = count + 1
    end
    local file,err = fs.open(path,"w")
    if not file
    then
        error(err,0)
    end
    self.management[_sName] = count
    fm.OverWrite(self.management_dir,self.management)
    ---@class logFile
    local logFile = logHandler:Create_Object("logFile")
    logFile.file = file
    logFile.closed = false
    return logFile 
end
log = log_init()


logHandler_init = log:SubClass("logHandler",false)
function logHandler_init:Info(Info)
    self:isObject(true)
    self:isNamed("logFile",true)
    expect(false,1,Info,"string")
    if self:isClosed()
    then
        error("log_file is closed",2)
    end
    self.file.write(("Info:%s:%s\n"):format(hardWare.date(),Info))
end
function logHandler_init:Warn(Info)
    self:isObject(true)
    self:isNamed("logFile",true)
    expect(false,1,Info,"string")
    if self:isClosed()
    then
        error("log_file is closed",2)
    end
    self.file.write(("Warn:%s:%s\n"):format(hardWare.date(),Info))
end
function logHandler_init:Error(Err)
    self:isObject(true)
    self:isNamed("logFile",true)
    expect(false,1,Err,"string")
    if self:isClosed()
    then
        error("log_file is closed",2)
    end
    self.file.write(("Error:%s:%s\n"):format(hardWare.date(),Err))
end
function logHandler_init:Fatal(Fatal)
    self:isObject(true)
    self:isNamed("logFile",true)
    expect(false,1,Fatal,"string")
    if self:isClosed()
    then
        error("log_file is closed",2)
    end
    self.file.write(("Fatal:%s:%s\n"):format(hardWare.date(),Fatal))
end
function logHandler_init:isClosed()
    self:isObject(true)
    self:isNamed("logFile",true)
    return self.closed
end
function logHandler_init:Close()
    self:isObject(true)
    self:isNamed("logFile",true)
    self.file.close()
    self.closed = true
end
logHandler = logHandler_init()

return log


