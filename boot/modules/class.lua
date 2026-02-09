local expect_utils = (require and require("modules.expect2") or dofile("boot/modules/expect2.lua"))
local util = require and require("modules.utilities") or dofile("boot/modules/utilities.lua")
local field = expect_utils.field
local expectValue = expect_utils.expectValue
---@diagnostic disable-next-line: cast-local-type
local expect = expect_utils.expect
local debug = util.table.copy(debug)


local Main_class = {}


local function NextState(data)
    if data.Parent == nil then
        if debugger then debugger.debug() end
        return false
    end
    local meta = getmetatable(data.Parent)

    local CurrentState = data.Parent
    if not CurrentState or data.visited[CurrentState] then
        return false
    end
    -- If the parent has no meta, we've hit a raw table or the end of the chain
    if not meta then return false end

    -- MOVE THE WINDOW: The old parent is now the current 'self'
    data.self = CurrentState
    data.visited[CurrentState] = true

    -- EXTRACT: Populate the state with this specific level's data
    data.static     = meta.static
    data.private    = meta.private
    data.target     = meta.target or meta.private
    data.type       = meta.type
    -- PREPARE: Point 'Parent' to the next level up for the NEXT call
    data.Parent = meta.Parent
    
    return data
end

local function StartState(userData)
    return NextState({Parent = userData,visited = {}})
end

local function hasAccess(Current_State)
    if not debug
    then
        return true
    end
    CurrentProcess = debug.getinfo(3,"f")
    if not CurrentProcess.func
    then
        return false
    end
    if util.table.find(Current_State.static,CurrentProcess.func)
    then
        return true
    end
    local tempState = StartState(Current_State.Parent)
    while tempState do
        for i,v in pairs(tempState.static) do
            if v == CurrentProcess.func
            then
                return true
            end
        end
        tempState = NextState(tempState)
    end
end

local function index(userData, key)
    local Current_State = StartState(userData)
    while Current_State do
        -- 1. Check Private (if caller has access)
        if Current_State.private and Current_State.private[key] ~= nil then
            if hasAccess(Current_State) then
                return Current_State.private[key]
            end
        end

        -- 2. Check Static (This is where 'public' or 'static' proxies live!)
        if Current_State.static and Current_State.static[key] ~= nil then
            return Current_State.static[key]
        end

        Current_State = NextState(Current_State)
    end
end

local function newIndex(userData, key, value)
    local Current_State = StartState(userData)
    if not Current_State then
        error("unknown internal config", 2)
    end
    -- 1. Check ALL layers for existing protected keys
    -- We walk the chain to see if 'key' is reserved anywhere as static or private
    local searchState = StartState(userData)
    while searchState do
        if (searchState.static and searchState.static[key] ~= nil) or 
           (searchState.private ~= nil and searchState.private ~= Current_State.target and searchState.private[key] ~= nil) then
            return error(("Security Violation: '%s' is a protected member and cannot be shadowed or overwritten."):format(key), 2)
        end
        searchState = NextState(searchState)
    end

    -- 2. Handle Proxy Routing (The "Window" logic)
    if Current_State.target == Current_State.private then
        if not hasAccess(Current_State) then
            error("Permission Denied: Private access restricted", 2)
        end
    end
    if Current_State.target == Current_State.static and type(value) == "table"
    then
        return error("can not put a table on the static table",2)
    end
    -- 3. Volatile Fallback
    -- If it's not a proxy write and not a protected key, it goes straight to the object
    rawset(Current_State.target, key, value)
end

local function __iter(state, prev_key)
    -- 1. Try to get the next item from the current target
    local key, value = next(state.target, prev_key)

    if key ~= nil then
        return key, value
    end

    -- 2. Current target is empty. Pivot based on mode.
    if state.mode == 0 then
        -- We finished 'self' (the object), move to 'static'
        state.mode = 1
        state.target = state.static
        return __iter(state, nil) -- Restart iteration on the new target

    elseif state.mode == 1 then
        -- We finished 'static', move to the Parent class
        local next_lvl = NextState(state)
        if next_lvl then
            -- We don't want the parent's private data either
            state.private = nil 
            state.mode = 0
            state.target = next_lvl.self -- Start at the parent's instance level
            return __iter(state, nil)
        end
    end

    -- 3. End of the chain
    return nil
end

local function __pairs(self)
    local Current_State = StartState(self)
    Current_State.private = nil
    Current_State.mode = 0
    Current_State.target = self
    return __iter,Current_State,nil
end


--- this constructs the class as the class is readonly once constructed
--- this is how we get around it without the chicken and egg problem
local function build(self)
    ---@type table
    ---@diagnostic disable-next-line
    local meta = getmetatable(self)
    ---@class class
    local newClass = {}
    local metaData = {hash = util.table.get_hash(newClass),__index = index,__newindex = newIndex,static = meta.static,Parent = meta.Parent,type = "class",__name = meta.name,__tostring = util.table.tostring,__pairs = __pairs}
    setmetatable(newClass,metaData)
    if ProtectMeta
    then
        ProtectMeta(newClass,Main_class,util,NextState,expect_utils,StartState)
    end
    return newClass
end

--- this is used to put info into the constructor table 
local function initialize_handler(self,k,v)
    ---@type table
    ---@diagnostic disable-next-line
    local meta = getmetatable(self)
    if meta.static[k]
    then
        error(("%s: key is taken"):format(k))
    end
    if type(v) == "function" and debug.protect
    then
        debug.protect(v)
    end
    if type(v) == "table"
    then
        return error(3,"can not put table onto class")
    end
    meta.static[k] = v
end

local methods = {}
local function proxyProtect (_, k) 
    error("Proxy Read Violation: " .. tostring(k), 2) 
end

---create a object but dose not initialize it
---can take a bluePrint table as the table 
---@param name string
---@return table
function methods:Create_Object(name,allow_children)
    expect(false,1,name,"string")
    self:isClass(true)
    if allow_children == nil
    then
        allow_children = true
    else
        expect(false,4,allow_children,"boolean")
    end
    local newObject = {}
    local metaData = {allow_children = allow_children,__tostring = util.table.tostring,hash = util.table.get_hash(newObject),__index = index,__newindex = newIndex,Parent = self,private = {},static = {public = {},static = {}},type = "object",__name = name,__pairs = __pairs}
    --[[
        time to setup the proxies
    ]]
    setmetatable(metaData.static.static,{
        __index = proxyProtect,
        __newindex = newIndex,
        target = metaData.static,
        private = metaData.private,
        type = "static",
        self = newObject,
        __isProxy = true,
    })
    setmetatable(metaData.static.public,{
        __index = proxyProtect,
        __newindex = newIndex,
        target = newObject,
        static  = metaData.static,
        private = metaData.private,
        type = "public",
        self = newObject,
        __isProxy = true,
    })
    metaData._tostring = util.table.tostring
    setmetatable(newObject,metaData)
    if ProtectMeta
    then
        ProtectMeta(newObject,Main_class,util,NextState,expect_utils,StartState)
    end
    return newObject
end
--- create a class constructor 
--- call the class constructor table like [table]() for the class when finished
---@param name string
---@return table
function methods:SubClass(name)
    self:isClass(true)
    expect(false,1,name,"string")
    local methodContainer = setmetatable({},{
        __call = build,
        name  = name,
        Parent = self,
        __newindex = initialize_handler,
        static = {},
    })
    return methodContainer
end
---comment
---@param _bEnfore boolean|nil
---@return boolean
function methods:isObject(_bEnfore)
    local metaData = getmetatable(self)
    local isObject = metaData.type == "object"
    if not _bEnfore
    then
        return isObject
    end
    if not isObject
    then
        error("expected object",3)
    end
end

---comment
---@param _bEnfore boolean|nil
---@return boolean
function methods:isClass(_bEnfore)
    local metaData = getmetatable(self)
    local isClass = metaData.type == "class"
    if not _bEnfore
    then
        return isClass
    end
    if not isClass
    then
        error("expected class",3)
    end
end

--passes a object ownership down
---@param new_parent class
function  methods:setParent(new_parent)
    expect(false,1,new_parent,"table")
    self:isObject(true)
    if not hasAccess(self)
    then
        error("can %s not pass ownership of object",2)
    end
    local data = getmetatable(self)
    data.Parent = new_parent
    return true
end

---comment
---@param name  string
---@param btrue boolean
---@return boolean
function  methods:isNamed(name,btrue)
    expect(false,1,name,"string")
    expect(false,2,btrue,"boolean","nil")
    local metaData = getmetatable(self)
    local boolean = metaData.__name == name
    if btrue and not boolean
    then
        error(("expected table named %s, got %s"):format(name,metaData.__name or "not named"),3)
    end
    return boolean
end

function  methods:getName()
    return getmetatable(self).__name
end
---comment
---@param name string
function  methods:setName(name)
    expect(false,1,name,"string")
    local metaData = getmetatable(self)
    metaData.__name = name
end

do -- prepairs the framework
    local meta = {__index = methods,__newindex = newIndex,private = {},static = methods,type = "class",__name = "Class_framework",__pairs = __pairs}
    meta.hash = util.table.get_hash(Main_class)
    meta.__tostring = util.table.tostring
    setmetatable(Main_class,meta)
    if ProtectMeta
    then
        ProtectMeta(Main_class,Main_class,hasAccess,index,newIndex,__pairs,__iter,util,StartState)
    end
end
return Main_class,NextState,StartState