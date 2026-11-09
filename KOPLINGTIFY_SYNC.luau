-- KOPLINGTIFY LITE (ANDROID & MINIMIZE EDITION)
-- Fitur: UI ramah layar sentuh Android, Mode Compact (Minimize), Mode Floating Icon,
-- Auto-Sync durasi lagu, tanpa batas max speed 2x, Mute lokal, & Auto-Search pergantian lagu.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then return end

-- State & Variabel Utama
local cache = {}
local activeSound, activeSoundId = nil, nil
local activeItem = nil
local lyrics = {}
local currentIndex = 0
local lyricSpeed = 1.0
local syncOffset = 0.0
local manualSpeedOverride = false
local autoSpeedSynced = false
local isAutoRatioActive = false
local autoChat = false
local isMutedLocally = false
local originalVolume = 0.5
local lastSentLine = ""
local scanToken = 0
local isMinimized = false

local FULL_SIZE = UDim2.new(0, 350, 0, 400)
local MINI_SIZE = UDim2.new(0, 350, 0, 96)

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function httpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(result) == "string" then return result end
    return nil
end

local function cleanSongName(name)
    if not name then return "" end
    local clean = name:gsub("%[.-%]", ""):gsub("%(.-%)", ""):gsub("%{.-%}", "")
    local tags = {
        "audio", "full song", "sped up", "slowed", "bass boosted",
        "nightcore", "tiktok", "remix", "clean", "explicit",
        "short", "cut", "mv", "music video", "official", "lyrics", "lyric"
    }
    for _, tag in ipairs(tags) do
        clean = clean:gsub(tag, ""):gsub(tag:upper(), ""):gsub(tag:sub(1,1):upper() .. tag:sub(2), "")
    end
    clean = clean:gsub("[^%w%s%-]", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
    return (clean == "" or #clean < 2) and name or clean
end

local function getAggressiveName(name)
    if not name then return "" end
    local n = name:lower()
    local splitStr = string.split(n, "-")[1]
    if not splitStr then return "" end
    n = string.split(splitStr, "|")[1]
    n = string.split(splitStr, "(")[1]
    n = string.split(n, "[")[1]
    return n:match("^%s*(.-)%s*$") or ""
end

local function parseLRC(raw)
    local parsed = {}
    for line in tostring(raw or ""):gmatch("[^\r\n]+") do
        local stamps = {}
        for stamp in line:gmatch("%[(%d+:%d+%.?%d*)%]") do
            local mm, ss = stamp:match("^(%d+):(%d+%.?%d*)$")
            if mm and ss then
                table.insert(stamps, tonumber(mm) * 60 + tonumber(ss))
            end
        end
        local text = line:gsub("%[%d+:%d+%.?%d*%]", ""):gsub("^%s+", ""):gsub("%s+$", "")
        for _, t in ipairs(stamps) do
            table.insert(parsed, {Time = t, Text = text})
        end
    end
    table.sort(parsed, function(a, b) return a.Time < b.Time end)
    return parsed
end

local function searchLyrics(query)
    query = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then return {} end
    local key = string.lower(query)
    if cache[key] then return cache[key] end

    local url = "https://lrclib.net/api/search?q=" .. HttpService:UrlEncode(query)
    local body = httpGet(url)
    if not body then return {} end

    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(data) ~= "table" then return {} end

    local results = {}
    for _, item in ipairs(data) do
        local raw = item.syncedLyrics
        if type(raw) == "string" and raw ~= "" then
            local parsed = parseLRC(raw)
            if #parsed > 0 then
                local origDuration = tonumber(item.duration) or 0
                if origDuration == 0 and #parsed > 0 then
                    origDuration = parsed[#parsed].Time + 10
                end
                table.insert(results, {
                    Title = item.trackName or "Judul tidak diketahui",
                    Artist = item.artistName or "Artis tidak diketahui",
                    Album = item.albumName or "",
                    Duration = origDuration,
                    Lyrics = parsed
                })
            end
        end
        if #results >= 8 then break end
    end
    if #results > 0 then
        cache[key] = results
    end
    return results
end

local function sendChat(message)
    if not message or message == "" then return end
    local sent = false
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            local channel = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildWhichIsA("TextChannel"))
            if channel then
                channel:SendAsync(message)
                sent = true
            end
        end
    end)
    if not sent then
        pcall(function()
            local folder = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            local remote = folder and folder:FindFirstChild("SayMessageRequest")
            if remote then remote:FireServer(message, "All") end
        end)
    end
end

local function findSound()
    local best, bestVolume = nil, -1
    local roots = {workspace, game:GetService("SoundService"), player}
    for _, root in ipairs(roots) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("Sound") and obj.IsPlaying and obj.SoundId ~= "" and (obj.Volume > 0 or ( isMutedLocally and obj == activeSound )) then
                if obj.TimeLength == 0 or obj.TimeLength > 15 then
                    local vol = (obj == activeSound and isMutedLocally) and originalVolume or obj.Volume
                    if vol > bestVolume then
                        best, bestVolume = obj, vol
                    end
                end
            end
        end
    end
    return best
end

-- ======================== UI SETUP ========================
local guiParent = player:WaitForChild("PlayerGui")
local old = guiParent:FindFirstChild("KoplingtifyLite")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "KoplingtifyLite"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.IgnoreGuiInset = true
gui.Parent = guiParent

-- Frame Utama
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = FULL_SIZE
main.AnchorPoint = Vector2.new(0.5, 0)
main.Position = UDim2.new(0.5, 0, 0.08, 0)
main.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
main.BackgroundTransparency = 0.04
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(30, 215, 115)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.25

-- Skala otomatis agar pas di layar HP kecil maupun tablet
local uiScale = Instance.new("UIScale", main)
local function updateScreenScale()
    local cam = workspace.CurrentCamera
    if cam then
        local minDim = math.min(cam.ViewportSize.X, cam.ViewportSize.Y)
        if minDim < 420 then
            uiScale.Scale = math.clamp(minDim / 430, 0.78, 1)
        else
            uiScale.Scale = 1
        end
    end
end
updateScreenScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScreenScale)
end

-- Tombol Mengambang (Floating Pill saat disembunyikan penuh)
local floatBtn = Instance.new("TextButton")
floatBtn.Name = "FloatingToggle"
floatBtn.Size = UDim2.new(0, 52, 0, 52)
floatBtn.Position = UDim2.new(0, 16, 0.45, 0)
floatBtn.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
floatBtn.TextColor3 = Color3.fromRGB(30, 230, 135)
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 22
floatBtn.Text = "🎵"
floatBtn.Visible = false
floatBtn.Active = true
floatBtn.Parent = gui
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
local floatStroke = Instance.new("UIStroke", floatBtn)
floatStroke.Color = Color3.fromRGB(30, 215, 115)
floatStroke.Thickness = 2

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
    b.BackgroundColor3 = bgColor or Color3.fromRGB(36, 41, 49)
    b.TextColor3 = Color3.fromRGB(245, 245, 245)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
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
    btn.MouseLeave:Connect(function()
        holding = false
    end)
end

-- Fungsi Dragging Khusus Android & Mouse (Tanpa Mengganggu Scroll)
local function enableDrag(dragHandle, targetFrame)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ======================== HEADER BAR ========================
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = Color3.fromRGB(25, 29, 36)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Parent = main
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 14)

local titleHeader = makeLabel(topBar, "Header", UDim2.new(0, 14, 0, 4), UDim2.new(1, -160, 0, 20), "KOPLINGTIFY LITE", 13, Color3.fromRGB(30, 230, 135))
titleHeader.Font = Enum.Font.GothamBold
titleHeader.TextXAlignment = Enum.TextXAlignment.Left

local subHeader = makeLabel(topBar, "SubHeader", UDim2.new(0, 14, 0, 21), UDim2.new(1, -160, 0, 16), "Geser bar ini untuk memindahkan", 10, Color3.fromRGB(150, 158, 170))
subHeader.TextXAlignment = Enum.TextXAlignment.Left
subHeader.TextTruncate = Enum.TextTruncate.AtEnd

-- Tombol Kontrol Header (Ukuran 32x30 agar nyaman disentuh di HP)
local muteBtn = makeButton(topBar, "🔊", UDim2.new(1, -144, 0, 6), UDim2.new(0, 32, 0, 30), Color3.fromRGB(38, 44, 54))
local pillModeBtn = makeButton(topBar, "🎵", UDim2.new(1, -108, 0, 6), UDim2.new(0, 32, 0, 30), Color3.fromRGB(38, 44, 54))
local minBtn = makeButton(topBar, "—", UDim2.new(1, -72, 0, 6), UDim2.new(0, 32, 0, 30), Color3.fromRGB(38, 44, 54))
local closeBtn = makeButton(topBar, "×", UDim2.new(1, -36, 0, 6), UDim2.new(0, 28, 0, 30), Color3.fromRGB(135, 45, 52))
closeBtn.TextSize = 16

enableDrag(topBar, main)
enableDrag(floatBtn, floatBtn)

-- ======================== MINI LYRIC BAR (Tampil Saat Minimize) ========================
local miniBar = Instance.new("Frame")
miniBar.Name = "MiniBar"
miniBar.Position = UDim2.new(0, 10, 0, 46)
miniBar.Size = UDim2.new(1, -20, 0, 44)
miniBar.BackgroundColor3 = Color3.fromRGB(26, 30, 38)
miniBar.BorderSizePixel = 0
miniBar.Visible = false
miniBar.Parent = main
Instance.new("UICorner", miniBar).CornerRadius = UDim.new(0, 9)

local miniLyricText = makeLabel(miniBar, "MiniLyric", UDim2.new(0, 10, 0, 2), UDim2.new(1, -20, 1, -4), "Menunggu lagu...", 14, Color3.fromRGB(255, 255, 255))
miniLyricText.Font = Enum.Font.GothamBold

-- ======================== BODY CONTAINER (Disembunyikan Saat Minimize) ========================
local body = Instance.new("Frame")
body.Name = "Body"
body.Position = UDim2.new(0, 0, 0, 44)
body.Size = UDim2.new(1, 0, 1, -44)
body.BackgroundTransparency = 1
body.Parent = main

-- Kotak Pencarian + Tombol Hapus (X) + Tombol Cari
local searchBg = Instance.new("Frame")
searchBg.Position = UDim2.new(0, 12, 0, 4)
searchBg.Size = UDim2.new(1, -82, 0, 36)
searchBg.BackgroundColor3 = Color3.fromRGB(30, 34, 42)
searchBg.BorderSizePixel = 0
searchBg.Parent = body
Instance.new("UICorner", searchBg).CornerRadius = UDim.new(0, 8)

local searchBox = Instance.new("TextBox")
searchBox.Position = UDim2.new(0, 10, 0, 0)
searchBox.Size = UDim2.new(1, -38, 1, 0)
searchBox.BackgroundTransparency = 1
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.PlaceholderColor3 = Color3.fromRGB(140, 148, 160)
searchBox.PlaceholderText = "Cari judul lagu / artis..."
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Text = ""
searchBox.Parent = searchBg

local clearSearchBtn = makeButton(searchBg, "×", UDim2.new(1, -28, 0, 5), UDim2.new(0, 24, 0, 26), Color3.fromRGB(48, 54, 66))
clearSearchBtn.TextSize = 14
clearSearchBtn.MouseButton1Click:Connect(function()
    searchBox.Text = ""
    searchBox:CaptureFocus()
end)

local searchBtn = makeButton(body, "CARI", UDim2.new(1, -64, 0, 4), UDim2.new(0, 52, 0, 36), Color3.fromRGB(30, 165, 95))

-- Daftar Hasil Pencarian (Tombol diperbesar untuk layar sentuh)
local resultsFrame = Instance.new("ScrollingFrame")
resultsFrame.Position = UDim2.new(0, 12, 0, 46)
resultsFrame.Size = UDim2.new(1, -24, 0, 68)
resultsFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 35)
resultsFrame.BorderSizePixel = 0
resultsFrame.ScrollBarThickness = 5
resultsFrame.ScrollBarImageColor3 = Color3.fromRGB(30, 215, 115)
resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsFrame.Parent = body
Instance.new("UICorner", resultsFrame).CornerRadius = UDim.new(0, 8)

local resultLayout = Instance.new("UIListLayout", resultsFrame)
resultLayout.Padding = UDim.new(0, 4)
resultLayout.SortOrder = Enum.SortOrder.LayoutOrder

local resultPad = Instance.new("UIPadding", resultsFrame)
resultPad.PaddingTop = UDim.new(0, 4)
resultPad.PaddingBottom = UDim.new(0, 4)
resultPad.PaddingLeft = UDim.new(0, 4)
resultPad.PaddingRight = UDim.new(0, 4)

-- Panel Lirik Karaoke (Dapat diketuk untuk kirim manual / copy)
local lyricCard = Instance.new("TextButton")
lyricCard.Name = "LyricCard"
lyricCard.Position = UDim2.new(0, 12, 0, 120)
lyricCard.Size = UDim2.new(1, -24, 0, 102)
lyricCard.BackgroundColor3 = Color3.fromRGB(24, 28, 35)
lyricCard.BorderSizePixel = 0
lyricCard.Text = ""
lyricCard.AutoButtonColor = false
lyricCard.Parent = body
Instance.new("UICorner", lyricCard).CornerRadius = UDim.new(0, 10)
local cardStroke = Instance.new("UIStroke", lyricCard)
cardStroke.Color = Color3.fromRGB(45, 52, 65)
cardStroke.Thickness = 1

local prevLine = makeLabel(lyricCard, "Previous", UDim2.new(0, 10, 0, 6), UDim2.new(1, -20, 0, 20), "", 11, Color3.fromRGB(130, 138, 150))
local currentLine = makeLabel(lyricCard, "Current", UDim2.new(0, 10, 0, 27), UDim2.new(1, -20, 0, 46), "Menunggu lagu...", 16, Color3.fromRGB(255, 255, 255))
currentLine.Font = Enum.Font.GothamBold
local nextLine = makeLabel(lyricCard, "Next", UDim2.new(0, 10, 0, 75), UDim2.new(1, -20, 0, 20), "", 11, Color3.fromRGB(130, 138, 150))

-- Ketuk kotak lirik untuk langsung mengirim baris saat ini ke chat
lyricCard.MouseButton1Click:Connect(function()
    local txt = currentLine.Text
    if txt ~= "" and txt ~= "Menunggu lagu..." and txt ~= "Mendeteksi lagu..." and txt ~= "Lirik tidak tersedia." and txt ~= "♪" then
        sendChat(txt)
        cardStroke.Color = Color3.fromRGB(30, 215, 115)
        task.delay(0.25, function()
            if cardStroke then cardStroke.Color = Color3.fromRGB(45, 52, 65) end
        end)
    end
end)

-- Informasi Sinkronisasi
local syncInfo = makeLabel(body, "SyncInfo", UDim2.new(0, 12, 0, 226), UDim2.new(1, -24, 0, 18), "Kecepatan: 1.00x   •   Offset: +0.00s", 11, Color3.fromRGB(30, 230, 135))
syncInfo.Font = Enum.Font.GothamSemibold

-- Kontrol Kecepatan & Offset (Tinggi 34px agar mudah ditekan di layar sentuh)
local slowerBtn = makeButton(body, "−", UDim2.new(0, 12, 0, 248), UDim2.new(0, 42, 0, 34))
slowerBtn.TextSize = 16
local speedBtn = makeButton(body, "1.00x", UDim2.new(0, 58, 0, 248), UDim2.new(0, 68, 0, 34))
local fasterBtn = makeButton(body, "+", UDim2.new(0, 130, 0, 248), UDim2.new(0, 42, 0, 34))
fasterBtn.TextSize = 16

local offsetBackBtn = makeButton(body, "−0.25s", UDim2.new(0, 180, 0, 248), UDim2.new(0, 76, 0, 34))
local offsetForwardBtn = makeButton(body, "+0.25s", UDim2.new(0, 262, 0, 248), UDim2.new(0, 76, 0, 34))

-- Baris Bawah: Reset Auto-Sync & Toggle Auto-Chat
local resetSyncBtn = makeButton(body, "🔄 AUTO SYNC", UDim2.new(0, 12, 0, 290), UDim2.new(0, 156, 0, 34), Color3.fromRGB(48, 58, 70))
local chatBtn = makeButton(body, "💬 Auto-Chat: OFF", UDim2.new(0, 174, 0, 290), UDim2.new(0, 164, 0, 34), Color3.fromRGB(36, 41, 49))

local footerHint = makeLabel(body, "Hint", UDim2.new(0, 12, 0, 330), UDim2.new(1, -24, 0, 18), "Tips: Ketuk kotak lirik untuk kirim manual ke chat.", 10, Color3.fromRGB(120, 128, 140))

-- ======================== LOGIKA TOMBOL & MINIMIZE ========================

local function setStatus(text)
    subHeader.Text = text
end

-- 1. Tombol Minimize (Mode Compact vs Mode Penuh)
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        minBtn.Text = "+"
        body.Visible = false
        miniBar.Visible = true
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = MINI_SIZE}):Play()
    else
        minBtn.Text = "—"
        miniBar.Visible = false
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = FULL_SIZE}):Play()
        task.delay(0.12, function()
            if not isMinimized then body.Visible = true end
        end)
    end
end)

-- 2. Tombol Mode Floating Icon (Sembunyikan penuh ke tombol bulat 🎵)
pillModeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    floatBtn.Visible = true
end)

floatBtn.MouseButton1Click:Connect(function()
    floatBtn.Visible = false
    main.Visible = true
end)

-- 3. Tombol Mute Audio Lokal
muteBtn.MouseButton1Click:Connect(function()
    isMutedLocally = not isMutedLocally
    muteBtn.Text = isMutedLocally and "🔇" or "🔊"
    muteBtn.BackgroundColor3 = isMutedLocally and Color3.fromRGB(135, 55, 55) or Color3.fromRGB(38, 44, 54)
    if activeSound then
        if isMutedLocally then
            originalVolume = activeSound.Volume > 0 and activeSound.Volume or originalVolume
            activeSound.Volume = 0
        else
            activeSound.Volume = originalVolume
        end
    end
end)

-- 4. Tombol Close
closeBtn.MouseButton1Click:Connect(function()
    if isMutedLocally and activeSound then
        activeSound.Volume = originalVolume
    end
    gui:Destroy()
end)

-- 5. Sinkronisasi & Kecepatan Tanpa Batas 2x
local function updateSyncText()
    local modeTag = isAutoRatioActive and " (Auto)" or ""
    syncInfo.Text = string.format("Kecepatan: %.2fx%s   •   Offset: %+.2fs", lyricSpeed, modeTag, syncOffset)
    speedBtn.Text = string.format("%.2fx", lyricSpeed)
    speedBtn.TextColor3 = isAutoRatioActive and Color3.fromRGB(30, 230, 135) or Color3.fromRGB(245, 245, 245)
end

local function applyDurationAutoSync()
    if manualSpeedOverride or not activeItem then return false end
    local origDur = tonumber(activeItem.Duration) or 0
    local rbxDur = (activeSound and activeSound.TimeLength) or 0

    if origDur > 0 and rbxDur > 5 then
        local autoRatio = origDur / rbxDur
        if autoRatio > 1.05 or autoRatio < 0.95 then
            lyricSpeed = math.floor(autoRatio * 100 + 0.5) / 100
            isAutoRatioActive = true
        else
            lyricSpeed = 1.00
            isAutoRatioActive = false
        end
        autoSpeedSynced = true
        updateSyncText()
        return true
    end
    return false
end

makeHoldable(slowerBtn, function()
    manualSpeedOverride = true
    isAutoRatioActive = false
    lyricSpeed = math.max(0.10, math.floor((lyricSpeed - 0.05) * 100 + 0.5) / 100)
    updateSyncText()
end)

makeHoldable(fasterBtn, function()
    manualSpeedOverride = true
    isAutoRatioActive = false
    lyricSpeed = math.floor((lyricSpeed + 0.05) * 100 + 0.5) / 100 -- Tanpa batas maksimal 2.00x
    updateSyncText()
end)

speedBtn.MouseButton1Click:Connect(function()
    manualSpeedOverride = true
    isAutoRatioActive = false
    lyricSpeed = 1.00
    updateSyncText()
end)

makeHoldable(offsetBackBtn, function()
    syncOffset = math.floor((syncOffset - 0.25) * 100 + 0.5) / 100
    updateSyncText()
end)

makeHoldable(offsetForwardBtn, function()
    syncOffset = math.floor((syncOffset + 0.25) * 100 + 0.5) / 100
    updateSyncText()
end)

resetSyncBtn.MouseButton1Click:Connect(function()
    manualSpeedOverride = false
    autoSpeedSynced = false
    isAutoRatioActive = false
    lyricSpeed = 1.00
    syncOffset = 0.00
    if not applyDurationAutoSync() then
        updateSyncText()
    end
end)
updateSyncText()

chatBtn.MouseButton1Click:Connect(function()
    autoChat = not autoChat
    lastSentLine = ""
    chatBtn.Text = "💬 Auto-Chat: " .. (autoChat and "ON" or "OFF")
    chatBtn.BackgroundColor3 = autoChat and Color3.fromRGB(30, 150, 90) or Color3.fromRGB(36, 41, 49)
end)

-- ======================== PENCARIAN & HASIL ========================

local resultButtons = {}

local function clearResults()
    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    resultButtons = {}
end

local function updateDisplayedLyric(prevTxt, currTxt, nextTxt)
    prevLine.Text = prevTxt or ""
    currentLine.Text = currTxt or ""
    nextLine.Text = nextTxt or ""
    miniLyricText.Text = currTxt or ""
end

local function activateResult(item, selectedBtn)
    activeItem = item
    lyrics = item.Lyrics or {}
    currentIndex = 0
    lastSentLine = ""
    autoSpeedSynced = false
    isAutoRatioActive = false

    for _, btn in ipairs(resultButtons) do
        btn.BackgroundColor3 = (btn == selectedBtn) and Color3.fromRGB(30, 135, 80) or Color3.fromRGB(34, 39, 48)
    end

    if not manualSpeedOverride then
        lyricSpeed = 1.00
        applyDurationAutoSync()
    end
    updateSyncText()

    setStatus(item.Title .. " — " .. item.Artist)
    updateDisplayedLyric("", #lyrics > 0 and "♪ Lirik siap, menunggu sinkronisasi..." or "Lirik kosong.", "")
end

local function showResults(items)
    clearResults()
    if #items == 0 then
        setStatus("Lirik tersinkronisasi tidak ditemukan.")
        updateDisplayedLyric("", "Lirik tidak tersedia.", "")
        return
    end
    for i, item in ipairs(items) do
        local durText = item.Duration > 0 and string.format(" (%d:%02d)", math.floor(item.Duration / 60), math.floor(item.Duration % 60)) or ""
        local b = makeButton(resultsFrame, "  " .. item.Title .. " — " .. item.Artist .. durText, UDim2.new(), UDim2.new(1, -4, 0, 30), Color3.fromRGB(34, 39, 48))
        b.LayoutOrder = i
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextTruncate = Enum.TextTruncate.AtEnd
        table.insert(resultButtons, b)
        b.MouseButton1Click:Connect(function()
            activateResult(item, b)
        end)
    end
    task.defer(function()
        resultsFrame.CanvasSize = UDim2.new(0, 0, 0, resultLayout.AbsoluteContentSize.Y + 8)
    end)
    activateResult(items[1], resultButtons[1])
end

local searchId = 0
local function doSearch(query, fallbackQueries)
    searchId += 1
    local thisSearch = searchId
    setStatus("Mencari lirik...")
    clearResults()

    task.spawn(function()
        local queriesToTry = {}
        if query and query ~= "" then
            table.insert(queriesToTry, query)
        end
        if type(fallbackQueries) == "table" then
            for _, q in ipairs(fallbackQueries) do
                if q and q ~= "" and q ~= query then
                    table.insert(queriesToTry, q)
                end
            end
        end

        local finalResults = {}
        local matchedQuery = query or ""

        for _, q in ipairs(queriesToTry) do
            if thisSearch ~= searchId then return end
            local res = searchLyrics(q)
            if #res > 0 then
                finalResults = res
                matchedQuery = q
                break
            end
        end

        if thisSearch ~= searchId then return end
        if matchedQuery ~= "" then
            searchBox.Text = matchedQuery
        end
        showResults(finalResults)
    end)
end

searchBtn.MouseButton1Click:Connect(function()
    doSearch(searchBox.Text, {cleanSongName(searchBox.Text)})
end)
searchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        doSearch(searchBox.Text, {cleanSongName(searchBox.Text)})
    end
end)

-- ======================== DETEKSI LAGU OTOMATIS ========================

local function getInGameMusicGuiTitle()
    local guiTitle, guiArtist = "", ""
    pcall(function()
        local pGui = player:FindFirstChild("PlayerGui")
        if pGui and pGui:FindFirstChild("MusicGUI") then
            local mName = pGui.MusicGUI:FindFirstChild("MusicName")
            if mName and mName:IsA("TextLabel") then
                guiTitle = mName.Text
                local sArtist = mName:FindFirstChild("ArtistName")
                if sArtist and sArtist:IsA("TextLabel") then
                    guiArtist = sArtist.Text
                end
            end
        end
    end)
    if guiTitle:lower() == "label" or guiTitle:lower() == "text" or guiTitle:lower() == "song_name" then guiTitle = "" end
    if guiArtist:lower() == "label" or guiArtist:lower() == "text" or guiArtist:lower() == "artistname" or guiArtist:lower() == "artist_name" then guiArtist = "" end
    return guiTitle, guiArtist
end

task.spawn(function()
    while gui.Parent do
        local sound = findSound()
        local currentId = sound and sound.SoundId or nil

        if sound and (sound ~= activeSound or currentId ~= activeSoundId) then
            activeSound = sound
            activeSoundId = currentId
            if not isMutedLocally then
                originalVolume = sound.Volume > 0 and sound.Volume or 0.5
            end
            scanToken += 1
            local thisToken = scanToken

            activeItem = nil
            lyrics = {}
            currentIndex = 0
            lastSentLine = ""
            manualSpeedOverride = false
            autoSpeedSynced = false
            isAutoRatioActive = false
            lyricSpeed = 1.00
            syncOffset = 0.00
            updateSyncText()

            updateDisplayedLyric("", "Mendeteksi lagu...", "")
            setStatus("Membaca metadata audio...")

            task.spawn(function()
                task.wait(0.5)
                if scanToken ~= thisToken or not sound or not sound.Parent then return end

                local guiTitle, guiArtist = getInGameMusicGuiTitle()
                local rawName = (sound.Name ~= "Sound" and sound.Name ~= "Hawk909LocalAudio") and sound.Name or ""

                local assetId = tonumber(activeSoundId and activeSoundId:match("%d+"))
                if assetId then
                    local info = safeCall(function()
                        return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
                    end)
                    if info and info.Name then
                        rawName = info.Name
                    end
                end

                local cleanedRaw = cleanSongName(rawName)
                local aggressiveRaw = getAggressiveName(rawName)

                local displayQuery = ""
                if guiTitle ~= "" and guiArtist ~= "" then
                    displayQuery = guiTitle .. " " .. guiArtist
                elseif guiTitle ~= "" then
                    displayQuery = guiTitle
                elseif cleanedRaw ~= "" then
                    displayQuery = cleanedRaw
                else
                    displayQuery = rawName
                end

                if displayQuery ~= "" then
                    searchBox.Text = displayQuery
                    doSearch(displayQuery, {
                        guiTitle,
                        cleanedRaw,
                        aggressiveRaw,
                        rawName
                    })
                else
                    searchBox.Text = ""
                    setStatus("Audio ID: " .. tostring(assetId or "Custom") .. " (Cari manual)")
                    updateDisplayedLyric("", "Judul lagu tidak terdeteksi.", "")
                end
            end)
        elseif not sound and activeSound then
            activeSound = nil
            activeSoundId = nil
            setStatus("Menunggu musik diputar...")
        end
        task.wait(0.8)
    end
end)

-- ======================== SINKRONISASI REAL-TIME ========================

RunService.Heartbeat:Connect(function()
    if not gui.Parent or not activeSound or not activeSound.IsPlaying then return end

    if isMutedLocally then
        activeSound.Volume = 0
    end

    if activeItem and not autoSpeedSynced and not manualSpeedOverride and activeSound.TimeLength > 5 then
        applyDurationAutoSync()
    end

    if #lyrics == 0 then return end

    local position = (activeSound.TimePosition * lyricSpeed) + syncOffset
    local found = 0
    for i, line in ipairs(lyrics) do
        if position >= line.Time then
            found = i
        else
            break
        end
    end

    if found > 0 and found ~= currentIndex then
        currentIndex = found
        local line = lyrics[found]
        local text = line.Text

        local p = 1
        while lyrics[found - p] and lyrics[found - p].Text == "" do p += 1 end
        local n = 1
        while lyrics[found + n] and lyrics[found + n].Text == "" do n += 1 end

        local prevTxt = lyrics[found - p] and lyrics[found - p].Text or ""
        local currTxt = text ~= "" and text or "♪"
        local nextTxt = lyrics[found + n] and lyrics[found + n].Text or ""

        updateDisplayedLyric(prevTxt, currTxt, nextTxt)

        if autoChat and text ~= "" and text ~= lastSentLine then
            lastSentLine = text
            sendChat(text)
        end
    end
end)

print("Koplingtify Lite (Android UI & Minimize Edition) loaded.")
