local util = require("modules.utilties")
local expect = require("modules.expect2")
local field = expect.field
---@diagnostic disable-next-line: cast-local-type
expect = expect.expect
local MetaTable = {
    getmetatable = getmetatable,
    setmetatable = setmetatable,
    nativeRawSet = rawset
}
local function MakeProtectedVars(Object,global)
    expect(false,1,Object,"table")
    expect(false,2,global,"table")
    local protected = {}
    return setmetatable(Object,{__index = function (_,index)
        index = tostring(index)
        local val = protected[index]
        return val ~= nil and val or global[index]
    end,__newindex = function (_, index, val)
        if index == "protected"
        then
            expect(false,3,val,"table")
            field(3,val,"index","string","number")
            if val.index == "protected"
            then
                error("can not set value to reserved word",2)
            end
            if protected[val.index]
            then
                error("tried to change a protected_value",2)
            end
            protected[index] = val.value
            return
        end
        MetaTable.nativeRawSet(Object,index,val)
    end,__disabledGetMeta = true,__disabledSetMeta = true})
end
local object = {}
util.table.setType(object,"class: Main")
function object:SubClass(_sName)
    assert(not type(self) ~= "table","make sure you are using object:SubClass not object.SubClass")
    expect(true,0,self,"class")
    expect(false,1,_sName,"string")
    local class = {}
    MakeProtectedVars(class,self)
    util.table.setType(class,("class:%s"):format(_sName))
    return class
end
function object:isClass()
    assert(not type(self) ~= "table","make sure you are using object:isClass not object.isClass")
    return self:getType() == "class"
end
function object:isSubclass()
    assert(not type(self) ~= "table","make sure you are using object:isSubclass not object.isSubclass")
    if not self:isClass()
    then
        return false
    end
    return self.Parent ~= object
end
function object:getType(index)
    index = expect(false,1,index,"number","nil") or 1
    return util.string.split(util.table.getType(self),": ")[index]
end
local function makeObject(self,_sName,...)
    return self:getType(1) == "object" and self:create_Object(_sName,...) or {}
end
function object:create_Object(_sName,...)
    expect(true,0,self,"class","object")
    expect(false,1,_sName,"string")
    assert(not type(self) ~= "table","make sure you are using object:create_Object not object.create_Object")
    local new_Object = makeObject(self,_sName,...)
    MakeProtectedVars(new_Object,self)
    util.table.setType(new_Object,("object:%s:%s"):format(self:getType(2),_sName))
    new_Object:init(_sName,...)
    return new_Object
end
function object:init(_sName,...)
    expect(true,0,self,"object")
    self.children = MetaTable.setmetatable({},{__mode = 'v'})
    return self
end
return function (_sclass)
    expect(false,1,_sclass,"string")
    return object:SubClass(_sclass)
end