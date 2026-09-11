local HttpService = game:GetService("HttpService")

local ConfigManager = {}

ConfigManager.Library = nil
ConfigManager.Folder = "MoonHub"
ConfigManager.ConfigExtension = ".json"
ConfigManager.CurrentConfig = "Default"
ConfigManager.AutoSave = false
ConfigManager.AutoSaveName = "Default"
ConfigManager.AutoSaveInterval = 60
ConfigManager._AutoSaveRunning = false

ConfigManager.Parser = {
    Toggles = {},
    Options = {},
    Inputs = {},
    Sliders = {},
}

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

local function CleanName(Name)
    Name = tostring(Name or "")
    Name = Name:gsub("[<>:\"/\\|%?%*]", "")
    Name = Name:gsub("%c", "")
    Name = Name:gsub("^%s+", "")
    Name = Name:gsub("%s+$", "")

    if Name == "" then
        Name = "Default"
    end

    return Name
end

local function GetConfigPath(Name)
    return ConfigManager.Folder
        .. "/"
        .. CleanName(Name)
        .. ConfigManager.ConfigExtension
end

function ConfigManager:SetLibrary(Library)
    self.Library = Library
    return self
end

function ConfigManager:SetFolder(Folder)
    self.Folder = tostring(Folder or "MoonHub")
    EnsureFolder(self.Folder)
    return self
end

function ConfigManager:RegisterToggle(Key, Toggle)
    if Key and Toggle then
        self.Parser.Toggles[tostring(Key)] = Toggle
    end
end

function ConfigManager:RegisterOption(Key, Option)
    if Key and Option then
        self.Parser.Options[tostring(Key)] = Option
    end
end

function ConfigManager:RegisterInput(Key, Input)
    if Key and Input then
        self.Parser.Inputs[tostring(Key)] = Input
    end
end

function ConfigManager:RegisterSlider(Key, Slider)
    if Key and Slider then
        self.Parser.Sliders[tostring(Key)] = Slider
    end
end

function ConfigManager:Refresh()
    if not self.Library then
        return self
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

function ConfigManager:GetConfig()
    self:Refresh()

    local Config = {
        Toggles = {},
        Options = {},
        Inputs = {},
        Sliders = {},
    }

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

    for Key, Input in pairs(self.Parser.Inputs) do
        if Input.Box and Input.Box.Text ~= nil then
            Config.Inputs[Key] = tostring(Input.Box.Text)
        elseif Input.GetValue then
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

function ConfigManager:LoadData(Config)
    if type(Config) ~= "table" then
        return false
    end

    self:Refresh()

    if type(Config.Toggles) == "table" then
        for Key, Value in pairs(Config.Toggles) do
            local Toggle = self.Parser.Toggles[Key]

            if Toggle and Toggle.SetValue then
                pcall(function()
                    Toggle:SetValue(Value == true)
                end)
            end
        end
    end

    if type(Config.Options) == "table" then
        for Key, Value in pairs(Config.Options) do
            local Option = self.Parser.Options[Key]

            if Option and Option.SetValue then
                pcall(function()
                    Option:SetValue(Value)
                end)
            end
        end
    end

    if type(Config.Inputs) == "table" then
        for Key, Value in pairs(Config.Inputs) do
            local Input = self.Parser.Inputs[Key]

            if Input and Input.SetValue then
                pcall(function()
                    Input:SetValue(Value)
                end)
            end
        end
    end

    if type(Config.Sliders) == "table" then
        for Key, Value in pairs(Config.Sliders) do
            local Slider = self.Parser.Sliders[Key]

            if Slider and Slider.SetValue then
                pcall(function()
                    Slider:SetValue(Value)
                end)
            end
        end
    end

    return true
end

function ConfigManager:Save(Name)
    if not CanUseFileSystem() then
        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Config sistemi bu executor'da desteklenmiyor.",
                Time = 4,
            })
        end
        return false
    end

    Name = CleanName(Name)

    if not EnsureFolder(self.Folder) then
        return false
    end

    local Config = self:GetConfig()
    Config.Version = 1
    Config.Name = Name

    local Encoded = Encode(Config)
    if not Encoded then
        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Config kaydedilemedi.",
                Time = 4,
            })
        end
        return false
    end

    local Path = GetConfigPath(Name)
    local Success = pcall(function()
        writefile(Path, Encoded)
    end)

    if not Success then
        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Config kaydedilemedi: " .. Name,
                Time = 4,
            })
        end
        return false
    end

    self.CurrentConfig = Name

    if self.Library and self.Library.Notify then
        self.Library:Notify({
            Title = "MoonHub",
            Description = "Config kaydedildi: " .. Name,
            Time = 3,
        })
    end

    return true
end

function ConfigManager:Load(Name)
    if not CanUseFileSystem() then
        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Config sistemi bu executor'da desteklenmiyor.",
                Time = 4,
            })
        end
        return false
    end

    Name = CleanName(Name)
    local Path = GetConfigPath(Name)

    if not isfile(Path) then
        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Config bulunamadı: " .. Name,
                Time = 4,
            })
        end
        return false
    end

    local Success, Raw = pcall(function()
        return readfile(Path)
    end)

    if not Success then
        return false
    end

    local Config = Decode(Raw)
    if not Config then
        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Config okunamadı: " .. Name,
                Time = 4,
            })
        end
        return false
    end

    local Applied = self:LoadData(Config)

    if Applied then
        self.CurrentConfig = Name

        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Config yüklendi: " .. Name,
                Time = 3,
            })
        end
    end

    return Applied
end

function ConfigManager:Delete(Name)
    if not CanUseFileSystem() then
        return false
    end

    Name = CleanName(Name)
    local Path = GetConfigPath(Name)

    if not isfile(Path) then
        return false
    end

    local Success = pcall(function()
        delfile(Path)
    end)

    if Success then
        if self.CurrentConfig == Name then
            self.CurrentConfig = "Default"
        end

        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Config silindi: " .. Name,
                Time = 3,
            })
        end

        return true
    end

    return false
end

function ConfigManager:Exists(Name)
    if not CanUseFileSystem() then
        return false
    end

    return isfile(GetConfigPath(CleanName(Name)))
end

function ConfigManager:AllConfigs()
    if not CanUseFileSystem() then
        return {}
    end

    if not EnsureFolder(self.Folder) then
        return {}
    end

    if type(listfiles) ~= "function" then
        return {}
    end

    local Success, Result = pcall(function()
        return listfiles(self.Folder)
    end)

    if not Success or type(Result) ~= "table" then
        return {}
    end

    local Files = {}
    local Seen = {}

    for _, Path in ipairs(Result) do
        if type(Path) == "string"
            and string.sub(Path, -#self.ConfigExtension) == self.ConfigExtension then

            local FileName = string.match(Path, "([^/\\]+)$")

            if FileName then
                FileName = string.sub(
                    FileName,
                    1,
                    #FileName - #self.ConfigExtension
                )

                if FileName ~= "" and not Seen[FileName] then
                    Seen[FileName] = true
                    table.insert(Files, FileName)
                end
            end
        end
    end

    table.sort(Files, function(A, B)
        return string.lower(A) < string.lower(B)
    end)

    return Files
end

function ConfigManager:BuildConfigSection(Tab)
    if not Tab then
        return nil
    end

    local Groupbox = Tab:AddLeftGroupbox("Configuration")
    local SavedConfigsDropdown
    local ConfigInput

    local function GetInputName()
        local Name

        if ConfigInput and ConfigInput.Box then
            Name = ConfigInput.Box.Text
        end

        if Name == nil or tostring(Name):match("^%s*$") then
            Name = self.CurrentConfig or "Default"
        end

        return CleanName(Name)
    end

    local function SetInputName(Name)
        Name = CleanName(Name)
        self.CurrentConfig = Name

        if ConfigInput and ConfigInput.SetValue then
            pcall(function()
                ConfigInput:SetValue(Name)
            end)
        elseif ConfigInput and ConfigInput.Box then
            ConfigInput.Box.Text = Name
            ConfigInput.Value = Name
        end
    end

    local function RefreshSavedConfigs()
        local ConfigNames = self:AllConfigs()
        local Current = CleanName(self.CurrentConfig)
        local DefaultIndex = 1

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

        if SavedConfigsDropdown and SavedConfigsDropdown.SetValues then
            SavedConfigsDropdown:SetValues(ConfigNames, DefaultIndex)
            return
        end

        SavedConfigsDropdown = Groupbox:AddDropdown("SavedConfigs", {
            Text = "Saved Configs",
            Values = ConfigNames,
            Default = DefaultIndex,
            Callback = function(Value)
                if Value == "No saved configs" then
                    return
                end

                SetInputName(Value)
            end,
        })
    end

    RefreshSavedConfigs()

    ConfigInput = Groupbox:AddInput("ConfigName", {
        Text = "Config Name",
        Default = self.CurrentConfig or "Default",
        Placeholder = "Config name...",
        ClearTextOnFocus = false,
        Callback = function(Value)
            local Name = CleanName(Value)
            self.CurrentConfig = Name
        end,
    })

    Groupbox:AddButton("SaveConfig", {
        Text = "Save Config",
        Callback = function()
            local Name = GetInputName()
            SetInputName(Name)

            if self:Save(Name) then
                RefreshSavedConfigs()
            end
        end,
    })

    Groupbox:AddButton("LoadConfig", {
        Text = "Load Config",
        Callback = function()
            local Name = GetInputName()

            if self:Load(Name) then
                SetInputName(Name)
            end
        end,
    })

    Groupbox:AddButton("DeleteConfig", {
        Text = "Delete Config",
        Callback = function()
            local Name = GetInputName()

            if self:Delete(Name) then
                local ConfigNames = self:AllConfigs()
                local NextName = ConfigNames[1] or "Default"
                SetInputName(NextName)
                RefreshSavedConfigs()
            end
        end,
    })

    RefreshSavedConfigs()

    return Groupbox
end

function ConfigManager:EnableAutoSave(Name, Interval)
    self.AutoSave = true
    self.AutoSaveName = CleanName(Name or "Default")
    self.AutoSaveInterval = tonumber(Interval) or 60

    if self._AutoSaveRunning then
        return
    end

    self._AutoSaveRunning = true

    task.spawn(function()
        while self.AutoSave do
            task.wait(math.max(self.AutoSaveInterval, 5))

            if self.AutoSave then
                self:Save(self.AutoSaveName)
            end
        end

        self._AutoSaveRunning = false
    end)
end

function ConfigManager:DisableAutoSave()
    self.AutoSave = false
end

function ConfigManager:SetCurrentConfig(Name)
    self.CurrentConfig = CleanName(Name)
    return self.CurrentConfig
end

function ConfigManager:GetCurrentConfig()
    return self.CurrentConfig
end

function ConfigManager:Init(Library, Folder)
    if Library then
        self:SetLibrary(Library)
    end

    self:SetFolder(Folder or "MoonHub")
    self:Refresh()

    return self
end

return ConfigManager
