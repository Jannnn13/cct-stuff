-- CC: Tweaked Library for advanced filesystem operations

-- Licensed under the MIT License
-- Made by Jannnn13

local afs = {}

function afs.scan(path)
    local returnData = {}
    local files = fs.list(path)

    for _, file in pairs(files) do
        local fullPath = fs.combine(path, file)
        table.insert(returnData, fullPath)

        if fs.isDir(fullPath) then
            local subData = afs.scan(fullPath)
            for _, subFile in pairs(subData) do
                table.insert(returnData, subFile)
            end
        end
    end

    return returnData
end

function afs.quickRead(path)
    if not fs.exists(path) then
        return nil, "File does not exist"
    end

    if fs.isDir(path) then
        return nil, "Path is a directory"
    end

    local file = fs.open(path, "r")

    if not file then return nil, "Failed to open file" end

    local content = file.readAll()
    file.close()

    return content
end

function afs.quickWrite(path, data)
    if not (path or data) then
        return false, "Path or data is nil"
    end
    
    local file = fs.open(path, "w")
    if not file then return false, "Failed to open file" end

    file.write(data)
    file.close()
    return true
end

function afs.quickAdd(path, data)
    local existingData = afs.quickRead(path) or ""
    return afs.quickWrite(path, existingData .. data)
end

function afs.touch(path)
    if fs.exists(path) then
        return false, "File already exists"
    end

    local file = fs.open(path, "w")
    if not file then return false, "Failed to create file" end
    file.close()
    return true
end

function afs.toOBJ(path)
    local listData = fs.list(path)

    if not listData or #listData == 0 then
        return {}
    end

    local returnData = {}

    for _, file in pairs(listData) do
        if fs.isDir(fs.combine(path, file)) then
            table.insert(returnData, {type = "dir", name = file, data = afs.toOBJ(fs.combine(path, file))})
        else
            table.insert(returnData, {type = "file", name = file, data = afs.quickRead(fs.combine(path, file))})
        end
    end

    return returnData
end

function afs.fromOBJ(path, obj)
    if not obj or type(obj) ~= "table" then
        return false, "Invalid object"
    end

    if not fs.exists(path) then
        fs.makeDir(path)
    elseif not fs.isDir(path) then
        return false, "Path exists but is not a directory"
    end

    for _, item in pairs(obj) do
        local itemPath = fs.combine(path, item.name)
        if item.type == "dir" then
            local success, err = afs.fromOBJ(itemPath, item.data)
            if not success then
                return false, err
            end
        elseif item.type == "file" then
            local success, err = afs.quickWrite(itemPath, item.data)
            if not success then
                return false, err
            end
        else
            return false, "Unknown item type: " .. tostring(item.type)
        end
    end

    return true
end

return afs