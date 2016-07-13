local print = print
local table = table
local string = string
local type = type
local pairs = pairs

local printAll = function(target, params)
    local targetType = type(target)
    if targetType == "table" then
        local tip = params and params.tip or "This is a Table!^_<......................................"
        local cache = {[target] = "."}
        local isHead = false

        local function dump(t, space, level)
            local temp = {}
            if not isHead then
                temp = {tip}
                isHead = true
            end
            for k, v in pairs(t) do
                local key = tostring(k)
                if type(v) == "table" then
                    table.insert(temp, string.format("%s+[%s]\n%s", string.rep(" ", level), key, dump(v, space, level + 1)))
                else
                    table.insert(temp, string.format("%s+[%s]%s", string.rep(" ", level), key, tostring(v)))
                end
            end
            return table.concat(temp, string.format("\n%s", space))
        end
        print(dump(target, "", 0))
        print(".................................................")
    elseif targetType == "userdata" then
        return printAll(debug.getuservalue(target), {tip = "Userdata's uservalue detail:"})
    else
        print("[printAll error]: not support type")
    end
end

--Author: mixi
--Date: 2016-06-30 11:31:55
--Abstract: XmlParser xml解析工具 之前的不能用 只好重写

local XMLParsers = {}
local PREV_NAME = "t_"
local SavePath = "/Users/mixi/Desktop"

-- 一些规定
-- 第七行是字段名字，第九行是默认数值存放，第十行开始是有效数据，第一列数据是无效的
local fieldTypeLine = 7
local defaultValueLine = 9
local valueStartLine = 10
-- local invaildLineIndexTable = {min = 2, max = 5}
local valueStartRow = 2
-- 命名
local FieldInfo = {}
-- 默认数据填充
local DefaultInfo = {}
-- 主id 有的话只能有一个 且与default不能同时存在
local mainIndex = false

local function reftesh()
    FieldInfo = {}
    DefaultInfo = {}
    mainIndex = false
end

local function fieldTypeParser(cellInfo)
    FieldInfo = cellInfo
end

local function defaultValueParser(cellInfo)
    -- printAll(cellInfo)
    for rowIndex = valueStartRow, #cellInfo do
        local cellStr = cellInfo[rowIndex]
        if cellStr then
            local startPos, endPos = string.find(cellStr, "default=")
            if endPos then
                value = string.sub(cellStr, endPos + 1)
                local newValue = tonumber(value)
                DefaultInfo[rowIndex] = newValue or value
            elseif not mainIndex then
                startPos, endPos = string.find(cellStr, "main")
                if startPos then
                    mainIndex = FieldInfo[rowIndex]
                end
            end
        end
    end
end

local function enumParser(rowInfo)
end

local function fullDataFromInfo(info)
    local t = {}
    for index, value in ipairs(FieldInfo) do
        if index >= valueStartRow then
            local data = info[index]
            if not data and DefaultInfo[index] then
                data = DefaultInfo[index]
            end
            t[value] = data
        end
    end
    -- printAll(t)
    return t
end

local file = false
local function doWrite(msg, file)
    msg = msg .. "\n"
    file:write(msg)
end

local function write2Table(t, indent, file_handle)
    local pre = string.rep("\t", indent)
    for k,v in pairs(t) do
        if type(v) == "table" then
            if type(k) == "number" then
                doWrite(pre .. "[" .. k .. "]" .. " = {", file_handle)
                write2Table(v, indent + 1, file_handle)
                doWrite(pre .. "},", file_handle)
            elseif type(k) == "string" then
                if tonumber(k) then
                    doWrite(pre .. "[\"" .. k .. "\"] = {", file_handle)
                elseif (tonumber(string.sub(k, 1, 1))) then
                    doWrite(pre .. "[\"" .. k .. "\"] = {", file_handle)
                else
                    doWrite(pre .. k .. " = {", file_handle)
                end
                write2Table(v, indent + 1, file_handle)
                doWrite(pre .. "},", file_handle)
            end
        elseif type(v) == "number" then
            if type(k) == "number" then
                doWrite(pre .. "[" .. k .. "]" .. " = " .. v .. ",", file_handle)
            elseif type(k) == "string" then
                if tonumber(k) then
                    doWrite(pre .. "[\"" .. k .. "\"] = " .. v .. ",", file_handle)
                elseif (tonumber(string.sub(k, 1, 1))) then
                    doWrite(pre .. "[\"" .. k .. "\"] = " .. v .. ",", file_handle)
                else
                    doWrite(pre .. k .. " = " .. v .. ",", file_handle)
                end
            end
        elseif type(v) == "string" then
            local text = string.gsub(v, "[\n]", "")
            text = string.gsub(text, "\"", "\\\"")
            if type(k) == "number" then
                doWrite(pre .. "[" .. k .. "]" .. " = \"" .. text .. "\",", file_handle)
            elseif type(k) == "string" then
                if tonumber(k) then
                    doWrite(pre .. "[\"" .. k .. "\"] = \"" .. text .. "\",", file_handle)
                elseif (tonumber(string.sub(k, 1, 1))) then
                    doWrite(pre .. "[\"" .. k .. "\"] = \"" .. text .. "\",", file_handle)
                else
                    doWrite(pre .. k .. " = \"" .. text .. "\",", file_handle)
                end
            end
        end
    end
end

local function saveFile(tableInfo, fileName, path, des)
    local output = string.format("%s/%s.lua", path, fileName)

    file = assert(io.open(output, 'w'))
    local des = des or ""
    doWrite(string.format("-- %s %s", fileName, des), file)
    doWrite("local root = {", file)
    write2Table(tableInfo, 1, file)
    doWrite("}", file)
    doWrite("return root", file)
    file:close()
end

local lineVaildIndexTable = {
    [fieldTypeLine] = fieldTypeParser,
    [defaultValueLine] = defaultValueParser,
}

local function splitStr(str, sign)
    local info = {}
    local startPos, endPos = 0, 0
    local signLength = string.len(sign)
    local function getSplitInfo()
        startPos = string.find(str, sign, endPos + 1)
        if not startPos then
            return 
        end
        endPos = string.find(str, sign, startPos + signLength)
        if endPos then 
            endPos = endPos - 1
        else
            endPos = string.len(str)
        end
        return string.sub(str, startPos, endPos)
    end
    local splitInfo = getSplitInfo()
    while splitInfo do
        table.insert(info, splitInfo)
        splitInfo = getSplitInfo()
    end
    return info
end

local function filterRowStr(rowStr)
    local info = {}
    local cellIndex = 0
    -- 由于不是一定以</Cell>结尾 还有以/>结尾
    local cellSign = "<Cell"
    local cellStrInfo = splitStr(rowStr, cellSign)
    -- print("cellStrInfo")
    -- printAll(cellStrInfo)
    for i, cellStr in ipairs(cellStrInfo) do
        -- 找到row信息
        string.gsub(
            cellStr, 
            "<Cell.->", 
            function(str)
                local _, pos = string.find(str, "ss:Index")
                if pos then 
                    local startPos, endPos = string.find(str, "\".-\"", pos + 1)
                    cellIndex = string.sub(str, startPos + 1, endPos - 1)
                    cellIndex = tonumber(cellIndex)
                else
                    cellIndex = cellIndex + 1
                end
            end
        )

        local offset = cellIndex - (#info + 1)
        if offset > 0 then
            for i = 1, offset do
                table.insert(info, false)
            end
        end

        if cellIndex < valueStartRow then
            table.insert(info, false)
        else
            local value = false
            -- 解析data
            local prevPos, prevEndPos = string.find(cellStr, "<Data.->")
            local suffixPos, suffixEndPos = string.find(cellStr, "</Data>")
            if prevEndPos and suffixPos then
                local data = string.sub(cellStr, prevEndPos + 1, suffixPos - 1)
                if data then
                    local dataType
                    local str = string.sub(cellStr, prevPos, prevEndPos)
                    string.gsub(str, "\".-\"", function(s) dataType = string.sub(s, 2, -2) end)
                    if dataType and dataType == "Number" then
                        data = tonumber(data)
                    end
                    -- print("dataTypedataType", dataType, data)
                    value = data
                end
            end
            table.insert(info, value)
        end
    end
    return info
end

local function parseXmlText(xmlText)
    local xmlInfo = {}
    local dataInfo = {}

	string.gsub(
		xmlText, 
		"<Worksheet .-</Worksheet>", 
		function(ss)
            -- 找表名
            local name, des = false
            string.gsub(
                ss, 
                "<Worksheet.->", 
                function(nameStr)
                    local bracketPos = string.find(nameStr, "%(")
                    if bracketPos then
                        local startPos, endPos = string.find(nameStr, "\".-\"")
                        des = string.sub(nameStr, startPos + 1, bracketPos - 1)
                        string.gsub(nameStr, "%(.-%)", function(str) name = string.sub(str, 2, -2) end)
                    end
                end
            )
            print("文件名", name)
            -- 有名字的才有效
            if name then
                local dataTable = {}
                reftesh()
                local rowSign = "<Row"
                local rowStrInfo = splitStr(ss, rowSign)

                -- 枚举另外解析
                if name == "enum" then
                    local enumName, enumInfo
                    local enumNameIndex, enumDesIndex, enumValueIndex = 2, 3, 4
                    local rowMaxIndex = #rowStrInfo
                    for lineIndex, rowStr in ipairs(rowStrInfo) do
                        local info = filterRowStr(rowStr)
                        -- printAll(info)
                        if info[enumNameIndex] then
                            if not enumName then
                                enumName = info[enumNameIndex]
                                enumInfo = {}
                            else
                                enumInfo[info[enumNameIndex]] = tonumber(info[enumValueIndex])
                            end
                        elseif enumName and enumInfo then
                            dataTable[enumName] = enumInfo
                            enumName = false
                            enumInfo = {}
                        end
                        -- 最后一项的处理
                        if lineIndex == rowMaxIndex and not dataTable[enumName] then
                            dataTable[enumName] = enumInfo
                        end
                    end
                else
                    -- 表名
                    name = string.format("%s%s", PREV_NAME, name)
                    -- printAll(lineVaildIndexTable)
                    for lineIndex, rowStr in ipairs(rowStrInfo) do
                        if lineVaildIndexTable[lineIndex] then
                            local info = filterRowStr(rowStr)
                            lineVaildIndexTable[lineIndex](info)
                        elseif lineIndex >= valueStartLine then
                            local info = filterRowStr(rowStr)
                            local newData = fullDataFromInfo(info)
                            table.insert(dataTable, newData)
                        end
                    end
                    -- 更换index 不能有重复, 重复的就先覆盖吧
                    if mainIndex then
                        local newDataTable = {}
                        for i, v in ipairs(dataTable) do
                            if v[mainIndex] and newDataTable[v[mainIndex]] then
                                print("警告，有个数据重复了", mainIndex, v[mainIndex], i)
                            end
                            newDataTable[v[mainIndex]] = v
                        end
                        dataTable = newDataTable
                    end
                end
                saveFile(dataTable, name, SavePath, des)                        
            end
		end
	)
end

function XMLParsers.loadFile(xmlFileFullPath, saveFilePath)
    local hFile, err = io.open(xmlFileFullPath, "r");
    if saveFilePath then
        SavePath = saveFilePath
    end
    if hFile and not err then
        local xmlText = hFile:read("*a"); -- read file content
        io.close(hFile);
        return parseXmlText(xmlText), nil;
    else
        print(err)
        return nil
    end
end

return XMLParsers