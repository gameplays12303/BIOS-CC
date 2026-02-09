local expect = (require and require("modules.expect2") or dofile("boot/modules/expect2.lua")).expect
local util = require and require("modules.utilities") or dofile("boot/modules/utilities.lua")
local nativeFs = util.table.copy(fs)
fs.delete = function (sPath)
    expect(false,1,sPath,"string")
    if sPath == ".settings" or string.sub(sPath,1,4) == "bios"
    then
        error(("%s:Access denied"):format(sPath),2)
    end
    local bool,mess = pcall(nativeFs.delete,sPath)
    if not bool
    then
        return false,mess
    end
    return true
end
fs.makeDir = function (sPath)
    expect(false,1,sPath,"string")
    if sPath == ".settings" or string.sub(sPath,1,4) == "bios"
    then
        error(("%s:Access denied"):format(sPath),2)
    end
    local bool,mess = pcall(nativeFs.makeDir,sPath)
    if not bool
    then
        return false,mess
    end
    return true
end
fs.move = function (sPath,sDest)
    expect(false,1,sPath,"string")
    expect(false,2,sDest,"string")
    if sPath == ".settings" or string.sub(sPath,1,4) == "bios" or sDest == ".settings" or string.sub(sDest,1,4) == "bios"
    then
        error(("%s:Access denied"):format(sPath),2)
    end
    local bool,mess = pcall(nativeFs.move,sPath,sDest)
    if not bool
    then
        return false,mess
    end
    return true
end
fs.isReadOnly = function (sPath)
    expect(false,1,sPath,"string")
    if sPath == ".settings" or string.sub(sPath,1,4) == "bios"
    then
        return true
    end
    return nativeFs.isReadOnly(sPath)
end
fs.attributes = function (sPath)
    expect(false,1,sPath,"string")
    local attributes = nativeFs.attributes(sPath)
    if sPath == ".settings" or string.sub(sPath,1,4) == "bios"
    then
       attributes.isReadOnly = true
    end
    return attributes
end
fs.open = function (sPath, mode)
    expect(false,1,sPath,"string")
    expect(false,2,mode,"string")
    if (sPath == ".settings" or string.sub(sPath,1,4) == "bios") and mode ~= "r" then
        return nil, ("%s:Access denied"):format(sPath)
    end
    return nativeFs.open(sPath, mode)
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
        return false,mess
    end
    return true
end