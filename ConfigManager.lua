--[[
    MoonHub ConfigManager.lua
    Compatible with the MoonHub Library.lua

    Features:
        - Save configuration
        - Load configuration
        - Delete configuration
        - Get configuration list
        - Auto-save helpers
        - Config folder creation
        - JSON based storage

    Usage:

        local ConfigManager = loadstring(
            game:HttpGet("YOUR_CONFIGMANAGER_URL")
        )()

        ConfigManager:SetLibrary(Library)

        ConfigManager:SetFolder("MoonHub")

        ConfigManager:BuildConfigSection(Tab)

        -- Save:
        ConfigManager:Save("MyConfig")

        -- Load:
        ConfigManager:Load("MyConfig")
]]

local HttpService = game:GetService("HttpService")

local ConfigManager = {}

ConfigManager.Library = nil
ConfigManager.Folder = "MoonHub"
ConfigManager.ConfigExtension = ".json"

ConfigManager.Parser = {
    Toggles = {},
    Options = {},
    Inputs = {},
    Sliders = {},
}

--//==================================================
--// INTERNAL FILE FUNCTIONS
--//==================================================

local function CanUseFileSystem()
    return type(isfolder) == "function"
        and type(makefolder) == "function"
        and type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
        and type(delfile) == "function"
end

local function EnsureFolder(Folder)
    if not CanUseFileSystem() then
        return false
    end

    if not isfolder(Folder) then
        pcall(function()
            makefolder(Folder)
        end)
    end

    return isfolder(Folder)
end

local function Encode(Data)
    local Success, Result =
        pcall(function()
            return HttpService:JSONEncode(Data)
        end)

    if Success then
        return Result
    end

    return nil
end

local function Decode(Data)
    local Success, Result =
        pcall(function()
            return HttpService:JSONDecode(Data)
        end)

    if Success then
        return Result
    end

    return nil
end

local function GetConfigPath(Name)
    return ConfigManager.Folder
        .. "/"
        .. tostring(Name)
        .. ConfigManager.ConfigExtension
end

--//==================================================
--// LIBRARY CONNECTION
--//==================================================

function ConfigManager:SetLibrary(Library)
    self.Library = Library
    return self
end

function ConfigManager:SetFolder(Folder)
    self.Folder = tostring(Folder or "MoonHub")

    if CanUseFileSystem() then
        EnsureFolder(self.Folder)
    end

    return self
end

--//==================================================
--// REGISTER OBJECT
--//==================================================

function ConfigManager:RegisterToggle(Key, Toggle)
    if not Key or not Toggle then
        return
    end

    self.Parser.Toggles[tostring(Key)] = Toggle
end

function ConfigManager:RegisterOption(Key, Option)
    if not Key or not Option then
        return
    end

    self.Parser.Options[tostring(Key)] = Option
end

function ConfigManager:RegisterInput(Key, Input)
    if not Key or not Input then
        return
    end

    self.Parser.Inputs[tostring(Key)] = Input
end

function ConfigManager:RegisterSlider(Key, Slider)
    if not Key or not Slider then
        return
    end

    self.Parser.Sliders[tostring(Key)] = Slider
end

--//==================================================
--// AUTOMATIC REGISTRATION
--//==================================================

function ConfigManager:Refresh()
    if not self.Library then
        return
    end

    if self.Library.Toggles then
        for Key, Toggle in pairs(self.Library.Toggles) do
            self:RegisterToggle(Key, Toggle)
        end
    end

    if self.Library.Options then
        for Key, Option in pairs(self.Library.Options) do
            self:RegisterOption(Key, Option)
        end
    end

    if self.Library.Labels then
        for Key, Label in pairs(self.Library.Labels) do
            if Label.Type == "Input" then
                self:RegisterInput(Key, Label)
            end
        end
    end

    return self
end

--//==================================================
--// COLLECT
--//==================================================

function ConfigManager:GetConfig()
    self:Refresh()

    local Config = {
        Toggles = {},
        Options = {},
        Inputs = {},
        Sliders = {},
    }

    --// TOGGLES

    for Key, Toggle in pairs(
        self.Parser.Toggles
    ) do

        if Toggle.GetValue then
            local Success, Value =
                pcall(function()
                    return Toggle:GetValue()
                end)

            if Success then
                Config.Toggles[Key] = Value
            end
        elseif Toggle.Value ~= nil then
            Config.Toggles[Key] =
                Toggle.Value
        end
    end

    --// DROPDOWNS

    for Key, Option in pairs(
        self.Parser.Options
    ) do

        if Option.GetValue then
            local Success, Value =
                pcall(function()
                    return Option:GetValue()
                end)

            if Success then
                Config.Options[Key] = Value
            end
        elseif Option.Value ~= nil then
            Config.Options[Key] =
                Option.Value
        end
    end

    --// INPUTS

    for Key, Input in pairs(
        self.Parser.Inputs
    ) do

        if Input.GetValue then
            local Success, Value =
                pcall(function()
                    return Input:GetValue()
                end)

            if Success then
                Config.Inputs[Key] = Value
            end
        elseif Input.Value ~= nil then
            Config.Inputs[Key] =
                Input.Value
        end
    end

    --// SLIDERS

    for Key, Slider in pairs(
        self.Parser.Sliders
    ) do

        if Slider.Value ~= nil then
            Config.Sliders[Key] =
                Slider.Value
        end
    end

    return Config
end

--//==================================================
--// APPLY
--//==================================================

function ConfigManager:LoadData(Config)
    if type(Config) ~= "table" then
        return false
    end

    self:Refresh()

    --// TOGGLES

    if type(Config.Toggles) == "table" then

        for Key, Value in pairs(
            Config.Toggles
        ) do

            local Toggle =
                self.Parser.Toggles[Key]

            if Toggle
                and Toggle.SetValue then

                pcall(function()
                    Toggle:SetValue(
                        Value == true
                    )
                end)
            end
        end
    end

    --// DROPDOWNS

    if type(Config.Options) == "table" then

        for Key, Value in pairs(
            Config.Options
        ) do

            local Option =
                self.Parser.Options[Key]

            if Option
                and Option.SetValue then

                pcall(function()
                    Option:SetValue(Value)
                end)
            end
        end
    end

    --// INPUTS

    if type(Config.Inputs) == "table" then

        for Key, Value in pairs(
            Config.Inputs
        ) do

            local Input =
                self.Parser.Inputs[Key]

            if Input
                and Input.SetValue then

                pcall(function()
                    Input:SetValue(Value)
                end)
            end
        end
    end

    --// SLIDERS

    if type(Config.Sliders) == "table" then

        for Key, Value in pairs(
            Config.Sliders
        ) do

            local Slider =
                self.Parser.Sliders[Key]

            if Slider
                and Slider.SetValue then

                pcall(function()
                    Slider:SetValue(Value)
                end)
            end
        end
    end

    return true
end

--//==================================================
--// SAVE
--//==================================================

function ConfigManager:Save(Name)
    if not CanUseFileSystem() then
        if self.Library
            and self.Library.Notify then

            self.Library:Notify({
                Title = "MoonHub",
                Description =
                    "Config sistemi bu executor'da desteklenmiyor.",
                Time = 4,
            })
        end

        return false
    end

    Name = tostring(Name or "Default")

    if Name == "" then
        Name = "Default"
    end

    EnsureFolder(self.Folder)

    local Config =
        self:GetConfig()

    Config.Version = 1
    Config.Name = Name

    local Encoded =
        Encode(Config)

    if not Encoded then

        if self.Library
            and self.Library.Notify then

            self.Library:Notify({
                Title = "MoonHub",
                Description =
                    "Config kaydedilemedi.",
                Time = 4,
            })
        end

        return false
    end

    local Path =
        GetConfigPath(Name)

    local Success =
        pcall(function()
            writefile(
                Path,
                Encoded
            )
        end)

    if Success then

        if self.Library
            and self.Library.Notify then

            self.Library:Notify({
                Title = "MoonHub",
                Description =
                    "Config kaydedildi: "
                    .. Name,
                Time = 3,
            })
        end

        return true
    end

    return false
end

--//==================================================
--// LOAD
--//==================================================

function ConfigManager:Load(Name)
    if not CanUseFileSystem() then

        if self.Library
            and self.Library.Notify then

            self.Library:Notify({
                Title = "MoonHub",
                Description =
                    "Config sistemi bu executor'da desteklenmiyor.",
                Time = 4,
            })
        end

        return false
    end

    Name = tostring(Name or "Default")

    local Path =
        GetConfigPath(Name)

    if not isfile(Path) then

        if self.Library
            and self.Library.Notify then

            self.Library:Notify({
                Title = "MoonHub",
                Description =
                    "Config bulunamadı: "
                    .. Name,
                Time = 4,
            })
        end

        return false
    end

    local Success, Raw =
        pcall(function()
            return readfile(Path)
        end)

    if not Success then
        return false
    end

    local Config =
        Decode(Raw)

    if not Config then

        if self.Library
            and self.Library.Notify then

            self.Library:Notify({
                Title = "MoonHub",
                Description =
                    "Config okunamadı: "
                    .. Name,
                Time = 4,
            })
        end

        return false
    end

    local Applied =
        self:LoadData(Config)

    if Applied then

        if self.Library
            and self.Library.Notify then

            self.Library:Notify({
                Title = "MoonHub",
                Description =
                    "Config yüklendi: "
                    .. Name,
                Time = 3,
            })
        end
    end

    return Applied
end

--//==================================================
--// DELETE
--//==================================================

function ConfigManager:Delete(Name)
    if not CanUseFileSystem() then
        return false
    end

    Name = tostring(Name or "Default")

    local Path =
        GetConfigPath(Name)

    if not isfile(Path) then
        return false
    end

    local Success =
        pcall(function()
            delfile(Path)
        end)

    if Success then

        if self.Library
            and self.Library.Notify then

            self.Library:Notify({
                Title = "MoonHub",
                Description =
                    "Config silindi: "
                    .. Name,
                Time = 3,
            })
        end

        return true
    end

    return false
end

--//==================================================
--// EXISTS
--//==================================================

function ConfigManager:Exists(Name)
    if not CanUseFileSystem() then
        return false
    end

    Name = tostring(Name or "Default")

    return isfile(
        GetConfigPath(Name)
    )
end

--//==================================================
--// GET CONFIGS
--//==================================================

function ConfigManager:AllConfigs()
    if not CanUseFileSystem() then
        return {}
    end

    EnsureFolder(self.Folder)

    local Files = {}

    if type(listfiles) ~= "function" then
        return Files
    end

    local Success, Result =
        pcall(function()
            return listfiles(
                self.Folder
            )
        end)

    if not Success
        or type(Result) ~= "table" then

        return Files
    end

    for _, Path in ipairs(Result) do

        if string.sub(
            Path,
            -#self.ConfigExtension
        ) == self.ConfigExtension then

            local FileName =
                string.match(
                    Path,
                    "([^/\\]+)"
                )

            if FileName then

                FileName =
                    string.sub(
                        FileName,
                        1,
                        #FileName
                        - #self.ConfigExtension
                    )

                table.insert(
                    Files,
                    FileName
                )
            end
        end
    end

    table.sort(Files)

    return Files
end

--//==================================================
--// BUILD CONFIG SECTION
--//==================================================

function ConfigManager:BuildConfigSection(Tab)
    if not Tab then
        return nil
    end

    local Groupbox =
        Tab:AddLeftGroupbox(
            "Configuration"
        )

    local ConfigInput
    local SavedConfigsDropdown

    ConfigInput = Groupbox:AddInput(
        "ConfigName",
        {
            Text = "Config Name",
            Default = self.CurrentConfig or "Default",
            Placeholder = "Config name...",
            ClearTextOnFocus = false,
            Callback = function(Value)
                self.CurrentConfig =
                    tostring(Value or "Default")
            end,
        }
    )

    local function RefreshSavedConfigs()
        if SavedConfigsDropdown then
            pcall(function()
                SavedConfigsDropdown:Destroy()
            end)
            SavedConfigsDropdown = nil
        end

        local ConfigNames = self:AllConfigs()
        local DefaultIndex = 1
        local Current = tostring(self.CurrentConfig or "Default")

        for Index, Name in ipairs(ConfigNames) do
            if Name == Current then
                DefaultIndex = Index
                break
            end
        end

        if #ConfigNames == 0 then
            ConfigNames = { "No saved configs" }
            DefaultIndex = 1
        end

        SavedConfigsDropdown = Groupbox:AddDropdown(
            "SavedConfigs",
            {
                Text = "Saved Configs",
                Values = ConfigNames,
                Default = DefaultIndex,
                Callback = function(Value)
                    if Value == "No saved configs" then
                        return
                    end

                    self:SetCurrentConfig(Value)

                    if ConfigInput and ConfigInput.SetValue then
                        ConfigInput:SetValue(Value)
                    end
                end,
            }
        )
    end

    Groupbox:AddButton(
        "SaveConfig",
        {
            Text = "Save Config",
            Callback = function()
                local Name =
                    tostring(self.CurrentConfig or "Default")

                if Name == "" then
                    Name = "Default"
                end

                self.CurrentConfig = Name
                self:Save(Name)
                RefreshSavedConfigs()
            end,
        }
    )

    Groupbox:AddButton(
        "LoadConfig",
        {
            Text = "Load Config",
            Callback = function()
                local Name =
                    tostring(self.CurrentConfig or "Default")

                self:Load(Name)
            end,
        }
    )

    Groupbox:AddButton(
        "DeleteConfig",
        {
            Text = "Delete Config",
            Callback = function()
                local Name =
                    tostring(self.CurrentConfig or "Default")

                if self:Delete(Name) then
                    local ConfigNames = self:AllConfigs()
                    self.CurrentConfig = ConfigNames[1] or "Default"

                    if ConfigInput and ConfigInput.SetValue then
                        ConfigInput:SetValue(self.CurrentConfig)
                    end

                    RefreshSavedConfigs()
                end
            end,
        }
    )

    RefreshSavedConfigs()

    return Groupbox
end

--//==================================================
--// AUTO SAVE
--//==================================================

ConfigManager.AutoSave = false
ConfigManager.AutoSaveName = "Default"
ConfigManager.AutoSaveInterval = 60
ConfigManager._AutoSaveRunning = false

function ConfigManager:EnableAutoSave(Name, Interval)
    self.AutoSave = true
    self.AutoSaveName =
        tostring(Name or "Default")

    self.AutoSaveInterval =
        tonumber(Interval)
        or 60

    if self._AutoSaveRunning then
        return
    end

    self._AutoSaveRunning = true

    task.spawn(function()

        while self.AutoSave do

            task.wait(
                math.max(
                    self.AutoSaveInterval,
                    5
                )
            )

            if self.AutoSave then
                self:Save(
                    self.AutoSaveName
                )
            end
        end

        self._AutoSaveRunning = false
    end)
end

function ConfigManager:DisableAutoSave()
    self.AutoSave = false
end

--//==================================================
--// CURRENT CONFIG
--//==================================================

ConfigManager.CurrentConfig =
    "Default"

function ConfigManager:SetCurrentConfig(Name)
    self.CurrentConfig =
        tostring(Name or "Default")

    return self.CurrentConfig
end

function ConfigManager:GetCurrentConfig()
    return self.CurrentConfig
end

--//==================================================
--// INIT
--//==================================================

function ConfigManager:Init(Library, Folder)
    if Library then
        self:SetLibrary(Library)
    end

    if Folder then
        self:SetFolder(Folder)
    else
        self:SetFolder("MoonHub")
    end

    self:Refresh()

    return self
end

return ConfigManager
