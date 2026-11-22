-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - WORLD, FLY, SPECTATE, 8-CAM & CINEMA FILTER ENGINE
-- File: KOPLINGTIFY_WORLD.luau
-- =================================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local WorldModule = {}

function WorldModule.Init(UI, showToast, Config, saveConfig)
    local player = Players.LocalPlayer
    local gui = UI.Gui
    Config = Config or {}
    saveConfig = saveConfig or function() end

    -- Referensi UI dari KOPLINGTIFY_UI
    local main = UI.Main
    local floatBtn = UI.FloatBtn
    local orbitBtn = UI.OrbitBtn
    local orbitCfgBtn = UI.OrbitCfgBtn
    local orbitPanel = UI.OrbitPanel
    local closeOrbitPanelBtn = UI.CloseOrbitPanelBtn
    local orbitToggleInsideBtn = UI.OrbitToggleInsideBtn
    local orbitDirBtn = UI.OrbitDirBtn
    local orbitResetBtn = UI.OrbitResetBtn

    local noclipBtn = UI.NoclipBtn
    local wallViewBtn = UI.WallViewBtn

    local userSearchBox = UI.UserSearchBox
    local clearUserBtn = UI.ClearUserBtn
    local refreshUserBtn = UI.RefreshUserBtn
    local userListFrame = UI.UserListFrame
    local userListLayout = UI.UserListLayout
    local stopTrackBtn = UI.StopTrackBtn
    local tpTrackBtn = UI.TpTrackBtn

    local makeLabel = UI.MakeLabel
    local makeButton = UI.MakeButton
    local makeHoldable = UI.MakeHoldable
    local enableDrag = UI.EnableDrag

    -- ======================== STATE KONFIGURASI ========================
    local isNoClipEnabled = Config.isNoClipEnabled == true
    local isWallViewEnabled = Config.isWallViewEnabled == true
    local isShiftLockEnabled = Config.isShiftLockEnabled == true
    local isShiftPinEnabled = Config.isShiftPinEnabled == true
    local isFlyEnabled = false
    local flySpeed = tonumber(Config.flySpeed) or 50

    local savedCanCollide, fadedWallParts, secretWallBoxes = {}, {}, {}
    local origOcclusionMode = player.DevCameraOcclusionMode
    local lastWallScan = 0

    -- State 8 Mode Kamera
    local camModeNames = {
        "Orbit Putar",
        "FreeCam Bebas",
        "Drone Atas",
        "First-Person",
        "Front Selfie",
        "Side Tracking",
        "Over-Shoulder",
        "Beat-Shake Cam"
    }
    local camModeShortNames = {
        "Orbit",
        "FreeCam",
        "Drone",
        "1st-POV",
        "Selfie",
        "Side-MV",
        "Shoulder",
        "BeatCam"
    }
    local camModeIndex = math.clamp(tonumber(Config.camModeIndex) or 1, 1, #camModeNames)
    local isCustomCamEnabled, wasCustomCam = false, false
    local orbitAngle = 0
    local orbitDistance = tonumber(Config.orbitDistance) or 10.0
    local orbitHeight = tonumber(Config.orbitHeight) or 3.5
    local orbitSpeed = tonumber(Config.orbitSpeed) or 0.55
    local orbitLookHeight = tonumber(Config.orbitLookHeight) or 1.0
    local orbitFOV = tonumber(Config.orbitFOV) or 70
    local orbitDirection = tonumber(Config.orbitDirection) or 1
    local savedDefaultFOV = (workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView) or 70
    local freeCamPos = nil

    -- State Efek Bokeh / Color Grading & Clean Recording Mode
    local filmFilterNames = {"Normal", "Bokeh Fokus", "Warm Sunset", "Moody Night", "Vivid Cinema"}
    local filmFilterIndex = math.clamp(tonumber(Config.filmFilterIndex) or 1, 1, #filmFilterNames)
    local isCleanRecMode = Config.isCleanRecMode == true
    local didAutoHideMain = false

    -- State Kotak Cinematic Terpisah
    local isCinematicBars = Config.isCinematicBars == true
    local barHeightScale = 0.12

    -- State Pelacak & Intip (Spectate) User
    local trackedPlayer = nil
    local isSpectatingUser = false
    local trackerHighlight, trackerBillboard, trackerNameLbl, trackerBeam, trackerAtt0, trackerAtt1 = nil, nil, nil, nil, nil, nil

    local function syncWorldConfig()
        Config.isNoClipEnabled = isNoClipEnabled
        Config.isWallViewEnabled = isWallViewEnabled
        Config.isShiftLockEnabled = isShiftLockEnabled
        Config.isShiftPinEnabled = isShiftPinEnabled
        Config.flySpeed = flySpeed
        Config.camModeIndex = camModeIndex
        Config.orbitDistance = orbitDistance
        Config.orbitHeight = orbitHeight
        Config.orbitSpeed = orbitSpeed
        Config.orbitLookHeight = orbitLookHeight
        Config.orbitFOV = orbitFOV
        Config.orbitDirection = orbitDirection
        Config.isCinematicBars = isCinematicBars
        Config.filmFilterIndex = filmFilterIndex
        Config.isCleanRecMode = isCleanRecMode
        saveConfig()
    end

    -- ======================== EFEK LOKAL BOKEH & COLOR GRADING ========================
    local cineDOF = Instance.new("DepthOfFieldEffect")
    cineDOF.Name = "KoplingtifyCineDOF"
    cineDOF.Enabled = false
    cineDOF.FarIntensity = 0.65
    cineDOF.NearIntensity = 0.25
    cineDOF.InFocusRadius = 14
    cineDOF.FocusDistance = 12
    cineDOF.Parent = Lighting

    local cineCC = Instance.new("ColorCorrectionEffect")
    cineCC.Name = "KoplingtifyCineCC"
    cineCC.Enabled = false
    cineCC.Parent = Lighting

    local function applyFilmFilterPreset()
        local preset = filmFilterNames[filmFilterIndex] or "Normal"
        if preset == "Normal" then
            cineDOF.Enabled = false
            cineCC.Enabled = false
        elseif preset == "Bokeh Fokus" then
            cineDOF.Enabled = true
            cineDOF.FarIntensity = 0.72
            cineDOF.NearIntensity = 0.25
            cineDOF.InFocusRadius = 12
            cineCC.Enabled = true
            cineCC.Brightness = 0.02
            cineCC.Contrast = 0.08
            cineCC.Saturation = 0.10
            cineCC.TintColor = Color3.fromRGB(255, 255, 255)
        elseif preset == "Warm Sunset" then
            cineDOF.Enabled = true
            cineDOF.FarIntensity = 0.65
            cineDOF.NearIntensity = 0.20
            cineDOF.InFocusRadius = 15
            cineCC.Enabled = true
            cineCC.Brightness = 0.03
            cineCC.Contrast = 0.12
            cineCC.Saturation = 0.22
            cineCC.TintColor = Color3.fromRGB(255, 224, 190)
        elseif preset == "Moody Night" then
            cineDOF.Enabled = true
            cineDOF.FarIntensity = 0.75
            cineDOF.NearIntensity = 0.25
            cineDOF.InFocusRadius = 13
            cineCC.Enabled = true
            cineCC.Brightness = -0.05
            cineCC.Contrast = 0.18
            cineCC.Saturation = -0.15
            cineCC.TintColor = Color3.fromRGB(195, 218, 255)
        elseif preset == "Vivid Cinema" then
            cineDOF.Enabled = false
            cineCC.Enabled = true
            cineCC.Brightness = 0.04
            cineCC.Contrast = 0.16
            cineCC.Saturation = 0.28
            cineCC.TintColor = Color3.fromRGB(255, 248, 240)
        end
    end

    -- ======================== SMART AUTO-HIDE UI (CLEAN RECORDING MODE) ========================
    local function handleCleanRecordingVisibility(shouldHide)
        if not main or not floatBtn then return end
        if shouldHide and isCleanRecMode then
            if main.Visible then
                didAutoHideMain = true
                main.Visible = false
                orbitPanel.Visible = false
                orbitCfgBtn.BackgroundColor3 = Color3.fromRGB(52, 44, 72)
                floatBtn.Visible = true
            end
        elseif not shouldHide and didAutoHideMain then
            didAutoHideMain = false
            floatBtn.Visible = false
            main.Visible = true
        end
    end

    -- ======================== PENATAAN TOMBOL BARIS WORLD ========================
    local worldActionParent = noclipBtn.Parent
    local rowY = noclipBtn.Position.Y.Offset
    local rowH = noclipBtn.Size.Y.Offset

    -- Baris 1: [👻 NoClip] [🧱 Tembok] [🕊️ Fly] [🎬 Cinema]
    noclipBtn.Position = UDim2.new(0, 0, 0, rowY)
    noclipBtn.Size = UDim2.new(0.25, -2, 0, rowH)
    noclipBtn.TextSize = 10

    wallViewBtn.Position = UDim2.new(0.25, 2, 0, rowY)
    wallViewBtn.Size = UDim2.new(0.25, -2, 0, rowH)
    wallViewBtn.TextSize = 10

    local flyBtn = makeButton(
        worldActionParent,
        "🕊️ Fly: OFF",
        UDim2.new(0.50, 2, 0, rowY),
        UDim2.new(0.25, -2, 0, rowH),
        Color3.fromRGB(36, 41, 50)
    )
    flyBtn.TextSize = 10

    local cinemaToggleBtn = makeButton(
        worldActionParent,
        "🎬 Cinema",
        UDim2.new(0.75, 2, 0, rowY),
        UDim2.new(0.25, -2, 0, rowH),
        Color3.fromRGB(36, 41, 50)
    )
    cinemaToggleBtn.TextSize = 10

    -- Baris 2: [🎯 ShiftLock: OFF] [📌 Pin] [🎥 Mode Kamera] [⚙️ Setting]
    local row2Y = rowY + rowH + 6
    local shiftLockBtn = makeButton(
        worldActionParent,
        "🎯 Shift: OFF",
        UDim2.new(0, 0, 0, row2Y),
        UDim2.new(0.32, -2, 0, rowH),
        Color3.fromRGB(36, 41, 50)
    )
    shiftLockBtn.TextSize = 10

    local shiftPinBtn = makeButton(
        worldActionParent,
        "📌",
        UDim2.new(0.32, 2, 0, row2Y),
        UDim2.new(0.11, -2, 0, rowH),
        Color3.fromRGB(45, 52, 64)
    )
    shiftPinBtn.TextSize = 11

    orbitBtn.Parent = worldActionParent
    orbitBtn.Position = UDim2.new(0.43, 2, 0, row2Y)
    orbitBtn.Size = UDim2.new(0.43, -2, 0, rowH)
    orbitBtn.TextSize = 10
    orbitBtn.Text = "🎥 Cam: OFF"

    orbitCfgBtn.Parent = worldActionParent
    orbitCfgBtn.Visible = true
    orbitCfgBtn.Position = UDim2.new(0.86, 2, 0, row2Y)
    orbitCfgBtn.Size = UDim2.new(0.14, -2, 0, rowH)
    orbitCfgBtn.Text = "⚙️"
    orbitCfgBtn.TextSize = 12

    for _, sibling in ipairs(worldActionParent:GetChildren()) do
        if sibling:IsA("GuiObject") and sibling ~= noclipBtn and sibling ~= wallViewBtn and sibling ~= flyBtn
            and sibling ~= cinemaToggleBtn and sibling ~= shiftLockBtn and sibling ~= shiftPinBtn
            and sibling ~= orbitBtn and sibling ~= orbitCfgBtn then
            if sibling.Position.Y.Offset >= row2Y then
                sibling.Position = UDim2.new(
                    sibling.Position.X.Scale,
                    sibling.Position.X.Offset,
                    sibling.Position.Y.Scale,
                    sibling.Position.Y.Offset + rowH + 6
                )
            end
        end
    end

    -- ======================== FLOATING SHIFTLOCK & CROSSHAIR ========================
    local floatShiftBtn = Instance.new("TextButton")
    floatShiftBtn.Name = "KoplingFloatShiftLock"
    floatShiftBtn.Size = UDim2.new(0, 44, 0, 44)
    floatShiftBtn.Position = UDim2.new(0.88, -22, 0.55, 0)
    floatShiftBtn.BackgroundColor3 = Color3.fromRGB(22, 27, 36)
    floatShiftBtn.BackgroundTransparency = 0.15
    floatShiftBtn.Text = "🎯"
    floatShiftBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
    floatShiftBtn.Font = Enum.Font.GothamBold
    floatShiftBtn.TextSize = 18
    floatShiftBtn.Visible = isShiftPinEnabled
    floatShiftBtn.Parent = gui
    Instance.new("UICorner", floatShiftBtn).CornerRadius = UDim.new(1, 0)

    local floatShiftStroke = Instance.new("UIStroke", floatShiftBtn)
    floatShiftStroke.Color = Color3.fromRGB(70, 80, 100)
    floatShiftStroke.Thickness = 1.8

    local crosshairDot = Instance.new("Frame")
    crosshairDot.Name = "ShiftLockCrosshair"
    crosshairDot.Size = UDim2.new(0, 6, 0, 6)
    crosshairDot.Position = UDim2.new(0.5, -3, 0.5, -3)
    crosshairDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshairDot.BackgroundTransparency = 0.2
    crosshairDot.BorderSizePixel = 0
    crosshairDot.Visible = false
    crosshairDot.Parent = gui
    Instance.new("UICorner", crosshairDot).CornerRadius = UDim.new(1, 0)
    local chStroke = Instance.new("UIStroke", crosshairDot)
    chStroke.Color = Color3.fromRGB(0, 0, 0)
    chStroke.Thickness = 1

    if enableDrag then
        enableDrag(floatShiftBtn, floatShiftBtn)
    end

    -- ======================== KOTAK CINEMATIC BAR TERPISAH ========================
    local cinemaGui = Instance.new("ScreenGui")
    cinemaGui.Name = "KoplingtifyCinemaBars"
    cinemaGui.IgnoreGuiInset = true
    cinemaGui.ResetOnSpawn = false
    cinemaGui.DisplayOrder = 9990
    cinemaGui.Parent = gui.Parent

    local topCinemaBar = Instance.new("Frame")
    topCinemaBar.Name = "TopBar"
    topCinemaBar.Size = UDim2.new(1, 0, barHeightScale, 0)
    topCinemaBar.Position = UDim2.new(0, 0, -barHeightScale, 0)
    topCinemaBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    topCinemaBar.BorderSizePixel = 0
    topCinemaBar.Parent = cinemaGui

    local bottomCinemaBar = Instance.new("Frame")
    bottomCinemaBar.Name = "BottomBar"
    bottomCinemaBar.Size = UDim2.new(1, 0, barHeightScale, 0)
    bottomCinemaBar.Position = UDim2.new(0, 0, 1, 0)
    bottomCinemaBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bottomCinemaBar.BorderSizePixel = 0
    bottomCinemaBar.Parent = cinemaGui

    local function setCinematicBars(state, skipSave)
        isCinematicBars = state
        cinemaToggleBtn.Text = "🎬 Cinema"
        cinemaToggleBtn.BackgroundColor3 = isCinematicBars and Color3.fromRGB(35, 150, 90) or Color3.fromRGB(36, 41, 50)

        local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if isCinematicBars then
            TweenService:Create(topCinemaBar, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
            TweenService:Create(bottomCinemaBar, tweenInfo, {Position = UDim2.new(0, 0, 1 - barHeightScale, 0)}):Play()
        else
            TweenService:Create(topCinemaBar, tweenInfo, {Position = UDim2.new(0, 0, -barHeightScale, 0)}):Play()
            TweenService:Create(bottomCinemaBar, tweenInfo, {Position = UDim2.new(0, 0, 1, 0)}):Play()
        end
        if not skipSave then
            syncWorldConfig()
            handleCleanRecordingVisibility(isCinematicBars or isCustomCamEnabled)
        end
    end

    cinemaToggleBtn.MouseButton1Click:Connect(function()
        setCinematicBars(not isCinematicBars)
        showToast("Kotak Cinematic " .. (isCinematicBars and "ON" or "OFF"))
    end)

    -- ======================== PANEL PENGATURAN KAMERA, BOKEH & CLEAN REC ========================
    orbitPanel.Size = UDim2.new(0, 280, 0, 360)

    -- Baris Mode Kamera (◀ [1/8] Orbit Putar ▶)
    local prevCamModeBtn = makeButton(
        orbitPanel,
        "◀",
        UDim2.new(0, 12, 0, 74),
        UDim2.new(0, 32, 0, 26),
        Color3.fromRGB(45, 38, 68)
    )
    prevCamModeBtn.TextSize = 11

    local camModeCycleBtn = makeButton(
        orbitPanel,
        string.format("🎥 [%d/%d] %s", camModeIndex, #camModeNames, camModeNames[camModeIndex]),
        UDim2.new(0, 48, 0, 74),
        UDim2.new(0, 184, 0, 26),
        Color3.fromRGB(58, 48, 86)
    )
    camModeCycleBtn.TextSize = 11

    local nextCamModeBtn = makeButton(
        orbitPanel,
        "▶",
        UDim2.new(0, 236, 0, 74),
        UDim2.new(0, 32, 0, 26),
        Color3.fromRGB(45, 38, 68)
    )
    nextCamModeBtn.TextSize = 11

    -- Baris Efek Bokeh/Film & Mode Rekam Bersih (Clean Rec)
    local filmFilterBtn = makeButton(
        orbitPanel,
        "🎞️ Filter: " .. filmFilterNames[filmFilterIndex],
        UDim2.new(0, 12, 0, 105),
        UDim2.new(0, 136, 0, 26),
        filmFilterIndex > 1 and Color3.fromRGB(145, 85, 215) or Color3.fromRGB(40, 46, 58)
    )
    filmFilterBtn.TextSize = 10

    local cleanRecBtn = makeButton(
        orbitPanel,
        "📸 Clean Rec: " .. (isCleanRecMode and "ON" or "OFF"),
        UDim2.new(0, 152, 0, 105),
        UDim2.new(0, 116, 0, 26),
        isCleanRecMode and Color3.fromRGB(35, 150, 90) or Color3.fromRGB(40, 46, 58)
    )
    cleanRecBtn.TextSize = 10

    filmFilterBtn.MouseButton1Click:Connect(function()
        filmFilterIndex = (filmFilterIndex % #filmFilterNames) + 1
        filmFilterBtn.Text = "🎞️ Filter: " .. filmFilterNames[filmFilterIndex]
        filmFilterBtn.BackgroundColor3 = filmFilterIndex > 1 and Color3.fromRGB(145, 85, 215) or Color3.fromRGB(40, 46, 58)
        applyFilmFilterPreset()
        syncWorldConfig()
        showToast("Efek Kamera: " .. filmFilterNames[filmFilterIndex])
    end)

    cleanRecBtn.MouseButton1Click:Connect(function()
        isCleanRecMode = not isCleanRecMode
        cleanRecBtn.Text = "📸 Clean Rec: " .. (isCleanRecMode and "ON" or "OFF")
        cleanRecBtn.BackgroundColor3 = isCleanRecMode and Color3.fromRGB(35, 150, 90) or Color3.fromRGB(40, 46, 58)
        syncWorldConfig()
        showToast("Clean Recording Mode " .. (isCleanRecMode and "ON (Auto-Hide UI)" or "OFF"))
    end)

    local orbitUiUpdaters = {}
    local function createOrbitSettingRow(yPos, labelText, formatStr, getVal, setVal, step, minVal, maxVal)
        local lbl = makeLabel(orbitPanel, labelText, UDim2.new(0, 12, 0, yPos), UDim2.new(0, 125, 0, 24), labelText, 11, Color3.fromRGB(210, 215, 225))
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local btnMinus = makeButton(orbitPanel, "−", UDim2.new(0, 142, 0, yPos), UDim2.new(0, 32, 0, 24), Color3.fromRGB(40, 46, 56))
        btnMinus.TextSize = 15

        local valLbl = makeLabel(orbitPanel, "Val", UDim2.new(0, 176, 0, yPos), UDim2.new(0, 56, 0, 24), string.format(formatStr, getVal()), 11, Color3.fromRGB(205, 165, 255))
        valLbl.Font = Enum.Font.GothamBold

        local btnPlus = makeButton(orbitPanel, "+", UDim2.new(0, 236, 0, yPos), UDim2.new(0, 32, 0, 24), Color3.fromRGB(40, 46, 56))
        btnPlus.TextSize = 15

        local function refresh()
            valLbl.Text = string.format(formatStr, getVal())
        end
        table.insert(orbitUiUpdaters, refresh)

        makeHoldable(btnMinus, function()
            local nv = math.clamp(math.floor((getVal() - step) * 100 + 0.5) / 100, minVal, maxVal)
            setVal(nv)
            refresh()
            syncWorldConfig()
        end)
        makeHoldable(btnPlus, function()
            local nv = math.clamp(math.floor((getVal() + step) * 100 + 0.5) / 100, minVal, maxVal)
            setVal(nv)
            refresh()
            syncWorldConfig()
        end)
    end

    createOrbitSettingRow(138, "Jarak Kamera:",     "%.1f",  function() return orbitDistance end,   function(v) orbitDistance = v end,   0.5,  1.5,  80.0)
    createOrbitSettingRow(166, "Ketinggian (Y):",   "%.1f",  function() return orbitHeight end,     function(v) orbitHeight = v end,     0.5, -10.0, 50.0)
    createOrbitSettingRow(194, "Kecepatan/Getar:",  "%.2fx", function() return orbitSpeed end,      function(v) orbitSpeed = v end,      0.05, 0.0,  5.0)
    createOrbitSettingRow(222, "Titik Fokus (Y):",  "%.1f",  function() return orbitLookHeight end, function(v) orbitLookHeight = v end, 0.5, -5.0,  10.0)
    createOrbitSettingRow(250, "Sudut Lensa FOV:",  "%d°",   function() return orbitFOV end,        function(v) orbitFOV = v end,        2,    20,   120)
    createOrbitSettingRow(278, "Speed Fly/FreeCam:","%d",    function() return flySpeed end,        function(v) flySpeed = v end,        5,    10,   250)

    orbitDirBtn.Size = UDim2.new(0, 124, 0, 30)
    orbitDirBtn.Position = UDim2.new(0, 12, 0, 314)
    orbitDirBtn.Text = orbitDirection == 1 and "🔄 Sisi: Kanan" or "🔄 Sisi: Kiri"

    orbitResetBtn.Size = UDim2.new(0, 124, 0, 30)
    orbitResetBtn.Position = UDim2.new(0, 144, 0, 314)
    orbitResetBtn.Text = "♻ Reset Semua"

    -- ======================== SISTEM FLY ADMIN (MOBILE & PC) ========================
    local flyBV, flyBG = nil, nil

    local function stopFlyPhysics()
        if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
        if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
        end
    end

    local function toggleFlyAdmin()
        isFlyEnabled = not isFlyEnabled
        flyBtn.Text = "🕊️ Fly: " .. (isFlyEnabled and "ON" or "OFF")
        flyBtn.BackgroundColor3 = isFlyEnabled and Color3.fromRGB(45, 165, 220) or Color3.fromRGB(36, 41, 50)
        if not isFlyEnabled then
            stopFlyPhysics()
        end
        showToast("Fly Admin " .. (isFlyEnabled and "Aktif! (Gunakan Analog/WASD)" or "Dimatikan"))
    end

    flyBtn.MouseButton1Click:Connect(toggleFlyAdmin)

    -- ======================== TAB USER: PELACAK + FITUR INTIP (SPECTATE) ========================
    local userBtnParent = stopTrackBtn.Parent
    local uBtnY = stopTrackBtn.Position.Y.Offset
    local uBtnH = stopTrackBtn.Size.Y.Offset

    local spectateUserBtn = makeButton(
        userBtnParent,
        "👁️ Intip: OFF",
        UDim2.new(0, 0, 0, uBtnY),
        UDim2.new(0.35, -2, 0, uBtnH),
        Color3.fromRGB(36, 41, 50)
    )
    spectateUserBtn.TextSize = 10

    tpTrackBtn.Position = UDim2.new(0.35, 2, 0, uBtnY)
    tpTrackBtn.Size = UDim2.new(0.35, -2, 0, uBtnH)
    tpTrackBtn.TextSize = 10

    stopTrackBtn.Position = UDim2.new(0.70, 2, 0, uBtnY)
    stopTrackBtn.Size = UDim2.new(0.30, -2, 0, uBtnH)
    stopTrackBtn.TextSize = 10

    local function updateSpectateButtonUI()
        spectateUserBtn.Text = "👁️ Intip: " .. (isSpectatingUser and "ON" or "OFF")
        spectateUserBtn.BackgroundColor3 = isSpectatingUser and Color3.fromRGB(155, 85, 225) or Color3.fromRGB(36, 41, 50)
    end

    local function stopSpectatingUser()
        isSpectatingUser = false
        updateSpectateButtonUI()
        local cam = workspace.CurrentCamera
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if cam and hum and not isCustomCamEnabled then
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = hum
        end
    end

    local function clearPlayerLocator()
        trackedPlayer = nil
        stopSpectatingUser()
        if trackerHighlight then pcall(function() trackerHighlight:Destroy() end); trackerHighlight = nil end
        if trackerBillboard then pcall(function() trackerBillboard:Destroy() end); trackerBillboard = nil end
        if trackerBeam then pcall(function() trackerBeam:Destroy() end); trackerBeam = nil end
        if trackerAtt0 then pcall(function() trackerAtt0:Destroy() end); trackerAtt0 = nil end
        if trackerAtt1 then pcall(function() trackerAtt1:Destroy() end); trackerAtt1 = nil end
        trackerNameLbl = nil
    end

    local function createLocatorForPlayer(targetPlr)
        clearPlayerLocator()
        if not targetPlr or targetPlr == player then return end
        trackedPlayer = targetPlr

        local hl = Instance.new("Highlight")
        hl.Name = "KoplingTrackerHL"
        hl.FillColor = Color3.fromRGB(35, 235, 135)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.45
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = gui
        trackerHighlight = hl

        local bb = Instance.new("BillboardGui")
        bb.Name = "KoplingTrackerBB"
        bb.Size = UDim2.new(0, 200, 0, 52)
        bb.StudsOffset = Vector3.new(0, 3.8, 0)
        bb.AlwaysOnTop = true
        bb.Parent = gui
        trackerBillboard = bb

        local badge = Instance.new("Frame")
        badge.Size = UDim2.new(1, 0, 1, 0)
        badge.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
        badge.BackgroundTransparency = 0.15
        badge.BorderSizePixel = 0
        badge.Parent = bb
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 8)
        local bStroke = Instance.new("UIStroke", badge)
        bStroke.Color = Color3.fromRGB(40, 235, 140)
        bStroke.Thickness = 1.5

        local lbl = makeLabel(badge, "Info", UDim2.new(0, 6, 0, 2), UDim2.new(1, -12, 1, -4), "📍 " .. targetPlr.DisplayName, 11, Color3.fromRGB(255, 255, 255))
        lbl.Font = Enum.Font.GothamBold
        trackerNameLbl = lbl

        local beam = Instance.new("Beam")
        beam.Name = "KoplingTrackerBeam"
        beam.FaceCamera = true
        beam.Color = ColorSequence.new(Color3.fromRGB(40, 235, 140), Color3.fromRGB(80, 195, 255))
        beam.Width0 = 0.18
        beam.Width1 = 0.18
        beam.Transparency = NumberSequence.new(0.15)
        beam.LightEmission = 1
        beam.Parent = gui
        trackerBeam = beam
    end

    local function refreshPlayerList()
        for _, child in ipairs(userListFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local filterTxt = string.lower(userSearchBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local allPlayers = Players:GetPlayers()
        local order = 0

        for _, plr in ipairs(allPlayers) do
            if plr ~= player then
                local uName = plr.Name or ""
                local dName = plr.DisplayName or uName
                local matchStr = string.lower(dName .. " " .. uName)
                if filterTxt == "" or matchStr:find(filterTxt, 1, true) then
                    order += 1
                    local distStr = ""
                    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if myHrp and tHrp then
                        distStr = string.format(" • %dm", math.floor((myHrp.Position - tHrp.Position).Magnitude))
                    end

                    local isSelected = (trackedPlayer == plr)
                    local btnBg = isSelected and Color3.fromRGB(35, 150, 90) or Color3.fromRGB(32, 37, 46)
                    local b = makeButton(userListFrame, string.format("  📍 %s (@%s)%s", dName, uName, distStr), UDim2.new(), UDim2.new(1, -6, 0, 32), btnBg)
                    b.LayoutOrder = order
                    b.TextXAlignment = Enum.TextXAlignment.Left
                    b.TextTruncate = Enum.TextTruncate.AtEnd

                    b.MouseButton1Click:Connect(function()
                        if trackedPlayer == plr then
                            clearPlayerLocator()
                            showToast("Pelacak lokasi dimatikan.")
                        else
                            createLocatorForPlayer(plr)
                            showToast("Menandai user: " .. dName)
                        end
                        refreshPlayerList()
                    end)
                end
            end
        end

        task.defer(function()
            userListFrame.CanvasSize = UDim2.new(0, 0, 0, userListLayout.AbsoluteContentSize.Y + 6)
        end)
    end

    spectateUserBtn.MouseButton1Click:Connect(function()
        if not trackedPlayer or not trackedPlayer.Parent then
            showToast("Klik/tandai salah satu user dulu!", Color3.fromRGB(165, 65, 55))
            return
        end
        isSpectatingUser = not isSpectatingUser
        updateSpectateButtonUI()
        if isSpectatingUser then
            showToast("👁️ Mengintip kamera: " .. trackedPlayer.DisplayName, Color3.fromRGB(140, 85, 215))
        else
            stopSpectatingUser()
            showToast("Kamera kembali ke karakter sendiri.")
        end
    end)

    clearUserBtn.MouseButton1Click:Connect(function()
        userSearchBox.Text = ""
        refreshPlayerList()
    end)
    refreshUserBtn.MouseButton1Click:Connect(refreshPlayerList)
    userSearchBox:GetPropertyChangedSignal("Text"):Connect(refreshPlayerList)

    stopTrackBtn.MouseButton1Click:Connect(function()
        clearPlayerLocator()
        refreshPlayerList()
        showToast("Pelacak & Intip dimatikan.")
    end)

    tpTrackBtn.MouseButton1Click:Connect(function()
        if not trackedPlayer or not trackedPlayer.Character then
            showToast("Pilih user di daftar terlebih dahulu!", Color3.fromRGB(165, 65, 55))
            return
        end
        local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local tHrp = trackedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myHrp and tHrp then
            myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)
            showToast("Teleport ke " .. trackedPlayer.DisplayName)
        end
    end)

    Players.PlayerAdded:Connect(function() task.delay(0.5, refreshPlayerList) end)
    Players.PlayerRemoving:Connect(function(plr)
        if plr == trackedPlayer then clearPlayerLocator() end
        task.delay(0.2, refreshPlayerList)
    end)
    refreshPlayerList()

    -- ======================== BATAS TEMBOK TRANSPARAN (INVISIBLE BARRIER ESP) ========================
    local function restoreCharacterCollision()
        for part, canCol in pairs(savedCanCollide) do
            if part and part.Parent then part.CanCollide = canCol end
        end
        savedCanCollide = {}
    end

    local function clearSecretWallHighlights()
        for part, box in pairs(secretWallBoxes) do
            if box then pcall(function() box:Destroy() end) end
        end
        secretWallBoxes = {}
    end

    local function restoreFadedWalls()
        for part, origLTM in pairs(fadedWallParts) do
            if part and part.Parent then part.LocalTransparencyModifier = origLTM end
        end
        fadedWallParts = {}
    end

    local function applyWallOcclusionMode()
        pcall(function()
            if isWallViewEnabled then
                player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
            else
                player.DevCameraOcclusionMode = origOcclusionMode
                restoreFadedWalls()
                clearSecretWallHighlights()
            end
        end)
    end

    local function scanWallsAndSecretPassages(cam, focusPos, ignoreChar)
        restoreFadedWalls()
        local okParts, obstructing = pcall(function()
            return cam:GetPartsObscuringTarget({focusPos}, {ignoreChar})
        end)
        if okParts and type(obstructing) == "table" then
            for _, part in ipairs(obstructing) do
                if part:IsA("BasePart") and part.Transparency < 0.7 then
                    fadedWallParts[part] = part.LocalTransparencyModifier
                    part.LocalTransparencyModifier = 0.82
                end
            end
        end

        local now = tick()
        if now - lastWallScan < 0.35 then return end
        lastWallScan = now

        for part, box in pairs(secretWallBoxes) do
            if not part or not part.Parent or (part.Position - focusPos).Magnitude > 140 or part.Transparency < 0.85 then
                if box then pcall(function() box:Destroy() end) end
                secretWallBoxes[part] = nil
            end
        end

        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Exclude
        overlapParams.FilterDescendantsInstances = {ignoreChar}

        local nearbyParts = workspace:GetPartBoundsInRadius(focusPos, 120, overlapParams)
        for _, part in ipairs(nearbyParts) do
            if part:IsA("BasePart") and not part:IsDescendantOf(gui) then
                local isCharacterPart = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
                local sz = part.Size
                local isBarrierSized = (sz.X >= 1.5 or sz.Y >= 1.5 or sz.Z >= 1.5)

                if not isCharacterPart and isBarrierSized and part.Transparency >= 0.85 and part.CanCollide then
                    if not secretWallBoxes[part] then
                        local selBox = Instance.new("SelectionBox")
                        selBox.Name = "KoplingInvisibleBarrierESP"
                        selBox.Adornee = part
                        selBox.Color3 = Color3.fromRGB(0, 215, 255)
                        selBox.SurfaceColor3 = Color3.fromRGB(0, 185, 255)
                        selBox.SurfaceTransparency = 0.85
                        selBox.LineThickness = 0.035
                        selBox.Parent = gui
                        secretWallBoxes[part] = selBox
                    end
                end
            end
        end
    end

    -- ======================== LOGIKA SHIFTLOCK CUSTOM ========================
    local function releaseShiftLockState()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.AutoRotate = true
            hum.CameraOffset = Vector3.new(0, 0, 0)
        end
        crosshairDot.Visible = false
    end

    local function updateShiftLockVisuals()
        shiftLockBtn.Text = "🎯 Shift: " .. (isShiftLockEnabled and "ON" or "OFF")
        shiftLockBtn.BackgroundColor3 = isShiftLockEnabled and Color3.fromRGB(35, 155, 95) or Color3.fromRGB(36, 41, 50)

        floatShiftBtn.BackgroundColor3 = isShiftLockEnabled and Color3.fromRGB(30, 150, 90) or Color3.fromRGB(22, 27, 36)
        floatShiftStroke.Color = isShiftLockEnabled and Color3.fromRGB(85, 255, 160) or Color3.fromRGB(70, 80, 100)

        shiftPinBtn.BackgroundColor3 = isShiftPinEnabled and Color3.fromRGB(140, 85, 215) or Color3.fromRGB(45, 52, 64)
        floatShiftBtn.Visible = isShiftPinEnabled

        if not isShiftLockEnabled then
            releaseShiftLockState()
        end
    end

    local function toggleShiftLock()
        isShiftLockEnabled = not isShiftLockEnabled
        updateShiftLockVisuals()
        syncWorldConfig()
        showToast("ShiftLock " .. (isShiftLockEnabled and "ON (Terkunci)" or "OFF"))
    end

    shiftLockBtn.MouseButton1Click:Connect(toggleShiftLock)
    floatShiftBtn.MouseButton1Click:Connect(toggleShiftLock)

    shiftPinBtn.MouseButton1Click:Connect(function()
        isShiftPinEnabled = not isShiftPinEnabled
        updateShiftLockVisuals()
        syncWorldConfig()
        showToast("Tombol Floating ShiftLock " .. (isShiftPinEnabled and "Ditampilkan" or "Disembunyikan"))
    end)

    -- ======================== KONTROL 8 MODE KAMERA ========================
    local function getCurrentPlayingLoudness()
        local maxLoud = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Sound") and obj.IsPlaying and obj.PlaybackLoudness > maxLoud then
                maxLoud = obj.PlaybackLoudness
            end
        end
        return maxLoud
    end

    local function resetCameraToNormal()
        local cam = workspace.CurrentCamera
        local targetHum = nil
        if isSpectatingUser and trackedPlayer and trackedPlayer.Character then
            targetHum = trackedPlayer.Character:FindFirstChildOfClass("Humanoid")
        else
            targetHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        end

        freeCamPos = nil
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            cam.FieldOfView = savedDefaultFOV
            if targetHum then cam.CameraSubject = targetHum end
        end
    end

    local function updateCameraButtonVisuals()
        local modeShort = camModeShortNames[camModeIndex] or "Orbit"
        orbitBtn.Text = isCustomCamEnabled and ("🎥 " .. modeShort .. ": ON") or ("🎥 " .. modeShort .. ": OFF")
        orbitBtn.BackgroundColor3 = isCustomCamEnabled and Color3.fromRGB(165, 105, 235) or Color3.fromRGB(36, 42, 52)

        camModeCycleBtn.Text = string.format("🎥 [%d/%d] %s", camModeIndex, #camModeNames, camModeNames[camModeIndex])
        orbitToggleInsideBtn.Text = "Status (" .. modeShort .. "): " .. (isCustomCamEnabled and "ON" or "OFF")
        orbitToggleInsideBtn.BackgroundColor3 = isCustomCamEnabled and Color3.fromRGB(135, 75, 205) or Color3.fromRGB(39, 45, 55)
    end

    local function setCameraModeIndex(newIdx)
        camModeIndex = ((newIdx - 1) % #camModeNames) + 1
        local cam = workspace.CurrentCamera
        if cam then freeCamPos = cam.CFrame.Position end
        updateCameraButtonVisuals()
        syncWorldConfig()
        showToast(string.format("Mode Kamera [%d/%d]: %s", camModeIndex, #camModeNames, camModeNames[camModeIndex]))
    end

    local function toggleCustomCameraState()
        isCustomCamEnabled = not isCustomCamEnabled
        if isCustomCamEnabled then
            local cam = workspace.CurrentCamera
            if cam then
                savedDefaultFOV = cam.FieldOfView
                freeCamPos = cam.CFrame.Position
            end
            handleCleanRecordingVisibility(true)
        else
            resetCameraToNormal()
            handleCleanRecordingVisibility(isCinematicBars)
        end
        updateCameraButtonVisuals()
        showToast("Kamera (" .. camModeNames[camModeIndex] .. ") " .. (isCustomCamEnabled and "ON" or "OFF"), Color3.fromRGB(140, 85, 215))
    end

    prevCamModeBtn.MouseButton1Click:Connect(function() setCameraModeIndex(camModeIndex - 1) end)
    camModeCycleBtn.MouseButton1Click:Connect(function() setCameraModeIndex(camModeIndex + 1) end)
    nextCamModeBtn.MouseButton1Click:Connect(function() setCameraModeIndex(camModeIndex + 1) end)

    orbitDirBtn.MouseButton1Click:Connect(function()
        orbitDirection = -orbitDirection
        orbitDirBtn.Text = orbitDirection == 1 and "🔄 Sisi: Kanan" or "🔄 Sisi: Kiri"
        syncWorldConfig()
    end)

    orbitResetBtn.MouseButton1Click:Connect(function()
        orbitDistance, orbitHeight, orbitSpeed = 10.0, 3.5, 0.55
        orbitLookHeight, orbitFOV, orbitDirection, flySpeed = 1.0, 70, 1, 50
        filmFilterIndex, isCleanRecMode = 1, false
        orbitDirBtn.Text = "🔄 Sisi: Kanan"
        filmFilterBtn.Text = "🎞️ Filter: Normal"
        filmFilterBtn.BackgroundColor3 = Color3.fromRGB(40, 46, 58)
        cleanRecBtn.Text = "📸 Clean Rec: OFF"
        cleanRecBtn.BackgroundColor3 = Color3.fromRGB(40, 46, 58)
        applyFilmFilterPreset()
        for _, fn in ipairs(orbitUiUpdaters) do fn() end
        syncWorldConfig()
        showToast("Pengaturan Kamera, Filter & Fly direset!")
    end)

    orbitBtn.MouseButton1Click:Connect(toggleCustomCameraState)
    orbitToggleInsideBtn.MouseButton1Click:Connect(toggleCustomCameraState)

    orbitCfgBtn.MouseButton1Click:Connect(function()
        orbitPanel.Visible = not orbitPanel.Visible
        orbitCfgBtn.BackgroundColor3 = orbitPanel.Visible and Color3.fromRGB(165, 105, 235) or Color3.fromRGB(52, 44, 72)
    end)

    closeOrbitPanelBtn.MouseButton1Click:Connect(function()
        orbitPanel.Visible = false
        orbitCfgBtn.BackgroundColor3 = Color3.fromRGB(52, 44, 72)
    end)

    -- Terapkan status awal dari Config
    noclipBtn.Text = "👻 NoClip: " .. (isNoClipEnabled and "ON" or "OFF")
    noclipBtn.BackgroundColor3 = isNoClipEnabled and Color3.fromRGB(205, 115, 45) or Color3.fromRGB(36, 41, 50)

    wallViewBtn.Text = "🧱 Tembok: " .. (isWallViewEnabled and "ON" or "OFF")
    wallViewBtn.BackgroundColor3 = isWallViewEnabled and Color3.fromRGB(50, 140, 210) or Color3.fromRGB(36, 41, 50)
    if isWallViewEnabled then applyWallOcclusionMode() end
    if isCinematicBars then setCinematicBars(true, true) end
    applyFilmFilterPreset()
    updateShiftLockVisuals()
    updateCameraButtonVisuals()

    noclipBtn.MouseButton1Click:Connect(function()
        isNoClipEnabled = not isNoClipEnabled
        noclipBtn.Text = "👻 NoClip: " .. (isNoClipEnabled and "ON" or "OFF")
        noclipBtn.BackgroundColor3 = isNoClipEnabled and Color3.fromRGB(205, 115, 45) or Color3.fromRGB(36, 41, 50)
        if not isNoClipEnabled then restoreCharacterCollision() end
        syncWorldConfig()
        showToast("NoClip " .. (isNoClipEnabled and "Diaktifkan" or "Dimatikan"))
    end)

    wallViewBtn.MouseButton1Click:Connect(function()
        isWallViewEnabled = not isWallViewEnabled
        wallViewBtn.Text = "🧱 Tembok: " .. (isWallViewEnabled and "ON" or "OFF")
        wallViewBtn.BackgroundColor3 = isWallViewEnabled and Color3.fromRGB(50, 140, 210) or Color3.fromRGB(36, 41, 50)
        applyWallOcclusionMode()
        syncWorldConfig()
        showToast("Batas Tembok Transparan " .. (isWallViewEnabled and "ON" or "OFF"))
    end)

    -- ======================== LOOP FISIKA NOCLIP & FLY ADMIN ========================
    RunService.Stepped:Connect(function()
        if not gui.Parent then return end
        local char = player.Character
        if not char then return end

        if isNoClipEnabled or isFlyEnabled then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if savedCanCollide[part] == nil then
                        savedCanCollide[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end
    end)

    -- ======================== LOOP RENDERSTEPPED UTAMA ========================
    RunService.RenderStepped:Connect(function(dt)
        if not gui.Parent then return end

        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera

        -- 1. Update Fly Admin
        if isFlyEnabled and hrp and hum and cam then
            if not flyBV or flyBV.Parent ~= hrp then
                if flyBV then pcall(function() flyBV:Destroy() end) end
                flyBV = Instance.new("BodyVelocity")
                flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                flyBV.Velocity = Vector3.new(0, 0, 0)
                flyBV.Parent = hrp
            end
            if not flyBG or flyBG.Parent ~= hrp then
                if flyBG then pcall(function() flyBG:Destroy() end) end
                flyBG = Instance.new("BodyGyro")
                flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                flyBG.P = 9e4
                flyBG.D = 1000
                flyBG.Parent = hrp
            end

            hum.PlatformStand = true
            flyBG.CFrame = cam.CFrame

            local moveDir = hum.MoveDirection
            local targetVel = Vector3.new(0, 0, 0)

            if not (isCustomCamEnabled and camModeIndex == 2) then
                if moveDir.Magnitude > 0.05 then
                    local camCF = cam.CFrame
                    local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
                    local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
                    if flatLook.Magnitude > 0.001 then flatLook = flatLook.Unit end
                    if flatRight.Magnitude > 0.001 then flatRight = flatRight.Unit end

                    local forwardAmt = moveDir:Dot(flatLook)
                    local rightAmt = moveDir:Dot(flatRight)
                    targetVel = (camCF.LookVector * forwardAmt + camCF.RightVector * rightAmt) * flySpeed
                end

                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    targetVel += Vector3.new(0, flySpeed * 0.85, 0)
                elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    targetVel -= Vector3.new(0, flySpeed * 0.85, 0)
                end
            end

            flyBV.Velocity = flyBV.Velocity:Lerp(targetVel, math.clamp(dt * 12, 0, 1))
        elseif flyBV or flyBG then
            stopFlyPhysics()
        end

        -- 2. Update Pelacak & Intip User
        local activeTargetChar = char
        local activeTargetHrp = hrp
        local activeTargetHum = hum

        if trackedPlayer and trackedPlayer.Parent then
            local tChar = trackedPlayer.Character
            local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHead = tChar and (tChar:FindFirstChild("Head") or tHrp)
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if tChar and tHrp then
                if trackerHighlight then trackerHighlight.Adornee = tChar end
                if trackerBillboard then trackerBillboard.Adornee = tHead end
                local dist = hrp and math.floor((hrp.Position - tHrp.Position).Magnitude) or 0
                if trackerNameLbl then
                    trackerNameLbl.Text = string.format("📍 %s (@%s)\nJarak: %d Stud", trackedPlayer.DisplayName, trackedPlayer.Name, dist)
                end
                if hrp and trackerBeam then
                    if not trackerAtt0 or trackerAtt0.Parent ~= hrp then
                        if trackerAtt0 then pcall(function() trackerAtt0:Destroy() end) end
                        trackerAtt0 = Instance.new("Attachment", hrp)
                    end
                    if not trackerAtt1 or trackerAtt1.Parent ~= tHrp then
                        if trackerAtt1 then pcall(function() trackerAtt1:Destroy() end) end
                        trackerAtt1 = Instance.new("Attachment", tHrp)
                    end
                    trackerBeam.Attachment0 = trackerAtt0
                    trackerBeam.Attachment1 = trackerAtt1
                    trackerBeam.Enabled = true
                end

                if isSpectatingUser then
                    activeTargetChar = tChar
                    activeTargetHrp = tHrp
                    activeTargetHum = tHum
                    if cam and not isCustomCamEnabled and tHum then
                        cam.CameraType = Enum.CameraType.Custom
                        cam.CameraSubject = tHum
                    end
                end
            else
                if trackerHighlight then trackerHighlight.Adornee = nil end
                if trackerBillboard then trackerBillboard.Adornee = nil end
                if trackerBeam then trackerBeam.Enabled = false end
            end
        elseif isSpectatingUser then
            stopSpectatingUser()
        end

        -- 3. Update Auto-Fokus Bokeh (DepthOfField) pada Karakter/Target
        if cineDOF.Enabled and cam and activeTargetHrp then
            local distToSubject = (cam.CFrame.Position - activeTargetHrp.Position).Magnitude
            cineDOF.FocusDistance = distToSubject
        end

        -- 4. Update 8 Mode Kamera
        if isCustomCamEnabled and activeTargetHrp and cam then
            cam.CameraType = Enum.CameraType.Scriptable
            local targetCF = activeTargetHrp.CFrame
            local lookAtPos = targetCF.Position + Vector3.new(0, orbitLookHeight, 0)

            if camModeIndex == 1 then
                -- Mode 1: Orbit Putar (360°)
                cam.FieldOfView = cam.FieldOfView + (orbitFOV - cam.FieldOfView) * math.clamp(dt * 10, 0, 1)
                orbitAngle = orbitAngle + (dt * orbitSpeed * orbitDirection)
                local offset = Vector3.new(
                    math.cos(orbitAngle) * orbitDistance,
                    orbitHeight,
                    math.sin(orbitAngle) * orbitDistance
                )
                cam.CFrame = CFrame.new(targetCF.Position + offset, lookAtPos)

            elseif camModeIndex == 2 then
                -- Mode 2: FreeCam Bebas
                cam.FieldOfView = cam.FieldOfView + (orbitFOV - cam.FieldOfView) * math.clamp(dt * 10, 0, 1)
                if not freeCamPos then freeCamPos = cam.CFrame.Position end
                local rotOnly = cam.CFrame - cam.CFrame.Position
                if hum and hum.MoveDirection.Magnitude > 0.05 then
                    local camCF = cam.CFrame
                    local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
                    local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
                    if flatLook.Magnitude > 0.001 then flatLook = flatLook.Unit end
                    if flatRight.Magnitude > 0.001 then flatRight = flatRight.Unit end
                    local forwardAmt = hum.MoveDirection:Dot(flatLook)
                    local rightAmt = hum.MoveDirection:Dot(flatRight)
                    freeCamPos = freeCamPos + (camCF.LookVector * forwardAmt + camCF.RightVector * rightAmt) * (flySpeed * dt)
                end
                cam.CFrame = CFrame.new(freeCamPos) * rotOnly

            elseif camModeIndex == 3 then
                -- Mode 3: Drone Atas (Top-Down)
                cam.FieldOfView = cam.FieldOfView + (orbitFOV - cam.FieldOfView) * math.clamp(dt * 10, 0, 1)
                orbitAngle = orbitAngle + (dt * orbitSpeed * 0.25 * orbitDirection)
                local topHeight = math.max(8, orbitDistance + orbitHeight)
                local camPos = targetCF.Position + Vector3.new(math.cos(orbitAngle) * 2.5, topHeight, math.sin(orbitAngle) * 2.5)
                cam.CFrame = CFrame.new(camPos, lookAtPos)

            elseif camModeIndex == 4 then
                -- Mode 4: First-Person (POV)
                cam.FieldOfView = cam.FieldOfView + (orbitFOV - cam.FieldOfView) * math.clamp(dt * 10, 0, 1)
                local head = activeTargetChar and activeTargetChar:FindFirstChild("Head")
                local eyePos = head and (head.Position + Vector3.new(0, 0.2, 0)) or (targetCF.Position + Vector3.new(0, 1.6, 0))
                local rotOnly = cam.CFrame - cam.CFrame.Position
                cam.CFrame = CFrame.new(eyePos) * rotOnly

            elseif camModeIndex == 5 then
                -- Mode 5: Front Selfie
                cam.FieldOfView = cam.FieldOfView + (orbitFOV - cam.FieldOfView) * math.clamp(dt * 10, 0, 1)
                local desiredPos = targetCF.Position + (targetCF.LookVector * orbitDistance) + Vector3.new(0, orbitHeight * 0.5, 0)
                local desiredCF = CFrame.new(desiredPos, lookAtPos + Vector3.new(0, 0.5, 0))
                cam.CFrame = cam.CFrame:Lerp(desiredCF, math.clamp(dt * 10, 0, 1))

            elseif camModeIndex == 6 then
                -- Mode 6: Side Tracking
                cam.FieldOfView = cam.FieldOfView + (orbitFOV - cam.FieldOfView) * math.clamp(dt * 10, 0, 1)
                local sideVec = targetCF.RightVector * (orbitDistance * orbitDirection)
                local desiredPos = targetCF.Position + sideVec + Vector3.new(0, orbitHeight * 0.4, 0)
                local desiredCF = CFrame.new(desiredPos, lookAtPos)
                cam.CFrame = cam.CFrame:Lerp(desiredCF, math.clamp(dt * 10, 0, 1))

            elseif camModeIndex == 7 then
                -- Mode 7: Over-Shoulder
                cam.FieldOfView = cam.FieldOfView + (orbitFOV - cam.FieldOfView) * math.clamp(dt * 10, 0, 1)
                local backDist = math.max(3.5, orbitDistance * 0.65)
                local shoulderSide = targetCF.RightVector * (2.2 * orbitDirection)
                local desiredPos = targetCF.Position - (targetCF.LookVector * backDist) + shoulderSide + Vector3.new(0, math.max(1.5, orbitHeight * 0.5), 0)
                local aimTarget = lookAtPos + (targetCF.LookVector * 6) + (shoulderSide * 0.4)
                local desiredCF = CFrame.new(desiredPos, aimTarget)
                cam.CFrame = cam.CFrame:Lerp(desiredCF, math.clamp(dt * 12, 0, 1))

            elseif camModeIndex == 8 then
                -- Mode 8: Beat-Shake / JJ Cam
                local loud = getCurrentPlayingLoudness()
                local bassFactor = math.clamp(loud / 300, 0, 1.5)
                local dynamicFOV = math.clamp(orbitFOV - (bassFactor * 12 * math.max(0.3, orbitSpeed)), 25, 120)
                cam.FieldOfView = cam.FieldOfView + (dynamicFOV - cam.FieldOfView) * math.clamp(dt * 18, 0, 1)

                local shakeMag = bassFactor * 0.45 * math.max(0.2, orbitSpeed)
                local shakeOffset = Vector3.new(
                    (math.random() - 0.5) * shakeMag,
                    (math.random() - 0.5) * shakeMag,
                    (math.random() - 0.5) * shakeMag
                )
                local rollAngle = math.rad((math.random() - 0.5) * bassFactor * 4 * orbitSpeed)
                local basePos = targetCF.Position - (targetCF.LookVector * orbitDistance) + Vector3.new(0, orbitHeight, 0) + shakeOffset
                cam.CFrame = CFrame.new(basePos, lookAtPos) * CFrame.Angles(0, 0, rollAngle)
            end

            wasCustomCam = true
        elseif wasCustomCam then
            wasCustomCam = false
            resetCameraToNormal()
        end

        -- 5. Update ShiftLock
        if isShiftLockEnabled and not isCustomCamEnabled and hrp and hum and cam then
            if hum.Sit or hum.Health <= 0 then
                hum.AutoRotate = true
                hum.CameraOffset = Vector3.new(0, 0, 0)
                crosshairDot.Visible = false
            else
                hum.AutoRotate = false
                local camDist = (cam.CFrame.Position - cam.Focus.Position).Magnitude
                if camDist > 1.2 then
                    hum.CameraOffset = hum.CameraOffset:Lerp(Vector3.new(1.75, 0, 0), math.clamp(dt * 15, 0, 1))
                else
                    hum.CameraOffset = Vector3.new(0, 0, 0)
                end

                local lookVec = cam.CFrame.LookVector
                local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z)
                if flatLook.Magnitude > 0.001 then
                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + flatLook.Unit)
                end
                crosshairDot.Visible = true
            end
        elseif not isShiftLockEnabled or isCustomCamEnabled then
            crosshairDot.Visible = false
            if isCustomCamEnabled and hum then
                hum.AutoRotate = true
                hum.CameraOffset = Vector3.new(0, 0, 0)
            end
        end

        -- 6. Update View Batas Tembok Transparan
        if isWallViewEnabled and cam and activeTargetHrp then
            scanWallsAndSecretPassages(cam, activeTargetHrp.Position, activeTargetChar)
        end
    end)

    return {
        Cleanup = function()
            if isCustomCamEnabled then isCustomCamEnabled = false; resetCameraToNormal() end
            if isFlyEnabled then isFlyEnabled = false; stopFlyPhysics() end
            if isNoClipEnabled then isNoClipEnabled = false; restoreCharacterCollision() end
            if isWallViewEnabled then isWallViewEnabled = false; applyWallOcclusionMode() end
            if isShiftLockEnabled then isShiftLockEnabled = false; releaseShiftLockState() end
            clearPlayerLocator()
            if cineDOF then pcall(function() cineDOF:Destroy() end) end
            if cineCC then pcall(function() cineCC:Destroy() end) end
            if cinemaGui then pcall(function() cinemaGui:Destroy() end) end
        end
    }
end

return WorldModule
