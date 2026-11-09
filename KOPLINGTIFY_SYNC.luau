-- KOPLINGTIFY LITE (UPDATED)
-- Fitur: Auto-sync durasi lagu, tanpa batas max speed 2x, deteksi & pencarian lagu otomatis.
-- Dibuat dengan API Roblox standar; tidak memakai file API / CoreGui / request khusus executor.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then return end

local cache = {}
local activeSound, activeSoundId = nil, nil
local activeItem = nil
local lyrics = {}
local currentIndex = 0
local lyricSpeed = 1.0 -- 1.0 = normal
local syncOffset = 0.0 -- detik; positif memajukan lirik
local manualSpeedOverride = false
local autoSpeedSynced = false
local autoChat = false
local lastSentLine = ""
local scanToken = 0

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

-- Pembersih judul lagu seperti di Koplingtify / Hawk909 biasa
local function cleanSongName(name)
    if not name then return "" end
    local clean = name:gsub("%[.-%]", ""):gsub("%(.-%)", ""):gsub("%{.-%}", "")
    local tags = {
        "audio", "full song", "sped up", "slowed", "bass boosted",
        "nightcore", "tiktok", "remix", "clean", "explicit",
        "short", "cut", "mv", "music video", "official", "lyrics", "lyric"
    }
    for _, tag in ipairs(tags) do
        clean = clean:gsub("(?i)" .. tag, "")
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
            if obj:IsA("Sound") and obj.IsPlaying and obj.SoundId ~= "" and obj.Volume > 0 then
                if obj.TimeLength == 0 or obj.TimeLength > 15 then
                    if obj.Volume > bestVolume then
                        best, bestVolume = obj, obj.Volume
                    end
                end
            end
        end
    end
    return best
end

-- UI
local guiParent = player:WaitForChild("PlayerGui")
local old = guiParent:FindFirstChild("KoplingtifyLite")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "KoplingtifyLite"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = guiParent

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 340, 0, 365)
main.Position = UDim2.new(0.5, -170, 0.18, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 22, 27)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(30, 215, 125)
stroke.Transparency = 0.25

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

local function makeButton(parent, text, pos, size)
    local b = Instance.new("TextButton")
    b.Position = pos
    b.Size = size
    b.BackgroundColor3 = Color3.fromRGB(39, 45, 51)
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

local header = makeLabel(main, "Header", UDim2.new(0, 12, 0, 7), UDim2.new(1, -55, 0, 25), "KOPLINGTIFY  •  LYRICS", 14, Color3.fromRGB(30, 230, 135))
header.TextXAlignment = Enum.TextXAlignment.Left
local close = makeButton(main, "×", UDim2.new(1, -36, 0, 7), UDim2.new(0, 26, 0, 25))
close.BackgroundColor3 = Color3.fromRGB(120, 42, 48)
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local searchBox = Instance.new("TextBox")
searchBox.Position = UDim2.new(0, 12, 0, 40)
searchBox.Size = UDim2.new(1, -86, 0, 30)
searchBox.BackgroundColor3 = Color3.fromRGB(34, 38, 44)
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.PlaceholderColor3 = Color3.fromRGB(150, 155, 165)
searchBox.PlaceholderText = "Cari judul lagu / artis..."
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.Text = ""
searchBox.Parent = main
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 7)

local searchBtn = makeButton(main, "CARI", UDim2.new(1, -66, 0, 40), UDim2.new(0, 54, 0, 30))
searchBtn.BackgroundColor3 = Color3.fromRGB(30, 160, 95)
local status = makeLabel(main, "Status", UDim2.new(0, 12, 0, 74), UDim2.new(1, -24, 0, 18), "Putar musik untuk mendeteksi audio atau cari lirik.", 10, Color3.fromRGB(165, 170, 180))
status.TextXAlignment = Enum.TextXAlignment.Left

local resultsFrame = Instance.new("ScrollingFrame")
resultsFrame.Position = UDim2.new(0, 12, 0, 96)
resultsFrame.Size = UDim2.new(1, -24, 0, 58)
resultsFrame.BackgroundColor3 = Color3.fromRGB(27, 31, 37)
resultsFrame.BorderSizePixel = 0
resultsFrame.ScrollBarThickness = 3
resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsFrame.Parent = main
Instance.new("UICorner", resultsFrame).CornerRadius = UDim.new(0, 7)
local resultLayout = Instance.new("UIListLayout", resultsFrame)
resultLayout.Padding = UDim.new(0, 3)
resultLayout.SortOrder = Enum.SortOrder.LayoutOrder

local prevLine = makeLabel(main, "Previous", UDim2.new(0, 15, 0, 158), UDim2.new(1, -30, 0, 22), "", 11, Color3.fromRGB(135, 143, 153))
local currentLine = makeLabel(main, "Current", UDim2.new(0, 15, 0, 181), UDim2.new(1, -30, 0, 42), "Menunggu lagu...", 16, Color3.fromRGB(255, 255, 255))
currentLine.Font = Enum.Font.GothamBold
local nextLine = makeLabel(main, "Next", UDim2.new(0, 15, 0, 225), UDim2.new(1, -30, 0, 20), "", 11, Color3.fromRGB(135, 143, 153))

local syncInfo = makeLabel(main, "SyncInfo", UDim2.new(0, 12, 0, 250), UDim2.new(1, -24, 0, 18), "Kecepatan: 1.00x   •   Offset: +0.00s", 10, Color3.fromRGB(30, 230, 135))
syncInfo.TextXAlignment = Enum.TextXAlignment.Center

local slowerBtn = makeButton(main, "−", UDim2.new(0, 12, 0, 272), UDim2.new(0, 34, 0, 27))
local speedBtn = makeButton(main, "1.00x", UDim2.new(0, 51, 0, 272), UDim2.new(0, 72, 0, 27))
local fasterBtn = makeButton(main, "+", UDim2.new(0, 128, 0, 272), UDim2.new(0, 34, 0, 27))
local offsetBackBtn = makeButton(main, "Lirik −0.25s", UDim2.new(0, 170, 0, 272), UDim2.new(0, 72, 0, 27))
local offsetForwardBtn = makeButton(main, "Lirik +0.25s", UDim2.new(0, 247, 0, 272), UDim2.new(0, 81, 0, 27))

local resetSyncBtn = makeButton(main, "RESET SINKRONISASI (AUTO)", UDim2.new(0, 12, 0, 304), UDim2.new(1, -24, 0, 24))
resetSyncBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 75)

local isAutoRatioActive = false

local function updateSyncText()
    local modeTag = isAutoRatioActive and " (Auto)" or ""
    syncInfo.Text = string.format("Kecepatan: %.2fx%s   •   Offset: %+.2fs", lyricSpeed, modeTag, syncOffset)
    speedBtn.Text = string.format("%.2fx", lyricSpeed)
end

-- Fungsi Auto-Sync Durasi Lagu (Seperti Koplingtify / Hawk909)
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

-- Tombol kecepatan tanpa batas maksimal 2x speed
makeHoldable(slowerBtn, function()
    manualSpeedOverride = true
    isAutoRatioActive = false
    lyricSpeed = math.max(0.10, math.floor((lyricSpeed - 0.05) * 100 + 0.5) / 100)
    updateSyncText()
end)

makeHoldable(fasterBtn, function()
    manualSpeedOverride = true
    isAutoRatioActive = false
    lyricSpeed = math.floor((lyricSpeed + 0.05) * 100 + 0.5) / 100 -- Tanpa math.min(2.00)
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

local chatBtn = makeButton(main, "Kirim lirik ke chat: OFF", UDim2.new(0, 12, 1, -31), UDim2.new(1, -24, 0, 24))
chatBtn.MouseButton1Click:Connect(function()
    autoChat = not autoChat
    lastSentLine = ""
    chatBtn.Text = "Kirim lirik ke chat: " .. (autoChat and "ON" or "OFF")
    chatBtn.BackgroundColor3 = autoChat and Color3.fromRGB(30, 145, 90) or Color3.fromRGB(39, 45, 51)
end)

local function clearResults()
    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end

local function activateResult(item)
    activeItem = item
    lyrics = item.Lyrics or {}
    currentIndex = 0
    lastSentLine = ""
    autoSpeedSynced = false
    isAutoRatioActive = false

    if not manualSpeedOverride then
        lyricSpeed = 1.00
        applyDurationAutoSync()
    end
    updateSyncText()

    status.Text = item.Title .. " — " .. item.Artist
    prevLine.Text, nextLine.Text = "", ""
    currentLine.Text = #lyrics > 0 and "Lirik siap. Menunggu sinkronisasi..." or "Lirik kosong."
end

local function showResults(items)
    clearResults()
    if #items == 0 then
        status.Text = "Lirik tersinkronisasi tidak ditemukan."
        currentLine.Text = "Lirik tidak tersedia."
        return
    end
    for i, item in ipairs(items) do
        local durText = item.Duration > 0 and string.format(" [%d:%02d]", math.floor(item.Duration / 60), math.floor(item.Duration % 60)) or ""
        local b = makeButton(resultsFrame, item.Title .. " — " .. item.Artist .. durText, UDim2.new(), UDim2.new(1, -6, 0, 25))
        b.LayoutOrder = i
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextTruncate = Enum.TextTruncate.AtEnd
        b.MouseButton1Click:Connect(function() activateResult(item) end)
    end
    task.defer(function()
        resultsFrame.CanvasSize = UDim2.new(0, 0, 0, resultLayout.AbsoluteContentSize.Y + 4)
    end)
    activateResult(items[1])
end

-- Pencarian Manual & Multi-Query Otomatis
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

-- Drag support untuk mouse dan touch
local dragging, dragStart, startPosition
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)
main.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)

-- Membaca MusicGUI dalam game jika tersedia
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

-- Deteksi lagu aktif otomatis (Memantau pergantian instance Sound maupun pergantian SoundId)
task.spawn(function()
    while gui.Parent do
        local sound = findSound()
        local currentId = sound and sound.SoundId or nil

        if sound and (sound ~= activeSound or currentId ~= activeSoundId) then
            activeSound = sound
            activeSoundId = currentId
            scanToken += 1
            local thisToken = scanToken

            -- Reset state untuk lagu baru
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

            currentLine.Text = "Mendeteksi lagu..."
            prevLine.Text, nextLine.Text = "", ""
            status.Text = "Membaca metadata audio..."

            task.spawn(function()
                task.wait(0.5) -- Beri waktu singkat agar GUI game / TimeLength termuat
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
                    status.Text = "Audio terdeteksi (ID: " .. tostring(assetId or "Custom") .. "). Cari manual."
                    currentLine.Text = "Judul lagu tidak terdeteksi."
                end
            end)
        elseif not sound and activeSound then
            activeSound = nil
            activeSoundId = nil
            status.Text = "Tidak ada musik yang sedang diputar."
        end
        task.wait(0.8)
    end
end)

-- Karaoke mengikuti TimePosition audio aktif & Auto-Sync Durasi real-time
RunService.Heartbeat:Connect(function()
    if not gui.Parent or not activeSound or not activeSound.IsPlaying then return end

    -- Jika TimeLength baru selesai dimuat oleh Roblox setelah lirik terpilih, langsung sinkronkan otomatis
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

        -- Lewati baris kosong untuk tampilan Previous dan Next seperti di Koplingtify utama
        local p = 1
        while lyrics[found - p] and lyrics[found - p].Text == "" do p += 1 end
        local n = 1
        while lyrics[found + n] and lyrics[found + n].Text == "" do n += 1 end

        prevLine.Text = lyrics[found - p] and lyrics[found - p].Text or ""
        currentLine.Text = text ~= "" and text or "♪"
        nextLine.Text = lyrics[found + n] and lyrics[found + n].Text or ""

        if autoChat and text ~= "" and text ~= lastSentLine then
            lastSentLine = text
            sendChat(text)
        end
    end
end)

print("Koplingtify Lite (Auto-Sync & Unlimited Speed) loaded.")
