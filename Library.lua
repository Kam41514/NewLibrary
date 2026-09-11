--[[
    MoonHub Library.lua
    Obsidian-style API, MoonHub visual style.

    Supported API:
        local Library = loadstring(game:HttpGet("YOUR_URL"))()

        local Window = Library:CreateWindow({
            Title = "Moon Hub",
            Footer = "MoonHub"
        })

        local Tabs = {
            Main = Window:AddTab("Main"),
            Settings = Window:AddTab("Settings")
        }

        local Left = Tabs.Main:AddLeftGroupbox("Movement")
        local Right = Tabs.Main:AddRightGroupbox("Combat")

        Left:AddToggle("Speed", {
            Text = "Speed",
            Default = false,
            Callback = function(Value) end
        })

        Left:AddDropdown("Mode", {
            Text = "Mode",
            Values = {"Default", "Fast", "Extreme"},
            Default = 1,
            Callback = function(Value) end
        })

        Right:AddButton("Test", function() end)

        Library:Notify({
            Title = "MoonHub",
            Description = "Loaded successfully.",
            Time = 5
        })
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {}

--//==================================================
--// THEME
--//==================================================

Library.Theme = {
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
}

Library.Toggles = {}
Library.Options = {}
Library.Labels = {}
Library.Buttons = {}
Library.Windows = {}

Library.Unloaded = false
Library.CurrentWindow = nil
Library._ThemeCallbacks = {}

function Library:RegisterThemeCallback(Callback)
    table.insert(self._ThemeCallbacks, Callback)
    return Callback
end

--//==================================================
--// HELPERS
--//==================================================

local function New(className, properties)
    local Object = Instance.new(className)

    for Property, Value in pairs(properties or {}) do
        Object[Property] = Value
    end

    return Object
end

local function Corner(Object, Radius)
    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, Radius or 6)
    C.Parent = Object
    return C
end

local function Stroke(Object, Color, Transparency, Thickness)
    local S = Instance.new("UIStroke")
    S.Color = Color or Library.Theme.Outline
    S.Transparency = Transparency or 0
    S.Thickness = Thickness or 1
    S.Parent = Object
    return S
end

local function Tween(Object, Time, Properties)
    local T = TweenService:Create(
        Object,
        TweenInfo.new(
            Time or 0.12,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        Properties
    )

    T:Play()
    return T
end

local function NormalizeName(Name)
    return string.lower(tostring(Name or ""))
end

local function MakeKey(Identifier, Options)
    if type(Identifier) == "table" then
        return tostring(Identifier.Text or Identifier.Name or "Element"), Identifier
    end

    return tostring(Identifier), Options or {}
end

local function GetValue(Options, Key, Default)
    if Options[Key] ~= nil then
        return Options[Key]
    end

    return Default
end

--//==================================================
--// NOTIFICATIONS
--//==================================================

local NotificationGui
local NotificationList
local Notifications = {}

local function CreateNotificationGui()
    if NotificationGui and NotificationGui.Parent then
        return
    end

    NotificationGui = New("ScreenGui", {
        Name = "MoonHubNotifications",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = PlayerGui,
    })

    local Area = New("Frame", {
        Name = "NotificationArea",
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, 14, 0, 88),
        Size = UDim2.new(0, 330, 1, -102),
        BackgroundTransparency = 1,
        Parent = NotificationGui,
    })

    NotificationList = New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Area,
    })
end

CreateNotificationGui()

function Library:Notify(Data, Time)
    if Library.Unloaded then
        return
    end

    if type(Data) == "string" then
        Data = {
            Title = "MoonHub",
            Description = Data,
            Time = Time or 5,
        }
    else
        Data = Data or {}
    end

    local Title = tostring(Data.Title or "MoonHub")
    local Description = tostring(
        Data.Description
        or Data.Content
        or Data.Message
        or ""
    )

    local Duration = tonumber(
        Data.Time
        or Data.Duration
        or 5
    ) or 5

    Duration = math.max(Duration, 0.5)

    CreateNotificationGui()

    local Card = New("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, 310, 0, 66),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = -os.clock(),
        Parent = NotificationList.Parent,
    })

    Corner(Card, 7)
    Stroke(Card, Library.Theme.OutlineSoft, 0.18, 1)

    local Accent = New("Frame", {
        Name = "Accent",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        Parent = Card,
    })

    local TitleLabel = New("TextLabel", {
        Name = "Title",
        Position = UDim2.new(0, 13, 0, 9),
        Size = UDim2.new(1, -26, 0, 18),
        BackgroundTransparency = 1,
        Text = Title,
        TextColor3 = Library.Theme.TextBright,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        TextStrokeTransparency = 0.82,
        Parent = Card,
    })

    local DescriptionLabel = New("TextLabel", {
        Name = "Description",
        Position = UDim2.new(0, 13, 0, 27),
        Size = UDim2.new(1, -26, 0, 25),
        BackgroundTransparency = 1,
        Text = Description,
        TextColor3 = Library.Theme.TextDim,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = Card,
    })

    local ProgressBackground = New("Frame", {
        Name = "ProgressBackground",
        Position = UDim2.new(0, 12, 1, -5),
        Size = UDim2.new(1, -24, 0, 2),
        BackgroundColor3 = Color3.fromRGB(25, 25, 29),
        BorderSizePixel = 0,
        Parent = Card,
    })

    Corner(ProgressBackground, 2)

    local Progress = New("Frame", {
        Name = "Progress",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        Parent = ProgressBackground,
    })

    Corner(Progress, 2)

    table.insert(Notifications, Card)

    -- start slightly left and fade in
    Card.Position = UDim2.new(0, -25, 0, 0)
    Card.BackgroundTransparency = 0.35
    TitleLabel.TextTransparency = 0.35
    DescriptionLabel.TextTransparency = 0.35

    Tween(Card, 0.22, {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0,
    })

    Tween(TitleLabel, 0.22, {
        TextTransparency = 0,
    })

    Tween(DescriptionLabel, 0.22, {
        TextTransparency = 0,
    })

    Tween(Progress, Duration, {
        Size = UDim2.new(0, 0, 1, 0),
    })

    task.delay(Duration, function()
        if not Card or not Card.Parent then
            return
        end

        Tween(Card, 0.2, {
            Position = UDim2.new(0, -20, 0, 0),
            BackgroundTransparency = 1,
        })

        Tween(TitleLabel, 0.16, {
            TextTransparency = 1,
        })

        Tween(DescriptionLabel, 0.16, {
            TextTransparency = 1,
        })

        task.delay(0.21, function()
            for Index, Item in ipairs(Notifications) do
                if Item == Card then
                    table.remove(Notifications, Index)
                    break
                end
            end

            if Card then
                Card:Destroy()
            end
        end)
    end)

    return Card
end

--//==================================================
--// ELEMENT OBJECT
--//==================================================

local ElementMethods = {}

function ElementMethods:SetVisible(Value)
    self.Container.Visible = Value ~= false
end

function ElementMethods:AddTooltip(Text)
    self.Tooltip = Text
    return self
end

function ElementMethods:Destroy()
    if self.Container then
        self.Container:Destroy()
    end
end

--//==================================================
--// TOGGLE
--//==================================================

local function CreateToggle(Groupbox, Identifier, Info)
    local Key, Options = MakeKey(Identifier, Info)

    local Text = tostring(
        Options.Text
        or Options.Name
        or Key
    )

    local Default = Options.Default == true
    local Value = Default

    local Container = New("TextButton", {
        Name = Key .. "Toggle",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = Groupbox.Container,
    })

    Corner(Container, 5)
    Stroke(Container, Library.Theme.Outline, 0.25, 1)
    Container:SetAttribute("SearchName", NormalizeName(Key .. " " .. Text))

    local Label = New("TextLabel", {
        Name = "Text",
        Position = UDim2.new(0, 11, 0, 0),
        Size = UDim2.new(1, -55, 1, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Container,
    })

    local Switch = New("Frame", {
        Name = "Switch",
        Position = UDim2.new(1, -40, 0.5, -8),
        Size = UDim2.new(0, 30, 0, 16),
        BackgroundColor3 = Library.Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = Container,
    })

    Corner(Switch, 20)

    local Knob = New("Frame", {
        Name = "Knob",
        Position = UDim2.new(0, 2, 0.5, -6),
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Library.Theme.KnobOff,
        BorderSizePixel = 0,
        Parent = Switch,
    })

    Corner(Knob, 20)

    local Toggle = {
        Type = "Toggle",
        Key = Key,
        Text = Text,
        Value = Value,
        Container = Container,
        Callback = Options.Callback or function() end,
        Changed = Options.Changed or function() end,
    }

    setmetatable(Toggle, {__index = ElementMethods})

    local function UpdateVisual()
        if Value then
            Tween(Switch, 0.15, {
                BackgroundColor3 = Library.Theme.ToggleOn,
            })

            Tween(Knob, 0.15, {
                Position = UDim2.new(1, -14, 0.5, -6),
                BackgroundColor3 = Library.Theme.TextBright,
            })

            Tween(Label, 0.15, {
                TextColor3 = Library.Theme.TextBright,
            })
        else
            Tween(Switch, 0.15, {
                BackgroundColor3 = Library.Theme.ToggleOff,
            })

            Tween(Knob, 0.15, {
                Position = UDim2.new(0, 2, 0.5, -6),
                BackgroundColor3 = Library.Theme.KnobOff,
            })

            Tween(Label, 0.15, {
                TextColor3 = Library.Theme.Text,
            })
        end
    end

    function Toggle:SetValue(NewValue)
        Value = NewValue == true
        self.Value = Value
        UpdateVisual()

        task.spawn(function()
            self.Callback(Value)
        end)

        task.spawn(function()
            self.Changed(Value)
        end)
    end

    function Toggle:GetValue()
        return Value
    end

    Container.MouseEnter:Connect(function()
        Tween(Container, 0.12, {
            BackgroundColor3 = Library.Theme.ElementHover,
        })
    end)

    Container.MouseLeave:Connect(function()
        Tween(Container, 0.12, {
            BackgroundColor3 = Library.Theme.Element,
        })
    end)

    Container.MouseButton1Click:Connect(function()
        Toggle:SetValue(not Value)
    end)

    Library.Toggles[Key] = Toggle

    UpdateVisual()

    return Toggle
end

--//==================================================
--// DROPDOWN
--//==================================================

local function CreateDropdown(Groupbox, Identifier, Info)
    local Key, Options = MakeKey(Identifier, Info)

    local Text = tostring(
        Options.Text
        or Options.Name
        or Key
    )

    local Values = Options.Values or {}
    local Default = Options.Default or 1

    local Selected

    if type(Default) == "number" then
        Selected = Values[Default]
    else
        Selected = Default
    end

    Selected = Selected or Values[1] or ""

    local Container = New("Frame", {
        Name = Key .. "Dropdown",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Groupbox.Container,
    })

    local Button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = Container,
    })

    Corner(Button, 5)
    Stroke(Button, Library.Theme.Outline, 0.25, 1)
    Button:SetAttribute("SearchName", NormalizeName(Key .. " " .. Text))

    local Label = New("TextLabel", {
        Position = UDim2.new(0, 11, 0, 0),
        Size = UDim2.new(1, -42, 1, 0),
        BackgroundTransparency = 1,
        Text = Text .. ": " .. tostring(Selected),
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Button,
    })

    local Chevron = New("TextLabel", {
        Position = UDim2.new(1, -26, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = Library.Theme.TextDim,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = Button,
    })

    local OptionsFrame = New("Frame", {
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, math.max(1, #Values) * 30 + 6),
        BackgroundColor3 = Color3.fromRGB(11, 11, 14),
        BorderSizePixel = 0,
        Parent = Container,
    })

    Corner(OptionsFrame, 5)

    local Padding = New("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        Parent = OptionsFrame,
    })

    local Layout = New("UIListLayout", {
        Padding = UDim.new(0, 1),
        Parent = OptionsFrame,
    })

    local Open = false

    local Dropdown = {
        Type = "Dropdown",
        Key = Key,
        Text = Text,
        Value = Selected,
        Values = Values,
        Container = Container,
        Callback = Options.Callback or function() end,
        Changed = Options.Changed or function() end,
    }

    setmetatable(Dropdown, {__index = ElementMethods})

    local function SetOpen(State)
        Open = State

        local Height = Open
            and (40 + (#Values * 30 + 6))
            or 36

        Tween(Container, 0.18, {
            Size = UDim2.new(1, 0, 0, Height),
        })

        Chevron.Text = Open and "^" or "v"
    end

    local function SetValue(Value)
        if type(Value) == "number" then
            Value = Values[Value]
        end

        Dropdown.Value = Value
        Selected = Value

        Label.Text =
            Text .. ": " .. tostring(Value)

        task.spawn(function()
            Dropdown.Callback(Value)
        end)

        task.spawn(function()
            Dropdown.Changed(Value)
        end)

        SetOpen(false)
    end

    function Dropdown:SetValue(Value)
        SetValue(Value)
    end

    function Dropdown:GetValue()
        return Dropdown.Value
    end

    for Index, Value in ipairs(Values) do
        local Option = New("TextButton", {
            Name = "Option_" .. tostring(Index),
            Size = UDim2.new(1, -8, 0, 30),
            BackgroundColor3 = Color3.fromRGB(11, 11, 14),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = tostring(Value),
            TextColor3 = Library.Theme.Text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = OptionsFrame,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 8),
            Parent = Option,
        })

        Option.MouseEnter:Connect(function()
            Tween(Option, 0.1, {
                BackgroundColor3 = Library.Theme.ElementHover,
                TextColor3 = Library.Theme.TextBright,
            })
        end)

        Option.MouseLeave:Connect(function()
            Tween(Option, 0.1, {
                BackgroundColor3 = Color3.fromRGB(11, 11, 14),
                TextColor3 = Library.Theme.Text,
            })
        end)

        Option.MouseButton1Click:Connect(function()
            SetValue(Value)
        end)
    end

    Button.MouseEnter:Connect(function()
        Tween(Button, 0.12, {
            BackgroundColor3 = Library.Theme.ElementHover,
        })
    end)

    Button.MouseLeave:Connect(function()
        Tween(Button, 0.12, {
            BackgroundColor3 = Library.Theme.Element,
        })
    end)

    Button.MouseButton1Click:Connect(function()
        SetOpen(not Open)
    end)

    Library.Options[Key] = Dropdown

    return Dropdown
end

--//==================================================
--// BUTTON
--//==================================================

local function CreateButton(Groupbox, Identifier, Info)
    local Key, Options = MakeKey(Identifier, Info)

    local Text = tostring(
        Options.Text
        or Options.Name
        or Key
    )

    local Callback =
        Options.Callback
        or Options.Func
        or (
            type(Info) == "function"
            and Info
        )
        or function() end

    local Container = New("TextButton", {
        Name = Key .. "Button",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = Text,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Groupbox.Container,
    })

    Corner(Container, 5)
    Stroke(Container, Library.Theme.Outline, 0.25, 1)
    Container:SetAttribute("SearchName", NormalizeName(Key .. " " .. Text))

    local Button = {
        Type = "Button",
        Key = Key,
        Text = Text,
        Container = Container,
        Callback = Callback,
    }

    setmetatable(Button, {__index = ElementMethods})

    Container.MouseEnter:Connect(function()
        Tween(Container, 0.12, {
            BackgroundColor3 = Library.Theme.ElementHover,
            TextColor3 = Library.Theme.TextBright,
        })
    end)

    Container.MouseLeave:Connect(function()
        Tween(Container, 0.12, {
            BackgroundColor3 = Library.Theme.Element,
            TextColor3 = Library.Theme.Text,
        })
    end)

    Container.MouseButton1Click:Connect(function()
        task.spawn(Callback)
    end)

    Library.Buttons[Key] = Button

    return Button
end

--//==================================================
--// LABEL
--//==================================================

local function CreateLabel(Groupbox, Identifier, Info)
    local Key, Options = MakeKey(Identifier, Info)

    local Text = tostring(
        Options.Text
        or Options.Name
        or Key
    )

    local Container = New("TextLabel", {
        Name = Key .. "Label",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Theme.TextDim,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Groupbox.Container,
    })

    local Label = {
        Type = "Label",
        Key = Key,
        Text = Text,
        Container = Container,
    }

    setmetatable(Label, {__index = ElementMethods})

    function Label:SetText(NewText)
        self.Text = tostring(NewText)
        Container.Text = self.Text
    end

    Library.Labels[Key] = Label

    return Label
end

--//==================================================
--// INPUT
--//==================================================

local function CreateInput(Groupbox, Identifier, Info)
    local Key, Options = MakeKey(Identifier, Info)

    local Text = tostring(
        Options.Text
        or Options.Name
        or Key
    )

    local Value = tostring(
        Options.Default
        or ""
    )

    local Holder = New("Frame", {
        Name = Key .. "Input",
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundTransparency = 1,
        Parent = Groupbox.Container,
    })

    local Label = New("TextLabel", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    local Box = New("TextBox", {
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        ClearTextOnFocus = Options.ClearTextOnFocus ~= false,
        Text = Value,
        PlaceholderText = tostring(Options.Placeholder or ""),
        PlaceholderColor3 = Library.Theme.Placeholder,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    Corner(Box, 5)
    Stroke(Box, Library.Theme.Outline, 0.25, 1)
    Box:SetAttribute("SearchName", NormalizeName(Key .. " " .. Text))

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = Box,
    })

    local Input = {
        Type = "Input",
        Key = Key,
        Text = Text,
        Value = Value,
        Container = Holder,
        Box = Box,
        Callback = Options.Callback or function() end,
        Changed = Options.Changed or function() end,
    }

    setmetatable(Input, {__index = ElementMethods})

    function Input:SetValue(NewValue)
        Value = tostring(NewValue or "")
        self.Value = Value
        Box.Text = Value

        task.spawn(function()
            self.Callback(Value)
        end)
    end

    Box.FocusLost:Connect(function()
        Value = Box.Text
        Input.Value = Value

        task.spawn(function()
            Input.Callback(Value)
        end)

        task.spawn(function()
            Input.Changed(Value)
        end)
    end)

    Library.Labels[Key] = Input

    return Input
end

--//==================================================
--// SLIDER
--//==================================================

local function CreateSlider(Groupbox, Identifier, Info)
    local Key, Options = MakeKey(Identifier, Info)

    local Text = tostring(
        Options.Text
        or Options.Name
        or Key
    )

    local Min = tonumber(Options.Min) or 0
    local Max = tonumber(Options.Max) or 100
    local Default = tonumber(Options.Default) or Min

    if Max <= Min then
        Max = Min + 1
    end

    Default = math.clamp(Default, Min, Max)

    local Holder = New("Frame", {
        Name = Key .. "Slider",
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1,
        Parent = Groupbox.Container,
    })

    local Label = New("TextLabel", {
        Size = UDim2.new(0.7, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    Holder:SetAttribute("SearchName", NormalizeName(Key .. " " .. Text))

    local ValueLabel = New("TextLabel", {
        Position = UDim2.new(0.7, 0, 0, 0),
        Size = UDim2.new(0.3, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = tostring(Default),
        TextColor3 = Library.Theme.TextDim,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Holder,
    })

    local Bar = New("Frame", {
        Position = UDim2.new(0, 0, 0, 29),
        Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = Library.Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = Holder,
    })

    Corner(Bar, 6)

    local Fill = New("Frame", {
        Size = UDim2.new(
            (Default - Min) / (Max - Min),
            0,
            1,
            0
        ),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        Parent = Bar,
    })

    Corner(Fill, 6)

    local Value = Default
    local Dragging = false

    local Slider = {
        Type = "Slider",
        Key = Key,
        Text = Text,
        Value = Value,
        Min = Min,
        Max = Max,
        Container = Holder,
        Callback = Options.Callback or function() end,
        Changed = Options.Changed or function() end,
    }

    setmetatable(Slider, {__index = ElementMethods})

    local function SetValue(NewValue)
        NewValue = math.clamp(
            tonumber(NewValue) or Min,
            Min,
            Max
        )

        local Rounding = tonumber(Options.Rounding)

        if Rounding and Rounding > 0 then
            local Power = 10 ^ Rounding
            NewValue = math.floor(NewValue * Power + 0.5) / Power
        else
            NewValue = math.floor(NewValue + 0.5)
        end

        Value = NewValue
        Slider.Value = Value

        local Percent =
            (Value - Min) /
            (Max - Min)

        Fill.Size =
            UDim2.new(
                Percent,
                0,
                1,
                0
            )

        ValueLabel.Text =
            tostring(Value)

        task.spawn(function()
            Slider.Callback(Value)
        end)

        task.spawn(function()
            Slider.Changed(Value)
        end)
    end

    function Slider:SetValue(NewValue)
        SetValue(NewValue)
    end

    function Slider:GetValue()
        return Value
    end

    Library.Options[Key] = Slider

    local function UpdateFromInput(Input)
        local X = Input.Position.X
        local Start = Bar.AbsolutePosition.X
        local Width = Bar.AbsoluteSize.X

        local Percent =
            math.clamp(
                (X - Start) / Width,
                0,
                1
            )

        SetValue(
            Min +
            ((Max - Min) * Percent)
        )
    end

    Bar.InputBegan:Connect(function(Input)
        if Input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or Input.UserInputType ==
            Enum.UserInputType.Touch then

            Dragging = true
            UpdateFromInput(Input)
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if Dragging and (
            Input.UserInputType ==
            Enum.UserInputType.MouseMovement
            or Input.UserInputType ==
            Enum.UserInputType.Touch
        ) then

            UpdateFromInput(Input)
        end
    end)

    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or Input.UserInputType ==
            Enum.UserInputType.Touch then

            Dragging = false
        end
    end)

    return Slider
end

--//==================================================
--// GROUPBOX
--//==================================================

local GroupboxMethods = {}

function GroupboxMethods:AddToggle(Identifier, Info)
    return CreateToggle(self, Identifier, Info)
end

function GroupboxMethods:AddDropdown(Identifier, Info)
    return CreateDropdown(self, Identifier, Info)
end

function GroupboxMethods:AddButton(Identifier, Info)
    return CreateButton(self, Identifier, Info)
end

function GroupboxMethods:AddLabel(Identifier, Info)
    return CreateLabel(self, Identifier, Info)
end

function GroupboxMethods:AddInput(Identifier, Info)
    return CreateInput(self, Identifier, Info)
end

function GroupboxMethods:AddSlider(Identifier, Info)
    return CreateSlider(self, Identifier, Info)
end

function GroupboxMethods:AddDivider()
    local Divider = New("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Library.Theme.Outline,
        BorderSizePixel = 0,
        Parent = self.Container,
    })

    return Divider
end

function GroupboxMethods:AddSection(Text)
    local Section = New("TextLabel", {
        Name = "Section",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = tostring(Text),
        TextColor3 = Library.Theme.TextBright,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container,
    })

    return Section
end

function GroupboxMethods:AddBlank(Height)
    local Blank = New("Frame", {
        Name = "Blank",
        Size = UDim2.new(1, 0, 0, tonumber(Height) or 5),
        BackgroundTransparency = 1,
        Parent = self.Container,
    })

    return Blank
end

local function CreateGroupbox(Tab, Name, Side)
    local Column = Side == "Right"
        and Tab.RightColumn
        or Tab.LeftColumn

    local Box = New("Frame", {
        Name = tostring(Name),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0,
        Parent = Column,
    })

    Corner(Box, 7)
    Stroke(Box, Library.Theme.OutlineSoft, 0.22, 1)

    local Padding = New("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = Box,
    })

    local Layout = New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Box,
    })

    local Header = New("TextLabel", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = tostring(Name),
        TextColor3 = Library.Theme.TextBright,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Box,
    })

    local Container = New("Frame", {
        Name = "Container",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = Box,
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Container,
    })

    local Groupbox = {
        Name = tostring(Name),
        Side = Side,
        Container = Container,
        Frame = Box,
        Header = Header,
        Tab = Tab,
    }

    setmetatable(Groupbox, {
        __index = GroupboxMethods
    })

    table.insert(Tab.Groupboxes, Groupbox)

    return Groupbox
end

--//==================================================
--// TAB
--//==================================================

local TabMethods = {}

function TabMethods:AddLeftGroupbox(Name)
    return CreateGroupbox(
        self,
        Name,
        "Left"
    )
end

function TabMethods:AddRightGroupbox(Name)
    return CreateGroupbox(
        self,
        Name,
        "Right"
    )
end

function TabMethods:AddGroupbox(Name, Side)
    return CreateGroupbox(
        self,
        Name,
        Side == 2 and "Right" or "Left"
    )
end

--//==================================================
--// WINDOW
--//==================================================

local WindowMethods = {}

function WindowMethods:AddTab(Name)
    local TabName = tostring(Name)

    local TabButton = New("TextButton", {
        Name = TabName .. "Module",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = #self.Tabs + 1,
        Parent = self.ModuleContainer,
    })

    Corner(TabButton, 5)

    local TabText = New("TextLabel", {
        Name = "Text",
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        BackgroundTransparency = 1,
        Text = TabName,
        TextColor3 = Library.Theme.TextDim,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        TextStrokeTransparency = 0.82,
        Parent = TabButton,
    })

    local Page = New("Frame", {
        Name = TabName .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.Content,
    })

    local PagePadding = New("UIPadding", {
        PaddingTop = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Page,
    })

    local Columns = New("Frame", {
        Name = "Columns",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = Page,
    })

    local LeftColumn = New("ScrollingFrame", {
        Name = "LeftColumn",
        Size = UDim2.new(0.5, -5, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(65, 65, 70),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Parent = Columns,
    })

    local RightColumn = New("ScrollingFrame", {
        Name = "RightColumn",
        Position = UDim2.new(0.5, 5, 0, 0),
        Size = UDim2.new(0.5, -5, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(65, 65, 70),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Parent = Columns,
    })

    New("UIPadding", {
        PaddingRight = UDim.new(0, 5),
        Parent = LeftColumn,
    })

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 5),
        Parent = RightColumn,
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = LeftColumn,
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = RightColumn,
    })

    local Tab = {
        Name = TabName,
        Button = TabButton,
        Page = Page,
        Columns = Columns,
        LeftColumn = LeftColumn,
        RightColumn = RightColumn,
        Groupboxes = {},
        Window = self,
    }

    setmetatable(Tab, {
        __index = TabMethods
    })

    self.Tabs[TabName] = Tab

    local function Select()
        if self.ActiveTab == Tab then
            return
        end

        if self.ActiveTab then
            self.ActiveTab.Page.Visible = false
            self.ActiveTab.Button.BackgroundColor3 =
                Library.Theme.Element

            self.ActiveTab.Button.TextColor3 =
                Library.Theme.TextDim

            local OldText =
                self.ActiveTab.Button:FindFirstChild("Text")

            if OldText then
                OldText.TextColor3 =
                    Library.Theme.TextDim
            end
        end

        self.ActiveTab = Tab

        Tab.Page.Visible = true
        TabButton.BackgroundColor3 =
            Library.Theme.Selected

        TabText.TextColor3 =
            Library.Theme.TextBright

        self:ApplySearch()
    end

    TabButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= Tab then
            Tween(TabButton, 0.12, {
                BackgroundColor3 =
                    Library.Theme.ElementHover
            })

            Tween(TabText, 0.12, {
                TextColor3 =
                    Library.Theme.TextBright
            })
        end
    end)

    TabButton.MouseLeave:Connect(function()
        if self.ActiveTab ~= Tab then
            Tween(TabButton, 0.12, {
                BackgroundColor3 =
                    Library.Theme.Element
            })

            Tween(TabText, 0.12, {
                TextColor3 =
                    Library.Theme.TextDim
            })
        end
    end)

    TabButton.MouseButton1Click:Connect(Select)

    if not self.ActiveTab then
        Select()
    end

    return Tab
end

function WindowMethods:ApplySearch()
    local Search = NormalizeName(self.SearchInput.Text)

    for _, Tab in pairs(self.Tabs) do
        local IsActive = self.ActiveTab == Tab

        if IsActive then
            for _, Descendant in ipairs(
                Tab.Page:GetDescendants()
            ) do
                if Descendant:IsA("TextButton")
                    or Descendant:IsA("TextBox") then

                    local SearchName =
                        Descendant:GetAttribute(
                            "SearchName"
                        )

                    if SearchName then
                        Descendant.Visible =
                            Search == ""
                            or string.find(
                                SearchName,
                                Search,
                                1,
                                true
                            ) ~= nil
                    end
                end
            end

            for _, Groupbox in pairs(Tab.Groupboxes) do
                Groupbox.Frame.Visible = true
            end
        end
    end
end

function WindowMethods:SetSearch(Value)
    self.SearchInput.Text = tostring(Value or "")
    self:ApplySearch()
end

function WindowMethods:SelectTab(Name)
    local Tab = self.Tabs[Name]

    if not Tab then
        return
    end

    Tab.Button:Activate()
end

function WindowMethods:Toggle()
    self.Visible = not self.Visible
    self.Frame.Visible = self.Visible
end

function WindowMethods:Unload()
    if self.Unloaded then
        return
    end

    self.Unloaded = true

    if self.Frame then
        self.Frame:Destroy()
    end

    for Key, Toggle in pairs(Library.Toggles) do
        Library.Toggles[Key] = nil
    end

    if Library.CurrentWindow == self then
        Library.CurrentWindow = nil
    end
end

--//==================================================
--// CREATE WINDOW
--//==================================================

function Library:CreateWindow(Config)
    Config = Config or {}

    local Title =
        tostring(
            Config.Title
            or Config.Name
            or "Moon Hub"
        )

    local Footer =
        tostring(
            Config.Footer
            or ""
        )

    local Gui = New("ScreenGui", {
        Name = "MoonHub",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = PlayerGui,
    })

    local Frame = New("Frame", {
        Name = "MainFrame",
        Size = Config.Size
            or UDim2.new(0, 720, 0, 510),
        Position =
            UDim2.new(
                0.5,
                -360,
                0.5,
                -255
            ),
        BackgroundColor3 =
            Library.Theme.Background,
        BorderSizePixel = 0,
        Parent = Gui,
    })

    Corner(Frame, 9)
    Stroke(
        Frame,
        Library.Theme.OutlineSoft,
        0.1,
        1
    )

    local TopBar = New("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 =
            Color3.fromRGB(8, 8, 9),
        BorderSizePixel = 0,
        Parent = Frame,
    })

    Corner(TopBar, 9)

    local TitleLabel = New("TextLabel", {
        Name = "Title",
        AnchorPoint =
            Vector2.new(0.5, 0.5),
        Position =
            UDim2.new(0.5, 0, 0.5, 0),
        Size =
            UDim2.new(0, 250, 0, 36),
        BackgroundTransparency = 1,
        Text = Title,
        TextColor3 =
            Library.Theme.TextBright,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment =
            Enum.TextXAlignment.Center,
        TextYAlignment =
            Enum.TextYAlignment.Center,
        Parent = TopBar,
    })

    local SearchArea = New("Frame", {
        Name = "Explorer",
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(0, 160, 0, 30),
        BackgroundColor3 =
            Library.Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = Frame,
    })

    local SearchBox = New("Frame", {
        Name = "SearchBox",
        Position = UDim2.new(0, 6, 0, 4),
        Size = UDim2.new(1, -12, 1, -8),
        BackgroundColor3 =
            Color3.fromRGB(18, 18, 21),
        BorderSizePixel = 0,
        Parent = SearchArea,
    })

    Corner(SearchBox, 5)
    Stroke(
        SearchBox,
        Library.Theme.Outline,
        0.35,
        1
    )

    local SearchInput = New("TextBox", {
        Name = "SearchInput",
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -18, 1, 0),
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        PlaceholderText = "Search",
        PlaceholderColor3 =
            Library.Theme.Placeholder,
        Text = "",
        TextColor3 =
            Library.Theme.Text,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment =
            Enum.TextXAlignment.Left,
        Parent = SearchBox,
    })

    local Modules = New("Frame", {
        Name = "Modules",
        Position = UDim2.new(0, 0, 0, 66),
        Size = UDim2.new(0, 160, 1, -66),
        BackgroundColor3 =
            Library.Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = Frame,
    })

    local ModuleContainer = New("ScrollingFrame", {
        Name = "ModuleContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 =
            Color3.fromRGB(65, 65, 70),
        AutomaticCanvasSize =
            Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Parent = Modules,
    })

    New("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = ModuleContainer,
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ModuleContainer,
    })

    local Content = New("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 160, 0, 36),
        Size = UDim2.new(1, -160, 1, -36),
        BackgroundColor3 =
            Library.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Frame,
    })

    local Window = {
        Title = Title,
        Footer = Footer,
        Gui = Gui,
        Frame = Frame,
        TopBar = TopBar,
        SearchInput = SearchInput,
        ModuleContainer = ModuleContainer,
        Content = Content,
        Tabs = {},
        ActiveTab = nil,
        Visible = true,
        Unloaded = false,
        SearchText = "",
    }

    setmetatable(Window, {
        __index = WindowMethods
    })

    table.insert(Library.Windows, Window)
    Library.CurrentWindow = Window

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        Window.SearchText = SearchInput.Text
        Window:ApplySearch()
    end)

    --// Minimize

    local Minimize = New("TextButton", {
        Name = "Minimize",
        Position = UDim2.new(1, -64, 0, 0),
        Size = UDim2.new(0, 32, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "-",
        TextColor3 =
            Library.Theme.TextDim,
        TextSize = 18,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        Parent = TopBar,
    })

    local Close = New("TextButton", {
        Name = "Close",
        Position = UDim2.new(1, -32, 0, 0),
        Size = UDim2.new(0, 32, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "X",
        TextColor3 =
            Library.Theme.TextDim,
        TextSize = 18,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        Parent = TopBar,
    })

    Minimize.MouseEnter:Connect(function()
        Minimize.TextColor3 =
            Library.Theme.TextBright
    end)

    Minimize.MouseLeave:Connect(function()
        Minimize.TextColor3 =
            Library.Theme.TextDim
    end)

    Close.MouseEnter:Connect(function()
        Close.TextColor3 =
            Library.Theme.Error
    end)

    Close.MouseLeave:Connect(function()
        Close.TextColor3 =
            Library.Theme.TextDim
    end)

    local Minimized = false

    Minimize.MouseButton1Click:Connect(function()
        Minimized = not Minimized

        if Minimized then
            SearchArea.Visible = false
            Modules.Visible = false
            Content.Visible = false

            Frame.Size =
                UDim2.new(
                    0,
                    Frame.AbsoluteSize.X,
                    0,
                    36
                )
        else
            SearchArea.Visible = true
            Modules.Visible = true
            Content.Visible = true

            Frame.Size =
                Config.Size
                or UDim2.new(0, 720, 0, 510)
        end
    end)

    Close.MouseButton1Click:Connect(function()
        Window:Unload()
    end)

    --// Dragging

    local Dragging = false
    local DragStart
    local StartPosition

    TopBar.InputBegan:Connect(function(Input)
        if Input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or Input.UserInputType ==
            Enum.UserInputType.Touch then

            Dragging = true
            DragStart = Input.Position
            StartPosition = Frame.Position

            Input.Changed:Connect(function()
                if Input.UserInputState ==
                    Enum.UserInputState.End then

                    Dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(Input)
        if not Dragging then
            return
        end

        if Input.UserInputType ==
            Enum.UserInputType.MouseMovement
            or Input.UserInputType ==
            Enum.UserInputType.Touch then

            local Delta =
                Input.Position - DragStart

            Frame.Position =
                UDim2.new(
                    StartPosition.X.Scale,
                    StartPosition.X.Offset + Delta.X,
                    StartPosition.Y.Scale,
                    StartPosition.Y.Offset + Delta.Y
                )
        end
    end)

    return Window
end

--//==================================================
--// GLOBAL SETTINGS
--//==================================================

function Library:RefreshTheme()
    -- Refresh every live UI object using the current theme.
    for _, Gui in ipairs(PlayerGui:GetChildren()) do
        if Gui.Name == "MoonHub" or Gui.Name == "MoonHubNotifications" then
            for _, Object in ipairs(Gui:GetDescendants()) do
                pcall(function()
                    if Object.Name == "MainFrame" then
                        Object.BackgroundColor3 = Library.Theme.Background
                    elseif Object.Name == "TopBar" then
                        Object.BackgroundColor3 = Library.Theme.Panel
                    elseif Object.Name == "Explorer" or Object.Name == "Modules" then
                        Object.BackgroundColor3 = Library.Theme.Sidebar
                    elseif Object.Name == "Content" then
                        Object.BackgroundColor3 = Library.Theme.Background
                    elseif Object.Name == "SearchBox" then
                        Object.BackgroundColor3 = Library.Theme.Element
                    elseif Object.Name == "Header" then
                        Object.TextColor3 = Library.Theme.TextBright
                    elseif Object.Name == "Text" and Object:IsA("TextLabel") then
                        Object.TextColor3 = Library.Theme.Text
                    elseif Object.Name == "Title" and Object:IsA("TextLabel") then
                        Object.TextColor3 = Library.Theme.TextBright
                    elseif Object.Name == "Description" and Object:IsA("TextLabel") then
                        Object.TextColor3 = Library.Theme.TextDim
                    elseif Object:IsA("TextBox") then
                        Object.TextColor3 = Library.Theme.Text
                        Object.PlaceholderColor3 = Library.Theme.Placeholder
                    elseif Object:IsA("TextButton") then
                        if Object.Name:find("Module") then
                            Object.BackgroundColor3 = Library.Theme.Element
                        else
                            Object.BackgroundColor3 = Library.Theme.Element
                            Object.TextColor3 = Library.Theme.Text
                        end
                    elseif Object:IsA("Frame") then
                        if Object.Name == "Progress" or Object.Name == "Accent" then
                            Object.BackgroundColor3 = Library.Theme.Accent
                        elseif Object.Name == "Fill" then
                            Object.BackgroundColor3 = Library.Theme.Accent
                        elseif Object.Name == "Switch" then
                            -- Toggle state is restored below.
                        elseif Object.Name == "Knob" then
                            -- Toggle state is restored below.
                        end
                    end
                end)
            end
        end
    end

    for _, Toggle in pairs(Library.Toggles) do
        pcall(function()
            local switch = Toggle.Container:FindFirstChild("Switch")
            local knob = switch and switch:FindFirstChild("Knob")
            local label = Toggle.Container:FindFirstChild("Text")

            if switch then
                switch.BackgroundColor3 = Toggle.Value and Library.Theme.ToggleOn or Library.Theme.ToggleOff
            end

            if knob then
                knob.BackgroundColor3 = Toggle.Value and Library.Theme.TextBright or Library.Theme.KnobOff
                knob.Position = Toggle.Value
                    and UDim2.new(1, -14, 0.5, -6)
                    or UDim2.new(0, 2, 0.5, -6)
            end

            if label then
                label.TextColor3 = Toggle.Value and Library.Theme.TextBright or Library.Theme.Text
            end
        end)
    end

    for _, Callback in ipairs(Library._ThemeCallbacks) do
        pcall(Callback, Library.Theme)
    end
end

function Library:SetTheme(Theme)
    for Key, Value in pairs(Theme or {}) do
        if Library.Theme[Key] ~= nil then
            Library.Theme[Key] = Value
        end
    end

    self:RefreshTheme()
end

function Library:SetAccent(Color)
    if typeof(Color) == "Color3" then
        Library.Theme.Accent = Color
        self:RefreshTheme()
    end
end

function Library:Unload()
    if Library.Unloaded then
        return
    end

    Library.Unloaded = true

    for _, Window in ipairs(Library.Windows) do
        if Window and not Window.Unloaded then
            Window:Unload()
        end
    end

    if NotificationGui then
        NotificationGui:Destroy()
        NotificationGui = nil
        NotificationList = nil
    end

    for _, Window in ipairs(Library.Windows) do
        if Window and Window.Gui then
            pcall(function()
                Window.Gui:Destroy()
            end)
        end
    end

    table.clear(Library.Toggles)
    table.clear(Library.Options)
    table.clear(Library.Labels)
    table.clear(Library.Buttons)
    table.clear(Library.Windows)
    Library.CurrentWindow = nil
end


return Library
