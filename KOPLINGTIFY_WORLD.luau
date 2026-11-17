-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - MODULAR WORLD & CAMERA ENGINE (KOPLINGTIFY_WORLD.luau)
-- =================================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WorldModule = {}

function WorldModule.Init(UI, showToast)
    local player = Players.LocalPlayer
    local gui = UI.Gui

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

    local isNoClipEnabled, isWallViewEnabled = false, false
    local savedCanCollide, fadedWallParts = {}, {}
    local origOcclusionMode = player.DevCameraOcclusionMode

    local isOrbitEnabled, wasOrbitCam = false, false
    local orbitAngle, orbitDistance, orbitHeight = 0, 10.0, 3.5
    local orbitSpeed, orbitLookHeight, orbitFOV, orbitDirection = 0.55, 1.0, 70, 1
    local savedDefaultFOV = (workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView) or 70

    local trackedPlayer, trackerHighlight, trackerBillboard, trackerNameLbl, trackerBeam, trackerAtt0, trackerAtt1 = nil, nil, nil, nil, nil, nil, nil

    local orbitUiUpdaters = {}
    local function createOrbitSettingRow(yPos, labelText, formatStr, getVal, setVal, step, minVal, maxVal)
        local lbl = makeLabel(orbitPanel, labelText, UDim2.new(0, 12, 0, yPos), UDim2.new(0, 125, 0, 26), labelText, 11, Color3.fromRGB(210, 215, 225))
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local btnMinus = makeButton(orbitPanel, "−", UDim2.new(0, 142, 0, yPos), UDim2.new(0, 32, 0, 26), Color3.fromRGB(40, 46, 56))
        btnMinus.TextSize = 15

        local valLbl = makeLabel(orbitPanel, "Val", UDim2.new(0, 176, 0, yPos), UDim2.new(0, 56, 0, 26), string.format(formatStr, getVal()), 11, Color3.fromRGB(205, 165, 255))
        valLbl.Font = Enum.Font.GothamBold

        local btnPlus = makeButton(orbitPanel, "+", UDim2.new(0, 236, 0, yPos), UDim2.new(0, 32, 0, 26), Color3.fromRGB(40, 46, 56))
        btnPlus.TextSize = 15

        local function refresh()
            valLbl.Text = string.format(formatStr, getVal())
        end
        table.insert(orbitUiUpdaters, refresh)

        makeHoldable(btnMinus, function()
            local nv = math.clamp(math.floor((getVal() - step) * 100 + 0.5) / 100, minVal, maxVal)
            setVal(nv)
            refresh()
        end)
        makeHoldable(btnPlus, function()
            local nv = math.clamp(math.floor((getVal() + step) * 100 + 0.5) / 100, minVal, maxVal)
            setVal(nv)
            refresh()
        end)
    end

    createOrbitSettingRow(78,  "Jarak (Stud):",    "%.1f",  function() return orbitDistance end,   function(v) orbitDistance = v end,   0.5,  2.0,  60.0)
    createOrbitSettingRow(110, "Ketinggian (Y):",  "%.1f",  function() return orbitHeight end,     function(v) orbitHeight = v end,     0.5, -10.0, 35.0)
    createOrbitSettingRow(142, "Kecepatan Putar:", "%.2fx", function() return orbitSpeed end,      function(v) orbitSpeed = v end,      0.05, 0.0,  5.0)
    createOrbitSettingRow(174, "Titik Fokus (Y):", "%.1f",  function() return orbitLookHeight end, function(v) orbitLookHeight = v end, 0.5, -5.0,  10.0)
    createOrbitSettingRow(206, "Sudut Lensa FOV:", "%d°",   function() return orbitFOV end,        function(v) orbitFOV = v end,        2,    20,   120)

    local function clearPlayerLocator()
        trackedPlayer = nil
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
                            showToast("Melacak lokasi: " .. dName)
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

    clearUserBtn.MouseButton1Click:Connect(function()
        userSearchBox.Text = ""
        refreshPlayerList()
    end)
    refreshUserBtn.MouseButton1Click:Connect(refreshPlayerList)
    userSearchBox:GetPropertyChangedSignal("Text"):Connect(refreshPlayerList)

    stopTrackBtn.MouseButton1Click:Connect(function()
        clearPlayerLocator()
        refreshPlayerList()
        showToast("Pelacak lokasi dimatikan.")
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

    orbitDirBtn.MouseButton1Click:Connect(function()
        orbitDirection = -orbitDirection
        orbitDirBtn.Text = orbitDirection == 1 and "🔄 Arah: Kanan" or "🔄 Arah: Kiri"
    end)

    orbitResetBtn.MouseButton1Click:Connect(function()
        orbitDistance, orbitHeight, orbitSpeed = 10.0, 3.5, 0.55
        orbitLookHeight, orbitFOV, orbitDirection = 1.0, 70, 1
        orbitDirBtn.Text = "🔄 Arah: Kanan"
        for _, fn in ipairs(orbitUiUpdaters) do fn() end
    end)

    local function restoreCharacterCollision()
        for part, canCol in pairs(savedCanCollide) do
            if part and part.Parent then part.CanCollide = canCol end
        end
        savedCanCollide = {}
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
            end
        end)
    end

    noclipBtn.MouseButton1Click:Connect(function()
        isNoClipEnabled = not isNoClipEnabled
        noclipBtn.Text = "👻 NoClip: " .. (isNoClipEnabled and "ON" or "OFF")
        noclipBtn.BackgroundColor3 = isNoClipEnabled and Color3.fromRGB(205, 115, 45) or Color3.fromRGB(36, 41, 50)
        if not isNoClipEnabled then restoreCharacterCollision() end
        showToast("NoClip " .. (isNoClipEnabled and "Diaktifkan" or "Dimatikan"))
    end)

    wallViewBtn.MouseButton1Click:Connect(function()
        isWallViewEnabled = not isWallViewEnabled
        wallViewBtn.Text = "🧱 Tembok: " .. (isWallViewEnabled and "ON" or "OFF")
        wallViewBtn.BackgroundColor3 = isWallViewEnabled and Color3.fromRGB(50, 140, 210) or Color3.fromRGB(36, 41, 50)
        applyWallOcclusionMode()
        showToast("View Tembok Transparan " .. (isWallViewEnabled and "ON" or "OFF"))
    end)

    RunService.Stepped:Connect(function()
        if not gui.Parent or not isNoClipEnabled then return end
        local char = player.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if savedCanCollide[part] == nil then
                    savedCanCollide[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end)

    local function resetCameraToNormal()
        local cam = workspace.CurrentCamera
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            cam.FieldOfView = savedDefaultFOV
            if hum then cam.CameraSubject = hum end
        end
    end

    local function updateOrbitButtonVisuals()
        orbitBtn.BackgroundColor3 = isOrbitEnabled and Color3.fromRGB(165, 105, 235) or Color3.fromRGB(36, 42, 52)
        orbitToggleInsideBtn.Text = "Status Orbit: " .. (isOrbitEnabled and "ON (Aktif)" or "OFF (Mati)")
        orbitToggleInsideBtn.BackgroundColor3 = isOrbitEnabled and Color3.fromRGB(135, 75, 205) or Color3.fromRGB(39, 45, 55)
    end

    local function toggleOrbitState()
        isOrbitEnabled = not isOrbitEnabled
        if isOrbitEnabled then
            local cam = workspace.CurrentCamera
            if cam then savedDefaultFOV = cam.FieldOfView end
        else
            resetCameraToNormal()
        end
        updateOrbitButtonVisuals()
        showToast("Kamera Orbit " .. (isOrbitEnabled and "ON" or "OFF"), Color3.fromRGB(140, 85, 215))
    end

    orbitBtn.MouseButton1Click:Connect(toggleOrbitState)
    orbitToggleInsideBtn.MouseButton1Click:Connect(toggleOrbitState)

    orbitCfgBtn.MouseButton1Click:Connect(function()
        orbitPanel.Visible = not orbitPanel.Visible
        orbitCfgBtn.BackgroundColor3 = orbitPanel.Visible and Color3.fromRGB(165, 105, 235) or Color3.fromRGB(52, 44, 72)
    end)

    closeOrbitPanelBtn.MouseButton1Click:Connect(function()
        orbitPanel.Visible = false
        orbitCfgBtn.BackgroundColor3 = Color3.fromRGB(52, 44, 72)
    end)

    RunService.RenderStepped:Connect(function(dt)
        if not gui.Parent then return end

        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera

        if trackedPlayer and trackedPlayer.Parent then
            local tChar = trackedPlayer.Character
            local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHead = tChar and (tChar:FindFirstChild("Head") or tHrp)
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
            else
                if trackerHighlight then trackerHighlight.Adornee = nil end
                if trackerBillboard then trackerBillboard.Adornee = nil end
                if trackerBeam then trackerBeam.Enabled = false end
            end
        end

        if isOrbitEnabled and hrp and hum and cam then
            cam.CameraType = Enum.CameraType.Scriptable
            cam.FieldOfView = cam.FieldOfView + (orbitFOV - cam.FieldOfView) * math.clamp(dt * 10, 0, 1)

            orbitAngle = orbitAngle + (dt * orbitSpeed * orbitDirection)
            local offset = Vector3.new(
                math.cos(orbitAngle) * orbitDistance,
                orbitHeight,
                math.sin(orbitAngle) * orbitDistance
            )
            local orbitPos = hrp.Position + offset
            local lookAtPos = hrp.Position + Vector3.new(0, orbitLookHeight, 0)
            cam.CFrame = CFrame.new(orbitPos, lookAtPos)
            wasOrbitCam = true
        elseif wasOrbitCam then
            wasOrbitCam = false
            resetCameraToNormal()
        end

        if isWallViewEnabled and cam and hrp then
            restoreFadedWalls()
            local okParts, obstructing = pcall(function()
                return cam:GetPartsObscuringTarget({hrp.Position}, {char})
            end)
            if okParts and type(obstructing) == "table" then
                for _, part in ipairs(obstructing) do
                    if part:IsA("BasePart") then
                        fadedWallParts[part] = part.LocalTransparencyModifier
                        part.LocalTransparencyModifier = 0.85
                    end
                end
            end
        end
    end)

    return {
        Cleanup = function()
            if isOrbitEnabled then isOrbitEnabled = false; resetCameraToNormal() end
            if isNoClipEnabled then isNoClipEnabled = false; restoreCharacterCollision() end
            if isWallViewEnabled then isWallViewEnabled = false; applyWallOcclusionMode() end
            clearPlayerLocator()
        end
    }
end

return WorldModule
