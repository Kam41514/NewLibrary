local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {
    Flags = {},
    Items = {},
    Theme = {
        Background = Color3.fromRGB(8, 8, 8),
        Surface = Color3.fromRGB(11, 11, 11),
        Element = Color3.fromRGB(15, 15, 15),
        Stroke = Color3.fromRGB(18, 18, 18),
        Text = Color3.fromRGB(235, 235, 235),
        SubText = Color3.fromRGB(145, 145, 145),
        Muted = Color3.fromRGB(90, 90, 90),
        Accent = Color3.fromRGB(125, 105, 255),
        AccentDark = Color3.fromRGB(75, 62, 155),
        White = Color3.fromRGB(255, 255, 255)
    }
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamSemibold

local function New(class, properties, parent)
    local object = Instance.new(class)

    for property, value in pairs(properties or {}) do
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
    TweenService:Create(
        object,
        TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    ):Play()
end

local function MakeDraggable(frame, handle)
    local dragging = false
    local dragStart
    local startPosition

    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
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

local function CreateLabel(parent, text, size, color, font)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Library.Theme.Text,
        TextSize = size or 13,
        Font = font or FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.None
    }, parent)
end

local function SetFlag(name, value)
    Library.Flags[name] = value
end

local WindowMethods = {}
local TabMethods = {}
local GroupboxMethods = {}

function Library:CreateWindow(options)
    options = options or {}

    local title = options.Title or "Library"
    local size = options.Size or UDim2.fromOffset(680, 520)

    local gui = New("ScreenGui", {
        Name = "UILibrary",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, PlayerGui)

    local main = New("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, gui)

    Corner(main, 10)
    Stroke(main, Library.Theme.Stroke, 1)

    local topbar = New("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0
    }, main)

    local topLine = New("Frame", {
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.new(0, 14, 1, -1),
        BackgroundColor3 = Library.Theme.Stroke,
        BorderSizePixel = 0
    }, topbar)

    local logo = New("Frame", {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.new(0, 12, 0.5, -13),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0
    }, topbar)

    Corner(logo, 8)

    local logoText = CreateLabel(
        logo,
        string.sub(title, 1, 1):upper(),
        13,
        Library.Theme.White,
        FONT_BOLD
    )

    logoText.Size = UDim2.fromScale(1, 1)
    logoText.TextXAlignment = Enum.TextXAlignment.Center

    local titleLabel = CreateLabel(
        topbar,
        title,
        14,
        Library.Theme.Text,
        FONT_BOLD
    )

    titleLabel.Position = UDim2.new(0, 48, 0, 0)
    titleLabel.Size = UDim2.new(0, 300, 1, 0)

    local close = New("TextButton", {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -40, 0.5, -15),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Library.Theme.SubText,
        TextSize = 20,
        Font = FONT_BOLD,
        AutoButtonColor = false
    }, topbar)

    close.MouseEnter:Connect(function()
        Tween(close, {TextColor3 = Color3.fromRGB(255, 100, 100)})
    end)

    close.MouseLeave:Connect(function()
        Tween(close, {TextColor3 = Library.Theme.SubText})
    end)

    close.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    local content = New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -46),
        Position = UDim2.new(0, 0, 0, 46),
        BackgroundTransparency = 1
    }, main)

    local sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.fromOffset(150, 1),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0
    }, content)

    Padding(sidebar, 10, 12, 10, 12)

    local tabs = New("ScrollingFrame", {
        Name = "Tabs",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, sidebar)

    local tabLayout = New("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabs)

    local body = New("Frame", {
        Name = "Body",
        Size = UDim2.new(1, -150, 1, 0),
        Position = UDim2.new(0, 150, 0, 0),
        BackgroundTransparency = 1
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
    end

    return window
end

function WindowMethods:AddTab(name)
    local tabButton = New("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Library.Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, self.TabContainer)

    Corner(tabButton, 8)

    local indicator = New("Frame", {
        Size = UDim2.fromOffset(3, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = Library.Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, tabButton)

    Corner(indicator, 3)

    local label = CreateLabel(
        tabButton,
        name,
        12,
        Library.Theme.SubText,
        FONT
    )

    label.Position = UDim2.new(0, 14, 0, 0)
    label.Size = UDim2.new(1, -14, 1, 0)

    local page = New("ScrollingFrame", {
        Name = name .. "_Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.Theme.Stroke,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, self.Body)

    Padding(page, 14, 12, 14, 14)

    local columns = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, page)

    local left = New("Frame", {
        Name = "Left",
        Size = UDim2.new(0.5, -7, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, columns)

    local right = New("Frame", {
        Name = "Right",
        Size = UDim2.new(0.5, -7, 0, 0),
        Position = UDim2.new(0.5, 7, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, columns)

    local leftLayout = New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, left)

    local rightLayout = New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, right)

    local tab = {
        Name = name,
        Button = tabButton,
        Page = page,
        Left = left,
        Right = right,
        Window = self
    }

    setmetatable(tab, {__index = TabMethods})

    tabButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(tabButton, {
                BackgroundColor3 = Library.Theme.Element,
                BackgroundTransparency = 0
            })
        end
    end)

    tabButton.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(tabButton, {
                BackgroundTransparency = 1
            })
        end
    end)

    tabButton.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)

    if not self.ActiveTab then
        self:SelectTab(tab)
    end

    return tab
end

function WindowMethods:SelectTab(tab)
    if self.ActiveTab == tab then
        return
    end

    for _, other in ipairs(self.Tabs) do
        local active = other == tab

        other.Page.Visible = active

        Tween(other.Button, {
            BackgroundColor3 = active and Library.Theme.Element or Library.Theme.Background,
            BackgroundTransparency = active and 0 or 1
        })

        Tween(other.Button:FindFirstChildOfClass("TextLabel"), {
            TextColor3 = active and Library.Theme.Text or Library.Theme.SubText
        })

        Tween(other.Button:FindFirstChildOfClass("Frame"), {
            BackgroundTransparency = active and 0 or 1
        })
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

    Corner(box, 9)
    Stroke(box, Library.Theme.Stroke, 1)

    Padding(box, 10, 9, 10, 10)

    local title = CreateLabel(
        box,
        name,
        12,
        Library.Theme.Text,
        FONT_BOLD
    )

    title.Size = UDim2.new(1, 0, 0, 22)

    local container = New("Frame", {
        Name = "Container",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 27),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, box)

    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 7),
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
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        text,
        12,
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
        BackgroundColor3 = Library.Theme.Stroke,
        BorderSizePixel = 0
    }, self.Container)

    table.insert(self.Items, divider)

    return divider
end

function GroupboxMethods:AddButton(text, callback)
    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Library.Theme.Text,
        TextSize = 12,
        Font = FONT_BOLD,
        AutoButtonColor = false
    }, self.Container)

    Corner(button, 8)
    Stroke(button, Library.Theme.Stroke, 1)

    button.MouseEnter:Connect(function()
        Tween(button, {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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
            BackgroundColor3 = Library.Theme.Element
        }, 0.12)
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
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        options.Text or flag,
        12,
        Library.Theme.Text,
        FONT
    )

    label.Size = UDim2.new(1, -50, 1, 0)

    local toggle = New("TextButton", {
        Size = UDim2.fromOffset(34, 19),
        Position = UDim2.new(1, -34, 0.5, -9),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, holder)

    Corner(toggle, 10)
    Stroke(toggle, Library.Theme.Stroke, 1)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(13, 13),
        Position = UDim2.new(0, 3, 0.5, -6),
        BackgroundColor3 = Library.Theme.Muted,
        BorderSizePixel = 0
    }, toggle)

    Corner(knob, 7)

    local state = options.Default == true

    local function update(value, fire)
        state = value
        SetFlag(flag, value)

        if value then
            Tween(toggle, {
                BackgroundColor3 = Library.Theme.Accent
            })

            Tween(knob, {
                Position = UDim2.new(1, -16, 0.5, -6),
                BackgroundColor3 = Library.Theme.White
            })
        else
            Tween(toggle, {
                BackgroundColor3 = Library.Theme.Element
            })

            Tween(knob, {
                Position = UDim2.new(0, 3, 0.5, -6),
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
            update(value, true)
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

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        options.Text or flag,
        12,
        Library.Theme.Text,
        FONT
    )

    label.Size = UDim2.new(1, -55, 0, 20)

    local valueLabel = CreateLabel(
        holder,
        tostring(default),
        11,
        Library.Theme.SubText,
        FONT
    )

    valueLabel.Size = UDim2.fromOffset(50, 20)
    valueLabel.Position = UDim2.new(1, -50, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 5),
        Position = UDim2.new(0, 0, 0, 34),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0
    }, holder)

    Corner(bar, 4)
    Stroke(bar, Library.Theme.Stroke, 1)

    local fill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0
    }, bar)

    Corner(fill, 4)

    local dragging = false
    local value = default

    local function set(valueInput, fire)
        value = math.clamp(valueInput, min, max)

        if rounding > 0 then
            value = math.floor(value / rounding + 0.5) * rounding
        else
            value = math.floor(value + 0.5)
        end

        local percent = (value - min) / (max - min)

        fill.Size = UDim2.new(percent, 0, 1, 0)
        valueLabel.Text = tostring(value)
        SetFlag(flag, value)

        if fire and options.Callback then
            options.Callback(value)
        end
    end

    local function fromInput(input)
        local percent = math.clamp(
            (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
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
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        options.Text or flag,
        12,
        Library.Theme.Text,
        FONT
    )

    label.Size = UDim2.new(1, 0, 0, 20)

    local dropdown = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 23),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, holder)

    Corner(dropdown, 7)
    Stroke(dropdown, Library.Theme.Stroke, 1)

    local selected = CreateLabel(
        dropdown,
        tostring(current or ""),
        11,
        Library.Theme.SubText,
        FONT
    )

    selected.Position = UDim2.new(0, 9, 0, 0)
    selected.Size = UDim2.new(1, -28, 1, 0)

    local arrow = CreateLabel(
        dropdown,
        "⌄",
        13,
        Library.Theme.Muted,
        FONT_BOLD
    )

    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.Size = UDim2.fromOffset(18, 28)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local list = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 5),
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20
    }, dropdown)

    Corner(list, 7)
    Stroke(list, Library.Theme.Stroke, 1)

    local listLayout = New("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, list)

    Padding(list, 5, 5, 5, 5)

    local open = false

    for _, item in ipairs(values) do
        local option = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 27),
            BackgroundColor3 = Library.Theme.Surface,
            BorderSizePixel = 0,
            Text = tostring(item),
            TextColor3 = Library.Theme.SubText,
            TextSize = 11,
            Font = FONT,
            AutoButtonColor = false,
            ZIndex = 21
        }, list)

        Corner(option, 5)

        option.MouseEnter:Connect(function()
            Tween(option, {
                BackgroundColor3 = Library.Theme.Element,
                TextColor3 = Library.Theme.Text
            })
        end)

        option.MouseLeave:Connect(function()
            Tween(option, {
                BackgroundColor3 = Library.Theme.Surface,
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
        end)
    end

    local function toggle()
        open = not open
        list.Visible = open

        if open then
            local count = #values
            list.Size = UDim2.new(1, 0, 0, math.min(count * 29 + 10, 150))
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
            values = newValues
        end
    }

    table.insert(self.Items, object)

    return object
end

function GroupboxMethods:AddInput(flag, options)
    options = options or {}

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        options.Text or flag,
        12,
        Library.Theme.Text,
        FONT
    )

    label.Size = UDim2.new(1, 0, 0, 20)

    local input = New("TextBox", {
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 23),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = options.Default or "",
        PlaceholderText = options.Placeholder or "",
        PlaceholderColor3 = Library.Theme.Muted,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Font = FONT,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    Corner(input, 7)
    Stroke(input, Library.Theme.Stroke, 1)
    Padding(input, 9, 0, 9, 0)

    input.FocusLost:Connect(function()
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
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0
    }, self.Container)

    Corner(holder, 7)
    Stroke(holder, Library.Theme.Stroke, 1)

    local titleLabel = CreateLabel(
        holder,
        title,
        11,
        Library.Theme.Text,
        FONT_BOLD
    )

    titleLabel.Position = UDim2.new(0, 9, 0, 5)
    titleLabel.Size = UDim2.new(1, -18, 0, 18)

    local body = CreateLabel(
        holder,
        text,
        10,
        Library.Theme.SubText,
        FONT
    )

    body.Position = UDim2.new(0, 9, 0, 24)
    body.Size = UDim2.new(1, -18, 0, 28)
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top

    table.insert(self.Items, holder)

    return holder
end

function GroupboxMethods:AddColorPicker(flag, options)
    options = options or {}

    local color = options.Default or Color3.fromRGB(125, 105, 255)

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        options.Text or flag,
        12,
        Library.Theme.Text,
        FONT
    )

    label.Size = UDim2.new(1, -42, 1, 0)

    local picker = New("TextButton", {
        Size = UDim2.fromOffset(30, 20),
        Position = UDim2.new(1, -30, 0.5, -10),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, holder)

    Corner(picker, 6)
    Stroke(picker, Library.Theme.Stroke, 1)

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
        Size = UDim2.fromOffset(280, 70),
        Position = UDim2.new(1, -300, 1, -90),
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0
    }, gui)

    Corner(holder, 9)
    Stroke(holder, Library.Theme.Stroke, 1)

    local title = CreateLabel(
        holder,
        options.Title or "Notification",
        12,
        Library.Theme.Text,
        FONT_BOLD
    )

    title.Position = UDim2.new(0, 12, 0, 9)
    title.Size = UDim2.new(1, -24, 0, 20)

    local text = CreateLabel(
        holder,
        options.Description or "",
        10,
        Library.Theme.SubText,
        FONT
    )

    text.Position = UDim2.new(0, 12, 0, 29)
    text.Size = UDim2.new(1, -24, 0, 32)
    text.TextWrapped = true

    holder.Position = UDim2.new(1, 20, 1, -90)

    Tween(holder, {
        Position = UDim2.new(1, -300, 1, -90)
    })

    task.delay(options.Duration or 4, function()
        if holder and holder.Parent then
            Tween(holder, {
                Position = UDim2.new(1, 20, 1, -90)
            })

            task.wait(0.2)

            if holder then
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
