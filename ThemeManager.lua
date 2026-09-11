--[[
    MoonHub ThemeManager.lua
    Compatible with the MoonHub Library.lua

    IMPORTANT:
    MoonHub Library.lua already contains:
        Library.Theme
        Library:SetTheme(Theme)
        Library:SetAccent(Color3)

    This ThemeManager adds:
        - Built-in themes
        - Save / Load theme
        - Delete theme
        - List themes
        - Apply theme
        - Set accent
        - BuildThemeSection(Tab)

    Executor file APIs are required for Save/Load:
        isfolder, makefolder, writefile, readfile,
        isfile, delfile, listfiles
]]

local HttpService = game:GetService("HttpService")

local ThemeManager = {}

ThemeManager.Library = nil
ThemeManager.Folder = "MoonHub/Themes"
ThemeManager.Extension = ".json"

ThemeManager.CurrentTheme = "MoonHub"

-- MoonHub is always the startup theme.
ThemeManager.StartupTheme = "MoonHub"

ThemeManager.Themes = {
    MoonHub = {
        Background = Color3.fromRGB(4, 4, 5),
        Sidebar = Color3.fromRGB(7, 7, 8),
        Panel = Color3.fromRGB(9, 9, 11),
        Element = Color3.fromRGB(14, 14, 17),
        ElementHover = Color3.fromRGB(19, 19, 23),
        Selected = Color3.fromRGB(17, 17, 20),

        Outline = Color3.fromRGB(28, 28, 32),
        OutlineSoft = Color3.fromRGB(22, 22, 24),

        Text = Color3.fromRGB(235, 235, 240),
        TextDim = Color3.fromRGB(215, 215, 222),
        TextBright = Color3.fromRGB(250, 250, 252),
        Placeholder = Color3.fromRGB(120, 120, 126),

        ToggleOff = Color3.fromRGB(35, 35, 40),
        ToggleOn = Color3.fromRGB(85, 85, 92),
        KnobOff = Color3.fromRGB(190, 190, 195),

        Accent = Color3.fromRGB(145, 92, 255),
        AccentSoft = Color3.fromRGB(110, 70, 200),

        Success = Color3.fromRGB(120, 220, 150),
        Warning = Color3.fromRGB(235, 190, 90),
        Error = Color3.fromRGB(235, 95, 95),
    },

    Midnight = {
        Background = Color3.fromRGB(3, 5, 10),
        Sidebar = Color3.fromRGB(6, 8, 14),
        Panel = Color3.fromRGB(9, 12, 19),
        Element = Color3.fromRGB(13, 17, 25),
        ElementHover = Color3.fromRGB(19, 24, 34),
        Selected = Color3.fromRGB(17, 22, 31),

        Outline = Color3.fromRGB(30, 37, 50),
        OutlineSoft = Color3.fromRGB(22, 28, 39),

        Text = Color3.fromRGB(232, 238, 248),
        TextDim = Color3.fromRGB(202, 211, 225),
        TextBright = Color3.fromRGB(248, 251, 255),
        Placeholder = Color3.fromRGB(115, 126, 143),

        ToggleOff = Color3.fromRGB(34, 40, 50),
        ToggleOn = Color3.fromRGB(75, 88, 105),
        KnobOff = Color3.fromRGB(190, 198, 210),

        Accent = Color3.fromRGB(90, 150, 255),
        AccentSoft = Color3.fromRGB(65, 110, 200),

        Success = Color3.fromRGB(110, 220, 155),
        Warning = Color3.fromRGB(235, 190, 90),
        Error = Color3.fromRGB(235, 95, 95),
    },

    Crimson = {
        Background = Color3.fromRGB(6, 4, 5),
        Sidebar = Color3.fromRGB(10, 6, 8),
        Panel = Color3.fromRGB(13, 8, 10),
        Element = Color3.fromRGB(20, 11, 14),
        ElementHover = Color3.fromRGB(28, 15, 19),
        Selected = Color3.fromRGB(24, 13, 17),

        Outline = Color3.fromRGB(48, 25, 31),
        OutlineSoft = Color3.fromRGB(34, 18, 22),

        Text = Color3.fromRGB(240, 232, 235),
        TextDim = Color3.fromRGB(215, 202, 207),
        TextBright = Color3.fromRGB(255, 247, 250),
        Placeholder = Color3.fromRGB(135, 115, 122),

        ToggleOff = Color3.fromRGB(45, 28, 33),
        ToggleOn = Color3.fromRGB(105, 50, 60),
        KnobOff = Color3.fromRGB(195, 180, 185),

        Accent = Color3.fromRGB(235, 70, 105),
        AccentSoft = Color3.fromRGB(190, 55, 85),

        Success = Color3.fromRGB(120, 220, 150),
        Warning = Color3.fromRGB(235, 190, 90),
        Error = Color3.fromRGB(245, 80, 95),
    },

    Emerald = {
        Background = Color3.fromRGB(3, 6, 5),
        Sidebar = Color3.fromRGB(5, 10, 8),
        Panel = Color3.fromRGB(8, 14, 11),
        Element = Color3.fromRGB(12, 20, 16),
        ElementHover = Color3.fromRGB(18, 29, 23),
        Selected = Color3.fromRGB(15, 25, 20),

        Outline = Color3.fromRGB(25, 48, 37),
        OutlineSoft = Color3.fromRGB(19, 35, 28),

        Text = Color3.fromRGB(229, 240, 234),
        TextDim = Color3.fromRGB(202, 220, 211),
        TextBright = Color3.fromRGB(247, 255, 250),
        Placeholder = Color3.fromRGB(112, 135, 123),

        ToggleOff = Color3.fromRGB(29, 43, 35),
        ToggleOn = Color3.fromRGB(55, 100, 76),
        KnobOff = Color3.fromRGB(185, 200, 192),

        Accent = Color3.fromRGB(70, 210, 135),
        AccentSoft = Color3.fromRGB(55, 165, 105),

        Success = Color3.fromRGB(100, 225, 145),
        Warning = Color3.fromRGB(235, 190, 90),
        Error = Color3.fromRGB(235, 95, 95),
    },

    Rose = {
        Background = Color3.fromRGB(7, 4, 6),
        Sidebar = Color3.fromRGB(11, 6, 10),
        Panel = Color3.fromRGB(15, 8, 13),
        Element = Color3.fromRGB(22, 12, 19),
        ElementHover = Color3.fromRGB(31, 16, 26),
        Selected = Color3.fromRGB(27, 14, 23),

        Outline = Color3.fromRGB(48, 26, 42),
        OutlineSoft = Color3.fromRGB(35, 19, 30),

        Text = Color3.fromRGB(241, 232, 238),
        TextDim = Color3.fromRGB(216, 201, 211),
        TextBright = Color3.fromRGB(255, 247, 252),
        Placeholder = Color3.fromRGB(137, 116, 130),

        ToggleOff = Color3.fromRGB(46, 29, 40),
        ToggleOn = Color3.fromRGB(105, 55, 91),
        KnobOff = Color3.fromRGB(198, 184, 193),

        Accent = Color3.fromRGB(235, 90, 175),
        AccentSoft = Color3.fromRGB(190, 70, 140),

        Success = Color3.fromRGB(120, 220, 150),
        Warning = Color3.fromRGB(235, 190, 90),
        Error = Color3.fromRGB(240, 90, 110),
    },
}

local function CanUseFileSystem()
    return type(isfolder) == "function"
        and type(makefolder) == "function"
        and type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
        and type(delfile) == "function"
end

local function EnsureFolder(Path)
    if not CanUseFileSystem() then
        return false
    end

    if not isfolder(Path) then
        pcall(function()
            makefolder(Path)
        end)
    end

    return isfolder(Path)
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

local function SerializeColor(Value)
    if typeof(Value) == "Color3" then
        return {
            R = math.floor(Value.R * 255 + 0.5),
            G = math.floor(Value.G * 255 + 0.5),
            B = math.floor(Value.B * 255 + 0.5),
        }
    end

    return Value
end

local function DeserializeColor(Value)
    if type(Value) == "table"
        and Value.R ~= nil
        and Value.G ~= nil
        and Value.B ~= nil then

        return Color3.fromRGB(
            tonumber(Value.R) or 0,
            tonumber(Value.G) or 0,
            tonumber(Value.B) or 0
        )
    end

    return Value
end

local function SerializeTheme(Theme)
    local Result = {}

    for Key, Value in pairs(Theme or {}) do
        Result[Key] = SerializeColor(Value)
    end

    return Result
end

local function DeserializeTheme(Theme)
    local Result = {}

    for Key, Value in pairs(Theme or {}) do
        Result[Key] = DeserializeColor(Value)
    end

    return Result
end

local function GetPath(Name)
    return ThemeManager.Folder
        .. "/"
        .. tostring(Name)
        .. ThemeManager.Extension
end

function ThemeManager:SetLibrary(Library)
    self.Library = Library
    return self
end

function ThemeManager:SetFolder(Folder)
    self.Folder = tostring(Folder or "MoonHub/Themes")

    if CanUseFileSystem() then
        EnsureFolder(self.Folder)
    end

    return self
end

function ThemeManager:GetTheme(Name)
    return self.Themes[tostring(Name)]
end

function ThemeManager:AddTheme(Name, Theme)
    Name = tostring(Name or "")

    if Name == "" or type(Theme) ~= "table" then
        return false
    end

    self.Themes[Name] = Theme
    return true
end

function ThemeManager:RemoveTheme(Name)
    Name = tostring(Name or "")

    if self.Themes[Name] == nil then
        return false
    end

    if Name == "MoonHub" then
        return false
    end

    self.Themes[Name] = nil
    return true
end

function ThemeManager:ApplyTheme(Name)
    if not self.Library then
        return false
    end

    Name = tostring(Name or "MoonHub")

    local Theme = self.Themes[Name]

    if not Theme then
        return false
    end

    local Copy = {}
    for Key, Value in pairs(Theme) do Copy[Key] = Value end
    self.Library:SetTheme(Copy)
    self.CurrentTheme = Name
    if self.Library.RefreshTheme then
        self.Library:RefreshTheme()
    end
    return true
end

function ThemeManager:SetAccent(Color)
    if not self.Library then
        return false
    end

    if typeof(Color) ~= "Color3" then
        return false
    end

    self.Library:SetAccent(Color)
    return true
end

function ThemeManager:GetCurrentTheme()
    return self.CurrentTheme
end

function ThemeManager:GetCurrentThemeData()
    if not self.Library then
        return nil
    end

    return self.Library.Theme
end

function ThemeManager:Save(Name)
    if not CanUseFileSystem() then
        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Theme sistemi bu executor'da desteklenmiyor.",
                Time = 4,
            })
        end

        return false
    end

    if not self.Library then
        return false
    end

    Name = tostring(Name or self.CurrentTheme or "MoonHub")

    if Name == "" then
        Name = "MoonHub"
    end

    EnsureFolder(self.Folder)

    local Theme = SerializeTheme(self.Library.Theme)

    Theme.Version = 1
    Theme.Name = Name

    local Encoded = Encode(Theme)

    if not Encoded then
        return false
    end

    local Success = pcall(function()
        writefile(GetPath(Name), Encoded)
    end)

    if Success then
        self.CurrentTheme = Name

        if self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Theme kaydedildi: " .. Name,
                Time = 3,
            })
        end

        return true
    end

    return false
end

function ThemeManager:Load(Name)
    if not CanUseFileSystem() then
        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Theme sistemi bu executor'da desteklenmiyor.",
                Time = 4,
            })
        end

        return false
    end

    if not self.Library then
        return false
    end

    Name = tostring(Name or "MoonHub")

    local Path = GetPath(Name)

    if not isfile(Path) then
        if self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Theme bulunamadı: " .. Name,
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

    local Data = Decode(Raw)

    if type(Data) ~= "table" then
        return false
    end

    Data.Version = nil
    Data.Name = nil

    local Theme = DeserializeTheme(Data)

    self.Library:SetTheme(Theme)
    self.CurrentTheme = Name
    if self.Library.RefreshTheme then
        self.Library:RefreshTheme()
    end

    if self.Library.Notify then
        self.Library:Notify({
            Title = "MoonHub",
            Description = "Theme yüklendi: " .. Name,
            Time = 3,
        })
    end

    return true
end

function ThemeManager:Delete(Name)
    if not CanUseFileSystem() then
        return false
    end

    Name = tostring(Name or "")

    if Name == "" then
        return false
    end

    local Path = GetPath(Name)

    if not isfile(Path) then
        return false
    end

    local Success = pcall(function()
        delfile(Path)
    end)

    if Success then
        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = "MoonHub",
                Description = "Theme silindi: " .. Name,
                Time = 3,
            })
        end

        return true
    end

    return false
end

function ThemeManager:Exists(Name)
    if not CanUseFileSystem() then
        return false
    end

    Name = tostring(Name or "MoonHub")

    return isfile(GetPath(Name))
end

function ThemeManager:AllThemes()
    local Themes = {}

    for Name in pairs(self.Themes) do
        table.insert(Themes, Name)
    end

    if CanUseFileSystem()
        and type(listfiles) == "function" then

        EnsureFolder(self.Folder)

        local Success, Files = pcall(function()
            return listfiles(self.Folder)
        end)

        if Success and type(Files) == "table" then
            for _, Path in ipairs(Files) do
                if string.sub(Path, -#self.Extension) == self.Extension then
                    local FileName = string.match(Path, "([^/\\]+)")

                    if FileName then
                        FileName = string.sub(
                            FileName,
                            1,
                            #FileName - #self.Extension
                        )

                        local Exists = false

                        for _, Existing in ipairs(Themes) do
                            if Existing == FileName then
                                Exists = true
                                break
                            end
                        end

                        if not Exists then
                            table.insert(Themes, FileName)
                        end
                    end
                end
            end
        end
    end

    -- MoonHub her zaman listenin ilk teması olsun.
    -- Kalan temalar alfabetik sıralanır.
    table.sort(Themes, function(A, B)
        if A == self.StartupTheme then
            return true
        end
        if B == self.StartupTheme then
            return false
        end
        return A < B
    end)

    return Themes
end

function ThemeManager:BuildThemeSection(Tab)
    if not Tab then
        return nil
    end

    local Groupbox = Tab:AddLeftGroupbox("Themes")
    local ThemeDropdown

    local function RefreshThemeDropdown()
        if ThemeDropdown then
            pcall(function()
                ThemeDropdown:Destroy()
            end)
            ThemeDropdown = nil
        end

        local ThemeNames = self:AllThemes()
        if #ThemeNames == 0 then
            ThemeNames = { self.StartupTheme }
        end

        local DefaultTheme = 1
        for Index, Name in ipairs(ThemeNames) do
            if Name == self.CurrentTheme then
                DefaultTheme = Index
                break
            end
        end

        ThemeDropdown = Groupbox:AddDropdown("ThemeSelect", {
            Text = "Theme",
            Values = ThemeNames,
            Default = DefaultTheme,
            Callback = function(Value)
                if Value then
                    self:ApplyTheme(Value)
                end
            end,
        })
    end

    Groupbox:AddButton("SaveTheme", {
        Text = "Save Theme",
        Callback = function()
            self:Save(self.CurrentTheme)
            RefreshThemeDropdown()
        end,
    })

    Groupbox:AddButton("LoadTheme", {
        Text = "Load Theme",
        Callback = function()
            self:Load(self.CurrentTheme)
            RefreshThemeDropdown()
        end,
    })

    Groupbox:AddButton("DeleteTheme", {
        Text = "Delete Theme",
        Callback = function()
            if self.CurrentTheme ~= self.StartupTheme then
                if self:Delete(self.CurrentTheme) then
                    self.CurrentTheme = self.StartupTheme

                    local MoonHubTheme = self.Themes[self.StartupTheme]
                    if self.Library and self.Library.SetTheme and MoonHubTheme then
                        local Copy = {}
                        for Key, Value in pairs(MoonHubTheme) do
                            Copy[Key] = Value
                        end

                        self.Library:SetTheme(Copy)
                        if self.Library.RefreshTheme then
                            self.Library:RefreshTheme()
                        end
                    end
                end
            end

            RefreshThemeDropdown()
        end,
    })

    RefreshThemeDropdown()

    return Groupbox
end

function ThemeManager:ApplyToTab(Tab)
    if not Tab then
        return nil
    end

    return self:BuildThemeSection(Tab)
end

function ThemeManager:Init(Library, Folder)
    if Library then
        self:SetLibrary(Library)

        -- MoonHub her zaman başlangıç teması olsun.
        self.CurrentTheme = "MoonHub"

        local MoonHubTheme = self.Themes.MoonHub
        if MoonHubTheme then
            local Copy = {}

            for Key, Value in pairs(MoonHubTheme) do
                Copy[Key] = Value
            end

            self.Library:SetTheme(Copy)

            if self.Library.RefreshTheme then
                self.Library:RefreshTheme()
            end
        end
    end

    if Folder then
        self:SetFolder(Folder)
    else
        self:SetFolder("MoonHub/Themes")
    end

    return self
end

return ThemeManager
