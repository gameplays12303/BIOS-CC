-- general purpose code 
-- this code dose not have a decated purpose
-- it is just simple code that i would use multipul times 

local expect = expect or (require and require("modules.expect2") or BIOS.dofile("bios/modules/expect2.lua"))
local blacklist = expect.blacklist
local field = expect.field
---@diagnostic disable-next-line: cast-local-type
expect = expect.expect
local fs,string,table = fs,string,table
local setmetatable = setmetatable
local getmetatable = getmetatable
local utilties = {}
utilties.String = {}
utilties.Table = {}
utilties.File = {}
utilties.Color = {}
-- strings addons 

---splits a string input no sep value nor _bkeepdelimiters to get a list of chars
---@param inputstr string
---@param sep string|nil
---@param _bkeepdelimiters boolean|nil
---@return table
function utilties.String.split(inputstr, sep,_bkeepdelimiters)
      expect(false,1,inputstr,"string")
      expect(false,2,sep,"string","nil")
      expect(false,3,_bkeepdelimiters,"boolean","nil")
      local t={}
      if not sep
      then
            for char in inputstr:gmatch(".") do
                  table.insert(t, char) end
            return t
      end
      if not _bkeepdelimiters
      then
            for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                  table.insert(t, str)
            end
            return t
      end
      for str in string.gmatch(inputstr,"[^"..sep.."]*"..sep.."?") do
            table.insert(t, str)
      end
      t[#t] = nil
      return t
end
---preps a string for the window
---@param termnial_size number
---@param _sMessage string
---@param CursorPosX number|nil
function utilties.String.wrap(terminal_size,_sMessage,CursorPosX)
      expect(false,1,terminal_size,"number")
      expect(false,2,_sMessage,"string")
      CursorPosX = expect(false,3,CursorPosX,"number","nil") or 0
      local words = utilties.String.split(_sMessage," ",true)
      local result,size = "",0
      while #words > 0 do
            local CurrentWord = table.remove(words,1)
            for char in string.gmatch(CurrentWord,".") do
                  if char == "\n"
                  then
                        CursorPosX = 1
                        size = size + 1
                        result = result.."\n"
                  else
                        CursorPosX = CursorPosX + 1
                        if CursorPosX > terminal_size
                        then
                              CursorPosX = 1
                              size = size + 1
                              result = result.."\n"
                        end
                        result = result..char
                  end
            end
      end
      return result,size
end
---custom built Serializer design to handle selfReferencing tables and functions (using string.dump)
---@param _data any
---@param _Index any
---@return string|unknown
function utilties.String.Serialize(_data,_Index)
      blacklist(false,1,_data,"thread","userdata")
      _Index =  expect(false,2,_Index,"number","nil") or 0
      local indexGag = ("\t"):rep(_Index)
      local actions = {
            ["boolean"] = function ()
                  return tostring(_data)
            end,
            ["string"] = function ()
                  return "\"".._data.."\""
            end,
            ["table"] = function ()
                  local result = "{\n"
                  for i,v in pairs(_data) do
                        if type(v) ~= "table"
                        then
                              if type(i) == "string"
                              then
                                    if string.find(i,"%p") ~= nil
                                    then
                                          result = result.."\t"..indexGag..("[\"%s\"] = "):format(i)..utilties.String.Serialize(v,_Index+1)..",\n"
                                    else
                                          result = result.."\t"..indexGag..("%s = "):format(i)..utilties.String.Serialize(v,_Index+1)..",\n"
                                    end
                              else
                                    result = result.."\t"..indexGag..utilties.String.Serialize(v,_Index+1)..",\n"
                              end
                        end
                  end
                  return result..indexGag.."}"
            end,
            ["function"] = function ()
                  return string.dump(_data)
            end
      }
      actions["number"] = actions["boolean"]
      local action = actions[type(_data)]
      return action and action() or error(("unknown type %s"):format(type(_data)),2)
end
---custom text loader 
---@param _sData string
---@return unknown
function utilties.String.UnSerialize(_sData,_env,name)
      expect(false,1, _sData, "string")
      expect(false,2,_env,"table","nil")
      expect(false,3,name,"string","nil")
      local func,err = BIOS.load("return " .. _sData,("unserialize %s"):format(name or ""),"t",_env)
      if func then
            local ok, result = pcall(func)
            if ok then
                  return result
            end
      end
      return error(err,2)
end
-- fs addons

---gets the created date
---@param sPath string
---@return number
function utilties.File.created(sPath)
      expect(false,1,sPath,"string")
      return fs.attributes(sPath).created
end

---gets the modified date
---@param sPath string
---@return number
function utilties.File.modified(sPath)
      expect(false,1,sPath,"string")
      return fs.attributes(sPath).modified
end
---gets the extension type (.lua)
---@param _sfile string
---@return string
function utilties.File.getExtension(_sfile)
      expect(false,1,_sfile,"string")
      local Table = utilties.String.split(_sfile,"%.",true)
      return Table[2]
end
---gets the root (eg. C:/, Root)
---@param _sPath string
---@return string
function utilties.File.getRoot(_sPath)
      expect(false,1,_sPath,"string")
      return utilties.String.split(_sPath,"/")[1]
end
---gets the name but leaves out the extension
---@param _sfile string
---@return string
function utilties.File.withoutExtension(_sfile)
      expect(false,1,_sfile,"string")
      local Table = utilties.String.split(_sfile,"%.")
      return Table[1]
end

---list everything that's inside a folder and their folders 
---@param sPath string
---@param showFiles boolean|nil
---@param showDirs boolean|nil
---@param showRootDir boolean|nil
---@param showRom boolean|nil
---@return table
function utilties.File.listsubs(sPath,showFiles,showDirs,showRootDir,showRom)
      expect(false,1,sPath,"string")
      expect(false,2,showFiles,"boolean","nil")
      expect(false,3,showDirs,"boolean","nil")
      expect(false,5,showRootDir,"boolean","nil")
      expect(false,6,showRom,"boolean","nil")
      showDirs = showDirs or showRootDir
      if not fs.exists(sPath) then
            error("Could not find"..fs.getName(sPath),2)
      end
      if not fs.isDir(sPath) then
            error(fs.getName(sPath).."is not a directory",2)
      end
      local Table = fs.find(sPath.."/*")
      if not showRom
      then
            local ID = utilties.Table.find(Table,"rom")
            if ID
            then
                  table.remove(Table,ID)
            end
      end
      local list = {}
      if showRootDir
      then
            table.insert(list,sPath)
      end
      for _,v in pairs(Table) do
            if fs.isDir(v)
            then
                  if showDirs
                  then
                        table.insert(list,v)
                  end
                  local list2 = fs.find(fs.combine(v,"*"))
                  for _,i in pairs(list2) do
                        if fs.isDir(i)
                        then
                              table.insert(Table,i)
                        elseif showFiles
                        then
                              table.insert(list,i)
                        end
                  end
            elseif showFiles
            then
                  table.insert(list,v)
            end
      end
      return list
end

---list everything inside a folder
---@param sPath string
---@param showFiles boolean|nil
---@param showDirs boolean|nil
---@return table
function utilties.File.list(sPath,showFiles,showDirs,showPath)
      expect(false,1,sPath,"string")
      expect(false,2,showFiles,"boolean","nil")
      expect(false,3,showDirs,"boolean","nil")
      expect(false,4,showPath,"boolean","nil")
      if not fs.exists(sPath)
      then
            error(("%s : not found"):format(sPath),3)
      end
      if not fs.isDir(sPath)
      then
            error(("%s: is file expected directory"):format(sPath),3)
      end
      local list = fs.find(fs.combine(sPath,"*"))
      local list2 = {}
      for _,v in pairs(list) do
            if fs.isDir(v) and showDirs
            then
                  table.insert(list2,v)
            elseif not fs.isDir(v) and showFiles
            then
                  table.insert(list2,v)
            end
      end
      if not showPath
      then
            for i,v in pairs(list2) do
                  list2[i] = fs.getName(v)
            end
      end
      return list2
end
---wrapps the directory so ".." equals ""
---@param path string
---@return string
function utilties.File.getDir(path)
      expect(false,1,path,"string")
      if fs.getDir(path) == ".."
      then
            return ""
      else
            return fs.getDir(path)
      end
end

---test if a number is a color
---@param color number
---@return boolean
function utilties.Color.isColor(color)
      expect(false,1,color,"number")
      for i,v in pairs(colors) do
            if v == color
            then
                  return i
            end
      end
      return false
end
-- table addons

---looks in the table for a values (dose not check subtables nor the index table)
---@param base table
---@param ID any
---@param strict boolean|nil
---@return string|number|boolean
function utilties.Table.find(base,ID,strict)
      expect(false,1,base,"table")
      for i,v in pairs(base) do
            if type(v) == "string" and type(ID) == "string"
            then
                  if not strict and string.find(ID,i)
                  then
                        return i
                  elseif v == ID
                  then
                        return i
                  end
            elseif v == ID
            then
                  return i
            end
      end
      return false
end

---checks to see if a table is selfReferencing
---@param base table
---@return boolean
function utilties.Table.selfReferencing(base,Topions)
      expect(false, 1, base, "table")
      Topions = expect(false,2,Topions,"table","nil") or {}
      if Topions.checkMetatables ~= false
      then
            Topions.checkMetatables = true
      end 
      if Topions.bIndex ~= false
      then
            Topions.bIndex = true
      end
      if Topions.bnewIndex ~= false
      then
            Topions.bnewIndex = true
      end
      local stack = {{base, select(2, pcall(getmetatable, base))}}
      local seen = {}
      local firstLoop = true
      while true do
            local current = table.remove(stack)
            if not current then
                  break
            end
            local tbl, mt = current[1], current[2]
            if tbl == base and not firstLoop then
                  return true
            end
            seen[tbl] = true
            -- Iterate through the current table's values
            for _, v in pairs(tbl) do
                  if v == base then
                        return true
                  end
                  if type(v) == "table" and not seen[v] then
                        table.insert(stack, {v, select(2, pcall(getmetatable, v))})
                  end
            end
            -- Check the metatable's __index field if it's a table
            if type(mt) == "table" and Topions.checkMetatables then
                  local meta_index = mt.__index
                  if type(meta_index) == "table" and not seen[meta_index] and Topions.bIndex  then
                        table.insert(stack, {meta_index, select(2, pcall(getmetatable, meta_index))})
                  end
                  local meta_newindex = mt.__newindex
                  if type(meta_newindex) == "table" and not seen[meta_newindex] and Topions.bnewIndex then
                        table.insert(stack,{meta_newindex, select(2, pcall(getmetatable, meta_newindex))})
                  end
            end
            firstLoop = false
      end
      return false
end


---creates a true copy (with the option to include the meta table)
---@param Copy_Tbl table
---@param copymetatable boolean|nil
---@return table
function utilties.Table.copy(Copy_Tbl,copymetatable)
      expect(false,1,Copy_Tbl,"table")
      expect(false,2,copymetatable,"boolean","nil")
      local proxy = {}
      for index,v in pairs(Copy_Tbl) do
            if type(v) == "table" and not utilties.Table.selfReferencing(v)
            then
                  proxy[index] = utilties.Table.copy(v,copymetatable)
            else
                  proxy[index] = v
            end
      end
      local bool,result = pcall(getmetatable,Copy_Tbl)
      if bool and copymetatable
      then
            setmetatable(proxy,result)
      end
      return proxy
end

---transfers a number of items indexes into a new table
---@param base table
---@param _nTransfer number
---@return table
function utilties.Table.transfer(base,_nTransfer)
      expect(false,1,base,"table")
      expect(false,2,_nTransfer,"number")
      local CIndex = 1
      local result = {}
      while CIndex <= _nTransfer do
            result[CIndex] = base[CIndex]
            CIndex = CIndex + 1
      end
      return result
end

---replaces the table type with the class type
---@param self table
---@return string
function utilties.Table.tostring(self)
      local bool,meta = pcall(getmetatable,self)
      if not bool or not meta
      then
            return ("%s: (%s)"):format(utilties.getType(self),utilties.get_hash(self))
      end
      if not meta.hash
      then
            return meta.__name
      end
      return ("%s: (%s)"):format(meta._name,meta.hash)
end
---sets the table class type
---@param Tbl table
---@param Type string
---@param keepHash boolean|nil
---@return table
function utilties.Table.setType(Tbl,Type,keepHash)
      expect(false,1,Tbl,"table")
      expect(false,2,Type,"string")
      local bool,meta = pcall(getmetatable,Tbl)
      if not bool or not meta
      then
            meta = {}
      end
      meta.__name = Type
      if keepHash or keepHash == nil
      then
            meta.hash = utilties.Table.get_hash(Tbl)
      end
      meta.__tostring = utilties.Table.tostring
      return setmetatable(Tbl,meta)
end
---returns the class type
---@param Tbl table
---@return string
function utilties.Table.getType(Tbl)
      expect(false,1,Tbl,"table")
      local meta = getmetatable(Tbl) or {}
      return meta.__name or "table"
end
---returns the hash
---@param Tbl table
---@return string
function utilties.Table.get_hash(Tbl)
      expect(false,1,Tbl,"table")
      local meta = getmetatable(Tbl) or {}
      return meta.hash or tostring(Tbl):match("table: (%x+)")
end
return utilties