-- KOPLINGTIFY LITE (FIXED - PASTI MUNCUL SAAT EXECUTE)
-- Fitur: Auto-Sync durasi lagu, tanpa batas max speed 2x, Auto-Search pergantian lagu,
-- UI Android ramah sentuh, Minimize, Floating Icon, Subtitle Transparan (HUD), & Progress Bar.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- Tunggu LocalPlayer siap jika dieksekusi di autoexec
local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

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
local isSubtitleEnabled = false
local originalVolume = 0.5
local lastSentLine = ""
local scanToken = 0
local isMinimized = false

local FULL_SIZE = UDim2.new(0, 340, 0, 415)
local MINI_SIZE = UDim2.new(0, 340, 0, 94)

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

local function formatTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
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
    n = string.split(n, "(")[1]
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
            if obj:IsA("Sound") and obj.IsPlaying and obj.SoundId ~= "" and (obj.Volume > 0 or (isMutedLocally and obj == activeSound)) then
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

-- ======================== SAFE GUI PARENT (FIX TIDAK MUNCUL) ========================
local function getSafeParent()
    local okGethui, hui = pcall(function()
        return gethui and gethui()
    end)
    if okGethui and hui then return hui end

    local okCore, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and core then return core end

    return player:WaitForChild("PlayerGui")
end

-- Bersihkan UI lama di semua kemungkinan tempat
pcall(function()
    if gethui and gethui():FindFirstChild("KoplingtifyLite") then gethui().KoplingtifyLite:Destroy() end
end)
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("KoplingtifyLite") then game:GetService("CoreGui").KoplingtifyLite:Destroy() end
end)
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("KoplingtifyLite") then pg.KoplingtifyLite:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "KoplingtifyLite"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = getSafeParent()

-- Frame Utama (Menggunakan posisi eksplisit seperti skrip awal agar pasti terlihat)
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = FULL_SIZE
main.Position = UDim2.new(0.5, -170, 0.1, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 22, 27)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(30, 215, 125)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.25

-- Tombol Mengambang (Floating Pill saat disembunyikan penuh)
local floatBtn = Instance.new("TextButton")
floatBtn.Name = "FloatingToggle"
floatBtn.Size = UDim2.new(0, 50, 0, 50)
floatBtn.Position = UDim2.new(0, 20, 0.45, 0)
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
floatStroke.Color = Color3.fromRGB(30, 215, 125)
floatStroke.Thickness = 2

-- ======================== SUBTITLE HUD OVERLAY (TRANSPARAN) ========================
local subtitleFrame = Instance.new("Frame")
subtitleFrame.Name = "SubtitleOverlay"
subtitleFrame.Size = UDim2.new(0, 500, 0, 68)
subtitleFrame.Position = UDim2.new(0.5, -250, 0.82, 0)
subtitleFrame.BackgroundTransparency = 1
subtitleFrame.Visible = false
subtitleFrame.Active = true
subtitleFrame.Parent = gui

local subMainText = Instance.new("TextLabel")
subMainText.Name = "SubCurrent"
subMainText.Size = UDim2.new(1, 0, 0, 38)
subMainText.Position = UDim2.new(0, 0, 0, 0)
subMainText.BackgroundTransparency = 1
subMainText.Font = Enum.Font.GothamBold
subMainText.TextSize = 20
subMainText.TextColor3 = Color3.fromRGB(255, 255, 255)
subMainText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
subMainText.TextStrokeTransparency = 0.1
subMainText.TextWrapped = true
subMainText.Text = "Menunggu lagu..."
subMainText.Parent = subtitleFrame

local subNextText = Instance.new("TextLabel")
subNextText.Name = "SubNext"
subNextText.Size = UDim2.new(1, 0, 0, 24)
subNextText.Position = UDim2.new(0, 0, 0, 40)
subNextText.BackgroundTransparency = 1
subNextText.Font = Enum.Font.GothamSemibold
subNextText.TextSize = 14
subNextText.TextColor3 = Color3.fromRGB(185, 195, 205)
subNextText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
subNextText.TextStrokeTransparency = 0.25
subNextText.TextWrapped = true
subNextText.Text = ""
subNextText.Parent = subtitleFrame

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
    b.BackgroundColor3 = bgColor or Color3.fromRGB(39, 45, 51)
    b.TextColor3 = Color3.fromRGB(245, 245, 245)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
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

-- Fungsi Dragging Khusus Android & Mouse
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
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(26, 30, 37)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Parent = main
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

local titleHeader = makeLabel(topBar, "Header", UDim2.new(0, 12, 0, 3), UDim2.new(1, -185, 0, 18), "KOPLINGTIFY LITE", 13, Color3.fromRGB(30, 230, 135))
titleHeader.Font = Enum.Font.GothamBold
titleHeader.TextXAlignment = Enum.TextXAlignment.Left

local status = makeLabel(topBar, "Status", UDim2.new(0, 12, 0, 20), UDim2.new(1, -185, 0, 16), "Putar musik atau cari lirik...", 10, Color3.fromRGB(160, 168, 178))
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd

-- Tombol Kontrol Header (📺 Subtitle, 🔊 Mute, 🎵 Pill, — Minimize, × Close)
local subToggleBtn = makeButton(topBar, "📺", UDim2.new(1, -172, 0, 6), UDim2.new(0, 30, 0, 28), Color3.fromRGB(39, 45, 55))
local muteBtn = makeButton(topBar, "🔊", UDim2.new(1, -138, 0, 6), UDim2.new(0, 30, 0, 28), Color3.fromRGB(39, 45, 55))
local pillModeBtn = makeButton(topBar, "🎵", UDim2.new(1, -104, 0, 6), UDim2.new(0, 30, 0, 28), Color3.fromRGB(39, 45, 55))
local minBtn = makeButton(topBar, "—", UDim2.new(1, -70, 0, 6), UDim2.new(0, 30, 0, 28), Color3.fromRGB(39, 45, 55))
local closeBtn = makeButton(topBar, "×", UDim2.new(1, -36, 0, 6), UDim2.new(0, 28, 0, 28), Color3.fromRGB(130, 42, 48))
closeBtn.TextSize = 15

enableDrag(topBar, main)
enableDrag(floatBtn, floatBtn)
enableDrag(subtitleFrame, subtitleFrame)

-- ======================== MINI LYRIC BAR (Tampil Saat Minimize) ========================
local miniBar = Instance.new("Frame")
miniBar.Name = "MiniBar"
miniBar.Position = UDim2.new(0, 10, 0, 44)
miniBar.Size = UDim2.new(1, -20, 0, 44)
miniBar.BackgroundColor3 = Color3.fromRGB(27, 31, 38)
miniBar.BorderSizePixel = 0
miniBar.Visible = false
miniBar.Parent = main
Instance.new("UICorner", miniBar).CornerRadius = UDim.new(0, 8)

local miniLyricText = makeLabel(miniBar, "MiniLyric", UDim2.new(0, 10, 0, 2), UDim2.new(1, -20, 0, 34), "Menunggu lagu...", 13, Color3.fromRGB(255, 255, 255))
miniLyricText.Font = Enum.Font.GothamBold

local miniProgBg = Instance.new("Frame")
miniProgBg.Position = UDim2.new(0, 8, 1, -6)
miniProgBg.Size = UDim2.new(1, -16, 0, 3)
miniProgBg.BackgroundColor3 = Color3.fromRGB(45, 52, 65)
miniProgBg.BorderSizePixel = 0
miniProgBg.Parent = miniBar
Instance.new("UICorner", miniProgBg).CornerRadius = UDim.new(1, 0)

local miniProgFill = Instance.new("Frame")
miniProgFill.Size = UDim2.new(0, 0, 1, 0)
miniProgFill.BackgroundColor3 = Color3.fromRGB(30, 215, 125)
miniProgFill.BorderSizePixel = 0
miniProgFill.Parent = miniProgBg
Instance.new("UICorner", miniProgFill).CornerRadius = UDim.new(1, 0)

-- ======================== BODY CONTAINER ========================
local body = Instance.new("Frame")
body.Name = "Body"
body.Position = UDim2.new(0, 0, 0, 42)
body.Size = UDim2.new(1, 0, 1, -42)
body.BackgroundTransparency = 1
body.Parent = main

local searchBox = Instance.new("TextBox")
searchBox.Position = UDim2.new(0, 12, 0, 4)
searchBox.Size = UDim2.new(1, -110, 0, 32)
searchBox.BackgroundColor3 = Color3.fromRGB(32, 36, 44)
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.PlaceholderColor3 = Color3.fromRGB(145, 152, 162)
searchBox.PlaceholderText = "Cari judul lagu / artis..."
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.Text = ""
searchBox.Parent = body
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 7)

local clearSearchBtn = makeButton(body, "×", UDim2.new(1, -94, 0, 4), UDim2.new(0, 26, 0, 32), Color3.fromRGB(50, 56, 66))
clearSearchBtn.MouseButton1Click:Connect(function()
    searchBox.Text = ""
    searchBox:CaptureFocus()
end)

local searchBtn = makeButton(body, "CARI", UDim2.new(1, -64, 0, 4), UDim2.new(0, 52, 0, 32), Color3.fromRGB(30, 160, 95))

-- Daftar Hasil Pencarian
local resultsFrame = Instance.new("ScrollingFrame")
resultsFrame.Position = UDim2.new(0, 12, 0, 42)
resultsFrame.Size = UDim2.new(1, -24, 0, 64)
resultsFrame.BackgroundColor3 = Color3.fromRGB(26, 30, 37)
resultsFrame.BorderSizePixel = 0
resultsFrame.ScrollBarThickness = 5
resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsFrame.Parent = body
Instance.new("UICorner", resultsFrame).CornerRadius = UDim.new(0, 7)

local resultLayout = Instance.new("UIListLayout", resultsFrame)
resultLayout.Padding = UDim.new(0, 4)
resultLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Area Lirik Utama
local lyricCard = Instance.new("TextButton")
lyricCard.Name = "LyricCard"
lyricCard.Position = UDim2.new(0, 12, 0, 112)
lyricCard.Size = UDim2.new(1, -24, 0, 96)
lyricCard.BackgroundColor3 = Color3.fromRGB(25, 29, 36)
lyricCard.BorderSizePixel = 0
lyricCard.Text = ""
lyricCard.AutoButtonColor = false
lyricCard.Parent = body
Instance.new("UICorner", lyricCard).CornerRadius = UDim.new(0, 9)

local prevLine = makeLabel(lyricCard, "Previous", UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 20), "", 11, Color3.fromRGB(135, 143, 153))
local currentLine = makeLabel(lyricCard, "Current", UDim2.new(0, 8, 0, 25), UDim2.new(1, -16, 0, 44), "Menunggu lagu...", 15, Color3.fromRGB(255, 255, 255))
currentLine.Font = Enum.Font.GothamBold
local nextLine = makeLabel(lyricCard, "Next", UDim2.new(0, 8, 0, 71), UDim2.new(1, -16, 0, 20), "", 11, Color3.fromRGB(135, 143, 153))

lyricCard.MouseButton1Click:Connect(function()
    local txt = currentLine.Text
    if txt ~= "" and txt ~= "Menunggu lagu..." and txt ~= "Mendeteksi lagu..." and txt ~= "Lirik tidak tersedia." and txt ~= "♪" then
        sendChat(txt)
    end
end)

-- ======================== PROGRESS BAR LAGU & WAKTU REAL-TIME ========================
local timeCurrentLbl = makeLabel(body, "TimeCurrent", UDim2.new(0, 12, 0, 213), UDim2.new(0, 42, 0, 16), "00:00", 10, Color3.fromRGB(165, 175, 185))
timeCurrentLbl.TextXAlignment = Enum.TextXAlignment.Left

local progBarBg = Instance.new("Frame")
progBarBg.Name = "ProgressBarBg"
progBarBg.Position = UDim2.new(0, 54, 0, 219)
progBarBg.Size = UDim2.new(1, -108, 0, 5)
progBarBg.BackgroundColor3 = Color3.fromRGB(38, 44, 54)
progBarBg.BorderSizePixel = 0
progBarBg.Parent = body
Instance.new("UICorner", progBarBg).CornerRadius = UDim.new(1, 0)

local progBarFill = Instance.new("Frame")
progBarFill.Name = "Fill"
progBarFill.Size = UDim2.new(0, 0, 1, 0)
progBarFill.BackgroundColor3 = Color3.fromRGB(30, 215, 125)
progBarFill.BorderSizePixel = 0
progBarFill.Parent = progBarBg
Instance.new("UICorner", progBarFill).CornerRadius = UDim.new(1, 0)

local timeTotalLbl = makeLabel(body, "TimeTotal", UDim2.new(1, -54, 0, 213), UDim2.new(0, 42, 0, 16), "00:00", 10, Color3.fromRGB(165, 175, 185))
timeTotalLbl.TextXAlignment = Enum.TextXAlignment.Right

-- Informasi Sinkronisasi
local syncInfo = makeLabel(body, "SyncInfo", UDim2.new(0, 12, 0, 234), UDim2.new(1, -24, 0, 18), "Kecepatan: 1.00x   •   Offset: +0.00s", 11, Color3.fromRGB(30, 230, 135))
syncInfo.TextXAlignment = Enum.TextXAlignment.Center

-- Kontrol Kecepatan & Offset (Ramah Sentuhan)
local slowerBtn = makeButton(body, "−", UDim2.new(0, 12, 0, 256), UDim2.new(0, 38, 0, 32))
slowerBtn.TextSize = 16
local speedBtn = makeButton(body, "1.00x", UDim2.new(0, 54, 0, 256), UDim2.new(0, 68, 0, 32))
local fasterBtn = makeButton(body, "+", UDim2.new(0, 126, 0, 256), UDim2.new(0, 38, 0, 32))
fasterBtn.TextSize = 16

local offsetBackBtn = makeButton(body, "−0.25s", UDim2.new(0, 172, 0, 256), UDim2.new(0, 74, 0, 32))
local offsetForwardBtn = makeButton(body, "+0.25s", UDim2.new(0, 252, 0, 256), UDim2.new(0, 76, 0, 32))

-- Baris Bawah: Reset Auto-Sync & Toggle Auto-Chat
local resetSyncBtn = makeButton(body, "🔄 AUTO SYNC", UDim2.new(0, 12, 0, 296), UDim2.new(0, 152, 0, 32), Color3.fromRGB(52, 62, 74))
local chatBtn = makeButton(body, "💬 Auto-Chat: OFF", UDim2.new(0, 170, 0, 296), UDim2.new(0, 158, 0, 32), Color3.fromRGB(39, 45, 51))

local footerHint = makeLabel(body, "Hint", UDim2.new(0, 12, 0, 336), UDim2.new(1, -24, 0, 18), "Ketuk 📺 di atas untuk Subtitle transparan di layar.", 10, Color3.fromRGB(130, 138, 150))

-- ======================== LOGIKA TOMBOL & MINIMIZE ========================

-- 0. Tombol Subtitle HUD Mengambang (📺)
subToggleBtn.MouseButton1Click:Connect(function()
    isSubtitleEnabled = not isSubtitleEnabled
    subtitleFrame.Visible = isSubtitleEnabled
    subToggleBtn.BackgroundColor3 = isSubtitleEnabled and Color3.fromRGB(30, 150, 90) or Color3.fromRGB(39, 45, 55)
end)

-- 1. Tombol Minimize (Mode Compact vs Mode Penuh)
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        minBtn.Text = "+"
        body.Visible = false
        miniBar.Visible = true
        TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = MINI_SIZE}):Play()
    else
        minBtn.Text = "—"
        miniBar.Visible = false
        body.Visible = true
        TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = FULL_SIZE}):Play()
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
    muteBtn.BackgroundColor3 = isMutedLocally and Color3.fromRGB(135, 55, 55) or Color3.fromRGB(39, 45, 55)
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
    lyricSpeed = math.floor((lyricSpeed + 0.05) * 100 + 0.5) / 100
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
    chatBtn.BackgroundColor3 = autoChat and Color3.fromRGB(30, 145, 90) or Color3.fromRGB(39, 45, 51)
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
    subMainText.Text = currTxt or ""
    subNextText.Text = nextTxt or ""
end

local function activateResult(item, selectedBtn)
    activeItem = item
    lyrics = item.Lyrics or {}
    currentIndex = 0
    lastSentLine = ""
    autoSpeedSynced = false
    isAutoRatioActive = false

    for _, btn in ipairs(resultButtons) do
        btn.BackgroundColor3 = (btn == selectedBtn) and Color3.fromRGB(30, 135, 80) or Color3.fromRGB(35, 40, 48)
    end

    if not manualSpeedOverride then
        lyricSpeed = 1.00
        applyDurationAutoSync()
    end
    updateSyncText()

    status.Text = item.Title .. " — " .. item.Artist
    updateDisplayedLyric("", #lyrics > 0 and "♪ Lirik siap, menunggu sinkronisasi..." or "Lirik kosong.", "")
end

local function showResults(items)
    clearResults()
    if #items == 0 then
        status.Text = "Lirik tersinkronisasi tidak ditemukan."
        updateDisplayedLyric("", "Lirik tidak tersedia.", "")
        return
    end
    for i, item in ipairs(items) do
        local durText = item.Duration > 0 and string.format(" (%d:%02d)", math.floor(item.Duration / 60), math.floor(item.Duration % 60)) or ""
        local b = makeButton(resultsFrame, "  " .. item.Title .. " — " .. item.Artist .. durText, UDim2.new(), UDim2.new(1, -6, 0, 28), Color3.fromRGB(35, 40, 48))
        b.LayoutOrder = i
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextTruncate = Enum.TextTruncate.AtEnd
        table.insert(resultButtons, b)
        b.MouseButton1Click:Connect(function()
            activateResult(item, b)
        end)
    end
    task.defer(function()
        resultsFrame.CanvasSize = UDim2.new(0, 0, 0, resultLayout.AbsoluteContentSize.Y + 6)
    end)
    activateResult(items[1], resultButtons[1])
end

local searchId = 0
local function doSearch(query, fallbackQueries)
    searchId += 1
    local thisSearch = searchId
    status.Text = "Mencari lirik..."
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

            progBarFill.Size = UDim2.new(0, 0, 1, 0)
            miniProgFill.Size = UDim2.new(0, 0, 1, 0)
            timeCurrentLbl.Text = "00:00"
            timeTotalLbl.Text = "00:00"

            updateDisplayedLyric("", "Mendeteksi lagu...", "")
            status.Text = "Membaca metadata audio..."

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
                    status.Text = "Audio ID: " .. tostring(assetId or "Custom") .. " (Cari manual)"
                    updateDisplayedLyric("", "Judul lagu tidak terdeteksi.", "")
                end
            end)
        elseif not sound and activeSound then
            activeSound = nil
            activeSoundId = nil
            status.Text = "Menunggu musik diputar..."
            progBarFill.Size = UDim2.new(0, 0, 1, 0)
            miniProgFill.Size = UDim2.new(0, 0, 1, 0)
            timeCurrentLbl.Text = "00:00"
            timeTotalLbl.Text = "00:00"
        end
        task.wait(0.8)
    end
end)

-- ======================== SINKRONISASI & PROGRESS BAR REAL-TIME ========================

RunService.Heartbeat:Connect(function()
    if not gui.Parent or not activeSound or not activeSound.IsPlaying then return end

    if isMutedLocally then
        activeSound.Volume = 0
    end

    -- Update Progress Bar & Waktu Lagu Real-Time
    local curTime = activeSound.TimePosition or 0
    local totTime = activeSound.TimeLength or 0
    if totTime <= 0 and activeItem and activeItem.Duration > 0 then
        totTime = activeItem.Duration
    end

    timeCurrentLbl.Text = formatTime(curTime)
    timeTotalLbl.Text = formatTime(totTime)

    local progressRatio = totTime > 0 and math.clamp(curTime / totTime, 0, 1) or 0
    progBarFill.Size = UDim2.new(progressRatio, 0, 1, 0)
    miniProgFill.Size = UDim2.new(progressRatio, 0, 1, 0)

    -- Auto-Sync Durasi begitu TimeLength tersedia
    if activeItem and not autoSpeedSynced and not manualSpeedOverride and activeSound.TimeLength > 5 then
        applyDurationAutoSync()
    end

    if #lyrics == 0 then return end

    local position = (curTime * lyricSpeed) + syncOffset
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

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Koplingtify Lite",
        Text = "Berhasil dimuat!",
        Duration = 3
    })
end)

print("Koplingtify Lite (Fixed Edition) loaded.")
