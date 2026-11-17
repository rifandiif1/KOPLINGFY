-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - BOOTSTRAPPER & SPLASH LOADER (init.luau)
-- =================================================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

local function getSafeParent()
    local okGethui, hui = pcall(function() return gethui and gethui() end)
    if okGethui and hui then return hui end
    local okCore, core = pcall(function() return game:GetService("CoreGui") end)
    if okCore and core then return core end
    return player:WaitForChild("PlayerGui")
end

local splashGui = Instance.new("ScreenGui")
splashGui.Name = "KoplingtifySplash"
splashGui.ResetOnSpawn = false
splashGui.DisplayOrder = 10000
splashGui.Parent = getSafeParent()

local box = Instance.new("Frame")
box.Size = UDim2.new(0, 260, 0, 74)
box.Position = UDim2.new(0.5, -130, 0.45, -37)
box.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
box.BorderSizePixel = 0
box.Parent = splashGui
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", box)
stroke.Color = Color3.fromRGB(40, 235, 140)
stroke.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 24)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(40, 235, 140)
title.Text = "🎵 KOPLINGTIFY LITE v2.5"
title.Parent = box

local stepLbl = Instance.new("TextLabel")
stepLbl.Size = UDim2.new(1, -20, 0, 18)
stepLbl.Position = UDim2.new(0, 10, 0, 31)
stepLbl.BackgroundTransparency = 1
stepLbl.Font = Enum.Font.Gotham
stepLbl.TextSize = 10
stepLbl.TextColor3 = Color3.fromRGB(190, 200, 215)
stepLbl.Text = "Memuat modul..."
stepLbl.Parent = box

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -24, 0, 6)
barBg.Position = UDim2.new(0, 12, 0, 56)
barBg.BackgroundColor3 = Color3.fromRGB(34, 40, 50)
barBg.BorderSizePixel = 0
barBg.Parent = box
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(40, 235, 140)
barFill.BorderSizePixel = 0
barFill.Parent = barBg
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

local REPO_BASE = "https://raw.githubusercontent.com/rifandiif1/KOPLINGFY/main/"
_G.KoplingtifyModules = {}

local steps = {
    {Key = "UI",     File = "KOPLINGTIFY_UI.luau",     Label = "Memuat Modul UI (1/4)..."},
    {Key = "Filter", File = "KOPLINGTIFY_FILTER.luau", Label = "Memuat Kamus Filter Kata (2/4)..."},
    {Key = "World",  File = "KOPLINGTIFY_WORLD.luau",  Label = "Memuat Modul Kamera & ESP (3/4)..."},
    {Key = "Sync",   File = "KOPLINGTIFY_SYNC1.luau",   Label = "Menjalankan Mesin Sinkronisasi (4/4)..."}
}

for idx, item in ipairs(steps) do
    stepLbl.Text = item.Label
    TweenService:Create(barFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(idx / #steps, 0, 1, 0)
    }):Play()

    local ok, mod = pcall(function()
        return loadstring(game:HttpGet(REPO_BASE .. item.File))()
    end)
    if ok and mod then
        _G.KoplingtifyModules[item.Key] = mod
    end
end

task.wait(0.2)
splashGui:Destroy()
