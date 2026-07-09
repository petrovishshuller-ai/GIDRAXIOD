-- ============================================================
-- GIDRAXIOD - АИМБОТ НЕ ВИДИТ ЧЕРЕЗ СТЕНЫ
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ====== СОСТОЯНИЯ ======
local aimEnabled = false
local triggerEnabled = false
local espEnabled = false
local nightVisionEnabled = false
local noclipEnabled = false
local fovRadius = 120
local smoothness = 0.85
local aimTarget = nil
local maxFOV = 500
local aimPart = "Head"
local lastTriggerTime = 0

-- ====== ESP ======
local espObjects = {}
local trackedCharacters = {}
local updateInterval = 0.3
local espLoop = nil
local updateTimer = 0
local rescanTimer = 0
local RESCAN_INTERVAL = 2.5
local playerConnections = {}

-- ====== NIGHTVISION ======
local nvConn = nil
local savedBrightness = Lighting.Brightness
local savedAmbient = Lighting.Ambient
local savedOutdoorAmbient = Lighting.OutdoorAmbient
local savedClockTime = Lighting.ClockTime
local savedFogStart = Lighting.FogStart
local savedFogEnd = Lighting.FogEnd
local savedGlobalShadows = Lighting.GlobalShadows

-- ====== ТЕМЫ ======
local themes = {
    {name = "Purple", color = Color3.fromRGB(180, 80, 255), glow = Color3.fromRGB(220, 150, 255), dim = Color3.fromRGB(130, 40, 200)},
    {name = "White Neon", color = Color3.fromRGB(255, 255, 255), glow = Color3.fromRGB(255, 255, 255), dim = Color3.fromRGB(180, 180, 180)},
    {name = "Gray Neon", color = Color3.fromRGB(180, 180, 180), glow = Color3.fromRGB(220, 220, 220), dim = Color3.fromRGB(120, 120, 120)},
    {name = "Red Neon", color = Color3.fromRGB(255, 50, 50), glow = Color3.fromRGB(255, 100, 100), dim = Color3.fromRGB(180, 20, 20)},
    {name = "Cyan Neon", color = Color3.fromRGB(0, 255, 255), glow = Color3.fromRGB(100, 255, 255), dim = Color3.fromRGB(0, 180, 180)},
    {name = "Pink Neon", color = Color3.fromRGB(255, 100, 200), glow = Color3.fromRGB(255, 150, 220), dim = Color3.fromRGB(200, 50, 150)},
    {name = "Yellow Neon", color = Color3.fromRGB(255, 255, 0), glow = Color3.fromRGB(255, 255, 100), dim = Color3.fromRGB(180, 180, 0)},
    {name = "Orange Neon", color = Color3.fromRGB(255, 150, 0), glow = Color3.fromRGB(255, 180, 80), dim = Color3.fromRGB(200, 100, 0)},
    {name = "Rainbow", color = Color3.fromRGB(255, 0, 0), glow = Color3.fromRGB(255, 0, 255), dim = Color3.fromRGB(0, 255, 255)},
}

local currentThemeIndex = 1
local rainbowHue = 0
local currentColor, currentGlow, currentDim = themes[1].color, themes[1].glow, themes[1].dim
local themeChanged = true
local rainbowTimer = 0

local function getThemeColors()
    local theme = themes[currentThemeIndex]
    if theme.name == "Rainbow" then
        rainbowHue = (rainbowHue + 0.005) % 1
        currentColor = Color3.fromHSV(rainbowHue, 1, 1)
        currentGlow = Color3.fromHSV(rainbowHue, 0.8, 0.9)
        currentDim = Color3.fromHSV(rainbowHue, 0.8, 0.5)
        themeChanged = true
    else
        currentColor = theme.color
        currentGlow = theme.glow
        currentDim = theme.dim
        themeChanged = true
    end
    return currentColor, currentGlow, currentDim
end

-- ====== GUI ======
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GIDRAX_Menu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.Parent = CoreGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0.5, -25)
toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
toggleButton.Text = "G"
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.BorderSizePixel = 2
toggleButton.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 780)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -390)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.08
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2
mainStroke.Color = Color3.fromRGB(180, 80, 255)
mainStroke.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
title.TextColor3 = Color3.fromRGB(180, 80, 255)
title.Text = "✦ GIDRAXIOD ✦"
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = mainFrame

local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 1
titleStroke.Color = Color3.fromRGB(180, 80, 255)
titleStroke.Parent = title

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -100)
scroll.Position = UDim2.new(0, 10, 0, 55)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(180, 80, 255)
scroll.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

layout.Changed:Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 30)
end)

local uiElements = {
    buttons = {},
    sliders = {},
    labels = {},
}

local function updateUITheme()
    if not themeChanged then return end
    themeChanged = false
    
    toggleButton.TextColor3 = currentColor
    toggleButton.BorderColor3 = currentColor
    mainStroke.Color = currentColor
    title.TextColor3 = currentColor
    titleStroke.Color = currentColor
    scroll.ScrollBarImageColor3 = currentColor
    
    if crosshair then
        crosshair.TextColor3 = currentColor
        crosshair.TextStrokeColor3 = currentColor
    end
    
    if aimCircle then
        local stroke = aimCircle:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = currentColor end
    end
    
    for _, btn in pairs(uiElements.buttons) do
        if btn and btn.Parent then
            btn.BorderColor3 = currentColor
            if btn.Text and btn.Text:find("[ON]") then
                btn.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
            else
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            end
        end
    end
    
    for _, label in pairs(uiElements.labels) do
        if label and label.Parent then
            label.TextColor3 = currentColor
        end
    end
    
    for _, slider in pairs(uiElements.sliders) do
        if slider and slider.Parent then
            local fill = slider:FindFirstChildOfClass("Frame")
            if fill then
                fill.BackgroundColor3 = currentColor
            end
            local btn = slider:FindFirstChildOfClass("TextButton")
            if btn then
                btn.BackgroundColor3 = currentGlow
            end
        end
    end
    
    for char, data in pairs(espObjects) do
        if data.highlight then
            data.highlight.FillColor = currentColor
            data.highlight.OutlineColor = currentGlow
        end
        if data.label then
            data.label.TextColor3 = currentGlow
        end
    end
end

local function createButton(text, getState, setState)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = "◈ " .. text .. " [OFF]"
    btn.TextScaled = true
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 2
    btn.BorderColor3 = currentColor
    btn.Parent = scroll
    table.insert(uiElements.buttons, btn)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local newState = not getState()
        setState(newState)
        btn.Text = "◈ " .. text .. (newState and " [ON]" or " [OFF]")
        btn.BorderColor3 = newState and currentGlow or currentColor
        btn.BackgroundColor3 = newState and Color3.fromRGB(60, 40, 80) or Color3.fromRGB(30, 30, 40)
        updateUITheme()
        if text == "Night Vision" then
            if newState then startNV() else stopNV() end
        end
    end)
    return btn
end

local function createSlider(labelText, getValue, setValue, min, max, format)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 70)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    container.BorderSizePixel = 2
    container.BorderColor3 = currentColor
    container.Parent = scroll
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 2)
    label.BackgroundTransparency = 1
    label.TextColor3 = currentColor
    label.Text = labelText
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = container
    table.insert(uiElements.labels, label)
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 2)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.Text = format(getValue())
    valueLabel.TextScaled = true
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 14
    valueLabel.Parent = container
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -10, 0, 12)
    track.Position = UDim2.new(0, 5, 0, 28)
    track.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    track.BorderSizePixel = 1
    track.BorderColor3 = currentColor
    track.Parent = container
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 6)
    trackCorner.Parent = track
    
    local fillSize = (getValue() - min) / (max - min)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(fillSize, 0, 1, 0)
    fill.BackgroundColor3 = currentColor
    fill.BorderSizePixel = 0
    fill.Parent = track
    table.insert(uiElements.sliders, fill)
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fill
    
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0, 16, 0, 16)
    sliderBtn.Position = UDim2.new(fillSize, -8, 0.5, -8)
    sliderBtn.BackgroundColor3 = currentGlow
    sliderBtn.Text = ""
    sliderBtn.BorderSizePixel = 0
    sliderBtn.Parent = track
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = sliderBtn
    
    local dragging = false
    sliderBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local absPos = track.AbsolutePosition
            local size = track.AbsoluteSize.X
            local mouseX = input.Position.X
            local rel = math.clamp((mouseX - absPos.X) / size, 0, 1)
            local newVal = min + (max - min) * rel
            setValue(newVal)
            fill.BackgroundColor3 = currentColor
            sliderBtn.BackgroundColor3 = currentGlow
            fill.Size = UDim2.new(rel, 0, 1, 0)
            sliderBtn.Position = UDim2.new(rel, -8, 0.5, -8)
            valueLabel.Text = format(newVal)
            
            if labelText == "FOV" then
                if aimCircle then
                    aimCircle.Size = UDim2.fromOffset(fovRadius*2, fovRadius*2)
                end
                if aimInnerCircle then
                    aimInnerCircle.Size = UDim2.fromOffset(fovRadius*2 - 8, fovRadius*2 - 8)
                end
            end
        end
    end)
    
    return container
end

local espBtn = createButton("ESP", function() return espEnabled end, function(v)
    espEnabled = v
    if v then startESP() else stopESP() end
end)

local nvBtn = createButton("Night Vision", function() return nightVisionEnabled end, function(v)
    nightVisionEnabled = v
    if v then startNV() else stopNV() end
end)

local aimBtn = createButton("AimBot", function() return aimEnabled end, function(v)
    aimEnabled = v
    if not v then
        aimTarget = nil
        if aimCircle then aimCircle.Visible = false end
        if aimInnerCircle then aimInnerCircle.Visible = false end
    else
        if aimCircle then aimCircle.Visible = true end
        if aimInnerCircle then aimInnerCircle.Visible = true end
    end
end)

local triggerBtn = createButton("TriggerBot", function() return triggerEnabled end, function(v)
    triggerEnabled = v
    if crosshair then crosshair.Visible = v end
end)

local noclipBtn = createButton("Noclip", function() return noclipEnabled end, function(v)
    noclipEnabled = v
    if v then startNoclip() else stopNoclip() end
end)

local fovSlider = createSlider("FOV", function() return fovRadius end, function(v) fovRadius = math.floor(v) end, 30, 500, function(v) return tostring(math.floor(v)) end)

local aimTargetLabel = Instance.new("TextLabel")
aimTargetLabel.Size = UDim2.new(1, -10, 0, 20)
aimTargetLabel.BackgroundTransparency = 1
aimTargetLabel.TextColor3 = currentColor
aimTargetLabel.Text = "» Target: HEAD «"
aimTargetLabel.TextScaled = true
aimTargetLabel.Font = Enum.Font.Gotham
aimTargetLabel.TextSize = 14
aimTargetLabel.Parent = scroll
table.insert(uiElements.labels, aimTargetLabel)

local aimTargetBtn = Instance.new("TextButton")
aimTargetBtn.Size = UDim2.new(1, -10, 0, 35)
aimTargetBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
aimTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
aimTargetBtn.Text = "◈ Switch to BODY"
aimTargetBtn.TextScaled = true
aimTargetBtn.Font = Enum.Font.Gotham
aimTargetBtn.BorderSizePixel = 2
aimTargetBtn.BorderColor3 = currentColor
aimTargetBtn.Parent = scroll
table.insert(uiElements.buttons, aimTargetBtn)

aimTargetBtn.MouseButton1Click:Connect(function()
    if aimPart == "Head" then
        aimPart = "Torso"
        aimTargetLabel.Text = "» Target: BODY «"
        aimTargetBtn.Text = "◈ Switch to HEAD"
    else
        aimPart = "Head"
        aimTargetLabel.Text = "» Target: HEAD «"
        aimTargetBtn.Text = "◈ Switch to BODY"
    end
end)

local themeContainer = Instance.new("Frame")
themeContainer.Size = UDim2.new(1, -10, 0, 40)
themeContainer.BackgroundTransparency = 1
themeContainer.Parent = scroll

local themeLeft = Instance.new("TextButton")
themeLeft.Size = UDim2.new(0, 40, 0, 35)
themeLeft.Position = UDim2.new(0, 0, 0, 0)
themeLeft.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
themeLeft.TextColor3 = Color3.fromRGB(255, 255, 255)
themeLeft.Text = "◄"
themeLeft.TextScaled = true
themeLeft.Font = Enum.Font.GothamBold
themeLeft.BorderSizePixel = 2
themeLeft.BorderColor3 = currentColor
themeLeft.Parent = themeContainer
table.insert(uiElements.buttons, themeLeft)

local themeLabel = Instance.new("TextLabel")
themeLabel.Size = UDim2.new(0.6, 0, 1, 0)
themeLabel.Position = UDim2.new(0.2, 0, 0, 0)
themeLabel.BackgroundTransparency = 1
themeLabel.TextColor3 = currentColor
themeLabel.Text = "Purple"
themeLabel.TextScaled = true
themeLabel.Font = Enum.Font.GothamBold
themeLabel.TextSize = 14
themeLabel.Parent = themeContainer
table.insert(uiElements.labels, themeLabel)

local themeRight = Instance.new("TextButton")
themeRight.Size = UDim2.new(0, 40, 0, 35)
themeRight.Position = UDim2.new(1, -40, 0, 0)
themeRight.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
themeRight.TextColor3 = Color3.fromRGB(255, 255, 255)
themeRight.Text = "►"
themeRight.TextScaled = true
themeRight.Font = Enum.Font.GothamBold
themeRight.BorderSizePixel = 2
themeRight.BorderColor3 = currentColor
themeRight.Parent = themeContainer
table.insert(uiElements.buttons, themeRight)

local function updateThemeLabel()
    themeLabel.Text = themes[currentThemeIndex].name
    getThemeColors()
    updateUITheme()
end

themeLeft.MouseButton1Click:Connect(function()
    currentThemeIndex = currentThemeIndex - 1
    if currentThemeIndex < 1 then currentThemeIndex = #themes end
    updateThemeLabel()
end)

themeRight.MouseButton1Click:Connect(function()
    currentThemeIndex = currentThemeIndex + 1
    if currentThemeIndex > #themes then currentThemeIndex = 1 end
    updateThemeLabel()
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -10, 0, 35)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "◈ CLOSE ◈"
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.Gotham
closeBtn.BorderSizePixel = 2
closeBtn.BorderColor3 = currentColor
closeBtn.Parent = scroll
table.insert(uiElements.buttons, closeBtn)

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    getThemeColors()
    updateUITheme()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        aimEnabled = not aimEnabled
        aimBtn.Text = "◈ AimBot" .. (aimEnabled and " [ON]" or " [OFF]")
        aimBtn.BorderColor3 = aimEnabled and currentGlow or currentColor
        aimBtn.BackgroundColor3 = aimEnabled and Color3.fromRGB(60, 40, 80) or Color3.fromRGB(30, 30, 40)
        if not aimEnabled then
            aimTarget = nil
            if aimCircle then aimCircle.Visible = false end
            if aimInnerCircle then aimInnerCircle.Visible = false end
        else
            if aimCircle then aimCircle.Visible = true end
            if aimInnerCircle then aimInnerCircle.Visible = true end
        end
    end
end)

local rainbowLoop = RunService.Heartbeat:Connect(function(deltaTime)
    rainbowTimer = rainbowTimer + deltaTime
    if rainbowTimer >= 0.08 then
        rainbowTimer = 0
        local theme = themes[currentThemeIndex]
        if theme and theme.name == "Rainbow" then
            getThemeColors()
            updateUITheme()
        end
    end
end)

local crosshairGui = Instance.new("ScreenGui")
crosshairGui.Name = "CrosshairGUI"
crosshairGui.ResetOnSpawn = false
crosshairGui.IgnoreGuiInset = true
crosshairGui.DisplayOrder = 999998
crosshairGui.Parent = CoreGui

crosshair = Instance.new("TextLabel")
crosshair.Size = UDim2.new(0, 30, 0, 30)
crosshair.Position = UDim2.new(0.5, -15, 0.5, -15)
crosshair.BackgroundTransparency = 1
crosshair.Text = "+"
crosshair.TextColor3 = currentColor
crosshair.TextScaled = true
crosshair.Font = Enum.Font.GothamBold
crosshair.TextStrokeTransparency = 0
crosshair.TextStrokeColor3 = currentColor
crosshair.Visible = false
crosshair.Parent = crosshairGui

local aimGui = Instance.new("ScreenGui")
aimGui.Name = "AimbotGUI"
aimGui.ResetOnSpawn = false
aimGui.IgnoreGuiInset = true
aimGui.DisplayOrder = 999997
aimGui.Parent = CoreGui

aimCircle = Instance.new("Frame")
aimCircle.Size = UDim2.fromOffset(fovRadius*2, fovRadius*2)
aimCircle.AnchorPoint = Vector2.new(0.5,0.5)
aimCircle.Position = UDim2.new(0.5,0,0.5,-10)
aimCircle.BackgroundTransparency = 1
aimCircle.Visible = false
aimCircle.Parent = aimGui
local uc = Instance.new("UICorner")
uc.CornerRadius = UDim.new(1,0)
uc.Parent = aimCircle
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = currentColor
stroke.Parent = aimCircle

aimInnerCircle = Instance.new("Frame")
aimInnerCircle.Size = UDim2.fromOffset(fovRadius*2 - 8, fovRadius*2 - 8)
aimInnerCircle.AnchorPoint = Vector2.new(0.5,0.5)
aimInnerCircle.Position = UDim2.new(0.5,0,0.5,-10)
aimInnerCircle.BackgroundTransparency = 1
aimInnerCircle.BackgroundColor3 = Color3.fromRGB(0,0,0)
aimInnerCircle.Visible = false
aimInnerCircle.Parent = aimGui
local uc2 = Instance.new("UICorner")
uc2.CornerRadius = UDim.new(1,0)
uc2.Parent = aimInnerCircle

-- ====== NOCLIP ======
local noclipLoop = nil
local noclipConnection = nil

function startNoclip()
    if noclipLoop then return end
    local function setNoclip(part)
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    local char = localPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            setNoclip(part)
        end
    end
    noclipConnection = localPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.1)
        for _, part in pairs(newChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    noclipLoop = RunService.Heartbeat:Connect(function()
        if not noclipEnabled then return end
        local char = localPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

function stopNoclip()
    if noclipLoop then
        noclipLoop:Disconnect()
        noclipLoop = nil
    end
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    local char = localPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- ============================================================
-- ====== NIGHTVISION (УБИРАЕТ ТЕМНОТУ ПОЛНОСТЬЮ) =============
-- ============================================================
function startNV()
    if nvConn then return end
    savedBrightness = Lighting.Brightness
    savedAmbient = Lighting.Ambient
    savedOutdoorAmbient = Lighting.OutdoorAmbient
    savedClockTime = Lighting.ClockTime
    savedFogStart = Lighting.FogStart
    savedFogEnd = Lighting.FogEnd
    savedGlobalShadows = Lighting.GlobalShadows
    
    nvConn = RunService.RenderStepped:Connect(function()
        if not nightVisionEnabled then return end
        Lighting.Brightness = 4
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 14
        Lighting.FogStart = 0
        Lighting.FogEnd = 1e9
        Lighting.GlobalShadows = false
    end)
end

function stopNV()
    if nvConn then
        nvConn:Disconnect()
        nvConn = nil
    end
    Lighting.Brightness = savedBrightness
    Lighting.Ambient = savedAmbient
    Lighting.OutdoorAmbient = savedOutdoorAmbient
    Lighting.ClockTime = savedClockTime
    Lighting.FogStart = savedFogStart
    Lighting.FogEnd = savedFogEnd
    Lighting.GlobalShadows = savedGlobalShadows
end

-- ====== ESP ======
local function isVisible(part)
    if not part or not part.Parent then return false end
    local origin = camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local distance = (part.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localPlayer.Character, part}
    raycastParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction * distance, raycastParams)
    if result then
        local hit = result.Instance
        local char = hit
        while char and char ~= Workspace do
            if Players:GetPlayerFromCharacter(char) then return true end
            char = char.Parent
        end
        return false
    end
    return true
end

local function getAllTargets()
    local targets = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            if char and char.Parent then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    table.insert(targets, char)
                end
            end
        end
    end
    return targets
end

local function getTargetPart(character)
    if aimPart == "Head" then
        return character:FindFirstChild("Head")
    else
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
    end
end

local function removeCharacterESP(char)
    local data = espObjects[char]
    if data then
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        espObjects[char] = nil
    end
    trackedCharacters[char] = nil
end

local function addCharacterESP(char)
    if espObjects[char] then return end
    if not char or not char.Parent then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then
        task.wait(0.2)
        root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        if not root then return end
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local healthValue = nil
    local maxHealth = 100
    if humanoid then
        healthValue = humanoid.Health
        maxHealth = humanoid.MaxHealth
    else
        local hp = char:FindFirstChild("Health") or char:FindFirstChild("HP")
        if hp then
            healthValue = hp.Value
            maxHealth = healthValue
        else
            task.wait(0.3)
            humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                healthValue = humanoid.Health
                maxHealth = humanoid.MaxHealth
            else
                hp = char:FindFirstChild("Health") or char:FindFirstChild("HP")
                if hp then
                    healthValue = hp.Value
                    maxHealth = healthValue
                end
            end
        end
    end
    if not healthValue or healthValue <= 0 then return end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = currentColor
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = currentGlow
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 280, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextScaled = false
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = currentGlow
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.RichText = true
    label.Parent = billboard

    espObjects[char] = {
        highlight = highlight,
        billboard = billboard,
        label = label,
        lastUpdate = 0
    }
    trackedCharacters[char] = true

    local function onDeath()
        removeCharacterESP(char)
    end
    if humanoid then
        humanoid.Died:Connect(onDeath)
    end
    char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeCharacterESP(char)
        end
    end)
end

local function fullRescan()
    if not espEnabled then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            if char and char.Parent then
                if not espObjects[char] then
                    addCharacterESP(char)
                end
            end
        end
    end
    for char, data in pairs(espObjects) do
        if not char.Parent or not char:IsDescendantOf(Workspace) then
            removeCharacterESP(char)
        end
    end
end

local function updateESPInfo()
    if not espEnabled then return end
    if not camera then camera = Workspace.CurrentCamera end
    if not camera then return end

    local camPos = camera.CFrame.Position
    local currentTime = tick()
    for char, data in pairs(espObjects) do
        if currentTime - data.lastUpdate >= updateInterval then
            data.lastUpdate = currentTime
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            if not root then
                removeCharacterESP(char)
                continue
            end
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local health = 0
            local maxHealth = 100
            if humanoid then
                health = humanoid.Health
                maxHealth = humanoid.MaxHealth
            else
                local hp = char:FindFirstChild("Health") or char:FindFirstChild("HP")
                if hp then
                    health = hp.Value
                    maxHealth = health
                end
            end
            if health <= 0 then
                removeCharacterESP(char)
                continue
            end
            local dist = (root.Position - camPos).Magnitude
            local hpPercent = (health / maxHealth) * 100
            
            local hpColor
            if hpPercent > 60 then hpColor = Color3.fromRGB(0, 255, 0)
            elseif hpPercent > 30 then hpColor = Color3.fromRGB(255, 255, 0)
            else hpColor = Color3.fromRGB(255, 0, 0) end
            
            local name = "NPC"
            local player = Players:GetPlayerFromCharacter(char)
            if player then name = player.Name end
            
            data.label.Text = string.format("%s\n<font color='rgb(%d,%d,%d)'>%.0f/%.0f HP</font>\n<font color='rgb(%d,%d,%d)'>%.1f m</font>",
                name,
                hpColor.R*255, hpColor.G*255, hpColor.B*255, health, maxHealth,
                currentGlow.R*255, currentGlow.G*255, currentGlow.B*255, dist/10)

            if data.highlight then
                data.highlight.FillColor = currentColor
                data.highlight.OutlineColor = currentGlow
            end
        end
    end
end

function startESP()
    if espLoop then return end
    fullRescan()
    Players.PlayerAdded:Connect(function(player)
        if player ~= localPlayer then
            task.wait(0.5)
            fullRescan()
        end
    end)
    Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            removeCharacterESP(player.Character)
        end
    end)
    Workspace.DescendantAdded:Connect(function(descendant)
        if not espEnabled then return end
        if descendant:IsA("Model") and descendant ~= localPlayer.Character then
            local isPlayerModel = false
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character == descendant then
                    isPlayerModel = true
                    break
                end
            end
            if isPlayerModel then return end
            local humanoid = descendant:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if not espObjects[descendant] then
                    addCharacterESP(descendant)
                end
                return
            end
            local hp = descendant:FindFirstChild("Health") or descendant:FindFirstChild("HP")
            if hp and hp.Value > 0 then
                if not espObjects[descendant] then
                    addCharacterESP(descendant)
                end
            end
        end
    end)
    Workspace.DescendantRemoving:Connect(function(descendant)
        if descendant:IsA("Model") and espObjects[descendant] then
            removeCharacterESP(descendant)
        end
    end)
    espLoop = RunService.Heartbeat:Connect(function(deltaTime)
        if not espEnabled then return end
        updateTimer = updateTimer + deltaTime
        if updateTimer >= updateInterval then
            updateTimer = 0
            updateESPInfo()
        end
        rescanTimer = rescanTimer + deltaTime
        if rescanTimer >= RESCAN_INTERVAL then
            rescanTimer = 0
            fullRescan()
        end
    end)
end

function stopESP()
    if espLoop then
        espLoop:Disconnect()
        espLoop = nil
    end
    for char, data in pairs(espObjects) do
        removeCharacterESP(char)
    end
    trackedCharacters = {}
end

-- ====== TRIGGERBOT ======
local function getTargetAtCrosshair()
    local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    local closest, dist = nil, math.huge
    for char, _ in pairs(trackedCharacters) do
        if not char.Parent then
            removeCharacterESP(char)
            continue
        end
        if Players:GetPlayerFromCharacter(char) == localPlayer then
            continue
        end
        local targetPart = getTargetPart(char)
        if targetPart and isVisible(targetPart) then
            local pos, vis = camera:WorldToViewportPoint(targetPart.Position)
            if vis then
                local mag = (Vector2.new(pos.X,pos.Y) - center).Magnitude
                if mag <= 30 and mag < dist then
                    closest = targetPart
                    dist = mag
                end
            end
        end
    end
    return closest
end

local triggerLoop = nil
function startTriggerLoop()
    if triggerLoop then return end
    triggerLoop = RunService.RenderStepped:Connect(function()
        if triggerEnabled then
            local target = getTargetAtCrosshair()
            local currentTime = tick()
            if target and currentTime - lastTriggerTime >= 0.1 then
                mouse1click()
                lastTriggerTime = currentTime
            end
        end
    end)
end
startTriggerLoop()

-- ============================================================
-- ====== АИМБОТ (НЕ ВИДИТ ЧЕРЕЗ СТЕНЫ + СБРОС ЦЕЛИ) =========
-- ============================================================
local function isTargetVisible(targetPart)
    if not targetPart then return false end
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local distance = (targetPart.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction * distance, raycastParams)
    if result then
        local hit = result.Instance
        local targetChar = targetPart.Parent
        while targetChar and targetChar ~= Workspace do
            if hit:IsDescendantOf(targetChar) then
                return true
            end
            targetChar = targetChar.Parent
        end
        return false
    end
    return true
end

local function getClosestTarget(center)
    local closest, dist = nil, math.huge
    for char, _ in pairs(trackedCharacters) do
        if not char.Parent then
            removeCharacterESP(char)
            continue
        end
        if Players:GetPlayerFromCharacter(char) == localPlayer then
            continue
        end
        local targetPart = getTargetPart(char)
        if targetPart and targetPart:IsA("BasePart") then
            if not isTargetVisible(targetPart) then
                continue
            end
            local pos, vis = camera:WorldToViewportPoint(targetPart.Position)
            if vis then
                local mag = (Vector2.new(pos.X,pos.Y) - center).Magnitude
                if mag <= fovRadius and mag < dist then
                    closest = targetPart
                    dist = mag
                end
            end
        end
    end
    return closest
end

local aimLoop = nil
function startAimLoop()
    if aimLoop then return end
    aimLoop = RunService.RenderStepped:Connect(function()
        if aimEnabled then
            local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
            
            local targetIsValid = false
            if aimTarget and aimTarget.Parent then
                if isTargetVisible(aimTarget) then
                    local pos, vis = camera:WorldToViewportPoint(aimTarget.Position)
                    if vis and (Vector2.new(pos.X,pos.Y) - center).Magnitude <= fovRadius then
                        targetIsValid = true
                    end
                end
            end
            
            if not targetIsValid then
                aimTarget = nil
            end
            
            if not aimTarget then
                aimTarget = getClosestTarget(center)
            end
            
            if aimTarget then
                local goal = CFrame.new(camera.CFrame.Position, aimTarget.Position)
                camera.CFrame = camera.CFrame:Lerp(goal, smoothness)
            end
        else
            aimTarget = nil
        end
    end)
end

if aimLoop then aimLoop:Disconnect() end
startAimLoop()

-- ====== ОЧИСТКА ======
local function cleanAll()
    stopESP()
    stopNV()
    stopNoclip()
    if aimLoop then aimLoop:Disconnect(); aimLoop = nil end
    if triggerLoop then triggerLoop:Disconnect(); triggerLoop = nil end
    if rainbowLoop then rainbowLoop:Disconnect(); rainbowLoop = nil end
    if aimCircle then aimCircle:Destroy() end
    if aimInnerCircle then aimInnerCircle:Destroy() end
end

localPlayer.AncestryChanged:Connect(function()
    if not localPlayer.Parent then
        cleanAll()
    end
end)

updateThemeLabel()

print("✅ GIDRAXIOD загружен. Нажмите G для меню.")
print("✅ Аимбот НЕ ВИДИТ через стены и СБРАСЫВАЕТ цель при уходе за стену!")
print("✅ Night Vision полностью убирает темноту.")
print("❌ Invisibility удалён из меню.")
