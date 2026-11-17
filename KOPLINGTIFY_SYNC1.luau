-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - MODULAR SYNC ENGINE (KOPLINGTIFY_SYNC.luau)
-- =================================================================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

local subPalette = {
    {Name = "Putih",  Color = Color3.fromRGB(255, 255, 255)},
    {Name = "Hijau",  Color = Color3.fromRGB(45, 235, 135)},
    {Name = "Kuning", Color = Color3.fromRGB(255, 220, 65)},
    {Name = "Cyan",   Color = Color3.fromRGB(80, 225, 255)},
    {Name = "Pink",   Color = Color3.fromRGB(255, 135, 195)},
    {Name = "Ungu",   Color = Color3.fromRGB(195, 145, 255)}
}

local REPO_BASE = "https://raw.githubusercontent.com/rifandiif1/KOPLINGFY/main/"
local Modules = _G.KoplingtifyModules or {}

local UIModule = Modules.UI or loadstring(game:HttpGet(REPO_BASE .. "KOPLINGTIFY_UI.luau"))()
local FilterOk, FilterModule = pcall(function()
    return Modules.Filter or loadstring(game:HttpGet(REPO_BASE .. "KOPLINGTIFY_FILTER.luau"))()
end)
local WorldOk, WorldModule = pcall(function()
    return Modules.World or loadstring(game:HttpGet(REPO_BASE .. "KOPLINGTIFY_WORLD.luau"))()
end)

local UI = UIModule.Create({SubPalette = subPalette})

local gui = UI.Gui
local main = UI.Main
local mainCorner = UI.MainCorner
local FULL_SIZE = UI.FullSize
local ISLAND_SIZE = UI.IslandSize
local toastBanner = UI.ToastBanner
local toastText = UI.ToastText
local floatBtn = UI.FloatBtn
local subtitleFrame = UI.SubtitleFrame
local subBoxStroke = UI.SubBoxStroke
local subMainText = UI.SubMainText
local subTransText = UI.SubTransText
local subNextText = UI.SubNextText
local topBar = UI.TopBar
local status = UI.Status
local subToggleBtn = UI.SubToggleBtn
local muteBtn = UI.MuteBtn
local pillModeBtn = UI.PillModeBtn
local minBtn = UI.MinBtn
local closeBtn = UI.CloseBtn
local islandBar = UI.IslandBar
local islandDisc = UI.IslandDisc
local islandLyric = UI.IslandLyric
local islandTrans = UI.IslandTrans
local islandExpandBtn = UI.IslandExpandBtn
local islandPillBtn = UI.IslandPillBtn
local islandProgFill = UI.IslandProgFill
local body = UI.Body
local lyricCard = UI.LyricCard
local cardStroke = UI.CardStroke
local prevLine = UI.PrevLine
local currentLine = UI.CurrentLine
local romLine = UI.RomLine
local transLine = UI.TransLine
local nextLine = UI.NextLine
local timeCurrentLbl = UI.TimeCurrentLbl
local progBarFill = UI.ProgBarFill
local timeTotalLbl = UI.TimeTotalLbl
local chatBtn = UI.ChatBtn
local chatModeBtn = UI.ChatModeBtn
local transToggleBtn = UI.TransToggleBtn
local romToggleBtn = UI.RomToggleBtn
local filterBtn = UI.FilterBtn
local searchBox = UI.SearchBox
local clearSearchBtn = UI.ClearSearchBtn
local searchBtn = UI.SearchBtn
local resultsFrame = UI.ResultsFrame
local resultLayout = UI.ResultLayout
local syncInfo = UI.SyncInfo
local slowerBtn = UI.SlowerBtn
local speedBtn = UI.SpeedBtn
local fasterBtn = UI.FasterBtn
local offsetBackBtn = UI.OffsetBackBtn
local offsetForwardBtn = UI.OffsetForwardBtn
local resetSyncBtn = UI.ResetSyncBtn
local orbitCfgBtn = UI.OrbitCfgBtn
local subCfgCard = UI.SubCfgCard
local subBgBtn = UI.SubBgBtn
local subColorBtn = UI.SubColorBtn
local subLockBtn = UI.SubLockBtn
local subResetBtn = UI.SubResetBtn
local orbitPanel = UI.OrbitPanel

local makeLabel = UI.MakeLabel
local makeButton = UI.MakeButton
local makeHoldable = UI.MakeHoldable
local enableDrag = UI.EnableDrag

local cache, transCache = {}, {}
local activeSound, activeSoundId, activeItem = nil, nil, nil
local lyrics = {}
local currentIndex = 0
local lyricSpeed, syncOffset = 1.0, 0.0
local manualSpeedOverride, autoSpeedSynced, isAutoRatioActive = false, false, false
local autoChat, safeFilterEnabled, translateEnabled, romanizeEnabled = false, true, true, true
local chatLangMode = 1
local chatLangNames = {"Asli/Rom", "Indo", "Dual"}

local isMutedLocally, originalVolume = false, 0.5
local lastSentLine = ""
local scanToken, transToken = 0, 0
local isMinimized = false

local isSubtitleEnabled = false
local subOffsetX, subOffsetY, subTextSize = 0, 0, 20
local subCinemaBg, subLocked = false, false
local subColorIndex = 1

enableDrag(subtitleFrame, subtitleFrame, function() return subLocked end)

local function safeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    return ok and res or nil
end

local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    return (ok and type(res) == "string") and res or nil
end

local function formatTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function sanitizeLyricText(text)
    if FilterOk and type(FilterModule) == "table" and FilterModule.Sanitize then
        return FilterModule.Sanitize(text, safeFilterEnabled)
    end
    return text or ""
end

local toastId = 0
local function showToast(msg, bgColor)
    if isMinimized then return end
    toastId += 1
    local myToast = toastId
    toastText.Text = "✨ " .. tostring(msg)
    toastBanner.BackgroundColor3 = bgColor or Color3.fromRGB(28, 155, 90)
    TweenService:Create(toastBanner, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 12, 0, 6)
    }):Play()
    task.delay(2.2, function()
        if toastId == myToast and toastBanner and toastBanner.Parent then
            TweenService:Create(toastBanner, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, 12, 0, -32)
            }):Play()
        end
    end)
end

local WorldController = nil
if WorldOk and type(WorldModule) == "table" and WorldModule.Init then
    WorldController = WorldModule.Init(UI, showToast)
end

local function applySubtitleStyle()
    subtitleFrame.Position = UDim2.new(0.5, -260 + subOffsetX, 0.80, subOffsetY)
    subtitleFrame.BackgroundTransparency = subCinemaBg and 0.35 or 1
    subBoxStroke.Transparency = subCinemaBg and 0.45 or 1
    subMainText.TextSize = subTextSize
    subMainText.TextColor3 = subPalette[subColorIndex].Color
    subTransText.TextSize = math.max(11, subTextSize - 4)
    subNextText.TextSize = math.max(10, subTextSize - 6)
    subTransText.Visible = translateEnabled
end

local subUiUpdaters = {}
local function createSubSettingRow(yPos, labelText, formatStr, getVal, setVal, step, minVal, maxVal)
    local lbl = makeLabel(subCfgCard, labelText, UDim2.new(0, 10, 0, yPos), UDim2.new(0, 130, 0, 26), labelText, 11, Color3.fromRGB(210, 215, 225))
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btnMinus = makeButton(subCfgCard, "−", UDim2.new(0, 146, 0, yPos), UDim2.new(0, 36, 0, 26), Color3.fromRGB(38, 44, 54))
    btnMinus.TextSize = 15

    local valLbl = makeLabel(subCfgCard, "Val", UDim2.new(0, 186, 0, yPos), UDim2.new(0, 86, 0, 26), string.format(formatStr, getVal()), 11, Color3.fromRGB(45, 235, 135))
    valLbl.Font = Enum.Font.GothamBold

    local btnPlus = makeButton(subCfgCard, "+", UDim2.new(0, 276, 0, yPos), UDim2.new(0, 36, 0, 26), Color3.fromRGB(38, 44, 54))
    btnPlus.TextSize = 15

    local function refresh()
        valLbl.Text = string.format(formatStr, getVal())
        applySubtitleStyle()
    end
    table.insert(subUiUpdaters, refresh)

    makeHoldable(btnMinus, function()
        setVal(math.clamp(getVal() - step, minVal, maxVal))
        refresh()
    end)
    makeHoldable(btnPlus, function()
        setVal(math.clamp(getVal() + step, minVal, maxVal))
        refresh()
    end)
end

createSubSettingRow(26, "Ukuran Font Sub:", "%d px", function() return subTextSize end, function(v) subTextSize = v end, 1, 12, 36)
createSubSettingRow(58, "Geser Kiri/Kanan X:", "%+d", function() return subOffsetX end, function(v) subOffsetX = v end, 10, -500, 500)
createSubSettingRow(90, "Geser Atas/Bawah Y:", "%+d", function() return subOffsetY end, function(v) subOffsetY = v end, 10, -500, 300)

subBgBtn.MouseButton1Click:Connect(function()
    subCinemaBg = not subCinemaBg
    subBgBtn.Text = "🎬 Kotak Cinema: " .. (subCinemaBg and "ON" or "OFF")
    subBgBtn.BackgroundColor3 = subCinemaBg and Color3.fromRGB(30, 145, 90) or Color3.fromRGB(36, 42, 52)
    applySubtitleStyle()
end)

subColorBtn.MouseButton1Click:Connect(function()
    subColorIndex = (subColorIndex % #subPalette) + 1
    subColorBtn.Text = "🎨 Warna: " .. subPalette[subColorIndex].Name
    subColorBtn.TextColor3 = subPalette[subColorIndex].Color
    applySubtitleStyle()
end)

subLockBtn.MouseButton1Click:Connect(function()
    subLocked = not subLocked
    subLockBtn.Text = subLocked and "🔒 Drag Sub: Terkunci" or "🔓 Drag Sub: Bebas"
    subLockBtn.BackgroundColor3 = subLocked and Color3.fromRGB(165, 85, 45) or Color3.fromRGB(36, 42, 52)
end)

subResetBtn.MouseButton1Click:Connect(function()
    subOffsetX, subOffsetY, subTextSize = 0, 0, 20
    subCinemaBg, subColorIndex = false, 1
    subBgBtn.Text = "🎬 Kotak Cinema: OFF"
    subBgBtn.BackgroundColor3 = Color3.fromRGB(36, 42, 52)
    subColorBtn.Text = "🎨 Warna: Putih"
    subColorBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
    for _, fn in ipairs(subUiUpdaters) do fn() end
    showToast("Posisi & gaya Subtitle direset!")
end)

subToggleBtn.MouseButton1Click:Connect(function()
    isSubtitleEnabled = not isSubtitleEnabled
    subtitleFrame.Visible = isSubtitleEnabled
    subToggleBtn.BackgroundColor3 = isSubtitleEnabled and Color3.fromRGB(35, 155, 95) or Color3.fromRGB(36, 42, 52)
    showToast("Subtitle Layar " .. (isSubtitleEnabled and "ON" or "OFF"))
end)

local function setMinimizeIsland(state)
    isMinimized = state
    if isMinimized then
        topBar.Visible = false
        body.Visible = false
        toastBanner.Visible = false
        islandBar.Visible = true
        mainCorner.CornerRadius = UDim.new(1, 0)
        TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = ISLAND_SIZE
        }):Play()
    else
        islandBar.Visible = false
        topBar.Visible = true
        body.Visible = true
        toastBanner.Visible = true
        mainCorner.CornerRadius = UDim.new(0, 16)
        TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = FULL_SIZE
        }):Play()
    end
end

minBtn.MouseButton1Click:Connect(function() setMinimizeIsland(true) end)
islandExpandBtn.MouseButton1Click:Connect(function() setMinimizeIsland(false) end)

local function enterPillMode()
    main.Visible = false
    orbitPanel.Visible = false
    orbitCfgBtn.BackgroundColor3 = Color3.fromRGB(52, 44, 72)
    floatBtn.Visible = true
end

pillModeBtn.MouseButton1Click:Connect(enterPillMode)
islandPillBtn.MouseButton1Click:Connect(enterPillMode)

floatBtn.MouseButton1Click:Connect(function()
    floatBtn.Visible = false
    main.Visible = true
end)

muteBtn.MouseButton1Click:Connect(function()
    isMutedLocally = not isMutedLocally
    muteBtn.Text = isMutedLocally and "🔇" or "🔊"
    muteBtn.BackgroundColor3 = isMutedLocally and Color3.fromRGB(135, 55, 55) or Color3.fromRGB(36, 42, 52)
    if activeSound then
        if isMutedLocally then
            originalVolume = activeSound.Volume > 0 and activeSound.Volume or originalVolume
            activeSound.Volume = 0
        else
            activeSound.Volume = originalVolume
        end
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    if isMutedLocally and activeSound then activeSound.Volume = originalVolume end
    if WorldController and WorldController.Cleanup then
        WorldController.Cleanup()
    end
    gui:Destroy()
end)

local function normalizeRomanizedASCII(str)
    if not str or str == "" then return "" end
    local diacritics = {
        ["ā"]="a", ["á"]="a", ["ǎ"]="a", ["à"]="a",
        ["ē"]="e", ["é"]="e", ["ě"]="e", ["è"]="e",
        ["ī"]="i", ["í"]="i", ["ǐ"]="i", ["ì"]="i",
        ["ō"]="o", ["ó"]="o", ["ǒ"]="o", ["ò"]="o",
        ["ū"]="u", ["ú"]="u", ["ǔ"]="u", ["ù"]="u",
        ["ǖ"]="u", ["ǘ"]="u", ["ǚ"]="u", ["ǜ"]="u", ["ü"]="u",
        ["Ā"]="A", ["Á"]="A", ["Ǎ"]="A", ["À"]="A",
        ["Ē"]="E", ["É"]="E", ["Ě"]="E", ["È"]="E",
        ["Ī"]="I", ["Í"]="I", ["Ǐ"]="I", ["Ì"]="I",
        ["Ō"]="O", ["Ó"]="O", ["Ǒ"]="O", ["Ò"]="O",
        ["Ū"]="U", ["Ú"]="U", ["Ǔ"]="U", ["Ù"]="U"
    }
    for k, v in pairs(diacritics) do str = str:gsub(k, v) end
    return str
end

local function fetchTranslateAndRoman(text)
    if not text or text == "" or text == "♪" then return "", "" end
    local key = string.lower(text)
    if transCache[key] then
        return transCache[key].Trans, transCache[key].Rom
    end

    local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=id&dt=t&dt=rm&q=" .. HttpService:UrlEncode(text)
    local body = httpGet(url)
    if not body then return "", "" end

    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if ok and type(data) == "table" and type(data[1]) == "table" then
        local transParts, romParts = {}, {}
        for _, seg in ipairs(data[1]) do
            if type(seg) == "table" then
                if type(seg[1]) == "string" then
                    table.insert(transParts, seg[1])
                end
                if type(seg[4]) == "string" and seg[4] ~= "" then
                    table.insert(romParts, seg[4])
                elseif type(seg[3]) == "string" and seg[3] ~= "" then
                    table.insert(romParts, seg[3])
                end
            end
        end
        local translated = table.concat(transParts, ""):gsub("^%s+", ""):gsub("%s+$", "")
        local romanized = normalizeRomanizedASCII(table.concat(romParts, " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))

        if string.lower(translated) == key then translated = "" end
        if string.lower(romanized) == key then romanized = "" end

        transCache[key] = {Trans = translated, Rom = romanized}
        return translated, romanized
    end
    return "", ""
end

local function prefetchTranslations(lyricList, myToken)
    task.spawn(function()
        local i = 1
        while i <= #lyricList and transToken == myToken do
            if not translateEnabled and not romanizeEnabled then
                task.wait(0.5)
            else
                local lineObj = lyricList[i]
                local rawTxt = lineObj and lineObj.Text or ""
                if rawTxt ~= "" and rawTxt ~= "♪" and (lineObj.Trans == nil or lineObj.Rom == nil) then
                    local cached = transCache[string.lower(rawTxt)]
                    if cached then
                        lineObj.Trans = cached.Trans
                        lineObj.Rom = cached.Rom
                        task.wait(0.02)
                    else
                        local tr, rm = fetchTranslateAndRoman(rawTxt)
                        if transToken ~= myToken then return end
                        lineObj.Trans = tr
                        lineObj.Rom = rm
                        task.wait(0.15)
                    end
                else
                    task.wait(0.02)
                end
                i += 1
            end
        end
    end)
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
            table.insert(parsed, {Time = t, Text = text, Trans = nil, Rom = nil})
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
    if #results > 0 then cache[key] = results end
    return results
end

local function sendChat(message)
    if not message or message == "" then return end
    local safeMsg = sanitizeLyricText(message)
    local sent = false
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            local channel = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildWhichIsA("TextChannel"))
            if channel then
                channel:SendAsync(safeMsg)
                sent = true
            end
        end
    end)
    if not sent then
        pcall(function()
            local folder = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            local remote = folder and folder:FindFirstChild("SayMessageRequest")
            if remote then remote:FireServer(safeMsg, "All") end
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

local function updateSyncText()
    local modeTag = isAutoRatioActive and " (Auto)" or ""
    syncInfo.Text = string.format("Kecepatan: %.2fx%s   •   Offset: %+.2fs", lyricSpeed, modeTag, syncOffset)
    speedBtn.Text = string.format("%.2fx", lyricSpeed)
    speedBtn.TextColor3 = isAutoRatioActive and Color3.fromRGB(40, 235, 140) or Color3.fromRGB(245, 245, 245)
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
    manualSpeedOverride, autoSpeedSynced, isAutoRatioActive = false, false, false
    lyricSpeed, syncOffset = 1.00, 0.00
    if not applyDurationAutoSync() then updateSyncText() end
    showToast("Sinkronisasi direset ke Auto-Sync!")
end)
updateSyncText()

local function buildChatLine(origTxt, indoTxt, romTxt)
    local baseTxt = (romanizeEnabled and romTxt and romTxt ~= "") and romTxt or (origTxt or "")
    local cleanOrig = sanitizeLyricText(baseTxt)
    local cleanIndo = sanitizeLyricText(indoTxt or "")
    if chatLangMode == 2 and cleanIndo ~= "" then
        return cleanIndo
    elseif chatLangMode == 3 and cleanIndo ~= "" then
        return cleanOrig .. " (" .. cleanIndo .. ")"
    end
    return cleanOrig
end

local function updateDisplayedLyric(prevTxt, currTxt, nextTxt, indoTxt, romTxt, animatePop)
    local sPrev = sanitizeLyricText(prevTxt or "")
    local sCurr = sanitizeLyricText(currTxt or "")
    local sNext = sanitizeLyricText(nextTxt or "")
    local sRom  = (romanizeEnabled and romTxt and romTxt ~= "") and sanitizeLyricText(romTxt) or ""
    local sIndo = (translateEnabled and indoTxt and indoTxt ~= "") and sanitizeLyricText(indoTxt) or ""

    prevLine.Text = sPrev
    currentLine.Text = sCurr
    romLine.Text = sRom ~= "" and ("🔤 " .. sRom) or ""
    transLine.Text = sIndo ~= "" and ("🌍 " .. sIndo) or ""
    nextLine.Text = sNext

    islandLyric.Text = sRom ~= "" and sRom or sCurr
    islandTrans.Text = sIndo

    subMainText.Text = sRom ~= "" and (sCurr .. "  [" .. sRom .. "]") or sCurr
    subTransText.Text = sIndo
    subNextText.Text = sNext

    if animatePop then
        currentLine.Position = UDim2.new(0, 10, 0, 29)
        currentLine.TextTransparency = 0.35
        TweenService:Create(currentLine, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 10, 0, 23),
            TextTransparency = 0
        }):Play()

        if sIndo ~= "" then
            transLine.Position = UDim2.new(0, 10, 0, 98)
            transLine.TextTransparency = 0.45
            TweenService:Create(transLine, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 10, 0, 92),
                TextTransparency = 0
            }):Play()
        end
    end
end

local function refreshCurrentLyricDisplay(animatePop)
    if currentIndex > 0 and lyrics[currentIndex] then
        local p = 1
        while lyrics[currentIndex - p] and lyrics[currentIndex - p].Text == "" do p += 1 end
        local n = 1
        while lyrics[currentIndex + n] and lyrics[currentIndex + n].Text == "" do n += 1 end
        local itemCurr = lyrics[currentIndex]
        updateDisplayedLyric(
            lyrics[currentIndex - p] and lyrics[currentIndex - p].Text or "",
            itemCurr.Text ~= "" and itemCurr.Text or "♪",
            lyrics[currentIndex + n] and lyrics[currentIndex + n].Text or "",
            itemCurr.Trans or "",
            itemCurr.Rom or "",
            animatePop
        )
    end
end

lyricCard.MouseButton1Click:Connect(function()
    if currentIndex > 0 and lyrics[currentIndex] then
        local itemCurr = lyrics[currentIndex]
        if itemCurr.Text ~= "" then
            sendChat(buildChatLine(itemCurr.Text, itemCurr.Trans, itemCurr.Rom))
            cardStroke.Color = Color3.fromRGB(40, 235, 140)
            task.delay(0.25, function()
                if cardStroke then cardStroke.Color = Color3.fromRGB(42, 50, 64) end
            end)
        end
    end
end)

chatBtn.MouseButton1Click:Connect(function()
    autoChat = not autoChat
    lastSentLine = ""
    chatBtn.Text = "💬 Auto-Chat: " .. (autoChat and "ON" or "OFF")
    chatBtn.BackgroundColor3 = autoChat and Color3.fromRGB(35, 155, 95) or Color3.fromRGB(36, 41, 50)
    showToast("Auto-Chat " .. (autoChat and "Diaktifkan" or "Dimatikan"))
end)

chatModeBtn.MouseButton1Click:Connect(function()
    chatLangMode = (chatLangMode % 3) + 1
    chatModeBtn.Text = "🗣️ Chat: " .. chatLangNames[chatLangMode]
    showToast("Mode Bahasa Chat: " .. chatLangNames[chatLangMode])
end)

transToggleBtn.MouseButton1Click:Connect(function()
    translateEnabled = not translateEnabled
    transToggleBtn.Text = "🌍 Indo: " .. (translateEnabled and "ON" or "OFF")
    transToggleBtn.BackgroundColor3 = translateEnabled and Color3.fromRGB(30, 145, 90) or Color3.fromRGB(36, 41, 50)
    applySubtitleStyle()
    if translateEnabled and #lyrics > 0 then
        transToken += 1
        prefetchTranslations(lyrics, transToken)
    end
    refreshCurrentLyricDisplay(false)
end)

romToggleBtn.MouseButton1Click:Connect(function()
    romanizeEnabled = not romanizeEnabled
    romToggleBtn.Text = "🔤 Latin: " .. (romanizeEnabled and "ON" or "OFF")
    romToggleBtn.BackgroundColor3 = romanizeEnabled and Color3.fromRGB(185, 135, 35) or Color3.fromRGB(36, 41, 50)
    if romanizeEnabled and #lyrics > 0 then
        transToken += 1
        prefetchTranslations(lyrics, transToken)
    end
    refreshCurrentLyricDisplay(false)
end)

filterBtn.MouseButton1Click:Connect(function()
    safeFilterEnabled = not safeFilterEnabled
    filterBtn.Text = "🛡 Sensor: " .. (safeFilterEnabled and "ON" or "OFF")
    filterBtn.BackgroundColor3 = safeFilterEnabled and Color3.fromRGB(30, 145, 90) or Color3.fromRGB(36, 41, 50)
    refreshCurrentLyricDisplay(false)
end)

local resultButtons = {}

local function clearResults()
    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    resultButtons = {}
end

local function activateResult(item, selectedBtn)
    activeItem = item
    lyrics = item.Lyrics or {}
    currentIndex = 0
    lastSentLine = ""
    autoSpeedSynced, isAutoRatioActive = false, false

    for _, btn in ipairs(resultButtons) do
        btn.BackgroundColor3 = (btn == selectedBtn) and Color3.fromRGB(35, 145, 85) or Color3.fromRGB(32, 37, 46)
    end

    if not manualSpeedOverride then
        lyricSpeed = 1.00
        applyDurationAutoSync()
    end
    updateSyncText()

    status.Text = item.Title .. " — " .. item.Artist
    updateDisplayedLyric("", #lyrics > 0 and "♪ Lirik siap, menunggu sinkronisasi..." or "Lirik kosong.", "", "", "", false)
    showToast("Lirik dimuat: " .. item.Title)

    transToken += 1
    if (translateEnabled or romanizeEnabled) and #lyrics > 0 then
        prefetchTranslations(lyrics, transToken)
    end
end

local function showResults(items)
    clearResults()
    if #items == 0 then
        status.Text = "Lirik tersinkronisasi tidak ditemukan."
        updateDisplayedLyric("", "Lirik tidak tersedia.", "", "", "", false)
        return
    end
    for i, item in ipairs(items) do
        local durText = item.Duration > 0 and string.format(" (%d:%02d)", math.floor(item.Duration / 60), math.floor(item.Duration % 60)) or ""
        local b = makeButton(resultsFrame, "  " .. item.Title .. " — " .. item.Artist .. durText, UDim2.new(), UDim2.new(1, -6, 0, 28), Color3.fromRGB(32, 37, 46))
        b.LayoutOrder = i
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextTruncate = Enum.TextTruncate.AtEnd
        table.insert(resultButtons, b)
        b.MouseButton1Click:Connect(function() activateResult(item, b) end)
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
        if query and query ~= "" then table.insert(queriesToTry, query) end
        if type(fallbackQueries) == "table" then
            for _, q in ipairs(fallbackQueries) do
                if q and q ~= "" and q ~= query then table.insert(queriesToTry, q) end
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
        if matchedQuery ~= "" then searchBox.Text = matchedQuery end
        showResults(finalResults)
    end)
end

clearSearchBtn.MouseButton1Click:Connect(function()
    searchBox.Text = ""
    searchBox:CaptureFocus()
end)

searchBtn.MouseButton1Click:Connect(function()
    doSearch(searchBox.Text, {cleanSongName(searchBox.Text)})
end)
searchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then doSearch(searchBox.Text, {cleanSongName(searchBox.Text)}) end
end)

local function getInGameMusicGuiTitle()
    local guiTitle, guiArtist = "", ""
    pcall(function()
        local pGui = player:FindFirstChild("PlayerGui")
        if pGui and pGui:FindFirstChild("MusicGUI") then
            local mName = pGui.MusicGUI:FindFirstChild("MusicName")
            if mName and mName:IsA("TextLabel") then
                guiTitle = mName.Text
                local sArtist = mName:FindFirstChild("ArtistName")
                if sArtist and sArtist:IsA("TextLabel") then guiArtist = sArtist.Text end
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
            manualSpeedOverride, autoSpeedSynced, isAutoRatioActive = false, false, false
            lyricSpeed, syncOffset = 1.00, 0.00
            updateSyncText()

            progBarFill.Size = UDim2.new(0, 0, 1, 0)
            islandProgFill.Size = UDim2.new(0, 0, 1, 0)
            timeCurrentLbl.Text = "00:00"
            timeTotalLbl.Text = "00:00"

            updateDisplayedLyric("", "Mendeteksi lagu...", "", "", "", false)
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
                    if info and info.Name then rawName = info.Name end
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
                    doSearch(displayQuery, {guiTitle, cleanedRaw, aggressiveRaw, rawName})
                else
                    searchBox.Text = ""
                    status.Text = "Audio ID: " .. tostring(assetId or "Custom") .. " (Cari manual)"
                    updateDisplayedLyric("", "Judul lagu tidak terdeteksi.", "", "", "", false)
                end
            end)
        elseif not sound and activeSound then
            activeSound, activeSoundId = nil, nil
            status.Text = "Menunggu musik diputar..."
            progBarFill.Size = UDim2.new(0, 0, 1, 0)
            islandProgFill.Size = UDim2.new(0, 0, 1, 0)
            timeCurrentLbl.Text = "00:00"
            timeTotalLbl.Text = "00:00"
        end
        task.wait(0.8)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not gui.Parent then return end
    if isMinimized and activeSound and activeSound.IsPlaying then
        islandDisc.Rotation = (islandDisc.Rotation + dt * 90) % 360
    end
end)

RunService.Heartbeat:Connect(function()
    if not gui.Parent or not activeSound or not activeSound.IsPlaying then return end

    if isMutedLocally then activeSound.Volume = 0 end

    local curTime = activeSound.TimePosition or 0
    local totTime = activeSound.TimeLength or 0
    if totTime <= 0 and activeItem and activeItem.Duration > 0 then
        totTime = activeItem.Duration
    end

    timeCurrentLbl.Text = formatTime(curTime)
    timeTotalLbl.Text = formatTime(totTime)

    local progressRatio = totTime > 0 and math.clamp(curTime / totTime, 0, 1) or 0
    progBarFill.Size = UDim2.new(progressRatio, 0, 1, 0)
    islandProgFill.Size = UDim2.new(progressRatio, 0, 1, 0)

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

        if (translateEnabled or romanizeEnabled) and (line.Trans == nil or line.Rom == nil) and text ~= "" and text ~= "♪" then
            task.spawn(function()
                local tr, rm = fetchTranslateAndRoman(text)
                line.Trans = tr
                line.Rom = rm
                if currentIndex == found then
                    refreshCurrentLyricDisplay(false)
                end
            end)
        end

        updateDisplayedLyric(prevTxt, currTxt, nextTxt, line.Trans or "", line.Rom or "", true)

        if autoChat and text ~= "" then
            local chatPayload = buildChatLine(text, line.Trans, line.Rom)
            if chatPayload ~= "" and chatPayload ~= lastSentLine then
                lastSentLine = chatPayload
                sendChat(chatPayload)
            end
        end
    end
end)

applySubtitleStyle()
showToast("Koplingtify Lite v2.5 siap digunakan!")
print("Koplingtify Lite v2.5 Modular (UI + Filter + World + Sync) loaded.")
