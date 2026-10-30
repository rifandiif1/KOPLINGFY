-- =========================================================================
-- HAWK909 DYNAMIC AUDIO TRACKER - THE ULTIMATE TITAN (ARCEUS X NEO & ANDROID)
-- =========================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    Players.PlayerAdded:Wait()
    LocalPlayer = Players.LocalPlayer
end

local songCache, lyricsCache = {}, {}
local currentSongId, activeSound = nil, nil
local activeLyrics = {}
local currentLyricMatches = {}
local isWidgetVisible = false

-- Global Variables
local lyricOffset, lyricSpeed = 0.0, 1.0 
local autoChatEnabled, manualSpeedOverride, isMutedLocally = false, false, false
local originalVolume = 0.5
local isHologramEnabled, isMinimized, isCinematic = false, false, false
local currentCam = Workspace.CurrentCamera or Workspace:WaitForChild("Camera", 5)
local targetBaseFOV = currentCam and currentCam.FieldOfView or 70
local originalFOV = targetBaseFOV
local currentLyricProvider = "LRCLIB"
local wasCinematicCam = false

-- // OVERLAY INDEPENDENT SETTINGS //
local overlayMode = 0 -- 0=Mati, 1=Bawah Cine, 2=Kanan, 3=Kiri, 4=Subtitle
local ovSettings = {
    [1] = {x=0, y=0, sz=20, ven=true, vpos=2, vsz=15, cr=1, cg=1, cb=1, vr=0.11, vg=0.84, vb=0.37},
    [2] = {x=0, y=0, sz=20, ven=true, vpos=2, vsz=15, cr=1, cg=1, cb=1, vr=0.11, vg=0.84, vb=0.37},
    [3] = {x=0, y=0, sz=20, ven=true, vpos=2, vsz=15, cr=1, cg=1, cb=1, vr=0.11, vg=0.84, vb=0.37},
    [4] = {x=0, y=0, sz=24, ven=true, vpos=2, vsz=10, cr=1, cg=1, cb=1, vr=0.11, vg=0.84, vb=0.37}
}

-- // 0. LOCAL MP3 INJECTOR ENGINE //
local CustomAudioPlayer = Workspace:FindFirstChild("Hawk909LocalAudio")
if not CustomAudioPlayer then
    CustomAudioPlayer = Instance.new("Sound")
    CustomAudioPlayer.Name = "Hawk909LocalAudio"
    CustomAudioPlayer.Parent = Workspace
end

-- CLEAN & SETUP POST-PROCESSING (DLSS 5 ENGINE)
for _, v in pairs(Lighting:GetChildren()) do 
    if v.Name == "Hawk909_DoF" or v.Name == "Hawk909_CineCC" or v.Name == "Hawk909_DLSSColor" or v.Name == "Hawk909_DLSSBloom" then 
        v:Destroy() 
    end 
end

local CineCC = Instance.new("ColorCorrectionEffect"); CineCC.Name = "Hawk909_CineCC"; CineCC.Saturation = 0; CineCC.Contrast = 0; CineCC.Enabled = false; CineCC.Parent = Lighting
local CineDoF = Instance.new("DepthOfFieldEffect"); CineDoF.Name = "Hawk909_DoF"; CineDoF.FocusDistance = 10; CineDoF.InFocusRadius = 15; CineDoF.NearIntensity = 1; CineDoF.FarIntensity = 1; CineDoF.Enabled = false; CineDoF.Parent = Lighting
local DLSSColor = Instance.new("ColorCorrectionEffect"); DLSSColor.Name = "Hawk909_DLSSColor"; DLSSColor.Contrast = 0.15; DLSSColor.Saturation = 0.1; DLSSColor.Brightness = 0.02; DLSSColor.Enabled = false; DLSSColor.Parent = Lighting
local DLSSBloom = Instance.new("BloomEffect"); DLSSBloom.Name = "Hawk909_DLSSBloom"; DLSSBloom.Intensity = 1.5; DLSSBloom.Size = 30; DLSSBloom.Threshold = 0.8; DLSSBloom.Enabled = false; DLSSBloom.Parent = Lighting

-- // 1. AUTO-SAVE ENGINE & VARIABLES //
local holoOffsetX, holoOffsetY, holoOffsetZ = 8, 1.5, 0
local holoTextColor, holoGlowColor = Color3.fromRGB(255, 255, 255), Color3.fromRGB(30, 215, 96) 
local holoTextSize = 32
local bassGlowEnabled, particlesEnabled, karaoke3DEnabled, vis3DEnabled = true, true, true, true
local holoAlign = 0 
local cineOrbit, cineOTS, cineShake, cineDoFState, cineGlitch, cineVignette, cineGhost = false, false, false, false, false, false, false
local cineFOVPulse, cineLowAngle, cineRipple, cineSpotlight, cineDLSS = false, false, false, false, false

pcall(function()
    if type(isfile) == "function" and type(readfile) == "function" and isfile("Hawk909_TitanConfig_v3.txt") then
        local data = HttpService:JSONDecode(readfile("Hawk909_TitanConfig_v3.txt"))
        if data then
            holoOffsetX = data.X or 8; holoOffsetY = data.Y or 1.5; holoOffsetZ = data.Z or 0
            if data.R and data.G and data.B then holoTextColor = Color3.new(data.R, data.G, data.B) end
            if data.GR and data.GG and data.GB then holoGlowColor = Color3.new(data.GR, data.GG, data.GB) end
            holoTextSize = data.Size or 32; holoAlign = data.Align or 0
            bassGlowEnabled = data.BassGlow ~= false; particlesEnabled = data.Particles ~= false
            karaoke3DEnabled = data.Karaoke ~= false; vis3DEnabled = data.Vis3D ~= false
            cineOrbit = data.COrbit or false; cineOTS = data.COTS or false; cineShake = data.CShake or false
            cineDoFState = data.CDoF or false; cineGlitch = data.CGlitch or false; cineVignette = data.CVignette or false
            cineGhost = data.CGhost or false; cineFOVPulse = data.CFov or false; cineLowAngle = data.CLow or false
            cineRipple = data.CRipple or false; cineSpotlight = data.CSpot or false; cineDLSS = data.CDLSS or false
            
            overlayMode = data.OvMode or 0
            if data.OvSets then
                for k, v in pairs(data.OvSets) do
                    local numKey = tonumber(k) or k
                    if ovSettings[numKey] then ovSettings[numKey] = v end
                end
            end
        end
    end
end)

local function SaveHoloSettings()
    pcall(function()
        local data = { 
            X = holoOffsetX, Y = holoOffsetY, Z = holoOffsetZ, R = holoTextColor.R, G = holoTextColor.G, B = holoTextColor.B,
            GR = holoGlowColor.R, GG = holoGlowColor.G, GB = holoGlowColor.B, Size = holoTextSize, Align = holoAlign,
            BassGlow = bassGlowEnabled, Particles = particlesEnabled, Karaoke = karaoke3DEnabled, Vis3D = vis3DEnabled,
            COrbit = cineOrbit, COTS = cineOTS, CShake = cineShake, CDoF = cineDoFState, CGlitch = cineGlitch, CVignette = cineVignette, 
            CGhost = cineGhost, CFov = cineFOVPulse, CLow = cineLowAngle, CRipple = cineRipple, CSpot = cineSpotlight, CDLSS = cineDLSS,
            OvMode = overlayMode, OvSets = ovSettings
        }
        if type(writefile) == "function" then
            writefile("Hawk909_TitanConfig_v3.txt", HttpService:JSONEncode(data))
        end
    end)
end

local alignEnums = {Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right}
local alignNames = {"Kiri", "Tengah", "Kanan"}
local overlayModeNames = {"OFF", "Bawah Cine", "Kanan", "Kiri", "Subtitle"}
local overlayVisPosNames = {"Atas Lirik", "Bawah Lirik"}

local function makeHoldable(btn, callback)
    local holding = false
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            holding = true
            callback()
            task.wait(0.3)
            while holding do
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

-- Anti-AFK (Guarded for Arceus X Neo & Android)
task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end)
end)

local function CleanSongName(name)
    if not name then return "" end
    local clean = name:gsub("%[.-%]", ""):gsub("%(.-%)", ""):gsub("%{.-%}", "")
    local tags = {"audio", "full song", "sped up", "slowed", "bass boosted", "nightcore", "tiktok", "remix", "clean", "explicit", "short", "cut", "mv", "music video"}
    for _, tag in ipairs(tags) do
        clean = clean:gsub(tag, ""):gsub(tag:upper(), ""):gsub(tag:sub(1,1):upper() .. tag:sub(2), "")
    end
    clean = clean:gsub("[^%w%s%-]", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
    return (clean == "" or #clean < 2) and name or clean
end

local function GetAggressiveName(name)
    if not name then return "" end
    local n = name:lower()
    local splitStr = string.split(n, "-")[1]
    if not splitStr then return "" end
    n = string.split(splitStr, "|")[1]
    n = string.split(n, "(")[1]
    n = string.split(n, "[")[1]
    return n:match("^%s*(.-)%s*$") or ""
end

local function SendToChat(message)
    task.spawn(function()
        pcall(function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                local rbxGeneral = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if rbxGeneral then rbxGeneral:SendAsync(message) end
            else
                local defaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                local sayMessage = defaultChat and defaultChat:FindFirstChild("SayMessageRequest")
                if sayMessage then sayMessage:FireServer(message, "All") end
            end
        end)
    end)
end

-- ARCEUS X NEO SAFE GUI PARENTING (Supports gethui, CoreGui, and PlayerGui)
local function getSafeParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local success, core = pcall(function() return CoreGui end)
    if success and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local parentGui = getSafeParent()
for _, target in ipairs({parentGui, CoreGui, LocalPlayer:FindFirstChild("PlayerGui")}) do
    if target then
        pcall(function()
            local old = target:FindFirstChild("Hawk909_SpotifyWidget")
            if old then old:Destroy() end
        end)
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Hawk909_SpotifyWidget"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

-- ANDROID / ARCEUS X NEO ADAPTIVE SCALING
local MobileScale = Instance.new("UIScale")
MobileScale.Name = "Hawk909_MobileScale"
MobileScale.Scale = 1
MobileScale.Parent = ScreenGui

local function UpdateMobileScale()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    if viewport.X <= 0 or viewport.Y <= 0 then return end
    local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local maxWidthNeeded = isTouchDevice and 580 or 550
    local maxHeightNeeded = isTouchDevice and 440 or 360
    local widthScale = math.clamp((viewport.X - 20) / maxWidthNeeded, 0.55, 1)
    local heightScale = math.clamp((viewport.Y - 24) / maxHeightNeeded, 0.55, 1)
    MobileScale.Scale = math.min(widthScale, heightScale)
end

UpdateMobileScale()
local camConn = nil
local function BindCameraViewport()
    if camConn then camConn:Disconnect(); camConn = nil end
    if Workspace.CurrentCamera then
        UpdateMobileScale()
        camConn = Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateMobileScale)
    end
end
BindCameraViewport()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.defer(BindCameraViewport)
end)

-- CINEMATIC LETTERBOX BARS
local CineTop = Instance.new("Frame", ScreenGui); CineTop.Size = UDim2.new(1, 0, 0, 110); CineTop.Position = UDim2.new(0, 0, 0, -110); CineTop.BackgroundColor3 = Color3.new(0, 0, 0); CineTop.BorderSizePixel = 0; CineTop.ZIndex = 1
local CineBottom = Instance.new("Frame", ScreenGui); CineBottom.Size = UDim2.new(1, 0, 0, 110); CineBottom.Position = UDim2.new(0, 0, 1, 0); CineBottom.BackgroundColor3 = Color3.new(0, 0, 0); CineBottom.BorderSizePixel = 0; CineBottom.ZIndex = 1

local VignetteImg = Instance.new("ImageLabel", ScreenGui); VignetteImg.Size = UDim2.new(1, 0, 1, 0); VignetteImg.BackgroundTransparency = 1; VignetteImg.Image = "rbxassetid://7335689886"; VignetteImg.ImageColor3 = Color3.new(0,0,0); VignetteImg.ImageTransparency = 1; VignetteImg.ZIndex = 2; VignetteImg.Active = false

-- // OVERLAY 2D ARCHITECTURE //
local OvContainer = Instance.new("Frame", ScreenGui)
OvContainer.Name = "Hawk909_2D_Overlay_Container"
OvContainer.BackgroundTransparency = 1
OvContainer.Size = UDim2.new(0, 800, 0, 150)
OvContainer.Visible = false
OvContainer.ZIndex = 10
local OvListLayout = Instance.new("UIListLayout", OvContainer)
OvListLayout.FillDirection = Enum.FillDirection.Vertical
OvListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
OvListLayout.SortOrder = Enum.SortOrder.LayoutOrder
OvListLayout.Padding = UDim.new(0, 5)

local OvTextContainer = Instance.new("Frame", OvContainer)
OvTextContainer.BackgroundTransparency = 1
OvTextContainer.Size = UDim2.new(1, 0, 0, 80)
OvTextContainer.LayoutOrder = 2
local OvTextList = Instance.new("UIListLayout", OvTextContainer)
OvTextList.FillDirection = Enum.FillDirection.Vertical
OvTextList.HorizontalAlignment = Enum.HorizontalAlignment.Center
OvTextList.SortOrder = Enum.SortOrder.LayoutOrder
OvTextList.Padding = UDim.new(0, 2)

local OvPrev = Instance.new("TextLabel", OvTextContainer); OvPrev.BackgroundTransparency = 1; OvPrev.Size = UDim2.new(1,0,0,20); OvPrev.Font = Enum.Font.Gotham; OvPrev.TextColor3 = Color3.fromRGB(150,150,150); OvPrev.TextTransparency = 0.5; OvPrev.TextStrokeTransparency = 0.5; OvPrev.TextScaled = false; OvPrev.LayoutOrder = 1; OvPrev.Text = ""
local OvCurr = Instance.new("TextLabel", OvTextContainer); OvCurr.BackgroundTransparency = 1; OvCurr.Size = UDim2.new(1,0,0,30); OvCurr.Font = Enum.Font.GothamBold; OvCurr.TextColor3 = Color3.new(1,1,1); OvCurr.TextStrokeTransparency = 0.2; OvCurr.TextScaled = false; OvCurr.LayoutOrder = 2; OvCurr.Text = "..."
local OvNext = Instance.new("TextLabel", OvTextContainer); OvNext.BackgroundTransparency = 1; OvNext.Size = UDim2.new(1,0,0,20); OvNext.Font = Enum.Font.Gotham; OvNext.TextColor3 = Color3.fromRGB(150,150,150); OvNext.TextTransparency = 0.5; OvNext.TextStrokeTransparency = 0.5; OvNext.TextScaled = false; OvNext.LayoutOrder = 3; OvNext.Text = ""

local OvVisContainer = Instance.new("Frame", OvContainer)
OvVisContainer.BackgroundTransparency = 1
OvVisContainer.Size = UDim2.new(1, 0, 0, 30)
OvVisContainer.LayoutOrder = 3
local OvVisList = Instance.new("UIListLayout", OvVisContainer)
OvVisList.FillDirection = Enum.FillDirection.Horizontal
OvVisList.HorizontalAlignment = Enum.HorizontalAlignment.Center
OvVisList.VerticalAlignment = Enum.VerticalAlignment.Bottom
OvVisList.Padding = UDim.new(0, 3)

local ovBars = {}
for i = 1, 40 do
    local b = Instance.new("Frame", OvVisContainer)
    b.Size = UDim2.new(0, 4, 0, 2)
    b.BackgroundColor3 = Color3.new(1,1,1)
    b.BorderSizePixel = 0
    table.insert(ovBars, b)
end

-- 3D HOLOGRAM PROJECTION
local Billboard3D = Instance.new("BillboardGui"); Billboard3D.Name = "Hawk909_3D_Hologram"; Billboard3D.Size = UDim2.new(18, 0, 4, 0); Billboard3D.SizeOffset = Vector2.new(0.5, 0); Billboard3D.AlwaysOnTop = false; Billboard3D.LightInfluence = 0; Billboard3D.Enabled = false; Billboard3D.Parent = ScreenGui
local Lyr3DPrev = Instance.new("TextLabel", Billboard3D); Lyr3DPrev.Size = UDim2.new(1, 0, 0.2, 0); Lyr3DPrev.Position = UDim2.new(0, 0, 0, 0); Lyr3DPrev.BackgroundTransparency = 1; Lyr3DPrev.Font = Enum.Font.Gotham; Lyr3DPrev.TextColor3 = Color3.fromRGB(150, 150, 150); Lyr3DPrev.TextXAlignment = alignEnums[holoAlign + 1]; Lyr3DPrev.TextYAlignment = Enum.TextYAlignment.Bottom; Lyr3DPrev.TextTransparency = 0.5; Lyr3DPrev.TextStrokeTransparency = 0.5; Lyr3DPrev.TextScaled = true; Lyr3DPrev.Text = ""
local ConstraintPrev = Instance.new("UITextSizeConstraint", Lyr3DPrev); ConstraintPrev.MaxTextSize = math.max(10, holoTextSize - 12)
local Lyr3DCurrent = Instance.new("TextLabel", Billboard3D); Lyr3DCurrent.Size = UDim2.new(1, 0, 0.4, 0); Lyr3DCurrent.Position = UDim2.new(0, 0, 0.2, 0); Lyr3DCurrent.BackgroundTransparency = 1; Lyr3DCurrent.Font = Enum.Font.GothamBold; Lyr3DCurrent.TextColor3 = holoTextColor; Lyr3DCurrent.TextXAlignment = alignEnums[holoAlign + 1]; Lyr3DCurrent.TextStrokeTransparency = 0.2; Lyr3DCurrent.TextScaled = true; Lyr3DCurrent.Text = "..."
local ConstraintCurrent = Instance.new("UITextSizeConstraint", Lyr3DCurrent); ConstraintCurrent.MaxTextSize = holoTextSize
local Scale3D = Instance.new("UIScale", Lyr3DCurrent)
local Grad3D = Instance.new("UIGradient", Lyr3DCurrent); Grad3D.Offset = Vector2.new(-0.5, 0); Grad3D.Enabled = karaoke3DEnabled

local GlitchRed = Lyr3DCurrent:Clone(); GlitchRed.Parent = Billboard3D; GlitchRed.TextColor3 = Color3.fromRGB(255, 0, 50); GlitchRed.TextStrokeTransparency = 1; GlitchRed.TextTransparency = 1; GlitchRed.ZIndex = -1; if GlitchRed:FindFirstChildOfClass("UIGradient") then GlitchRed:FindFirstChildOfClass("UIGradient"):Destroy() end
local GlitchCyan = Lyr3DCurrent:Clone(); GlitchCyan.Parent = Billboard3D; GlitchCyan.TextColor3 = Color3.fromRGB(0, 255, 255); GlitchCyan.TextStrokeTransparency = 1; GlitchCyan.TextTransparency = 1; GlitchCyan.ZIndex = -2; if GlitchCyan:FindFirstChildOfClass("UIGradient") then GlitchCyan:FindFirstChildOfClass("UIGradient"):Destroy() end

local Lyr3DNext = Instance.new("TextLabel", Billboard3D); Lyr3DNext.Size = UDim2.new(1, 0, 0.2, 0); Lyr3DNext.Position = UDim2.new(0, 0, 0.6, 0); Lyr3DNext.BackgroundTransparency = 1; Lyr3DNext.Font = Enum.Font.Gotham; Lyr3DNext.TextColor3 = Color3.fromRGB(150, 150, 150); Lyr3DNext.TextXAlignment = alignEnums[holoAlign + 1]; Lyr3DNext.TextYAlignment = Enum.TextYAlignment.Top; Lyr3DNext.TextTransparency = 0.5; Lyr3DNext.TextStrokeTransparency = 0.5; Lyr3DNext.TextScaled = true; Lyr3DNext.Text = ""
local ConstraintNext = Instance.new("UITextSizeConstraint", Lyr3DNext); ConstraintNext.MaxTextSize = math.max(10, holoTextSize - 12)

local Vis3DContainer = Instance.new("Frame", Billboard3D); Vis3DContainer.Size = UDim2.new(1, 0, 0.15, 0); Vis3DContainer.Position = UDim2.new(0, 0, 0.90, 0); Vis3DContainer.BackgroundTransparency = 1; Vis3DContainer.Visible = vis3DEnabled
local UIListLayout3D = Instance.new("UIListLayout", Vis3DContainer); UIListLayout3D.FillDirection = Enum.FillDirection.Horizontal; UIListLayout3D.HorizontalAlignment = Enum.HorizontalAlignment.Center; UIListLayout3D.VerticalAlignment = Enum.VerticalAlignment.Bottom; UIListLayout3D.Padding = UDim.new(0, 4)
local vis3DBars = {}
for i = 1, 50 do local bar = Instance.new("Frame", Vis3DContainer); bar.Size = UDim2.new(0, 6, 0, 2); bar.BackgroundColor3 = holoGlowColor; bar.BorderSizePixel = 0; bar.BackgroundTransparency = 0.1; table.insert(vis3DBars, bar) end

-- WIDGET UTAMA (2D)
local MainFrame = Instance.new("Frame"); MainFrame.Name = "MainFrame"; MainFrame.Size = UDim2.new(0, 550, 0, 175); MainFrame.AnchorPoint = Vector2.new(0.5, 0); MainFrame.Position = UDim2.new(0.5, 0, 0, -200); MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24); MainFrame.BackgroundTransparency = 0.05; MainFrame.BorderSizePixel = 0; MainFrame.ClipsDescendants = false; MainFrame.Active = true; MainFrame.ZIndex = 20; MainFrame.Parent = ScreenGui
local InnerFrame = Instance.new("Frame"); InnerFrame.Size = UDim2.new(1, 0, 1, 0); InnerFrame.BackgroundTransparency = 1; InnerFrame.ClipsDescendants = true; InnerFrame.Parent = MainFrame
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12); Instance.new("UICorner", InnerFrame).CornerRadius = UDim.new(0, 12)
local UIStroke = Instance.new("UIStroke", MainFrame); UIStroke.Color = Color3.fromRGB(30, 215, 96); UIStroke.Thickness = 1.5; UIStroke.Transparency = 0.3

local VisualizerContainer = Instance.new("Frame", InnerFrame); VisualizerContainer.Size = UDim2.new(1, -24, 0, 12); VisualizerContainer.Position = UDim2.new(0, 12, 0, 50); VisualizerContainer.BackgroundTransparency = 1
Instance.new("UIListLayout", VisualizerContainer).FillDirection = Enum.FillDirection.Horizontal; VisualizerContainer.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; VisualizerContainer.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom; VisualizerContainer.UIListLayout.Padding = UDim.new(0, 2)
local visBars = {}
for i = 1, 85 do local bar = Instance.new("Frame", VisualizerContainer); bar.Size = UDim2.new(0, 4, 0, 2); bar.BackgroundColor3 = Color3.fromRGB(30, 215, 96); bar.BorderSizePixel = 0; table.insert(visBars, bar) end

local AlbumArt = Instance.new("ImageLabel", InnerFrame); AlbumArt.Size = UDim2.new(0, 40, 0, 40); AlbumArt.Position = UDim2.new(0, 12, 0, 12); AlbumArt.BackgroundColor3 = Color3.fromRGB(40, 40, 40); AlbumArt.Image = "rbxthumb://type=Asset&id=15569839695&w=150&h=150"; Instance.new("UICorner", AlbumArt).CornerRadius = UDim.new(0, 6)

local TitleLabel = Instance.new("TextLabel", InnerFrame); TitleLabel.Size = UDim2.new(1, -110, 0, 20); TitleLabel.Position = UDim2.new(0, 62, 0, 12); TitleLabel.BackgroundTransparency = 1; TitleLabel.Font = Enum.Font.GothamBold; TitleLabel.TextSize = 14; TitleLabel.TextColor3 = Color3.new(1, 1, 1); TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd; TitleLabel.Text = "Mencari Frekuensi..."
local ArtistLabel = Instance.new("TextLabel", InnerFrame); ArtistLabel.Size = UDim2.new(1, -110, 0, 15); ArtistLabel.Position = UDim2.new(0, 62, 0, 34); ArtistLabel.BackgroundTransparency = 1; ArtistLabel.Font = Enum.Font.Gotham; ArtistLabel.TextSize = 11; ArtistLabel.TextColor3 = Color3.fromRGB(179, 179, 179); ArtistLabel.TextXAlignment = Enum.TextXAlignment.Left; ArtistLabel.TextTruncate = Enum.TextTruncate.AtEnd; ArtistLabel.Text = "Menunggu Audio"

local LyricPrev = Instance.new("TextLabel", InnerFrame); LyricPrev.Size = UDim2.new(1, -110, 0, 15); LyricPrev.Position = UDim2.new(0, 12, 0, 66); LyricPrev.BackgroundTransparency = 1; LyricPrev.Font = Enum.Font.Gotham; LyricPrev.TextSize = 11; LyricPrev.TextColor3 = Color3.fromRGB(120, 120, 120); LyricPrev.TextXAlignment = Enum.TextXAlignment.Left; LyricPrev.TextTruncate = Enum.TextTruncate.AtEnd; LyricPrev.Text = ""
local LyricCurrent = Instance.new("TextLabel", InnerFrame); LyricCurrent.Size = UDim2.new(1, -110, 0, 20); LyricCurrent.Position = UDim2.new(0, 12, 0, 85); LyricCurrent.BackgroundTransparency = 1; LyricCurrent.Font = Enum.Font.GothamBold; LyricCurrent.TextSize = 15; LyricCurrent.TextColor3 = Color3.new(1,1,1); LyricCurrent.TextXAlignment = Enum.TextXAlignment.Left; LyricCurrent.TextTruncate = Enum.TextTruncate.AtEnd; LyricCurrent.Text = "..."
local Grad2D = Instance.new("UIGradient", LyricCurrent); Grad2D.Offset = Vector2.new(-0.5, 0)
local LyricNext = Instance.new("TextLabel", InnerFrame); LyricNext.Size = UDim2.new(1, -110, 0, 15); LyricNext.Position = UDim2.new(0, 12, 0, 110); LyricNext.BackgroundTransparency = 1; LyricNext.Font = Enum.Font.Gotham; LyricNext.TextSize = 11; LyricNext.TextColor3 = Color3.fromRGB(120, 120, 120); LyricNext.TextXAlignment = Enum.TextXAlignment.Left; LyricNext.TextTruncate = Enum.TextTruncate.AtEnd; LyricNext.Text = ""

local function UpdateGradientColors()
    local base = Color3.fromRGB(120, 120, 120) 
    Grad3D.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, holoTextColor), ColorSequenceKeypoint.new(0.5, holoTextColor), ColorSequenceKeypoint.new(0.501, base), ColorSequenceKeypoint.new(1, base) })
    Grad2D.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 215, 96)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 215, 96)), ColorSequenceKeypoint.new(0.501, base), ColorSequenceKeypoint.new(1, base) })
end
UpdateGradientColors()

-- KONTROL TOMBOL ATAS
local BtnMinimize = Instance.new("TextButton", InnerFrame); BtnMinimize.Size = UDim2.new(0, 24, 0, 24); BtnMinimize.Position = UDim2.new(1, -30, 0, 8); BtnMinimize.BackgroundTransparency = 1; BtnMinimize.Font = Enum.Font.GothamBold; BtnMinimize.TextColor3 = Color3.fromRGB(150, 150, 150); BtnMinimize.TextSize = 18; BtnMinimize.Text = "—"
local BtnMute = Instance.new("TextButton", InnerFrame); BtnMute.Size = UDim2.new(0, 24, 0, 24); BtnMute.Position = UDim2.new(1, -60, 0, 8); BtnMute.BackgroundTransparency = 1; BtnMute.Font = Enum.Font.GothamBold; BtnMute.TextColor3 = Color3.fromRGB(200, 200, 200); BtnMute.TextSize = 14; BtnMute.Text = "🔊"

local SyncLabel = Instance.new("TextLabel", InnerFrame); SyncLabel.Size = UDim2.new(0, 85, 0, 12); SyncLabel.Position = UDim2.new(1, -95, 0, 64); SyncLabel.BackgroundTransparency = 1; SyncLabel.Font = Enum.Font.Gotham; SyncLabel.TextSize = 9; SyncLabel.TextColor3 = Color3.fromRGB(150, 150, 150); SyncLabel.Text = "Offset: 0.0s"
local BtnMinus = Instance.new("TextButton", InnerFrame); BtnMinus.Size = UDim2.new(0, 25, 0, 16); BtnMinus.Position = UDim2.new(1, -90, 0, 78); BtnMinus.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnMinus.Font = Enum.Font.GothamBold; BtnMinus.TextColor3 = Color3.new(1, 1, 1); BtnMinus.TextSize = 12; BtnMinus.Text = "<"; Instance.new("UICorner", BtnMinus).CornerRadius = UDim.new(0, 4)
local BtnPlus = Instance.new("TextButton", InnerFrame); BtnPlus.Size = UDim2.new(0, 25, 0, 16); BtnPlus.Position = UDim2.new(1, -40, 0, 78); BtnPlus.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnPlus.Font = Enum.Font.GothamBold; BtnPlus.TextColor3 = Color3.new(1, 1, 1); BtnPlus.TextSize = 12; BtnPlus.Text = ">"; Instance.new("UICorner", BtnPlus).CornerRadius = UDim.new(0, 4)
makeHoldable(BtnMinus, function() lyricOffset = lyricOffset - 0.5; SyncLabel.Text = string.format("Offset: %.1fs", lyricOffset) end)
makeHoldable(BtnPlus, function() lyricOffset = lyricOffset + 0.5; SyncLabel.Text = string.format("Offset: %.1fs", lyricOffset) end)

local SpeedLabelBtn = Instance.new("TextLabel", InnerFrame); SpeedLabelBtn.Size = UDim2.new(0, 85, 0, 12); SpeedLabelBtn.Position = UDim2.new(1, -95, 0, 96); SpeedLabelBtn.BackgroundTransparency = 1; SpeedLabelBtn.Font = Enum.Font.Gotham; SpeedLabelBtn.TextSize = 9; SpeedLabelBtn.TextColor3 = Color3.fromRGB(200, 150, 255); SpeedLabelBtn.Text = "Speed: 1.0x"
local BtnSpeedMinus = Instance.new("TextButton", InnerFrame); BtnSpeedMinus.Size = UDim2.new(0, 25, 0, 16); BtnSpeedMinus.Position = UDim2.new(1, -90, 0, 110); BtnSpeedMinus.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnSpeedMinus.Font = Enum.Font.GothamBold; BtnSpeedMinus.TextColor3 = Color3.fromRGB(200, 150, 255); BtnSpeedMinus.TextSize = 12; BtnSpeedMinus.Text = "<"; Instance.new("UICorner", BtnSpeedMinus).CornerRadius = UDim.new(0, 4)
local BtnSpeedPlus = Instance.new("TextButton", InnerFrame); BtnSpeedPlus.Size = UDim2.new(0, 25, 0, 16); BtnSpeedPlus.Position = UDim2.new(1, -40, 0, 110); BtnSpeedPlus.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnSpeedPlus.Font = Enum.Font.GothamBold; BtnSpeedPlus.TextColor3 = Color3.fromRGB(200, 150, 255); BtnSpeedPlus.TextSize = 12; BtnSpeedPlus.Text = ">"; Instance.new("UICorner", BtnSpeedPlus).CornerRadius = UDim.new(0, 4)
makeHoldable(BtnSpeedMinus, function() manualSpeedOverride = true; lyricSpeed = math.max(0.1, lyricSpeed - 0.05); SpeedLabelBtn.Text = string.format("Speed: %.2fx", lyricSpeed) end)
makeHoldable(BtnSpeedPlus, function() manualSpeedOverride = true; lyricSpeed = lyricSpeed + 0.05; SpeedLabelBtn.Text = string.format("Speed: %.2fx", lyricSpeed) end)

local ChatToggleBtn = Instance.new("TextButton", InnerFrame); ChatToggleBtn.Size = UDim2.new(0, 85, 0, 22); ChatToggleBtn.Position = UDim2.new(1, -95, 0, 138); ChatToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); ChatToggleBtn.Font = Enum.Font.GothamBold; ChatToggleBtn.TextColor3 = Color3.fromRGB(150, 150, 150); ChatToggleBtn.TextSize = 11; ChatToggleBtn.Text = "Auto-Chat: OFF"; Instance.new("UICorner", ChatToggleBtn).CornerRadius = UDim.new(0, 4)
local ChatUIStroke = Instance.new("UIStroke", ChatToggleBtn); ChatUIStroke.Color = Color3.fromRGB(150, 150, 150); ChatUIStroke.Thickness = 1
ChatToggleBtn.Activated:Connect(function()
    autoChatEnabled = not autoChatEnabled
    ChatToggleBtn.BackgroundColor3 = autoChatEnabled and Color3.fromRGB(20, 80, 40) or Color3.fromRGB(40, 40, 40)
    ChatToggleBtn.TextColor3 = autoChatEnabled and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(150, 150, 150)
    ChatUIStroke.Color = autoChatEnabled and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(150, 150, 150)
    ChatToggleBtn.Text = "Auto-Chat: " .. (autoChatEnabled and "ON" or "OFF")
end)

local HologramToggleBtn = Instance.new("TextButton", InnerFrame); HologramToggleBtn.Size = UDim2.new(0, 85, 0, 22); HologramToggleBtn.Position = UDim2.new(1, -185, 0, 138); HologramToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); HologramToggleBtn.Font = Enum.Font.GothamBold; HologramToggleBtn.TextColor3 = Color3.fromRGB(150, 150, 150); HologramToggleBtn.TextSize = 11; HologramToggleBtn.Text = "3D Lirik: OFF"; Instance.new("UICorner", HologramToggleBtn).CornerRadius = UDim.new(0, 4)
local HoloUIStroke = Instance.new("UIStroke", HologramToggleBtn); HoloUIStroke.Color = Color3.fromRGB(150, 150, 150); HoloUIStroke.Thickness = 1
HologramToggleBtn.Activated:Connect(function()
    isHologramEnabled = not isHologramEnabled
    HologramToggleBtn.BackgroundColor3 = isHologramEnabled and Color3.fromRGB(20, 80, 40) or Color3.fromRGB(40, 40, 40)
    HologramToggleBtn.TextColor3 = isHologramEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    HoloUIStroke.Color = isHologramEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    HologramToggleBtn.Text = "3D Lirik: " .. (isHologramEnabled and "ON" or "OFF")
end)

-- PANEL CONTAINERS (Positioned safely inside MainFrame width so they never clip off mobile screens)
local HoloSetPanel = Instance.new("Frame", MainFrame)
local MediaPanel = Instance.new("Frame", MainFrame)
local DirectorPanel = Instance.new("Frame", MainFrame)
local LyricPanel = Instance.new("Frame", MainFrame)
local OverlayPanel = Instance.new("Frame", MainFrame)

local BtnHoloSettings = Instance.new("TextButton", InnerFrame); BtnHoloSettings.Size = UDim2.new(0, 22, 0, 22); BtnHoloSettings.Position = UDim2.new(1, -212, 0, 138); BtnHoloSettings.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnHoloSettings.Font = Enum.Font.GothamBold; BtnHoloSettings.TextColor3 = Color3.fromRGB(200, 200, 200); BtnHoloSettings.TextSize = 14; BtnHoloSettings.Text = "⚙"; Instance.new("UICorner", BtnHoloSettings).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", BtnHoloSettings).Color = Color3.fromRGB(150, 150, 150)
local BtnMedia = Instance.new("TextButton", InnerFrame); BtnMedia.Size = UDim2.new(0, 22, 0, 22); BtnMedia.Position = UDim2.new(1, -238, 0, 138); BtnMedia.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnMedia.Font = Enum.Font.GothamBold; BtnMedia.TextColor3 = Color3.fromRGB(200, 200, 200); BtnMedia.TextSize = 12; BtnMedia.Text = "🎵"; Instance.new("UICorner", BtnMedia).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", BtnMedia).Color = Color3.fromRGB(150, 150, 150)
local BtnDirector = Instance.new("TextButton", InnerFrame); BtnDirector.Size = UDim2.new(0, 22, 0, 22); BtnDirector.Position = UDim2.new(1, -264, 0, 138); BtnDirector.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnDirector.Font = Enum.Font.GothamBold; BtnDirector.TextColor3 = Color3.fromRGB(200, 200, 200); BtnDirector.TextSize = 12; BtnDirector.Text = "🎬"; Instance.new("UICorner", BtnDirector).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", BtnDirector).Color = Color3.fromRGB(150, 150, 150)
local BtnCinematic = Instance.new("TextButton", InnerFrame); BtnCinematic.Size = UDim2.new(0, 22, 0, 22); BtnCinematic.Position = UDim2.new(1, -290, 0, 138); BtnCinematic.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnCinematic.Font = Enum.Font.GothamBold; BtnCinematic.TextColor3 = Color3.fromRGB(200, 200, 200); BtnCinematic.TextSize = 12; BtnCinematic.Text = "🎥"; Instance.new("UICorner", BtnCinematic).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", BtnCinematic).Color = Color3.fromRGB(150, 150, 150)
local BtnLyricsMenu = Instance.new("TextButton", InnerFrame); BtnLyricsMenu.Size = UDim2.new(0, 22, 0, 22); BtnLyricsMenu.Position = UDim2.new(1, -316, 0, 138); BtnLyricsMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnLyricsMenu.Font = Enum.Font.GothamBold; BtnLyricsMenu.TextColor3 = Color3.fromRGB(200, 200, 200); BtnLyricsMenu.TextSize = 12; BtnLyricsMenu.Text = "📝"; Instance.new("UICorner", BtnLyricsMenu).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", BtnLyricsMenu).Color = Color3.fromRGB(150, 150, 150)
local BtnOverlay = Instance.new("TextButton", InnerFrame); BtnOverlay.Size = UDim2.new(0, 22, 0, 22); BtnOverlay.Position = UDim2.new(1, -342, 0, 138); BtnOverlay.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnOverlay.Font = Enum.Font.GothamBold; BtnOverlay.TextColor3 = Color3.fromRGB(200, 200, 200); BtnOverlay.TextSize = 12; BtnOverlay.Text = "📺"; Instance.new("UICorner", BtnOverlay).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", BtnOverlay).Color = Color3.fromRGB(150, 150, 150)

local function CloseAllPanels()
    HoloSetPanel.Visible = false; MediaPanel.Visible = false; DirectorPanel.Visible = false; LyricPanel.Visible = false; OverlayPanel.Visible = false
    BtnHoloSettings.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnHoloSettings.TextColor3 = Color3.fromRGB(200, 200, 200)
    BtnMedia.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnMedia.TextColor3 = Color3.fromRGB(200, 200, 200)
    BtnDirector.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnDirector.TextColor3 = Color3.fromRGB(200, 200, 200)
    BtnLyricsMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnLyricsMenu.TextColor3 = Color3.fromRGB(200, 200, 200)
    BtnOverlay.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnOverlay.TextColor3 = Color3.fromRGB(200, 200, 200)
end

-- MASTER CINEMATIC MODE TRIGGER
BtnCinematic.Activated:Connect(function()
    isCinematic = not isCinematic
    CloseAllPanels()

    if isCinematic then
        targetBaseFOV = 50
        BtnCinematic.BackgroundColor3 = Color3.fromRGB(30, 215, 96); BtnCinematic.TextColor3 = Color3.new(0,0,0)
        TweenService:Create(CineTop, TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        TweenService:Create(CineBottom, TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 1, -110)}):Play()
        CineCC.Enabled = true; TweenService:Create(CineCC, TweenInfo.new(1.5), {Saturation = -0.25, Contrast = 0.15}):Play()
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
        
        if not isMinimized then isMinimized = true; BtnMinimize.Text = "+"; TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 64)}):Play() end
    else
        targetBaseFOV = originalFOV
        BtnCinematic.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnCinematic.TextColor3 = Color3.fromRGB(200, 200, 200)
        TweenService:Create(CineTop, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, -110)}):Play()
        TweenService:Create(CineBottom, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 1, 0)}):Play()
        local twCC = TweenService:Create(CineCC, TweenInfo.new(1.5), {Saturation = 0, Contrast = 0})
        twCC:Play(); twCC.Completed:Connect(function() if not isCinematic then CineCC.Enabled = false end end)
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
    end
end)

local function CreateSettingRow(parent, yPos, labelText, getValue, step, callback)
    local lbl = Instance.new("TextLabel", parent); lbl.Size = UDim2.new(0, 120, 0, 20); lbl.Position = UDim2.new(0, 10, 0, yPos); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextColor3 = Color3.fromRGB(180, 180, 180); lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local btnMinus = Instance.new("TextButton", parent); btnMinus.Size = UDim2.new(0, 24, 0, 20); btnMinus.Position = UDim2.new(0, 140, 0, yPos); btnMinus.BackgroundColor3 = Color3.fromRGB(40,40,40); btnMinus.Font = Enum.Font.GothamBold; btnMinus.TextColor3 = Color3.new(1,1,1); btnMinus.Text = "<"; Instance.new("UICorner", btnMinus).CornerRadius = UDim.new(0,4)
    local valDisplay = Instance.new("TextLabel", parent); valDisplay.Size = UDim2.new(0, 40, 0, 20); valDisplay.Position = UDim2.new(0, 170, 0, yPos); valDisplay.BackgroundTransparency = 1; valDisplay.Font = Enum.Font.GothamBold; valDisplay.TextColor3 = Color3.fromRGB(30, 215, 96); valDisplay.TextSize = 12; valDisplay.Text = string.format("%.1f", getValue())
    local btnPlus = Instance.new("TextButton", parent); btnPlus.Size = UDim2.new(0, 24, 0, 20); btnPlus.Position = UDim2.new(0, 216, 0, yPos); btnPlus.BackgroundColor3 = Color3.fromRGB(40,40,40); btnPlus.Font = Enum.Font.GothamBold; btnPlus.TextColor3 = Color3.new(1,1,1); btnPlus.Text = ">"; Instance.new("UICorner", btnPlus).CornerRadius = UDim.new(0,4)
    makeHoldable(btnMinus, function() local newVal = getValue() - step; valDisplay.Text = string.format("%.1f", newVal); callback(newVal); SaveHoloSettings() end)
    makeHoldable(btnPlus, function() local newVal = getValue() + step; valDisplay.Text = string.format("%.1f", newVal); callback(newVal); SaveHoloSettings() end)
end

-- A. Panel 3D Settings 
HoloSetPanel.Size = UDim2.new(0, 280, 0, 260); HoloSetPanel.AnchorPoint = Vector2.new(0.5, 0); HoloSetPanel.Position = UDim2.new(0.5, 0, 1, 5); HoloSetPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20); HoloSetPanel.BorderSizePixel = 0; HoloSetPanel.Visible = false; HoloSetPanel.Active = true
Instance.new("UICorner", HoloSetPanel).CornerRadius = UDim.new(0, 8); local PanelStroke = Instance.new("UIStroke", HoloSetPanel); PanelStroke.Color = Color3.fromRGB(30, 215, 96); PanelStroke.Thickness = 1.5
local PanelTitle = Instance.new("TextLabel", HoloSetPanel); PanelTitle.Size = UDim2.new(1, 0, 0, 25); PanelTitle.BackgroundTransparency = 1; PanelTitle.Font = Enum.Font.GothamBold; PanelTitle.TextColor3 = Color3.new(1,1,1); PanelTitle.TextSize = 12; PanelTitle.Text = "Kustomisasi Lirik 3D Penuh"

CreateSettingRow(HoloSetPanel, 30, "X (Kanan / Kiri):", function() return holoOffsetX end, 0.5, function(v) holoOffsetX = v end)
CreateSettingRow(HoloSetPanel, 55, "Y (Atas / Bawah):", function() return holoOffsetY end, 0.5, function(v) holoOffsetY = v end)
CreateSettingRow(HoloSetPanel, 80, "Z (Depan / Blkng):", function() return holoOffsetZ end, 0.5, function(v) holoOffsetZ = v end)
CreateSettingRow(HoloSetPanel, 105, "Ukuran Teks (Size):", function() return holoTextSize end, 1, function(v) 
    holoTextSize = math.clamp(v, 15, 60); ConstraintCurrent.MaxTextSize = holoTextSize; ConstraintPrev.MaxTextSize = math.max(10, holoTextSize - 12); ConstraintNext.MaxTextSize = math.max(10, holoTextSize - 12)
end)

local colors = { Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0), Color3.fromRGB(150,150,150), Color3.fromRGB(30,215,96), Color3.fromRGB(255,50,50), Color3.fromRGB(50,150,255), Color3.fromRGB(255,215,0), Color3.fromRGB(255,0,255), Color3.fromRGB(0,255,255), Color3.fromRGB(255,100,0), Color3.fromRGB(150,50,255) }
local ColTitleText = Instance.new("TextLabel", HoloSetPanel); ColTitleText.Size = UDim2.new(0, 50, 0, 20); ColTitleText.Position = UDim2.new(0, 10, 0, 130); ColTitleText.BackgroundTransparency = 1; ColTitleText.Font = Enum.Font.Gotham; ColTitleText.TextColor3 = Color3.fromRGB(180, 180, 180); ColTitleText.TextSize = 11; ColTitleText.TextXAlignment = Enum.TextXAlignment.Left; ColTitleText.Text = "Teks:"
for i, col in ipairs(colors) do
    local btnC = Instance.new("TextButton", HoloSetPanel); btnC.Size = UDim2.new(0, 16, 0, 16); btnC.Position = UDim2.new(0, 45 + (i*18), 0, 132); btnC.BackgroundColor3 = col; btnC.Text = ""; Instance.new("UICorner", btnC).CornerRadius = UDim.new(1,0)
    if col == Color3.fromRGB(0,0,0) then local strk = Instance.new("UIStroke", btnC); strk.Color = Color3.fromRGB(100,100,100) end
    btnC.Activated:Connect(function() holoTextColor = col; GlitchRed.TextColor3 = Color3.fromRGB(255,0,50); GlitchCyan.TextColor3 = Color3.fromRGB(0,255,255); UpdateGradientColors(); SaveHoloSettings() end)
end

local ColTitleGlow = Instance.new("TextLabel", HoloSetPanel); ColTitleGlow.Size = UDim2.new(0, 50, 0, 20); ColTitleGlow.Position = UDim2.new(0, 10, 0, 155); ColTitleGlow.BackgroundTransparency = 1; ColTitleGlow.Font = Enum.Font.Gotham; ColTitleGlow.TextColor3 = Color3.fromRGB(180, 180, 180); ColTitleGlow.TextSize = 11; ColTitleGlow.TextXAlignment = Enum.TextXAlignment.Left; ColTitleGlow.Text = "Glow:"
for i, col in ipairs(colors) do
    local btnC = Instance.new("TextButton", HoloSetPanel); btnC.Size = UDim2.new(0, 16, 0, 16); btnC.Position = UDim2.new(0, 45 + (i*18), 0, 157); btnC.BackgroundColor3 = col; btnC.Text = ""; Instance.new("UICorner", btnC).CornerRadius = UDim.new(1,0)
    if col == Color3.fromRGB(0,0,0) then local strk = Instance.new("UIStroke", btnC); strk.Color = Color3.fromRGB(100,100,100) end
    btnC.Activated:Connect(function() holoGlowColor = col; SaveHoloSettings() end)
end

local BtnAlign = Instance.new("TextButton", HoloSetPanel); BtnAlign.Size = UDim2.new(0, 125, 0, 22); BtnAlign.Position = UDim2.new(0, 10, 0, 185); BtnAlign.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnAlign.TextColor3 = Color3.new(1,1,1); BtnAlign.Font = Enum.Font.GothamBold; BtnAlign.TextSize = 10; BtnAlign.Text = "Rata: " .. alignNames[holoAlign + 1]; Instance.new("UICorner", BtnAlign).CornerRadius = UDim.new(0,4)
BtnAlign.Activated:Connect(function() holoAlign = (holoAlign + 1) % 3; BtnAlign.Text = "Rata: " .. alignNames[holoAlign + 1]; local enumVal = alignEnums[holoAlign + 1]; Lyr3DPrev.TextXAlignment = enumVal; Lyr3DCurrent.TextXAlignment = enumVal; Lyr3DNext.TextXAlignment = enumVal; SaveHoloSettings() end)
local TglKaraoke = Instance.new("TextButton", HoloSetPanel); TglKaraoke.Size = UDim2.new(0, 125, 0, 22); TglKaraoke.Position = UDim2.new(0, 145, 0, 185); TglKaraoke.BackgroundColor3 = karaoke3DEnabled and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(40, 40, 40); TglKaraoke.TextColor3 = karaoke3DEnabled and Color3.new(0,0,0) or Color3.new(1,1,1); TglKaraoke.Font = Enum.Font.GothamBold; TglKaraoke.TextSize = 10; TglKaraoke.Text = "Karaoke 3D: " .. (karaoke3DEnabled and "ON" or "OFF"); Instance.new("UICorner", TglKaraoke).CornerRadius = UDim.new(0,4)
TglKaraoke.Activated:Connect(function() karaoke3DEnabled = not karaoke3DEnabled; TglKaraoke.BackgroundColor3 = karaoke3DEnabled and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(40, 40, 40); TglKaraoke.TextColor3 = karaoke3DEnabled and Color3.new(0,0,0) or Color3.new(1,1,1); TglKaraoke.Text = "Karaoke 3D: " .. (karaoke3DEnabled and "ON" or "OFF"); Grad3D.Enabled = karaoke3DEnabled; SaveHoloSettings() end)
local TglBassGlow = Instance.new("TextButton", HoloSetPanel); TglBassGlow.Size = UDim2.new(0, 80, 0, 22); TglBassGlow.Position = UDim2.new(0, 10, 0, 215); TglBassGlow.BackgroundColor3 = bassGlowEnabled and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(40, 40, 40); TglBassGlow.TextColor3 = bassGlowEnabled and Color3.new(0,0,0) or Color3.new(1,1,1); TglBassGlow.Font = Enum.Font.GothamBold; TglBassGlow.TextSize = 9; TglBassGlow.Text = "Aura Bass"; Instance.new("UICorner", TglBassGlow).CornerRadius = UDim.new(0,4)
TglBassGlow.Activated:Connect(function() bassGlowEnabled = not bassGlowEnabled; TglBassGlow.BackgroundColor3 = bassGlowEnabled and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(40, 40, 40); TglBassGlow.TextColor3 = bassGlowEnabled and Color3.new(0,0,0) or Color3.new(1,1,1); SaveHoloSettings() end)
local TglVis3D = Instance.new("TextButton", HoloSetPanel); TglVis3D.Size = UDim2.new(0, 80, 0, 22); TglVis3D.Position = UDim2.new(0, 100, 0, 215); TglVis3D.BackgroundColor3 = vis3DEnabled and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(40, 40, 40); TglVis3D.TextColor3 = vis3DEnabled and Color3.new(0,0,0) or Color3.new(1,1,1); TglVis3D.Font = Enum.Font.GothamBold; TglVis3D.TextSize = 9; TglVis3D.Text = "Vis 3D"; Instance.new("UICorner", TglVis3D).CornerRadius = UDim.new(0,4)
TglVis3D.Activated:Connect(function() vis3DEnabled = not vis3DEnabled; TglVis3D.BackgroundColor3 = vis3DEnabled and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(40, 40, 40); TglVis3D.TextColor3 = vis3DEnabled and Color3.new(0,0,0) or Color3.new(1,1,1); Vis3DContainer.Visible = vis3DEnabled; SaveHoloSettings() end)
local TglParticles = Instance.new("TextButton", HoloSetPanel); TglParticles.Size = UDim2.new(0, 80, 0, 22); TglParticles.Position = UDim2.new(0, 190, 0, 215); TglParticles.BackgroundColor3 = particlesEnabled and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(40, 40, 40); TglParticles.TextColor3 = particlesEnabled and Color3.new(0,0,0) or Color3.new(1,1,1); TglParticles.Font = Enum.Font.GothamBold; TglParticles.TextSize = 9; TglParticles.Text = "Partikel"; Instance.new("UICorner", TglParticles).CornerRadius = UDim.new(0,4)
TglParticles.Activated:Connect(function() particlesEnabled = not particlesEnabled; TglParticles.BackgroundColor3 = particlesEnabled and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(40, 40, 40); TglParticles.TextColor3 = particlesEnabled and Color3.new(0,0,0) or Color3.new(1,1,1); SaveHoloSettings() end)

-- E. PANEL OVERLAY 2D (📺)
OverlayPanel.Size = UDim2.new(0, 280, 0, 255); OverlayPanel.AnchorPoint = Vector2.new(0.5, 0); OverlayPanel.Position = UDim2.new(0.5, 0, 1, 5); OverlayPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20); OverlayPanel.BorderSizePixel = 0; OverlayPanel.Visible = false; OverlayPanel.Active = true
Instance.new("UICorner", OverlayPanel).CornerRadius = UDim.new(0, 8); local OvStroke = Instance.new("UIStroke", OverlayPanel); OvStroke.Color = Color3.fromRGB(255, 100, 150); OvStroke.Thickness = 1.5
local OvTitle = Instance.new("TextLabel", OverlayPanel); OvTitle.Size = UDim2.new(1, 0, 0, 25); OvTitle.BackgroundTransparency = 1; OvTitle.Font = Enum.Font.GothamBold; OvTitle.TextColor3 = Color3.new(1,1,1); OvTitle.TextSize = 12; OvTitle.Text = "Kustomisasi Lirik & Vis 2D"

local BtnOvMode = Instance.new("TextButton", OverlayPanel); BtnOvMode.Size = UDim2.new(0, 260, 0, 22); BtnOvMode.Position = UDim2.new(0, 10, 0, 30); BtnOvMode.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnOvMode.TextColor3 = Color3.new(1,1,1); BtnOvMode.Font = Enum.Font.GothamBold; BtnOvMode.TextSize = 11; BtnOvMode.Text = "Mode: " .. overlayModeNames[overlayMode + 1]; Instance.new("UICorner", BtnOvMode).CornerRadius = UDim.new(0,4)

local ovUiUpdaters = {}
local BtnOvVis = Instance.new("TextButton", OverlayPanel); BtnOvVis.Size = UDim2.new(0, 125, 0, 22); BtnOvVis.Position = UDim2.new(0, 10, 0, 135); BtnOvVis.Font = Enum.Font.GothamBold; BtnOvVis.TextSize = 10; Instance.new("UICorner", BtnOvVis).CornerRadius = UDim.new(0,4)
local BtnOvVisPos = Instance.new("TextButton", OverlayPanel); BtnOvVisPos.Size = UDim2.new(0, 125, 0, 22); BtnOvVisPos.Position = UDim2.new(0, 145, 0, 135); BtnOvVisPos.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnOvVisPos.TextColor3 = Color3.new(1,1,1); BtnOvVisPos.Font = Enum.Font.GothamBold; BtnOvVisPos.TextSize = 10; Instance.new("UICorner", BtnOvVisPos).CornerRadius = UDim.new(0,4)

local function RefreshOverlayUI()
    local cfg = ovSettings[overlayMode == 0 and 1 or overlayMode]
    for _, fn in ipairs(ovUiUpdaters) do fn() end
    BtnOvVis.BackgroundColor3 = cfg.ven and Color3.fromRGB(255, 100, 150) or Color3.fromRGB(40, 40, 40)
    BtnOvVis.TextColor3 = cfg.ven and Color3.new(0,0,0) or Color3.new(1,1,1)
    BtnOvVis.Text = "Visualizer 2D: " .. (cfg.ven and "ON" or "OFF")
    BtnOvVisPos.Text = "Posisi Vis: " .. overlayVisPosNames[cfg.vpos]
end

BtnOvMode.Activated:Connect(function() 
    overlayMode = (overlayMode + 1) % 5
    BtnOvMode.Text = "Mode: " .. overlayModeNames[overlayMode + 1]
    RefreshOverlayUI()
    SaveHoloSettings() 
end)

local function CreateOvSettingRow(yPos, labelText, key, minVal, maxVal, step)
    local lbl = Instance.new("TextLabel", OverlayPanel); lbl.Size = UDim2.new(0, 120, 0, 20); lbl.Position = UDim2.new(0, 10, 0, yPos); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextColor3 = Color3.fromRGB(180, 180, 180); lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local btnMinus = Instance.new("TextButton", OverlayPanel); btnMinus.Size = UDim2.new(0, 24, 0, 20); btnMinus.Position = UDim2.new(0, 140, 0, yPos); btnMinus.BackgroundColor3 = Color3.fromRGB(40,40,40); btnMinus.Font = Enum.Font.GothamBold; btnMinus.TextColor3 = Color3.new(1,1,1); btnMinus.Text = "<"; Instance.new("UICorner", btnMinus).CornerRadius = UDim.new(0,4)
    local valDisplay = Instance.new("TextLabel", OverlayPanel); valDisplay.Size = UDim2.new(0, 40, 0, 20); valDisplay.Position = UDim2.new(0, 170, 0, yPos); valDisplay.BackgroundTransparency = 1; valDisplay.Font = Enum.Font.GothamBold; valDisplay.TextColor3 = Color3.fromRGB(255, 100, 150); valDisplay.TextSize = 12; valDisplay.Text = "0"
    local btnPlus = Instance.new("TextButton", OverlayPanel); btnPlus.Size = UDim2.new(0, 24, 0, 20); btnPlus.Position = UDim2.new(0, 216, 0, yPos); btnPlus.BackgroundColor3 = Color3.fromRGB(40,40,40); btnPlus.Font = Enum.Font.GothamBold; btnPlus.TextColor3 = Color3.new(1,1,1); btnPlus.Text = ">"; Instance.new("UICorner", btnPlus).CornerRadius = UDim.new(0,4)
    
    local function updateText()
        local cfg = ovSettings[overlayMode == 0 and 1 or overlayMode]
        valDisplay.Text = string.format("%.1f", cfg[key])
    end
    table.insert(ovUiUpdaters, updateText)
    
    makeHoldable(btnMinus, function()
        local cfg = ovSettings[overlayMode == 0 and 1 or overlayMode]
        cfg[key] = math.clamp(cfg[key] - step, minVal, maxVal)
        updateText(); SaveHoloSettings()
    end)
    makeHoldable(btnPlus, function()
        local cfg = ovSettings[overlayMode == 0 and 1 or overlayMode]
        cfg[key] = math.clamp(cfg[key] + step, minVal, maxVal)
        updateText(); SaveHoloSettings()
    end)
end

CreateOvSettingRow(60, "Ukuran Teks:", "sz", 10, 80, 1)
CreateOvSettingRow(85, "Geser X:", "x", -800, 800, 5)
CreateOvSettingRow(110, "Geser Y:", "y", -800, 800, 5)

BtnOvVis.Activated:Connect(function() 
    local cfg = ovSettings[overlayMode == 0 and 1 or overlayMode]
    cfg.ven = not cfg.ven
    RefreshOverlayUI(); SaveHoloSettings() 
end)

BtnOvVisPos.Activated:Connect(function() 
    local cfg = ovSettings[overlayMode == 0 and 1 or overlayMode]
    cfg.vpos = (cfg.vpos % 2) + 1
    RefreshOverlayUI(); SaveHoloSettings() 
end)

CreateOvSettingRow(160, "Tinggi Visualizer:", "vsz", 5, 100, 1)

local OvColTextTitle = Instance.new("TextLabel", OverlayPanel); OvColTextTitle.Size = UDim2.new(0, 40, 0, 20); OvColTextTitle.Position = UDim2.new(0, 10, 0, 195); OvColTextTitle.BackgroundTransparency = 1; OvColTextTitle.Font = Enum.Font.Gotham; OvColTextTitle.TextColor3 = Color3.fromRGB(180, 180, 180); OvColTextTitle.TextSize = 10; OvColTextTitle.TextXAlignment = Enum.TextXAlignment.Left; OvColTextTitle.Text = "Teks:"
for i, col in ipairs(colors) do
    local btnC = Instance.new("TextButton", OverlayPanel); btnC.Size = UDim2.new(0, 14, 0, 14); btnC.Position = UDim2.new(0, 35 + (i*16), 0, 198); btnC.BackgroundColor3 = col; btnC.Text = ""; Instance.new("UICorner", btnC).CornerRadius = UDim.new(1,0)
    if col == Color3.fromRGB(0,0,0) then local strk = Instance.new("UIStroke", btnC); strk.Color = Color3.fromRGB(100,100,100) end
    btnC.Activated:Connect(function() 
        local cfg = ovSettings[overlayMode == 0 and 1 or overlayMode]
        cfg.cr, cfg.cg, cfg.cb = col.R, col.G, col.B; SaveHoloSettings() 
    end)
end

local OvColVisTitle = Instance.new("TextLabel", OverlayPanel); OvColVisTitle.Size = UDim2.new(0, 40, 0, 20); OvColVisTitle.Position = UDim2.new(0, 10, 0, 220); OvColVisTitle.BackgroundTransparency = 1; OvColVisTitle.Font = Enum.Font.Gotham; OvColVisTitle.TextColor3 = Color3.fromRGB(180, 180, 180); OvColVisTitle.TextSize = 10; OvColVisTitle.TextXAlignment = Enum.TextXAlignment.Left; OvColVisTitle.Text = "Vis:"
for i, col in ipairs(colors) do
    local btnC = Instance.new("TextButton", OverlayPanel); btnC.Size = UDim2.new(0, 14, 0, 14); btnC.Position = UDim2.new(0, 35 + (i*16), 0, 223); btnC.BackgroundColor3 = col; btnC.Text = ""; Instance.new("UICorner", btnC).CornerRadius = UDim.new(1,0)
    if col == Color3.fromRGB(0,0,0) then local strk = Instance.new("UIStroke", btnC); strk.Color = Color3.fromRGB(100,100,100) end
    btnC.Activated:Connect(function() 
        local cfg = ovSettings[overlayMode == 0 and 1 or overlayMode]
        cfg.vr, cfg.vg, cfg.vb = col.R, col.G, col.B; SaveHoloSettings() 
    end)
end

RefreshOverlayUI()

-- B. Panel Media Player (Centered under MainFrame for mobile screens)
MediaPanel.Size = UDim2.new(0, 220, 0, 110); MediaPanel.AnchorPoint = Vector2.new(0.5, 0); MediaPanel.Position = UDim2.new(0.5, 0, 1, 5); MediaPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20); MediaPanel.BorderSizePixel = 0; MediaPanel.Visible = false; MediaPanel.Active = true
Instance.new("UICorner", MediaPanel).CornerRadius = UDim.new(0, 8); local MediaStroke = Instance.new("UIStroke", MediaPanel); MediaStroke.Color = Color3.fromRGB(30, 215, 96); MediaStroke.Thickness = 1.5
local MediaTitle = Instance.new("TextLabel", MediaPanel); MediaTitle.Size = UDim2.new(1, 0, 0, 25); MediaTitle.BackgroundTransparency = 1; MediaTitle.Font = Enum.Font.GothamBold; MediaTitle.TextColor3 = Color3.new(1,1,1); MediaTitle.TextSize = 12; MediaTitle.Text = "Local Media Player"
local AudioInput = Instance.new("TextBox", MediaPanel); AudioInput.Size = UDim2.new(1, -20, 0, 25); AudioInput.Position = UDim2.new(0, 10, 0, 35); AudioInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40); AudioInput.TextColor3 = Color3.new(1,1,1); AudioInput.Font = Enum.Font.Gotham; AudioInput.TextSize = 12; AudioInput.PlaceholderText = "Masukkan ID Lagu..."; AudioInput.ClearTextOnFocus = false; AudioInput.Text = ""; Instance.new("UICorner", AudioInput).CornerRadius = UDim.new(0, 4)
local BtnPlayLocal = Instance.new("TextButton", MediaPanel); BtnPlayLocal.Size = UDim2.new(0.5, -15, 0, 25); BtnPlayLocal.Position = UDim2.new(0, 10, 0, 70); BtnPlayLocal.BackgroundColor3 = Color3.fromRGB(30, 215, 96); BtnPlayLocal.TextColor3 = Color3.new(0,0,0); BtnPlayLocal.Font = Enum.Font.GothamBold; BtnPlayLocal.TextSize = 12; BtnPlayLocal.Text = "▶ Putar"; Instance.new("UICorner", BtnPlayLocal).CornerRadius = UDim.new(0, 4)
local BtnStopLocal = Instance.new("TextButton", MediaPanel); BtnStopLocal.Size = UDim2.new(0.5, -15, 0, 25); BtnStopLocal.Position = UDim2.new(0.5, 5, 0, 70); BtnStopLocal.BackgroundColor3 = Color3.fromRGB(255, 50, 50); BtnStopLocal.TextColor3 = Color3.new(1,1,1); BtnStopLocal.Font = Enum.Font.GothamBold; BtnStopLocal.TextSize = 12; BtnStopLocal.Text = "⏹ Stop"; Instance.new("UICorner", BtnStopLocal).CornerRadius = UDim.new(0, 4)

-- C. DIRECTOR PANEL (🎬) (Centered under MainFrame for mobile screens)
DirectorPanel.Size = UDim2.new(0, 300, 0, 250); DirectorPanel.AnchorPoint = Vector2.new(0.5, 0); DirectorPanel.Position = UDim2.new(0.5, 0, 1, 5); DirectorPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20); DirectorPanel.BorderSizePixel = 0; DirectorPanel.Visible = false; DirectorPanel.Active = true
Instance.new("UICorner", DirectorPanel).CornerRadius = UDim.new(0, 8); local DirStroke = Instance.new("UIStroke", DirectorPanel); DirStroke.Color = Color3.fromRGB(200, 150, 255); DirStroke.Thickness = 1.5
local DirTitle = Instance.new("TextLabel", DirectorPanel); DirTitle.Size = UDim2.new(1, 0, 0, 25); DirTitle.BackgroundTransparency = 1; DirTitle.Font = Enum.Font.GothamBold; DirTitle.TextColor3 = Color3.new(1,1,1); DirTitle.TextSize = 12; DirTitle.Text = "Mode Sutradara (Cinematic/VFX)"

local function CreateDirToggle(name, state, x, y, callback)
    local btn = Instance.new("TextButton", DirectorPanel)
    btn.Size = UDim2.new(0, 135, 0, 26); btn.Position = UDim2.new(0, x, 0, y); btn.BackgroundColor3 = state and Color3.fromRGB(200, 150, 255) or Color3.fromRGB(40, 40, 40); btn.TextColor3 = state and Color3.new(0,0,0) or Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; btn.Text = name .. (state and ": ON" or ": OFF"); Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.Activated:Connect(function() state = not state; btn.BackgroundColor3 = state and Color3.fromRGB(200, 150, 255) or Color3.fromRGB(40, 40, 40); btn.TextColor3 = state and Color3.new(0,0,0) or Color3.new(1,1,1); btn.Text = name .. (state and ": ON" or ": OFF"); callback(state) end)
    return btn
end

CreateDirToggle("Drone Orbit", cineOrbit, 10, 35, function(s) cineOrbit = s; SaveHoloSettings() end)
CreateDirToggle("Action Cam (OTS)", cineOTS, 155, 35, function(s) cineOTS = s; SaveHoloSettings() end)
CreateDirToggle("Hero Cam (Low)", cineLowAngle, 10, 70, function(s) cineLowAngle = s; SaveHoloSettings() end)
CreateDirToggle("FOV Pulse", cineFOVPulse, 155, 70, function(s) cineFOVPulse = s; SaveHoloSettings() end)
CreateDirToggle("Bass Recoil", cineShake, 10, 105, function(s) cineShake = s; SaveHoloSettings() end)
CreateDirToggle("Depth of Field", cineDoFState, 155, 105, function(s) cineDoFState = s; SaveHoloSettings() end)
CreateDirToggle("Glitch RGB", cineGlitch, 10, 140, function(s) cineGlitch = s; SaveHoloSettings() end)
CreateDirToggle("Vignette Pulse", cineVignette, 155, 140, function(s) cineVignette = s; SaveHoloSettings() end)
CreateDirToggle("Ghost Trail", cineGhost, 10, 175, function(s) cineGhost = s; SaveHoloSettings() end)
CreateDirToggle("Ground Ripple", cineRipple, 155, 175, function(s) cineRipple = s; SaveHoloSettings() end)
CreateDirToggle("Spotlight", cineSpotlight, 10, 210, function(s) cineSpotlight = s; SaveHoloSettings() end)
CreateDirToggle("DLSS 5 (RTX)", cineDLSS, 155, 210, function(s) cineDLSS = s; SaveHoloSettings() end)

-- D. PANEL PILIHAN LIRIK MULTIPLE & MANUAL SEARCH (📝) (Fixed duplicate instance & wired up search button)
LyricPanel.Size = UDim2.new(0, 280, 0, 175); LyricPanel.AnchorPoint = Vector2.new(0.5, 0); LyricPanel.Position = UDim2.new(0.5, 0, 1, 5); LyricPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20); LyricPanel.BorderSizePixel = 0; LyricPanel.Visible = false; LyricPanel.Active = true
Instance.new("UICorner", LyricPanel).CornerRadius = UDim.new(0, 8); local LyrStroke = Instance.new("UIStroke", LyricPanel); LyrStroke.Color = Color3.fromRGB(255, 200, 50); LyrStroke.Thickness = 1.5
local LyrPanelTitle = Instance.new("TextLabel", LyricPanel); LyrPanelTitle.Size = UDim2.new(1, 0, 0, 25); LyrPanelTitle.BackgroundTransparency = 1; LyrPanelTitle.Font = Enum.Font.GothamBold; LyrPanelTitle.TextColor3 = Color3.new(1,1,1); LyrPanelTitle.TextSize = 12; LyrPanelTitle.Text = "Pencarian Lirik Manual"

local ManualSearchInput = Instance.new("TextBox", LyricPanel); ManualSearchInput.Size = UDim2.new(1, -120, 0, 24); ManualSearchInput.Position = UDim2.new(0, 10, 0, 30); ManualSearchInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40); ManualSearchInput.TextColor3 = Color3.new(1,1,1); ManualSearchInput.Font = Enum.Font.Gotham; ManualSearchInput.TextSize = 11; ManualSearchInput.PlaceholderText = "Ketik Judul & Artis..."; ManualSearchInput.ClearTextOnFocus = false; ManualSearchInput.Text = ""; Instance.new("UICorner", ManualSearchInput).CornerRadius = UDim.new(0, 4)

local BtnProvider = Instance.new("TextButton", LyricPanel); BtnProvider.Size = UDim2.new(0, 55, 0, 24); BtnProvider.Position = UDim2.new(1, -105, 0, 30); BtnProvider.BackgroundColor3 = Color3.fromRGB(30, 100, 200); BtnProvider.TextColor3 = Color3.new(1,1,1); BtnProvider.Font = Enum.Font.GothamBold; BtnProvider.TextSize = 10; BtnProvider.Text = currentLyricProvider; Instance.new("UICorner", BtnProvider).CornerRadius = UDim.new(0, 4)
BtnProvider.Activated:Connect(function()
    if currentLyricProvider == "LRCLIB" then currentLyricProvider = "NETEASE"; BtnProvider.BackgroundColor3 = Color3.fromRGB(200, 50, 50) 
    else currentLyricProvider = "LRCLIB"; BtnProvider.BackgroundColor3 = Color3.fromRGB(30, 100, 200) end
    BtnProvider.Text = currentLyricProvider
end)

local BtnSearchManual = Instance.new("TextButton", LyricPanel); BtnSearchManual.Size = UDim2.new(0, 40, 0, 24); BtnSearchManual.Position = UDim2.new(1, -45, 0, 30); BtnSearchManual.BackgroundColor3 = Color3.fromRGB(255, 200, 50); BtnSearchManual.TextColor3 = Color3.new(0,0,0); BtnSearchManual.Font = Enum.Font.GothamBold; BtnSearchManual.TextSize = 11; BtnSearchManual.Text = "Cari"; Instance.new("UICorner", BtnSearchManual).CornerRadius = UDim.new(0, 4)

local LyricSelectionBtns = {}
local function SetActiveLyricData(matchData)
    if not matchData then return end
    activeLyrics = matchData.Lyrics
    local origDur, rbxDur = matchData.OriginalDuration, activeSound and activeSound.TimeLength or 0
    if not manualSpeedOverride and origDur > 0 and rbxDur > 5 then
        local autoRatio = origDur / rbxDur
        if autoRatio > 1.05 or autoRatio < 0.95 then
            lyricSpeed = autoRatio; SpeedLabelBtn.Text = string.format("Speed: %.2fx (Auto)", lyricSpeed); SpeedLabelBtn.TextColor3 = Color3.fromRGB(30, 215, 96)
        else
            lyricSpeed = 1.0; SpeedLabelBtn.Text = "Speed: 1.0x"; SpeedLabelBtn.TextColor3 = Color3.fromRGB(200, 150, 255)
        end
    end
    lyricOffset = 0.0; SyncLabel.Text = "Offset: 0.0s"
    TitleLabel.Text = matchData.TrackName; ArtistLabel.Text = matchData.ArtistName
    pcall(function() StarterGui:SetCore("SendNotification", { Title = "Lirik Dipilih", Text = matchData.TrackName, Duration = 3 }) end)
end

for i = 1, 3 do
    local btn = Instance.new("TextButton", LyricPanel)
    btn.Size = UDim2.new(1, -20, 0, 28); btn.Position = UDim2.new(0, 10, 0, 62 + ((i-1)*32))
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.new(1,1,1); btn.TextSize = 11; btn.TextTruncate = Enum.TextTruncate.AtEnd; btn.Visible = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.Activated:Connect(function() if currentLyricMatches and currentLyricMatches[i] then SetActiveLyricData(currentLyricMatches[i]) end end)
    table.insert(LyricSelectionBtns, btn)
end

BtnHoloSettings.Activated:Connect(function() local target = not HoloSetPanel.Visible; CloseAllPanels(); HoloSetPanel.Visible = target; BtnHoloSettings.BackgroundColor3 = target and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(40, 40, 40); BtnHoloSettings.TextColor3 = target and Color3.new(0,0,0) or Color3.fromRGB(200, 200, 200) end)
BtnMedia.Activated:Connect(function() local target = not MediaPanel.Visible; CloseAllPanels(); MediaPanel.Visible = target; BtnMedia.BackgroundColor3 = target and Color3.fromRGB(30, 215, 96) or Color3.fromRGB(40, 40, 40); BtnMedia.TextColor3 = target and Color3.new(0,0,0) or Color3.fromRGB(200, 200, 200) end)
BtnDirector.Activated:Connect(function() local target = not DirectorPanel.Visible; CloseAllPanels(); DirectorPanel.Visible = target; BtnDirector.BackgroundColor3 = target and Color3.fromRGB(200, 150, 255) or Color3.fromRGB(40, 40, 40); BtnDirector.TextColor3 = target and Color3.new(0,0,0) or Color3.fromRGB(200, 200, 200) end)
BtnLyricsMenu.Activated:Connect(function() local target = not LyricPanel.Visible; CloseAllPanels(); LyricPanel.Visible = target; BtnLyricsMenu.BackgroundColor3 = target and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(40, 40, 40); BtnLyricsMenu.TextColor3 = target and Color3.new(0,0,0) or Color3.fromRGB(200, 200, 200) end)
BtnOverlay.Activated:Connect(function() local target = not OverlayPanel.Visible; CloseAllPanels(); OverlayPanel.Visible = target; BtnOverlay.BackgroundColor3 = target and Color3.fromRGB(255, 100, 150) or Color3.fromRGB(40, 40, 40); BtnOverlay.TextColor3 = target and Color3.new(0,0,0) or Color3.fromRGB(200, 200, 200) end)

BtnPlayLocal.Activated:Connect(function() local id = AudioInput.Text:match("%d+"); if id then CustomAudioPlayer.SoundId = "rbxassetid://" .. id; CustomAudioPlayer.Volume = 1; CustomAudioPlayer:Play(); pcall(function() StarterGui:SetCore("SendNotification", { Title = "Local Audio", Text = "Memutar ID: "..id, Duration = 3 }) end) end end)
BtnStopLocal.Activated:Connect(function() CustomAudioPlayer:Stop() end)
BtnMute.Activated:Connect(function() isMutedLocally = not isMutedLocally; BtnMute.Text = isMutedLocally and "🔇" or "🔊"; if activeSound and not isMutedLocally then activeSound.Volume = originalVolume end end)

BtnMinimize.Activated:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then BtnMinimize.Text = "+"; TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 64)}):Play(); CloseAllPanels()
    else BtnMinimize.Text = "—"; TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 550, 0, 175)}):Play() end
end)

-- FIXED ANDROID TOUCH & MOUSE DRAG LOGIC (Accounts for UIScale and AnchorPoint 0.5)
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local scale = math.max(MobileScale.Scale, 0.01)
        local delta = (input.Position - dragStart) / scale
        local camera = Workspace.CurrentCamera
        local viewport = camera and (camera.ViewportSize / scale) or Vector2.new(800, 600)
        local halfW = MainFrame.Size.X.Offset * 0.5
        local frameH = MainFrame.Size.Y.Offset
        local minX = -viewport.X * 0.5 + halfW + 6
        local maxX = viewport.X * 0.5 - halfW - 6
        local minY = 6
        local maxY = math.max(6, viewport.Y - frameH - 6)
        local x = math.clamp(startPos.X.Offset + delta.X, minX, maxX)
        local y = math.clamp(startPos.Y.Offset + delta.Y, minY, maxY)
        MainFrame.Position = UDim2.new(0.5, x, 0, y)
    end
end)
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightControl then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

local function ShowWidget()
    if not isWidgetVisible then
        isWidgetVisible = true
        TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 20)}):Play()
    end
end
local function HideWidget()
    if isWidgetVisible then
        isWidgetVisible = false
        CloseAllPanels()
        TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -200)}):Play()
    end
end

-- DRAGGABLE ANDROID FLOATING TOGGLE BUTTON
local MobileToggle = Instance.new("TextButton")
MobileToggle.Name = "Hawk909_MobileToggle"
MobileToggle.Size = UDim2.new(0, 46, 0, 46)
MobileToggle.AnchorPoint = Vector2.new(1, 0.5)
MobileToggle.Position = UDim2.new(1, -12, 0.62, 0)
MobileToggle.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
MobileToggle.BackgroundTransparency = 0.12
MobileToggle.Text = "♫"
MobileToggle.TextColor3 = Color3.fromRGB(30, 215, 96)
MobileToggle.TextSize = 24
MobileToggle.Font = Enum.Font.GothamBold
MobileToggle.AutoButtonColor = true
MobileToggle.ZIndex = 100
MobileToggle.Parent = ScreenGui
Instance.new("UICorner", MobileToggle).CornerRadius = UDim.new(1, 0)
local MobileToggleStroke = Instance.new("UIStroke", MobileToggle)
MobileToggleStroke.Color = Color3.fromRGB(30, 215, 96)
MobileToggleStroke.Thickness = 1.5

local toggleDrag, toggleDragInput, toggleDragStart, toggleStartPos, toggleMoved = false, nil, nil, nil, false
MobileToggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDrag = true
        toggleMoved = false
        toggleDragStart = input.Position
        toggleStartPos = MobileToggle.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                toggleDrag = false
            end
        end)
    end
end)
MobileToggle.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == toggleDragInput and toggleDrag then
        local delta = input.Position - toggleDragStart
        if delta.Magnitude > 8 then
            toggleMoved = true
            local scale = math.max(MobileScale.Scale, 0.01)
            local scaledDelta = delta / scale
            MobileToggle.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + scaledDelta.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + scaledDelta.Y)
        end
    end
end)
MobileToggle.Activated:Connect(function()
    if toggleMoved then return end
    if not isWidgetVisible then
        MainFrame.Visible = true
        ShowWidget()
        MobileToggle.Text = "♫"
    else
        MainFrame.Visible = not MainFrame.Visible
        if not MainFrame.Visible then CloseAllPanels() end
        MobileToggle.Text = MainFrame.Visible and "♫" or "+"
    end
end)

-- ARCEUS X NEO & ANDROID HTTP COMPATIBILITY WRAPPER
local function HttpGetCompat(url)
    local requestFn = nil
    if type(request) == "function" then
        requestFn = request
    elseif type(http_request) == "function" then
        requestFn = http_request
    elseif type(http) == "table" and type(http.request) == "function" then
        requestFn = http.request
    elseif type(syn) == "table" and type(syn.request) == "function" then
        requestFn = syn.request
    elseif type(fluxus) == "table" and type(fluxus.request) == "function" then
        requestFn = fluxus.request
    elseif type(Arceus) == "table" and type(Arceus.request) == "function" then
        requestFn = Arceus.request
    end

    if requestFn then
        local ok, response = pcall(requestFn, {
            Url = url,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Mozilla/5.0 (Linux; Android 13) Roblox/ArceusXNeo",
                ["Accept"] = "application/json"
            }
        })
        if ok and type(response) == "table" then
            local status = tonumber(response.StatusCode or response.Status or 200)
            if status and status >= 200 and status < 300 and type(response.Body) == "string" and response.Body ~= "" then
                return response.Body
            end
        end
    end

    local ok, response = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(response) == "string" and response ~= "" then
        return response
    end
    local ok2, response2 = pcall(function() return game:HttpGetAsync(url) end)
    if ok2 and type(response2) == "string" and response2 ~= "" then
        return response2
    end
    return nil
end

-- FETCH ENGINE 1: LRCLIB
local function FetchMultipleLyricsLRCLIB(searchQuery)
    local fallbackData = {}
    local encodedName = HttpService:UrlEncode(searchQuery)
    local apiUrl = "https://lrclib.net/api/search?q=" .. encodedName
    local success, response = pcall(function() return HttpGetCompat(apiUrl) end)
    if not success or not response then return fallbackData end
    local data = nil; pcall(function() data = HttpService:JSONDecode(response) end)
    if type(data) ~= "table" or #data == 0 then return fallbackData end
    local results = {}
    for i = 1, math.min(#data, 20) do 
        if data[i].syncedLyrics and data[i].syncedLyrics ~= "" then 
            local rawLRC = data[i].syncedLyrics
            local origDuration = data[i].duration or 0
            local trackName = data[i].trackName or "Unknown"
            local artistName = data[i].artistName or "Unknown"
            local parsedLyrics = {}
            for line in string.gmatch(rawLRC, "[^\r\n]+") do
                local min, sec, text = string.match(line, "%[(%d+):(%d+%.?%d*)%](.*)")
                if min and sec then table.insert(parsedLyrics, { Time = (tonumber(min) * 60) + tonumber(sec), Text = text and text:gsub("^%s*(.-)%s*$", "%1") or "" }) end
            end
            if origDuration == 0 and #parsedLyrics > 0 then origDuration = parsedLyrics[#parsedLyrics].Time + 10 end
            table.insert(results, { Lyrics = parsedLyrics, OriginalDuration = origDuration, TrackName = trackName, ArtistName = artistName })
            if #results >= 3 then break end
        end 
    end
    return results
end

-- FETCH ENGINE 2: NETEASE
local function FetchMultipleLyricsNetease(searchQuery)
    local fallbackData = {}
    local encodedQuery = HttpService:UrlEncode(searchQuery)
    local searchUrl = "https://music.163.com/api/search/pc?s=" .. encodedQuery .. "&type=1&limit=5"
    local sSuc, sRes = pcall(function() return HttpGetCompat(searchUrl) end)
    if not sSuc or not sRes then return fallbackData end
    local searchData; pcall(function() searchData = HttpService:JSONDecode(sRes) end)
    if not searchData or not searchData.result or not searchData.result.songs then return fallbackData end
    local results = {}
    for i = 1, math.min(#searchData.result.songs, 5) do
        local song = searchData.result.songs[i]
        local trackName = song.name or "Unknown"
        local artistName = (song.artists and song.artists[1] and song.artists[1].name) or "Unknown"
        local duration = (song.duration or 0) / 1000
        local lyricUrl = "https://music.163.com/api/song/lyric?id=" .. tostring(song.id) .. "&lv=1"
        local lSuc, lRes = pcall(function() return HttpGetCompat(lyricUrl) end)
        if lSuc and lRes then
            local lData; pcall(function() lData = HttpService:JSONDecode(lRes) end)
            if lData and lData.lrc and lData.lrc.lyric then
                local rawLRC = lData.lrc.lyric
                local parsedLyrics = {}
                for line in string.gmatch(rawLRC, "[^\r\n]+") do
                    local min, sec, text = string.match(line, "%[(%d+):(%d+%.?%d*)%](.*)")
                    if min and sec then table.insert(parsedLyrics, { Time = (tonumber(min) * 60) + tonumber(sec), Text = text and text:gsub("^%s*(.-)%s*$", "%1") or "" }) end
                end
                if #parsedLyrics > 0 then table.insert(results, { Lyrics = parsedLyrics, OriginalDuration = duration, TrackName = trackName, ArtistName = artistName }) end
            end
        end
        if #results >= 3 then break end
    end
    return results
end

local function FetchMultipleLyrics(query, isManual)
    local searchString = isManual and query or CleanSongName(query)
    local cacheKey = currentLyricProvider .. "_" .. searchString
    if lyricsCache[cacheKey] then return lyricsCache[cacheKey] end
    local results = {}
    if currentLyricProvider == "LRCLIB" then results = FetchMultipleLyricsLRCLIB(searchString) elseif currentLyricProvider == "NETEASE" then results = FetchMultipleLyricsNetease(searchString) end
    if #results > 0 then lyricsCache[cacheKey] = results end
    return results
end

-- CONNECTED MANUAL LYRIC SEARCH BUTTON (Previously missing in original script)
BtnSearchManual.Activated:Connect(function()
    local q = ManualSearchInput.Text:match("^%s*(.-)%s*$")
    if not q or q == "" then return end
    BtnSearchManual.Text = "..."
    for _, b in ipairs(LyricSelectionBtns) do b.Visible = false end
    task.spawn(function()
        local suc, matches = pcall(function() return FetchMultipleLyrics(q, true) end)
        BtnSearchManual.Text = "Cari"
        if suc and matches and #matches > 0 then
            currentLyricMatches = matches
            for i = 1, 3 do
                if matches[i] then
                    LyricSelectionBtns[i].Text = matches[i].TrackName .. " - " .. matches[i].ArtistName
                    LyricSelectionBtns[i].Visible = true
                end
            end
            SetActiveLyricData(matches[1])
        else
            pcall(function() StarterGui:SetCore("SendNotification", { Title = "Lirik", Text = "Tidak ditemukan untuk: " .. q, Duration = 3 }) end)
        end
    end)
end)

local function FindPlayingSong()
    if CustomAudioPlayer and CustomAudioPlayer.IsPlaying then return CustomAudioPlayer end
    local bestSound = nil; local maxVolume = -1
    for _, area in ipairs({Workspace, SoundService, LocalPlayer}) do
        for _, obj in pairs(area:GetDescendants()) do
            if obj:IsA("Sound") and obj.IsPlaying and obj.SoundId ~= "" and obj ~= CustomAudioPlayer then
                if obj.TimeLength == 0 or obj.TimeLength > 15 then if obj.Volume > maxVolume then maxVolume = obj.Volume; bestSound = obj end end
            end
        end
    end
    return bestSound
end

-- // VFX ENGINE //
local lastParticleTime = 0
local function EmitMusicNote()
    if tick() - lastParticleTime < 0.25 then return end
    lastParticleTime = tick()
    local note = Instance.new("TextLabel"); note.BackgroundTransparency = 1; note.Text = math.random() > 0.5 and "🎵" or "🎶"; note.TextSize = math.random(18, 30); note.Position = UDim2.new(0, math.random(0, 300), 0, 80); note.Parent = Billboard3D
    local tw = TweenService:Create(note, TweenInfo.new(math.random(15, 25)/10, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Position = UDim2.new(0, note.Position.X.Offset + math.random(-40, 40), 0, -80), TextTransparency = 1, TextStrokeTransparency = 1 })
    tw:Play(); tw.Completed:Connect(function() note:Destroy() end)
end

local function FireGlitchEffect()
    if not cineGlitch then return end
    GlitchRed.Text = Lyr3DCurrent.Text; GlitchCyan.Text = Lyr3DCurrent.Text
    GlitchRed.Position = Lyr3DCurrent.Position + UDim2.new(0, math.random(2, 6), 0, math.random(-2, 2))
    GlitchCyan.Position = Lyr3DCurrent.Position + UDim2.new(0, math.random(-6, -2), 0, math.random(-2, 2))
    GlitchRed.TextTransparency = 0; GlitchCyan.TextTransparency = 0
    TweenService:Create(GlitchRed, TweenInfo.new(0.2), {Position = Lyr3DCurrent.Position, TextTransparency = 1}):Play()
    TweenService:Create(GlitchCyan, TweenInfo.new(0.2), {Position = Lyr3DCurrent.Position, TextTransparency = 1}):Play()
end

local lastGhostTime = 0
local function EmitGhostTrail(hrp)
    if not cineGhost or tick() - lastGhostTime < 0.15 then return end
    lastGhostTime = tick()
    local ghost = Instance.new("Part"); ghost.Transparency = 1; ghost.CanCollide = false; ghost.Anchored = true; ghost.Size = Vector3.new(0.1,0.1,0.1); ghost.CFrame = hrp.CFrame * CFrame.new(holoOffsetX, holoOffsetY, holoOffsetZ); ghost.Parent = Workspace
    local bg = Instance.new("BillboardGui", ghost); bg.Size = Billboard3D.Size; bg.SizeOffset = Billboard3D.SizeOffset; bg.AlwaysOnTop = false; bg.LightInfluence = 0
    local txt = Instance.new("TextLabel", bg); txt.Size = Lyr3DCurrent.Size; txt.Position = Lyr3DCurrent.Position; txt.BackgroundTransparency = 1; txt.Font = Lyr3DCurrent.Font; txt.Text = Lyr3DCurrent.Text; txt.TextColor3 = holoGlowColor; txt.TextScaled = true; txt.TextTransparency = 0.5
    local cons = Instance.new("UITextSizeConstraint", txt); cons.MaxTextSize = holoTextSize
    local tw = TweenService:Create(txt, TweenInfo.new(0.6), {TextTransparency = 1}); tw:Play(); tw.Completed:Connect(function() ghost:Destroy() end)
end

local lastRippleTime = 0
local function EmitRipple(hrp)
    if not cineRipple or tick() - lastRippleTime < 0.4 then return end
    lastRippleTime = tick()
    local ripple = Instance.new("Part"); ripple.Anchored = true; ripple.CanCollide = false; ripple.CastShadow = false
    ripple.Material = Enum.Material.Neon; ripple.Color = holoGlowColor; ripple.Transparency = 0.2
    ripple.Size = Vector3.new(1, 0.05, 1); ripple.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 3, 0)) * CFrame.Angles(0,0,0)
    Instance.new("CylinderMesh", ripple); ripple.Parent = Workspace
    local tw = TweenService:Create(ripple, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = Vector3.new(30, 0.05, 30), Transparency = 1})
    tw:Play(); tw.Completed:Connect(function() ripple:Destroy() end)
end

local SpotlightPart = Instance.new("Part"); SpotlightPart.Transparency = 1; SpotlightPart.Anchored = true; SpotlightPart.CanCollide = false; SpotlightPart.Parent = Workspace
local OverheadSpotlight = Instance.new("SpotLight", SpotlightPart); OverheadSpotlight.Angle = 70; OverheadSpotlight.Range = 30; OverheadSpotlight.Enabled = false

-- // 1.5. EXTREME FIDELITY OVERRIDE: TRUE RTX & ANTI-ALIASING //
local function ForceExtremeFidelity()
    pcall(function()
        Lighting.GlobalShadows = true
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
    end)
    
    local function UpgradeAccessory(char)
        if not char then return end
        task.wait(0.5) 
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and not root:FindFirstChild("Hawk909_RTXLight") then
            local rtxLight = Instance.new("PointLight", root)
            rtxLight.Name = "Hawk909_RTXLight"
            rtxLight.Brightness = 1.5
            rtxLight.Range = 15
            rtxLight.Color = Color3.fromRGB(255, 250, 245)
            rtxLight.Shadows = true
            rtxLight.Enabled = false 
        end
        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle then
                    pcall(function()
                        if handle:IsA("MeshPart") then handle.RenderFidelity = Enum.RenderFidelity.Precise end
                    end)
                    handle.Material = Enum.Material.SmoothPlastic; handle.Reflectance = 0.15
                    if not handle:FindFirstChild("Hawk909_EdgeAA") then
                        local hl = Instance.new("Highlight", handle); hl.Name = "Hawk909_EdgeAA"; hl.Adornee = handle; hl.FillTransparency = 1; hl.OutlineColor = Color3.new(1, 1, 1); hl.OutlineTransparency = 0.7; hl.DepthMode = Enum.HighlightDepthMode.Occluded
                    end
                    local sa = handle:FindFirstChildOfClass("SurfaceAppearance")
                    if sa then local temp = sa.Parent; sa.Parent = nil; RunService.RenderStepped:Wait(); sa.Parent = temp end
                end
            end
        end
    end
    if LocalPlayer.Character then task.spawn(UpgradeAccessory, LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(function(char) task.spawn(UpgradeAccessory, char) end)
end
ForceExtremeFidelity()

-- // LOOP RENDER UTAMA (DLSS FRAME GEN EQUATION) //
local orbitAngle = 0
RunService.RenderStepped:Connect(function(dt)
    if isMutedLocally and activeSound then activeSound.Volume = 0 end

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    local loudness = 0
    if activeSound and activeSound.IsPlaying then loudness = math.clamp(activeSound.PlaybackLoudness / 150, 0, 1.5) end

    DLSSColor.Enabled = cineDLSS; DLSSBloom.Enabled = cineDLSS; CineDoF.Enabled = cineDoFState; VignetteImg.Active = cineVignette
    if cineVignette then VignetteImg.ImageTransparency = math.clamp(0.9 - (0.4 * loudness), 0.2, 1) else VignetteImg.ImageTransparency = 1 end

    if hrp then
        local rtxLight = hrp:FindFirstChild("Hawk909_RTXLight")
        if rtxLight then rtxLight.Enabled = cineDLSS end
    end

    -- FREECAM STABILIZER BYPASS
    local isCineCamNeeded = (cineOrbit or cineLowAngle)
    local isFreecam = (cam.CameraType == Enum.CameraType.Scriptable and not isCineCamNeeded and not wasCinematicCam)

    if hrp and hum and not isFreecam then
        local baseOffset = cineOTS and Vector3.new(2, 0.5, 0) or Vector3.new(0, 0, 0)
        local shakeOffset = Vector3.new(0,0,0)
        if cineShake and loudness > 0.8 then
            local intensity = loudness * 0.3
            shakeOffset = Vector3.new(math.random(-10,10)*0.01*intensity, math.random(-10,10)*0.01*intensity, math.random(-10,10)*0.01*intensity)
        end
        hum.CameraOffset = hum.CameraOffset:Lerp(baseOffset + shakeOffset, 1 - math.exp(-10 * dt))

        if cineLowAngle then
            cam.CameraType = Enum.CameraType.Scriptable
            local targetPos = hrp.CFrame * CFrame.new(0, -3, -8)
            cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(targetPos.Position, hrp.Position + Vector3.new(0, 3, 0)), 1 - math.exp(-6 * dt))
        elseif cineOrbit then
            cam.CameraType = Enum.CameraType.Scriptable
            orbitAngle = orbitAngle + (dt * 0.5)
            local orbitPos = hrp.Position + Vector3.new(math.cos(orbitAngle)*10, 4, math.sin(orbitAngle)*10)
            cam.CFrame = CFrame.new(orbitPos, hrp.Position)
        else
            if cam.CameraType == Enum.CameraType.Scriptable then 
                cam.CameraType = Enum.CameraType.Custom 
                cam.CameraSubject = hum
            end
        end
        
        local fovOffset = 0
        if cineFOVPulse and loudness > 0.8 then fovOffset = -(loudness * 5) end
        cam.FieldOfView = cam.FieldOfView + ((targetBaseFOV + fovOffset) - cam.FieldOfView) * (1 - math.exp(-8 * dt))
    end
    wasCinematicCam = isCineCamNeeded
    
    if hrp and hum then
        if cineSpotlight then
            SpotlightPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 15, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
            OverheadSpotlight.Enabled = true; OverheadSpotlight.Color = holoGlowColor; OverheadSpotlight.Brightness = 1 + (loudness * 3)
        else OverheadSpotlight.Enabled = false end
        if cineRipple and loudness > 1.0 then EmitRipple(hrp) end
    end

    if isHologramEnabled and hrp then
        local holoPart = hrp:FindFirstChild("Hawk909_Holo_Part")
        if not holoPart then holoPart = Instance.new("Part"); holoPart.Name = "Hawk909_Holo_Part"; holoPart.Transparency = 1; holoPart.CanCollide = false; holoPart.Anchored = true; holoPart.Size = Vector3.new(0.1, 0.1, 0.1); holoPart.Parent = hrp end
        holoPart.CFrame = hrp.CFrame * CFrame.new(holoOffsetX, holoOffsetY, holoOffsetZ)
        Billboard3D.Adornee = holoPart; Billboard3D.Enabled = isWidgetVisible
        if hum and hum.MoveDirection.Magnitude > 0 then EmitGhostTrail(hrp) end
    else Billboard3D.Enabled = false end

    local tickTime = tick() * 4
    if activeSound and activeSound.IsPlaying then
        for i, bar in ipairs(visBars) do
            local targetHeight = math.clamp(12 * loudness * math.abs(math.noise(tickTime, i * 0.1, 0) + math.sin(tickTime + i)), 2, 12)
            bar.Size = bar.Size:Lerp(UDim2.new(0, 4, 0, targetHeight), 1 - math.exp(-15 * dt))
        end
        if vis3DEnabled and isHologramEnabled then
            Vis3DContainer.Visible = true
            for i, bar in ipairs(vis3DBars) do
                local freq = math.abs(math.noise(tickTime, i * 0.1, 0) + math.sin(tickTime + i))
                bar.Size = bar.Size:Lerp(UDim2.new(0, 6, 0, math.clamp(15 * loudness * freq, 2, 15)), 1 - math.exp(-15 * dt)); bar.BackgroundColor3 = holoGlowColor
            end
        else Vis3DContainer.Visible = false end
        if isHologramEnabled and particlesEnabled and loudness > 0.8 then EmitMusicNote() end
    else
        for _, bar in ipairs(visBars) do bar.Size = bar.Size:Lerp(UDim2.new(0, 4, 0, 2), 1 - math.exp(-15 * dt)) end
        if vis3DEnabled then for _, bar in ipairs(vis3DBars) do bar.Size = bar.Size:Lerp(UDim2.new(0, 6, 0, 2), 1 - math.exp(-15 * dt)) end end
    end

    if not isWidgetVisible or not activeSound or not activeSound.IsPlaying then 
        OvContainer.Visible = false
        return 
    end
    
    local currentPos = (activeSound.TimePosition * lyricSpeed) + lyricOffset
    local prevText, currentText, nextText = "", "...", ""
    local lineProgress = 0
    
    if #activeLyrics > 0 then
        local currentIndex = 0
        for i = 1, #activeLyrics do
            local lyric, nextLyr = activeLyrics[i], activeLyrics[i + 1]
            if currentPos >= lyric.Time and (not nextLyr or currentPos < nextLyr.Time) then
                currentIndex = i; currentText = lyric.Text ~= "" and lyric.Text or "..."
                if nextLyr then local duration = nextLyr.Time - lyric.Time; if duration > 0 then lineProgress = math.clamp((currentPos - lyric.Time) / duration, 0, 1) end else lineProgress = 1 end
                break
            end
        end
        if currentIndex > 0 then
            local p = 1; while activeLyrics[currentIndex - p] and activeLyrics[currentIndex - p].Text == "" do p = p + 1 end
            prevText = activeLyrics[currentIndex - p] and activeLyrics[currentIndex - p].Text or ""
            local n = 1; while activeLyrics[currentIndex + n] and activeLyrics[currentIndex + n].Text == "" do n = n + 1 end
            nextText = activeLyrics[currentIndex + n] and activeLyrics[currentIndex + n].Text or ""
        end
    else
        currentText = "Lirik tidak tersedia."
    end
    
    Grad2D.Offset = Vector2.new(lineProgress - 0.5, 0)
    if karaoke3DEnabled then Grad3D.Offset = Vector2.new(lineProgress - 0.5, 0) end

    -- OVERLAY 2D RENDERER (INDEPENDENT SETTINGS)
    if overlayMode > 0 then
        local cfg = ovSettings[overlayMode]
        
        OvContainer.Visible = true
        OvPrev.Text = prevText
        OvCurr.Text = currentText
        OvNext.Text = nextText
        
        OvCurr.TextColor3 = Color3.new(cfg.cr, cfg.cg, cfg.cb)
        OvCurr.TextSize = cfg.sz
        OvPrev.TextSize = math.max(10, cfg.sz - 6)
        OvNext.TextSize = math.max(10, cfg.sz - 6)
        
        OvVisContainer.LayoutOrder = (cfg.vpos == 1) and 1 or 3

        if overlayMode == 4 then 
            OvPrev.Visible = false
            OvNext.Visible = false
        else
            OvPrev.Visible = true
            OvNext.Visible = true
        end

        if overlayMode == 1 or overlayMode == 4 then 
            OvContainer.AnchorPoint = Vector2.new(0.5, 0.5)
            OvContainer.Position = UDim2.new(0.5, cfg.x, 1, -55 + cfg.y)
            OvListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            OvTextList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            OvVisList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            OvPrev.TextXAlignment = Enum.TextXAlignment.Center
            OvCurr.TextXAlignment = Enum.TextXAlignment.Center
            OvNext.TextXAlignment = Enum.TextXAlignment.Center
        elseif overlayMode == 2 then 
            OvContainer.AnchorPoint = Vector2.new(1, 0.5)
            OvContainer.Position = UDim2.new(1, -20 + cfg.x, 0.5, cfg.y)
            OvListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            OvTextList.HorizontalAlignment = Enum.HorizontalAlignment.Right
            OvVisList.HorizontalAlignment = Enum.HorizontalAlignment.Right
            OvPrev.TextXAlignment = Enum.TextXAlignment.Right
            OvCurr.TextXAlignment = Enum.TextXAlignment.Right
            OvNext.TextXAlignment = Enum.TextXAlignment.Right
        elseif overlayMode == 3 then 
            OvContainer.AnchorPoint = Vector2.new(0, 0.5)
            OvContainer.Position = UDim2.new(0, 20 + cfg.x, 0.5, cfg.y)
            OvListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
            OvTextList.HorizontalAlignment = Enum.HorizontalAlignment.Left
            OvVisList.HorizontalAlignment = Enum.HorizontalAlignment.Left
            OvPrev.TextXAlignment = Enum.TextXAlignment.Left
            OvCurr.TextXAlignment = Enum.TextXAlignment.Left
            OvNext.TextXAlignment = Enum.TextXAlignment.Left
        end

        if cfg.ven then
            OvVisContainer.Visible = true
            local visColor = Color3.new(cfg.vr, cfg.vg, cfg.vb)
            for i, bar in ipairs(ovBars) do
                local freq = math.abs(math.noise(tickTime, i * 0.1, 0) + math.sin(tickTime + i))
                local targetH = math.clamp(cfg.vsz * loudness * freq, 2, cfg.vsz)
                bar.Size = bar.Size:Lerp(UDim2.new(0, 4, 0, targetH), 1 - math.exp(-15 * dt))
                bar.BackgroundColor3 = visColor
            end
        else
            OvVisContainer.Visible = false
        end
    else
        OvContainer.Visible = false
    end

    if LyricCurrent.Text ~= currentText then
        LyricPrev.Text = prevText; LyricCurrent.Text = currentText; LyricNext.Text = nextText
        LyricCurrent.TextSize = 16; TweenService:Create(LyricCurrent, TweenInfo.new(0.2), {TextSize = 15}):Play()
        Lyr3DPrev.Text = prevText; Lyr3DCurrent.Text = currentText; Lyr3DNext.Text = nextText
        
        FireGlitchEffect()
        
        if ConstraintCurrent then ConstraintCurrent.MaxTextSize = holoTextSize + 6; TweenService:Create(ConstraintCurrent, TweenInfo.new(0.2), {MaxTextSize = holoTextSize}):Play() end
        if autoChatEnabled and currentText ~= "..." and currentText ~= "Lirik tidak tersedia." and currentText ~= "Mencari lirik..." then SendToChat(currentText) end
    end

    if bassGlowEnabled then
        Scale3D.Scale = 1; Lyr3DCurrent.TextStrokeColor3 = holoGlowColor; Lyr3DCurrent.TextStrokeTransparency = math.clamp(0.8 - (0.8 * loudness), 0, 1) 
    else
        Scale3D.Scale = 1; Lyr3DCurrent.TextStrokeColor3 = Color3.new(0,0,0); Lyr3DCurrent.TextStrokeTransparency = 0.5
    end
end)

-- // LOOP PEMINDAI AUDIO UTAMA //
task.spawn(function()
    while task.wait(1.0) do
        local playingSound = FindPlayingSong()
        if playingSound then
            local rawId = playingSound.SoundId
            if rawId ~= currentSongId then
                currentSongId, activeSound = rawId, playingSound
                originalVolume = activeSound.Volume
                lyricOffset, lyricSpeed, manualSpeedOverride = 0.0, 1.0, false
                
                SyncLabel.Text = "Offset: 0.0s"
                SpeedLabelBtn.Text = "Speed: 1.0x"; SpeedLabelBtn.TextColor3 = Color3.fromRGB(200, 150, 255)
                
                TitleLabel.Text, ArtistLabel.Text = "Mengkalibrasi Frekuensi...", "Membaca Data..."
                LyricPrev.Text, LyricCurrent.Text, LyricNext.Text = "", "Mencari lirik...", ""
                Lyr3DPrev.Text, Lyr3DCurrent.Text, Lyr3DNext.Text = "", "Mencari lirik...", ""
                activeLyrics = {}; currentLyricMatches = {}; ShowWidget()
                
                for _, b in ipairs(LyricSelectionBtns) do b.Visible = false end
                
                local scanId = currentSongId 
                
                task.spawn(function()
                    task.wait(2.5) 
                    if currentSongId ~= scanId then return end
                    
                    local guiTitle, guiArtist = "", ""
                    pcall(function()
                        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
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

                    local displayTitle = "Audio Tracker"
                    local displayArtist = "ID: " .. (string.match(rawId, "%d+") or "Custom")
                    local rawName = activeSound.Name ~= "Sound" and activeSound.Name or "Unknown Audio"
                    local assetIdNum = tonumber(string.match(rawId, "%d+"))
                    if assetIdNum then
                        local success, info = pcall(function() return MarketplaceService:GetProductInfo(assetIdNum, Enum.InfoType.Asset) end)
                        if success and info and info.Name then rawName = info.Name end
                    end
                    
                    if guiTitle ~= "" then
                        displayTitle = guiTitle
                        if guiArtist ~= "" then displayArtist = guiArtist end
                    else displayTitle = CleanSongName(rawName) end
                    
                    TitleLabel.Text, ArtistLabel.Text = displayTitle, displayArtist
                    pcall(function() StarterGui:SetCore("SendNotification", { Title = "Memutar", Text = displayTitle, Duration = 4 }) end)
                    
                    local searchAttempts = { (guiTitle ~= "" and guiArtist ~= "") and (guiTitle .. " " .. guiArtist) or "", guiTitle, CleanSongName(rawName), GetAggressiveName(rawName) }
                    local matches = {}
                    
                    for _, query in ipairs(searchAttempts) do
                        if query and query ~= "" then 
                            local suc, res = pcall(function() return FetchMultipleLyrics(query, false) end)
                            if suc and res and #res > 0 then matches = res; break end 
                        end
                    end
                    
                    if currentSongId ~= scanId then return end 
                    
                    currentLyricMatches = matches
                    
                    if #matches == 0 then
                        LyricCurrent.Text, Lyr3DCurrent.Text = "Lirik tidak tersedia.", "Lirik tidak tersedia."
                    else
                        for i = 1, 3 do
                            if matches[i] then
                                LyricSelectionBtns[i].Text = matches[i].TrackName .. " - " .. matches[i].ArtistName
                                LyricSelectionBtns[i].Visible = true
                            end
                        end
                        SetActiveLyricData(matches[1])
                    end
                end)
            end
        else
            if currentSongId ~= nil then currentSongId, activeSound = nil, nil; HideWidget() end
        end
    end
end)

print("Hawk909 Titan-Class (Arceus X Neo & Android): ALL SYSTEMS OPERATIONAL.")
