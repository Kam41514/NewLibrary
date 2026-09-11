--[[
    MoonHub ConfigManager.lua
    Compatible with MoonHub Library.lua

    Features:
        - Save configuration
        - Load configuration
        - Delete configuration
        - Config dropdown
        - Automatic config list refresh
        - Get configuration list
        - Auto-save helpers
        - Config folder creation
        - JSON based storage
        - Toggle support
        - Dropdown support
        - Input support
        - Slider support

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

        -- Delete:
        ConfigManager:Delete("MyConfig")

        -- Get configs:
        local Configs = ConfigManager:AllConfigs()
]]

local HttpService = game:GetService("HttpService")

local ConfigManager = {}

ConfigManager.Library = nil
ConfigManager.Folder = "MoonHub"
ConfigManager.ConfigExtension = ".json"

ConfigManager.CurrentConfig = "Default"

ConfigManager.Parser = {
    Toggles = {},
    Options = {},
    Inputs = {},
    Sliders = {},
}

ConfigManager.ConfigDropdown = nil
ConfigManager.ConfigInput = nil
ConfigManager.ConfigGroupbox = nil

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
    local Success, Result = pcall(function()
        return HttpService:JSONEncode(Data)
    end)

    if Success then
        return Result
    end

    return nil
end

local function Decode(Data)
    local Success, Result = pcall(function()
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

local function Notify(Title, Description, Time)
    if ConfigManager.Library
        and ConfigManager.Library.Notify then

        ConfigManager.Library:Notify({
            Title = Title or "MoonHub",
            Description = Description or "",
            Time = Time or 3,
        })
    end
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
        return self
    end

    -- Toggles
    if self.Library.Toggles then
        for Key, Toggle in pairs(self.Library.Toggles) do
            self:RegisterToggle(Key, Toggle)
        end
    end

    -- Dropdowns
    if self.Library.Options then
        for Key, Option in pairs(self.Library.Options) do
            self:RegisterOption(Key, Option)
        end
    end

    -- Inputs
    if self.Library.Labels then
        for Key, Label in pairs(self.Library.Labels) do
            if Label.Type == "Input" then
                self:RegisterInput(Key, Label)
            end
        end
    end

    -- Sliders
    if self.Library.Sliders then
        for Key, Slider in pairs(self.Library.Sliders) do
            self:RegisterSlider(Key, Slider)
        end
    end

    return self
end

--//==================================================
--// COLLECT CONFIG
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

    for Key, Toggle in pairs(self.Parser.Toggles) do

        if Toggle.GetValue then

            local Success, Value = pcall(function()
                return Toggle:GetValue()
            end)

            if Success then
                Config.Toggles[Key] = Value
            end

        elseif Toggle.Value ~= nil then

            Config.Toggles[Key] = Toggle.Value

        end
    end

    --// DROPDOWNS

    for Key, Option in pairs(self.Parser.Options) do

        if Option.GetValue then

            local Success, Value = pcall(function()
                return Option:GetValue()
            end)

            if Success then
                Config.Options[Key] = Value
            end

        elseif Option.Value ~= nil then

            Config.Options[Key] = Option.Value

        end
    end

    --// INPUTS

    for Key, Input in pairs(self.Parser.Inputs) do

        if Input.GetValue then

            local Success, Value = pcall(function()
                return Input:GetValue()
            end)

            if Success then
                Config.Inputs[Key] = Value
            end

        elseif Input.Value ~= nil then

            Config.Inputs[Key] = Input.Value

        end
    end

    --// SLIDERS

    for Key, Slider in pairs(self.Parser.Sliders) do

        if Slider.GetValue then

            local Success, Value = pcall(function()
                return Slider:GetValue()
            end)

            if Success then
                Config.Sliders[Key] = Value
            end

        elseif Slider.Value ~= nil then

            Config.Sliders[Key] = Slider.Value

        end
    end

    return Config
end

--//==================================================
--// APPLY CONFIG
--//==================================================

function ConfigManager:LoadData(Config)
    if type(Config) ~= "table" then
        return false
    end

    self:Refresh()

    --// TOGGLES

    if type(Config.Toggles) == "table" then

        for Key, Value in pairs(Config.Toggles) do

            local Toggle = self.Parser.Toggles[Key]

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

        for Key, Value in pairs(Config.Options) do

            local Option = self.Parser.Options[Key]

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

        for Key, Value in pairs(Config.Inputs) do

            local Input = self.Parser.Inputs[Key]

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

        for Key, Value in pairs(Config.Sliders) do

            local Slider = self.Parser.Sliders[Key]

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

        Notify(
            "MoonHub",
            "Config sistemi bu executor'da desteklenmiyor.",
            4
        )

        return false
    end

    Name = tostring(Name or self.CurrentConfig or "Default")

    if Name == "" then
        Name = "Default"
    end

    EnsureFolder(self.Folder)

    local Config = self:GetConfig()

    Config.Version = 1
    Config.Name = Name

    local Encoded = Encode(Config)

    if not Encoded then

        Notify(
            "MoonHub",
            "Config kaydedilemedi.",
            4
        )

        return false
    end

    local Path = GetConfigPath(Name)

    local Success = pcall(function()
        writefile(
            Path,
            Encoded
        )
    end)

    if Success then

        self.CurrentConfig = Name

        -- Input varsa güncelle
        if self.ConfigInput
            and self.ConfigInput.SetValue then

            pcall(function()
                self.ConfigInput:SetValue(Name)
            end)

        end

        -- Dropdown'u yenile
        self:RefreshConfigDropdown(Name)

        Notify(
            "MoonHub",
            "Config kaydedildi: " .. Name,
            3
        )

        return true
    end

    Notify(
        "MoonHub",
        "Config kaydedilemedi: " .. Name,
        4
    )

    return false
end

--//==================================================
--// LOAD
--//==================================================

function ConfigManager:Load(Name)

    if not CanUseFileSystem() then

        Notify(
            "MoonHub",
            "Config sistemi bu executor'da desteklenmiyor.",
            4
        )

        return false
    end

    Name = tostring(
        Name
        or self.CurrentConfig
        or "Default"
    )

    if Name == ""
        or Name == "No configs" then

        Notify(
            "MoonHub",
            "Yüklenecek config seçilmedi.",
            3
        )

        return false
    end

    local Path = GetConfigPath(Name)

    if not isfile(Path) then

        Notify(
            "MoonHub",
            "Config bulunamadı: " .. Name,
            4
        )

        return false
    end

    local Success, Raw = pcall(function()
        return readfile(Path)
    end)

    if not Success then

        Notify(
            "MoonHub",
            "Config okunamadı: " .. Name,
            4
        )

        return false
    end

    local Config = Decode(Raw)

    if not Config then

        Notify(
            "MoonHub",
            "Config JSON verisi bozuk: " .. Name,
            4
        )

        return false
    end

    local Applied = self:LoadData(Config)

    if Applied then

        self.CurrentConfig = Name

        if self.ConfigInput
            and self.ConfigInput.SetValue then

            pcall(function()
                self.ConfigInput:SetValue(Name)
            end)

        end

        if self.ConfigDropdown
            and self.ConfigDropdown.SetValue then

            pcall(function()
                self.ConfigDropdown:SetValue(Name)
            end)

        end

        Notify(
            "MoonHub",
            "Config yüklendi: " .. Name,
            3
        )

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

    Name = tostring(
        Name
        or self.CurrentConfig
        or "Default"
    )

    if Name == ""
        or Name == "No configs" then
        return false
    end

    local Path = GetConfigPath(Name)

    if not isfile(Path) then

        Notify(
            "MoonHub",
            "Config bulunamadı: " .. Name,
            3
        )

        return false
    end

    local Success = pcall(function()
        delfile(Path)
    end)

    if Success then

        Notify(
            "MoonHub",
            "Config silindi: " .. Name,
            3
        )

        local Configs = self:AllConfigs()

        if #Configs > 0 then

            self.CurrentConfig = Configs[1]

        else

            self.CurrentConfig = "Default"

        end

        -- Input'u güncelle
        if self.ConfigInput
            and self.ConfigInput.SetValue then

            pcall(function()
                self.ConfigInput:SetValue(
                    self.CurrentConfig
                )
            end)

        end

        -- Dropdown'u yenile
        self:RefreshConfigDropdown(
            self.CurrentConfig
        )

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

    Name = tostring(
        Name
        or self.CurrentConfig
        or "Default"
    )

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

    local Success, Result = pcall(function()
        return listfiles(self.Folder)
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

            local FileName = string.match(
                Path,
                "([^/\\]+)"
            )

            if FileName then

                FileName = string.sub(
                    FileName,
                    1,
                    #FileName - #self.ConfigExtension
                )

                if FileName ~= "" then

                    table.insert(
                        Files,
                        FileName
                    )

                end
            end
        end
    end

    table.sort(Files, function(A, B)
        return string.lower(A)
            < string.lower(B)
    end)

    return Files
end

--//==================================================
--// REFRESH CONFIG DROPDOWN
--//==================================================

function ConfigManager:RefreshConfigDropdown(SelectedName)

    if not self.ConfigGroupbox then
        return
    end

    local Configs = self:AllConfigs()

    local Values = {}

    for _, Name in ipairs(Configs) do
        table.insert(
            Values,
            Name
        )
    end

    -- Hiç config yoksa placeholder
    if #Values == 0 then
        Values = {
            "No configs"
        }
    end

    -- Eski dropdown'u temizle
    if self.ConfigDropdown then

        pcall(function()
            self.ConfigDropdown:Destroy()
        end)

        self.ConfigDropdown = nil
    end

    local DefaultValue = SelectedName

    if not DefaultValue
        or DefaultValue == ""
        or DefaultValue == "Default" then

        if #Configs > 0 then
            DefaultValue = Configs[1]
        else
            DefaultValue = "No configs"
        end
    end

    -- Seçilen config gerçekten listede mi?
    local Found = false

    for _, Name in ipairs(Values) do

        if Name == DefaultValue then
            Found = true
            break
        end
    end

    if not Found then

        if #Configs > 0 then
            DefaultValue = Configs[1]
        else
            DefaultValue = "No configs"
        end

    end

    self.CurrentConfig = DefaultValue

    self.ConfigDropdown =
        self.ConfigGroupbox:AddDropdown(
            "SavedConfigs",
            {
                Text = "Saved Configs",
                Values = Values,
                Default = DefaultValue,

                Callback = function(Value)

                    Value = tostring(
                        Value or ""
                    )

                    if Value == ""
                        or Value == "No configs" then
                        return
                    end

                    self.CurrentConfig = Value

                    -- Config name input'u da eşitle
                    if self.ConfigInput
                        and self.ConfigInput.SetValue then

                        pcall(function()
                            self.ConfigInput:SetValue(
                                Value
                            )
                        end)

                    end
                end,
            }
        )

    return self.ConfigDropdown
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

    self.ConfigGroupbox = Groupbox

    --// CONFIG NAME INPUT

    self.ConfigInput =
        Groupbox:AddInput(
            "ConfigName",
            {
                Text = "Config Name",
                Default = self.CurrentConfig
                    or "Default",

                Placeholder =
                    "Config name...",

                ClearTextOnFocus = false,

                Callback = function(Value)

                    Value = tostring(
                        Value or ""
                    )

                    if Value ~= "" then
                        self.CurrentConfig = Value
                    end

                end,
            }
        )

    --// SAVED CONFIG DROPDOWN

    self:RefreshConfigDropdown(
        self.CurrentConfig
    )

    --// SAVE BUTTON

    Groupbox:AddButton(
        "SaveConfig",
        {
            Text = "Save Config",

            Callback = function()

                local Name =
                    self.CurrentConfig
                    or "Default"

                if self.ConfigInput
                    and self.ConfigInput.GetValue then

                    local Success, Value =
                        pcall(function()
                            return self.ConfigInput:GetValue()
                        end)

                    if Success
                        and Value
                        and tostring(Value) ~= "" then

                        Name = tostring(Value)

                    end
                end

                if Name == ""
                    or Name == "No configs" then

                    Name = "Default"

                end

                self:Save(Name)

            end,
        }
    )

    --// LOAD BUTTON

    Groupbox:AddButton(
        "LoadConfig",
        {
            Text = "Load Config",

            Callback = function()

                local Name =
                    self.CurrentConfig

                if self.ConfigDropdown
                    and self.ConfigDropdown.GetValue then

                    local Success, Value =
                        pcall(function()
                            return self.ConfigDropdown:GetValue()
                        end)

                    if Success
                        and Value
                        and tostring(Value) ~= ""
                        and tostring(Value) ~= "No configs" then

                        Name = tostring(Value)

                    end
                end

                self:Load(Name)

            end,
        }
    )

    --// DELETE BUTTON

    Groupbox:AddButton(
        "DeleteConfig",
        {
            Text = "Delete Config",

            Callback = function()

                local Name =
                    self.CurrentConfig

                if self.ConfigDropdown
                    and self.ConfigDropdown.GetValue then

                    local Success, Value =
                        pcall(function()
                            return self.ConfigDropdown:GetValue()
                        end)

                    if Success
                        and Value
                        and tostring(Value) ~= ""
                        and tostring(Value) ~= "No configs" then

                        Name = tostring(Value)

                    end
                end

                self:Delete(Name)

            end,
        }
    )

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
        tostring(
            Name
            or self.CurrentConfig
            or "Default"
        )

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

function ConfigManager:SetCurrentConfig(Name)

    Name = tostring(
        Name or "Default"
    )

    self.CurrentConfig = Name

    if self.ConfigInput
        and self.ConfigInput.SetValue then

        pcall(function()
            self.ConfigInput:SetValue(Name)
        end)

    end

    if self.ConfigDropdown
        and self.ConfigDropdown.SetValue
        and Name ~= "No configs" then

        pcall(function()
            self.ConfigDropdown:SetValue(Name)
        end)

    end

    return self.CurrentConfig
end

function ConfigManager:GetCurrentConfig()
    return self.CurrentConfig
end

--//==================================================
--// INIT
--//==================================================

function ConfigManager:Init(
    Library,
    Folder
)

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
