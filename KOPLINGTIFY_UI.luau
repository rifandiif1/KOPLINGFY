-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - MODULAR UI TEMPLATE (KOPLINGTIFY_UI.luau)
-- =================================================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local UIModule = {}

function UIModule.Create(config)
    config = config or {}
    local player = Players.LocalPlayer
    if not player then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        player = Players.LocalPlayer
    end

    local subPalette = config.SubPalette or {
        {Name = "Putih",  Color = Color3.fromRGB(255, 255, 255)},
        {Name = "Hijau",  Color = Color3.fromRGB(45, 235, 135)},
        {Name = "Kuning", Color = Color3.fromRGB(255, 220, 65)},
        {Name = "Cyan",   Color = Color3.fromRGB(80, 225, 255)},
        {Name = "Pink",   Color = Color3.fromRGB(255, 135, 195)},
        {Name = "Ungu",   Color = Color3.fromRGB(195, 145, 255)}
    }

    local FULL_SIZE = UDim2.new(0, 350, 0, 350)
    local ISLAND_SIZE = UDim2.new(0, 290, 0, 48)

    local function getSafeParent()
        local okGethui, hui = pcall(function() return gethui and gethui() end)
        if okGethui and hui then return hui end
        local okCore, core = pcall(function() return game:GetService("CoreGui") end)
        if okCore and core then return core end
        return player:WaitForChild("PlayerGui")
    end

    pcall(function() if gethui and gethui():FindFirstChild("KoplingtifyLite") then gethui().KoplingtifyLite:Destroy() end end)
    pcall(function() if game:GetService("CoreGui"):FindFirstChild("KoplingtifyLite") then game:GetService("CoreGui").KoplingtifyLite:Destroy() end end)
    pcall(function()
        local pg = player:FindFirstChild("PlayerGui")
        if pg and pg:FindFirstChild("KoplingtifyLite") then pg.KoplingtifyLite:Destroy() end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "KoplingtifyLite"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9999
    gui.Parent = getSafeParent()

    local function makeLabel(parent, name, pos, size, text, fontSize, color)
        local obj = Instance.new("TextLabel")
        obj.Name = name
        obj.Position = pos
        obj.Size = size
        obj.BackgroundTransparency = 1
        obj.Font = Enum.Font.Gotham
        obj.TextSize = fontSize
        obj.TextColor3 = color or Color3.fromRGB(240, 240, 240)
        obj.Text = text
        obj.TextWrapped = true
        obj.Parent = parent
        return obj
    end

    local function makeButton(parent, text, pos, size, bgColor)
        local b = Instance.new("TextButton")
        b.Position = pos
        b.Size = size
        b.BackgroundColor3 = bgColor or Color3.fromRGB(36, 41, 50)
        b.TextColor3 = Color3.fromRGB(245, 245, 245)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 11
        b.Text = text
        b.AutoButtonColor = true
        b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end

    local function makeHoldable(btn, callback)
        local holding = false
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                holding = true
                callback()
                task.wait(0.3)
                while holding and gui.Parent do
                    callback()
                    task.wait(0.05)
                end
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                holding = false
            end
        end)
        btn.MouseLeave:Connect(function() holding = false end)
    end

    local function enableDrag(dragHandle, targetFrame, checkLockFn)
        local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
        dragHandle.InputBegan:Connect(function(input)
            if checkLockFn and checkLockFn() then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = targetFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        dragHandle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                if checkLockFn and checkLockFn() then
                    dragging = false
                    return
                end
                local delta = input.Position - dragStart
                targetFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- Frame Utama
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = FULL_SIZE
    main.Position = UDim2.new(0.5, -175, 0.08, 0)
    main.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    main.BackgroundTransparency = 0.04
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Active = true
    main.Parent = gui
    local mainCorner = Instance.new("UICorner", main)
    mainCorner.CornerRadius = UDim.new(0, 16)

    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = Color3.fromRGB(255, 255, 255)
    mainStroke.Thickness = 1.6
    mainStroke.Transparency = 0.15

    local strokeGrad = Instance.new("UIGradient", mainStroke)
    strokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 230, 135)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 160, 250)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(175, 110, 255))
    })
    strokeGrad.Rotation = 35

    -- Toast Banner
    local toastBanner = Instance.new("Frame")
    toastBanner.Name = "ToastBanner"
    toastBanner.Size = UDim2.new(1, -24, 0, 26)
    toastBanner.Position = UDim2.new(0, 12, 0, -32)
    toastBanner.BackgroundColor3 = Color3.fromRGB(28, 165, 95)
    toastBanner.BorderSizePixel = 0
    toastBanner.ZIndex = 30
    toastBanner.Parent = main
    Instance.new("UICorner", toastBanner).CornerRadius = UDim.new(0, 8)

    local toastText = makeLabel(toastBanner, "ToastText", UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), "", 11, Color3.fromRGB(255, 255, 255))
    toastText.Font = Enum.Font.GothamBold
    toastText.ZIndex = 31

    -- Floating Pill
    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "FloatingToggle"
    floatBtn.Size = UDim2.new(0, 50, 0, 50)
    floatBtn.Position = UDim2.new(0, 20, 0.45, 0)
    floatBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
    floatBtn.TextColor3 = Color3.fromRGB(35, 230, 135)
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.TextSize = 22
    floatBtn.Text = "🎵"
    floatBtn.Visible = false
    floatBtn.Active = true
    floatBtn.Parent = gui
    Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
    local floatStroke = Instance.new("UIStroke", floatBtn)
    floatStroke.Color = Color3.fromRGB(35, 230, 135)
    floatStroke.Thickness = 2

    -- Subtitle HUD Overlay
    local subtitleFrame = Instance.new("Frame")
    subtitleFrame.Name = "SubtitleOverlay"
    subtitleFrame.Size = UDim2.new(0, 520, 0, 86)
    subtitleFrame.Position = UDim2.new(0.5, -260, 0.80, 0)
    subtitleFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
    subtitleFrame.BackgroundTransparency = 1
    subtitleFrame.BorderSizePixel = 0
    subtitleFrame.Visible = false
    subtitleFrame.Active = true
    subtitleFrame.Parent = gui
    Instance.new("UICorner", subtitleFrame).CornerRadius = UDim.new(0, 12)

    local subBoxStroke = Instance.new("UIStroke", subtitleFrame)
    subBoxStroke.Color = Color3.fromRGB(45, 235, 135)
    subBoxStroke.Thickness = 1.2
    subBoxStroke.Transparency = 1

    local subMainText = Instance.new("TextLabel")
    subMainText.Name = "SubCurrent"
    subMainText.Size = UDim2.new(1, -16, 0, 34)
    subMainText.Position = UDim2.new(0, 8, 0, 4)
    subMainText.BackgroundTransparency = 1
    subMainText.Font = Enum.Font.GothamBold
    subMainText.TextSize = 20
    subMainText.TextColor3 = subPalette[1].Color
    subMainText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    subMainText.TextStrokeTransparency = 0.08
    subMainText.TextWrapped = true
    subMainText.Text = "Menunggu lagu..."
    subMainText.Parent = subtitleFrame

    local subTransText = Instance.new("TextLabel")
    subTransText.Name = "SubTrans"
    subTransText.Size = UDim2.new(1, -16, 0, 22)
    subTransText.Position = UDim2.new(0, 8, 0, 38)
    subTransText.BackgroundTransparency = 1
    subTransText.Font = Enum.Font.GothamSemibold
    subTransText.TextSize = 16
    subTransText.TextColor3 = Color3.fromRGB(115, 245, 175)
    subTransText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    subTransText.TextStrokeTransparency = 0.12
    subTransText.TextWrapped = true
    subTransText.Text = ""
    subTransText.Parent = subtitleFrame

    local subNextText = Instance.new("TextLabel")
    subNextText.Name = "SubNext"
    subNextText.Size = UDim2.new(1, -16, 0, 20)
    subNextText.Position = UDim2.new(0, 8, 0, 62)
    subNextText.BackgroundTransparency = 1
    subNextText.Font = Enum.Font.Gotham
    subNextText.TextSize = 14
    subNextText.TextColor3 = Color3.fromRGB(175, 185, 195)
    subNextText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    subNextText.TextStrokeTransparency = 0.25
    subNextText.TextWrapped = true
    subNextText.Text = ""
    subNextText.Parent = subtitleFrame

    -- Top Header Bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
    topBar.BorderSizePixel = 0
    topBar.Active = true
    topBar.Parent = main
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 16)

    local titleHeader = makeLabel(topBar, "Header", UDim2.new(0, 12, 0, 3), UDim2.new(1, -205, 0, 18), "KOPLINGTIFY  •  PRO", 12, Color3.fromRGB(40, 235, 140))
    titleHeader.Font = Enum.Font.GothamBold
    titleHeader.TextXAlignment = Enum.TextXAlignment.Left

    local status = makeLabel(topBar, "Status", UDim2.new(0, 12, 0, 20), UDim2.new(1, -205, 0, 16), "Putar musik atau cari lirik...", 9, Color3.fromRGB(155, 165, 178))
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextTruncate = Enum.TextTruncate.AtEnd

    local orbitBtn = makeButton(topBar, "🎥", UDim2.new(1, -192, 0, 6), UDim2.new(0, 28, 0, 28), Color3.fromRGB(36, 42, 52))
    local subToggleBtn = makeButton(topBar, "📺", UDim2.new(1, -160, 0, 6), UDim2.new(0, 28, 0, 28), Color3.fromRGB(36, 42, 52))
    local muteBtn = makeButton(topBar, "🔊", UDim2.new(1, -128, 0, 6), UDim2.new(0, 28, 0, 28), Color3.fromRGB(36, 42, 52))
    local pillModeBtn = makeButton(topBar, "🎵", UDim2.new(1, -96, 0, 6), UDim2.new(0, 28, 0, 28), Color3.fromRGB(36, 42, 52))
    local minBtn = makeButton(topBar, "—", UDim2.new(1, -64, 0, 6), UDim2.new(0, 28, 0, 28), Color3.fromRGB(36, 42, 52))
    local closeBtn = makeButton(topBar, "×", UDim2.new(1, -32, 0, 6), UDim2.new(0, 26, 0, 28), Color3.fromRGB(135, 42, 48))
    closeBtn.TextSize = 15

    -- Dynamic Island Capsule
    local islandBar = Instance.new("Frame")
    islandBar.Name = "DynamicIsland"
    islandBar.Size = UDim2.new(1, 0, 1, 0)
    islandBar.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
    islandBar.BorderSizePixel = 0
    islandBar.Visible = false
    islandBar.Active = true
    islandBar.Parent = main
    Instance.new("UICorner", islandBar).CornerRadius = UDim.new(1, 0)

    local islandDisc = makeLabel(islandBar, "Disc", UDim2.new(0, 10, 0.5, -14), UDim2.new(0, 28, 0, 28), "💿", 18, Color3.fromRGB(45, 235, 135))
    local islandLyric = makeLabel(islandBar, "IslandLyric", UDim2.new(0, 42, 0, 4), UDim2.new(1, -110, 0, 22), "Menunggu lagu...", 12, Color3.fromRGB(255, 255, 255))
    islandLyric.Font = Enum.Font.GothamBold
    islandLyric.TextXAlignment = Enum.TextXAlignment.Left
    islandLyric.TextTruncate = Enum.TextTruncate.AtEnd

    local islandTrans = makeLabel(islandBar, "IslandTrans", UDim2.new(0, 42, 0, 23), UDim2.new(1, -110, 0, 16), "", 10, Color3.fromRGB(105, 235, 165))
    islandTrans.TextXAlignment = Enum.TextXAlignment.Left
    islandTrans.TextTruncate = Enum.TextTruncate.AtEnd

    local islandExpandBtn = makeButton(islandBar, "＋", UDim2.new(1, -62, 0.5, -13), UDim2.new(0, 26, 0, 26), Color3.fromRGB(35, 150, 90))
    local islandPillBtn = makeButton(islandBar, "🎵", UDim2.new(1, -32, 0.5, -13), UDim2.new(0, 26, 0, 26), Color3.fromRGB(36, 42, 52))

    local islandProgBg = Instance.new("Frame")
    islandProgBg.Position = UDim2.new(0, 24, 1, -4)
    islandProgBg.Size = UDim2.new(1, -48, 0, 2)
    islandProgBg.BackgroundColor3 = Color3.fromRGB(40, 46, 58)
    islandProgBg.BorderSizePixel = 0
    islandProgBg.Parent = islandBar
    Instance.new("UICorner", islandProgBg).CornerRadius = UDim.new(1, 0)

    local islandProgFill = Instance.new("Frame")
    islandProgFill.Size = UDim2.new(0, 0, 1, 0)
    islandProgFill.BackgroundColor3 = Color3.fromRGB(40, 235, 140)
    islandProgFill.BorderSizePixel = 0
    islandProgFill.Parent = islandProgBg
    Instance.new("UICorner", islandProgFill).CornerRadius = UDim.new(1, 0)

    -- 4-Tab Navigation Body
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Position = UDim2.new(0, 0, 0, 42)
    body.Size = UDim2.new(1, 0, 1, -42)
    body.BackgroundTransparency = 1
    body.Parent = main

    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Position = UDim2.new(0, 12, 0, 2)
    tabBar.Size = UDim2.new(1, -24, 0, 32)
    tabBar.BackgroundColor3 = Color3.fromRGB(23, 27, 35)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = body
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 9)

    local tabBtn1 = makeButton(tabBar, "🎤 Lirik", UDim2.new(0, 3, 0, 3), UDim2.new(0.24, -3, 1, -6), Color3.fromRGB(35, 155, 95))
    local tabBtn2 = makeButton(tabBar, "🔍 Sync", UDim2.new(0.24, 2, 0, 3), UDim2.new(0.25, -3, 1, -6), Color3.fromRGB(30, 35, 44))
    local tabBtn3 = makeButton(tabBar, "📍 User", UDim2.new(0.49, 2, 0, 3), UDim2.new(0.25, -3, 1, -6), Color3.fromRGB(30, 35, 44))
    local tabBtn4 = makeButton(tabBar, "🛠️ Sub", UDim2.new(0.74, 2, 0, 3), UDim2.new(0.26, -5, 1, -6), Color3.fromRGB(30, 35, 44))

    local page1 = Instance.new("Frame", body)
    page1.Name = "PageLyrics"
    page1.Position = UDim2.new(0, 0, 0, 38)
    page1.Size = UDim2.new(1, 0, 1, -38)
    page1.BackgroundTransparency = 1

    local page2 = Instance.new("Frame", body)
    page2.Name = "PageSearchSync"
    page2.Position = UDim2.new(0, 0, 0, 38)
    page2.Size = UDim2.new(1, 0, 1, -38)
    page2.BackgroundTransparency = 1
    page2.Visible = false

    local page3 = Instance.new("Frame", body)
    page3.Name = "PageUserLocator"
    page3.Position = UDim2.new(0, 0, 0, 38)
    page3.Size = UDim2.new(1, 0, 1, -38)
    page3.BackgroundTransparency = 1
    page3.Visible = false

    local page4 = Instance.new("Frame", body)
    page4.Name = "PageExtraSub"
    page4.Position = UDim2.new(0, 0, 0, 38)
    page4.Size = UDim2.new(1, 0, 1, -38)
    page4.BackgroundTransparency = 1
    page4.Visible = false

    local function switchTab(tabIndex)
        page1.Visible = (tabIndex == 1)
        page2.Visible = (tabIndex == 2)
        page3.Visible = (tabIndex == 3)
        page4.Visible = (tabIndex == 4)
        tabBtn1.BackgroundColor3 = (tabIndex == 1) and Color3.fromRGB(35, 155, 95) or Color3.fromRGB(30, 35, 44)
        tabBtn2.BackgroundColor3 = (tabIndex == 2) and Color3.fromRGB(35, 155, 95) or Color3.fromRGB(30, 35, 44)
        tabBtn3.BackgroundColor3 = (tabIndex == 3) and Color3.fromRGB(35, 155, 95) or Color3.fromRGB(30, 35, 44)
        tabBtn4.BackgroundColor3 = (tabIndex == 4) and Color3.fromRGB(35, 155, 95) or Color3.fromRGB(30, 35, 44)
    end

    tabBtn1.MouseButton1Click:Connect(function() switchTab(1) end)
    tabBtn2.MouseButton1Click:Connect(function() switchTab(2) end)
    tabBtn3.MouseButton1Click:Connect(function() switchTab(3) end)
    tabBtn4.MouseButton1Click:Connect(function() switchTab(4) end)

    -- Tab 1: Lirik, Romanization, Translate & Progress Bar
    local lyricCard = Instance.new("TextButton")
    lyricCard.Name = "LyricCard"
    lyricCard.Position = UDim2.new(0, 12, 0, 4)
    lyricCard.Size = UDim2.new(1, -24, 0, 154)
    lyricCard.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
    lyricCard.BorderSizePixel = 0
    lyricCard.Text = ""
    lyricCard.AutoButtonColor = false
    lyricCard.ClipsDescendants = true
    lyricCard.Parent = page1
    Instance.new("UICorner", lyricCard).CornerRadius = UDim.new(0, 12)
    local cardStroke = Instance.new("UIStroke", lyricCard)
    cardStroke.Color = Color3.fromRGB(42, 50, 64)
    cardStroke.Thickness = 1

    local prevLine = makeLabel(lyricCard, "Previous", UDim2.new(0, 10, 0, 4), UDim2.new(1, -20, 0, 18), "", 11, Color3.fromRGB(130, 140, 155))
    local currentLine = makeLabel(lyricCard, "Current", UDim2.new(0, 10, 0, 23), UDim2.new(1, -20, 0, 44), "Menunggu lagu...", 15, Color3.fromRGB(255, 255, 255))
    currentLine.Font = Enum.Font.GothamBold

    local romLine = makeLabel(lyricCard, "Romanization", UDim2.new(0, 10, 0, 68), UDim2.new(1, -20, 0, 22), "", 11, Color3.fromRGB(255, 215, 90))
    romLine.Font = Enum.Font.GothamSemibold

    local transLine = makeLabel(lyricCard, "Translation", UDim2.new(0, 10, 0, 92), UDim2.new(1, -20, 0, 32), "", 12, Color3.fromRGB(80, 235, 155))
    transLine.Font = Enum.Font.GothamSemibold

    local nextLine = makeLabel(lyricCard, "Next", UDim2.new(0, 10, 0, 128), UDim2.new(1, -20, 0, 18), "", 11, Color3.fromRGB(130, 140, 155))

    local timeCurrentLbl = makeLabel(page1, "TimeCurrent", UDim2.new(0, 12, 0, 162), UDim2.new(0, 42, 0, 16), "00:00", 10, Color3.fromRGB(165, 175, 185))
    timeCurrentLbl.TextXAlignment = Enum.TextXAlignment.Left

    local progBarBg = Instance.new("Frame")
    progBarBg.Name = "ProgressBarBg"
    progBarBg.Position = UDim2.new(0, 56, 0, 168)
    progBarBg.Size = UDim2.new(1, -112, 0, 5)
    progBarBg.BackgroundColor3 = Color3.fromRGB(36, 42, 54)
    progBarBg.BorderSizePixel = 0
    progBarBg.Parent = page1
    Instance.new("UICorner", progBarBg).CornerRadius = UDim.new(1, 0)

    local progBarFill = Instance.new("Frame")
    progBarFill.Name = "Fill"
    progBarFill.Size = UDim2.new(0, 0, 1, 0)
    progBarFill.BackgroundColor3 = Color3.fromRGB(40, 230, 135)
    progBarFill.BorderSizePixel = 0
    progBarFill.Parent = progBarBg
    Instance.new("UICorner", progBarFill).CornerRadius = UDim.new(1, 0)

    local timeTotalLbl = makeLabel(page1, "TimeTotal", UDim2.new(1, -54, 0, 162), UDim2.new(0, 42, 0, 16), "00:00", 10, Color3.fromRGB(165, 175, 185))
    timeTotalLbl.TextXAlignment = Enum.TextXAlignment.Right

    local chatBtn = makeButton(page1, "💬 Auto-Chat: OFF", UDim2.new(0, 12, 0, 184), UDim2.new(0, 158, 0, 34), Color3.fromRGB(36, 41, 50))
    local chatModeBtn = makeButton(page1, "🗣️ Chat: Asli/Rom", UDim2.new(0, 176, 0, 184), UDim2.new(0, 162, 0, 34), Color3.fromRGB(45, 52, 65))

    local transToggleBtn = makeButton(page1, "🌍 Indo: ON", UDim2.new(0, 12, 0, 224), UDim2.new(0, 104, 0, 34), Color3.fromRGB(30, 145, 90))
    local romToggleBtn = makeButton(page1, "🔤 Latin: ON", UDim2.new(0, 122, 0, 224), UDim2.new(0, 104, 0, 34), Color3.fromRGB(185, 135, 35))
    local filterBtn = makeButton(page1, "🛡 Sensor: ON", UDim2.new(0, 232, 0, 224), UDim2.new(0, 106, 0, 34), Color3.fromRGB(30, 145, 90))

    -- Tab 2: Cari Lirik & Sinkronisasi
    local searchBox = Instance.new("TextBox")
    searchBox.Position = UDim2.new(0, 12, 0, 6)
    searchBox.Size = UDim2.new(1, -110, 0, 34)
    searchBox.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    searchBox.TextColor3 = Color3.new(1, 1, 1)
    searchBox.PlaceholderColor3 = Color3.fromRGB(145, 152, 162)
    searchBox.PlaceholderText = "Cari judul lagu / artis..."
    searchBox.ClearTextOnFocus = false
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 12
    searchBox.Text = ""
    searchBox.Parent = page2
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 8)

    local clearSearchBtn = makeButton(page2, "×", UDim2.new(1, -94, 0, 6), UDim2.new(0, 26, 0, 34), Color3.fromRGB(48, 54, 66))
    clearSearchBtn.TextSize = 14

    local searchBtn = makeButton(page2, "CARI", UDim2.new(1, -64, 0, 6), UDim2.new(0, 52, 0, 34), Color3.fromRGB(35, 160, 95))

    local resultsFrame = Instance.new("ScrollingFrame")
    resultsFrame.Position = UDim2.new(0, 12, 0, 46)
    resultsFrame.Size = UDim2.new(1, -24, 0, 114)
    resultsFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
    resultsFrame.BorderSizePixel = 0
    resultsFrame.ScrollBarThickness = 5
    resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    resultsFrame.Parent = page2
    Instance.new("UICorner", resultsFrame).CornerRadius = UDim.new(0, 9)

    local resultLayout = Instance.new("UIListLayout", resultsFrame)
    resultLayout.Padding = UDim.new(0, 4)
    resultLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local syncInfo = makeLabel(page2, "SyncInfo", UDim2.new(0, 12, 0, 166), UDim2.new(1, -24, 0, 18), "Kecepatan: 1.00x   •   Offset: +0.00s", 11, Color3.fromRGB(40, 235, 140))
    syncInfo.TextXAlignment = Enum.TextXAlignment.Center

    local slowerBtn = makeButton(page2, "−", UDim2.new(0, 12, 0, 188), UDim2.new(0, 40, 0, 32))
    slowerBtn.TextSize = 16
    local speedBtn = makeButton(page2, "1.00x", UDim2.new(0, 56, 0, 188), UDim2.new(0, 70, 0, 32))
    local fasterBtn = makeButton(page2, "+", UDim2.new(0, 130, 0, 188), UDim2.new(0, 40, 0, 32))
    fasterBtn.TextSize = 16

    local offsetBackBtn = makeButton(page2, "−0.25s", UDim2.new(0, 178, 0, 188), UDim2.new(0, 76, 0, 32))
    local offsetForwardBtn = makeButton(page2, "+0.25s", UDim2.new(0, 260, 0, 188), UDim2.new(0, 78, 0, 32))

    local resetSyncBtn = makeButton(page2, "🔄 RESET & AUTO-SYNC DURASI LAGU", UDim2.new(0, 12, 0, 226), UDim2.new(1, -24, 0, 32), Color3.fromRGB(48, 58, 72))

    -- Tab 3: Cari User & Pelacak Lokasi
    local userSearchBox = Instance.new("TextBox")
    userSearchBox.Position = UDim2.new(0, 12, 0, 6)
    userSearchBox.Size = UDim2.new(1, -110, 0, 34)
    userSearchBox.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    userSearchBox.TextColor3 = Color3.new(1, 1, 1)
    userSearchBox.PlaceholderColor3 = Color3.fromRGB(145, 152, 162)
    userSearchBox.PlaceholderText = "Filter nama / username pemain..."
    userSearchBox.ClearTextOnFocus = false
    userSearchBox.Font = Enum.Font.Gotham
    userSearchBox.TextSize = 12
    userSearchBox.Text = ""
    userSearchBox.Parent = page3
    Instance.new("UICorner", userSearchBox).CornerRadius = UDim.new(0, 8)

    local clearUserBtn = makeButton(page3, "×", UDim2.new(1, -94, 0, 6), UDim2.new(0, 26, 0, 34), Color3.fromRGB(48, 54, 66))
    clearUserBtn.TextSize = 14

    local refreshUserBtn = makeButton(page3, "🔄", UDim2.new(1, -64, 0, 6), UDim2.new(0, 52, 0, 34), Color3.fromRGB(45, 130, 200))
    refreshUserBtn.TextSize = 14

    local userListFrame = Instance.new("ScrollingFrame")
    userListFrame.Position = UDim2.new(0, 12, 0, 46)
    userListFrame.Size = UDim2.new(1, -24, 0, 168)
    userListFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
    userListFrame.BorderSizePixel = 0
    userListFrame.ScrollBarThickness = 5
    userListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    userListFrame.Parent = page3
    Instance.new("UICorner", userListFrame).CornerRadius = UDim.new(0, 9)

    local userListLayout = Instance.new("UIListLayout", userListFrame)
    userListLayout.Padding = UDim.new(0, 4)
    userListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local stopTrackBtn = makeButton(page3, "❌ Matikan Pelacak Lokasi", UDim2.new(0, 12, 0, 222), UDim2.new(0, 168, 0, 34), Color3.fromRGB(125, 45, 52))
    local tpTrackBtn = makeButton(page3, "⚡ Teleport ke User", UDim2.new(0, 186, 0, 222), UDim2.new(0, 152, 0, 34), Color3.fromRGB(45, 145, 95))

    -- Tab 4: Ekstra (NoClip, Tembok, Orbit) & Pengaturan Subtitle
    local noclipBtn = makeButton(page4, "👻 NoClip: OFF", UDim2.new(0, 12, 0, 6), UDim2.new(0, 104, 0, 32), Color3.fromRGB(36, 41, 50))
    local wallViewBtn = makeButton(page4, "🧱 Tembok: OFF", UDim2.new(0, 122, 0, 6), UDim2.new(0, 104, 0, 32), Color3.fromRGB(36, 41, 50))
    local orbitCfgBtn = makeButton(page4, "⚙ Set Orbit", UDim2.new(0, 232, 0, 6), UDim2.new(0, 106, 0, 32), Color3.fromRGB(52, 44, 72))

    local subCfgCard = Instance.new("Frame")
    subCfgCard.Position = UDim2.new(0, 12, 0, 44)
    subCfgCard.Size = UDim2.new(1, -24, 0, 214)
    subCfgCard.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
    subCfgCard.BorderSizePixel = 0
    subCfgCard.Parent = page4
    Instance.new("UICorner", subCfgCard).CornerRadius = UDim.new(0, 10)

    local subCfgTitle = makeLabel(subCfgCard, "SubCfgTitle", UDim2.new(0, 10, 0, 4), UDim2.new(1, -20, 0, 18), "📺 KUSTOMISASI POSISI & GAYA SUBTITLE", 10, Color3.fromRGB(45, 235, 135))
    subCfgTitle.Font = Enum.Font.GothamBold
    subCfgTitle.TextXAlignment = Enum.TextXAlignment.Left

    local subBgBtn = makeButton(subCfgCard, "🎬 Kotak Cinema: OFF", UDim2.new(0, 10, 0, 126), UDim2.new(0, 148, 0, 30), Color3.fromRGB(36, 42, 52))
    local subColorBtn = makeButton(subCfgCard, "🎨 Warna: Putih", UDim2.new(0, 166, 0, 126), UDim2.new(0, 148, 0, 30), Color3.fromRGB(36, 42, 52))
    local subLockBtn = makeButton(subCfgCard, "🔓 Drag Sub: Bebas", UDim2.new(0, 10, 0, 164), UDim2.new(0, 148, 0, 30), Color3.fromRGB(36, 42, 52))
    local subResetBtn = makeButton(subCfgCard, "♻ Reset Posisi Sub", UDim2.new(0, 166, 0, 164), UDim2.new(0, 148, 0, 30), Color3.fromRGB(52, 60, 74))

    -- Panel Kustomisasi Orbit Kamera
    local orbitPanel = Instance.new("Frame")
    orbitPanel.Name = "OrbitSettingsPanel"
    orbitPanel.Size = UDim2.new(0, 280, 0, 290)
    orbitPanel.Position = UDim2.new(0.5, 182, 0.08, 0)
    orbitPanel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    orbitPanel.BorderSizePixel = 0
    orbitPanel.Visible = false
    orbitPanel.Active = true
    orbitPanel.Parent = gui
    Instance.new("UICorner", orbitPanel).CornerRadius = UDim.new(0, 12)

    local orbitStroke = Instance.new("UIStroke", orbitPanel)
    orbitStroke.Color = Color3.fromRGB(165, 105, 235)
    orbitStroke.Thickness = 1.5

    local orbitTopBar = Instance.new("Frame")
    orbitTopBar.Size = UDim2.new(1, 0, 0, 34)
    orbitTopBar.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
    orbitTopBar.BorderSizePixel = 0
    orbitTopBar.Active = true
    orbitTopBar.Parent = orbitPanel
    Instance.new("UICorner", orbitTopBar).CornerRadius = UDim.new(0, 12)

    local orbitTitle = makeLabel(orbitTopBar, "OrbitTitle", UDim2.new(0, 12, 0, 0), UDim2.new(1, -45, 1, 0), "🎥 PENGATURAN ORBIT KAMERA", 11, Color3.fromRGB(205, 165, 255))
    orbitTitle.Font = Enum.Font.GothamBold
    orbitTitle.TextXAlignment = Enum.TextXAlignment.Left

    local closeOrbitPanelBtn = makeButton(orbitTopBar, "×", UDim2.new(1, -30, 0, 4), UDim2.new(0, 24, 0, 26), Color3.fromRGB(120, 42, 48))
    closeOrbitPanelBtn.TextSize = 14

    local orbitToggleInsideBtn = makeButton(orbitPanel, "Status Orbit: OFF", UDim2.new(0, 12, 0, 42), UDim2.new(1, -24, 0, 28), Color3.fromRGB(39, 45, 55))
    local orbitDirBtn = makeButton(orbitPanel, "🔄 Arah: Kanan", UDim2.new(0, 12, 0, 244), UDim2.new(0, 124, 0, 32), Color3.fromRGB(45, 52, 64))
    local orbitResetBtn = makeButton(orbitPanel, "♻ Reset Orbit", UDim2.new(0, 144, 0, 244), UDim2.new(0, 124, 0, 32), Color3.fromRGB(65, 50, 85))

    enableDrag(topBar, main)
    enableDrag(islandBar, main)
    enableDrag(floatBtn, floatBtn)
    enableDrag(orbitTopBar, orbitPanel)

    return {
        Gui = gui,
        Main = main,
        MainCorner = mainCorner,
        FullSize = FULL_SIZE,
        IslandSize = ISLAND_SIZE,
        ToastBanner = toastBanner,
        ToastText = toastText,
        FloatBtn = floatBtn,
        SubtitleFrame = subtitleFrame,
        SubBoxStroke = subBoxStroke,
        SubMainText = subMainText,
        SubTransText = subTransText,
        SubNextText = subNextText,
        TopBar = topBar,
        Status = status,
        OrbitBtn = orbitBtn,
        SubToggleBtn = subToggleBtn,
        MuteBtn = muteBtn,
        PillModeBtn = pillModeBtn,
        MinBtn = minBtn,
        CloseBtn = closeBtn,
        IslandBar = islandBar,
        IslandDisc = islandDisc,
        IslandLyric = islandLyric,
        IslandTrans = islandTrans,
        IslandExpandBtn = islandExpandBtn,
        IslandPillBtn = islandPillBtn,
        IslandProgFill = islandProgFill,
        Body = body,
        LyricCard = lyricCard,
        CardStroke = cardStroke,
        PrevLine = prevLine,
        CurrentLine = currentLine,
        RomLine = romLine,
        TransLine = transLine,
        NextLine = nextLine,
        TimeCurrentLbl = timeCurrentLbl,
        ProgBarFill = progBarFill,
        TimeTotalLbl = timeTotalLbl,
        ChatBtn = chatBtn,
        ChatModeBtn = chatModeBtn,
        TransToggleBtn = transToggleBtn,
        RomToggleBtn = romToggleBtn,
        FilterBtn = filterBtn,
        SearchBox = searchBox,
        ClearSearchBtn = clearSearchBtn,
        SearchBtn = searchBtn,
        ResultsFrame = resultsFrame,
        ResultLayout = resultLayout,
        SyncInfo = syncInfo,
        SlowerBtn = slowerBtn,
        SpeedBtn = speedBtn,
        FasterBtn = fasterBtn,
        OffsetBackBtn = offsetBackBtn,
        OffsetForwardBtn = offsetForwardBtn,
        ResetSyncBtn = resetSyncBtn,
        UserSearchBox = userSearchBox,
        ClearUserBtn = clearUserBtn,
        RefreshUserBtn = refreshUserBtn,
        UserListFrame = userListFrame,
        UserListLayout = userListLayout,
        StopTrackBtn = stopTrackBtn,
        TpTrackBtn = tpTrackBtn,
        NoclipBtn = noclipBtn,
        WallViewBtn = wallViewBtn,
        OrbitCfgBtn = orbitCfgBtn,
        SubCfgCard = subCfgCard,
        SubBgBtn = subBgBtn,
        SubColorBtn = subColorBtn,
        SubLockBtn = subLockBtn,
        SubResetBtn = subResetBtn,
        OrbitPanel = orbitPanel,
        CloseOrbitPanelBtn = closeOrbitPanelBtn,
        OrbitToggleInsideBtn = orbitToggleInsideBtn,
        OrbitDirBtn = orbitDirBtn,
        OrbitResetBtn = orbitResetBtn,
        MakeLabel = makeLabel,
        MakeButton = makeButton,
        MakeHoldable = makeHoldable,
        EnableDrag = enableDrag
    }
end

return UIModule
