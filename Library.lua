--// Moon Hub Library
--// Custom UI Library
--// Lucide icon support
--// Window / Tabs / Groupboxes
--// Designed for the Moon Hub UI

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {}

Library.__index = Library

Library.Version = "1.0.0"

Library.Theme = {
    Background = Color3.fromRGB(4, 4, 5),
    TopBar = Color3.fromRGB(8, 8, 9),

    Explorer = Color3.fromRGB(5, 5, 6),
    Modules = Color3.fromRGB(5, 5, 6),

    Content = Color3.fromRGB(4, 4, 5),

    Groupbox = Color3.fromRGB(9, 9, 11),

    Module = Color3.fromRGB(9, 9, 11),
    ModuleHover = Color3.fromRGB(15, 15, 18),
    ModuleSelected = Color3.fromRGB(17, 17, 20),

    Search = Color3.fromRGB(18, 18, 21),
    SearchFocused = Color3.fromRGB(21, 21, 24),

    Text = Color3.fromRGB(218, 218, 223),
    TextSecondary = Color3.fromRGB(135, 135, 142),
    TextWhite = Color3.fromRGB(250, 250, 252),

    Stroke = Color3.fromRGB(21, 21, 24),
    SearchStroke = Color3.fromRGB(28, 28, 32),
}

Library.Options = {}

Library.CurrentWindow = nil
Library.CurrentTab = nil


--// SERVICES

local function New(className, properties)

    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    return object

end


--// LUCIDE

local LucideLoaded = false
local Lucide = nil

do

    local success, result = pcall(function()

        local source = game:HttpGet(
            "https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"
        )

        return loadstring(source)()

    end)

    if success and result then

        LucideLoaded = true
        Lucide = result

    end

end


function Library:GetIcon(name)

    if not name or not LucideLoaded then
        return nil
    end

    local success, icon = pcall(function()

        return Lucide.GetAsset(Lucide, string.lower(name))

    end)

    if success and icon then
        return icon
    end

    return nil

end


function Library:SetIcon(imageLabel, iconName, color)

    if not imageLabel or not iconName then
        return
    end

    local icon = Library:GetIcon(iconName)

    if not icon then
        return
    end

    imageLabel.Image = icon.Url
    imageLabel.ImageRectOffset = icon.ImageRectOffset
    imageLabel.ImageRectSize = icon.ImageRectSize

    if color then
        imageLabel.ImageColor3 = color
    end

end


--// WINDOW

function Library:CreateWindow(config)

    config = config or {}

    if Library.CurrentWindow then
        pcall(function()
            Library.CurrentWindow:Destroy()
        end)
    end


    local Window = {}

    Window.Library = Library

    Window.Title = config.Title or "Moon Hub"
    Window.Size = config.Size or UDim2.fromOffset(720, 510)
    Window.Position = config.Position

    Window.Tabs = {}
    Window.TabList = {}

    Window.ActiveTab = nil
    Window.Minimized = false


    --// SCREEN GUI

    local ScreenGui = New("ScreenGui", {
        Name = "MoonHubGui",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = PlayerGui
    })

    Window.ScreenGui = ScreenGui


    --// MAIN FRAME

    local Frame = New("Frame", {
        Name = "MainFrame",
        Size = Window.Size,
        Position = Window.Position or UDim2.new(0.5, -360, 0.5, -255),
        BackgroundColor3 = Library.Theme.Background,
        BorderSizePixel = 0,
        Parent = ScreenGui
    })

    Window.MainFrame = Frame


    local MainStroke = New("UIStroke", {
        Thickness = 1,
        Color = Color3.fromRGB(22, 22, 24),
        Transparency = 0.1,
        Parent = Frame
    })


    local MainCorner = New("UICorner", {
        CornerRadius = UDim.new(0, 9),
        Parent = Frame
    })


    --// TOPBAR

    local TopBar = New("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Library.Theme.TopBar,
        BorderSizePixel = 0,
        Parent = Frame
    })

    Window.TopBar = TopBar


    New("UICorner", {
        CornerRadius = UDim.new(0, 9),
        Parent = TopBar
    })


    --// TITLE

    local Title = New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        Text = Window.Title,
        TextColor3 = Library.Theme.TextWhite,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 2,
        Parent = TopBar
    })

    Window.TitleLabel = Title


    --// MINIMIZE

    local MinimizeButton = New("TextButton", {
        Name = "MinimizeButton",
        Size = UDim2.fromOffset(32, 36),
        Position = UDim2.new(1, -64, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "−",
        TextColor3 = Color3.fromRGB(195, 195, 200),
        TextSize = 18,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = TopBar
    })

    Window.MinimizeButton = MinimizeButton


    --// CLOSE

    local CloseButton = New("TextButton", {
        Name = "CloseButton",
        Size = UDim2.fromOffset(32, 36),
        Position = UDim2.new(1, -32, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Color3.fromRGB(195, 195, 200),
        TextSize = 18,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = TopBar
    })

    Window.CloseButton = CloseButton


    --// EXPLORER

    local Explorer = New("Frame", {
        Name = "Explorer",
        Size = UDim2.new(0, 160, 0, 30),
        Position = UDim2.fromOffset(0, 36),
        BackgroundColor3 = Library.Theme.Explorer,
        BorderSizePixel = 0,
        Parent = Frame
    })

    Window.Explorer = Explorer


    --// SEARCH

    local SearchBox = New("Frame", {
        Name = "SearchBox",
        Size = UDim2.new(1, -12, 1, -8),
        Position = UDim2.fromOffset(6, 4),
        BackgroundColor3 = Library.Theme.Search,
        BorderSizePixel = 0,
        Parent = Explorer
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, 5),
        Parent = SearchBox
    })


    local SearchStroke = New("UIStroke", {
        Thickness = 1,
        Color = Library.Theme.SearchStroke,
        Transparency = 0.35,
        Parent = SearchBox
    })


    --// SEARCH ICON

    local SearchIcon = New("Frame", {
        Name = "SearchIcon",
        Size = UDim2.fromOffset(15, 15),
        Position = UDim2.new(0, 8, 0.5, -8),
        BackgroundTransparency = 1,
        Parent = SearchBox
    })

    local SearchCircle = New("Frame", {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.fromOffset(1, 1),
        BackgroundTransparency = 1,
        Parent = SearchIcon
    })

    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = SearchCircle
    })

    New("UIStroke", {
        Thickness = 1.5,
        Color = Library.Theme.TextSecondary,
        Parent = SearchCircle
    })

    New("Frame", {
        Name = "Handle",
        Size = UDim2.fromOffset(6, 1.5),
        Position = UDim2.fromOffset(8, 10),
        Rotation = 45,
        BackgroundColor3 = Library.Theme.TextSecondary,
        BorderSizePixel = 0,
        Parent = SearchIcon
    })


    local SearchInput = New("TextBox", {
        Name = "SearchInput",
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.fromOffset(31, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Text = "",
        PlaceholderText = "Search",
        PlaceholderColor3 = Color3.fromRGB(120, 120, 126),
        TextColor3 = Color3.fromRGB(235, 235, 238),
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = SearchBox
    })

    Window.SearchInput = SearchInput


    SearchInput.Focused:Connect(function()

        SearchBox.BackgroundColor3 = Library.Theme.SearchFocused
        SearchStroke.Color = Color3.fromRGB(45, 45, 50)

    end)


    SearchInput.FocusLost:Connect(function()

        SearchBox.BackgroundColor3 = Library.Theme.Search
        SearchStroke.Color = Library.Theme.SearchStroke

    end)


    --// MODULES

    local Modules = New("Frame", {
        Name = "Modules",
        Size = UDim2.new(0, 160, 1, -66),
        Position = UDim2.fromOffset(0, 66),
        BackgroundColor3 = Library.Theme.Modules,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Frame
    })

    Window.Modules = Modules


    local ModuleContainer = New("ScrollingFrame", {
        Name = "ModuleContainer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(65, 65, 70),
        ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Modules
    })

    Window.ModuleContainer = ModuleContainer


    New("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = ModuleContainer
    })


    local ModuleLayout = New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ModuleContainer
    })

    Window.ModuleLayout = ModuleLayout


    --// CONTENT

    local Content = New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -160, 1, -36),
        Position = UDim2.fromOffset(160, 36),
        BackgroundColor3 = Library.Theme.Content,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = Frame
    })

    Window.Content = Content


    --// GROUPBOX COLUMNS

    local LeftColumn = New("ScrollingFrame", {
        Name = "LeftColumn",
        Size = UDim2.new(0.5, -7, 1, -24),
        Position = UDim2.fromOffset(10, 12),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(55, 55, 60),
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Content
    })

    local RightColumn = New("ScrollingFrame", {
        Name = "RightColumn",
        Size = UDim2.new(0.5, -7, 1, -24),
        Position = UDim2.new(0.5, -3, 0, 12),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(55, 55, 60),
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Content
    })

    Window.LeftColumn = LeftColumn
    Window.RightColumn = RightColumn


    for _, column in ipairs({LeftColumn, RightColumn}) do

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 10),
            Parent = column
        })

        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = column
        })

    end


    --// MODULE SELECTION

    local SelectedModule = nil


    function Window:AddTab(name, icon)

        local Tab = {}

        Tab.Name = name
        Tab.Icon = icon
        Tab.Window = Window
        Tab.Groupboxes = {}
        Tab.Active = false


        --// MODULE BUTTON

        local Module = New("TextButton", {
            Name = name .. "Module",
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = Library.Theme.Module,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = #Window.TabList + 1,
            Parent = ModuleContainer
        })

        Tab.Button = Module


        --// ICON

        local Icon = New("ImageLabel", {
            Name = "Icon",
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(0, 9, 0.5, -9),
            BackgroundTransparency = 1,
            ImageTransparency = 0,
            Parent = Module
        })

        Tab.IconLabel = Icon


        if icon then
            Library:SetIcon(Icon, icon, Library.Theme.TextSecondary)
        end


        --// TEXT

        local ModuleText = New("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -38, 1, 0),
            Position = UDim2.fromOffset(38, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Library.Theme.Text,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = Module
        })

        Tab.TextLabel = ModuleText


        local ModuleStroke = New("UIStroke", {
            Thickness = 1,
            Color = Library.Theme.Stroke,
            Transparency = 0.55,
            Parent = Module
        })


        --// SHOW TAB

        function Tab:Show()

            if Window.ActiveTab then

                local Old = Window.ActiveTab

                Old.Active = false
                Old.Button.BackgroundColor3 = Library.Theme.Module
                Old.TextLabel.TextColor3 = Library.Theme.Text

                if Old.IconLabel then
                    Old.IconLabel.ImageColor3 = Library.Theme.TextSecondary
                end

            end


            Window.ActiveTab = Tab
            Library.CurrentTab = Tab

            Tab.Active = true

            Module.BackgroundColor3 = Library.Theme.ModuleSelected
            ModuleText.TextColor3 = Library.Theme.TextWhite

            if Icon then
                Icon.ImageColor3 = Library.Theme.TextWhite
            end


            for _, tab in pairs(Window.Tabs) do

                if tab.Page then
                    tab.Page.Visible = false
                end

            end


            Tab.Page.Visible = true

        end


        Module.MouseEnter:Connect(function()

            if not Tab.Active then

                Module.BackgroundColor3 = Library.Theme.ModuleHover
                ModuleText.TextColor3 = Library.Theme.TextWhite

                if Icon then
                    Icon.ImageColor3 = Library.Theme.TextWhite
                end

            end

        end)


        Module.MouseLeave:Connect(function()

            if not Tab.Active then

                Module.BackgroundColor3 = Library.Theme.Module
                ModuleText.TextColor3 = Library.Theme.Text

                if Icon then
                    Icon.ImageColor3 = Library.Theme.TextSecondary
                end

            end

        end)


        Module.MouseButton1Click:Connect(function()
            Tab:Show()
        end)


        --// TAB PAGE

        local Page = New("Frame", {
            Name = name .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = Content
        })

        Tab.Page = Page


        --// TAB GROUPBOX COLUMNS

        local TabLeft = New("ScrollingFrame", {
            Name = "Left",
            Size = UDim2.new(0.5, -7, 1, -24),
            Position = UDim2.fromOffset(10, 12),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Color3.fromRGB(55, 55, 60),
            CanvasSize = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = Page
        })

        local TabRight = New("ScrollingFrame", {
            Name = "Right",
            Size = UDim2.new(0.5, -7, 1, -24),
            Position = UDim2.new(0.5, -3, 0, 12),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Color3.fromRGB(55, 55, 60),
            CanvasSize = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = Page
        })


        for _, column in ipairs({TabLeft, TabRight}) do

            New("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                Parent = column
            })

            New("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = column
            })

        end


        Tab.Left = TabLeft
        Tab.Right = TabRight


        --// GROUPBOX CREATOR

        function Tab:AddGroupbox(info)

            info = info or {}

            local groupName = info.Name or "Groupbox"
            local side = info.Side or 1
            local groupIcon = info.Icon


            local parentColumn = side == 1 and TabLeft or TabRight


            local Groupbox = {}

            Groupbox.Name = groupName
            Groupbox.Icon = groupIcon
            Groupbox.Tab = Tab
            Groupbox.Elements = {}


            local Holder = New("Frame", {
                Name = groupName .. "Holder",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Library.Theme.Groupbox,
                BorderSizePixel = 0,
                Parent = parentColumn
            })

            Groupbox.Holder = Holder


            New("UICorner", {
                CornerRadius = UDim.new(0, 7),
                Parent = Holder
            })


            New("UIStroke", {
                Thickness = 1,
                Color = Library.Theme.Stroke,
                Transparency = 0.25,
                Parent = Holder
            })


            --// GROUPBOX HEADER

            local Header = New("Frame", {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundTransparency = 1,
                Parent = Holder
            })

            Groupbox.Header = Header


            local HeaderIcon = New("ImageLabel", {
                Name = "Icon",
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.new(0, 10, 0.5, -8),
                BackgroundTransparency = 1,
                Parent = Header
            })


            if groupIcon then
                Library:SetIcon(
                    HeaderIcon,
                    groupIcon,
                    Library.Theme.TextSecondary
                )
            else
                HeaderIcon.Visible = false
            end


            local HeaderText = New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, groupIcon and -38 or -20, 1, 0),
                Position = UDim2.fromOffset(groupIcon and 32 or 10, 0),
                BackgroundTransparency = 1,
                Text = groupName,
                TextColor3 = Library.Theme.TextWhite,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                Parent = Header
            })


            New("Frame", {
                Name = "Divider",
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.fromOffset(0, 34),
                BackgroundColor3 = Library.Theme.Stroke,
                BorderSizePixel = 0,
                Parent = Holder
            })


            --// CONTAINER

            local Container = New("Frame", {
                Name = "Container",
                Size = UDim2.new(1, -20, 0, 0),
                Position = UDim2.fromOffset(10, 40),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = Holder
            })

            Groupbox.Container = Container


            local Padding = New("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                Parent = Container
            })


            local Layout = New("UIListLayout", {
                Padding = UDim.new(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Container
            })


            --// LABEL

            function Groupbox:AddLabel(text)

                local Label = New("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Text = text or "",
                    TextColor3 = Library.Theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Parent = Container
                })

                table.insert(Groupbox.Elements, Label)

                return Label

            end


            --// BUTTON

            function Groupbox:AddButton(info)

                info = info or {}

                local Button = New("TextButton", {
                    Name = info.Name or "Button",
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Color3.fromRGB(14, 14, 17),
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = info.Text or "Button",
                    TextColor3 = Library.Theme.TextWhite,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    Parent = Container
                })


                New("UICorner", {
                    CornerRadius = UDim.new(0, 5),
                    Parent = Button
                })


                New("UIStroke", {
                    Thickness = 1,
                    Color = Library.Theme.Stroke,
                    Transparency = 0.4,
                    Parent = Button
                })


                Button.MouseEnter:Connect(function()
                    Button.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
                end)


                Button.MouseLeave:Connect(function()
                    Button.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
                end)


                Button.MouseButton1Click:Connect(function()

                    if typeof(info.Func) == "function" then
                        task.spawn(info.Func)
                    elseif typeof(info.Callback) == "function" then
                        task.spawn(info.Callback)
                    end

                end)


                table.insert(Groupbox.Elements, Button)

                return Button

            end


            --// TOGGLE

            function Groupbox:AddToggle(flag, info)

                info = info or {}

                local Toggle = {}

                Toggle.Flag = flag
                Toggle.Value = info.Default or false


                local Button = New("TextButton", {
                    Name = flag,
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "",
                    Parent = Container
                })


                local Box = New("Frame", {
                    Size = UDim2.fromOffset(16, 16),
                    Position = UDim2.new(0, 0, 0.5, -8),
                    BackgroundColor3 = Color3.fromRGB(15, 15, 18),
                    BorderSizePixel = 0,
                    Parent = Button
                })


                New("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = Box
                })


                local Text = New("TextLabel", {
                    Size = UDim2.new(1, -24, 1, 0),
                    Position = UDim2.fromOffset(24, 0),
                    BackgroundTransparency = 1,
                    Text = info.Text or flag,
                    TextColor3 = Library.Theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    Parent = Button
                })


                local function Update()

                    if Toggle.Value then
                        Box.BackgroundColor3 = Color3.fromRGB(230, 230, 235)
                    else
                        Box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
                    end

                    if typeof(info.Callback) == "function" then
                        task.spawn(info.Callback, Toggle.Value)
                    end

                end


                function Toggle:SetValue(value)

                    Toggle.Value = value == true
                    Update()

                end


                Button.MouseButton1Click:Connect(function()
                    Toggle:SetValue(not Toggle.Value)
                end)


                Toggle:SetValue(Toggle.Value)

                Library.Options[flag] = Toggle

                return Toggle

            end


            --// INPUT

            function Groupbox:AddInput(flag, info)

                info = info or {}

                local Input = {}

                Input.Value = info.Default or ""


                local Box = New("TextBox", {
                    Name = flag,
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Color3.fromRGB(14, 14, 17),
                    BorderSizePixel = 0,
                    Text = Input.Value,
                    PlaceholderText = info.Placeholder or "Input",
                    PlaceholderColor3 = Library.Theme.TextSecondary,
                    TextColor3 = Library.Theme.TextWhite,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    ClearTextOnFocus = false,
                    Parent = Container
                })


                New("UICorner", {
                    CornerRadius = UDim.new(0, 5),
                    Parent = Box
                })


                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 9),
                    PaddingRight = UDim.new(0, 9),
                    Parent = Box
                })


                function Input:SetValue(value)

                    Input.Value = tostring(value or "")
                    Box.Text = Input.Value

                    if typeof(info.Callback) == "function" then
                        task.spawn(info.Callback, Input.Value)
                    end

                end


                Box.FocusLost:Connect(function()
                    Input:SetValue(Box.Text)
                end)


                Library.Options[flag] = Input

                return Input

            end


            --// GROUPBOX RESIZE

            function Groupbox:Resize()

                task.defer(function()

                    local height =
                        Layout.AbsoluteContentSize.Y
                        + 50

                    Holder.Size = UDim2.new(
                        1,
                        0,
                        0,
                        height
                    )

                end)

            end


            Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Groupbox:Resize()
            end)


            Groupbox:Resize()

            table.insert(Tab.Groupboxes, Groupbox)

            return Groupbox

        end


        function Tab:AddLeftGroupbox(name, icon)
            return Tab:AddGroupbox({
                Name = name,
                Icon = icon,
                Side = 1
            })
        end


        function Tab:AddRightGroupbox(name, icon)
            return Tab:AddGroupbox({
                Name = name,
                Icon = icon,
                Side = 2
            })
        end


        Window.Tabs[name] = Tab
        table.insert(Window.TabList, Tab)


        if not Window.ActiveTab then
            Tab:Show()
        end


        return Tab

    end


    --// WINDOW DESTROY

    function Window:Destroy()

        if ScreenGui then
            ScreenGui:Destroy()
        end

        if Library.CurrentWindow == Window then
            Library.CurrentWindow = nil
        end

    end


    --// MINIMIZE

    local minimized = false

    MinimizeButton.MouseEnter:Connect(function()
        MinimizeButton.TextColor3 = Library.Theme.TextWhite
    end)

    MinimizeButton.MouseLeave:Connect(function()
        MinimizeButton.TextColor3 = Color3.fromRGB(195, 195, 200)
    end)


    CloseButton.MouseEnter:Connect(function()
        CloseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
    end)

    CloseButton.MouseLeave:Connect(function()
        CloseButton.TextColor3 = Color3.fromRGB(195, 195, 200)
    end)


    MinimizeButton.MouseButton1Click:Connect(function()

        minimized = not minimized

        Window.Minimized = minimized

        Explorer.Visible = not minimized
        Modules.Visible = not minimized
        Content.Visible = not minimized

        if minimized then
            Frame.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, 36)
        else
            Frame.Size = Window.Size
        end

    end)


    CloseButton.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)


    --// DRAGGING

    local dragging = false
    local dragStart
    local startPosition

    TopBar.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = Frame.Position

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

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            local delta = input.Position - dragStart

            Frame.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )

        end

    end)


    --// SEARCH TABS

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()

        local query = string.lower(SearchInput.Text or "")

        for _, Tab in ipairs(Window.TabList) do

            local visible = query == ""
                or string.find(
                    string.lower(Tab.Name),
                    query,
                    1,
                    true
                )

            Tab.Button.Visible = visible

        end

    end)


    Library.CurrentWindow = Window

    return Window

end


--// NOTIFY

function Library:Notify(text)

    print("[Moon Hub] " .. tostring(text))

end


--// RETURN

return Library
