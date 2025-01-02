local util = require("modules.utilties")
local GUI_size_X,GUI_Size_Y = GUI:getSize()
local Menu_window = GUI:create(1,1,GUI_size_X,GUI_Size_Y,true)
Menu_window:setBackgroundColor(colors.black)
local message_window = Menu_window:create(4,1,GUI_size_X-6,1,true)
message_window:make_textBox()
do -- sets up the message_window
    local message = "boot_Menu"
    message_window:setCursorPos(select(1,message_window:getCenter())-(#message/2),1)
    message_window:write(message)
end
local button_canv = Menu_window:create(1,2,GUI_size_X,GUI_Size_Y-1,true)
button_canv:setBackgroundColor(colors.black)
local previous_button = Menu_window:create(1,1,3,1,true)
local next_button = Menu_window:create(GUI_size_X-2,1,3,1,true)


local pages = {{}}
local fm = require("fm")
local menu_list,run = nil,true
do --- loads up the menu options
    local menu_chunk = fm.readFile("bios/menu.lua_data","R") -- gets the avaible options
    ---@diagnostic disable-next-line: param-type-mismatch
    menu_list = util.String.UnSerialize(menu_chunk,_ENV,"menu.lua_data")
    menu_list["exit"] = function ()
        run = false
    end
end
previous_button:make_button()
next_button:make_button()
previous_button.active_window:setText("<")
previous_button.default_window:setText("<")
next_button.default_window:setText(">")
next_button.active_window:setText(">")

previous_button:redraw()
next_button:redraw()
do -- prepares the pages
    local function loadSubProgram(file,...)
        local isFile = fs.exists(file) and not fs.isDir(file) or false
        if not isFile
        then
            local err = ("file not found or is Directory :%s"):format(file)
            Menu_window:upDate(false)
            logFile:Error(err)
            return error(err,3)
        end
        local fn,err = BIOS.loadfile(file,"bt",_ENV)
        if not fn
        then
            Menu_window:upDate(false)
            logFile:Error(err)
            return  error(err,3)
        end
        local bool
        ---@diagnostic disable-next-line: param-type-mismatch
        bool,err = pcall(fn,...)
        if not bool
        then
            Menu_window:upDate(false)
            logFile:Error(err)
            return error(err,3)
        end
    end
    local CurrentPage = pages[1]
    local Current_x,Current_y = 1,1
    local newFlag = true
    for i,v in pairs(menu_list) do
        if type(i) == "string"
        then
            if #i+Current_x > GUI_size_X
            then
                Current_x = 1
                Current_y = Current_y + 2
                if Current_y > GUI_Size_Y
                then
                    Current_y = 1
                    local newPage = {}
                    newFlag = true
                    table.insert(pages,newPage)
                    CurrentPage = newPage
                end
            end
            local button = button_canv:create(Current_x,Current_y,#i+2,1,true)
            button:make_button()
            if newFlag
            then
                button:upDate(false)
                button:OverRide_status(true)
                button:upDate(true)
                newFlag = false
            end
            button.active_window:setText(i)
            button.default_window:setText(i)
            Current_x = Current_x+#i+3
            local v_type = type(v)
            if v_type == "table"
            then
                v_type =  type(v.fn)
                if v_type == "string"
                then
                    button:setActivate(loadSubProgram,v.fn,table.unpack(v.args))
                elseif v_type == "function"
                then
                    button:setActivate(v.fn,table.unpack(v.args))
                end
            elseif v_type == "function"
            then
                button:setActivate(v)
            elseif v_type == "string"
            then
                button:setActivate(loadSubProgram,v)
            end
            table.insert(CurrentPage,button)
        end
    end
    if #pages == 1
    then
        previous_button:upDate(false)
        next_button:upDate(false)
    end
end

local currentSel = 1
local CurrentPage_n = 1
local CurrentPage = pages[1]


local function SetSel(n)
    CurrentPage[currentSel]:OverRide_status()
    currentSel = currentSel + n
    CurrentPage[currentSel]:OverRide_status()
end

local function SetPage(n)
    if not pages[CurrentPage_n + n]
    then
        --- there is nothing we can do so we return
        return
    end
    for _,v in pairs(CurrentPage) do
        v:upDate(false)
    end
    button_canv:clear()
    CurrentPage_n = CurrentPage_n + n
    CurrentPage = pages[CurrentPage_n]
    for i,v in pairs(CurrentPage) do
        v:upDate(true)
        v:redraw()
        if v:isActive()
        then
            currentSel = i
        end
    end
end


previous_button:setActivate(function ()
    SetPage(-1)
end)
next_button:setActivate(function ()
    SetPage(1)
end)

local event_list = {
    ["key"] = {
        [keys.left] = function ()
            if currentSel ~= 1
            then
                SetSel(-1)
            end
        end,
        [keys.right] = function ()
            if currentSel ~= #CurrentPage
            then
                SetSel(1)
            end
        end,
        [keys.enter] = function ()
            local bool,mess = CurrentPage[currentSel]:trigger()
            if bool == false
            then
                Menu_window:upDate(false)
                error(mess,4)
            end
            CurrentPage[currentSel]:OverRide_status(true)
            Menu_window:redraw()
        end,
        [keys.up] = function ()
            if CurrentPage_n ~= #pages
            then
                SetPage(1)
            end
        end,
        [keys.down] = function ()
            if CurrentPage_n ~= 1
            then
                SetPage(-1)
            end
        end,
    },
    ["mouse_click"] = function (events)
        if previous_button:isClicked(table.unpack(events))
        then
            previous_button:trigger()
        elseif next_button:isClicked(table.unpack(events))
        then
            next_button:trigger()
        else
            for _,v in pairs(CurrentPage) do
                local Current_status = v:isActive()
                if v:isClicked(table.unpack(events))
                then
                    local bool,mess = v:trigger()
                    if bool == false
                    then
                        Menu_window:upDate(false)
                        error(mess,4)
                    end
                    v:OverRide_status(Current_status) -- restores the status of the button to active
                    Menu_window:redraw()
                end
            end
        end
    end,

}

while run do
    for _,v in pairs(CurrentPage) do
        v:redraw()
    end
    local events = table.pack(BIOS.pullEvent())
    local filter_actions = event_list[events[1]]
    local action
    if filter_actions
    then
        if type(filter_actions) == "table"
        then
            action = filter_actions[events[2]]
        else
            action = filter_actions
        end
    end
    if action
    then
        action(events)
    end
end
do -- time to set the first_time_flag

end

return true
