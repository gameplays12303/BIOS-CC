local expect = (require and require("bios.modules.expect2") or BIOS.dofile("bios/modules/expect2.lua")).expect
local util = require and require("bios.modules.utilties") or BIOS.dofile("bios/modules/utilties.lua")
local nativeFs = util.Table.copy(fs)
fs.delete = function (sPath)
    expect(false,1,sPath,"string")
    if sPath == ".settings" or string.find(string.sub(sPath,4),"bios")
    then
        error(("%s:Access denied"):format(sPath),2)
    end
    local bool,mess = pcall(nativeFs.delete,sPath)
    if not bool
    then
        error(mess,2)
    end
    return true
end
fs.makeDir = function (sPath)
    expect(false,1,sPath,"string")
    if sPath == ".settings" or string.find(string.sub(sPath,4),"bios")
    then
        error(("%s:Access denied"):format(sPath),2)
    end
    local bool,mess = pcall(nativeFs.makeDir,sPath)
    if not bool
    then
        error(mess,2)
    end
    return true
end
fs.move = function (sPath,sDest)
    expect(false,1,sPath,"string")
    expect(false,2,sDest,"string")
    if sPath == ".settings" or string.find(string.sub(sPath,4),"bios") or sDest == ".settings" or string.find(string.sub(sDest,4),"bios")
    then
        error(("%s:Access denied"):format(sPath),2)
    end
    local bool,mess = pcall(nativeFs.move,sPath,sDest)
    if not bool
    then
        error(mess,2)
    end
    return true
end
fs.isReadOnly = function (sPath)
    expect(false,1,sPath,"string")
    if sPath == ".settings" or string.find(string.sub(sPath,4),"bios")
    then
        return true
    end
    local bool,mess = pcall(nativeFs.isReadOnly,sPath)
    if not bool
    then
        error(mess,2)
    end
    return true
end
fs.attributes = function (sPath)
    expect(false,1,sPath,"string")
    local bool,attributes = pcall(nativeFs.attributes,sPath)
    if not bool
    then
        error(attributes,2)
    end
    if sPath == ".settings" or string.find(string.sub(sPath,4),"bios")
    then
       attributes.isReadOnly = true
    end
    return attributes
    
end
fs.open = function (sPath,mode)
    expect(false,1,sPath,"string")
    expect(false,2,mode,"string")
    if (sPath == ".settings" or string.find(string.sub(sPath,4),"bios")) and mode ~= "r"
    then
        error(("%s:Access denied"):format(sPath),2)
    end
    local bool,file = pcall(nativeFs.open,sPath,mode)
    if not bool
    then
        error(file,2)
    end
    return file
end
fs.copy = function (sPath,sDest)
    expect(false,1,sPath,"string")
    expect(false,2,sDest,"string")
    if sPath == ".settings" or string.find(string.sub(sPath,4),"bios") or sDest == ".settings" or string.find(string.sub(sDest,4),"bios")
    then
        error(("%s:Access denied"):format(sPath),2)
    end
    local bool,mess = pcall(nativeFs.copy,sPath,sDest)
    if not bool
    then
        error(mess,2)
    end
    return true
end