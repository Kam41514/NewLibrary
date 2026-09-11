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
        Surface2 = Color3.fromRGB(17, 20, 25),
        Element = Color3.fromRGB(21, 24, 30),
        ElementHover = Color3.fromRGB(27, 30, 38),

        Stroke = Color3.fromRGB(36, 40, 49),
        StrokeSoft = Color3.fromRGB(27, 30, 37),

        Text = Color3.fromRGB(245, 246, 249),
        SubText = Color3.fromRGB(168, 173, 184),
        Muted = Color3.fromRGB(105, 111, 124),

        Accent = Color3.fromRGB(105, 96, 255),
        AccentHover = Color3.fromRGB(120, 111, 255),
        AccentDark = Color3.fromRGB(76, 69, 180),

        White = Color3.fromRGB(255, 255, 255),
        Red = Color3.fromRGB(239, 91, 96)
    }
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

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
    if not object or not object.Parent then
        return
    end

    TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.16,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        properties
    ):Play()
end

local function CreateLabel(parent, text, size, color, font)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Library.Theme.Text,
        TextSize = size or 12,
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

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------

function Library:CreateWindow(options)
    options = options or {}

    local title = options.Title or "Library"
    local size = options.Size or UDim2.fromOffset(820, 555)

    local gui = New("ScreenGui", {
        Name = "UILibrary",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, PlayerGui)

    local dropdownGui = New("ScreenGui", {
        Name = "UILibraryDropdowns",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 999999
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

    ------------------------------------------------------------
    -- TOPBAR
    ------------------------------------------------------------

    local topbar = New("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0
    }, main)

    local topLine = New("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 1, -1),
        BackgroundColor3 = Library.Theme.StrokeSoft,
        BorderSizePixel = 0
    }, topbar)

    local logo = New("Frame", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(0, 12, 0.5, -12),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0
    }, topbar)

    Corner(logo, 7)

    local logoText = CreateLabel(
        logo,
        string.sub(title, 1, 1):upper(),
        11,
        Library.Theme.White,
        FONT_BOLD
    )

    logoText.Size = UDim2.fromScale(1, 1)
    logoText.TextXAlignment = Enum.TextXAlignment.Center

    local titleLabel = CreateLabel(
        topbar,
        title,
        13,
        Library.Theme.Text,
        FONT_BOLD
    )

    titleLabel.Position = UDim2.new(0, 45, 0, 0)
    titleLabel.Size = UDim2.new(0, 280, 1, 0)

    local close = New("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -38, 0.5, -14),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Library.Theme.Muted,
        TextSize = 17,
        Font = FONT_BOLD,
        AutoButtonColor = false
    }, topbar)

    close.MouseEnter:Connect(function()
        Tween(close, {
            TextColor3 = Library.Theme.Red
        })
    end)

    close.MouseLeave:Connect(function()
        Tween(close, {
            TextColor3 = Library.Theme.Muted
        })
    end)

    close.MouseButton1Click:Connect(function()
        gui:Destroy()
        dropdownGui:Destroy()
    end)

    ------------------------------------------------------------
    -- CONTENT
    ------------------------------------------------------------

    local content = New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -42),
        Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1
    }, main)

    ------------------------------------------------------------
    -- SIDEBAR
    ------------------------------------------------------------

    local sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.fromOffset(158, 1),
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0
    }, content)

    Padding(sidebar, 9, 10, 9, 10)

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

    ------------------------------------------------------------
    -- BODY
    ------------------------------------------------------------

    local body = New("Frame", {
        Name = "Body",
        Size = UDim2.new(1, -158, 1, 0),
        Position = UDim2.new(0, 158, 0, 0),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0
    }, content)

    local window = {
        Instance = main,
        Gui = gui,
        DropdownGui = dropdownGui,
        Tabs = {},
        ActiveTab = nil,
        Body = body,
        TabContainer = tabs,
        TabLayout = tabLayout
    }

    setmetatable(window, {
        __index = WindowMethods
    })

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

----------------------------------------------------------------
-- TAB
----------------------------------------------------------------

function WindowMethods:AddTab(name)
    local tabButton = New("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Library.Theme.Surface,
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

    local icon = CreateLabel(
        tabButton,
        "◆",
        7,
        Library.Theme.Muted,
        FONT_BOLD
    )

    icon.Position = UDim2.new(0, 11, 0, 0)
    icon.Size = UDim2.fromOffset(14, 34)
    icon.TextXAlignment = Enum.TextXAlignment.Center

    local label = CreateLabel(
        tabButton,
        name,
        11,
        Library.Theme.SubText,
        FONT_BOLD
    )

    label.Position = UDim2.new(0, 31, 0, 0)
    label.Size = UDim2.new(1, -36, 1, 0)

    ------------------------------------------------------------
    -- PAGE
    ------------------------------------------------------------

    local page = New("ScrollingFrame", {
        Name = name .. "_Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Library.Theme.Stroke,
        ScrollBarImageTransparency = 0.15,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, self.Body)

    Padding(page, 15, 13, 15, 16)

    local columns = New("Frame", {
        Name = "Columns",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, page)

    local left = New("Frame", {
        Name = "Left",
        Size = UDim2.new(0.5, -6, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, columns)

    local right = New("Frame", {
        Name = "Right",
        Size = UDim2.new(0.5, -6, 0, 0),
        Position = UDim2.new(0.5, 6, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, columns)

    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, left)

    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, right)

    local tab = {
        Name = name,
        Button = tabButton,
        Page = page,
        Columns = columns,
        Left = left,
        Right = right,
        Window = self
    }

    setmetatable(tab, {
        __index = TabMethods
    })

    tabButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(tabButton, {
                BackgroundColor3 = Library.Theme.Element,
                BackgroundTransparency = 0
            })

            Tween(label, {
                TextColor3 = Library.Theme.Text
            })
        end
    end)

    tabButton.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(tabButton, {
                BackgroundTransparency = 1
            })

            Tween(label, {
                TextColor3 = Library.Theme.SubText
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
    for _, other in ipairs(self.Tabs) do
        local active = other == tab

        other.Page.Visible = active

        Tween(other.Button, {
            BackgroundColor3 = active
                and Library.Theme.Element
                or Library.Theme.Surface,
            BackgroundTransparency = active and 0 or 1
        })

        local text = other.Button:FindFirstChildWhichIsA("TextLabel")
        if text then
            Tween(text, {
                TextColor3 = active
                    and Library.Theme.Text
                    or Library.Theme.SubText
            })
        end

        local indicator = other.Button:FindFirstChildWhichIsA("Frame")
        if indicator then
            Tween(indicator, {
                BackgroundTransparency = active and 0 or 1
            })
        end
    end

    self.ActiveTab = tab
end

----------------------------------------------------------------
-- GROUPBOX
----------------------------------------------------------------

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

    Corner(box, 10)
    Stroke(box, Library.Theme.StrokeSoft, 1)
    Padding(box, 12, 10, 12, 12)

    local title = CreateLabel(
        box,
        name,
        12,
        Library.Theme.Text,
        FONT_BOLD
    )

    title.Size = UDim2.new(1, 0, 0, 20)

    local divider = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 27),
        BackgroundColor3 = Library.Theme.StrokeSoft,
        BorderSizePixel = 0
    }, box)

    local container = New("Frame", {
        Name = "Container",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 37),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    }, box)

    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, container)

    local groupbox = {
        Instance = box,
        Container = container,
        Layout = layout,
        Items = {}
    }

    setmetatable(groupbox, {
        __index = GroupboxMethods
    })

    return groupbox
end

----------------------------------------------------------------
-- LABEL
----------------------------------------------------------------

function GroupboxMethods:AddLabel(text)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
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

----------------------------------------------------------------
-- DIVIDER
----------------------------------------------------------------

function GroupboxMethods:AddDivider()
    local divider = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Library.Theme.StrokeSoft,
        BorderSizePixel = 0
    }, self.Container)

    table.insert(self.Items, divider)

    return divider
end

----------------------------------------------------------------
-- BUTTON
----------------------------------------------------------------

function GroupboxMethods:AddButton(text, callback)
    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Font = FONT_BOLD,
        AutoButtonColor = false
    }, self.Container)

    Corner(button, 8)
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
        }, 0.08)
    end)

    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    table.insert(self.Items, button)

    return button
end

----------------------------------------------------------------
-- TOGGLE
----------------------------------------------------------------

function GroupboxMethods:AddToggle(flag, options)
    options = options or {}

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        options.Text or flag,
        11,
        Library.Theme.Text,
        FONT_BOLD
    )

    label.Size = UDim2.new(1, -52, 1, 0)

    local toggle = New("TextButton", {
        Size = UDim2.fromOffset(38, 21),
        Position = UDim2.new(1, -38, 0.5, -10),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, holder)

    Corner(toggle, 12)
    Stroke(toggle, Library.Theme.Stroke, 1)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(15, 15),
        Position = UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = Library.Theme.Muted,
        BorderSizePixel = 0
    }, toggle)

    Corner(knob, 8)

    local state = options.Default == true

    local function update(value, fire)
        state = value
        SetFlag(flag, value)

        if value then
            Tween(toggle, {
                BackgroundColor3 = Library.Theme.Accent
            })

            Tween(knob, {
                Position = UDim2.new(1, -18, 0.5, -7),
                BackgroundColor3 = Library.Theme.White
            })
        else
            Tween(toggle, {
                BackgroundColor3 = Library.Theme.Element
            })

            Tween(knob, {
                Position = UDim2.new(0, 3, 0.5, -7),
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

----------------------------------------------------------------
-- SLIDER
----------------------------------------------------------------

function GroupboxMethods:AddSlider(flag, options)
    options = options or {}

    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default
    local rounding = options.Rounding or 0

    if default == nil then
        default = min
    end

    if max <= min then
        max = min + 1
    end

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 55),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        options.Text or flag,
        11,
        Library.Theme.Text,
        FONT_BOLD
    )

    label.Size = UDim2.new(1, -55, 0, 20)

    local valueLabel = CreateLabel(
        holder,
        tostring(default),
        10,
        Library.Theme.SubText,
        FONT_BOLD
    )

    valueLabel.Size = UDim2.fromOffset(55, 20)
    valueLabel.Position = UDim2.new(1, -55, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 5),
        Position = UDim2.new(0, 0, 0, 34),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0
    }, holder)

    Corner(bar, 4)

    local fill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0
    }, bar)

    Corner(fill, 4)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(13, 13),
        Position = UDim2.new(0, -6, 0.5, -6),
        BackgroundColor3 = Library.Theme.White,
        BorderSizePixel = 0
    }, bar)

    Corner(knob, 7)

    local dragging = false
    local value = default

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
        knob.Position = UDim2.new(percent, -6, 0.5, -6)
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

        set(
            min + (max - min) * percent,
            true
        )
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

----------------------------------------------------------------
-- DROPDOWN
-- Completely separate overlay.
-- Does NOT change groupbox height.
-- Does NOT get clipped by scrolling frames.
-- Does NOT overlap other modules incorrectly.
----------------------------------------------------------------

function GroupboxMethods:AddDropdown(flag, options)
    options = options or {}

    local values = options.Values or {}
    local current = options.Default

    if current == nil then
        current = values[1]
    end

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 55),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        options.Text or flag,
        11,
        Library.Theme.Text,
        FONT_BOLD
    )

    label.Size = UDim2.new(1, 0, 0, 20)

    local dropdown = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5
    }, holder)

    Corner(dropdown, 8)
    Stroke(dropdown, Library.Theme.Stroke, 1)

    local selected = CreateLabel(
        dropdown,
        tostring(current or ""),
        10,
        Library.Theme.SubText,
        FONT_BOLD
    )

    selected.Position = UDim2.new(0, 10, 0, 0)
    selected.Size = UDim2.new(1, -38, 1, 0)

    local arrow = CreateLabel(
        dropdown,
        "⌄",
        13,
        Library.Theme.Muted,
        FONT_BOLD
    )

    arrow.Position = UDim2.new(1, -28, 0, 0)
    arrow.Size = UDim2.fromOffset(20, 30)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local open = false
    local menu
    local menuConnection

    local function closeMenu()
        if not open then
            return
        end

        open = false

        if menuConnection then
            menuConnection:Disconnect()
            menuConnection = nil
        end

        if menu and menu.Parent then
            Tween(menu, {
                BackgroundTransparency = 1
            }, 0.08)

            task.delay(0.09, function()
                if menu and menu.Parent then
                    menu:Destroy()
                end
            end)
        end

        Tween(arrow, {
            Rotation = 0
        })
    end

    local function rebuildMenu()
        if menu and menu.Parent then
            menu:Destroy()
        end

        local count = #values

        if count == 0 then
            return
        end

        local rowHeight = 29
        local maxRows = 6
        local visibleRows = math.min(count, maxRows)

        local menuHeight =
            (visibleRows * rowHeight)
            + ((visibleRows - 1) * 4)
            + 10

        local absolutePosition = dropdown.AbsolutePosition
        local absoluteSize = dropdown.AbsoluteSize

        local viewportHeight = workspace.CurrentCamera
            and workspace.CurrentCamera.ViewportSize.Y
            or 600

        local spaceBelow =
            viewportHeight
            - (absolutePosition.Y + absoluteSize.Y)
            - 8

        local spaceAbove =
            absolutePosition.Y
            - 8

        local openBelow = spaceBelow >= math.min(menuHeight, spaceBelow)
            or spaceBelow >= spaceAbove

        local finalHeight = math.min(
            menuHeight,
            math.max(45, math.max(spaceBelow, spaceAbove))
        )

        local menuY

        if openBelow then
            menuY = absolutePosition.Y + absoluteSize.Y + 5
        else
            menuY = absolutePosition.Y - finalHeight - 5
        end

        menu = New("Frame", {
            Name = "DropdownMenu",
            Size = UDim2.fromOffset(
                absoluteSize.X,
                finalHeight
            ),
            Position = UDim2.fromOffset(
                absolutePosition.X,
                menuY
            ),
            BackgroundColor3 = Library.Theme.Surface2,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 1000,
            Active = true
        }, self.Container.Parent.Parent.Parent.Parent.Parent.Parent.DropdownGui)

        Corner(menu, 9)
        Stroke(menu, Library.Theme.Stroke, 1)

        Padding(menu, 5, 5, 5, 5)

        local scrolling = New("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = count > maxRows and 3 or 0,
            ScrollBarImageColor3 = Library.Theme.Stroke,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 1001
        }, menu)

        local list = New("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, scrolling)

        for index, item in ipairs(values) do
            local option = New("TextButton", {
                Name = "Option_" .. index,
                Size = UDim2.new(1, -2, 0, rowHeight),
                BackgroundColor3 = Library.Theme.Surface2,
                BorderSizePixel = 0,
                Text = tostring(item),
                TextColor3 = item == current
                    and Library.Theme.Text
                    or Library.Theme.SubText,
                TextSize = 10,
                Font = FONT_BOLD,
                AutoButtonColor = false,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 1002
            }, scrolling)

            Corner(option, 6)

            option.MouseEnter:Connect(function()
                Tween(option, {
                    BackgroundColor3 = Library.Theme.ElementHover,
                    TextColor3 = Library.Theme.Text
                }, 0.1)
            end)

            option.MouseLeave:Connect(function()
                Tween(option, {
                    BackgroundColor3 = Library.Theme.Surface2,
                    TextColor3 = item == current
                        and Library.Theme.Text
                        or Library.Theme.SubText
                }, 0.1)
            end)

            option.MouseButton1Click:Connect(function()
                current = item
                selected.Text = tostring(item)

                SetFlag(flag, current)

                if options.Callback then
                    options.Callback(current)
                end

                closeMenu()
            end)
        end

        Tween(menu, {
            BackgroundTransparency = 0
        }, 0.12)
    end

    local function openMenu()
        if open then
            closeMenu()
            return
        end

        open = true

        Tween(arrow, {
            Rotation = 180
        })

        task.defer(function()
            if open then
                rebuildMenu()
            end
        end)
    end

    dropdown.MouseEnter:Connect(function()
        Tween(dropdown, {
            BackgroundColor3 = Library.Theme.ElementHover
        })
    end)

    dropdown.MouseLeave:Connect(function()
        if not open then
            Tween(dropdown, {
                BackgroundColor3 = Library.Theme.Element
            })
        end
    end)

    dropdown.MouseButton1Click:Connect(function()
        openMenu()
    end)

    SetFlag(flag, current)

    local object = {
        Instance = holder,
        Dropdown = dropdown,

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

----------------------------------------------------------------
-- INPUT
----------------------------------------------------------------

function GroupboxMethods:AddInput(flag, options)
    options = options or {}

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 55),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        options.Text or flag,
        11,
        Library.Theme.Text,
        FONT_BOLD
    )

    label.Size = UDim2.new(1, 0, 0, 20)

    local input = New("TextBox", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        Text = options.Default or "",
        PlaceholderText = options.Placeholder or "",
        PlaceholderColor3 = Library.Theme.Muted,
        TextColor3 = Library.Theme.Text,
        TextSize = 10,
        Font = FONT_BOLD,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, holder)

    Corner(input, 8)
    Stroke(input, Library.Theme.Stroke, 1)
    Padding(input, 10, 0, 10, 0)

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

----------------------------------------------------------------
-- PARAGRAPH
----------------------------------------------------------------

function GroupboxMethods:AddParagraph(title, text)
    text = tostring(text or "")

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Library.Theme.Element,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y
    }, self.Container)

    Corner(holder, 8)
    Stroke(holder, Library.Theme.StrokeSoft, 1)

    Padding(holder, 10, 8, 10, 9)

    local titleLabel = CreateLabel(
        holder,
        title,
        11,
        Library.Theme.Text,
        FONT_BOLD
    )

    titleLabel.Size = UDim2.new(1, 0, 0, 18)

    local body = CreateLabel(
        holder,
        text,
        10,
        Library.Theme.SubText,
        FONT
    )

    body.Position = UDim2.new(0, 0, 0, 22)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top

    table.insert(self.Items, holder)

    return holder
end

----------------------------------------------------------------
-- COLOR PICKER
----------------------------------------------------------------

function GroupboxMethods:AddColorPicker(flag, options)
    options = options or {}

    local color = options.Default or Library.Theme.Accent

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1
    }, self.Container)

    local label = CreateLabel(
        holder,
        options.Text or flag,
        11,
        Library.Theme.Text,
        FONT_BOLD
    )

    label.Size = UDim2.new(1, -48, 1, 0)

    local picker = New("TextButton", {
        Size = UDim2.fromOffset(32, 20),
        Position = UDim2.new(1, -32, 0.5, -10),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, holder)

    Corner(picker, 7)
    Stroke(picker, Library.Theme.Stroke, 1)

    picker.MouseEnter:Connect(function()
        Tween(picker, {
            BackgroundColor3 = color:Lerp(
                Color3.new(1, 1, 1),
                0.08
            )
        })
    end)

    picker.MouseLeave:Connect(function()
        Tween(picker, {
            BackgroundColor3 = color
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

----------------------------------------------------------------
-- NOTIFICATION
----------------------------------------------------------------

function Library:Notify(options)
    options = options or {}

    local gui = PlayerGui:FindFirstChild("UILibraryNotifications")

    if not gui then
        gui = New("ScreenGui", {
            Name = "UILibraryNotifications",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 999998
        }, PlayerGui)
    end

    local holder = New("Frame", {
        Size = UDim2.fromOffset(300, 72),
        Position = UDim2.new(1, 20, 1, -90),
        BackgroundColor3 = Library.Theme.Surface,
        BorderSizePixel = 0
    }, gui)

    Corner(holder, 10)
    Stroke(holder, Library.Theme.Stroke, 1)

    local accent = New("Frame", {
        Size = UDim2.fromOffset(3, 42),
        Position = UDim2.new(0, 0, 0.5, -21),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0
    }, holder)

    Corner(accent, 2)

    local title = CreateLabel(
        holder,
        options.Title or "Notification",
        11,
        Library.Theme.Text,
        FONT_BOLD
    )

    title.Position = UDim2.new(0, 14, 0, 9)
    title.Size = UDim2.new(1, -28, 0, 18)

    local description = CreateLabel(
        holder,
        options.Description or "",
        9,
        Library.Theme.SubText,
        FONT
    )

    description.Position = UDim2.new(0, 14, 0, 30)
    description.Size = UDim2.new(1, -28, 0, 32)
    description.TextWrapped = true
    description.TextYAlignment = Enum.TextYAlignment.Top

    Tween(holder, {
        Position = UDim2.new(1, -320, 1, -90)
    })

    task.delay(options.Duration or 4, function()
        if holder and holder.Parent then
            Tween(holder, {
                Position = UDim2.new(1, 20, 1, -90)
            }, 0.2)

            task.wait(0.22)

            if holder and holder.Parent then
                holder:Destroy()
            end
        end
    end)

    return holder
end

----------------------------------------------------------------
-- FLAGS / ACCENT / UNLOAD
----------------------------------------------------------------

function Library:GetFlag(flag)
    return Library.Flags[flag]
end

function Library:SetFlag(flag, value)
    Library.Flags[flag] = value
end

function Library:SetAccent(color)
    Library.Theme.Accent = color
end

function Library:Unload()
    local gui = PlayerGui:FindFirstChild("UILibrary")

    if gui then
        gui:Destroy()
    end

    local dropdownGui = PlayerGui:FindFirstChild("UILibraryDropdowns")

    if dropdownGui then
        dropdownGui:Destroy()
    end

    local notifications = PlayerGui:FindFirstChild("UILibraryNotifications")

    if notifications then
        notifications:Destroy()
    end

    Library.Flags = {}
    Library.Items = {}
end

return Library
