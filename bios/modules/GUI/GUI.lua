---@diagnostic disable: duplicate-set-field, undefined-field

---@diagnostic disable-next-line: undefined-field
local native = type(term) == "function" and term() or type(term.current) == "function" and term.current() or type(term.native) == "function" and term.native() or type(term.native) == "table" and term.native or term
local util = require and require("modules.utilties") or dofile("bios/modules/utilties.lua")
local expect = (require and require("modules.expect2") or dofile("bios/modules/expect2.lua"))
local range = expect.range
local field = expect.field
---@diagnostic disable-next-line: cast-local-type
expect = expect.expect

---@diagnostic disable-next-line: param-type-mismatch
native = util.table.copy(native)

local GUI
---@diagnostic disable-next-line: param-type-mismatch
local function isColor(color)
    if not util.color.isColor(color)
    then
        error(("%s: invalid color"):format(color),3)
    end
end
---@class terminal

local function restorePallet(terminal)
    for i,v in pairs(terminal.color.palette) do
        if util.color.isColor(i)
        then
            native.setPaletteColor(i,table.unpack(v))
        end
    end
end
-- this is a custom terminal and will return a window
---@class terminal
local terminal = setmetatable({},{__disableSetMeta = true})
setmetatable(native,{__index = GUI})
GUI = setmetatable({
    window = {
        x = 1,
        y = 1,
        width = select(1,native.getSize()),
        height = select(2,native.getSize())
    },
    pixels = {},
    color = {back = colors.black,palette = util.table.setType({},"palette")},
    visible = false,
    children = setmetatable({},{__mode = "v"})
},{__index = terminal})
function GUI.getSize()
    return native.getSize()
end
function GUI.setNatvieTable(Tbl)
    expect(true,1,Tbl,"table","monitor")
    native = util.table.copy(Tbl)
end
function GUI.reposition()
    return true
end
function GUI.getABS()
    return 1,1
end
function GUI.isVisible()
    return true  
end
function GUI.redrawAll()
    return true
end

--- builds a terminal to draw to
util.table.setType(GUI,"terminal")
function terminal:clear(_redrawChildren)
    expect(false,1,_redrawChildren,"boolean","nil")
    self.pixels = {}
    self:redraw(_redrawChildren)
end
function terminal:reset()
    self.children = {}
    self:redraw(false)
end
function terminal:getSize()
    return self.window.width,self.window.height
end
function terminal:redraw(_redrawChildren)
    local nativeColor = native.getBackgroundColor()
    if self:isVisible()
    then
        local aX,aY = self:getABS()
        local x,y = self:getSize()
        local CBG = self:getBackgroundColor()
        restorePallet(self)
        for i = 1,y do
            for C = 1,x do
                native.setCursorPos(aX+(C-1),aY+(i-1))
                if self.pixels[i] and self.pixels[i][C]
                then
                    native.setBackgroundColor(self.pixels[i][C])
                else
                    native.setBackgroundColor(CBG)
                end
                native.write("\t")
            end
        end
        if self.children and type(_redrawChildren) == "nil" or _redrawChildren == true
        then
            for _,v in pairs(self.children) do
                v:redraw()
            end
        end
    end
    native.setBackgroundColor(nativeColor)
end
function terminal:getPosition()
    return self.window.x,self.window.y
end
function terminal:isColor()
    return native.isColor()
end
---comment
---@param color number
---@param r number
---@param g number
---@param b number
function terminal:setPaletteColor(color,r,g,b)
    expect(false,1,color,"number")
    isColor(color)
    self.color.palette[color] = table.pack(r,g,b)
end
---comment
---@param color number
function terminal:getPaletteColor(color)
    expect(false,1,color,"number")
    isColor(color)
    return table.unpack(self.color.palette[color])
end
---comment
---@param color number
function terminal:setBackgroundColor(color)
    expect(false,1,color,"number")
    isColor(color)
    self.color.back = color
end
---comment
---@return number
function terminal:getBackgroundColor() 
    return self.color.back
end
---comment
---@param color number
---@param x number
---@param y number
function terminal:setPixel(color,x,y)
    expect(true,0,self,"terminal")
    expect(false,1,color,"number")
    expect(false,2,x,"number")
    expect(false,3,y,"number")
    do
        local Rx,Ry = self:getSize()
        range(2,x,0,Rx)
        range(3,y,0,Ry)
    end
    self.pixels[y] = self.pixels[y] or {}
    self.pixels[y][x] = color
end
function terminal:getCenter()
    local Sx,Sy = self:getSize()
    local x = math.ceil(Sx/2)
    local y = math.ceil(Sy/2)
    return ((x > 0  and x) or 1),((y > 0  and y) or 1)
end 
---comment
---@param bTrue boolean
---@return boolean
function terminal:setVisible(bTrue)
    expect(false,1,bTrue,"boolean")
    self.visible = bTrue
    return true
end

-- this creates a new instance of the Parent window and then stores the new window as a child in the Parent
-- the child table is a weak table meaning when you close the window the garbage will clean it out
---comment
---@param nX number
---@param nY number
---@param nWidth number
---@param nHeight number
---@param Visible boolean|nil
function terminal:create(nX,nY,nWidth,nHeight,Visible)
    expect(true,0,self,"terminal")
    expect(false,1,nX,"number")
    expect(false,2,nY,"number")
    expect(false,3,nWidth,"number")
    expect(false,4,nHeight,"number")
    expect(false,5,Visible,"boolean","nil")
    local instance
    do
        local x,y = self:getSize()
        range(1,nX,1,x)
        range(2,nY,1,y)
        range(3,nWidth,1,x)
        range(4,nHeight,1,y)
    end
    instance = setmetatable({
        window = {
            x = nX,
            y = nY,
            width = nWidth,
            height = nHeight,
        },
        pixels = {},
        color = {back = colors.white,palette = util.table.copy(self.color.palette,true)},
        visible = Visible or false,
        children = setmetatable({},{__mode = "v"})
    },{__index = terminal})
    util.table.setType(instance,"terminal")
    table.insert(self.children,instance)
    function instance.reposition(new_x,new_y,new_width,new_height,new_Parent)
        expect(false,1,new_x,"number")
        expect(false,2,new_y,"number")
        expect(false,3,new_width,"number")
        expect(false,4,new_height,"number")
        expect(false,5,new_Parent,"terminal","nil")
        do
            local x,y
            if new_Parent
            then
                x,y = new_Parent:getSize()
            else
                x,y = self:getSize()
            end
            range(1,new_x,1,x)
            range(2,new_y,1,y)
            range(3,new_width,1,x)
            range(4,new_height,1,y)
        end
        instance.window.x = new_x
        instance.window.y = new_y
        instance.window.width = new_width
        instance.window.height = new_height
        if new_Parent
        then
            self.children[select(2,util.table.find(self.children,instance))] = nil
            self = new_Parent
            table.insert(self.children,instance)
        end
        self:redraw()
        return true
    end
    function instance.getABS()
        local x,y = instance:getPosition()
        local Px,Py = self:getABS()
        return Px+(x-1),Py+(y-1)
    end
    function instance.isVisible()
        if self:isVisible()
        then
            return instance.visible
        end
        return false
    end
    function instance.redrawParent()
        return self:redraw()
    end
    return instance
end

-- just prepares the Parent for use
do
    for _,v in pairs(colors) do
        if type(v) == "number" and util.color.isColor(v)
        then
            GUI:setPaletteColor(v,native.getPaletteColor(v))
        end
    end
end

-- turns a terminal into a window to draw text to
---@class window
---@diagnostic disable-next-line: assign-type-mismatch
local window = setmetatable({},{__index = terminal})
---@diagnostic disable-next-line: duplicate-set-field
function window:clear()
    expect(true,0,self,"window")
    self.lines = {}
    self:redraw()
end
function window:clearLine()
    expect(true,0,self,"window")
    local y = select(self:getCursorPos())
    if self.lines[y]
    then
        self.lines[y] = nil
    end
    self:redrawLine()
end
function window:getCursorBlink()
    expect(true,0,self,"window")
    return self.Cursor.Blink
end
function window:getCursorPos()
    expect(true,0,self,"window")
    return self.Cursor.pos.x,self.Cursor.pos.y
end

---comment
---@return table
function window:getLine()
    expect(true,0,self,"window")
    local y = select(2,self:getCursorPos())
    return self.lines[y]
end
---comment
---@return number
function window:getTextColor()
    expect(true,0,self,"window")
    return self.color.text
end
function window:getOffset()
    return self.window.Offset.x,self.window.Offset.y
end
---@diagnostic disable-next-line: duplicate-set-field
function window:redraw()
    expect(true,0,self,"window")
    if self:isVisible()
    then
        local CBG,CTG = native.getBackgroundColor(),native.getTextColor()
        restorePallet(self)
        local x,y = self:getSize()
        local Ax,Ay = self:getABS()
        local offX,offY = self:getOffset()
        local CX,CY = 1,1
        local CBC = self:getBackgroundColor()
        while true do
            if CX > x
            then
                CX = 1
                CY = CY + 1
                if CY > y
                then
                    break
                end
            end
            local Tbl = (self.lines[CY+offY] or {})[CX+offX]
            native.setCursorPos(Ax+(CX-1),Ay+(CY-1))
            if Tbl
            then
                native.setBackgroundColor(Tbl.color.back)
                native.setTextColor(Tbl.color.text)
                native.write(Tbl.Char)
            else
                native.setBackgroundColor(CBC)
                native.write("\t")
            end
            CX = CX + 1
        end
        native.setBackgroundColor(CBG)
        native.setTextColor(CTG)
    end

end
function window:redrawLine()
    expect(true,0,self,"window")
    if self:isVisible()
    then
        local CBG,CTG = native.getBackgroundColor(),native.getTextColor()
        local y = select(2,self:getCursorPos())
        local offX,offY = self:getOffset()
        local Tbl = self.lines[y+offY] or {}
        offY = nil
        local x = self:getSize()
        local Cx,count= 1,1
        restorePallet(self)
        local Y,Ax
        do
            local U,Ay = self:getABS()
            Ax = U
            Y = Ay+(y-1)
        end
        local CBC,CTC = self:getBackgroundColor(),self:getTextColor()
        while true do
            if Cx > x
            then
                break
            end
            native.setCursorPos(Ax+(Cx-1),Y)
            local CT = Tbl[count+offX]
            if not CT
            then
                native.setBackgroundColor(CBC)
                native.setTextColor(CTC)
                native.write("\t")
            else
                native.setBackgroundColor(CT.color.back)
                native.setTextColor(CT.color.text)
                native.write(CT.Char)
            end
            count = count + 1
            Cx = Cx + 1
        end
        native.setBackgroundColor(CBG)
        native.setTextColor(CTG)
    end
end
function window:restoreCursor()
    expect(true,0,self,"window")
    if self:isVisible()
    then
        restorePallet(self)
        native.setBackgroundColor(self:getBackgroundColor())
        native.setTextColor(self:getTextColor())
        do
            local Ax,Ay = self:getABS()
            local x,y = self:getCursorPos()
            native.setCursorPos(Ax+(x-1),Ay+(y-1))
        end
        native.setCursorBlink(self:getCursorBlink())
    end
    return true
end
---comment
---@param _n number
function window:setOffset(offX,offY)
    expect(false,1,offX,"number","nil")
    expect(false,2,offY,"number","nil")
    do
        local SizeX,SizeY = self:getSize()
        offX = offX and range(1,offX,0,SizeX) or offX
        offY = offY and range(2,offY,0,SizeY) or offY
    end
    self.window.Offset.x = offX or self.window.Offset.x
    self.window.Offset.y = offY or self.window.Offset.y
    self:redraw()
end
---comment
-- this is used to make a new line to bypass
-- write function that would be required
--this will attach the line to the bottem of the line window
function window:newLine()
    self.lines[#self.lines+1] = {}
end
---comment
--- enables the cursor view and blinking
---@param bTrue boolean
function window:setCursorBlink(bTrue)
    expect(true,0,self,"window")
    expect(false,1,bTrue,"boolean")
    self.Cursor.Blink = bTrue
end
---comment
--- moves the Cursor to the requested position
---@param nX number
---@param nY number
function window:setCursorPos(nX,nY)
    expect(true,0,self,"window")
    expect(false,1,nX,"number","nil")
    expect(false,2,nY,"number","nil")
    do
        local x,y = self:getSize()
        nX = nX and range(1,nX,1,x)
        nY = nY and range(1,nY,1,y)
    end
    self.Cursor.pos.x = nX or self.Cursor.pos.x
    self.Cursor.pos.y = nY or self.Cursor.pos.y
end
---comment
---@param color number
function window:setTextColor(color)
    expect(true,0,self,"window")
    isColor(color)
    self.color.text = color
end
---comment
---@param sText string
---@param bOverWrite boolean
---@param keepPos boolean|nil
function window:write(sText,bOverWrite,keepPos)
    expect(true,0,self,"window")
    expect(false,1,sText,"string")
    expect(false,2,bOverWrite,"boolean","nil")
    local result = util.string.split(sText)
    local flagLines = false
    local X,Y = self:getCursorPos()
    do
        --- writes the sentece to the table
        -- one charator at a time
        local flagOffset = false
        self.lines[Y] = self.lines[Y] or {}
        local offX,offY = self:getOffset()
        local windowlengh = self:getSize()
        local CB,CT = self:getBackgroundColor(),self:getTextColor()
        for index=1,#sText do
            if not self.lines[Y+offY]
            then
                self.lines[Y+offY] = {}
            end
            if result[index] == "\b"
            then
                if X == windowlengh and offX > 0
                then
                    offX = offX - 1
                elseif X > 1
                then
                    X = X - 1
                end
                table.remove(self.lines[Y+offY],(X+offX))
            elseif result[index] == "\n"
            then
                Y = Y + 1
                X = 1
                flagLines = true
                self.lines[Y+offY] = self.lines[Y+offY] or {}
                if offX > 0
                then
                    offX = 0
                    flagOffset = true
                end
            elseif not bOverWrite
            then
                table.insert(self.lines[Y+offY],(X+offX),{
                    Char = result[index],
                    color = {back = CB,text = CT}
                })
                if X == windowlengh
                then
                    offX = offX + 1
                    flagOffset = true
                else
                    X = X + 1
                end
            else
                self.lines[Y+offY][X+offX] = {
                    Char = result[index],
                    color = {back = CB,text = CT}
                }
                if X == windowlengh
                then
                    offX = offX + 1
                    flagOffset = true
                else
                    X = X + 1
                end
            end
        end
        if flagOffset
        then
            self:setOffset(offX)
        end
        if not keepPos
        then
            self:setCursorPos(X,Y)
        end
    end
    -- requests a redraw
    if self:isVisible()
    then
        if not flagLines -- dose not runs if only one line was effected
        then
            self:redrawLine()
        else
            self:redraw()
        end
    end
end
---comment
---@param self terminal
function terminal:make_textBox()
    expect(true,0,self,"terminal")
    do
        local meta = getmetatable(self) or {}
        meta.__index = window
        setmetatable(self,meta)
    end
    util.table.setType(self,"window")
    self.window.Offset = {}
    self.window.Offset.x = 0
    self.window.Offset.y = 0
    self.lines = {}
    self.Cursor = {pos = {x = 1,y = 1},Blink = false}
    self.color.text = colors.black
    self.pixels = nil
    self.children = nil
end



-- turns a terminal into a button
---@class button
---@diagnostic disable-next-line: assign-type-mismatch
local button = setmetatable({},{__index = terminal})
---@diagnostic disable-next-line: duplicate-set-field
---comment
---@param color number
function button:setTextColor(color)
    expect(false,1,color,"number")
    self.color.text = color
end
---comment
---@param sText string
function button:setText(sText)
    expect(false,1,sText,"string")
    self.text = sText
end
function button:redraw()
    if self.self:isVisible()
    then
        local SX,SY = self.self:getSize()
        local APX,APH = self.self:getABS()
        local Cx,Cy = self.self:getCenter()
        local CTC = native.getTextColor()
        local CBC = native.getBackgroundColor()
        restorePallet(self.self)
        native.setBackgroundColor(self.color.back)
        for y = 1,SY do
            for x = 1,SX do
                native.setCursorPos(APX+(x-1),APH+(y-1))
                native.write("\t")
            end
        end
        if self.text and self.text:len() <= SX
        then
            native.setTextColor(self.color.text or colors.black)
            native.setCursorPos(APX+(Cx-((self.text:len()/2))),APH+Cy-1)
            native.write(self.text)
        end
        native.setTextColor(CTC)
        native.setBackgroundColor(CBC)
    end
end
function button:setID(_n)
    expect(false,1,_n,"number","string")
    self.self.ID = _n
end
function button:getID()
    return self.self.ID
end
---comment
---@param fn function
function button:setActivate(fn)
    expect(false,1,fn,"function")
    self.self.Activate = fn
end
---comment
---@param fn function
function button:setDeactivate(fn)
    expect(false,1,fn,"function")
    self.self.Deactivate = fn
end

---comment
---@param self terminal
function terminal:make_button(bToggle)
    expect(true,0,self,"terminal")
    expect(false,1,bToggle,"boolean","nil")
    self.self = self
    self.selected = setmetatable({
        self = self,
        text = "button",
        color = {
            text = colors.red,
            back = colors.yellow,
        },
    },{__index = button})
    self.default = setmetatable({
        self = self,
        text = "button",
        color = {
            text = colors.blue,
            back = colors.green,
        },
    },{__index = button})
    self.toggle = bToggle or false
    self.active = false
    self.Activate = function ()
        return nil
    end
    local ID
    self.pixels = nil
    self.text = "term"
    self.ID = ID
    self.children = nil
    setmetatable(self,{__index = button})
    util.table.setType(self,"button")
    return ID
end
--progress Bar
local progress_bar = setmetatable({},{__index = terminal})
---@diagnostic disable-next-line: duplicate-set-field
function progress_bar:redraw()
    local orginBackgroundColor = native.getBackgroundColor()
    local x = self:getSize()
    local count = math.floor((self.checkpoints_filled/self.checkpoints)*x)
    native.setCursorPos(self.getABS())
    native.setBackgroundColor(self:getBackgroundColor())
    native.write(("\t"):rep(x))
    native.setBackgroundColor(self.color.filled)
    native.setCursorPos(self.getABS())
    native.write(("\t"):rep(count))
    native.setBackgroundColor(orginBackgroundColor)
end
---comment
---@param _n number|nil
function progress_bar:checkPoint(_n)
    expect(false,1,_n,"number","nil")
    if self.checkpoints == self.checkpoints_filled
    then
        error("can't go beyond 100%",2)
    end
    self.checkpoints_filled = self.checkpoints_filled + (_n or 1)
end
function progress_bar:setfilledColor(color)
    expect(false,1,color,"number")
    self.color.filled = color
end
function terminal:make_progressBar(_nCheckpoints)
    expect(true,0,self,"terminal")
    expect(false,1,_nCheckpoints,"number")
    self.children = nil
    self.pixels = nil
    self.checkpoints = _nCheckpoints
    self.checkpoints_filled = 0
    self.color.filled = colors.blue
    self:setBackgroundColor(colors.green)
    setmetatable(self,{__index = progress_bar})
    util.table.setType(self,"progress_bar")
end

function terminal:Usrinput(_sContent,Tblsettings)
    expect(true,0,self,"terminal")
    _sContent = expect(false,1,_sContent,"string,","nil") or ""
    Tblsettings = expect(false,2,Tblsettings,"table","nil") or {}
    Tblsettings.prompt = field(2,Tblsettings,"prompt","string","nil") or "Usr input Screen"
    Tblsettings.BackgroundColor = field(2,Tblsettings,"BackgroundColor","number","nil") or colors.black
    Tblsettings.textColor = field(2,Tblsettings,"textColor","number","nil") or colors.white
    Tblsettings.autoBackground_Color = field(2,Tblsettings,"autoBackground_Color","number","nil") or colors.gray
    Tblsettings.menu = field(2,Tblsettings,"menuoptions","table","nil") or {}
    local getList = field(2,Tblsettings,"_fnAuotList","function","nil") or function (currentWord)
        return nil
    end
    local speicalList = field(2,Tblsettings,"_SpeicalList","function","nil") or function (currentWord)
        return nil
    end
    for _,v in pairs(Tblsettings.menu) do
        xpcall(expect,function (_sMessage)
            error(("Tblsettings.menu :%s"):format(_sMessage),3)
        end,false,0,v,"function")
    end
    local CurrentAutoList,currentAutoSel = {},1
    local flagAutoComplete = false
    local prompt,Usrinput,oppMenu
    local function retCurrentWord()
        local Line,sentence = nil,""
        do
            local CursorPosY = select(1,Usrinput:getCursorPos())
            Line = Usrinput.lines[CursorPosY] or {}
        end
        for _,obj in pairs(Line) do
            sentence = sentence..obj.Char
        end
        Line = util.string.split(sentence,"\t")
        return Line[#Line]
    end
    local function clearAuto()
        local lengthAuto = #CurrentAutoList[currentAutoSel]
        local CursorPosX,CursorPosY = Usrinput:getCursorPos()
        Usrinput:setCursorPos(CursorPosX+lengthAuto,CursorPosY)
        Usrinput:write(("\b"):rep(lengthAuto))
        flagAutoComplete = false
    end
    local function autoFill(_nIndex,_nOffSet)
        if not CurrentAutoList
        then
            return
        end
        _nIndex = _nIndex or 1
        local stri = CurrentAutoList[_nIndex]
        if not stri
        then
            return false
        end
        do
            if _nOffSet and _nOffSet > #stri
            then
                return false
            end
            stri = table.concat(util.string.split(stri),"",_nOffSet or 1)
        end
        currentAutoSel = _nIndex
        flagAutoComplete = true
        Usrinput:setBackgroundColor(Tblsettings.autoBackground_Color)
        Usrinput:write(stri,_nOffSet and true or false,not _nOffSet and true or false)
        Usrinput:setBackgroundColor(Tblsettings.BackgroundColor)
        return true
    end
    local run = true
    local result = ""
    Tblsettings.menu.exit = function ()
        if flagAutoComplete
        then
            clearAuto()
        end
        for index,y in pairs(Usrinput.lines) do
            if index > 1
            then
                result = result.."\n"
            end
            for _,x in pairs(y) do
                result = result..x.Char
            end
        end
        run = false
    end
    do -- builds the windows
        local termSizeX,termSizeY = self:getSize()
        prompt = self:create(1,1,termSizeX,1,true)
        prompt:make_textBox()
        prompt:setCursorPos(select(1,prompt:getCenter())-#Tblsettings.prompt/2,1)
        prompt:write(Tblsettings.prompt)
        Usrinput = self:create(1,2,termSizeX,termSizeY-1,true)
        Usrinput:make_textBox()
        Usrinput:setCursorBlink(true)
        Usrinput:setBackgroundColor(Tblsettings.BackgroundColor)
        Usrinput:setTextColor(Tblsettings.textColor)
        local term_CenterX,term_CenterY = self:getCenter()
        local menuCount = 4
        for _,_ in pairs(Tblsettings.menu) do
            menuCount = menuCount + 1
        end
        oppMenu = self:create(term_CenterX-5,term_CenterY-menuCount/2,10,menuCount)
    end
    do -- puts the content into the Usrinput textBox
        local result_contect = util.string.split(_sContent)
        for _,char in pairs(result_contect) do
            Usrinput:write(char,nil,true)
        end
    end
    local auto_depth = 0 -- for autoComplete_managment
    local keyHandle = {
        [keys.up] = function ()
            if flagAutoComplete
            then
            else
                local CursorPosX,CursorPosY = Usrinput:getCursorPos()
                local offset = select(2,Usrinput:getOffset())
                if CursorPosY == 1 and offset > 0
                then
                    Usrinput:setOffset(nil,offset - 1)
                elseif CursorPosY > 1
                then
                    Usrinput:setCursorPos(CursorPosX,CursorPosY - 1)
                end
            end
        end,
        [keys.down] = function ()
            if flagAutoComplete
            then
            else
                local CursorPosX,CursorPosY = Usrinput:getCursorPos()
                local windowHeight = select(2,Usrinput:getSize())
                local offset = select(2,Usrinput:getOffset())
                if Usrinput.lines[CursorPosY+offset+1]
                then
                    if CursorPosY  == windowHeight
                    then
                        Usrinput:setOffset(nil,offset+1)
                    else
                        Usrinput:setCursorPos(CursorPosX,CursorPosY+1)
                    end
                end
            end
        end,
        [keys.left] = function ()
            if flagAutoComplete
            then
            else
                local CursorPosX,CursorPosY = Usrinput:getCursorPos()
                local Offset = Usrinput:getOffset()
                if CursorPosX == 1 and Offset > 0
                then
                    Usrinput:setOffset(Offset-1)
                elseif CursorPosX > 1
                then
                    Usrinput:setCursorPos(CursorPosX-1,CursorPosY)
                end
            end
        end,
        [keys.right] = function ()
            if flagAutoComplete
            then
            else
                local CursorPosX,CursorPosY = Usrinput:getCursorPos()
                local windowlengh = Usrinput:getSize()
                local OffsetX,OffsetY = Usrinput:getOffset()
                if Usrinput.lines[CursorPosY+OffsetY][CursorPosX+OffsetX+1]
                then
                    if CursorPosX == windowlengh
                    then
                        Usrinput:setOffset(OffsetX+1)
                    else
                        Usrinput:setCursorPos(CursorPosX+1,CursorPosY)
                    end
                end
            end
        end,
        [keys.leftCtrl] = function ()
            parallel.waitForAny(function ()
                while true do
                    local Events = select(2,os.pullEventRaw("key"))
                    if Events == keys.leftCtrl
                    then
                        oppMenu:setVisible(false)
                        self:redraw(true)
                        break
                    end
                end
            end,function ()
                local list = {}
                for name,_ in pairs(Tblsettings.menu) do
                    table.insert(list,name)
                end
                local choice = list[oppMenu:run_list(list)]
                choice = Tblsettings.menu[choice]
                choice()
            end)
        end,
        [keys.backspace] = function ()
            if flagAutoComplete
            then
                clearAuto()
            end
            local CursorPosX,CursorPosY = Usrinput:getCursorPos()
            if CursorPosX == 1 and CursorPosY > 1
            then
                local OffsetY = select(2,Usrinput:getOffset())
                local lastLineLength = #Usrinput.lines[CursorPosY+OffsetY-1]
                local windowlengh = select(2,Usrinput:getSize())
                if OffsetY > 0
                then
                    OffsetY = OffsetY - 1
                    Usrinput:setOffset(nil,OffsetY)
                else
                    Usrinput:setCursorPos(nil,CursorPosY-1)
                end
                if lastLineLength > windowlengh
                then
                    Usrinput:setOffset(lastLineLength-windowlengh)
                    Usrinput:setCursorPos(windowlengh)
                else
                    Usrinput:setCursorPos(lastLineLength+1)
                end
                Usrinput:write("\b")
            end
            Usrinput:write("\b")
        end,
        [keys.tab] = function ()
            if flagAutoComplete
            then
                local auto_result
                do
                    local auto_word = CurrentAutoList[currentAutoSel]
                    local compare = #auto_word-auto_depth
                    auto_result = table.concat(util.string.split(auto_word),"",compare)
                end
                Usrinput:write(auto_result,true)
                auto_depth = 0            
                flagAutoComplete = false
            end
        end,
        [keys.enter] = function ()
            if flagAutoComplete
            then
                clearAuto()
            end
            Usrinput:write("\n")
        end,
        [keys.home] = function ()
            if flagAutoComplete
            then
                clearAuto()
            end
            local CursorPosY = select(2,Usrinput:getCursorPos())
            if select(1,Usrinput:getOffset()) > 0
            then
                Usrinput:setOffset(0)
            end
            Usrinput:setCursorPos(1,CursorPosY)
        end,
        [keys["end"]] = function ()
            if flagAutoComplete
            then
                clearAuto()
            end
            local XoffSet = select(2,Usrinput:getOffset())
            
        end,
        [keys.delete] = function ()
        end
    }
    parallel.waitForAny(function ()
        while true do
            Usrinput:restoreCursor()
            coroutine.yield()
        end
    end,function ()
        while run do
            local Events = table.pack(os.pullEventRaw())
            if Events[1] == "char" and not flagAutoComplete
            then
                if flagAutoComplete
                then
                    clearAuto()
                end
                Usrinput:write(Events[2])
                CurrentAutoList = getList(retCurrentWord())
                autoFill()
            elseif Events[1] == "key"
            then
                local fn = keyHandle[Events[2]] 
                if fn
                then
                    fn()
                end
            elseif Events[1] == "mouse_click" and not flagAutoComplete
            then
            end
        end
    end)
    if result == "\n"
    then
        return ""
    end
    return result
end

--[[
    built in functions
    thse come with the module 
    these are basic functions not made for any specific purpose
--]]

---comment
---@param mess string
---@param Tblsettings table|nil
---@return string|nil
function terminal:prompt(mess,Tblsettings)
    expect(true,0,self,"terminal")
    expect(false,1,mess,"string")
    Tblsettings = expect(false,2,Tblsettings,"table","nil") or {}
    field(2,Tblsettings,"BTC","number","nil")
    field(2,Tblsettings,"BPC","number","nil")
    field(2,Tblsettings,"TC","number","nil")
    field(2,Tblsettings,"PC","number","nil")
    self:setVisible(true)
    local sX,sY = self:getSize()
    range(0,sY,2)
    local prompt  = self:create(1,1,sX,1,true)
    prompt:make_textBox()
    prompt:setBackgroundColor(Tblsettings.BTC or colors.blue)
    prompt:setTextColor(Tblsettings.PC or colors.white)
    do
        local Cx = select(1,prompt:getCenter())
        prompt:setCursorPos(math.floor(Cx-(#mess/2)+1),1)
    end
    prompt:write(mess)
    local input = self:create(1,2,sX,sY,true)
    input:make_textBox()
    input:setBackgroundColor(Tblsettings.BTC or colors.gray)
    input:setCursorBlink(true)
    input:setTextColor(Tblsettings.TC or colors.white)
    input:redraw()
    input:setCursorBlink(true)
    parallel.waitForAny(function ()
        while true do
            input:restoreCursor()
            coroutine.yield()
        end
    end,function ()
        while true do
            local event = table.pack(os.pullEvent())
            if self:isVisible()
            then
                if event[1] == "char"
                then
                    local CX,CY = input:getCursorPos()
                    if CX <= sX and CY <= sY
                    then
                        input:write(event[2],true)
                        CX = CX + 1
                        if CX > sX
                        then
                            CX = 1
                            CY = CY + 1
                        end
                        if CX <= sX and CY <= sY
                        then
                            input:setCursorPos(CX,CY)
                        end
                    end
                elseif event[1] == "key"
                then
                    if event[2] == keys.backspace
                    then
                        input:write("\b")
                    elseif event[2] == keys.enter
                    then
                        local Temp = ""
                        for _,v in pairs(input.lines) do
                            for _,b in pairs(v) do
                                Temp = Temp..b.Char
                            end
                        end 
                        return Temp
                    end
                end
            end
        end
    end)
end

-- you only get this api if you are a advance computer
-- it only uses the mouse_click event 
if native.isColor()
then
    ---comment
    ---@param bnot_Loop boolean|nil
    ---@param ... table|button
    ---@return unknown
    function GUI.buttonRun(bnot_Loop,...)
    expect(false,1,bnot_Loop,"boolean")
    local Pages = {}
    do
        local argus = {...}
        for i,v in pairs(argus) do
            expect(false,i+1,v,"table")
        end
        if #argus == 0
        then
            error("no button APIs",2)
        end
        if util.table.getType(argus[1]) ~= "button"
        then
            for _,v in pairs(argus[1]) do
                if util.table.getType(v) == "button"
                then
                    table.insert(Pages,v)
                end
            end
            if #Pages == 0
            then
                error("button APIs not found",2)
            end
        else
            for _,v in pairs(argus) do
                if util.table.getType(v) == "button"
                then
                    table.insert(Pages,v)
                end
            end
        end
    end
    for _,v in pairs(Pages) do
        v.self:setVisible(true)
    end
    local choice
    parallel.waitForAny(
        function ()
            while true do
                for _,v in pairs(Pages) do
                    if v.active
                    then
                        v.selected:redraw()
                    else
                        v.default:redraw()
                    end
                end
                coroutine.yield()
            end
        end,
        function ()
            local run = true
            while run do
                local event = table.pack(os.pullEventRaw())
                if event[1] == "mouse_click" or event[1] == "monitor_touch"
                then
                    for _,v in pairs(Pages) do
                        local Px,Py = v.self:getABS()
                        local Sx,SY = v.self:getSize()
                        local x,y = event[3],event[4]
                        if x >= Px and x <= (Sx+Px)-1 and y >= Py and y <= (SY+Py)-1 and v:isVisible()
                        then
                            if v.self.toggle
                            then
                                if v.self.active
                                then
                                    v.self.active = false
                                    v.self.Deactivate()
                                else
                                    v.self.active = true
                                    v.self.Activate()
                                end
                            else
                                v.selected:redraw()
                                coroutine.yield()
                                v.self.Activate()
                            end
                            choice = v:getID()
                            if not bnot_Loop
                            then
                                run = false
                                break
                            end
                        end
                    end
                end
            end
        end
    )
    return choice
    end
end


---comment
---@param self terminal
---@param OTbl table|terminal
---@param TblSettings table|nil
function terminal:run_list(OTbl,TblSettings) 
    expect(true,0,self,"terminal")
    expect(false,1,OTbl,"table")
    TblSettings = expect(false,2,TblSettings,"table","nil") or {}
    field(2,TblSettings,"OTC","number","nil")
    field(2,TblSettings,"OBC","number","nil")
    field(2,TblSettings,"MBC","number","nil")
    field(2,TblSettings,"MTC","number","nil")
    if TblSettings.help
    then
        local stri = "\n"
        local function Add(mess,Type,meaning)
            stri = stri..("[\"%s\"] = \"%s\",meaning:%s\n"):format(mess,Type,meaning)
        end
        Add("message","string nil","will be displayed on the first row")
        Add("MBC","number nil","message_BackgroundColor")
        Add("MTC","number nil","message_TextColor")
        Add("OTC","number nil","option_textColor")
        Add("OBC","number nil","option_backgeoundColor")
        error(("table of settings %s"):format(stri),0)
    end
    TblSettings = expect(false,2,TblSettings,"table","nil") or {}
    if #OTbl == 0
    then
        error("table is empty",2)
    end
    self:setVisible(true)
    local x,y = self:getSize()
    range(0,y,2)
    local Pages = {{}}
    local textWindow = self:create(1,1,x,1,true)
    textWindow:make_textBox()
    local canv = self:create(1,2,x,y-2,true)
    canv:setBackgroundColor(self:getBackgroundColor())
    local Page = self:create(1,y,x,1,true)
    Page:make_textBox()
    Page:setBackgroundColor(TblSettings.MBC or colors.white)
    Page:setTextColor(TblSettings.MTC or colors.black)
    do -- sperates the tbl into pages
        local PagesCount = 1
        local Cy = 1
        for i,v in pairs(OTbl) do
            if Cy > y-2
            then
                Cy = 1
                PagesCount = PagesCount + 1
                Pages[PagesCount] = {}
            end
            local temp = canv:create(1,Cy,x,1,true)
            temp:make_button()
            temp.selected:setText(v)
            temp.default:setText(v)
            temp:setID(i)
            table.insert(Pages[PagesCount],temp)
            Cy = Cy + 1
        end
    end
    local left,right,smallScreen
    local otpLen = #Pages
    local CurrentPage,currentSel = 1,1
    local function setPage(n)
        canv:clear(false)
        for _,v in pairs(Pages[CurrentPage]) do
            v:setVisible(false)
        end
        CurrentPage = CurrentPage + n
        for i,v in pairs(Pages[CurrentPage]) do
            v:setVisible(true)
            if v.active
            then
                currentSel = i
            end
        end
        currentSel = currentSel or 1
        Page:clear()
        if not smallScreen
        then
            Page:write(("Page %s of %s"):format(CurrentPage,otpLen))
        else
            Page:write(("%s/%s"):format(CurrentPage,otpLen))
        end
        Page:setCursorPos(1,1)
    end
    do -- builds the page indacator
        local stri = ("Page %s of %s"):format(1,otpLen)
        if #stri <= select(1,Page:getSize())
        then
            Page:write(stri)
        else
            Page:write(("%s/%s"):format(1,otpLen))
            smallScreen = true
        end
        Page:setCursorPos(1,1)
    end
    if otpLen > 1 and GUI.buttonRun
    then
        textWindow.reposition(2,1,x-1,1)
        left = self:create(1,1,1,1,true)
        right = self:create(x,1,1,1,true)
        left:make_button(false)
        right:make_button(false)
        left.default:setText("<")
        left.selected:setText("<")
        right.default:setText(">")
        right.selected:setText(">")
        right:setActivate(function ()
            if CurrentPage < #Pages
            then
                setPage(1)
            end

        end)
        left:setActivate(function ()
            if CurrentPage > 1
            then
                setPage(-1)
            end

        end)
        left:setVisible(true)
        right:setVisible(true)
    end
    do -- builds the prompt window
        local message = field(2,TblSettings,"message","string","nil") or "please choose"
        local x2 = select(1,textWindow:getSize())
        if #message < x2
        then
            local x3,y3 = textWindow:getCenter()
            textWindow:setCursorPos(x3-(#message/2)+1,y3)
            textWindow:setBackgroundColor(TblSettings.MBC or colors.white)
            textWindow:setTextColor(TblSettings.MTC or colors.black)
            textWindow:write(message)
        else
            textWindow = nil
        end
    end
    Pages[1][1].active = true
    self:redraw()
    local selected = 1
    local function start()
        local run = true
        while run do
            if self:isVisible()
            then
                local event = {os.pullEventRaw()}
                if event[1] == "key"
                then
                    if event[2] == keys.down and currentSel < #Pages[CurrentPage]
                    then
                        Pages[CurrentPage][currentSel].active = false
                        currentSel = currentSel + 1
                        Pages[CurrentPage][currentSel].active = true
                    elseif event[2] == keys.up and currentSel > 1
                    then
                        Pages[CurrentPage][currentSel].active = false
                        currentSel = currentSel - 1
                        Pages[CurrentPage][currentSel].active = true
                    elseif event[2]  == keys.enter
                    then
                        selected = Pages[CurrentPage][currentSel]:getID()
                        break
                    elseif event[2] == keys.right and CurrentPage < otpLen
                    then
                        setPage(1)
                    elseif event[2] == keys.left and CurrentPage > 1
                    then
                        setPage(-1)
                    end
                elseif event[1] == "mouse_click"
                then
                    for _,v in pairs(Pages[CurrentPage]) do
                        local Posx,Posy = v.getABS()
                        local sX,sY = v:getSize()
                        sX = (sX + Posx)-1
                        sY = (sY + Posy)-1
                        if event[3] >= Posx and event[3] <= sX and event[4] >= Posy and event[4] <= sY
                        then
                            selected = v:getID()
                            run = false
                            break
                        end
                    end
                end
            else
                coroutine.yield()
            end
        end
    end
    local function redraw()
        while true do
            native.setCursorBlink(false)
            for _,v in pairs(Pages[CurrentPage]) do
                if v.active then
                    v.selected:redraw()
                else
                    v.default:redraw()
                end
            end
            coroutine.yield()
        end
    end
    if GUI.buttonRun and otpLen > 1
    then
        parallel.waitForAny(function ()
            GUI.buttonRun(true,left,right)
        end,start,redraw)
    else
        parallel.waitForAny(start,redraw)
    end
    return selected
end

---time to build the GUI modules
return GUI
