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
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {}

--//==================================================
--// THEME
--//==================================================

Library.DefaultTheme = {
    -- MoonHub: dark navy palette based on the supplied GUI.
    -- Keep the base very dark; blue is used only for readable controls.
Background = Color3.fromRGB(5, 18, 31),
    Sidebar = Color3.fromRGB(7, 23, 39),
    Panel = Color3.fromRGB(8, 27, 44),

    Element = Color3.fromRGB(24, 58, 88),
    ElementHover = Color3.fromRGB(38, 91, 132),
    Selected = Color3.fromRGB(35, 82, 110),

    Outline = Color3.fromRGB(78, 112, 136),
    OutlineSoft = Color3.fromRGB(60, 94, 119),

    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(190, 208, 222),
    TextBright = Color3.fromRGB(255, 255, 255),
    Placeholder = Color3.fromRGB(165, 185, 200),

    ToggleOff = Color3.fromRGB(12, 30, 45),
    ToggleOn = Color3.fromRGB(42, 104, 138),
    KnobOff = Color3.fromRGB(178, 193, 205),

    Accent = Color3.fromRGB(42, 104, 138),
    AccentSoft = Color3.fromRGB(17, 43, 61),

    Success = Color3.fromRGB(120, 220, 150),
    Warning = Color3.fromRGB(235, 190, 90),
    Error = Color3.fromRGB(235, 95, 95),
    GradientEnabled = true,
    StarsEnabled = true,
}

-- Always start from the exact MoonHub palette.
Library.Theme = {}
for Key, Value in pairs(Library.DefaultTheme) do
    Library.Theme[Key] = Value
end

Library.Toggles = {}
Library.Options = {}
Library.Labels = {}
Library.Buttons = {}
Library.KeyPickers = {}
Library.Windows = {}

Library.Unloaded = false
Library.CurrentWindow = nil
Library._ThemeCallbacks = {}
Library._UnloadCallbacks = {}

local TooltipGui
local ActiveTooltip
local TooltipToken = 0
local ActiveTweens = {}

function Library:RegisterThemeCallback(Callback)
    table.insert(self._ThemeCallbacks, Callback)
    return Callback
end

--// Register code that must be cleaned up when the library is unloaded.
function Library:OnUnload(Callback)
    if type(Callback) ~= "function" then
        return nil
    end

    if self.Unloaded then
        task.spawn(function()
            pcall(Callback)
        end)
        return Callback
    end

    table.insert(self._UnloadCallbacks, Callback)
    return Callback
end

function Library:RegisterUnloadCallback(Callback)
    return self:OnUnload(Callback)
end

--// Show / hide the main MoonHub GUI without destroying it.
function Library:SetVisible(Visible)
    Visible = Visible == true

    if not Visible then
        if TooltipGui then
            TooltipToken = TooltipToken + 1
            ActiveTooltip = nil
            pcall(function()
                TooltipGui:ClearAllChildren()
            end)
        end
    end

    for _, Window in ipairs(self.Windows) do
        if Window and Window.Gui and Window.Gui.Parent then
            if not Visible and Window.ActiveTab then
                Window.LastTabName = Window.ActiveTab.Name
            end

            Window.Gui.Enabled = Visible
            Window.Visible = Visible

            if Visible then
                local RestoreTab = nil

                if Window.LastTabName then
                    RestoreTab = Window.Tabs[Window.LastTabName]
                end

                if not RestoreTab then
                    for _, Tab in pairs(Window.Tabs) do
                        RestoreTab = Tab
                        break
                    end
                end

                if RestoreTab then
                    for _, Tab in pairs(Window.Tabs) do
                        local IsActive = Tab == RestoreTab

                        Tab.Page.Visible = IsActive
                        Tab.Button.BackgroundColor3 = IsActive
                            and Library.Theme.Selected
                            or Library.Theme.Element

                        local TabText = Tab.Button:FindFirstChild("Text")
                        if TabText then
                            TabText.TextColor3 = IsActive
                                and Library.Theme.TextBright
                                or Library.Theme.TextDim
                        end
                    end

                    Window.ActiveTab = RestoreTab
                    Window.LastTabName = RestoreTab.Name
                    Window:ApplySearch()
                end
            end
        end
    end

    return Visible
end

function Library:IsVisible()
    for _, Window in ipairs(self.Windows) do
        if Window and Window.Gui and Window.Gui.Parent then
            return Window.Gui.Enabled
        end
    end

    return false
end

function Library:ToggleGUI()
    return self:SetVisible(not self:IsVisible())
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
    if not Object then
        return nil
    end

    -- Roblox's native BorderSizePixel can create a second hard line beside
    -- the UIStroke. MoonHub uses UIStroke only for its outlines.
    pcall(function()
        Object.BorderSizePixel = 0
    end)

    -- Never leave two Outline strokes on the same object. That was the source
    -- of the dark/light parallel-line artifact around some controls.
    for _, Child in ipairs(Object:GetChildren()) do
        if Child:IsA("UIStroke") and Child.Name == "Outline" then
            Child:Destroy()
        end
    end

    local S = Instance.new("UIStroke")
    S.Name = "Outline"
    S.Color = Color or Library.Theme.Outline
    S.Transparency = Transparency or 0
    S.Thickness = Thickness or 1
    S.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pcall(function()
        S.BorderStrokePosition = Enum.BorderStrokePosition.Inner
        S.BorderOffset = UDim.new(0, 0)
        S.LineJoinMode = Enum.LineJoinMode.Round
    end)
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

    ActiveTweens[T] = true
    T.Completed:Connect(function()
        ActiveTweens[T] = nil
    end)

    T:Play()
    return T
end

local function CancelThemeTweens()
    for TweenObject in pairs(ActiveTweens) do
        pcall(function()
            TweenObject:Cancel()
        end)
        ActiveTweens[TweenObject] = nil
    end
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

local function CreateTooltipGui()
    if TooltipGui and TooltipGui.Parent then
        return
    end

    TooltipGui = New("ScreenGui", {
        Name = "MoonHubTooltip",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 1000,
        Parent = PlayerGui,
    })
end

local function HideTooltip()
    TooltipToken = TooltipToken + 1

    if ActiveTooltip then
        local Card = ActiveTooltip
        ActiveTooltip = nil
        Tween(Card, 0.08, {
            BackgroundTransparency = 1,
        })

        local TextLabel = Card:FindFirstChild("Text")
        if TextLabel then
            Tween(TextLabel, 0.08, {
                TextTransparency = 1,
            })
        end

        task.delay(0.09, function()
            if Card and Card.Parent and Card ~= ActiveTooltip then
                Card:Destroy()
            end
        end)
    end
end

local function UpdateTooltipPosition()
    if not ActiveTooltip or not ActiveTooltip.Parent then
        return
    end

    local Camera = workspace.CurrentCamera
    if not Camera then
        return
    end

    local MousePosition = UserInputService:GetMouseLocation()
    local ScreenSize = Camera.ViewportSize
    local Card = ActiveTooltip

    local X = MousePosition.X + 12
    local Y = MousePosition.Y + 16

    if X + Card.AbsoluteSize.X > ScreenSize.X - 6 then
        X = MousePosition.X - Card.AbsoluteSize.X - 12
    end

    if Y + Card.AbsoluteSize.Y > ScreenSize.Y - 6 then
        Y = MousePosition.Y - Card.AbsoluteSize.Y - 12
    end

    X = math.clamp(X, 6, math.max(6, ScreenSize.X - Card.AbsoluteSize.X - 6))
    Y = math.clamp(Y, 6, math.max(6, ScreenSize.Y - Card.AbsoluteSize.Y - 6))

    Card.Position = UDim2.fromOffset(X, Y)
end

local function ShowTooltip(Target, Text)
    if not Target or not Target.Parent then
        return
    end

    if not Library:IsVisible() then
        return
    end

    Text = tostring(Text or "")
    if Text == "" then
        return
    end

    HideTooltip()
    TooltipToken = TooltipToken + 1
    local Token = TooltipToken
    CreateTooltipGui()

    local Card = New("Frame", {
        Name = "Tooltip",
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Library.Theme.Panel,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 1000,
        Parent = TooltipGui,
    })

    Corner(Card, 5)
    Stroke(Card, Library.Theme.Outline, 0.1, 1)

    local TextLabel = New("TextLabel", {
        Name = "Text",
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Theme.Text,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 1001,
        Parent = Card,
    })

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9),
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        Parent = Card,
    })

    ActiveTooltip = Card

    task.defer(function()
        if Token ~= TooltipToken or not Card.Parent or not Target.Parent then
            return
        end

        if not Library:IsVisible() then
            if Card.Parent then
                Card:Destroy()
            end
            if ActiveTooltip == Card then
                ActiveTooltip = nil
            end
            return
        end

        UpdateTooltipPosition()

        Tween(Card, 0.1, {
            BackgroundTransparency = 0.08,
        })

        Tween(TextLabel, 0.1, {
            TextTransparency = 0,
        })
    end)
end

local function AttachTooltip(Target, Text)
    if not Target then
        return nil
    end

    local TooltipText = tostring(Text or "")
    if TooltipText == "" then
        return nil
    end

    local HoverToken = 0

    local EnterConnection = Target.MouseEnter:Connect(function()
        HoverToken = HoverToken + 1
        local Token = HoverToken

        task.delay(0.25, function()
            if Token ~= HoverToken then
                return
            end

            if Target and Target.Parent and Library:IsVisible() then
                ShowTooltip(Target, TooltipText)
            end
        end)
    end)

    local LeaveConnection = Target.MouseLeave:Connect(function()
        HoverToken = HoverToken + 1
        HideTooltip()
    end)

    Target.AncestryChanged:Connect(function(_, Parent)
        if not Parent then
            HoverToken = HoverToken + 1
            HideTooltip()
        end
    end)

    return EnterConnection, LeaveConnection
end

UserInputService.InputChanged:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseMovement then
        if ActiveTooltip and ActiveTooltip.Parent and Library:IsVisible() then
            UpdateTooltipPosition()
        end
    end
end)

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
        TextStrokeColor3 = Library.Theme.Background,
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
        BackgroundColor3 = Library.Theme.Sidebar,
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
    self.Tooltip = tostring(Text or "")

    if self.Container then
        if self._TooltipConnections then
            for _, Connection in ipairs(self._TooltipConnections) do
                pcall(function()
                    Connection:Disconnect()
                end)
            end
        end

        self._TooltipConnections = {}

        local EnterConnection, LeaveConnection = AttachTooltip(
            self.Container,
            self.Tooltip
        )

        if EnterConnection then
            table.insert(self._TooltipConnections, EnterConnection)
        end

        if LeaveConnection then
            table.insert(self._TooltipConnections, LeaveConnection)
        end
    end

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
    Stroke(Switch, Library.Theme.OutlineSoft, 0.22, 1)

    local Knob = New("Frame", {
        Name = "Knob",
        Position = UDim2.new(0, 2, 0.5, -6),
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Library.Theme.KnobOff,
        BorderSizePixel = 0,
        Parent = Switch,
    })

    Corner(Knob, 20)
    Stroke(Knob, Library.Theme.Outline, 0.10, 1)

    local Toggle = {
        Type = "Toggle",
        Key = Key,
        Text = Text,
        Value = Value,
        Container = Container,
        Callback = Options.Callback or function() end,
        Changed = Options.Changed or function() end,
        Tooltip = Options.Tooltip,
    }

    setmetatable(Toggle, {__index = ElementMethods})

    if Options.Tooltip then
        Toggle:AddTooltip(Options.Tooltip)
    end

    local function UpdateVisual()
        local SwitchStroke = Switch:FindFirstChildOfClass("UIStroke")
        local KnobStroke = Knob:FindFirstChildOfClass("UIStroke")

        if Value then
            Tween(Switch, 0.15, {
                BackgroundColor3 = Library.Theme.ToggleOn,
            })
            local SwitchStroke = Switch:FindFirstChild("ToggleStroke")
            if SwitchStroke then
                Tween(SwitchStroke, 0.15, {Color = Library.Theme.ToggleOn, Transparency = 0})
            end

            if SwitchStroke then
                Tween(SwitchStroke, 0.15, {
                    Color = Library.Theme.ToggleOn,
                    Transparency = 0.02,
                })
            end

            Tween(Knob, 0.15, {
                Position = UDim2.new(1, -14, 0.5, -6),
                BackgroundColor3 = Library.Theme.TextBright,
            })

            if KnobStroke then
                Tween(KnobStroke, 0.15, {
                    Color = Library.Theme.TextBright,
                    Transparency = 0.02,
                })
            end

            Tween(Label, 0.15, {
                TextColor3 = Library.Theme.TextBright,
            })
        else
            Tween(Switch, 0.15, {
                BackgroundColor3 = Library.Theme.ToggleOff,
            })
            local SwitchStroke = Switch:FindFirstChild("ToggleStroke")
            if SwitchStroke then
                Tween(SwitchStroke, 0.15, {Color = Library.Theme.OutlineSoft, Transparency = 0.15})
            end

            if SwitchStroke then
                Tween(SwitchStroke, 0.15, {
                    Color = Library.Theme.OutlineSoft,
                    Transparency = 0.22,
                })
            end

            Tween(Knob, 0.15, {
                Position = UDim2.new(0, 2, 0.5, -6),
                BackgroundColor3 = Library.Theme.KnobOff,
            })

            if KnobStroke then
                Tween(KnobStroke, 0.15, {
                    Color = Library.Theme.Outline,
                    Transparency = 0.10,
                })
            end

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
            local Success, Error = pcall(function()
                self.Callback(Value)
            end)

            if not Success then
                warn("[MoonHub] Toggle callback error:", Error)
            end
        end)

        task.spawn(function()
            local Success, Error = pcall(function()
                self.Changed(Value)
            end)

            if not Success then
                warn("[MoonHub] Toggle Changed error:", Error)
            end
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
        -- When a key picker is attached, clicking its key box must not also
        -- toggle the parent toggle. The picker marks itself as Listening first.
        local Picker = Toggle._KeyPicker
        if Picker and Picker.Listening then
            return
        end

        Toggle:SetValue(not Value)
    end)

    Library.Toggles[Key] = Toggle

    UpdateVisual()

    return Toggle
end

--//==================================================
--// KEY PICKER
--//==================================================

local function ResolveKey(Key)
    if typeof(Key) == "EnumItem" and Key.EnumType == Enum.KeyCode then
        return Key
    end

    if type(Key) == "string" then
        local Success, Result = pcall(function()
            return Enum.KeyCode[Key]
        end)

        if Success and Result then
            return Result
        end
    end

    return Enum.KeyCode.RightShift
end

local function CreateKeyPicker(Groupbox, Identifier, Info)
    local Key, Options = MakeKey(Identifier, Info)

    local Text = tostring(
        Options.Text
        or Options.Name
        or Key
    )

    local CurrentKey = ResolveKey(
        Options.Default
        or Options.Key
        or "RightShift"
    )

    local Mode = tostring(Options.Mode or "Toggle")
    if Mode ~= "Toggle" and Mode ~= "Hold" then
        Mode = "Toggle"
    end

    local Active = false
    local Listening = false

    local Container = New("Frame", {
        Name = Key .. "KeyPicker",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Parent = Groupbox.Container,
    })

    Corner(Container, 5)
    Stroke(Container, Library.Theme.Outline, 0.25, 1)
    Container:SetAttribute("SearchName", NormalizeName(Key .. " " .. Text))

    local Label = New("TextLabel", {
        Name = "Text",
        Position = UDim2.new(0, 11, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Container,
    })

    local KeyButton = New("TextButton", {
        Name = "KeyButton",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 62, 0, 24),
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = CurrentKey.Name,
        TextColor3 = Library.Theme.TextDim,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = Container,
    })

    Corner(KeyButton, 5)
    Stroke(KeyButton, Library.Theme.Outline, 0.15, 1)

    local KeyPicker = {
        Type = "KeyPicker",
        Key = Key,
        Text = Text,
        Mode = Mode,
        Value = CurrentKey,
        KeyCode = CurrentKey,
        Active = Active,
        Listening = Listening,
        Container = Container,
        Button = KeyButton,
        Callback = Options.Callback or function() end,
        Changed = Options.Changed or function() end,
    }

    setmetatable(KeyPicker, {__index = ElementMethods})

    local function FireCallback(Value)
        task.spawn(function()
            KeyPicker.Callback(Value)
        end)

        task.spawn(function()
            KeyPicker.Changed(Value)
        end)
    end

    local function SetActive(Value)
        Active = Value == true
        KeyPicker.Active = Active
        FireCallback(Active)
    end

    local function UpdateKeyButton()
        if Listening then
            KeyButton.Text = "Press key..."
            KeyButton.TextColor3 = Library.Theme.TextBright
            KeyButton.BackgroundColor3 = Library.Theme.ElementHover
        else
            KeyButton.Text = CurrentKey.Name
            KeyButton.TextColor3 = Library.Theme.TextDim
            KeyButton.BackgroundColor3 = Library.Theme.Panel
        end
    end

    function KeyPicker:SetKey(NewKey)
        CurrentKey = ResolveKey(NewKey)
        self.Value = CurrentKey
        self.KeyCode = CurrentKey
        UpdateKeyButton()

        task.spawn(function()
            self.Changed(CurrentKey)
        end)
    end

    function KeyPicker:GetKey()
        return CurrentKey
    end

    function KeyPicker:SetValue(NewValue)
        if typeof(NewValue) == "EnumItem" or type(NewValue) == "string" then
            self:SetKey(NewValue)
        elseif type(NewValue) == "boolean" then
            SetActive(NewValue)
        end
    end

    function KeyPicker:GetValue()
        return CurrentKey
    end

    function KeyPicker:SetActive(Value)
        SetActive(Value)
    end

    function KeyPicker:GetActive()
        return Active
    end

    KeyButton.MouseEnter:Connect(function()
        if not Listening then
            Tween(KeyButton, 0.12, {
                BackgroundColor3 = Library.Theme.ElementHover,
                TextColor3 = Library.Theme.TextBright,
            })
        end
    end)

    KeyButton.MouseLeave:Connect(function()
        if not Listening then
            Tween(KeyButton, 0.12, {
                BackgroundColor3 = Library.Theme.Panel,
                TextColor3 = Library.Theme.TextDim,
            })
        end
    end)

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

    KeyButton.MouseButton1Click:Connect(function()
        Listening = true
        KeyPicker.Listening = true
        UpdateKeyButton()
    end)

    UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if Listening then
            if Input.UserInputType == Enum.UserInputType.Keyboard then
                if Input.KeyCode ~= Enum.KeyCode.Unknown then
                    CurrentKey = Input.KeyCode
                    KeyPicker.Value = CurrentKey
                    KeyPicker.KeyCode = CurrentKey
                    Listening = false
                    KeyPicker.Listening = false
                    UpdateKeyButton()

                    task.spawn(function()
                        KeyPicker.Changed(CurrentKey)
                    end)
                end
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                Listening = false
                KeyPicker.Listening = false
                UpdateKeyButton()
            end
            return
        end

        if GameProcessed then
            return
        end

        if Input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if Input.KeyCode ~= CurrentKey then
            return
        end

        if Mode == "Hold" then
            SetActive(true)
        else
            SetActive(not Active)
        end
    end)

    if Mode == "Hold" then
        UserInputService.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.Keyboard
                and Input.KeyCode == CurrentKey then
                SetActive(false)
            end
        end)
    end

    Library.KeyPickers[Key] = KeyPicker

    return KeyPicker
end

--//==================================================
--// TOGGLE -> KEY PICKER (Obsidian-style)
--//==================================================

local function CreateToggleKeyPicker(Toggle, Identifier, Info)
    local Key, Options = MakeKey(Identifier, Info)

    Options = Options or {}

    local CurrentKey = ResolveKey(
        Options.Default
        or Options.Key
        or "RightShift"
    )

    local Mode = tostring(Options.Mode or "Toggle")
    if Mode ~= "Toggle" and Mode ~= "Hold" then
        Mode = "Toggle"
    end

    local SyncToggleState = Options.SyncToggleState == true
    local Active = false
    local Listening = false
    local Destroyed = false

    local Existing = Toggle._KeyPicker
    if Existing and Existing.Destroy then
        pcall(function()
            Existing:Destroy()
        end)
    end

    local KeyButton = New("TextButton", {
        Name = "KeyButton",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -46, 0.5, 0),
        Size = UDim2.new(0, 58, 0, 22),
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = CurrentKey.Name,
        TextColor3 = Library.Theme.TextDim,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = Toggle.Container.ZIndex + 2,
        Parent = Toggle.Container,
    })

    Corner(KeyButton, 5)
    Stroke(KeyButton, Library.Theme.Outline, 0.10, 1)

    -- Switch'i key picker varken biraz sağa taşı.
    local Switch = Toggle.Container:FindFirstChild("Switch")
    if Switch then
        -- Obsidian-style layout: key box at the far right, toggle switch
        -- immediately to its left. Keep both controls on the same row.
        Switch.Position = UDim2.new(1, -76, 0.5, -8)
    end

    local Picker = {
        Type = "KeyPicker",
        Key = Key,
        Text = tostring(Options.Text or Options.Name or Key),
        Mode = Mode,
        Value = CurrentKey,
        KeyCode = CurrentKey,
        Active = Active,
        Listening = Listening,
        SyncToggleState = SyncToggleState,
        Container = Toggle.Container,
        Button = KeyButton,
        Toggle = Toggle,
        Callback = Options.Callback or function() end,
        Changed = Options.Changed or function() end,
        NoUI = Options.NoUI == true,
    }

    -- Make room for both the switch and the key box without overlapping the
    -- toggle text.
    local ToggleText = Toggle.Container:FindFirstChild("Text")
    if ToggleText and ToggleText:IsA("TextLabel") then
        ToggleText.Size = UDim2.new(1, -112, 1, 0)
    end

    local function SafeCall(Callback, Value)
        if type(Callback) ~= "function" then
            return
        end

        task.spawn(function()
            local Success, Error = pcall(Callback, Value)
            if not Success then
                warn("[MoonHub] KeyPicker callback error:", Error)
            end
        end)
    end

    local function UpdateButton()
        if Destroyed or not KeyButton.Parent then
            return
        end

        if Listening then
            KeyButton.Text = "Press key..."
            KeyButton.TextColor3 = Library.Theme.TextBright
            KeyButton.BackgroundColor3 = Library.Theme.ElementHover
        else
            KeyButton.Text = CurrentKey.Name
            KeyButton.TextColor3 = Active and Library.Theme.TextBright or Library.Theme.TextDim
            KeyButton.BackgroundColor3 = Active and Library.Theme.Selected or Library.Theme.Panel
        end
    end

    local function SetActive(NewValue, Fire)
        Active = NewValue == true
        Picker.Active = Active

        if SyncToggleState then
            if Toggle:GetValue() ~= Active then
                Toggle:SetValue(Active)
            end
        end

        UpdateButton()

        if Fire ~= false then
            SafeCall(Picker.Callback, Active)
            SafeCall(Picker.Changed, Active)
        end
    end

    function Picker:SetKey(NewKey)
        CurrentKey = ResolveKey(NewKey)
        Picker.Value = CurrentKey
        Picker.KeyCode = CurrentKey
        Listening = false
        Picker.Listening = false
        UpdateButton()
        SafeCall(Picker.Changed, CurrentKey)
        return Picker
    end

    function Picker:GetKey()
        return CurrentKey
    end

    function Picker:SetValue(NewValue)
        if typeof(NewValue) == "EnumItem" or type(NewValue) == "string" then
            return self:SetKey(NewValue)
        end

        if type(NewValue) == "boolean" then
            SetActive(NewValue)
        end

        return self
    end

    function Picker:GetValue()
        return CurrentKey
    end

    function Picker:SetActive(NewValue)
        SetActive(NewValue)
        return self
    end

    function Picker:GetActive()
        return Active
    end

    -- Obsidian-style event API.
    -- Example:
    -- KeyPicker:OnChanged(function(Value)
    --     print(Value)
    -- end)
    function Picker:OnChanged(Callback)
        if type(Callback) ~= "function" then
            return self
        end

        self.Changed = Callback
        return self
    end

    function Picker:Destroy()
        if Destroyed then
            return
        end

        Destroyed = true
        Listening = false
        Picker.Listening = false

        if KeyButton and KeyButton.Parent then
            KeyButton:Destroy()
        end

        local CurrentSwitch = Toggle.Container:FindFirstChild("Switch")
        if CurrentSwitch then
            CurrentSwitch.Position = UDim2.new(1, -40, 0.5, -8)
        end

        if Library.KeyPickers[Key] == Picker then
            Library.KeyPickers[Key] = nil
        end

        if Toggle._KeyPicker == Picker then
            Toggle._KeyPicker = nil
        end
    end

    KeyButton.MouseEnter:Connect(function()
        if not Listening then
            Tween(KeyButton, 0.12, {
                BackgroundColor3 = Active and Library.Theme.Selected or Library.Theme.ElementHover,
                TextColor3 = Library.Theme.TextBright,
            })
        end
    end)

    KeyButton.MouseLeave:Connect(function()
        if not Listening then
            UpdateButton()
        end
    end)

    KeyButton.MouseButton1Click:Connect(function()
        Listening = true
        Picker.Listening = true
        UpdateButton()
    end)

    local InputBeganConnection
    local InputEndedConnection

    InputBeganConnection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
        if Destroyed then
            return
        end

        if Listening then
            if Input.UserInputType == Enum.UserInputType.Keyboard then
                if Input.KeyCode ~= Enum.KeyCode.Unknown then
                    CurrentKey = Input.KeyCode
                    Picker.Value = CurrentKey
                    Picker.KeyCode = CurrentKey
                    Listening = false
                    Picker.Listening = false
                    UpdateButton()
                    SafeCall(Picker.Changed, CurrentKey)
                end
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                Listening = false
                Picker.Listening = false
                UpdateButton()
            end
            return
        end

        if GameProcessed then
            return
        end

        if Input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if Input.KeyCode ~= CurrentKey then
            return
        end

        if Mode == "Hold" then
            SetActive(true)
        else
            SetActive(not Active)
        end
    end)

    if Mode == "Hold" then
        InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
            if Destroyed then
                return
            end

            if Input.UserInputType == Enum.UserInputType.Keyboard
                and Input.KeyCode == CurrentKey then
                SetActive(false)
            end
        end)
    end

    -- Disconnect input listeners when the picker is destroyed.
    local OriginalDestroy = Picker.Destroy
    function Picker:Destroy()
        if Destroyed then
            return
        end

        OriginalDestroy(self)

        pcall(function()
            InputBeganConnection:Disconnect()
        end)

        pcall(function()
            if InputEndedConnection then
                InputEndedConnection:Disconnect()
            end
        end)
    end

    if Options.NoUI then
        KeyButton.Visible = false

        -- With no visible key box, use the normal toggle position again.
        local HiddenSwitch = Toggle.Container:FindFirstChild("Switch")
        if HiddenSwitch then
            HiddenSwitch.Position = UDim2.new(1, -40, 0.5, -8)
        end

        local HiddenToggleText = Toggle.Container:FindFirstChild("Text")
        if HiddenToggleText and HiddenToggleText:IsA("TextLabel") then
            HiddenToggleText.Size = UDim2.new(1, -55, 1, 0)
        end
    end

    Toggle._KeyPicker = Picker
    Toggle.KeyPicker = Picker
    Library.KeyPickers[Key] = Picker

    UpdateButton()

    -- Obsidian davranışı: SyncToggleState ile picker ve toggle birbirine bağlı olur.
    if SyncToggleState then
        local OldChanged = Toggle.Changed
        Toggle.Changed = function(Value)
            if not Destroyed then
                Active = Value == true
                Picker.Active = Active
                UpdateButton()
            end

            SafeCall(OldChanged, Value)
        end

        Active = Toggle:GetValue() == true
        Picker.Active = Active
        UpdateButton()
    end

    return Picker
end

-- Toggle:AddKeyPicker(...) is the Obsidian-style API.
function ElementMethods:AddKeyPicker(Identifier, Info)
    if self.Type ~= "Toggle" then
        warn("[MoonHub] AddKeyPicker can only be used on a Toggle.")
        return nil
    end

    return CreateToggleKeyPicker(self, Identifier, Info)
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
        Name = "DropdownButton",
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

    --// Thin dropdown chevron (no TextLabel / no bold glyph)
    local Chevron = New("Frame", {
        Name = "DropdownChevron",
        Position = UDim2.new(1, -18, 0.5, -5),
        Size = UDim2.new(0, 9, 0, 9),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = Button,
    })

    local ChevronLeft = New("Frame", {
        Name = "ChevronLeft",
        Size = UDim2.new(0, 6, 0, 1.25),
        Position = UDim2.new(0, 0, 0, 3),
        AnchorPoint = Vector2.new(0, 0.5),
        Rotation = 45,
        BackgroundColor3 = Library.Theme.TextDim,
        BorderSizePixel = 0,
        Parent = Chevron,
    })

    local ChevronRight = New("Frame", {
        Name = "ChevronRight",
        Size = UDim2.new(0, 6, 0, 1.25),
        Position = UDim2.new(0, 4, 0, 3),
        AnchorPoint = Vector2.new(0, 0.5),
        Rotation = -45,
        BackgroundColor3 = Library.Theme.TextDim,
        BorderSizePixel = 0,
        Parent = Chevron,
    })

    local OptionsFrame = New("Frame", {
        Name = "OptionsFrame",
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, math.max(1, #Values) * 30 + 6),
        BackgroundColor3 = Library.Theme.Panel,
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

        ChevronLeft.Rotation = Open and 135 or 45
        ChevronRight.Rotation = Open and -135 or -45
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

    function Dropdown:SetValues(NewValues, Default)
        if type(NewValues) ~= "table" then
            NewValues = {}
        end

        Values = NewValues
        Dropdown.Values = NewValues

        for _, Child in ipairs(OptionsFrame:GetChildren()) do
            if Child:IsA("TextButton") then
                Child:Destroy()
            end
        end

        local NewSelected

        if type(Default) == "number" then
            NewSelected = Values[Default]
        elseif Default ~= nil then
            NewSelected = Default
        end

        if NewSelected == nil or not table.find(Values, NewSelected) then
            if Dropdown.Value and table.find(Values, Dropdown.Value) then
                NewSelected = Dropdown.Value
            else
                NewSelected = Values[1] or ""
            end
        end

        Dropdown.Value = NewSelected
        Selected = NewSelected
        Label.Text = Text .. ": " .. tostring(NewSelected)

        OptionsFrame.Size = UDim2.new(1, 0, 0, math.max(1, #Values) * 30 + 6)

        for Index, Value in ipairs(Values) do
            local Option = New("TextButton", {
                Name = "Option_" .. tostring(Index),
                Size = UDim2.new(1, -8, 0, 30),
                BackgroundColor3 = Library.Theme.Panel,
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
                    BackgroundColor3 = Library.Theme.Panel,
                    TextColor3 = Library.Theme.Text,
                })
            end)

            Option.MouseButton1Click:Connect(function()
                SetValue(Value)
            end)
        end
    end

    for Index, Value in ipairs(Values) do
        local Option = New("TextButton", {
            Name = "Option_" .. tostring(Index),
            Size = UDim2.new(1, -8, 0, 30),
            BackgroundColor3 = Library.Theme.Panel,
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
                BackgroundColor3 = Library.Theme.Panel,
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
        Tooltip = Options.Tooltip,
    }

    setmetatable(Button, {__index = ElementMethods})

    if Options.Tooltip then
        Button:AddTooltip(Options.Tooltip)
    end

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

local function CreateSlider(Parent, Key, Options)
    Options = Options or {}

    local Text = Options.Text or Key
    local Min = tonumber(Options.Min) or 0
    local Max = tonumber(Options.Max) or 100
    local Default = tonumber(Options.Default)

    if Min > Max then
        Min, Max = Max, Min
    end

    if Default == nil then
        Default = Min
    end

    Default = math.clamp(Default, Min, Max)

    local Holder = New("Frame", {
        Name = Key,
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = Parent.Container,
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

    -- Modern slider track.
    -- İnce bir çizgi yerine UICorner'lı, daha dolgun bir kapsül kullanılıyor.
    local SliderTrack = New("Frame", {
        Name = "SliderTrack",
        Position = UDim2.new(0, 0, 0, 29),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Library.Theme.ToggleOff,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = Holder,
    })

    Corner(SliderTrack, 5)

    local Percent = 0
    if Max ~= Min then
        Percent = (Default - Min) / (Max - Min)
    end

    local SliderFill = New("Frame", {
        Name = "SliderFill",
        Size = UDim2.new(Percent, 0, 1, 0),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        Parent = SliderTrack,
    })

    Corner(SliderFill, 5)

    -- Sürüklenebilir modern thumb:
    -- Yuvarlak nokta yerine küçük UICorner'lı kapsül/frame.
    local SliderThumb = New("Frame", {
        Name = "SliderThumb",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(Percent, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = Library.Theme.TextBright,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = SliderTrack,
    })

    Corner(SliderThumb, 5)

    local ThumbStroke = New("UIStroke", {
        Name = "ThumbStroke",
        Thickness = 1,
        Color = Library.Theme.Outline,
        Transparency = 0,
        Parent = SliderThumb,
    })

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

    local function SetVisualPercent(ValueToUse)
        local VisualPercent = 0

        if Max ~= Min then
            VisualPercent = math.clamp(
                (ValueToUse - Min) / (Max - Min),
                0,
                1
            )
        end

        SliderFill.Size = UDim2.new(
            VisualPercent,
            0,
            1,
            0
        )

        SliderThumb.Position = UDim2.new(
            VisualPercent,
            0,
            0.5,
            0
        )
    end

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

        Value = math.clamp(NewValue, Min, Max)
        Slider.Value = Value

        SetVisualPercent(Value)
        ValueLabel.Text = tostring(Value)

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

    local function UpdateFromX(X)
        local Start = SliderTrack.AbsolutePosition.X
        local Width = SliderTrack.AbsoluteSize.X

        if Width <= 0 then
            return
        end

        local VisualPercent = math.clamp(
            (X - Start) / Width,
            0,
            1
        )

        SetValue(
            Min + ((Max - Min) * VisualPercent)
        )
    end

    local function BeginDrag(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then

            Dragging = true
            UpdateFromX(Input.Position.X)
        end
    end

    SliderTrack.InputBegan:Connect(BeginDrag)
    SliderThumb.InputBegan:Connect(BeginDrag)

    UserInputService.InputChanged:Connect(function(Input)
        if not Dragging then
            return
        end

        if Input.UserInputType == Enum.UserInputType.MouseMovement
            or Input.UserInputType == Enum.UserInputType.Touch then

            UpdateFromX(Input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then

            Dragging = false
        end
    end)

    -- Başlangıç görünümünü garanti et.
    SetVisualPercent(Value)

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

function GroupboxMethods:AddKeyPicker(Identifier, Info)
    return CreateKeyPicker(self, Identifier, Info)
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

    Box:SetAttribute("MoonHubGroupbox", true)

    Corner(Box, 7)
    Stroke(Box, Library.Theme.OutlineSoft, 0.08, 1)

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
        TextColor3 = Library.Theme.TextBright,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextStrokeColor3 = Library.Theme.Background,
        TextStrokeTransparency = 0.88,
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
        ScrollBarImageColor3 = Library.Theme.Outline,
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
        ScrollBarImageColor3 = Library.Theme.Outline,
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
                Library.Theme.TextBright

            local OldText =
                self.ActiveTab.Button:FindFirstChild("Text")

            if OldText then
                OldText.TextColor3 =
                    Library.Theme.TextBright
            end
        end

        self.ActiveTab = Tab
        self.LastTabName = Tab.Name

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
                    Library.Theme.TextBright
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
    if Library.Unloaded then
        return false
    end

    return Library:Unload()
end

--//==================================================
--// CREATE WINDOW
--//==================================================

--//==================================================
--// MOONHUB BACKGROUND VISUALS
--//==================================================

local function SetMoonHubGradient(Object, Keypoints, Rotation)
    if not Object then
        return
    end

    local Gradient = Object:FindFirstChild("MoonHubGradient")
    if not Gradient then
        Gradient = Instance.new("UIGradient")
        Gradient.Name = "MoonHubGradient"
        Gradient.Parent = Object
    end

    Gradient.Rotation = Rotation or 35
    Gradient.Color = ColorSequence.new(Keypoints)
    Gradient.Enabled = Library.Theme.GradientEnabled == true
end

local function EnsureMoonHubStars(Frame)
    if not Frame then
        return
    end

    local Folder = Frame:FindFirstChild("MoonHubStars")
    if not Folder then
        Folder = Instance.new("Folder")
        Folder.Name = "MoonHubStars"
        Folder.Parent = Frame

        local RandomObject = Random.new(41514)
        for Index = 1, 100 do
            local Star = Instance.new("Frame")
            Star.Name = "Star" .. Index
            Star.Size = UDim2.fromOffset(
                RandomObject:NextInteger(1, 2),
                RandomObject:NextInteger(1, 2)
            )
            Star.Position = UDim2.new(
                RandomObject:NextNumber(), 0,
                RandomObject:NextNumber(), 0
            )
            Star.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Star.BackgroundTransparency = RandomObject:NextNumber(0.55, 0.90)
            Star.BorderSizePixel = 0
            Star.ZIndex = 0
            Star.Parent = Folder
        end
    end

    -- Stars are a MoonHub-only visual. Do not tie them to generic gradient state.
    local StarsVisible = Library.Theme.StarsEnabled == true
    for _, Star in ipairs(Folder:GetChildren()) do
        if Star:IsA("GuiObject") then
            Star.Visible = StarsVisible
        end
    end
end

local function RefreshMoonHubBackgrounds(Frame, TopBar, Explorer, Modules, Content, SearchBox)
    if not Frame then
        return
    end

    local Theme = Library.Theme
    local Enabled = Theme.GradientEnabled == true

    -- MainFrame is ALWAYS solid. The visible outline is a separate overlay,
    -- so no gradient can bleed into the outer edge.
    Frame.BackgroundColor3 = Theme.Background
    Frame.BackgroundTransparency = 0

    local BackgroundVisual = Frame:FindFirstChild("MainBackgroundVisual")
    if BackgroundVisual then
        BackgroundVisual.BackgroundColor3 = Theme.Background
        local Gradient = BackgroundVisual:FindFirstChild("MoonHubGradient")
        if Gradient then Gradient.Enabled = Enabled end
    end

    -- MoonHub is the only nebula-gradient theme. Other themes use their own
    -- flat colors, so changing theme can never leave MoonHub blue behind.
    if Enabled then
        SetMoonHubGradient(BackgroundVisual, {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(3, 10, 22)),
            ColorSequenceKeypoint.new(0.18, Color3.fromRGB(5, 20, 39)),
            ColorSequenceKeypoint.new(0.38, Color3.fromRGB(8, 31, 58)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(12, 45, 78)),
            ColorSequenceKeypoint.new(0.72, Color3.fromRGB(7, 29, 55)),
            ColorSequenceKeypoint.new(0.88, Color3.fromRGB(4, 17, 35)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 9, 20)),
        }, 28)

        SetMoonHubGradient(TopBar, {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 16, 31)),
            ColorSequenceKeypoint.new(0.30, Color3.fromRGB(8, 29, 51)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(13, 43, 72)),
            ColorSequenceKeypoint.new(0.78, Color3.fromRGB(8, 27, 49)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 13, 27)),
        }, 25)

        local NebulaSide = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 14, 28)),
            ColorSequenceKeypoint.new(0.35, Color3.fromRGB(6, 24, 45)),
            ColorSequenceKeypoint.new(0.58, Color3.fromRGB(9, 34, 58)),
            ColorSequenceKeypoint.new(0.82, Color3.fromRGB(5, 21, 40)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 12, 25)),
        }
        SetMoonHubGradient(Explorer, NebulaSide, 25)
        SetMoonHubGradient(Modules, NebulaSide, 25)

        SetMoonHubGradient(Content, {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(3, 11, 23)),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(7, 26, 48)),
            ColorSequenceKeypoint.new(0.72, Color3.fromRGB(9, 31, 55)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 11, 23)),
        }, 25)

        SetMoonHubGradient(SearchBox, {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 25, 44)),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(13, 43, 68)),
            ColorSequenceKeypoint.new(0.70, Color3.fromRGB(18, 55, 82)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 23, 42)),
        }, 20)
    else
        local Objects = {BackgroundVisual, TopBar, Explorer, Modules, Content, SearchBox}
        for _, Object in ipairs(Objects) do
            if Object then
                local Gradient = Object:FindFirstChild("MoonHubGradient")
                if Gradient then Gradient.Enabled = false end
            end
        end

        if TopBar then TopBar.BackgroundColor3 = Theme.Panel end
        if Explorer then Explorer.BackgroundColor3 = Theme.Sidebar end
        if Modules then Modules.BackgroundColor3 = Theme.Sidebar end
        if Content then Content.BackgroundColor3 = Theme.Background end
        if SearchBox then SearchBox.BackgroundColor3 = Theme.Element end
    end

    EnsureMoonHubStars(Frame)
end

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
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Gui,
    })

    Corner(Frame, 9)

    -- Solid layer directly under the outer stroke.
    -- The MoonHub gradient is applied to this layer instead of MainFrame,
    -- keeping the entire extreme outer outline visually flat and uniform.
    local BackgroundVisual = New("Frame", {
        Name = "MainBackgroundVisual",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 0,
        Parent = Frame,
    })

    Corner(BackgroundVisual, 8)

    -- Dedicated solid outer outline. This is drawn ABOVE every visual layer,
    -- so the extreme edge can never inherit a nebula/gradient color.
    local OuterOutline = New("Frame", {
        Name = "MainOuterOutline",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 50,
        Parent = Frame,
    })
    Corner(OuterOutline, 9)
    Stroke(OuterOutline, Library.Theme.OutlineSoft, 0, 1)

    EnsureMoonHubStars(Frame)

    local TopBar = New("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 =
            Library.Theme.Panel,
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

    --// Game Name
    -- Use the current PlaceId instead of game.Name because some executors
    -- expose game.Name as "UGC"/"Game" instead of the actual place name.
    local GameName = New("TextLabel", {
        Name = "GameName",
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 190, 0, 36),
        BackgroundTransparency = 1,
        Text = "Loading...",
        TextColor3 = Library.Theme.TextBright,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
        Parent = TopBar,
    })

    task.spawn(function()
        local PlaceId = tonumber(game.PlaceId)
        local FoundName = nil

        local function AcceptPlaceInfo(Info)
            if type(Info) ~= "table" then
                return nil
            end

            local Name = Info.Name
            local AssetTypeId = tonumber(Info.AssetTypeId)

            -- Place assets use AssetTypeId 9. This prevents executor-provided
            -- generic names such as "UGC" from being used as the game name.
            if AssetTypeId == 9
                and type(Name) == "string"
                and Name ~= "" then
                return Name
            end

            return nil
        end

        if PlaceId and PlaceId > 0 then
            local Success, Info = pcall(function()
                return MarketplaceService:GetProductInfoAsync(
                    PlaceId,
                    Enum.InfoType.Asset
                )
            end)

            if Success then
                FoundName = AcceptPlaceInfo(Info)
            end

            if not FoundName then
                local OldSuccess, OldInfo = pcall(function()
                    return MarketplaceService:GetProductInfo(
                        PlaceId,
                        Enum.InfoType.Asset
                    )
                end)

                if OldSuccess then
                    FoundName = AcceptPlaceInfo(OldInfo)
                end
            end
        end

        if GameName and GameName.Parent then
            GameName.Text = FoundName or "Unknown Game"
        end
    end)

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
            Library.Theme.Element,
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

    --// Search icon (thin magnifier, like the old MoonHub UI)
    local SearchIcon = Instance.new("Frame")
    SearchIcon.Name = "SearchIcon"
    SearchIcon.Size = UDim2.new(0, 15, 0, 15)
    SearchIcon.Position = UDim2.new(0, 8, 0.5, -8)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.BorderSizePixel = 0
    SearchIcon.Parent = SearchBox

    local SearchCircle = Instance.new("Frame")
    SearchCircle.Name = "SearchCircle"
    SearchCircle.Size = UDim2.new(0, 8, 0, 8)
    SearchCircle.Position = UDim2.new(0, 1, 0, 1)
    SearchCircle.BackgroundTransparency = 1
    SearchCircle.BorderSizePixel = 0
    SearchCircle.Parent = SearchIcon

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = SearchCircle

    local CircleStroke = Instance.new("UIStroke")
    CircleStroke.Name = "CircleStroke"
    CircleStroke.Thickness = 1.5
    CircleStroke.Color = Library.Theme.TextDim
    CircleStroke.Parent = SearchCircle

    local SearchHandle = Instance.new("Frame")
    SearchHandle.Name = "SearchHandle"
    SearchHandle.Size = UDim2.new(0, 6, 0, 1.5)
    SearchHandle.Position = UDim2.new(0, 8, 0, 10)
    SearchHandle.AnchorPoint = Vector2.new(0, 0.5)
    SearchHandle.Rotation = 45
    SearchHandle.BackgroundColor3 = Library.Theme.TextDim
    SearchHandle.BorderSizePixel = 0
    SearchHandle.Parent = SearchIcon

    local SearchInput = New("TextBox", {
        Name = "SearchInput",
        Position = UDim2.new(0, 31, 0, 0),
        Size = UDim2.new(1, -34, 1, 0),
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
            Library.Theme.Outline,
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

    RefreshMoonHubBackgrounds(
        Frame,
        TopBar,
        SearchArea,
        Modules,
        Content,
        SearchBox
    )

    local Window = {
        Title = Title,
        Footer = Footer,
        Gui = Gui,
        Frame = Frame,
        TopBar = TopBar,
        GameName = GameName,
        SearchInput = SearchInput,
        ModuleContainer = ModuleContainer,
        Content = Content,
        Tabs = {},
        ActiveTab = nil,
        LastTabName = nil,
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
        Text = "−",
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
        Text = "×",
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
    local Theme = Library.Theme

    for _, Gui in ipairs(PlayerGui:GetChildren()) do
        if Gui.Name == "MoonHub" then
            local MainFrame = Gui:FindFirstChild("MainFrame")
            if MainFrame then
                local TopBar = MainFrame:FindFirstChild("TopBar")
                local Explorer = MainFrame:FindFirstChild("Explorer")
                local Modules = MainFrame:FindFirstChild("Modules")
                local Content = MainFrame:FindFirstChild("Content")
                local SearchBox = Explorer and Explorer:FindFirstChild("SearchBox")
                RefreshMoonHubBackgrounds(
                    MainFrame,
                    TopBar,
                    Explorer,
                    Modules,
                    Content,
                    SearchBox
                )
            end
        end
    end

    if ActiveTooltip and ActiveTooltip.Parent then
        ActiveTooltip.BackgroundColor3 = Theme.Panel
        local TooltipStroke = ActiveTooltip:FindFirstChildOfClass("UIStroke")
        if TooltipStroke then
            TooltipStroke.Color = Theme.Outline
        end

        local TooltipText = ActiveTooltip:FindFirstChild("Text")
        if TooltipText and TooltipText:IsA("TextLabel") then
            TooltipText.TextColor3 = Theme.Text
        end
    end

    local function ApplyStroke(Object, Color, Transparency)
        if not Object then
            return
        end

        pcall(function()
            Object.BorderSizePixel = 0
        end)

        local FirstOutline = nil
        for _, Child in ipairs(Object:GetChildren()) do
            if Child:IsA("UIStroke") then
                -- Keep intentionally named special strokes such as ThumbStroke
                -- and CircleStroke, but collapse duplicate generic outlines.
                if Child.Name == "Outline" then
                    if FirstOutline then
                        Child:Destroy()
                    else
                        FirstOutline = Child
                    end
                end
            end
        end

        for _, Child in ipairs(Object:GetChildren()) do
            if Child:IsA("UIStroke") and (Child.Name == "Outline" or Child.Name == "ThumbStroke" or Child.Name == "CircleStroke") then
                Child.Color = Color
                if Transparency ~= nil then
                    Child.Transparency = Transparency
                end
                Child.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                pcall(function()
                    Child.BorderStrokePosition = Enum.BorderStrokePosition.Inner
                    Child.BorderOffset = UDim.new(0, 0)
                    Child.LineJoinMode = Enum.LineJoinMode.Round
                end)
            end
        end
    end

    local function ApplyElement(Object)
        if Object:GetAttribute("MoonHubGroupbox") then
            Object.BackgroundColor3 = Theme.Panel
            ApplyStroke(Object, Theme.OutlineSoft, 0.08)
            return
        end

        if Object.Name == "MainFrame" then
            Object.BackgroundColor3 = Theme.Background

            local BackgroundVisual = Object:FindFirstChild("MainBackgroundVisual")
            if BackgroundVisual then
                BackgroundVisual.BackgroundColor3 = Theme.Background
                ApplyStroke(BackgroundVisual, Theme.Background, 1)
            end
        elseif Object.Name == "MainBackgroundVisual" then
            Object.BackgroundColor3 = Theme.Background
        elseif Object.Name == "MainOuterOutline" then
            Object.BackgroundTransparency = 1
            ApplyStroke(Object, Theme.OutlineSoft, 0)
        elseif Object.Name == "TopBar" then
            Object.BackgroundColor3 = Theme.Panel
        elseif Object.Name == "Explorer" or Object.Name == "Modules" then
            Object.BackgroundColor3 = Theme.Sidebar
        elseif Object.Name == "Content" then
            Object.BackgroundColor3 = Theme.Background
        elseif Object.Name == "SearchBox" then
            Object.BackgroundColor3 = Theme.Element
            ApplyStroke(Object, Theme.Outline, 0.12)
        elseif Object.Name == "ModuleContainer" and Object:IsA("ScrollingFrame") then
            Object.ScrollBarImageColor3 = Theme.Outline
        elseif Object.Name == "SearchHandle" then
            Object.BackgroundColor3 = Theme.TextDim
        elseif Object.Name == "CircleStroke" and Object:IsA("UIStroke") then
            Object.Color = Theme.TextDim
        elseif Object.Name == "Header" and Object:IsA("TextLabel") then
            Object.TextColor3 = Theme.TextBright
        elseif Object.Name == "Title" and Object:IsA("TextLabel") then
            Object.TextColor3 = Theme.TextBright
            Object.TextStrokeColor3 = Theme.Background
        elseif Object.Name == "GameName" and Object:IsA("TextLabel") then
            Object.TextColor3 = Theme.TextBright
            Object.TextStrokeColor3 = Theme.Background
        elseif Object.Name == "Description" and Object:IsA("TextLabel") then
            Object.TextColor3 = Theme.TextDim
        elseif Object.Name == "Minimize" or Object.Name == "Close" then
            Object.TextColor3 = Theme.TextDim
        elseif Object.Name == "Text" and Object:IsA("TextLabel") then
            Object.TextColor3 = Theme.Text
        elseif Object.Name == "SearchInput" and Object:IsA("TextBox") then
            Object.TextColor3 = Theme.Text
            Object.PlaceholderColor3 = Theme.Placeholder
        elseif Object.Name == "DropdownChevron" then
            Object.BackgroundColor3 = Theme.Panel
        elseif Object.Name == "ChevronLeft" or Object.Name == "ChevronRight" then
            Object.BackgroundColor3 = Theme.TextDim
        elseif Object.Name == "KeyButton" and Object:IsA("TextButton") then
            Object.BackgroundColor3 = Theme.Panel
            Object.TextColor3 = Theme.TextDim
            ApplyStroke(Object, Theme.Outline, 0.15)
        elseif Object.Name == "Option_1" or string.sub(Object.Name, 1, 7) == "Option_" then
            if Object:IsA("TextButton") then
                Object.BackgroundColor3 = Theme.Panel
                Object.TextColor3 = Theme.Text
            end
        elseif Object.Name == "SliderTrack" then
            Object.BackgroundColor3 = Theme.ToggleOff
        elseif Object.Name == "SliderFill" then
            Object.BackgroundColor3 = Theme.Accent
        elseif Object.Name == "SliderThumb" then
            Object.BackgroundColor3 = Theme.TextBright
            ApplyStroke(Object, Theme.Outline, 0)
        elseif Object.Name == "ThumbStroke" and Object:IsA("UIStroke") then
            Object.Color = Theme.Outline
        elseif Object.Name == "Tooltip" then
            Object.BackgroundColor3 = Theme.Panel
            ApplyStroke(Object, Theme.Outline, 0.1)
        elseif Object.Name == "Notification" then
            Object.BackgroundColor3 = Theme.Panel
            ApplyStroke(Object, Theme.OutlineSoft, 0.18)
        elseif Object.Name == "Progress" then
            Object.BackgroundColor3 = Theme.Accent
        elseif Object.Name == "ProgressBackground" then
            Object.BackgroundColor3 = Theme.Element
        elseif Object.Name == "OptionsFrame" then
            Object.BackgroundColor3 = Theme.Panel
        elseif string.match(Object.Name, "Module$") and Object:IsA("TextButton") then
            -- MoonHub module buttons intentionally keep the same solid blue
            -- seen in the reference: dark UI around them, clear blue modules.
            Object.BackgroundColor3 = Theme.Element
            Object.TextColor3 = Theme.TextBright

            local ModuleText = Object:FindFirstChild("Text")
            if ModuleText and ModuleText:IsA("TextLabel") then
                ModuleText.TextColor3 = Theme.TextBright
            end
        elseif Object.Name == "DropdownButton" and Object:IsA("TextButton") then
            Object.BackgroundColor3 = Theme.Element
            Object.TextColor3 = Theme.Text
            ApplyStroke(Object, Theme.Outline, 0.12)
        elseif Object.Name == "Divider" then
            Object.BackgroundColor3 = Theme.Outline
        elseif Object:IsA("TextBox") then
            Object.TextColor3 = Theme.Text
            Object.PlaceholderColor3 = Theme.Placeholder
        elseif Object:IsA("TextButton") then
            Object.BackgroundColor3 = Theme.Element
            Object.TextColor3 = Theme.Text
        elseif Object:IsA("TextLabel") and Object.BackgroundTransparency < 1 then
            Object.TextColor3 = Theme.Text
        end
    end

    for _, Gui in ipairs(PlayerGui:GetChildren()) do
        if Gui.Name == "MoonHub" or Gui.Name == "MoonHubNotifications" or Gui.Name == "MoonHubTooltip" then
            for _, Object in ipairs(Gui:GetDescendants()) do
                pcall(function()
                    ApplyElement(Object)

                    if Object:IsA("UIStroke") then
                        local Parent = Object.Parent
                        if Parent then
                            if Parent:GetAttribute("MoonHubGroupbox") then
                                Object.Color = Theme.OutlineSoft
                            elseif Parent.Name == "Notification" then
                                Object.Color = Theme.OutlineSoft
                            elseif Parent.Name == "SearchBox" then
                                Object.Color = Theme.Outline
                            elseif Parent.Name == "KeyButton" or Parent.Name == "Button" then
                                Object.Color = Theme.Outline
                            end
                        end
                    end
                end)
            end
        end
    end

    -- Hard refresh dropdowns so no dropdown can keep the previous theme.
    for _, Dropdown in pairs(Library.Options) do
        pcall(function()
            if Dropdown.Type == "Dropdown" then
                local Container = Dropdown.Container
                local Button = Container and Container:FindFirstChild("DropdownButton")
                local OptionsFrame = Container and Container:FindFirstChild("OptionsFrame")
                if Button then
                    Button.BackgroundColor3 = Theme.Element
                    Button.TextColor3 = Theme.Text
                    ApplyStroke(Button, Theme.Outline, 0.12)
                    local Label = Button:FindFirstChildOfClass("TextLabel")
                    if Label then Label.TextColor3 = Theme.Text end
                end
                if OptionsFrame then
                    OptionsFrame.BackgroundColor3 = Theme.Panel
                    for _, Option in ipairs(OptionsFrame:GetChildren()) do
                        if Option:IsA("TextButton") and string.sub(Option.Name, 1, 7) == "Option_" then
                            Option.BackgroundColor3 = Theme.Panel
                            Option.TextColor3 = Theme.Text
                            ApplyStroke(Option, Theme.OutlineSoft, 0.10)
                        end
                    end
                end
            end
        end)
    end

    for _, Toggle in pairs(Library.Toggles) do
        pcall(function()
            local Container = Toggle.Container
            local Switch = Container:FindFirstChild("Switch")
            local Knob = Switch and Switch:FindFirstChild("Knob")
            local Label = Container:FindFirstChild("Text")

            Container.BackgroundColor3 = Theme.Element
            ApplyStroke(Container, Theme.Outline, 0.12)

            if Switch then
                Switch.BackgroundColor3 = Toggle.Value and Theme.ToggleOn or Theme.ToggleOff
                ApplyStroke(Switch, Toggle.Value and Theme.ToggleOn or Theme.Outline, Toggle.Value and 0.02 or 0.22)
            end

            if Knob then
                Knob.BackgroundColor3 = Toggle.Value and Theme.TextBright or Theme.KnobOff
                ApplyStroke(Knob, Toggle.Value and Theme.TextBright or Theme.Outline, Toggle.Value and 0.02 or 0.10)
                Knob.Position = Toggle.Value
                    and UDim2.new(1, -14, 0.5, -6)
                    or UDim2.new(0, 2, 0.5, -6)
            end

            if Label then
                Label.TextColor3 = Toggle.Value and Theme.TextBright or Theme.Text
            end
        end)
    end

    for _, Gui in ipairs(PlayerGui:GetChildren()) do
        if Gui.Name == "MoonHub" then
            local MainFrame = Gui:FindFirstChild("MainFrame")
            local Modules = MainFrame and MainFrame:FindFirstChild("Modules")
            local ModuleContainer = Modules and Modules:FindFirstChild("ModuleContainer")
            if ModuleContainer then
                for _, ModuleButton in ipairs(ModuleContainer:GetChildren()) do
                    if ModuleButton:IsA("TextButton") then
                        ModuleButton.BackgroundColor3 = Theme.Element
                        local ModuleText = ModuleButton:FindFirstChild("Text")
                        if ModuleText and ModuleText:IsA("TextLabel") then
                            ModuleText.TextColor3 = Theme.TextBright
                        end
                    end
                end
            end
        end
    end

    for _, Button in pairs(Library.Buttons) do
        pcall(function()
            Button.Container.BackgroundColor3 = Theme.Element
            Button.Container.TextColor3 = Theme.Text
            ApplyStroke(Button.Container, Theme.Outline, 0.12)
        end)
    end

    for _, Picker in pairs(Library.KeyPickers) do
        pcall(function()
            Picker.Container.BackgroundColor3 = Theme.Element
            ApplyStroke(Picker.Container, Theme.Outline, 0.12)

            local Label = Picker.Container:FindFirstChild("Text")
            if Label then
                Label.TextColor3 = Theme.Text
            end

            local KeyButton = Picker.Button or Picker.Container:FindFirstChild("KeyButton")
            if KeyButton then
                if Picker.Listening then
                    KeyButton.BackgroundColor3 = Theme.ElementHover
                    KeyButton.TextColor3 = Theme.TextBright
                else
                    KeyButton.BackgroundColor3 = Theme.Panel
                    KeyButton.TextColor3 = Theme.TextDim
                end
                ApplyStroke(KeyButton, Theme.Outline, 0.10)
            end
        end)
    end

    for _, Dropdown in pairs(Library.Options) do
        if Dropdown.Type == "Dropdown" then
            pcall(function()
                local Container = Dropdown.Container
                Container.BackgroundTransparency = 1

                local MainButton = Container:FindFirstChildWhichIsA("TextButton")
                if MainButton then
                    MainButton.BackgroundColor3 = Theme.Element
                    ApplyStroke(MainButton, Theme.Outline, 0.12)

                    local Label = MainButton:FindFirstChild("Text")
                    if Label then
                        Label.TextColor3 = Theme.Text
                    end

                    local Left = MainButton:FindFirstChild("DropdownChevron")
                    if Left then
                        for _, Chevron in ipairs(Left:GetChildren()) do
                            if Chevron:IsA("Frame") then
                                Chevron.BackgroundColor3 = Theme.TextDim
                            end
                        end
                    end
                end

                for _, Object in ipairs(Container:GetDescendants()) do
                    if Object:IsA("TextButton") and string.sub(Object.Name, 1, 7) == "Option_" then
                        Object.BackgroundColor3 = Theme.Panel
                        Object.TextColor3 = Theme.Text
                        ApplyStroke(Object, Theme.OutlineSoft, 0.10)
                    elseif Object.Name == "ChevronLeft" or Object.Name == "ChevronRight" then
                        Object.BackgroundColor3 = Theme.TextDim
                    end
                end
            end)
        end
    end

    for _, Input in pairs(Library.Labels) do
        pcall(function()
            if Input.Type == "Input" then
                local Holder = Input.Container
                local Label = Holder:FindFirstChildOfClass("TextLabel")
                local Box = Input.Box or Holder:FindFirstChildOfClass("TextBox")

                if Label then
                    Label.TextColor3 = Theme.Text
                end

                if Box then
                    Box.BackgroundColor3 = Theme.Element
                    Box.TextColor3 = Theme.Text
                    Box.PlaceholderColor3 = Theme.Placeholder
                    ApplyStroke(Box, Theme.Outline, 0.12)
                end
            elseif Input.Type == "Label" then
                Input.Container.TextColor3 = Theme.TextDim
            end
        end)
    end

    for _, Option in pairs(Library.Options) do
        if Option.Type == "Slider" then
            pcall(function()
                local Holder = Option.Container
                local Label = Holder:FindFirstChildOfClass("TextLabel")
                local Track = Holder:FindFirstChild("SliderTrack")
                local Fill = Track and Track:FindFirstChild("SliderFill")
                local Thumb = Track and Track:FindFirstChild("SliderThumb")
                local ValueLabel = nil

                local TextLabels = Holder:GetChildren()
                for _, Child in ipairs(TextLabels) do
                    if Child:IsA("TextLabel") and Child ~= Label then
                        ValueLabel = Child
                    end
                end

                if Label then
                    Label.TextColor3 = Theme.Text
                end

                if ValueLabel then
                    ValueLabel.TextColor3 = Theme.TextDim
                end

                if Track then
                    Track.BackgroundColor3 = Theme.ToggleOff
                    ApplyStroke(Track, Theme.OutlineSoft, 0.12)
                end

                if Fill then
                    Fill.BackgroundColor3 = Theme.Accent
                end

                if Thumb then
                    Thumb.BackgroundColor3 = Theme.TextBright
                    ApplyStroke(Thumb, Theme.Outline, 0.05)
                end
            end)
        end
    end

    for _, TabButton in pairs(Library.Windows) do
        pcall(function()
            for _, Tab in pairs(TabButton.Tabs) do
                Tab.Button.BackgroundColor3 = TabButton.ActiveTab == Tab and Theme.Selected or Theme.Element
                local Text = Tab.Button:FindFirstChild("Text")
                if Text then
                    Text.TextColor3 = TabButton.ActiveTab == Tab and Theme.TextBright or Theme.TextDim
                    Text.TextStrokeColor3 = Theme.Background
                end
            end
        end)
    end

    for _, Callback in ipairs(Library._ThemeCallbacks) do
        pcall(Callback, Theme)
    end
end

function Library:SetTheme(Theme)
    -- A theme switch is a hard visual reset. Cancel every running hover/open
    -- tween first; otherwise an old tween can finish later and write the old
    -- theme color back into a dropdown, button, tab, etc.
    CancelThemeTweens()

    self._ThemeVersion = (self._ThemeVersion or 0) + 1
    local Version = self._ThemeVersion

    -- Start from the complete MoonHub base palette every single time.
    -- This prevents partial/custom themes from inheriting any previous color.
    for Key, Value in pairs(Library.DefaultTheme) do
        Library.Theme[Key] = Value
    end

    -- Only known theme keys are accepted.
    for Key, Value in pairs(Theme or {}) do
        if Library.DefaultTheme[Key] ~= nil then
            Library.Theme[Key] = Value
        end
    end

    self:RefreshTheme()

    -- A second pass catches objects created/opened during the switch and
    -- guarantees dropdown option frames use the new theme as well.
    task.delay(0.22, function()
        if self._ThemeVersion == Version and not self.Unloaded then
            CancelThemeTweens()
            pcall(function()
                self:RefreshTheme()
            end)
        end
    end)
end

function Library:SetAccent(Color)
    if typeof(Color) == "Color3" then
        Library.Theme.Accent = Color
        self:RefreshTheme()
    end
end

function Library:Unload()
    if self.Unloaded then
        return false
    end

    self.Unloaded = true

    local Callbacks = table.clone(self._UnloadCallbacks)
    table.clear(self._UnloadCallbacks)

    for _, Callback in ipairs(Callbacks) do
        pcall(Callback)
    end

    for _, Window in ipairs(self.Windows) do
        if Window then
            Window.Unloaded = true

            if Window.Frame then
                pcall(function()
                    Window.Frame:Destroy()
                end)
            end

            if Window.Gui then
                pcall(function()
                    Window.Gui:Destroy()
                end)
            end
        end
    end

    if NotificationGui then
        pcall(function()
            NotificationGui:Destroy()
        end)
        NotificationGui = nil
        NotificationList = nil
    end

    if TooltipGui then
        pcall(function()
            TooltipGui:Destroy()
        end)
        TooltipGui = nil
        ActiveTooltip = nil
    end

    table.clear(Notifications)
    table.clear(self.Toggles)
    table.clear(self.Options)
    table.clear(self.Labels)
    table.clear(self.Buttons)
    table.clear(self.KeyPickers)
    table.clear(self.Windows)
    table.clear(self._ThemeCallbacks)
    self.CurrentWindow = nil

    return true
end


return Library
