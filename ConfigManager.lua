local HttpService = game:GetService("HttpService")

local ConfigManager = {
Folder = "UILibrary",
FileExtension = ".json",
Ignore = {},
Callbacks = {},
Library = nil
}

local function getGlobal(name)
local value = rawget(getfenv(), name)

if value ~= nil then
    return value
end

return _G[name]


end

local function isAvailable(name)
return type(getGlobal(name)) == "function"
end

local function ensureFolder(path)
if not isAvailable("isfolder") or not isAvailable("makefolder") then
return
end

if not isfolder(path) then
    makefolder(path)
end


end

local function fileExists(path)
if not isAvailable("isfile") then
return false
end

return isfile(path)


end

local function readFile(path)
if not isAvailable("readfile") then
return nil
end

local success, result = pcall(readfile, path)

if success then
    return result
end

return nil


end

local function writeFile(path, content)
if not isAvailable("writefile") then
return false
end

local success = pcall(writefile, path, content)

return success


end

local function deleteFile(path)
if not isAvailable("delfile") then
return false
end

local success = pcall(delfile, path)

return success


end

local function listFiles(path)
if not isAvailable("listfiles") then
return {}
end

local success, result = pcall(listfiles, path)

if success and type(result) == "table" then
    return result
end

return {}


end

local function getFileName(path)
return path:match("([^/\]+)$") or path
end

local function stripExtension(name)
return name:gsub("%.json$", "")
end

local function sanitizeName(name)
name = tostring(name or "Config")

name = name:gsub("[<>:\"/\\|%?%*]", "")
name = name:gsub("^%s+", "")
name = name:gsub("%s+$", "")

if name == "" then
    name = "Config"
end

return name


end

local function deepCopy(value)
if type(value) ~= "table" then
return value
end

local result = {}

for key, item in pairs(value) do
    result[key] = deepCopy(item)
end

return result


end

local function serializeValue(value)
local valueType = typeof(value)

if valueType == "Color3" then
    return {
        __type = "Color3",
        R = value.R,
        G = value.G,
        B = value.B
    }
end

if valueType == "BrickColor" then
    return {
        __type = "BrickColor",
        Number = value.Number
    }
end

if valueType == "Vector2" then
    return {
        __type = "Vector2",
        X = value.X,
        Y = value.Y
    }
end

if valueType == "Vector3" then
    return {
        __type = "Vector3",
        X = value.X,
        Y = value.Y,
        Z = value.Z
    }
end

if valueType == "UDim2" then
    return {
        __type = "UDim2",
        XScale = value.X.Scale,
        XOffset = value.X.Offset,
        YScale = value.Y.Scale,
        YOffset = value.Y.Offset
    }
end

if valueType == "EnumItem" then
    return {
        __type = "EnumItem",
        EnumType = tostring(value.EnumType),
        Name = value.Name
    }
end

if type(value) == "table" then
    local result = {}

    for key, item in pairs(value) do
        result[key] = serializeValue(item)
    end

    return result
end

if type(value) == "function"
    or type(value) == "userdata"
    or type(value) == "thread" then
    return nil
end

return value


end

local function deserializeValue(value)
if type(value) ~= "table" then
return value
end

if value.__type == "Color3" then
    return Color3.new(value.R, value.G, value.B)
end

if value.__type == "BrickColor" then
    return BrickColor.new(value.Number)
end

if value.__type == "Vector2" then
    return Vector2.new(value.X, value.Y)
end

if value.__type == "Vector3" then
    return Vector3.new(value.X, value.Y, value.Z)
end

if value.__type == "UDim2" then
    return UDim2.new(
        value.XScale,
        value.XOffset,
        value.YScale,
        value.YOffset
    )
end

if value.__type == "EnumItem" then
    local enumName = value.EnumType:gsub("Enum%.", "")
    local enumObject = Enum[enumName]

    if enumObject then
        return enumObject[value.Name]
    end
end

local result = {}

for key, item in pairs(value) do
    result[key] = deserializeValue(item)
end

return result


end

function ConfigManager:SetLibrary(library)
self.Library = library

return self


end

function ConfigManager:SetFolder(folder)
self.Folder = sanitizeName(folder)

return self


end

function ConfigManager:SetIgnoreIndexes(indexes)
self.Ignore = {}

for _, index in ipairs(indexes or {}) do
    self.Ignore[index] = true
end

return self


end

function ConfigManager:BuildFolder()
ensureFolder(self.Folder)
end

function ConfigManager:GetPath(name)
return self.Folder .. "/" .. sanitizeName(name) .. self.FileExtension
end

function ConfigManager:Save(name)
if not self.Library then
return false, "Library is not connected"
end

if not isAvailable("writefile") then
    return false, "writefile is unavailable"
end

self:BuildFolder()

local flags = self.Library.Flags or {}
local data = {}

for flag, value in pairs(flags) do
    if not self.Ignore[flag] then
        local serialized = serializeValue(value)

        if serialized ~= nil then
            data[flag] = serialized
        end
    end
end

local payload = {
    Version = 1,
    Config = data
}

local success, encoded = pcall(function()
    return HttpService:JSONEncode(payload)
end)

if not success then
    return false, encoded
end

local path = self:GetPath(name)

if not writeFile(path, encoded) then
    return false, "Unable to write config"
end

return true, path


end

function ConfigManager:Load(name)
if not self.Library then
return false, "Library is not connected"
end

local path = self:GetPath(name)

if not fileExists(path) then
    return false, "Config does not exist"
end

local content = readFile(path)

if not content then
    return false, "Unable to read config"
end

local success, decoded = pcall(function()
    return HttpService:JSONDecode(content)
end)

if not success then
    return false, "Invalid config"
end

local config = decoded.Config or decoded

for flag, value in pairs(config) do
    if not self.Ignore[flag] then
        local restored = deserializeValue(value)

        self.Library.Flags[flag] = restored

        local callback = self.Callbacks[flag]

        if callback then
            task.spawn(function()
                pcall(callback, restored)
            end)
        end
    end
end

return true, config


end

function ConfigManager:Delete(name)
local path = self:GetPath(name)

if not fileExists(path) then
    return false, "Config does not exist"
end

if not deleteFile(path) then
    return false, "Unable to delete config"
end

return true


end

function ConfigManager:Exists(name)
return fileExists(self:GetPath(name))
end

function ConfigManager:Rename(oldName, newName)
if not isAvailable("readfile") or not isAvailable("writefile") then
return false, "File API unavailable"
end

local oldPath = self:GetPath(oldName)
local newPath = self:GetPath(newName)

if not fileExists(oldPath) then
    return false, "Config does not exist"
end

if fileExists(newPath) then
    return false, "Target config already exists"
end

local content = readFile(oldPath)

if not content then
    return false, "Unable to read config"
end

if not writeFile(newPath, content) then
    return false, "Unable to create renamed config"
end

deleteFile(oldPath)

return true


end

function ConfigManager:GetConfigs()
self:BuildFolder()

local configs = {}

for _, path in ipairs(listFiles(self.Folder)) do
    local fileName = getFileName(path)

    if fileName:sub(-#self.FileExtension) == self.FileExtension then
        table.insert(
            configs,
            stripExtension(fileName)
        )
    end
end

table.sort(configs, function(a, b)
    return a:lower() < b:lower()
end)

return configs


end

function ConfigManager:SetFlagCallback(flag, callback)
if type(callback) ~= "function" then
self.Callbacks[flag] = nil
return
end

self.Callbacks[flag] = callback


end

function ConfigManager:SetFlagCallbacks(callbacks)
for flag, callback in pairs(callbacks or {}) do
self:SetFlagCallback(flag, callback)
end

return self


end

function ConfigManager:ClearCallbacks()
self.Callbacks = {}
end

function ConfigManager:LoadAutoload()
local path = self:GetPath("autoload")

if not fileExists(path) then
    return false
end

return self:Load("autoload")


end

function ConfigManager:SetAutoload(name)
local source = self:GetPath(name)
local target = self:GetPath("autoload")

if not fileExists(source) then
    return false, "Config does not exist"
end

local content = readFile(source)

if not content then
    return false, "Unable to read config"
end

if not writeFile(target, content) then
    return false, "Unable to write autoload"
end

return true


end

function ConfigManager:RemoveAutoload()
local path = self:GetPath("autoload")

if fileExists(path) then
    deleteFile(path)
end

return true


end

function ConfigManager:Export(name)
if not fileExists(self:GetPath(name)) then
return nil
end

return readFile(self:GetPath(name))


end

function ConfigManager:Import(name, content)
if type(content) ~= "string" then
return false, "Invalid content"
end

self:BuildFolder()

local success = writeFile(
    self:GetPath(name),
    content
)

if not success then
    return false, "Unable to import config"
end

return true


end

function ConfigManager:Reset()
if not self.Library then
return false
end

for flag, value in pairs(self.Library.Flags or {}) do
    if not self.Ignore[flag] then
        if type(value) == "boolean" then
            self.Library.Flags[flag] = false
        elseif type(value) == "number" then
            self.Library.Flags[flag] = 0
        elseif type(value) == "string" then
            self.Library.Flags[flag] = ""
        elseif type(value) == "table" then
            self.Library.Flags[flag] = {}
        end
    end
end

return true


end

return ConfigManager
