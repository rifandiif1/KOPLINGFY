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

local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/rifandiif1/KOPLINGFY/main/KOPLINGTIFY_UI.luau"))()
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
local orbitBtn = UI.OrbitBtn
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
local userSearchBox = UI.UserSearchBox
local clearUserBtn = UI.ClearUserBtn
local refreshUserBtn = UI.RefreshUserBtn
local userListFrame = UI.UserListFrame
local userListLayout = UI.UserListLayout
local stopTrackBtn = UI.StopTrackBtn
local tpTrackBtn = UI.TpTrackBtn
local noclipBtn = UI.NoclipBtn
local wallViewBtn = UI.WallViewBtn
local orbitCfgBtn = UI.OrbitCfgBtn
local subCfgCard = UI.SubCfgCard
local subBgBtn = UI.SubBgBtn
local subColorBtn = UI.SubColorBtn
local subLockBtn = UI.SubLockBtn
local subResetBtn = UI.SubResetBtn
local orbitPanel = UI.OrbitPanel
local closeOrbitPanelBtn = UI.CloseOrbitPanelBtn
local orbitToggleInsideBtn = UI.OrbitToggleInsideBtn
local orbitDirBtn = UI.OrbitDirBtn
local orbitResetBtn = UI.OrbitResetBtn

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

local isNoClipEnabled, isWallViewEnabled = false, false
local savedCanCollide, fadedWallParts = {}, {}
local origOcclusionMode = player.DevCameraOcclusionMode

local isOrbitEnabled, wasOrbitCam = false, false
local orbitAngle, orbitDistance, orbitHeight = 0, 10.0, 3.5
local orbitSpeed, orbitLookHeight, orbitFOV, orbitDirection = 0.55, 1.0, 70, 1
local savedDefaultFOV = (workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView) or 70

local trackedPlayer, trackerHighlight, trackerBillboard, trackerNameLbl, trackerBeam, trackerAtt0, trackerAtt1 = nil, nil, nil, nil, nil, nil, nil

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

local phraseReplacements = {
    {"memudar dalam remang sunyi", "meredup dalam teduh hening"},
    {"dalam remang sunyi", "dalam teduh hening"},
    {"memudar dalam remang", "meredup dalam teduh"},
    {"remang-remang", "redup"},
    {"memiliki dirimu", "mengarungi waktumu"},
    {"memiliki kamu", "menemani kamu"},
    {"memiliki hatimu", "menjaga hatimu"},
    {"miliki dirimu", "temani langkahmu"},
    {"utuh milikku", "utuh untukku"},
    {"jadi milikku", "jadi temanku"},
    {"menjadi milikku", "menjadi bagianku"},
    {"seutuhnya milikmu", "seutuhnya untukmu"},
    {"shut the fuck up", "keep it quiet"},
    {"what the fuck", "what the heck"},
    {"what the hell", "what the heck"},
    {"piece of shit", "piece of junk"},
    {"son of a bitch", "rascal"},
    {"kill yourself", "take care"},
    {"killing myself", "losing myself"},
    {"want to die", "want to fly"},
    {"wanna die", "wanna fly"},
    {"gonna die", "gonna fly"},
    {"make love", "hold hands"},
    {"one night stand", "late night dance"},
    {"bunuh diri", "menyerah"},
    {"kurang ajar", "nakal sekali"},
    {"anak haram", "anak jalanan"},
    {"anak pungut", "anak rantau"},
    {"tidur denganmu", "duduk denganmu"},
    {"tidur bersamamu", "duduk bersamamu"},
    {"di atas ranjang", "di atas awan"},
    {"di dalam kamar", "di dalam ruang"},
    {"jatuh cinta", "jatuh hati"},
    {"putus cinta", "patah hati"},
    {"malam pertama", "malam indah"},
    {"peluk erat", "genggam erat"},
    {"cium kening", "sapa hangat"},
    {"cium pipi", "sapa manis"},
    {"buka baju", "lepas jaket"},
    {"ganti baju", "ganti gaya"},
    {"nomor hp", "kode frekuensi"},
    {"nomor telepon", "kode frekuensi"},
    {"berapa umurmu", "apa kabarmu"},
    {"sleep with me", "stay with me"},
    {"sleeping with", "staying with"},
    {"in my bed", "in my head"},
    {"on the bed", "on the floor"},
    {"in the bedroom", "in the room"},
    {"kiss me", "miss me"},
    {"kissing you", "missing you"},
    {"kissed you", "missed you"},
    {"hold my hand", "stand by me"},
    {"touch my body", "feel the rhythm"},
    {"touch your body", "feel the music"},
    {"take off your", "put on your"},
    {"fall in love", "fall apart"},
    {"be my girlfriend", "be my friend"},
    {"be my boyfriend", "be my friend"},
    {"phone number", "lucky charm"},
    {"how old are you", "how are you"}
}

local wordReplacements = {
    ["memnudar"] = "meredup", ["memudar"] = "meredup", ["pudar"] = "redup",
    ["remang"] = "teduh", ["sunyi"] = "hening", ["sepi"] = "tenang",
    ["kesepian"] = "sendirian", ["gelap"] = "malam", ["kegelapan"] = "malam",
    ["hampa"] = "kosong", ["kelam"] = "sendu", ["lara"] = "duka", ["pilu"] = "sendu",
    ["memiliki"] = "mendapati", ["memilikimu"] = "menemanimu", ["miliki"] = "dapati",
    ["milikku"] = "bagianku", ["milikmu"] = "bagianmu", ["dirimu"] = "sosokmu", ["diriku"] = "sosokku",
    ["motherfucker"] = "troublemaker", ["motherfuckers"] = "troublemakers",
    ["motherfuckin"] = "freakin", ["motherfucking"] = "freaking",
    ["muthafucka"] = "troublemaker", ["muthafuckin"] = "freakin",
    ["mf"] = "pal", ["fucking"] = "freaking", ["fuckin"] = "freakin",
    ["fckin"] = "freakin", ["fcking"] = "freaking", ["fucked"] = "messed",
    ["fucker"] = "joker", ["fuckers"] = "jokers", ["fuck"] = "freak",
    ["fucks"] = "cares", ["fck"] = "freak", ["fuk"] = "freak", ["fuq"] = "freak",
    ["wtf"] = "what", ["stfu"] = "shh", ["shitting"] = "kidding",
    ["shitty"] = "messy", ["bullshit"] = "nonsense", ["horseshit"] = "nonsense",
    ["dipshit"] = "goofball", ["shithead"] = "airhead", ["shits"] = "shoots",
    ["shit"] = "shoot", ["sht"] = "shoot", ["bitching"] = "complaining",
    ["bitches"] = "witches", ["bitchy"] = "sassy", ["bitch"] = "witch",
    ["btch"] = "witch", ["biatch"] = "witch", ["assholes"] = "rascals",
    ["asshole"] = "rascal", ["dumbass"] = "silly", ["jackass"] = "clown",
    ["badass"] = "cool", ["fatass"] = "heavy", ["asses"] = "butts",
    ["ass"] = "butt", ["arse"] = "butt", ["bastards"] = "rascals",
    ["bastard"] = "rascal", ["dammit"] = "darnit", ["damned"] = "darned",
    ["damn"] = "darn", ["goddammit"] = "goshdarn", ["goddamn"] = "goshdarn",
    ["hella"] = "super", ["hell"] = "heck", ["cunts"] = "jerks", ["cunt"] = "jerk",
    ["dicks"] = "jerks", ["dickhead"] = "blockhead", ["dick"] = "jerk",
    ["cocks"] = "roosters", ["cock"] = "rooster", ["pussies"] = "kitties",
    ["pussy"] = "kitty", ["twat"] = "fool", ["prick"] = "thorn",
    ["wanker"] = "joker", ["bollocks"] = "nonsense", ["bugger"] = "rascal",
    ["douchebag"] = "showoff", ["douche"] = "showoff", ["scumbag"] = "villain",
    ["slutty"] = "flirty", ["sluts"] = "heartbreakers", ["slut"] = "heartbreaker",
    ["whores"] = "players", ["whore"] = "player", ["hoe"] = "player",
    ["hoes"] = "players", ["skank"] = "meanie", ["prostitute"] = "dancer",
    ["stripper"] = "dancer", ["hooker"] = "dancer", ["pimp"] = "boss",
    ["nigga"] = "homie", ["niggas"] = "homies", ["niggaz"] = "homies",
    ["nigger"] = "brother", ["niggers"] = "brothers", ["nibba"] = "homie",
    ["negro"] = "fellow", ["faggot"] = "fool", ["faggots"] = "fools",
    ["fag"] = "fool", ["fags"] = "fools", ["dyke"] = "rebel",
    ["tranny"] = "person", ["retard"] = "silly", ["retards"] = "goofballs",
    ["retarded"] = "foolish", ["cripple"] = "broken", ["spastic"] = "frantic",
    ["suicidal"] = "hopeless", ["suicide"] = "give up", ["kms"] = "sigh", ["kys"] = "bye",
    ["killing"] = "chilling", ["killed"] = "chilled", ["killer"] = "hunter",
    ["kills"] = "chills", ["kill"] = "chill", ["murderer"] = "stranger",
    ["murdered"] = "vanished", ["murdering"] = "chasing", ["murder"] = "mystery",
    ["homicide"] = "incident", ["genocide"] = "wipeout", ["massacre"] = "chaos",
    ["slaughter"] = "defeat", ["butcher"] = "fighter", ["dying"] = "fading",
    ["died"] = "faded", ["dies"] = "fades", ["die"] = "fly", ["dead"] = "gone",
    ["death"] = "sleep", ["corpse"] = "statue", ["coffin"] = "box", ["grave"] = "ground",
    ["bleeding"] = "crying", ["bleed"] = "cry", ["bloody"] = "messy", ["blood"] = "sweat",
    ["gore"] = "mess", ["stabbed"] = "poked", ["stabbing"] = "poking", ["stab"] = "poke",
    ["slit"] = "cut", ["choke"] = "gasp", ["choking"] = "gasping", ["strangle"] = "grab",
    ["hang"] = "hold", ["hanged"] = "held", ["shoot"] = "blast", ["shooting"] = "blasting",
    ["shotgun"] = "blaster", ["gunshot"] = "thunder", ["guns"] = "blasters", ["gun"] = "blaster",
    ["pistol"] = "blaster", ["rifle"] = "blaster", ["glock"] = "blaster", ["ak47"] = "blaster",
    ["bullets"] = "sparks", ["bullet"] = "spark", ["trigger"] = "switch", ["bomb"] = "boom",
    ["terrorist"] = "villain", ["terrorism"] = "chaos", ["hostage"] = "captive",
    ["torture"] = "trouble", ["abuse"] = "mistreat", ["violent"] = "wild", ["violence"] = "chaos",
    ["sexual"] = "romantic", ["sexually"] = "deeply", ["sex"] = "love",
    ["sexy"] = "lovely", ["sexiest"] = "loveliest", ["porn"] = "movie",
    ["porno"] = "movie", ["hentai"] = "anime", ["nsfw"] = "secret",
    ["nude"] = "bare", ["nudes"] = "photos", ["naked"] = "bare",
    ["horny"] = "lonely", ["orgasm"] = "climax", ["climax"] = "peak",
    ["cum"] = "come", ["cumming"] = "coming", ["sperm"] = "seed",
    ["erection"] = "rising", ["boner"] = "spark", ["boobs"] = "chest",
    ["boob"] = "chest", ["titties"] = "chest", ["tits"] = "chest", ["tit"] = "chest",
    ["nipples"] = "buttons", ["nipple"] = "button", ["booty"] = "hips",
    ["thighs"] = "legs", ["virgin"] = "innocent", ["virginity"] = "innocence",
    ["lust"] = "desire", ["fetish"] = "habit", ["kinky"] = "quirky", ["bdsm"] = "chains",
    ["rape"] = "hurt", ["raped"] = "hurt", ["rapist"] = "villain", ["molest"] = "bother",
    ["pedophile"] = "creep", ["pedo"] = "creep", ["incest"] = "kin",
    ["drugs"] = "sweets", ["drug"] = "candy", ["weed"] = "herb", ["marijuana"] = "herbs",
    ["cannabis"] = "herbs", ["blunt"] = "stick", ["joint"] = "roll", ["stoned"] = "sleepy",
    ["cocaine"] = "powder", ["coke"] = "soda", ["heroin"] = "potion", ["meth"] = "crystal",
    ["ecstasy"] = "joy", ["molly"] = "candy", ["lsd"] = "dream", ["acid"] = "lemon",
    ["pills"] = "mints", ["pill"] = "mint", ["overdose"] = "overload", ["addict"] = "fan",
    ["addicted"] = "hooked", ["nicotine"] = "caffeine", ["cigarette"] = "candle",
    ["cigarettes"] = "candles", ["vape"] = "mist", ["smoking"] = "glowing",
    ["smoke"] = "cloud", ["drunk"] = "dizzy", ["wasted"] = "tired", ["tipsy"] = "giggly",
    ["alcohol"] = "soda", ["liquor"] = "juice", ["whiskey"] = "tea", ["vodka"] = "water",
    ["tequila"] = "lemonade", ["beer"] = "rootbeer", ["wine"] = "grape",
    ["champagne"] = "sparkling", ["bartender"] = "barista",
    ["kiss"] = "greet", ["kisses"] = "smiles", ["kissing"] = "smiling", ["kissed"] = "smiled",
    ["hug"] = "hold", ["hugs"] = "holds", ["hugging"] = "holding", ["hugged"] = "held",
    ["cuddle"] = "huddle", ["cuddling"] = "huddling", ["caress"] = "breeze",
    ["touch"] = "reach", ["touches"] = "reaches", ["touching"] = "reaching", ["touched"] = "reached",
    ["lips"] = "smile", ["lip"] = "smile", ["tongue"] = "voice", ["neck"] = "shoulder",
    ["chest"] = "heart", ["waist"] = "side", ["hips"] = "steps", ["hip"] = "step",
    ["thigh"] = "leg", ["skin"] = "glow", ["body"] = "soul", ["bodies"] = "souls",
    ["sweat"] = "rain", ["sweating"] = "shining", ["breath"] = "wind", ["breathe"] = "sigh",
    ["breathing"] = "sighing", ["moan"] = "sigh", ["moaning"] = "sighing", ["whisper"] = "echo",
    ["undress"] = "unwind", ["clothes"] = "outfit", ["shirt"] = "jacket", ["pants"] = "shoes",
    ["skirt"] = "dress", ["underwear"] = "gear", ["bra"] = "top", ["panties"] = "gear",
    ["bikini"] = "swimsuit", ["bed"] = "cloud", ["bedroom"] = "room", ["sheets"] = "clouds",
    ["pillow"] = "cushion", ["blanket"] = "cover", ["shower"] = "rain", ["hotel"] = "tower",
    ["motel"] = "tower", ["boyfriend"] = "partner", ["girlfriend"] = "partner",
    ["lover"] = "dreamer", ["lovers"] = "dreamers", ["dating"] = "hanging", ["date"] = "meet",
    ["marry"] = "promise", ["married"] = "promised", ["wedding"] = "party",
    ["husband"] = "partner", ["wife"] = "partner", ["bride"] = "star", ["groom"] = "star",
    ["babe"] = "star", ["baby"] = "darling", ["honey"] = "sweetie", ["sugar"] = "sweet",
    ["shawty"] = "shorty", ["shorty"] = "friend", ["daddy"] = "boss", ["mommy"] = "queen",
    ["crush"] = "spark", ["flirt"] = "tease", ["flirting"] = "joking", ["seduce"] = "charm",
    ["jealous"] = "envious", ["cheating"] = "lying", ["cheat"] = "trick", ["ex"] = "past",
    ["anjing"] = "kucing", ["anjir"] = "astaga", ["anjay"] = "keren", ["anjrit"] = "waduh",
    ["anjrot"] = "waduh", ["anying"] = "kucing", ["njir"] = "wah", ["njay"] = "keren",
    ["asu"] = "kucing", ["babi"] = "kelinci", ["celeng"] = "kelinci", ["monyet"] = "kera",
    ["kunyuk"] = "kera", ["kampret"] = "kelelawar", ["bangsat"] = "nakal", ["bgst"] = "nakal",
    ["brengsek"] = "bandel", ["bajingan"] = "penjahat", ["keparat"] = "nakal", ["bedebah"] = "bandel",
    ["kurangajar"] = "nakal", ["sialan"] = "aduhai", ["sial"] = "malang", ["bangke"] = "ranting",
    ["bangkai"] = "ranting", ["tai"] = "debu", ["tahi"] = "debu", ["taik"] = "debu",
    ["berak"] = "pergi", ["kentut"] = "angin", ["kencing"] = "air", ["bacot"] = "bicara",
    ["bct"] = "bicara", ["cocot"] = "mulut", ["congor"] = "mulut", ["nyinyir"] = "cerewet",
    ["mampus"] = "habis", ["modar"] = "habis", ["kojor"] = "lemas", ["matek"] = "lemas",
    ["setan"] = "bayangan", ["syaiton"] = "bayangan", ["iblis"] = "bayangan", ["dajjal"] = "raksasa",
    ["neraka"] = "lembah", ["jahanam"] = "gelap", ["laknat"] = "buruk", ["terkutuk"] = "terlupakan",
    ["haram"] = "terlarang", ["dosa"] = "salah", ["berdosa"] = "bersalah", ["kafir"] = "asing",
    ["goblok"] = "polos", ["goblog"] = "polos", ["gblk"] = "polos", ["tolol"] = "lucu",
    ["tll"] = "lucu", ["bodoh"] = "polos", ["bego"] = "lugu", ["begok"] = "lugu",
    ["oon"] = "lugu", ["bloon"] = "lugu", ["dungu"] = "polos", ["idiot"] = "unik",
    ["autis"] = "fokus", ["cacat"] = "kurang", ["gila"] = "heboh", ["sinting"] = "heboh",
    ["sarap"] = "heboh", ["edan"] = "heboh", ["stres"] = "pusing", ["depresi"] = "sedih",
    ["frustrasi"] = "kecewa", ["budek"] = "kurang dengar", ["buta"] = "gelap", ["bisu"] = "diam",
    ["pincang"] = "pelan", ["gendut"] = "gemoy", ["gembrot"] = "gemoy", ["ceking"] = "ramping",
    ["jelek"] = "biasa", ["burik"] = "pudar", ["dekil"] = "lusuh", ["miskin"] = "sederhana",
    ["melarat"] = "sederhana", ["gembel"] = "pengembara", ["pengemis"] = "pencari",
    ["sampah"] = "dedaunan", ["pecundang"] = "pemula", ["cupu"] = "pemula", ["noob"] = "pemula",
    ["jancok"] = "astaga", ["jancuk"] = "astaga", ["dancok"] = "astaga", ["cuk"] = "kawan",
    ["cok"] = "kawan", ["jangkrik"] = "belalang", ["matamu"] = "matanya", ["ndasmu"] = "kepalamu",
    ["lambemu"] = "ucapanmu", ["raimu"] = "wajahmu", ["pantek"] = "waduh", ["kimak"] = "astaga",
    ["pukimak"] = "astaga", ["puki"] = "kucing", ["sundal"] = "nakal",
    ["kontol"] = "konyol", ["kntl"] = "konyol", ["memek"] = "bebek", ["mmk"] = "bebek",
    ["pepek"] = "bebek", ["jembut"] = "rambut", ["jmbt"] = "rambut", ["itil"] = "kecil",
    ["pentil"] = "ujung", ["tetek"] = "dada", ["tete"] = "dada", ["toket"] = "dada",
    ["payudara"] = "hati", ["buahdada"] = "hati", ["pantat"] = "belakang", ["bokong"] = "belakang",
    ["bool"] = "belakang", ["selangkangan"] = "pinggang", ["kelamin"] = "raga", ["zakar"] = "raga",
    ["vagina"] = "bunga", ["penis"] = "batang", ["ngentot"] = "joget", ["entot"] = "joget",
    ["ngewe"] = "joget", ["ewe"] = "joget", ["kenthu"] = "joget", ["kimpoi"] = "menikah",
    ["kawin"] = "menikah", ["peju"] = "keju", ["mani"] = "embun", ["sperma"] = "benih",
    ["coli"] = "sendiri", ["onani"] = "sendiri", ["masturbasi"] = "melamun",
    ["desah"] = "napas", ["mendesah"] = "bernapas", ["sange"] = "rindu", ["horni"] = "rindu",
    ["nafsu"] = "hasrat", ["birahi"] = "hasrat", ["gairah"] = "semangat", ["syahwat"] = "perasaan",
    ["perawan"] = "gadis", ["keperawanan"] = "kesucian", ["perjaka"] = "jejaka",
    ["pelacur"] = "penari", ["lonte"] = "bunga", ["psk"] = "pekerja", ["jablay"] = "santai",
    ["bispak"] = "santai", ["openbo"] = "jalan", ["michat"] = "pesan", ["mucikari"] = "perantara",
    ["germo"] = "perantara", ["simpanan"] = "rahasia", ["selingkuh"] = "mendua",
    ["selingkuhan"] = "bayangan", ["pelakor"] = "penggoda", ["pebinor"] = "penggoda",
    ["telanjang"] = "polos", ["bugil"] = "polos", ["seksi"] = "anggun", ["montok"] = "indah",
    ["bohay"] = "indah", ["semok"] = "indah", ["bercinta"] = "berdansa", ["seks"] = "cinta",
    ["seksual"] = "romantis", ["bokep"] = "film", ["mesum"] = "nakal", ["cabul"] = "nakal",
    ["perkosa"] = "lukai", ["memperkosa"] = "melukai", ["pemerkosaan"] = "kejahatan",
    ["pelecehan"] = "gangguan", ["mati"] = "pergi", ["matilah"] = "pergilah",
    ["kematian"] = "kepergian", ["meninggal"] = "berpulang", ["tewas"] = "gugur",
    ["bunuh"] = "kejar", ["membunuh"] = "mengejar", ["pembunuh"] = "pemburu",
    ["pembunuhan"] = "perburuan", ["bantai"] = "kalahkan", ["membantai"] = "mengalahkan",
    ["cekik"] = "pegang", ["mencekik"] = "memegang", ["tikam"] = "sentuh", ["menikam"] = "menyentuh",
    ["tusuk"] = "sentuh", ["menusuk"] = "menyentuh", ["bacok"] = "tebas", ["membacok"] = "menebas",
    ["penggal"] = "potong", ["gantung"] = "ayun", ["darah"] = "merah", ["berdarah"] = "terluka",
    ["mayat"] = "patung", ["jenazah"] = "raga", ["kuburan"] = "taman", ["makam"] = "taman",
    ["pisau"] = "pedang", ["belati"] = "pedang", ["golok"] = "pedang", ["celurit"] = "sabit",
    ["senjata"] = "alat", ["peluru"] = "cahaya", ["tembak"] = "bidik", ["menembak"] = "membidik",
    ["racun"] = "ramuan", ["beracun"] = "berbahaya", ["meracuni"] = "mengganggu",
    ["mabuk"] = "pusing", ["mabok"] = "pusing", ["teler"] = "lelah", ["miras"] = "sirup",
    ["alkohol"] = "soda", ["bir"] = "soda", ["anggur"] = "jus", ["tuak"] = "air",
    ["ciu"] = "air", ["amer"] = "sirup", ["intisar"] = "sirup", ["narkoba"] = "permen",
    ["narkotika"] = "permen", ["ganja"] = "daun", ["sabu"] = "kristal", ["ekstasi"] = "permen",
    ["heroin"] = "bubuk", ["kokain"] = "bubuk", ["pil"] = "permen", ["obat"] = "jamu",
    ["rokok"] = "asap", ["merokok"] = "berasap", ["judi"] = "main", ["berjudi"] = "bermain",
    ["bandar"] = "penjaga", ["slot"] = "mesin", ["maling"] = "pencari", ["pencuri"] = "pengambil",
    ["merampok"] = "mengambil", ["korupsi"] = "curang", ["penjara"] = "istana",
    ["peluk"] = "rengkuh", ["memeluk"] = "merengkuh", ["memelukmu"] = "merengkuhmu",
    ["pelukan"] = "rengkuhan", ["pelukanmu"] = "rengkuhanmu", ["dipeluk"] = "direngkuh",
    ["dekap"] = "jaga", ["mendekap"] = "menjaga", ["dekapan"] = "naungan",
    ["rangkul"] = "gandeng", ["merangkul"] = "menggandeng", ["cium"] = "sapa",
    ["mencium"] = "menyapa", ["menciummu"] = "menyapamu", ["ciuman"] = "sapaan",
    ["dicium"] = "disapa", ["kecup"] = "sapa", ["mengecup"] = "menyapa", ["kecupan"] = "sapaan",
    ["belai"] = "usap", ["membelai"] = "mengusap", ["belaian"] = "usapan",
    ["sentuh"] = "raih", ["menyentuh"] = "meraih", ["menyentuhmu"] = "meraihmu",
    ["sentuhan"] = "raihan", ["tersentuh"] = "tergugah", ["raba"] = "cari", ["meraba"] = "mencari",
    ["pangku"] = "damping", ["memangku"] = "mendampingi", ["pangkuan"] = "sisi",
    ["gandeng"] = "iring", ["menggandeng"] = "mengiringi", ["elus"] = "usap", ["mengelus"] = "mengusap",
    ["pacar"] = "rekan", ["pacarku"] = "rekanku", ["pacarmu"] = "rekanmu",
    ["pacaran"] = "berteman", ["berpacaran"] = "berteman", ["kekasih"] = "pujaan",
    ["kekasihku"] = "pujaanku", ["kekasihmu"] = "pujaanmu", ["sayang"] = "kasih",
    ["sayangku"] = "kasihku", ["sayangi"] = "kasihi", ["menyayangi"] = "mengasihi",
    ["kesayangan"] = "kebanggaan", ["cinta"] = "asa", ["cintaku"] = "asaku", ["cintamu"] = "asamu",
    ["mencintai"] = "mengagumi", ["mencintaimu"] = "mengagumimu", ["dicintai"] = "dikagumi",
    ["percintaan"] = "perjalanan", ["asmara"] = "irama", ["kasmaran"] = "bahagia",
    ["romantis"] = "manis", ["mesra"] = "akrab", ["kemesraan"] = "keakraban",
    ["bermesraan"] = "bercanda", ["kencan"] = "jalan", ["berkencan"] = "berjalan",
    ["jadian"] = "bersama", ["gebetan"] = "idola", ["mantan"] = "kenangan",
    ["mantanku"] = "masa laluku", ["nikah"] = "janji", ["menikah"] = "berjanji",
    ["menikahimu"] = "menemanimu", ["pernikahan"] = "ikatan", ["pengantin"] = "pasangan",
    ["suami"] = "pendamping", ["suamiku"] = "pendampingku", ["istri"] = "pendamping",
    ["istriku"] = "pendampingku", ["jodoh"] = "takdir", ["rayu"] = "bujuk",
    ["merayu"] = "membujuk", ["rayuan"] = "pujian", ["goda"] = "canda",
    ["menggoda"] = "bercanda", ["godaan"] = "candaan", ["bibir"] = "senyum",
    ["bibirmu"] = "senyummu", ["bibirku"] = "senyumku", ["lidah"] = "ucap",
    ["leher"] = "bahu", ["lehermu"] = "bahumu", ["dada"] = "hati", ["dadamu"] = "hatimu",
    ["dadaku"] = "hatiku", ["perut"] = "raga", ["pinggang"] = "sisi", ["pinggul"] = "langkah",
    ["paha"] = "kaki", ["kulit"] = "rona", ["kulitmu"] = "ronamu", ["tubuh"] = "raga",
    ["tubuhmu"] = "ragamu", ["tubuhku"] = "ragaku", ["badan"] = "raga", ["badanmu"] = "ragamu",
    ["badanku"] = "ragaku", ["keringat"] = "peluh", ["berkeringat"] = "berpeluh",
    ["desahan"] = "hembusan", ["napas"] = "hembus", ["napasmu"] = "hembusanmu",
    ["baju"] = "jubah", ["bajumu"] = "jubahmu", ["celana"] = "pakaian", ["rok"] = "gaun",
    ["pakaian"] = "busana", ["handuk"] = "kain", ["kamar"] = "ruang", ["kamarmu"] = "ruangmu",
    ["kamarku"] = "ruangku", ["ranjang"] = "peraduan", ["kasur"] = "alas",
    ["bantal"] = "sandaran", ["selimut"] = "penghangat", ["guling"] = "sandaran",
    ["tidur"] = "lelap", ["tidurlah"] = "lelaplah", ["meniduri"] = "menemani",
    ["ketiduran"] = "terlelap", ["mandi"] = "basuh", ["hotel"] = "gedung",
    ["penginapan"] = "singgahan", ["kos"] = "tempat", ["kosan"] = "tempat",
    ["umur"] = "waktu", ["umurmu"] = "waktumu", ["umurku"] = "waktuku", ["usia"] = "masa",
    ["alamat"] = "arah", ["nomor"] = "angka", ["telepon"] = "suara", ["hp"] = "layar",
    ["handphone"] = "layar", ["wa"] = "pesan", ["ig"] = "galeri", ["fb"] = "halaman",
    ["tt"] = "video", ["uang"] = "koin", ["duit"] = "koin", ["bayar"] = "tukar",
    ["membayar"] = "menukar", ["jual"] = "beri", ["beli"] = "ambil", ["harga"] = "nilai",
    ["murahan"] = "sederhana",
    ["discord"] = "radio", ["tiktok"] = "clock", ["instagram"] = "camera",
    ["whatsapp"] = "phone", ["telegram"] = "letter", ["youtube"] = "video",
    ["twitter"] = "bird", ["facebook"] = "book", ["snapchat"] = "ghost",
    ["tinder"] = "flame", ["onlyfans"] = "fanclub", ["spotify"] = "music"
}

local function matchCase(original, replacement)
    if replacement == "" then return "" end
    if original == original:upper() and #original > 1 then
        return replacement:upper()
    elseif original:sub(1, 1) == original:sub(1, 1):upper() then
        return replacement:sub(1, 1):upper() .. replacement:sub(2)
    end
    return replacement
end

local function sanitizeLyricText(text)
    if not text or text == "" or not safeFilterEnabled then return text end
    local cleaned = text

    for _, pair in ipairs(phraseReplacements) do
        local badPhrase, goodPhrase = pair[1], pair[2]
        local pattern = badPhrase:gsub("(%a)", function(c)
            return string.format("[%s%s]", c:lower(), c:upper())
        end)
        cleaned = cleaned:gsub(pattern, goodPhrase)
    end

    cleaned = cleaned:gsub("([%a'*%-]+)", function(word)
        local lowerWord = word:lower()
        if lowerWord:find("%*") then
            if lowerWord:match("^f.*k$") then return matchCase(word, "freak") end
            if lowerWord:match("^s.*t$") then return matchCase(word, "shoot") end
            if lowerWord:match("^b.*h$") then return matchCase(word, "witch") end
            if lowerWord:match("^n.*a$") or lowerWord:match("^n.*r$") then return matchCase(word, "homie") end
            if lowerWord:match("^c.*t$") then return matchCase(word, "jerk") end
            if lowerWord:match("^d.*k$") then return matchCase(word, "jerk") end
            return word:gsub("%*", "")
        end

        if wordReplacements[lowerWord] then
            return matchCase(word, wordReplacements[lowerWord])
        end

        local stripped = lowerWord:gsub("'", "")
        if wordReplacements[stripped] then
            return matchCase(word, wordReplacements[stripped])
        end

        if lowerWord:find("%-") then
            local parts = string.split(word, "-")
            for i, p in ipairs(parts) do
                local lp = p:lower():gsub("'", "")
                if wordReplacements[lp] then
                    parts[i] = matchCase(p, wordReplacements[lp])
                end
            end
            return table.concat(parts, "-")
        end

        local root, suffix = stripped:match("^([%a]+)(nya)$")
        if not root then root, suffix = stripped:match("^([%a]+)(mu)$") end
        if not root then root, suffix = stripped:match("^([%a]+)(ku)$") end
        if not root then root, suffix = stripped:match("^([%a]+)(lah)$") end
        if root and wordReplacements[root] then
            return matchCase(word, wordReplacements[root] .. suffix)
        end

        return word
    end)

    cleaned = cleaned:gsub("(%d)(%d)", "%1 %2"):gsub("(%d)(%d)", "%1 %2")
    return cleaned
end

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

-- ======================== PLAYER LOCATOR ESP ========================
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

-- ======================== KONTROL SUBTITLE, ORBIT, NOCLIP & TEMBOK ========================
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
    if isOrbitEnabled then isOrbitEnabled = false; resetCameraToNormal() end
    if isNoClipEnabled then isNoClipEnabled = false; restoreCharacterCollision() end
    if isWallViewEnabled then isWallViewEnabled = false; applyWallOcclusionMode() end
    clearPlayerLocator()
    gui:Destroy()
end)

-- ======================== SINKRONISASI & SPEED CONTROL ========================
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

-- ======================== TAMPILAN LIRIK & CHAT ========================
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
print("Koplingtify Lite v2.5 Modular Sync loaded.")
