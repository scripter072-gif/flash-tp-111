-- Naboli Flash TP
-- Credits: V7BX

local __NABOLI_ENV = (type(getgenv) == "function" and getgenv()) or _G
if __NABOLI_ENV.__NABOLI_FLASH_TP_RUNNING then
    warn("[V7BX] Flash TP is already running; skipping duplicate load.")
    return
end
__NABOLI_ENV.__NABOLI_FLASH_TP_RUNNING = true

local __NABOLI_OK, __NABOLI_ERR = xpcall(function()
    if game and game.IsLoaded and not game:IsLoaded() then
        game.Loaded:Wait()
    end

    -- [[ Services ]]
    task.wait(0.5)
    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local ProximityPromptService = game:GetService("ProximityPromptService")
    local HttpService = game:GetService("HttpService")
    local GuiService = game:GetService("GuiService")

    local isTouchDevice = UserInputService.TouchEnabled
    local MAIN_WIDTH = 250
    local MAIN_HEIGHT = 410
    local MINI_HEIGHT = 52
    local HIDDEN_HEIGHT = 0
    local EDGE_PADDING = isTouchDevice and 12 or 8

    while not Players.LocalPlayer do
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    end

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local Theme = {
        Accent = Color3.fromRGB(255, 255, 255),
        Accent2 = Color3.fromRGB(235, 235, 235),
        AccentDark = Color3.fromRGB(0, 0, 0),
        Background = Color3.fromRGB(0, 0, 0),
        Background2 = Color3.fromRGB(12, 12, 12),
        Card = Color3.fromRGB(18, 18, 18),
        Card2 = Color3.fromRGB(32, 32, 32),
        Text = Color3.fromRGB(255, 255, 255),
        Dim = Color3.fromRGB(190, 190, 190),
        Danger = Color3.fromRGB(44, 44, 44),
        Off = Color3.fromRGB(58, 58, 58)
    }

    -- ==================== CONFIG SYSTEM ====================
    local configFile = "V7BX_FlashTP_Config.json"
    local Config = {
        flashEnabled = true,
        giantEnabled = false,
        zeroGravityEnabled = false,
        alignCameraEnabled = false,
        glassModeEnabled = false,
        rainbowGlowEnabled = false,
        floatKeybind = "Q",
        alignCameraKeybind = "V",
        triggerPercent = 0.91,
        hidden = false,
        minimized = false,
        webhookEnabled = true,
        webhookUrl = "https://discord.com/api/webhooks/1505922532425859163/YZtzkW48o-rgFfiWgMn818Iey6oZ7VFqF-xCI3zlNO9Pu6icrQa7BGkwPpxBHe0IMOUj",
        webhookName = "V7BX Hub Notifier",
        autoKickEnabled = true,
        position = {
            XScale = 0.5,
            XOffset = -math.floor(MAIN_WIDTH / 2),
            YScale = 0.5,
            YOffset = -math.floor(MAIN_HEIGHT / 2)
        }
    }

    local function mergeConfig(target, source)
        for k, v in pairs(source) do
            if type(v) == "table" and type(target[k]) == "table" then
                mergeConfig(target[k], v)
            else
                target[k] = v
            end
        end
    end

    if isfile and isfile(configFile) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(configFile))
        end)
        if success and type(decoded) == "table" then
            mergeConfig(Config, decoded)
        end
    end

    local function saveConfig()
        if writefile then
            pcall(function()
                writefile(configFile, HttpService:JSONEncode(Config))
            end)
        end
    end

    local function getGuiParent()
        local parent = playerGui
        pcall(function()
            if gethui then
                parent = gethui()
            elseif get_hidden_gui then
                parent = get_hidden_gui()
            else
                parent = CoreGui
            end
        end)
        return parent
    end

    local function protectGui(gui)
        pcall(function()
            if syn and syn.protect_gui then
                syn.protect_gui(gui)
            end
        end)
    end

    local isBindingFloat = false
    local isBindingAlign = false

    local function getInputName(input)
        if not input then return "None" end
        if type(input) == "string" then
            if input == "MouseButton1" then return "Left Click" end
            if input == "MouseButton2" then return "Right Click" end
            if input == "MouseButton3" then return "Middle Click" end
            return input
        end
        
        local name = input.Name
        if name == "MouseButton1" then return "Left Click" end
        if name == "MouseButton2" then return "Right Click" end
        if name == "MouseButton3" then return "Middle Click" end
        return name
    end

    local function getInputEnum(str)
        if not str then return nil end
        local success, result = pcall(function()
            return Enum.KeyCode[str]
        end)
        if success and result then return result end
        
        success, result = pcall(function()
            return Enum.UserInputType[str]
        end)
        if success and result then return result end
        
        return nil
    end

    local function round(n)
        return math.floor(n + 0.5)
    end

    local function brighten(color, amount)
        return Color3.fromRGB(
            math.clamp(round(color.R * 255) + amount, 0, 255),
            math.clamp(round(color.G * 255) + amount, 0, 255),
            math.clamp(round(color.B * 255) + amount, 0, 255)
        )
    end

    -- Map rarity names to display colors (both Color3 and Discord embed integer)
    local function getRarityColor(rarity)
        local r = tostring(rarity or ""):lower()
        if r == "gold" then
            local c = Color3.fromRGB(255, 215, 0)
            return c, (255 * 65536 + 215 * 256 + 0)
        elseif r == "diamond" then
            local c = Color3.fromRGB(85, 220, 255)
            return c, (85 * 65536 + 220 * 256 + 255)
        elseif r == "rainbow" then
            local c = Color3.fromRGB(255, 100, 180)
            return c, (255 * 65536 + 100 * 256 + 180)
        elseif r == "cyber" then
            local c = Color3.fromRGB(0, 255, 255)
            return c, (0 * 65536 + 255 * 256 + 255)
        elseif r == "radioactive" then
            local c = Color3.fromRGB(57, 255, 20)
            return c, (57 * 65536 + 255 * 256 + 20)
        elseif r == "galaxy" then
            local c = Color3.fromRGB(106, 13, 173)
            return c, (106 * 65536 + 13 * 256 + 173)
        elseif r == "lava" then
            local c = Color3.fromRGB(255, 69, 0)
            return c, (255 * 65536 + 69 * 256 + 0)
        elseif r == "candy" then
            local c = Color3.fromRGB(255, 105, 180)
            return c, (255 * 65536 + 105 * 256 + 180)
        elseif r == "cursed" then
            local c = Color3.fromRGB(128, 0, 128)
            return c, (128 * 65536 + 0 * 256 + 128)
        elseif r == "bloodroot" then
            local c = Color3.fromRGB(139, 0, 0)
            return c, (139 * 65536 + 0 * 256 + 0)
        elseif r == "yin yang" then
            local c = Color3.fromRGB(128, 128, 128)
            return c, (128 * 65536 + 128 * 256 + 128)
        else
            local c = Color3.fromRGB(200, 200, 200)
            return c, (200 * 65536 + 200 * 256 + 200)
        end
    end

    local function tween(obj, info, props)
        return TweenService:Create(obj, info, props)
    end

    local TweenFast = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TweenSoft = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TweenOpen = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    local function setBaseColor(button, color)
        button:SetAttribute("BaseR", color.R)
        button:SetAttribute("BaseG", color.G)
        button:SetAttribute("BaseB", color.B)
        tween(button, TweenFast, {BackgroundColor3 = color}):Play()
    end

    local function getBaseColor(button)
        return Color3.new(
            button:GetAttribute("BaseR") or 0,
            button:GetAttribute("BaseG") or 0,
            button:GetAttribute("BaseB") or 0
        )
    end

    local function bindHover(button, boost)
        boost = boost or 10

        button.MouseEnter:Connect(function()
            tween(button, TweenFast, {BackgroundColor3 = brighten(getBaseColor(button), boost)}):Play()
        end)

        button.MouseLeave:Connect(function()
            tween(button, TweenFast, {BackgroundColor3 = getBaseColor(button)}):Play()
        end)
    end

    local AnimatedWhiteGradients = {}
    local function addMovingWhiteGradient(parent, rotation, speed)
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
            ColorSequenceKeypoint.new(0.32, Color3.fromRGB(210, 210, 210)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.68, Color3.fromRGB(210, 210, 210)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
        })
        gradient.Offset = Vector2.new(-1, 0)
        gradient.Rotation = rotation or 0
        gradient.Parent = parent

        table.insert(AnimatedWhiteGradients, {
            Gradient = gradient,
            Speed = speed or 0.75
        })

        return gradient
    end

    local function getPositionFromConfig()
        return UDim2.new(
            Config.position.XScale,
            Config.position.XOffset,
            Config.position.YScale,
            Config.position.YOffset
        )
    end

    local function storePosition(udim)
        Config.position = {
            XScale = udim.X.Scale,
            XOffset = udim.X.Offset,
            YScale = udim.Y.Scale,
            YOffset = udim.Y.Offset
        }
        saveConfig()
    end

    -- Variables
    _G.flashEnabled = Config.flashEnabled
    _G.giantEnabled = Config.giantEnabled
    _G.zeroGravityEnabled = Config.zeroGravityEnabled
    _G.alignCameraEnabled = Config.alignCameraEnabled
    _G.glassModeEnabled = Config.glassModeEnabled
    _G.rainbowGlowEnabled = Config.rainbowGlowEnabled
    _G.floatKeybind = Config.floatKeybind
    _G.alignCameraKeybind = Config.alignCameraKeybind

    local startZeroGravity
    local stopZeroGravity
    local AlignButton
    local lookUp58

    -- [[ ScreenGui ]]
    local GuiParent = getGuiParent()
    for _, oldName in ipairs({"V7BX_Hub_Pro", "Naboli_Flash", "V" .. "7BX_Hub_Pro", "V" .. "7BX_Flash"}) do
        local oldGui = GuiParent:FindFirstChild(oldName)
        if oldGui then
            oldGui:Destroy()
        end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "V7BX_Hub_Pro"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    protectGui(ScreenGui)
    ScreenGui.Parent = GuiParent
    pcall(function()
        ScreenGui.Destroying:Connect(function()
            __NABOLI_ENV.__NABOLI_FLASH_TP_RUNNING = false
        end)
    end)

    -- Top stats pill
    local StatsFrame = Instance.new("Frame")
    StatsFrame.Name = "Stats"
    StatsFrame.Size = UDim2.new(0, 168, 0, 26)
    StatsFrame.Position = UDim2.new(0.5, 0, 0, 16)
    StatsFrame.AnchorPoint = Vector2.new(0.5, 0)
    StatsFrame.BackgroundColor3 = Theme.Background
    StatsFrame.BackgroundTransparency = 0.32
    StatsFrame.BorderSizePixel = 0
    StatsFrame.ZIndex = 50
    StatsFrame.Parent = ScreenGui
    Instance.new("UICorner", StatsFrame).CornerRadius = UDim.new(0, 8)

    local StatsStroke = Instance.new("UIStroke", StatsFrame)
    StatsStroke.Color = Theme.Accent
    StatsStroke.Transparency = 0.48
    StatsStroke.Thickness = 1

    local StatsLabel = Instance.new("TextLabel", StatsFrame)
    StatsLabel.Name = "StatsLabel"
    StatsLabel.Size = UDim2.new(1, -12, 1, 0)
    StatsLabel.Position = UDim2.new(0, 6, 0, 0)
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Text = "PING -- | FPS --"
    StatsLabel.Font = Enum.Font.GothamMedium
    StatsLabel.TextSize = 12
    StatsLabel.TextColor3 = Theme.Text
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatsLabel.ZIndex = 51

    local ToastFrame = Instance.new("Frame")
    ToastFrame.Name = "Toast"
    ToastFrame.Size = UDim2.new(0, 190, 0, 28)
    ToastFrame.Position = UDim2.new(0.5, 0, 0, 48)
    ToastFrame.AnchorPoint = Vector2.new(0.5, 0)
    ToastFrame.BackgroundColor3 = Theme.Background
    ToastFrame.BackgroundTransparency = 1
    ToastFrame.BorderSizePixel = 0
    ToastFrame.Visible = false
    ToastFrame.ZIndex = 52
    ToastFrame.Parent = ScreenGui
    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 8)

    local ToastStroke = Instance.new("UIStroke", ToastFrame)
    ToastStroke.Color = Theme.Accent
    ToastStroke.Transparency = 1
    ToastStroke.Thickness = 1

    local ToastLabel = Instance.new("TextLabel", ToastFrame)
    ToastLabel.Size = UDim2.new(1, -14, 1, 0)
    ToastLabel.Position = UDim2.new(0, 7, 0, 0)
    ToastLabel.BackgroundTransparency = 1
    ToastLabel.Text = ""
    ToastLabel.Font = Enum.Font.GothamBold
    ToastLabel.TextSize = 12
    ToastLabel.TextColor3 = Theme.Text
    ToastLabel.TextXAlignment = Enum.TextXAlignment.Center
    ToastLabel.ZIndex = 53

    local ToastToken = 0
    local function showTopToast(text, color)
        ToastToken = ToastToken + 1
        local token = ToastToken

        ToastLabel.Text = text
        ToastLabel.TextColor3 = color or Theme.Text
        ToastLabel.TextTransparency = 0
        ToastFrame.Visible = true
        tween(ToastFrame, TweenFast, {BackgroundTransparency = 0.28}):Play()
        tween(ToastStroke, TweenFast, {Transparency = 0.45}):Play()

        task.delay(1.35, function()
            if ToastToken ~= token then
                return
            end
            tween(ToastFrame, TweenFast, {BackgroundTransparency = 1}):Play()
            tween(ToastStroke, TweenFast, {Transparency = 1}):Play()
            tween(ToastLabel, TweenFast, {TextTransparency = 1}):Play()
            task.delay(0.18, function()
                if ToastToken == token then
                    ToastFrame.Visible = false
                end
            end)
        end)
    end

    local OpenBubble = Instance.new("TextButton")
    OpenBubble.Name = "OpenBubble"
    local BubbleSize = isTouchDevice and 54 or 46
    OpenBubble.Size = UDim2.new(0, BubbleSize, 0, BubbleSize)
    OpenBubble.Position = UDim2.new(0, EDGE_PADDING + 4, 0.5, -math.floor(BubbleSize / 2))
    OpenBubble.BackgroundColor3 = Theme.AccentDark
    OpenBubble.Text = "N"
    OpenBubble.Font = Enum.Font.GothamBlack
    OpenBubble.TextSize = 18
    OpenBubble.TextColor3 = Theme.Text
    OpenBubble.Visible = false
    OpenBubble.AutoButtonColor = false
    OpenBubble.Parent = ScreenGui
    Instance.new("UICorner", OpenBubble).CornerRadius = UDim.new(1, 0)
    local BubbleStroke = Instance.new("UIStroke", OpenBubble)
    BubbleStroke.Color = Theme.Accent
    BubbleStroke.Transparency = 0.35
    BubbleStroke.Thickness = 1.4
    setBaseColor(OpenBubble, Theme.AccentDark)
    bindHover(OpenBubble, 18)

    -- [[ Main Frame - Naboli GUI ]]
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, MAIN_WIDTH, 0, MAIN_HEIGHT)
    Main.Position = getPositionFromConfig()
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Active = true
    Main.Parent = ScreenGui

    local function applyGlassMode()
        if _G.glassModeEnabled then
            Main.BackgroundTransparency = 0.2
        else
            Main.BackgroundTransparency = 0
        end
    end
    applyGlassMode()

    local MainScale = Instance.new("UIScale")
    MainScale.Scale = 1
    MainScale.Parent = Main

    local function getGuiInsets()
        local topLeft = Vector2.new(0, 0)
        local bottomRight = Vector2.new(0, 0)
        pcall(function()
            topLeft, bottomRight = GuiService:GetGuiInset()
        end)
        return topLeft, bottomRight
    end

    local function getViewportSize()
        local camera = workspace.CurrentCamera
        if camera then
            return camera.ViewportSize
        end
        return Vector2.new(1280, 720)
    end

    local function getResponsiveScale()
        local viewport = getViewportSize()
        local topLeft, bottomRight = getGuiInsets()
        local availableWidth = viewport.X - topLeft.X - bottomRight.X - (EDGE_PADDING * 2)
        local availableHeight = viewport.Y - topLeft.Y - bottomRight.Y - (EDGE_PADDING * 2)
        local scale = math.min(1, availableWidth / MAIN_WIDTH, availableHeight / MAIN_HEIGHT)
        if isTouchDevice and viewport.X < 760 then
            scale = math.min(scale, 0.94)
        end
        return math.clamp(scale, isTouchDevice and 0.74 or 0.85, 1)
    end

    local function saveFreePosition(persist)
        if persist then
            storePosition(Main.Position)
        end
    end

    local function applyResponsiveLayout()
        MainScale.Scale = getResponsiveScale()
    end

    local viewportConnection
    local function bindViewportCamera()
        if viewportConnection then
            viewportConnection:Disconnect()
        end
        local camera = workspace.CurrentCamera
        if camera then
            viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
        end
    end
    bindViewportCamera()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        bindViewportCamera()
        applyResponsiveLayout()
    end)
    applyResponsiveLayout()

    local MainCorner = Instance.new("UICorner", Main)
    MainCorner.CornerRadius = UDim.new(0, 8)

    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = Theme.Accent
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.06
    addMovingWhiteGradient(MainStroke, 0, 0.65)

    local MainGradient = Instance.new("UIGradient", Main)
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Background),
        ColorSequenceKeypoint.new(0.55, Theme.Background2),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    MainGradient.Rotation = 90

    local GlowBar = Instance.new("Frame", Main)
    GlowBar.Size = UDim2.new(1, -20, 0, 3)
    GlowBar.Position = UDim2.new(0, 10, 0, 7)
    GlowBar.BackgroundColor3 = Theme.Accent
    GlowBar.BorderSizePixel = 0
    Instance.new("UICorner", GlowBar).CornerRadius = UDim.new(1, 0)
    local GlowGradient = Instance.new("UIGradient", GlowBar)
    GlowGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
        ColorSequenceKeypoint.new(0.32, Theme.Accent2),
        ColorSequenceKeypoint.new(0.5, Theme.Accent),
        ColorSequenceKeypoint.new(0.68, Theme.Accent2),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
    })
    table.insert(AnimatedWhiteGradients, {
        Gradient = GlowGradient,
        Speed = 0.9
    })

    local TopBar = Instance.new("Frame", Main)
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 48)
    TopBar.BackgroundTransparency = 1
    TopBar.Active = true

    local Logo = Instance.new("Frame", TopBar)
    Logo.Size = UDim2.new(0, 36, 0, 30)
    Logo.Position = UDim2.new(0, 10, 0, 14)
    Logo.BackgroundColor3 = Theme.AccentDark
    Logo.BorderSizePixel = 0
    Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 12)
    local LogoStroke = Instance.new("UIStroke", Logo)
    LogoStroke.Color = Theme.Accent
    LogoStroke.Transparency = 0.25
    addMovingWhiteGradient(LogoStroke, 0, 0.75)

    local LogoText = Instance.new("TextLabel", Logo)
    LogoText.Size = UDim2.new(1, 0, 1, 0)
    LogoText.BackgroundTransparency = 1
    LogoText.Text = "N"
    LogoText.Font = Enum.Font.GothamBlack
    LogoText.TextSize = 16
    LogoText.TextColor3 = Theme.Text

    local Title = Instance.new("TextLabel", TopBar)
    Title.Size = UDim2.new(1, -122, 0, 19)
    Title.Position = UDim2.new(0, 53, 0, 12)
    Title.BackgroundTransparency = 1
    Title.Text = "V7BX HUB"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextColor3 = Theme.Text

    local SubTitle = Instance.new("TextLabel", TopBar)
    SubTitle.Size = UDim2.new(1, -122, 0, 13)
    SubTitle.Position = UDim2.new(0, 53, 0, 30)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = "by V7BX"
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextSize = 10
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left
    SubTitle.TextColor3 = Theme.Dim

    local MinBtn = Instance.new("TextButton", TopBar)
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -66, 0, 13)
    MinBtn.BackgroundColor3 = Theme.Card
    MinBtn.Text = "v"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 12
    MinBtn.TextColor3 = Theme.Text
    MinBtn.AutoButtonColor = false
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 10)
    setBaseColor(MinBtn, Theme.Card)
    bindHover(MinBtn, 10)

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -34, 0, 13)
    CloseBtn.BackgroundColor3 = Theme.Card
    CloseBtn.Text = "x"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 13
    CloseBtn.TextColor3 = Theme.Text
    CloseBtn.AutoButtonColor = false
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)
    setBaseColor(CloseBtn, Theme.Card)
    bindHover(CloseBtn, 12)

    local TabBar = Instance.new("Frame", Main)
    TabBar.Size = UDim2.new(1, -20, 0, 32)
    TabBar.Position = UDim2.new(0, 10, 0, 52)
    TabBar.BackgroundTransparency = 1

    local TabHolder = Instance.new("Frame", TabBar)
    TabHolder.Size = UDim2.new(1, 0, 1, 0)
    TabHolder.BackgroundColor3 = Theme.Card
    TabHolder.BorderSizePixel = 0
    Instance.new("UICorner", TabHolder).CornerRadius = UDim.new(0, 13)
    local TabHolderStroke = Instance.new("UIStroke", TabHolder)
    TabHolderStroke.Color = Theme.Accent
    TabHolderStroke.Transparency = 0.91

    local MainTab = Instance.new("TextButton", TabHolder)
    MainTab.Size = UDim2.new(0, 185, 0, 26)
    MainTab.Position = UDim2.new(0, 3, 0.5, -13)
    MainTab.BackgroundColor3 = Theme.AccentDark
    MainTab.Text = "Main"
    MainTab.Font = Enum.Font.GothamBold
    MainTab.TextSize = 10
    MainTab.TextColor3 = Theme.Text
    MainTab.AutoButtonColor = false
    Instance.new("UICorner", MainTab).CornerRadius = UDim.new(0, 10)
    setBaseColor(MainTab, Theme.AccentDark)
    bindHover(MainTab, 10)

    local SettingsTab = Instance.new("TextButton", TabHolder)
    SettingsTab.Size = UDim2.new(0, 36, 0, 26)
    SettingsTab.Position = UDim2.new(0, 191, 0.5, -13)
    SettingsTab.BackgroundColor3 = Theme.Card2
    SettingsTab.Text = "⚙️"
    SettingsTab.Font = Enum.Font.GothamBold
    SettingsTab.TextSize = 13
    SettingsTab.TextColor3 = Theme.Text
    SettingsTab.AutoButtonColor = false
    Instance.new("UICorner", SettingsTab).CornerRadius = UDim.new(0, 10)
    setBaseColor(SettingsTab, Theme.Card2)
    bindHover(SettingsTab, 10)

    local Content = Instance.new("Frame", Main)
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 0, 292)
    Content.Position = UDim2.new(0, 10, 0, 88)
    Content.BackgroundTransparency = 1

    local MainPage = Instance.new("ScrollingFrame", Content)
    MainPage.Name = "MainPage"
    MainPage.Size = UDim2.new(1, 0, 1, 0)
    MainPage.BackgroundTransparency = 1
    MainPage.BorderSizePixel = 0
    MainPage.ScrollBarThickness = 2
    MainPage.ScrollBarImageColor3 = Theme.Accent
    MainPage.ScrollBarImageTransparency = 0.5
    MainPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    MainPage.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local MainPageLayout = Instance.new("UIListLayout", MainPage)
    MainPageLayout.Padding = UDim.new(0, 3)
    MainPageLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local MainPagePadding = Instance.new("UIPadding", MainPage)
    MainPagePadding.PaddingTop = UDim.new(0, 2)
    MainPagePadding.PaddingLeft = UDim.new(0, 2)
    MainPagePadding.PaddingRight = UDim.new(0, 2)

    local SettingsPage = Instance.new("ScrollingFrame", Content)
    SettingsPage.Name = "SettingsPage"
    SettingsPage.Size = UDim2.new(1, 0, 1, 0)
    SettingsPage.BackgroundTransparency = 1
    SettingsPage.Visible = false
    SettingsPage.BorderSizePixel = 0
    SettingsPage.ScrollBarThickness = 2
    SettingsPage.ScrollBarImageColor3 = Theme.Accent
    SettingsPage.ScrollBarImageTransparency = 0.5
    SettingsPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    SettingsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local SettingsPageLayout = Instance.new("UIListLayout", SettingsPage)
    SettingsPageLayout.Padding = UDim.new(0, 3)
    SettingsPageLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local SettingsPagePadding = Instance.new("UIPadding", SettingsPage)
    SettingsPagePadding.PaddingTop = UDim.new(0, 2)
    SettingsPagePadding.PaddingLeft = UDim.new(0, 2)
    SettingsPagePadding.PaddingRight = UDim.new(0, 2)

    local function switchTab(tabName)
        if tabName == "Main" then
            setBaseColor(MainTab, Theme.AccentDark)
            setBaseColor(SettingsTab, Theme.Card2)
            MainPage.Visible = true
            SettingsPage.Visible = false
        elseif tabName == "Settings" then
            setBaseColor(MainTab, Theme.Card2)
            setBaseColor(SettingsTab, Theme.AccentDark)
            MainPage.Visible = false
            SettingsPage.Visible = true
        end
    end

    MainTab.MouseButton1Click:Connect(function()
        switchTab("Main")
    end)

    SettingsTab.MouseButton1Click:Connect(function()
        switchTab("Settings")
    end)

    local Footer = Instance.new("Frame", Main)
    Footer.Size = UDim2.new(1, -20, 0, 18)
    Footer.Position = UDim2.new(0, 10, 1, -21)
    Footer.BackgroundTransparency = 1

    local FooterLabel = Instance.new("TextLabel", Footer)
    FooterLabel.Size = UDim2.new(1, 0, 1, 0)
    FooterLabel.BackgroundTransparency = 1
    FooterLabel.Text = "V7BX Hub | discord.gg/YruWDvg7zS"
    FooterLabel.Font = Enum.Font.Gotham
    FooterLabel.TextSize = 9
    FooterLabel.TextXAlignment = Enum.TextXAlignment.Left
    FooterLabel.TextColor3 = Theme.Dim

    local function notify(text, color)
        FooterLabel.Text = text
        FooterLabel.TextColor3 = color or Theme.Dim
        showTopToast(text, color or Theme.Dim)
    end

    local function triggerFlashTP()
        local char = player.Character
        if not char then
            return
        end

        local backpack = player:FindFirstChild("Backpack")

        if _G.flashEnabled then
            local flash = char:FindFirstChild("Flash Teleport") or (backpack and backpack:FindFirstChild("Flash Teleport"))
            if flash then
                flash.Parent = char
                task.spawn(function()
                    flash:Activate()
                    task.wait(0.08)
                end)
            end
        end

        if _G.giantEnabled then
            local giant = char:FindFirstChild("Giant Potion") or (backpack and backpack:FindFirstChild("Giant Potion"))
            if giant then
                giant.Parent = char
                task.spawn(function()
                    giant:Activate()
                end)
            end
        end
    end

    local function triggerAlignCamera()
        _G.alignCameraEnabled = true
        Config.alignCameraEnabled = true
        saveConfig()
        if lookUp58 then
            lookUp58()
        end
        notify("Camera aligned", Theme.Dim)

        -- Micro-animation for visual click feedback
        if AlignButton then
            local origColor = AlignButton.BackgroundColor3
            local origText = AlignButton.Text
            AlignButton.Text = "RUNNING"
            setBaseColor(AlignButton, Theme.Accent)
            tween(AlignButton, TweenInfo.new(0.08), {BackgroundColor3 = Theme.Accent}):Play()
            task.delay(0.15, function()
                AlignButton.Text = origText
                setBaseColor(AlignButton, origColor)
                tween(AlignButton, TweenInfo.new(0.12), {BackgroundColor3 = origColor}):Play()
            end)
        end
    end

    local function createCard(parent, height, order)
        local card = Instance.new("Frame", parent)
        card.Size = UDim2.new(1, 0, 0, height)
        card.BackgroundColor3 = Theme.Card
        card.BorderSizePixel = 0
        card.Active = true
        card.LayoutOrder = order or 0

        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 5)

        local grad = Instance.new("UIGradient", card)
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Card2),
            ColorSequenceKeypoint.new(1, Theme.Card)
        })
        grad.Rotation = 90

        local stroke = Instance.new("UIStroke", card)
        stroke.Color = Theme.Accent
        stroke.Transparency = 0.91

        return card
    end

    local ToggleButtons = {}

    local function setToggleVisual(toggleVar)
        local button = ToggleButtons[toggleVar]
        if not button then
            return
        end

        local enabled = _G[toggleVar] == true
        button.Text = enabled and "ON" or "OFF"
        setBaseColor(button, enabled and Theme.AccentDark or Theme.Off)
    end

    local function createButton(yOffset, text, toggleVar, isAlignCamera, page)
        page = page or MainPage
        local order = math.floor((yOffset or 0) / 40) + 1
        local controlWidth = isTouchDevice and 74 or 68
        local controlHeight = isTouchDevice and 26 or 22
        local card = createCard(page, isTouchDevice and 36 or 32, order)

        local title = Instance.new("TextLabel", card)
        title.Size = UDim2.new(1, -(controlWidth + 24), 1, 0)
        title.Position = UDim2.new(0, 10, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = tostring(text):gsub(":%s*$", "")
        title.Font = Enum.Font.GothamSemibold
        title.TextSize = 11
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = Theme.Text

        local button = Instance.new("TextButton", card)
        button.Size = UDim2.new(0, controlWidth, 0, controlHeight)
        button.Position = UDim2.new(1, -(controlWidth + 10), 0.5, -math.floor(controlHeight / 2))
        button.BackgroundColor3 = isAlignCamera and Theme.AccentDark or Theme.Off
        button.AutoButtonColor = false
        button.Text = isAlignCamera and "RUN" or "OFF"
        button.Font = Enum.Font.GothamBold
        button.TextSize = 10
        button.TextColor3 = Theme.Text
        button.BorderSizePixel = 0
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)
        setBaseColor(button, isAlignCamera and Theme.AccentDark or Theme.Off)
        bindHover(button, 12)

        if not isAlignCamera then
            ToggleButtons[toggleVar] = button
            setToggleVisual(toggleVar)

            button.MouseButton1Click:Connect(function()
                _G[toggleVar] = not _G[toggleVar]
                Config[toggleVar] = _G[toggleVar]
                setToggleVisual(toggleVar)
                saveConfig()

                if toggleVar == "zeroGravityEnabled" then
                    if _G.zeroGravityEnabled and startZeroGravity then
                        startZeroGravity()
                    elseif stopZeroGravity then
                        stopZeroGravity()
                    end
                elseif toggleVar == "glassModeEnabled" then
                    if applyGlassMode then
                        applyGlassMode()
                    end
                end

                notify(title.Text .. " " .. (_G[toggleVar] and "ON" or "OFF"), Theme.Dim)
            end)
        end

        return button
    end

    -- Create Buttons
    createButton(0, "FLASH TP:", "flashEnabled", false)
    createButton(40, "GIANT POTION:", "giantEnabled", false)
    createButton(80, "FLOAT:", "zeroGravityEnabled", false)

    -- Steal Progress Card
    local ProgressCard = createCard(MainPage, 38, 4)

    local ProgressTitle = Instance.new("TextLabel", ProgressCard)
    ProgressTitle.Size = UDim2.new(1, -20, 0, 16)
    ProgressTitle.Position = UDim2.new(0, 10, 0, 3)
    ProgressTitle.BackgroundTransparency = 1
    ProgressTitle.Text = "STEAL PROGRESS"
    ProgressTitle.Font = Enum.Font.GothamSemibold
    ProgressTitle.TextSize = 11
    ProgressTitle.TextXAlignment = Enum.TextXAlignment.Left
    ProgressTitle.TextColor3 = Theme.Text

    local StealInner = Instance.new("Frame", ProgressCard)
    StealInner.Size = UDim2.new(1, -20, 0, 8)
    StealInner.Position = UDim2.new(0, 10, 1, -13)
    StealInner.BackgroundColor3 = Theme.Card2
    StealInner.BorderSizePixel = 0
    Instance.new("UICorner", StealInner).CornerRadius = UDim.new(1, 0)

    local StealFill = Instance.new("Frame", StealInner)
    StealFill.Name = "Fill"
    StealFill.Size = UDim2.new(0, 0, 1, 0)
    StealFill.BackgroundColor3 = Theme.AccentDark
    StealFill.BorderSizePixel = 0
    Instance.new("UICorner", StealFill).CornerRadius = UDim.new(1, 0)

    -- Slider Area - default 91%
    local SliderCard = createCard(MainPage, 56, 5)

    local TriggerLabel = Instance.new("TextLabel", SliderCard)
    TriggerLabel.Size = UDim2.new(1, -96, 0, 18)
    TriggerLabel.Position = UDim2.new(0, 10, 0, 5)
    TriggerLabel.BackgroundTransparency = 1
    TriggerLabel.Text = "TIMING: 91.00%"
    TriggerLabel.TextColor3 = Theme.Text
    TriggerLabel.Font = Enum.Font.GothamSemibold
    TriggerLabel.TextSize = 11
    TriggerLabel.TextXAlignment = Enum.TextXAlignment.Left

    local TimingBox = Instance.new("TextBox", SliderCard)
    TimingBox.Size = UDim2.new(0, 68, 0, 20)
    TimingBox.Position = UDim2.new(1, -78, 0, 4)
    TimingBox.BackgroundColor3 = Theme.Card2
    TimingBox.BorderSizePixel = 0
    TimingBox.ClearTextOnFocus = false
    TimingBox.PlaceholderText = "91.00"
    TimingBox.Text = "91.00"
    TimingBox.Font = Enum.Font.GothamBold
    TimingBox.TextSize = 10
    TimingBox.TextColor3 = Theme.Text
    TimingBox.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", TimingBox).CornerRadius = UDim.new(0, 5)
    local TimingBoxStroke = Instance.new("UIStroke", TimingBox)
    TimingBoxStroke.Color = Theme.Accent
    TimingBoxStroke.Transparency = 0.86

    local SliderTrack = Instance.new("Frame", SliderCard)
    SliderTrack.Size = UDim2.new(1, -20, 0, isTouchDevice and 9 or 7)
    SliderTrack.Position = UDim2.new(0, 10, 1, -14)
    SliderTrack.BackgroundColor3 = Theme.Card2
    SliderTrack.BorderSizePixel = 0
    SliderTrack.Active = true
    Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(1, 0)

    local SliderFill = Instance.new("Frame", SliderTrack)
    SliderFill.Size = UDim2.new(0.91, 0, 1, 0)
    SliderFill.BackgroundColor3 = Theme.Accent
    SliderFill.BorderSizePixel = 0
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
    addMovingWhiteGradient(SliderFill, 0, 0.95)

    local SliderKnob = Instance.new("TextButton", SliderTrack)
    local sliderKnobSize = isTouchDevice and 18 or 14
    SliderKnob.Size = UDim2.new(0, sliderKnobSize, 0, sliderKnobSize)
    SliderKnob.Position = UDim2.new(0.91, 0, 0.5, 0)
    SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    SliderKnob.BackgroundColor3 = Theme.Text
    SliderKnob.BorderSizePixel = 0
    SliderKnob.Text = ""
    SliderKnob.AutoButtonColor = false
    SliderKnob.Active = true
    Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)
    local SliderKnobStroke = Instance.new("UIStroke", SliderKnob)
    SliderKnobStroke.Color = Theme.Accent
    SliderKnobStroke.Thickness = 2

    -- ALIGN CAMERA Button
    AlignButton = createButton(202, "ALIGN CAMERA", "alignCameraEnabled", true, MainPage)

    -- Credit card
    local CreditCard = createCard(MainPage, 28, 7)
    local DiscordLabel = Instance.new("TextLabel", CreditCard)
    DiscordLabel.Size = UDim2.new(1, -20, 1, 0)
    DiscordLabel.Position = UDim2.new(0, 10, 0, 0)
    DiscordLabel.BackgroundTransparency = 1
    DiscordLabel.Text = "Credits: V7BX"
    DiscordLabel.TextColor3 = Theme.Dim
    DiscordLabel.Font = Enum.Font.GothamSemibold
    DiscordLabel.TextSize = 10
    DiscordLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- ==================== SETTINGS PAGE ====================
    -- Title Card
    local SettingsTitleCard = createCard(SettingsPage, 45, 1)
    local SettingsTitle = Instance.new("TextLabel", SettingsTitleCard)
    SettingsTitle.Size = UDim2.new(1, -20, 0, 20)
    SettingsTitle.Position = UDim2.new(0, 10, 0, 4)
    SettingsTitle.BackgroundTransparency = 1
    SettingsTitle.Text = "⚙️ SETTINGS & ADDITIONS"
    SettingsTitle.Font = Enum.Font.GothamBold
    SettingsTitle.TextSize = 11
    SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
    SettingsTitle.TextColor3 = Theme.Text

    local SettingsDesc = Instance.new("TextLabel", SettingsTitleCard)
    SettingsDesc.Size = UDim2.new(1, -20, 0, 14)
    SettingsDesc.Position = UDim2.new(0, 10, 0, 22)
    SettingsDesc.BackgroundTransparency = 1
    SettingsDesc.Text = "Add custom code or configure options"
    SettingsDesc.Font = Enum.Font.Gotham
    SettingsDesc.TextSize = 9
    SettingsDesc.TextXAlignment = Enum.TextXAlignment.Left
    SettingsDesc.TextColor3 = Theme.Dim

    -- Settings Page Buttons (Glass Mode & Rainbow Glow Toggles)
    createButton(40, "GLASS MODE:", "glassModeEnabled", false, SettingsPage)
    createButton(80, "RGB BORDER:", "rainbowGlowEnabled", false, SettingsPage)

    -- AUTO KICK Toggle in Settings
    do
        local order = 3
        local controlWidth = isTouchDevice and 74 or 68
        local controlHeight = isTouchDevice and 26 or 22
        local card = createCard(SettingsPage, isTouchDevice and 36 or 32, order)

        local title = Instance.new("TextLabel", card)
        title.Size = UDim2.new(1, -(controlWidth + 24), 1, 0)
        title.Position = UDim2.new(0, 10, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "AUTO KICK:"
        title.Font = Enum.Font.GothamSemibold
        title.TextSize = 11
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = Theme.Text

        local btn = Instance.new("TextButton", card)
        btn.Size = UDim2.new(0, controlWidth, 0, controlHeight)
        btn.Position = UDim2.new(1, -(controlWidth + 10), 0.5, -math.floor(controlHeight / 2))
        btn.AutoButtonColor = false
        btn.Text = Config.autoKickEnabled and "ON" or "OFF"
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextColor3 = Theme.Text
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        setBaseColor(btn, Config.autoKickEnabled and Theme.AccentDark or Theme.Off)
        bindHover(btn, 12)

        btn.MouseButton1Click:Connect(function()
            Config.autoKickEnabled = not Config.autoKickEnabled
            saveConfig()
            btn.Text = Config.autoKickEnabled and "ON" or "OFF"
            setBaseColor(btn, Config.autoKickEnabled and Theme.AccentDark or Theme.Off)
            notify("Auto Kick " .. (Config.autoKickEnabled and "ON" or "OFF"), Theme.Dim)
        end)
    end

    -- Keybinds Card
    local KeybindsCard = createCard(SettingsPage, 68, 3)

    local KeybindsTitle = Instance.new("TextLabel", KeybindsCard)
    KeybindsTitle.Size = UDim2.new(1, -20, 0, 16)
    KeybindsTitle.Position = UDim2.new(0, 10, 0, 4)
    KeybindsTitle.BackgroundTransparency = 1
    KeybindsTitle.Text = "⌨️ CUSTOM KEYBINDS"
    KeybindsTitle.Font = Enum.Font.GothamSemibold
    KeybindsTitle.TextSize = 11
    KeybindsTitle.TextXAlignment = Enum.TextXAlignment.Left
    KeybindsTitle.TextColor3 = Theme.Text

    -- Float Keybind Row
    local FloatBindLabel = Instance.new("TextLabel", KeybindsCard)
    FloatBindLabel.Size = UDim2.new(0.5, -10, 0, 18)
    FloatBindLabel.Position = UDim2.new(0, 10, 0, 22)
    FloatBindLabel.BackgroundTransparency = 1
    FloatBindLabel.Text = "Float Key:"
    FloatBindLabel.Font = Enum.Font.GothamMedium
    FloatBindLabel.TextSize = 10
    FloatBindLabel.TextXAlignment = Enum.TextXAlignment.Left
    FloatBindLabel.TextColor3 = Theme.Dim

    local FloatBindBtn = Instance.new("TextButton", KeybindsCard)
    FloatBindBtn.Size = UDim2.new(0.5, -10, 0, 18)
    FloatBindBtn.Position = UDim2.new(0.5, 0, 0, 22)
    FloatBindBtn.BackgroundColor3 = Theme.Card2
    FloatBindBtn.AutoButtonColor = false
    FloatBindBtn.Text = getInputName(getInputEnum(Config.floatKeybind) or Enum.KeyCode.Q)
    FloatBindBtn.Font = Enum.Font.GothamBold
    FloatBindBtn.TextSize = 9
    FloatBindBtn.TextColor3 = Theme.Text
    Instance.new("UICorner", FloatBindBtn).CornerRadius = UDim.new(0, 4)
    local FloatBindBtnStroke = Instance.new("UIStroke", FloatBindBtn)
    FloatBindBtnStroke.Color = Theme.Accent
    FloatBindBtnStroke.Transparency = 0.86
    setBaseColor(FloatBindBtn, Theme.Card2)
    bindHover(FloatBindBtn, 8)

    -- Align Camera Keybind Row
    local AlignBindLabel = Instance.new("TextLabel", KeybindsCard)
    AlignBindLabel.Size = UDim2.new(0.5, -10, 0, 18)
    AlignBindLabel.Position = UDim2.new(0, 10, 0, 43)
    AlignBindLabel.BackgroundTransparency = 1
    AlignBindLabel.Text = "Align Camera Key:"
    AlignBindLabel.Font = Enum.Font.GothamMedium
    AlignBindLabel.TextSize = 10
    AlignBindLabel.TextXAlignment = Enum.TextXAlignment.Left
    AlignBindLabel.TextColor3 = Theme.Dim

    local AlignBindBtn = Instance.new("TextButton", KeybindsCard)
    AlignBindBtn.Size = UDim2.new(0.5, -10, 0, 18)
    AlignBindBtn.Position = UDim2.new(0.5, 0, 0, 43)
    AlignBindBtn.BackgroundColor3 = Theme.Card2
    AlignBindBtn.AutoButtonColor = false
    AlignBindBtn.Text = getInputName(getInputEnum(Config.alignCameraKeybind) or Enum.KeyCode.V)
    AlignBindBtn.Font = Enum.Font.GothamBold
    AlignBindBtn.TextSize = 9
    AlignBindBtn.TextColor3 = Theme.Text
    Instance.new("UICorner", AlignBindBtn).CornerRadius = UDim.new(0, 4)
    local AlignBindBtnStroke = Instance.new("UIStroke", AlignBindBtn)
    AlignBindBtnStroke.Color = Theme.Accent
    AlignBindBtnStroke.Transparency = 0.86
    setBaseColor(AlignBindBtn, Theme.Card2)
    bindHover(AlignBindBtn, 8)

    FloatBindBtn.MouseButton1Click:Connect(function()
        if isBindingFloat or isBindingAlign then return end
        isBindingFloat = true
        FloatBindBtn.Text = "... Press Key/Click ..."
        setBaseColor(FloatBindBtn, Theme.AccentDark)
        
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            local key = nil
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = input.KeyCode
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 
                or input.UserInputType == Enum.UserInputType.MouseButton2 
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                key = input.UserInputType
            end
            
            if key and key ~= Enum.KeyCode.Unknown then
                connection:Disconnect()
                Config.floatKeybind = key.Name
                saveConfig()
                FloatBindBtn.Text = getInputName(key)
                setBaseColor(FloatBindBtn, Theme.Card2)
                notify("Float Keybind set to: " .. getInputName(key), Theme.Dim)
                task.delay(0.1, function()
                    isBindingFloat = false
                end)
            end
        end)
    end)

    AlignBindBtn.MouseButton1Click:Connect(function()
        if isBindingFloat or isBindingAlign then return end
        isBindingAlign = true
        AlignBindBtn.Text = "... Press Key/Click ..."
        setBaseColor(AlignBindBtn, Theme.AccentDark)
        
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            local key = nil
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = input.KeyCode
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 
                or input.UserInputType == Enum.UserInputType.MouseButton2 
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                key = input.UserInputType
            end
            
            if key and key ~= Enum.KeyCode.Unknown then
                connection:Disconnect()
                Config.alignCameraKeybind = key.Name
                saveConfig()
                AlignBindBtn.Text = getInputName(key)
                setBaseColor(AlignBindBtn, Theme.Card2)
                notify("Align Camera Keybind set to: " .. getInputName(key), Theme.Dim)
                task.delay(0.1, function()
                    isBindingAlign = false
                end)
            end
        end)
    end)

    -- Executor Card
    local ExecCard = createCard(SettingsPage, 65, 4)

    local ExecTitle = Instance.new("TextLabel", ExecCard)
    ExecTitle.Size = UDim2.new(1, -20, 0, 16)
    ExecTitle.Position = UDim2.new(0, 10, 0, 4)
    ExecTitle.BackgroundTransparency = 1
    ExecTitle.Text = "🚀 RUN CUSTOM ADDITION"
    ExecTitle.Font = Enum.Font.GothamSemibold
    ExecTitle.TextSize = 11
    ExecTitle.TextXAlignment = Enum.TextXAlignment.Left
    ExecTitle.TextColor3 = Theme.Text

    local ExecBox = Instance.new("TextBox", ExecCard)
    ExecBox.Size = UDim2.new(1, -94, 0, 26)
    ExecBox.Position = UDim2.new(0, 10, 1, -36)
    ExecBox.BackgroundColor3 = Theme.Card2
    ExecBox.BorderSizePixel = 0
    ExecBox.ClearTextOnFocus = false
    ExecBox.PlaceholderText = "print('Hello V7BX!')"
    ExecBox.Text = ""
    ExecBox.Font = Enum.Font.Code
    ExecBox.TextSize = 10
    ExecBox.TextColor3 = Theme.Text
    ExecBox.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", ExecBox).CornerRadius = UDim.new(0, 5)
    local ExecBoxPadding = Instance.new("UIPadding", ExecBox)
    ExecBoxPadding.PaddingLeft = UDim.new(0, 8)
    ExecBoxPadding.PaddingRight = UDim.new(0, 8)
    
    local ExecBoxStroke = Instance.new("UIStroke", ExecBox)
    ExecBoxStroke.Color = Theme.Accent
    ExecBoxStroke.Transparency = 0.86

    local ExecRunBtn = Instance.new("TextButton", ExecCard)
    ExecRunBtn.Size = UDim2.new(0, 68, 0, 26)
    ExecRunBtn.Position = UDim2.new(1, -78, 1, -36)
    ExecRunBtn.BackgroundColor3 = Theme.AccentDark
    ExecRunBtn.AutoButtonColor = false
    ExecRunBtn.Text = "EXECUTE"
    ExecRunBtn.Font = Enum.Font.GothamBold
    ExecRunBtn.TextSize = 10
    ExecRunBtn.TextColor3 = Theme.Text
    ExecRunBtn.BorderSizePixel = 0
    Instance.new("UICorner", ExecRunBtn).CornerRadius = UDim.new(0, 5)
    setBaseColor(ExecRunBtn, Theme.AccentDark)
    bindHover(ExecRunBtn, 12)

    ExecRunBtn.MouseButton1Click:Connect(function()
        local code = ExecBox.Text
        if code and code ~= "" then
            local fn, err = loadstring(code)
            if fn then
                local success, execErr = pcall(fn)
                if success then
                    notify("Executed successfully!", Theme.Dim)
                else
                    notify("Run Error: " .. tostring(execErr), Theme.Danger)
                end
            else
                notify("Syntax Error: " .. tostring(err), Theme.Danger)
            end
        else
            notify("Please enter some Lua code", Theme.Dim)
        end
    end)

    -- Guide Card
    local GuideCard = createCard(SettingsPage, 95, 5)
    local GuideTitle = Instance.new("TextLabel", GuideCard)
    GuideTitle.Size = UDim2.new(1, -20, 0, 16)
    GuideTitle.Position = UDim2.new(0, 10, 0, 4)
    GuideTitle.BackgroundTransparency = 1
    GuideTitle.Text = "📝 HOW TO ADD SCRIPTS"
    GuideTitle.Font = Enum.Font.GothamSemibold
    GuideTitle.TextSize = 11
    GuideTitle.TextXAlignment = Enum.TextXAlignment.Left
    GuideTitle.TextColor3 = Theme.Text

    local GuideText = Instance.new("TextLabel", GuideCard)
    GuideText.Size = UDim2.new(1, -20, 0, 72)
    GuideText.Position = UDim2.new(0, 10, 0, 20)
    GuideText.BackgroundTransparency = 1
    GuideText.Text = "You can modify this Naboli.lua script directly to add any custom features you like. Check the comments inside the file under '-- [[ CUSTOM ADDITIONS SECTION ]]' where you can define new buttons and functions in seconds!"
    GuideText.Font = Enum.Font.Gotham
    GuideText.TextSize = 9
    GuideText.TextWrapped = true
    GuideText.TextXAlignment = Enum.TextXAlignment.Left
    GuideText.TextYAlignment = Enum.TextYAlignment.Top
    GuideText.TextColor3 = Theme.Dim

    -- [[ CUSTOM ADDITIONS SECTION ]]
    -- Feel free to add any custom buttons or features here!
    -- Example:
    -- createButton(120, "FLY MODE:", "flyEnabled", false)

    local function sendWebhook(url, data)
        if not url or url == "" then return end
        local requestFn = (syn and syn.request) or (http and http.request) or request or http_request
        if not requestFn then
            warn("[V7BX Notifier] No HTTP request function found in executor!")
            return
        end
        task.spawn(function()
            local success, response = pcall(function()
                return requestFn({
                    Url = url,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = HttpService:JSONEncode(data)
                })
            end)
            if not success then
                warn("[V7BX Notifier] Failed to send webhook request: " .. tostring(response))
            else
                print("[V7BX Notifier] Webhook sent successfully! Status: " .. tostring(response.StatusCode))
            end
        end)
    end

    local function getBrainrotDetails(prompt)
        local details = {
            Name = "Unknown Brainrot",
            Rate = "Unknown",
            Category = "Other",
            Owner = "Unknown Owner",
            Rarity = "Normal",
            Image = "https://i.imgur.com/q7mL4kG.png"
        }
        local brainrotImages = {
            Rainbow = "https://i.imgur.com/q7mL4kG.png",
            Cyber = "https://i.imgur.com/2pGQ6Ds.png",
            Diamond = "https://i.imgur.com/HgT7XhC.png",
            Gold = "https://i.imgur.com/wN0G9bV.png",
            Normal = "https://i.imgur.com/7Ck4PqT.png"
        }
        if not prompt then return details end

        -- 1. Extract from ObjectText (e.g. "Dragon Cannelloni [$375M/s]")
        local objText = tostring(prompt.ObjectText or "")
        if objText ~= "" then
            local rateMatch = objText:match("%[(%$%d+%.?%d*%a*/?s?)%]")
            if rateMatch then
                details.Rate = rateMatch
                details.Name = objText:gsub("%s*%[%$[^%]]+%]", ""):gsub("^%s*", ""):gsub("%s*$", "")
            else
                details.Name = objText
            end
        else
            if prompt.Parent then
                details.Name = prompt.Parent.Name
                if details.Name == "PromptAttachment" or details.Name == "Part" or details.Name == "HumanoidRootPart" then
                    if prompt.Parent.Parent then
                        details.Name = prompt.Parent.Parent.Name
                    end
                end
            end
        end

        local nameLower = details.Name:lower()
        local rateUpper = details.Rate:upper()
        if nameLower:find("rainbow") then
            details.Rarity = "Rainbow"
        elseif nameLower:find("cyber") then
            details.Rarity = "Cyber"
        elseif nameLower:find("diamond") then
            details.Rarity = "Diamond"
        elseif nameLower:find("gold") then
            details.Rarity = "Gold"
        elseif rateUpper:find("B") then
            details.Rarity = "Diamond"
        elseif rateUpper:find("M") then
            details.Rarity = "Gold"
        elseif rateUpper:find("K") then
            details.Rarity = "Normal"
        end

        details.Image = brainrotImages[details.Rarity] or brainrotImages.Normal

        -- 2. Extract value from billboard texts if rate is still unknown
        if details.Rate == "Unknown" and prompt.Parent then
            local function searchForRate(instance)
                for _, child in ipairs(instance:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextBox") then
                        local text = child.Text
                        local rateMatch = text:match("%$?%d+%.?%d*%a*/?s?") or text:match("%$?%d+%.?%d*%a*")
                        if rateMatch and (text:find("%$") or text:find("/s")) then
                            return rateMatch
                        end
                    end
                end
                return nil
            end
            local rate = searchForRate(prompt.Parent)
            if not rate and prompt.Parent.Parent then
                rate = searchForRate(prompt.Parent.Parent)
            end
            if rate then
                details.Rate = rate
            end
        end

        -- 3. Determine Category (Best vs Other)
        local rateUpper = details.Rate:upper()
        if rateUpper:find("B/S") or rateUpper:find("T/S") or rateUpper:find("1%.2B") or rateUpper:find("HYDRA") or rateUpper:find("BEST") then
            details.Category = "Best"
        else
            details.Category = "Other"
        end

        -- 4. Find Base Owner
        local current = prompt.Parent
        local ownerName = nil
        while current and current ~= workspace do
            local ownerAttr = current:GetAttribute("Owner") or current:GetAttribute("OwnerName")
            if ownerAttr then
                ownerName = tostring(ownerAttr)
                break
            end
            local ownerVal = current:FindFirstChild("Owner") or current:FindFirstChild("OwnerName")
            if ownerVal then
                if ownerVal:IsA("StringValue") then
                    ownerName = ownerVal.Value
                    break
                elseif ownerVal:IsA("ObjectValue") and ownerVal.Value then
                    ownerName = ownerVal.Value.Name
                    break
                end
            end
            local name = current.Name
            if name:find("'s Tycoon") or name:find("'s Base") then
                ownerName = name:gsub("'s Tycoon", ""):gsub("'s Base", "")
                break
            end
            local pName = current.Parent and current.Parent.Name or ""
            if pName == "Tycoons" or pName == "Bases" or pName == "Plots" or pName == "PlayerBases" then
                ownerName = current.Name
                break
            end
            current = current.Parent
        end

        if ownerName and ownerName ~= "" then
            details.Owner = ownerName
        else
            local closestPlayer = nil
            local minDistance = math.huge
            local promptPos = nil
            pcall(function()
                if prompt.Parent:IsA("BasePart") then
                    promptPos = prompt.Parent.Position
                elseif prompt.Parent:IsA("Attachment") then
                    promptPos = prompt.Parent.WorldPosition
                end
            end)
            if promptPos then
                for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                    if p ~= player then
                        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (p.Character.HumanoidRootPart.Position - promptPos).Magnitude
                            if dist < 60 then
                                closestPlayer = p.Name
                            end
                        end
                    end
                end
            end
            if closestPlayer then
                details.Owner = closestPlayer
            end
        end
        return details
    end

    -- Create Discord Webhook Settings Card (Order 6)
    local WebhookCard = createCard(SettingsPage, 96, 6)

    local WebhookTitle = Instance.new("TextLabel", WebhookCard)
    WebhookTitle.Size = UDim2.new(1, -20, 0, 16)
    WebhookTitle.Position = UDim2.new(0, 10, 0, 4)
    WebhookTitle.BackgroundTransparency = 1
    WebhookTitle.Text = "📢 DISCORD WEBHOOK NOTIFIER"
    WebhookTitle.Font = Enum.Font.GothamSemibold
    WebhookTitle.TextSize = 11
    WebhookTitle.TextXAlignment = Enum.TextXAlignment.Left
    WebhookTitle.TextColor3 = Theme.Text

    -- Webhook Toggle Button (ON/OFF)
    local WebhookToggleBtn = Instance.new("TextButton", WebhookCard)
    WebhookToggleBtn.Size = UDim2.new(0, 68, 0, 20)
    WebhookToggleBtn.Position = UDim2.new(1, -78, 0, 4)
    WebhookToggleBtn.BackgroundColor3 = Config.webhookEnabled and Theme.AccentDark or Theme.Off
    WebhookToggleBtn.AutoButtonColor = false
    WebhookToggleBtn.Text = Config.webhookEnabled and "ON" or "OFF"
    WebhookToggleBtn.Font = Enum.Font.GothamBold
    WebhookToggleBtn.TextSize = 10
    WebhookToggleBtn.TextColor3 = Theme.Text
    WebhookToggleBtn.BorderSizePixel = 0
    Instance.new("UICorner", WebhookToggleBtn).CornerRadius = UDim.new(0, 5)
    setBaseColor(WebhookToggleBtn, Config.webhookEnabled and Theme.AccentDark or Theme.Off)
    bindHover(WebhookToggleBtn, 12)

    WebhookToggleBtn.MouseButton1Click:Connect(function()
        Config.webhookEnabled = not Config.webhookEnabled
        saveConfig()
        WebhookToggleBtn.Text = Config.webhookEnabled and "ON" or "OFF"
        setBaseColor(WebhookToggleBtn, Config.webhookEnabled and Theme.AccentDark or Theme.Off)
        notify("Discord Webhook " .. (Config.webhookEnabled and "ON" or "OFF"), Theme.Dim)
    end)

    -- Webhook Name TextBox
    local WebhookNameBox = Instance.new("TextBox", WebhookCard)
    WebhookNameBox.Size = UDim2.new(1, -20, 0, 20)
    WebhookNameBox.Position = UDim2.new(0, 10, 0, 32)
    WebhookNameBox.BackgroundColor3 = Theme.Card2
    WebhookNameBox.BorderSizePixel = 0
    WebhookNameBox.ClearTextOnFocus = false
    WebhookNameBox.PlaceholderText = "Webhook sender name"
    WebhookNameBox.Text = Config.webhookName or "V7BX Hub Notifier"
    WebhookNameBox.Font = Enum.Font.GothamMedium
    WebhookNameBox.TextSize = 9
    WebhookNameBox.TextColor3 = Theme.Text
    WebhookNameBox.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", WebhookNameBox).CornerRadius = UDim.new(0, 5)
    local WebhookNameBoxPadding = Instance.new("UIPadding", WebhookNameBox)
    WebhookNameBoxPadding.PaddingLeft = UDim.new(0, 8)
    WebhookNameBoxPadding.PaddingRight = UDim.new(0, 8)
    local WebhookNameBoxStroke = Instance.new("UIStroke", WebhookNameBox)
    WebhookNameBoxStroke.Color = Theme.Accent
    WebhookNameBoxStroke.Transparency = 0.86

    WebhookNameBox.FocusLost:Connect(function()
        local name = WebhookNameBox.Text:gsub("^%s*", ""):gsub("%s*$", "")
        if name == "" then
            name = "V7BX Hub Notifier"
            WebhookNameBox.Text = name
        end
        Config.webhookName = name
        saveConfig()
        notify("Webhook name updated", Theme.Dim)
    end)

    -- Webhook URL TextBox
    local WebhookBox = Instance.new("TextBox", WebhookCard)
    WebhookBox.Size = UDim2.new(1, -20, 0, 24)
    WebhookBox.Position = UDim2.new(0, 10, 0, 56)
    WebhookBox.BackgroundColor3 = Theme.Card2
    WebhookBox.BorderSizePixel = 0
    WebhookBox.ClearTextOnFocus = false
    WebhookBox.PlaceholderText = "Paste Discord Webhook URL Here"
    WebhookBox.Text = Config.webhookUrl or ""
    WebhookBox.Font = Enum.Font.GothamMedium
    WebhookBox.TextSize = 9
    WebhookBox.TextColor3 = Theme.Text
    WebhookBox.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", WebhookBox).CornerRadius = UDim.new(0, 5)
    
    local WebhookBoxPadding = Instance.new("UIPadding", WebhookBox)
    WebhookBoxPadding.PaddingLeft = UDim.new(0, 8)
    WebhookBoxPadding.PaddingRight = UDim.new(0, 8)
    
    local WebhookBoxStroke = Instance.new("UIStroke", WebhookBox)
    WebhookBoxStroke.Color = Theme.Accent
    WebhookBoxStroke.Transparency = 0.86

    WebhookBox.FocusLost:Connect(function()
        local url = WebhookBox.Text:gsub("%s+", "")
        if url:find("https://discord.com/api/webhooks/") or url:find("https://discordapp.com/api/webhooks/") then
            Config.webhookUrl = url
            saveConfig()
            notify("Webhook URL updated", Theme.Dim)
        else
            if url == "" then
                Config.webhookUrl = ""
                saveConfig()
                notify("Webhook cleared", Theme.Dim)
            else
                WebhookBox.Text = Config.webhookUrl or ""
                notify("Invalid Discord Webhook URL", Theme.Danger)
            end
        end
    end)

    -- Dragging Logic
    local function isPressInput(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
    end

    local function isMoveInput(input)
        return input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
    end

    local dragging, dragStart, startPos = false, nil, nil

    local function beginDrag(input)
        if dragging or not isPressInput(input) or UserInputService:GetFocusedTextBox() then
            return
        end

        dragging = true
        dragStart = input.Position
        startPos = Main.AbsolutePosition

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                saveFreePosition(true)
            end
        end)
    end

    for _, handle in ipairs({TopBar, Logo, LogoText, Title, SubTitle}) do
        handle.Active = true
        handle.InputBegan:Connect(beginDrag)
    end

    UserInputService.InputChanged:Connect(function(input)
        if dragging and isMoveInput(input) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(0, startPos.X + delta.X, 0, startPos.Y + delta.Y)
            saveFreePosition(false)
        end
    end)

    local FullSize = UDim2.new(0, MAIN_WIDTH, 0, MAIN_HEIGHT)
    local MiniSize = UDim2.new(0, MAIN_WIDTH, 0, MINI_HEIGHT)
    local HiddenSize = UDim2.new(0, MAIN_WIDTH, 0, HIDDEN_HEIGHT)
    local VisibilityToken = 0

    local function getOpenSize()
        return Config.minimized and MiniSize or FullSize
    end

    local function setMainVisibility(hidden)
        VisibilityToken = VisibilityToken + 1
        local token = VisibilityToken
        Config.hidden = hidden

        if hidden then
            saveConfig()
            OpenBubble.Visible = false
            local closeTween = tween(Main, TweenSoft, {Size = HiddenSize})
            closeTween.Completed:Connect(function()
                if VisibilityToken == token and Config.hidden then
                    Main.Visible = false
                    OpenBubble.Visible = true
                end
            end)
            closeTween:Play()
        else
            Main.Visible = true
            OpenBubble.Visible = false
            applyResponsiveLayout()
            Main.Size = HiddenSize
            tween(Main, TweenOpen, {Size = getOpenSize()}):Play()
            saveConfig()
        end
    end

    local function applyMinimized()
        TabBar.Visible = not Config.minimized
        Content.Visible = not Config.minimized
        Footer.Visible = not Config.minimized
        MinBtn.Text = Config.minimized and ">" or "v"
        tween(Main, TweenSoft, {Size = getOpenSize()}):Play()
        applyResponsiveLayout()
        saveConfig()
    end

    MinBtn.MouseButton1Click:Connect(function()
        Config.minimized = not Config.minimized
        applyMinimized()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        setMainVisibility(true)
    end)

    OpenBubble.MouseButton1Click:Connect(function()
        setMainVisibility(false)
        notify("UI opened", Theme.Dim)
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if UserInputService:GetFocusedTextBox() then
            return
        end

        -- Hardcoded UI show/hide on LeftControl/RightControl
        if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
            setMainVisibility(not Config.hidden)
            return
        end

        if isBindingFloat or isBindingAlign then
            return
        end

        -- FLOAT (Zero Gravity) toggle keybind
        local resolvedFloat = getInputEnum(Config.floatKeybind)
        if resolvedFloat then
            local isMatch = false
            if input.UserInputType == resolvedFloat or input.KeyCode == resolvedFloat then
                isMatch = true
            end

            if isMatch then
                _G.zeroGravityEnabled = not _G.zeroGravityEnabled
                Config.zeroGravityEnabled = _G.zeroGravityEnabled
                setToggleVisual("zeroGravityEnabled")
                saveConfig()

                if _G.zeroGravityEnabled and startZeroGravity then
                    startZeroGravity()
                elseif stopZeroGravity then
                    stopZeroGravity()
                end

                notify("FLOAT " .. (_G.zeroGravityEnabled and "ON" or "OFF"), Theme.Dim)
                return
            end
        end

        -- ALIGN CAMERA keybind
        local resolvedAlign = getInputEnum(Config.alignCameraKeybind)
        if resolvedAlign then
            local isMatch = false
            if input.UserInputType == resolvedAlign or input.KeyCode == resolvedAlign then
                isMatch = true
            end

            if isMatch then
                triggerAlignCamera()
                return
            end
        end
    end)

    -- ==================== ANIMATED WHITE ACCENTS ====================
    local whiteAccentClock = 0
    local rainbowClock = 0
    RunService.RenderStepped:Connect(function(dt)
        whiteAccentClock = (whiteAccentClock + (dt or 0.016)) % 1000

        if _G.rainbowGlowEnabled then
            rainbowClock = (rainbowClock + (dt or 0.016) * 0.1) % 1
            local col = Color3.fromHSV(rainbowClock, 1, 1)
            MainStroke.Color = col
            GlowBar.BackgroundColor3 = col
        else
            MainStroke.Color = Theme.Accent
            GlowBar.BackgroundColor3 = Theme.Accent
        end

        for i = #AnimatedWhiteGradients, 1, -1 do
            local item = AnimatedWhiteGradients[i]
            local gradient = item.Gradient
            if gradient and gradient.Parent then
                gradient.Offset = Vector2.new(((whiteAccentClock * item.Speed) % 2) - 1, 0)
            else
                table.remove(AnimatedWhiteGradients, i)
            end
        end
    end)

    -- ==================== FPS + PING COUNTER ====================
    local lastFPS = 0
    local frameCount = 0
    local lastTime = tick()
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        if tick() - lastTime >= 1 then
            lastFPS = frameCount
            frameCount = 0
            lastTime = tick()
        end
    end)

    RunService.Heartbeat:Connect(function()
        local ping = 0
        pcall(function()
            ping = math.floor(player:GetNetworkPing() * 1000)
        end)
        StatsLabel.Text = string.format("PING %03dms | FPS %02d", ping, lastFPS)
    end)

    -- ==================== FLOAT ====================
    local STEALING_ATTRIBUTE = "Stealing"
    local FLOAT_DESCENT_SPEED = -5.5
    local activeStealPrompts = {}
    local zeroGravityConnection = nil

    local function textHasSteal(value)
        local text = tostring(value or ""):lower()
        return text:find("steal", 1, true) ~= nil or text:find("سرق", 1, true) ~= nil
    end

    local function isStealPrompt(prompt)
        if not prompt then
            return false
        end

        if textHasSteal(prompt.Name) or textHasSteal(prompt.ActionText) or textHasSteal(prompt.ObjectText) then
            return true
        end

        local parent = prompt.Parent
        for _ = 1, 3 do
            if parent and textHasSteal(parent.Name) then
                return true
            end
            parent = parent and parent.Parent
        end

        return false
    end

    local function hasActiveStealPrompt()
        for prompt in pairs(activeStealPrompts) do
            if prompt and prompt.Parent then
                return true
            end
            activeStealPrompts[prompt] = nil
        end
        return false
    end

    local function isLocalPlayerStealing(character)
        if player:GetAttribute(STEALING_ATTRIBUTE) == true then
            return true
        end

        if character and character:GetAttribute(STEALING_ATTRIBUTE) == true then
            return true
        end

        return hasActiveStealPrompt()
    end

    pcall(function()
        ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
            activeStealPrompts[prompt] = nil
        end)
    end)

    local function applyLowGravity()
        if not _G.zeroGravityEnabled then
            return
        end

        local character = player.Character
        if not character or not isLocalPlayerStealing(character) then
            return
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
            return
        end

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end

        local velocity = root.AssemblyLinearVelocity
        if velocity.Y >= 0 then
            return
        end

        if velocity.Y < FLOAT_DESCENT_SPEED then
            root.AssemblyLinearVelocity = Vector3.new(velocity.X, FLOAT_DESCENT_SPEED, velocity.Z)
        end
    end

    startZeroGravity = function()
        if zeroGravityConnection then
            zeroGravityConnection:Disconnect()
        end
        zeroGravityConnection = RunService.Heartbeat:Connect(applyLowGravity)
    end

    stopZeroGravity = function()
        if zeroGravityConnection then
            zeroGravityConnection:Disconnect()
            zeroGravityConnection = nil
        end
    end

    if _G.zeroGravityEnabled then
        startZeroGravity()
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.8)
        if _G.zeroGravityEnabled then
            startZeroGravity()
        end
    end)

    -- ==================== CORE LOGIC - 91% TRIGGER ====================
    local sliderValue = math.clamp(tonumber(Config.triggerPercent) or 0.91, 0, 1)
    local manualOverride = true
    local triggerBump = false
    local activeTriggers = {}
    local sliderDragging = false

    local function formatTiming(percent)
        local value = math.floor((math.clamp(percent or 0, 0, 1) * 10000) + 0.5) / 100
        return string.format("%.2f", value)
    end

    local function parseTimingInput(text)
        local cleaned = tostring(text or "")
            :gsub("%s+", "")
            :gsub("%%", "")
            :gsub(",", ".")

        local numberValue = tonumber(cleaned)
        if not numberValue then
            return nil
        end

        if numberValue <= 1 then
            return math.clamp(numberValue, 0, 1)
        end

        return math.clamp(numberValue / 100, 0, 1)
    end

    local function setSliderVisual(percent, persist)
        percent = math.clamp(percent or sliderValue, 0, 1)
        sliderValue = percent
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        SliderKnob.Position = UDim2.new(percent, 0, 0.5, 0)
        TriggerLabel.Text = "TIMING: " .. formatTiming(percent) .. "%"

        local focused = false
        pcall(function()
            focused = TimingBox:IsFocused()
        end)
        if not focused then
            TimingBox.Text = formatTiming(percent)
        end

        if persist then
            Config.triggerPercent = percent
            saveConfig()
        end
    end

    local function updateSlider(x)
        local trackPos = SliderTrack.AbsolutePosition.X
        local trackSize = SliderTrack.AbsoluteSize.X
        local percent = math.clamp((x - trackPos) / trackSize, 0, 1)
        manualOverride = true
        setSliderVisual(percent, true)
        notify("Timing " .. formatTiming(percent) .. "%", Theme.Dim)
    end

    TimingBox.FocusLost:Connect(function()
        local percent = parseTimingInput(TimingBox.Text)
        if percent then
            manualOverride = true
            setSliderVisual(percent, true)
            notify("Timing " .. formatTiming(percent) .. "%", Theme.Dim)
        else
            setSliderVisual(sliderValue)
            notify("Invalid timing", Theme.Dim)
        end
    end)

    SliderKnob.MouseButton1Down:Connect(function()
        sliderDragging = true
    end)

    SliderTrack.InputBegan:Connect(function(input)
        if isPressInput(input) then
            sliderDragging = true
            updateSlider(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliderDragging and isMoveInput(input) then
            updateSlider(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if isPressInput(input) then
            sliderDragging = false
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not manualOverride then
            local base = 0.91
            setSliderVisual(triggerBump and (base + 0.015) or base)
        end
    end)

    lookUp58 = function()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local currentCF = camera.CFrame
        local pitch = math.rad(28.4)
        local newLookVector = Vector3.new(currentCF.LookVector.X, math.sin(pitch), currentCF.LookVector.Z)
        camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + newLookVector)
    end

    AlignButton.MouseButton1Click:Connect(function()
        triggerAlignCamera()
    end)

    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
        local details = getBrainrotDetails(prompt)
        if isStealPrompt(prompt) then
            activeStealPrompts[prompt] = true
            notify("Steal detected: " .. details.Name .. " [" .. details.Rate .. "]", Theme.Accent)
        elseif details.Owner == player.Name then
            notify("Base entry detected: " .. details.Name, Theme.Accent)
        end

        if not _G.flashEnabled and not _G.giantEnabled then
            return
        end

        if activeTriggers[prompt] then
            return
        end

        activeTriggers[prompt] = true
        local startTime = os.clock()
        local fired = false
        local duration = tonumber(prompt.HoldDuration) or 0.001
        if duration <= 0 then
            duration = 0.001
        end

        StealFill.Size = UDim2.new(0, 0, 1, 0)

        local connection
        connection = RunService.PreRender:Connect(function()
            if not prompt or not prompt.Parent then
                connection:Disconnect()
                activeTriggers[prompt] = nil
                return
            end

            local progress = math.clamp((os.clock() - startTime) / duration, 0, 1)
            StealFill.Size = UDim2.new(progress, 0, 1, 0)

            if not fired and progress >= sliderValue then
                fired = true
                connection:Disconnect()
                activeTriggers[prompt] = nil
                triggerBump = not triggerBump

                triggerFlashTP()

                notify("Prompt triggered", Theme.Dim)

                task.delay(0.25, function()
                    tween(StealFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
                        Size = UDim2.new(0, 0, 1, 0)
                    }):Play()
                end)
            end
        end)

        prompt.PromptButtonHoldEnded:Connect(function()
            if not fired then
                connection:Disconnect()
                activeTriggers[prompt] = nil
                tween(StealFill, TweenInfo.new(0.3), {
                    Size = UDim2.new(0, 0, 1, 0)
                }):Play()
            end
        end)
    end)

    ProximityPromptService.PromptTriggered:Connect(function(prompt)
        if not prompt then
            return
        end
        local details = getBrainrotDetails(prompt)
        if details.Owner == player.Name and not isStealPrompt(prompt) then
            notify("Base entry detected: " .. details.Name, Theme.Accent)

            if Config.webhookEnabled and Config.webhookUrl and Config.webhookUrl ~= "" then
                pcall(function()
                    local _rarityColor3, _rarityEmbedNum = getRarityColor(details.Rarity)
                    local _rHex = string.format("#%02X%02X%02X", round(_rarityColor3.R * 255), round(_rarityColor3.G * 255), round(_rarityColor3.B * 255))
                    local payload = {
                        username = Config.webhookName or "V7BX Hub Notifier",
                        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png",
                        embeds = {
                            {
                                title = "🏠 Stolen Item Entered Base",
                                color = _rarityEmbedNum,
                                description = "The stolen item has entered your base.",
                                image = {
                                    url = details.Image
                                },
                                fields = {
                                    {
                                        name = "👤 Owner",
                                        value = "• **" .. details.Owner .. "**",
                                        inline = true
                                    },
                                    {
                                        name = "🧾 Item",
                                        value = "• **" .. details.Name .. "**",
                                        inline = true
                                    },
                                    {
                                        name = "💎 Rarity",
                                        value = "• **" .. details.Rarity .. "** — " .. _rHex,
                                        inline = true
                                    },
                                    {
                                        name = "⚡ Rate",
                                        value = "• **" .. details.Rate .. "**",
                                        inline = true
                                    }
                                },
                                footer = {
                                    text = "V7BX Hub | discord.gg/YruWDvg7zS",
                                    icon_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
                                },
                                timestamp = DateTime.now():ToIsoDate()
                            }
                        }
                    }
                    sendWebhook(Config.webhookUrl, payload)
                end)
            end

            -- ✅ Kick لما تدخل الحيوان بيتك
            task.spawn(function()
                task.wait(1)
                pcall(function()
                    player:Kick("V7BX Hub - Stolen item entered base!")
                end)
            end)
        end
    end)

    if Config.hidden then
        Main.Visible = false
        OpenBubble.Visible = true
        Main.Size = HiddenSize
    else
        Main.Visible = true
        OpenBubble.Visible = false
        applyResponsiveLayout()
        applyMinimized()
        task.defer(function()
            Main.Size = HiddenSize
            tween(Main, TweenOpen, {Size = getOpenSize()}):Play()
        end)
    end

    setSliderVisual(sliderValue)
    -- ==================== AUTO KICK + WEBHOOK (you stole) ====================
    do
        local akKicked = false
        local akConnections = {}
        local WEBHOOK_URL = Config.webhookUrl or ""

        local function akHasKeyword(text)
            if typeof(text) ~= "string" then return false end
            return string.find(string.lower(text), "you stole") ~= nil
        end

        local function akStripTags(text)
            return tostring(text or ""):gsub("<[^>]+>", ""):gsub("^%s*", ""):gsub("%s*$", "")
        end

        local function akGetAnimalName(text)
            local clean = akStripTags(text)
            local name = clean:match("[Yy]ou stole%s+(.+)") or clean:match("[Yy]ou stole(.+)")
            if name then
                name = name:gsub("^%s*", ""):gsub("%s*$", "")
            end
            return name or "Unknown"
        end

        local function akGetRarity(name)
            local n = name:lower()
            if n:find("rainbow") then return "Rainbow"
            elseif n:find("radioactive") then return "Radioactive"
            elseif n:find("cyber") then return "Cyber"
            elseif n:find("diamond") then return "Diamond"
            elseif n:find("galaxy") then return "Galaxy"
            elseif n:find("lava") then return "Lava"
            elseif n:find("candy") then return "Candy"
            elseif n:find("cursed") then return "Cursed"
            elseif n:find("bloodroot") then return "Bloodroot"
            elseif n:find("yin") or n:find("yang") then return "Yin Yang"
            elseif n:find("gold") then return "Gold"
            else return "Normal" end
        end

        local function akSendAndKick(detectedText)
            if akKicked then return end
            akKicked = true

            -- يرسل دائماً بغض النظر عن Auto Kick
            pcall(function()
                if not Config.webhookUrl or Config.webhookUrl == "" then return end
                local animalName = akGetAnimalName(detectedText)
                local rarity = akGetRarity(animalName)
                local _rarityColor3, _rarityEmbedNum = getRarityColor(rarity)
                local _rHex = string.format("#%02X%02X%02X",
                    round(_rarityColor3.R * 255),
                    round(_rarityColor3.G * 255),
                    round(_rarityColor3.B * 255))

                local rarityEmoji = {
                    Rainbow = "🌈", Radioactive = "☢️", Cyber = "🤖",
                    Diamond = "💎", Galaxy = "🌌", Lava = "🌋",
                    Candy = "🍭", Cursed = "💀", Bloodroot = "🩸",
                    ["Yin Yang"] = "☯️", Gold = "🥇", Normal = "⬜"
                }
                local emoji = rarityEmoji[rarity] or "❓"

                local payload = {
                    username = Config.webhookName or "V7BX Hub Notifier",
                    avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png",
                    embeds = {{
                        title = "🚨  سرقة ناجحة — V7BX Hub",
                        description = "> تم اكتشاف سرقة ناجحة وإدخال الحيوان إلى البيت.",
                        color = _rarityEmbedNum,
                        fields = {
                            {
                                name = "👤  اللاعب",
                                value = "```" .. player.Name .. "```" ..
                                        "🪪 **DisplayName:** " .. player.DisplayName .. "\n" ..
                                        "🆔 **ID:** `" .. tostring(player.UserId) .. "`",
                                inline = false
                            },
                            {
                                name = emoji .. "  الحيوان المسروق",
                                value = "```" .. animalName .. "```",
                                inline = true
                            },
                            {
                                name = "💎  الـ Rarity",
                                value = emoji .. " **" .. rarity .. "**\n🎨 `" .. _rHex .. "`",
                                inline = true
                            },
                            {
                                name = "🔧  Auto Kick",
                                value = Config.autoKickEnabled and "✅ **مفعّل**" or "❌ **معطّل**",
                                inline = true
                            },
                            {
                                name = "🧪  Giant Potion",
                                value = _G.giantEnabled and "✅ **مفعّل**" or "❌ **معطّل**",
                                inline = true
                            },
                            {
                                name = "🪂  Float",
                                value = _G.zeroGravityEnabled and "✅ **مفعّل**" or "❌ **معطّل**",
                                inline = true
                            }
                        },
                        footer = {
                            text = "V7BX Hub • discord.gg/YruWDvg7zS",
                            icon_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=150&height=150&format=png"
                        },
                        timestamp = DateTime.now():ToIsoDate()
                    }}
                }
                sendWebhook(Config.webhookUrl, payload)
            end)

            -- Kick فوري، بس لو ON
            if Config.autoKickEnabled then
                pcall(function()
                    player:Kick("V7BX Hub - Stolen item entered base!")
                end)
            end
        end

        local function akWatchObject(obj)
            if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
            if akHasKeyword(obj.Text) then
                akSendAndKick(obj.Text)
                return
            end
            local conn = obj:GetPropertyChangedSignal("Text"):Connect(function()
                if akHasKeyword(obj.Text) then
                    akSendAndKick(obj.Text)
                end
            end)
            table.insert(akConnections, conn)
        end

        local function akWatchGui(gui)
            for _, obj in ipairs(gui:GetDescendants()) do akWatchObject(obj) end
            local conn = gui.DescendantAdded:Connect(function(desc) akWatchObject(desc) end)
            table.insert(akConnections, conn)
        end

        for _, gui in ipairs(playerGui:GetChildren()) do akWatchGui(gui) end
        table.insert(akConnections, playerGui.ChildAdded:Connect(function(gui) akWatchGui(gui) end))

        print("[V7BX] Auto Kick + Webhook شغال ✅")
    end
    -- ==================== END AUTO KICK ====================

    notify("V7BX GUI loaded", Theme.Dim)
    print("V7BX Flash TP Loaded | Credits: V7BX | Trigger 91%")
end, function(err)
    local traceback = debug and debug.traceback
    return traceback and traceback(err) or tostring(err)
end)

if not __NABOLI_OK then
    __NABOLI_ENV.__NABOLI_FLASH_TP_RUNNING = false
    warn("[V7BX] Flash TP load failed: " .. tostring(__NABOLI_ERR))
end
