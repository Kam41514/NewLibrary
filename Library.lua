local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {
    Flags = {},
    Items = {},

    Theme = {
        Background = Color3.fromRGB(9, 10, 13),
        Surface = Color3.fromRGB(13, 15, 19),
        Surface2 = Color3.fromRGB(17, 19, 24),
        Element = Color3.fromRGB(22, 25, 31),
        ElementHover = Color3.fromRGB(27, 30, 38),

        Stroke = Color3.fromRGB(35, 39, 48),
        StrokeSoft = Color3.fromRGB(28, 31, 39),

        Text = Color3.fromRGB(245, 246, 249),
        SubText = Color3.fromRGB(166, 171, 182),
        Muted = Color3.fromRGB(105, 111, 124),

        Accent = Color3.fromRGB(108, 99, 255),
        AccentHover = Color3.fromRGB(124, 115, 255),
        AccentDark = Color3.fromRGB(79, 72, 190),

        White = Color3.fromRGB(255, 255, 255),
        Red = Color3.fromRGB(239, 92, 92)
    }
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function New(class, props, parent)
    local object = Instance.new(class)

    for property, value in pairs(props or {}) do
        object[property] = value
    end

    if parent then
        object.Parent = parent
    end

    return object
end

local function Corner(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, parent)
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color = color or Library.Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    }, parent)
end

local function Padding(parent, left, top, right, bottom)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0)
    }, parent)
end

local function Tween(object, properties, duration)
    if not object or not object.Parent then
        return
    end

    TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.18,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        properties
    ):Play()
end

local function Label(parent, text, size, color, font)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Library.Theme.Text,
        TextSize = size or 13,
        Font = font or FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, parent)
end

local function SetFlag(name, value)
    Library.Flags[name] = value
end

local function MakeDraggable(frame, handle)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

local WindowMethods = {}
local TabMethods = {}
local GroupboxMethods = {}

function Library:CreateWindow(options)
    options = options or {}

    local title = options.Title or "Library"
    local size = options.Size or UDim2.fromOffset(820, 570)

    local gui = New("ScreenGui", {
        Name = "UILibrary",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, PlayerGui)

    local main = New("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(
            0.5,
            -size.X.Offset / 2,
            0.5,
            -size.Y.Offset / 2
        ),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, gui)

    Corner(main, 13)
    Stroke(main, Library.Theme.Stroke, 1)

    local topbar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0
    }, main)

    local line = New("Frame", {
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.new(0, 14, 1, -1),
        BackgroundColor3 = Library.Theme.StrokeSoft,
        BorderSizePixel = 0
    }, topbar)

    local logo = New("Frame", {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(0, 15, 0.5, -15),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0
    }, topbar)

    Corner(logo, 9)

    local logoText = Label(
        logo,
        string.sub(title, 1, 1):upper(),
        14,
        Library.Theme.White,
        FONT_BOLD
    )

    logoText.Size = UDim2.fromScale(1, 1)
    logoText.TextXAlignment = Enum.TextXAlignment.Center

    local titleLabel = Label(
        topbar,
        title,
        14,
        Library.Theme.Text,
        FONT_BOLD
    )

    titleLabel.Position = UDim2.new(0, 57, 0, 0)
    titleLabel.Size = UDim2.new(0, 320, 1, 0)

    local subtitle = Label(
        topbar,
        "Modern interface",
        10,
        Library.Theme.Muted,
        FONT
    )

    subtitle.Position = UDim2.new(0, 57, 0, 29)
    subtitle.Size = UDim2.new(0, 250, 0, 18)

    local close = New("TextButton", {
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, -48, 0.5, -17),
        BackgroundColor3 = Library.Theme.Surface2,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Library.Theme.SubText,
        TextSize = 18,
        Font = FONT_BOLD,
        AutoButtonColor = false
    }, topbar)

    Corner(close, 9)

    close.MouseEnter:Connect(function()
        Tween(close, {
            BackgroundColor3 = Color3.fromRGB(55, 29, 32),
            TextColor3 = Library.Theme.Red
        })
    end)

    close.MouseLeave:Connect(function()
        Tween(close, {
            BackgroundColor3 = Library.Theme.Surface2,
            TextColor3 = Library.Theme.SubText
        })
    end)

    close.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    local content = New("Frame", {
        Size = UDim2.new(1, 0, 1, -56),
        Position = UDim2.new(0, 0, 0, 56),
        BackgroundTransparency = 1
    }, main)

    local sidebar = New("Frame", {
        Size = UDim2.fromOffset(170, 1),
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0
    }, content)

    Padding(sidebar, 12, 14, 12, 14)

    local tabs = New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, sidebar)

    local tabLayout = New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabs)

    local body = New("Frame", {
        Size = UDim2.new(1, -170, 1, 0),
        Position = UDim2.new(0, 170, 0, 0),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0
    }, content)

    local window = {
        Instance = main,
        Gui = gui,
        Tabs = {},
        ActiveTab = nil,
        Body = body,
        TabContainer = tabs,
        TabLayout = tabLayout
    }

    setmetatable(window, {__index = WindowMethods})

    MakeDraggable(main, topbar)

    function window:SetTitle(value)
        titleLabel.Text = value
        logoText.Text = string.sub(value, 1, 1):upper()
    end

    function window:SetSize(value)
        main.Size = value
        main.Position = UDim2.new(
            0.5,
            -value.X.Offset / 2,
            0.5,
            -value.Y.Offset / 2
        )
    end

    return window
end

function WindowMethods:AddTab(name)
    local button = New("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 39),
        BackgroundColor3 = Library.Theme.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, self.TabContainer)

    Corner(button, 9)

    local indicator = New("Frame", {
        Size = UDim2.fromOffset(3, 18),
        Position = UDim2.new(0, 0, 0.5, -9),
        BackgroundColor3 = Library.Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, button)

    Corner(indicator, 3)

    local icon = Label(
        button,
        "◆",
        9,
        Library.Theme.Muted,
        FONT_BOLD
    )

    icon.Position = UDim2.new(0, 13, 0, 0)
    icon.Size = UDim2.fromOffset(15, 39)
    icon.TextXAlignment = Enum.TextXAlignment.Center

    local label = Label(
        button,
        name,
        12,
        Library.Theme.SubText,
        FONT_BOLD
    )

    label.Position = UDim2.new(0, 34, 0, 0)
    label.Size = UDim2.new(1, -40, 1, 0)

    local page = New("ScrollingFrame", {
        Name = name .. "_Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Library.Theme.Stroke,
        ScrollBarImageTransparency = 0.25,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, self.Body)

    Padding(page, 18, 16, 18, 18)

    local columns = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, page)

    local left = New("Frame", {
        Size = UDim2.new(0.5, -7, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, columns)

    local right = New("Frame", {
        Size = UDim2.new(0.5, -7, 0, 0),
        Position = UDim2.new(0.5, 7, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, columns)

    New("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, left)

    New("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, right)

    local tab = {
        Name = name,
        Button = button,
        Page = page,
        Left = left,
        Right = right,
        Window = self
    }

    setmetatable(tab, {__index = TabMethods})

    button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(button, {
                BackgroundColor3 = Library.Theme.Element,
                BackgroundTransparency = 0
            })

            Tween(label, {
                TextColor3 = Library.Theme.Text
            })
        end
    end)

    button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(button, {
                BackgroundTransparency = 1
            })

            Tween(label, {
                TextColor3 = Library.Theme.SubText
            })
        end
    end)

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)

    if not self.ActiveTab then
        self:SelectTab(tab)
    end

    return tab
end

function WindowMethods:SelectTab(tab)
    for _, other in ipairs(self.Tabs) do
        local active = other == tab

        other.Page.Visible = active

        Tween(other.Button, {
            BackgroundColor3 = active
                and Library.Theme.Element
                or Library.Theme.Surface,
            BackgroundTransparency = active and 0 or 1
        })

        local label = other.Button:FindFirstChildOfClass("TextLabel")
        if label then
            Tween(label, {
                TextColor3 = active
                    and Library.Theme.Text
                    or Library.Theme.SubText
            })
        end

        local indicator = other.Button:FindFirstChild("Frame")
        if indicator then
            Tween(indicator, {
                BackgroundTransparency = active and 0 or 1
            })
        end
    end

    self.ActiveTab = tab
end

function TabMethods:AddLeftGroupbox(name)
    return self:_CreateGroupbox(name, self.Left)
end

function TabMethods:AddRightGroupbox(name)
    return self:_CreateGroupbox(name, self.Right)
end

function TabMethods:_CreateGroupbox(name, parent)
    local box = New("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y
    }, parent)

    Corner(box, 11)
    Stroke(box, Library.Theme.StrokeSoft, 1)

    Padding(box, 14, 13, 14, 14)

    local title = Label(
        box,
        name,
        13,
        Library.Theme.Text,
        FONT_BOLD
    )

    title.Size = UDim2.new(1, 0, 0, 23)

    local line = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 31),
        BackgroundColor3 = Library.Theme.StrokeSoft,
        BorderSizePixel = 0
    }, box)

    local container = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, box)

    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, container)

    local groupbox = {
        Instance = box,
        Container = container,
        Layout = layout,
        Items = {}
    }

    setmetatable(groupbox, {__index = GroupboxMethods})

    return groupbox
end

function GroupboxMethods:AddLabel(text)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1
    }, self.Container)

    local label = Label(
        holder,
        text,
        11,
        Library.Theme.SubText,
        FONT
    )

    label.Size = UDim2.fromScale(1, 1)

    table.insert(self.Items, holder)
    return holder
end

function GroupboxMethods:AddDivider()
    local divider = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Library.Theme.StrokeSoft,
        BorderSizePixel = 0
    }, self.Container)

    table.insert(self.Items, divider)
    return divider
end

function GroupboxMethods:AddButton(text, callback)
    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Library.Theme.Text,
        TextSize = 12,
        Font = FONT_BOLD,
        AutoButtonColor = false
    }, self.Container)

    Corner(button, 9)
    Stroke(button, Library.Theme.Stroke, 1)

    button.MouseEnter:Connect(function()
        Tween(button, {
            BackgroundColor3 = Library.Theme.ElementHover
        })
    end)

    button.MouseLeave:Connect(function()
        Tween(button, {
            BackgroundColor3 = Library.Theme.Element
        })
    end)

    button.MouseButton1Down:Connect(function()
        Tween(button, {
            BackgroundColor3 = Library.Theme.AccentDark
        }, 0.08)
    end)

    button.MouseButton1Up:Connect(function()
        Tween(button, {
            BackgroundColor3 = Library.Theme.ElementHover
        }, 0.1)
    end)

    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    table.insert(self.Items, button)
    return button
end

function GroupboxMethods:AddToggle(flag, options)
    options = options or {}

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1
    }, self.Container)

    local label = Label(
        holder,
        options.Text or flag,
        12,
        Library.Theme.Text,
        FONT_BOLD
    )

    label.Size = UDim2.new(1, -58, 1, 0)

    local toggle = New("TextButton", {
        Size = UDim2.fromOffset(40, 22),
        Position = UDim2.new(1, -40, 0.5, -11),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, holder)

    Corner(toggle, 12)
    Stroke(toggle, Library.Theme.Stroke, 1)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Library.Theme.Muted,
        BorderSizePixel = 0
    }, toggle)

    Corner(knob, 9)

    local state = options.Default == true

    local function update(value, fire)
        state = value
        SetFlag(flag, value)

        if value then
            Tween(toggle, {
                BackgroundColor3 = Library.Theme.Accent
            })

            Tween(knob, {
                Position = UDim2.new(1, -19, 0.5, -8),
                BackgroundColor3 = Library.Theme.White
            })
        else
            Tween(toggle, {
                BackgroundColor3 = Library.Theme.Element
            })

            Tween(knob, {
                Position = UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Library.Theme.Muted
            })
        end

        if fire and options.Callback then
            options.Callback(value)
        end
    end

    toggle.MouseButton1Click:Connect(function()
        update(not state, true)
    end)

    update(state, false)

    local object = {
        Instance = holder,
        Toggle = toggle,

        SetValue = function(_, value)
            update(value == true, true)
        end,

        GetValue = function()
            return state
        end
    }

    table.insert(self.Items, object)
    return object
end

function GroupboxMethods:AddSlider(flag, options)
    options = options or {}

    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local rounding = options.Rounding or 0

    if max <= min then
        max = min + 1
    end

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 57),
        BackgroundTransparency = 1
    }, self.Container)

    local label = Label(
        holder,
        options.Text or flag,
        12,
        Library.Theme.Text,
        FONT_BOLD
    )

    label.Size = UDim2.new(1, -60, 0, 21)

    local valueLabel = Label(
        holder,
        tostring(default),
        11,
        Library.Theme.SubText,
        FONT_BOLD
    )

    valueLabel.Size = UDim2.fromOffset(55, 21)
    valueLabel.Position = UDim2.new(1, -55, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 37),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0
    }, holder)

    Corner(bar, 5)

    local fill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0
    }, bar)

    Corner(fill, 5)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(0, -7, 0.5, -7),
        BackgroundColor3 = Library.Theme.White,
        BorderSizePixel = 0
    }, bar)

    Corner(knob, 8)

    local value = default
    local dragging = false

    local function set(valueInput, fire)
        value = math.clamp(valueInput, min, max)

        if rounding > 0 then
            value = math.floor(value / rounding + 0.5) * rounding
        else
            value = math.floor(value + 0.5)
        end

        value = math.clamp(value, min, max)

        local percent = (value - min) / (max - min)

        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -7, 0.5, -7)
        valueLabel.Text = tostring(value)

        SetFlag(flag, value)

        if fire and options.Callback then
            options.Callback(value)
        end
    end

    local function fromInput(input)
        local width = bar.AbsoluteSize.X

        if width <= 0 then
            return
        end

        local percent = math.clamp(
            (input.Position.X - bar.AbsolutePosition.X) / width,
            0,
            1
        )

        set(min + (max - min) * percent, true)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            fromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    set(default, false)

    local object = {
        Instance = holder,

        SetValue = function(_, newValue)
            set(newValue, true)
        end,

        GetValue = function()
            return value
        end
    }

    table.insert(self.Items, object)
    return object
end

function GroupboxMethods:AddDropdown(flag, options)
    options = options or {}

    local values = options.Values or {}
    local current = options.Default or values[1]

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 57),
        BackgroundTransparency = 1
    }, self.Container)

    local label = Label(
        holder,
        options.Text or flag,
        12,
        Library.Theme.Text,
        FONT_BOLD
    )

    label.Size = UDim2.new(1, 0, 0, 21)

    local dropdown = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 31),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5
    }, holder)

    Corner(dropdown, 8)
    Stroke(dropdown, Library.Theme.Stroke, 1)

    local selected = Label(
        dropdown,
        tostring(current or ""),
        11,
        Library.Theme.SubText,
        FONT_BOLD
    )

    selected.Position = UDim2.new(0, 11, 0, 0)
    selected.Size = UDim2.new(1, -38, 1, 0)

    local arrow = Label(
        dropdown,
        "⌄",
        14,
        Library.Theme.Muted,
        FONT_BOLD
    )

    arrow.Position = UDim2.new(1, -27, 0, 0)
    arrow.Size = UDim2.fromOffset(20, 31)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local list = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 6),
        BackgroundColor3 = Library.Theme.Surface2,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 50
    }, dropdown)

    Corner(list, 8)
    Stroke(list, Library.Theme.Stroke, 1)
    Padding(list, 5, 5, 5, 5)

    local listLayout = New("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, list)

    local open = false

    local function rebuild()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for _, item in ipairs(values) do
            local option = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 29),
                BackgroundColor3 = Library.Theme.Surface2,
                BorderSizePixel = 0,
                Text = tostring(item),
                TextColor3 = Library.Theme.SubText,
                TextSize = 11,
                Font = FONT_BOLD,
                AutoButtonColor = false,
                ZIndex = 51
            }, list)

            Corner(option, 6)

            option.MouseEnter:Connect(function()
                Tween(option, {
                    BackgroundColor3 = Library.Theme.ElementHover,
                    TextColor3 = Library.Theme.Text
                })
            end)

            option.MouseLeave:Connect(function()
                Tween(option, {
                    BackgroundColor3 = Library.Theme.Surface2,
                    TextColor3 = Library.Theme.SubText
                })
            end)

            option.MouseButton1Click:Connect(function()
                current = item
                selected.Text = tostring(item)
                SetFlag(flag, current)

                if options.Callback then
                    options.Callback(current)
                end

                open = false
                list.Visible = false
                Tween(arrow, {Rotation = 0})
            end)
        end
    end

    rebuild()

    local function toggle()
        open = not open
        list.Visible = open

        if open then
            list.Size = UDim2.new(
                1,
                0,
                0,
                math.min(#values * 32 + 10, 170)
            )

            Tween(arrow, {Rotation = 180})
        else
            Tween(arrow, {Rotation = 0})
        end
    end

    dropdown.MouseButton1Click:Connect(toggle)

    SetFlag(flag, current)

    local object = {
        Instance = holder,

        SetValue = function(_, value)
            for _, item in ipairs(values) do
                if item == value then
                    current = value
                    selected.Text = tostring(value)
                    SetFlag(flag, value)

                    if options.Callback then
                        options.Callback(value)
                    end

                    return
                end
            end
        end,

        GetValue = function()
            return current
        end,

        Refresh = function(_, newValues)
            values = newValues or {}
            rebuild()

            if not table.find(values, current) then
                current = values[1]
                selected.Text = tostring(current or "")
                SetFlag(flag, current)
            end
        end
    }

    table.insert(self.Items, object)
    return object
end

function GroupboxMethods:AddInput(flag, options)
    options = options or {}

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 57),
        BackgroundTransparency = 1
    }, self.Container)

    local label = Label(
        holder,
        options.Text or flag,
        12,
        Library.Theme.Text,
        FONT_BOLD
    )

    label.Size = UDim2.new(1, 0, 0, 21)

    local input = New("TextBox", {
        Size = UDim2.new(1, 0, 0, 31),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = options.Default or "",
        PlaceholderText = options.Placeholder or "",
        PlaceholderColor3 = Library.Theme.Muted,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Font = FONT_BOLD,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, holder)

    Corner(input, 8)
    Stroke(input, Library.Theme.Stroke, 1)
    Padding(input, 11, 0, 11, 0)

    input.Focused:Connect(function()
        Tween(input, {
            BackgroundColor3 = Library.Theme.ElementHover
        })
    end)

    input.FocusLost:Connect(function()
        Tween(input, {
            BackgroundColor3 = Library.Theme.Element
        })

        SetFlag(flag, input.Text)

        if options.Callback then
            options.Callback(input.Text)
        end
    end)

    SetFlag(flag, input.Text)

    local object = {
        Instance = holder,

        SetValue = function(_, value)
            input.Text = tostring(value)
            SetFlag(flag, value)
        end,

        GetValue = function()
            return input.Text
        end
    }

    table.insert(self.Items, object)
    return object
end

function GroupboxMethods:AddParagraph(title, text)
    text = tostring(text or "")

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y
    }, self.Container)

    Corner(holder, 9)
    Stroke(holder, Library.Theme.StrokeSoft, 1)
    Padding(holder, 11, 9, 11, 10)

    local titleLabel = Label(
        holder,
        title,
        11,
        Library.Theme.Text,
        FONT_BOLD
    )

    titleLabel.Size = UDim2.new(1, 0, 0, 18)

    local body = Label(
        holder,
        text,
        10,
        Library.Theme.SubText,
        FONT
    )

    body.Position = UDim2.new(0, 0, 0, 23)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top

    table.insert(self.Items, holder)
    return holder
end

function GroupboxMethods:AddColorPicker(flag, options)
    options = options or {}

    local color = options.Default or Library.Theme.Accent

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1
    }, self.Container)

    local label = Label(
        holder,
        options.Text or flag,
        12,
        Library.Theme.Text,
        FONT_BOLD
    )

    label.Size = UDim2.new(1, -48, 1, 0)

    local picker = New("TextButton", {
        Size = UDim2.fromOffset(34, 22),
        Position = UDim2.new(1, -34, 0.5, -11),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, holder)

    Corner(picker, 7)
    Stroke(picker, Library.Theme.Stroke, 1)

    picker.MouseEnter:Connect(function()
        Tween(picker, {
            Size = UDim2.fromOffset(37, 24),
            Position = UDim2.new(1, -37, 0.5, -12)
        })
    end)

    picker.MouseLeave:Connect(function()
        Tween(picker, {
            Size = UDim2.fromOffset(34, 22),
            Position = UDim2.new(1, -34, 0.5, -11)
        })
    end)

    picker.MouseButton1Click:Connect(function()
        if options.Callback then
            options.Callback(color)
        end
    end)

    SetFlag(flag, color)

    local object = {
        Instance = holder,

        SetValue = function(_, value)
            color = value
            picker.BackgroundColor3 = value
            SetFlag(flag, value)

            if options.Callback then
                options.Callback(value)
            end
        end,

        GetValue = function()
            return color
        end
    }

    table.insert(self.Items, object)
    return object
end

function Library:Notify(options)
    options = options or {}

    local gui = PlayerGui:FindFirstChild("UILibraryNotifications")

    if not gui then
        gui = New("ScreenGui", {
            Name = "UILibraryNotifications",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        }, PlayerGui)
    end

    local holder = New("Frame", {
        Size = UDim2.fromOffset(320, 78),
        Position = UDim2.new(1, 25, 1, -100),
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0
    }, gui)

    Corner(holder, 11)
    Stroke(holder, Library.Theme.Stroke, 1)

    local accent = New("Frame", {
        Size = UDim2.fromOffset(3, 46),
        Position = UDim2.new(0, 0, 0.5, -23),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0
    }, holder)

    Corner(accent, 2)

    local title = Label(
        holder,
        options.Title or "Notification",
        12,
        Library.Theme.Text,
        FONT_BOLD
    )

    title.Position = UDim2.new(0, 15, 0, 10)
    title.Size = UDim2.new(1, -30, 0, 20)

    local text = Label(
        holder,
        options.Description or "",
        10,
        Library.Theme.SubText,
        FONT
    )

    text.Position = UDim2.new(0, 15, 0, 32)
    text.Size = UDim2.new(1, -30, 0, 34)
    text.TextWrapped = true
    text.TextYAlignment = Enum.TextYAlignment.Top

    Tween(holder, {
        Position = UDim2.new(1, -345, 1, -100)
    })

    task.delay(options.Duration or 4, function()
        if holder and holder.Parent then
            Tween(holder, {
                Position = UDim2.new(1, 25, 1, -100)
            }, 0.2)

            task.wait(0.25)

            if holder and holder.Parent then
                holder:Destroy()
            end
        end
    end)

    return holder
end

function Library:SetAccent(color)
    Library.Theme.Accent = color
end

function Library:GetFlag(flag)
    return Library.Flags[flag]
end

function Library:SetFlag(flag, value)
    Library.Flags[flag] = value
end

function Library:Unload()
    local gui = PlayerGui:FindFirstChild("UILibrary")

    if gui then
        gui:Destroy()
    end

    local notifications = PlayerGui:FindFirstChild("UILibraryNotifications")

    if notifications then
        notifications:Destroy()
    end

    Library.Flags = {}
    Library.Items = {}
end

return Library
