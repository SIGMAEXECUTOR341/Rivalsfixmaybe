local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ══════════════════════════════════════════
--  SETTINGS & STATES
-- ══════════════════════════════════════════
local ESP_SETTINGS = {
    Enabled         = true,
    ShowBox         = true,
    ShowName        = true,
    ShowSkeletons   = true,
    TeamCheck       = false,
}

local AIM_SETTINGS = {
    Enabled = false,
    TargetPart = "Head",
    Smoothness = 0.5, 
    FOV = 110,
    AimKey = Enum.UserInputType.MouseButton2,
    IsBinding = false
}

local HVH_SETTINGS = {
    OrbitEnabled = false,
    OrbitTarget = nil,
    OrbitSpeed = 10,
    OrbitDistance = 5
}

local bones = {
    {"Head","UpperTorso"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","LowerTorso"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}
}

-- ══════════════════════════════════════════
--  ACCENT COLOR SYSTEM
-- ══════════════════════════════════════════
local accentColor = Color3.fromRGB(0, 255, 0)
local accentListeners = {} -- functions called when accent changes

local function setAccent(col)
    accentColor = col
    for _, fn in pairs(accentListeners) do
        pcall(fn, col)
    end
end

local function onAccent(fn)
    table.insert(accentListeners, fn)
end

local function hexToColor3(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

local function color3ToHex(col)
    return string.format("%02X%02X%02X",
        math.floor(col.R * 255),
        math.floor(col.G * 255),
        math.floor(col.B * 255)
    )
end

-- ══════════════════════════════════════════
--  CORE FUNCTIONS
-- ══════════════════════════════════════════
local cache = {}
local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function getPlayerColor(plr)
    return (plr.Team and plr.Team.TeamColor.Color) or Color3.fromRGB(0, 255, 0)
end

local function createPlayerEsp(plr)
    local e = {}
    e.box = newDrawing("Square", {Thickness=1, Filled=false, Visible=false, Color=Color3.new(1,1,1)})
    e.name = newDrawing("Text", {Outline=true, Center=true, Size=13, Visible=false, Color=Color3.new(1,1,1)})
    e.skeleton = {}
    cache[plr] = e
end

local function getClosestPlayer()
    local target = nil
    local dist = AIM_SETTINGS.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild(AIM_SETTINGS.TargetPart) then
            if ESP_SETTINGS.TeamCheck and p.Team == player.Team then continue end
            local pos, onScreen = camera:WorldToViewportPoint(p.Character[AIM_SETTINGS.TargetPart].Position)
            if onScreen then
                local magnitude = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if magnitude < dist then
                    dist = magnitude
                    target = p
                end
            end
        end
    end
    return target
end

-- ══════════════════════════════════════════
--  GUI CONSTRUCTION
-- ══════════════════════════════════════════
if CoreGui:FindFirstChild("KikiaHookV3") then CoreGui.KikiaHookV3:Destroy() end
local screenGui = Instance.new("ScreenGui", CoreGui); screenGui.Name = "KikiaHookV3"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 520, 0, 420); mainFrame.Position = UDim2.new(0.5, -260, 0.5, -210); mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12); mainFrame.BorderSizePixel = 0
local mainCorner = Instance.new("UICorner", mainFrame); mainCorner.CornerRadius = UDim.new(0, 8)
local uiStroke = Instance.new("UIStroke", mainFrame); uiStroke.Color = accentColor; uiStroke.Thickness = 1.5
onAccent(function(c) uiStroke.Color = c end)

-- SNOW EFFECT
local snowCanvas = Instance.new("Frame", mainFrame); snowCanvas.Size = UDim2.new(1,0,1,0); snowCanvas.BackgroundTransparency = 1; snowCanvas.ClipsDescendants = true; snowCanvas.ZIndex = 0
local flakes = {}
for i = 1, 50 do
    local f = Instance.new("Frame", snowCanvas)
    f.Size = UDim2.new(0, 2, 0, 2); f.BackgroundColor3 = Color3.new(1,1,1); f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
    table.insert(flakes, {e = f, x = math.random(), y = math.random(), s = math.random(5, 15)/1000})
end

local sidebar = Instance.new("Frame", mainFrame); sidebar.Size = UDim2.new(0, 120, 1, 0); sidebar.BackgroundColor3 = Color3.fromRGB(8, 8, 8); sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)

local container = Instance.new("Frame", mainFrame); container.Size = UDim2.new(1, -140, 1, -20); container.Position = UDim2.new(0, 130, 0, 10); container.BackgroundTransparency = 1

local vFrame = Instance.new("ScrollingFrame", container); vFrame.Size = UDim2.new(1,0,1,0); vFrame.BackgroundTransparency = 1; vFrame.Visible = true; vFrame.ScrollBarThickness = 0
local aFrame = Instance.new("ScrollingFrame", container); aFrame.Size = UDim2.new(1,0,1,0); aFrame.BackgroundTransparency = 1; aFrame.Visible = false; aFrame.ScrollBarThickness = 0
local hFrame = Instance.new("ScrollingFrame", container); hFrame.Size = UDim2.new(1,0,1,0); hFrame.BackgroundTransparency = 1; hFrame.Visible = false; hFrame.ScrollBarThickness = 0
local sFrame = Instance.new("ScrollingFrame", container); sFrame.Size = UDim2.new(1,0,1,0); sFrame.BackgroundTransparency = 1; sFrame.Visible = false; sFrame.ScrollBarThickness = 0

local layouts = {vFrame, aFrame, hFrame, sFrame}
for _, frame in pairs(layouts) do
    local l = Instance.new("UIListLayout", frame); l.Padding = UDim.new(0, 10)
end

-- TAB SYSTEM
local allTabButtons = {}
local function makeTab(txt, y, target, isBottom)
    local b = Instance.new("TextButton", sidebar); b.Size = UDim2.new(1, 0, 0, 40)
    if isBottom then b.Position = UDim2.new(0, 0, 1, -40) else b.Position = UDim2.new(0, 0, 0, y) end
    b.BackgroundColor3 = Color3.fromRGB(8, 8, 8); b.Text = txt; b.TextColor3 = Color3.fromRGB(150, 150, 150); b.Font = Enum.Font.Code; b.BorderSizePixel = 0; b.TextSize = 14
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    table.insert(allTabButtons, b)
    b.MouseButton1Click:Connect(function() 
        for _, f in pairs(layouts) do f.Visible = false end
        target.Visible = true 
        for _, btn in pairs(allTabButtons) do btn.TextColor3 = Color3.fromRGB(150, 150, 150) end
        b.TextColor3 = accentColor
    end)
    onAccent(function(c)
        if target.Visible then b.TextColor3 = c end
    end)
end

makeTab("Visuals", 10, vFrame); makeTab("Aimbot", 55, aFrame); makeTab("HvH", 100, hFrame); makeTab("Settings", 0, sFrame, true)

-- UI COMPONENTS
local function createToggle(txt, parent, default, cb)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 30); f.BackgroundTransparency = 1
    local b = Instance.new("TextButton", f); b.Size = UDim2.new(0, 18, 0, 18); b.Position = UDim2.new(0, 5, 0.5, -9); b.BackgroundColor3 = default and accentColor or Color3.fromRGB(30, 30, 30); b.Text = ""; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, -35, 1, 0); t.Position = UDim2.new(0, 30, 0, 0); t.Text = txt; t.TextColor3 = Color3.fromRGB(200, 200, 200); t.Font = Enum.Font.Code; t.TextSize = 14; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
    local on = default
    b.MouseButton1Click:Connect(function() on = not on; b.BackgroundColor3 = on and accentColor or Color3.fromRGB(30, 30, 30); cb(on) end)
    onAccent(function(c) if on then b.BackgroundColor3 = c end end)
end

local function createSlider(txt, min, max, start, parent, cb)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 45); f.BackgroundTransparency = 1
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, 0, 0, 20); t.Text = txt .. ": " .. start; t.TextColor3 = Color3.fromRGB(200, 200, 200); t.Font = Enum.Font.Code; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
    local b = Instance.new("Frame", f); b.Size = UDim2.new(1, 0, 0, 6); b.Position = UDim2.new(0, 0, 0, 28); b.BackgroundColor3 = Color3.fromRGB(30, 30, 30); b.BorderSizePixel = 0
    Instance.new("UICorner", b)
    local fi = Instance.new("Frame", b); fi.Size = UDim2.new((start-min)/(max-min), 0, 1, 0); fi.BackgroundColor3 = accentColor; fi.BorderSizePixel = 0
    Instance.new("UICorner", fi)
    onAccent(function(c) fi.BackgroundColor3 = c end)
    local dragging = false
    local function update()
        local rel = math.clamp((UserInputService:GetMouseLocation().X - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        fi.Size = UDim2.new(rel, 0, 1, 0); t.Text = txt .. ": " .. val; cb(val)
    end
    b.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update() end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    RunService.RenderStepped:Connect(function() if dragging then update() end end)
end

local function createKeybind(parent)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 35); f.BackgroundTransparency = 1
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(0.5, 0, 1, 0); t.Text = "Aim Key:"; t.TextColor3 = Color3.fromRGB(200, 200, 200); t.Font = Enum.Font.Code; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left; t.Position = UDim2.new(0, 5, 0, 0)
    local b = Instance.new("TextButton", f); b.Size = UDim2.new(0.4, 0, 0, 25); b.Position = UDim2.new(0.5, 5, 0.5, -12); b.BackgroundColor3 = Color3.fromRGB(20, 20, 20); b.Text = "MB2"; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.Code; b.BorderSizePixel = 0
    Instance.new("UICorner", b)
    
    b.MouseButton1Click:Connect(function()
        b.Text = "..."
        AIM_SETTINGS.IsBinding = true
        local connection; connection = UserInputService.InputBegan:Connect(function(i)
            local key = i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode or i.UserInputType
            if key ~= Enum.KeyCode.RightShift then
                AIM_SETTINGS.AimKey = key
                b.Text = key.Name
                AIM_SETTINGS.IsBinding = false
                connection:Disconnect()
            end
        end)
    end)
end

local function createDropdown(parent, text, callback)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(0.95, 0, 0, 30); frame.BackgroundTransparency = 1; frame.ZIndex = 5
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.Text = text .. ": None"; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.Code; btn.BorderSizePixel = 0; btn.ZIndex = 6
    Instance.new("UICorner", btn)
    
    local list = Instance.new("ScrollingFrame", parent); list.Size = UDim2.new(0.95, 0, 0, 100); list.BackgroundColor3 = Color3.fromRGB(15, 15, 15); list.Visible = false; list.ZIndex = 10; list.BorderSizePixel = 0; list.ScrollBarThickness = 2
    local layout = Instance.new("UIListLayout", list); layout.Padding = UDim.new(0, 2)
    Instance.new("UICorner", list)
    
    btn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        if list.Visible then
            for _, v in pairs(list:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player then
                    local pBtn = Instance.new("TextButton", list); pBtn.Size = UDim2.new(1, 0, 0, 25); pBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); pBtn.Text = p.Name; pBtn.TextColor3 = Color3.new(1,1,1); pBtn.Font = Enum.Font.Code; pBtn.ZIndex = 11; pBtn.BorderSizePixel = 0
                    Instance.new("UICorner", pBtn)
                    pBtn.MouseButton1Click:Connect(function() 
                        btn.Text = text .. ": " .. p.Name; 
                        list.Visible = false; 
                        callback(p) 
                    end)
                end
            end
        end
    end)
end

-- ══════════════════════════════════════════
--  POPULATE TABS
-- ══════════════════════════════════════════
createToggle("Box ESP", vFrame, ESP_SETTINGS.ShowBox, function(v) ESP_SETTINGS.ShowBox = v end)
createToggle("Name ESP", vFrame, ESP_SETTINGS.ShowName, function(v) ESP_SETTINGS.ShowName = v end)
createToggle("Skeleton ESP", vFrame, ESP_SETTINGS.ShowSkeletons, function(v) ESP_SETTINGS.ShowSkeletons = v end)
createToggle("Team Check", vFrame, ESP_SETTINGS.TeamCheck, function(v) ESP_SETTINGS.TeamCheck = v end)

createToggle("Aimbot Master", aFrame, false, function(v) AIM_SETTINGS.Enabled = v end)
createKeybind(aFrame)
createSlider("Smoothness (%)", 0, 100, 50, aFrame, function(v) 
    if v >= 100 then AIM_SETTINGS.Smoothness = 0 else
        AIM_SETTINGS.Smoothness = math.pow(1 - (v / 100), 2.5)
    end
end)
createSlider("FOV Radius", 10, 600, 110, aFrame, function(v) AIM_SETTINGS.FOV = v end)

createToggle("Orbit Mode", hFrame, false, function(v) HVH_SETTINGS.OrbitEnabled = v end)
createDropdown(hFrame, "Target", function(p) HVH_SETTINGS.OrbitTarget = p end)
createSlider("Orbit Distance", 2, 50, 5, hFrame, function(v) HVH_SETTINGS.OrbitDistance = v v = math.floor(v) end)
createSlider("Orbit Speed", 1, 50, 10, hFrame, function(v) HVH_SETTINGS.OrbitSpeed = v v = math.floor(v) end)

-- ══════════════════════════════════════════
--  MAIN RENDER LOOP
-- ══════════════════════════════════════════
local fovCircle = Drawing.new("Circle"); fovCircle.Thickness = 1; fovCircle.Visible = true
local angle = 0

RunService.RenderStepped:Connect(function(deltaTime)
    -- Snow
    for _, fl in pairs(flakes) do
        fl.y = fl.y + fl.s
        if fl.y > 1 then fl.y = -0.05; fl.x = math.random() end
        fl.e.Position = UDim2.new(fl.x, 0, fl.y, 0)
    end

    fovCircle.Radius = AIM_SETTINGS.FOV
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Color = accentColor
    fovCircle.Visible = AIM_SETTINGS.Enabled

    -- AIMBOT EXECUTION
    if AIM_SETTINGS.Enabled and not AIM_SETTINGS.IsBinding and AIM_SETTINGS.Smoothness > 0 then
        local isPressed = (AIM_SETTINGS.AimKey.EnumType == Enum.UserInputType and UserInputService:IsMouseButtonPressed(AIM_SETTINGS.AimKey)) or UserInputService:IsKeyDown(AIM_SETTINGS.AimKey)
        if isPressed then
            local targetPlr = getClosestPlayer()
            if targetPlr and targetPlr.Character then
                local part = targetPlr.Character:FindFirstChild(AIM_SETTINGS.TargetPart)
                if part then
                    local targetCF = CFrame.new(camera.CFrame.Position, part.Position)
                    camera.CFrame = camera.CFrame:Lerp(targetCF, AIM_SETTINGS.Smoothness)
                end
            end
        end
    end

    -- ESP UPDATE
    for plr, e in pairs(cache) do
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local rootPos, onScreen = camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if onScreen and (not ESP_SETTINGS.TeamCheck or plr.Team ~= player.Team) then
                local color = getPlayerColor(plr)
                if ESP_SETTINGS.ShowBox then
                    local size = Vector2.new(2000/rootPos.Z, 2500/rootPos.Z)
                    e.box.Visible = true; e.box.Size = size; e.box.Position = Vector2.new(rootPos.X - size.X/2, rootPos.Y - size.Y/2); e.box.Color = color
                else e.box.Visible = false end
                if ESP_SETTINGS.ShowName then
                    e.name.Visible = true; e.name.Text = plr.Name; e.name.Position = Vector2.new(rootPos.X, rootPos.Y - (2500/rootPos.Z)/2 - 15); e.name.Color = color
                else e.name.Visible = false end
                if ESP_SETTINGS.ShowSkeletons then
                    if #e.skeleton == 0 then for _,bp in pairs(bones) do table.insert(e.skeleton, {newDrawing("Line",{Thickness=1.5}), bp[1], bp[2]}) end end
                    for _,ld in pairs(e.skeleton) do
                        local p1, p2 = char:FindFirstChild(ld[2]), char:FindFirstChild(ld[3])
                        if p1 and p2 then
                            local s1, o1 = camera:WorldToViewportPoint(p1.Position); local s2, o2 = camera:WorldToViewportPoint(p2.Position)
                            if o1 and o2 then ld[1].From = Vector2.new(s1.X, s1.Y); ld[1].To = Vector2.new(s2.X, s2.Y); ld[1].Color = color; ld[1].Visible = true else ld[1].Visible = false end
                        else ld[1].Visible = false end
                    end
                else for _,l in pairs(e.skeleton) do l[1].Visible = false end end
            else e.box.Visible = false; e.name.Visible = false; for _,l in pairs(e.skeleton) do l[1].Visible = false end end
        else e.box.Visible = false; e.name.Visible = false; for _,l in pairs(e.skeleton) do l[1].Visible = false end end
    end

    -- FIXED ORBIT LOGIC
    if HVH_SETTINGS.OrbitEnabled and HVH_SETTINGS.OrbitTarget and HVH_SETTINGS.OrbitTarget.Character then
        local tChar = HVH_SETTINGS.OrbitTarget.Character
        local tRoot = tChar:FindFirstChild("HumanoidRootPart")
        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        
        if tRoot and myRoot then
            angle = angle + (deltaTime * HVH_SETTINGS.OrbitSpeed)
            
            local x = math.cos(angle) * HVH_SETTINGS.OrbitDistance
            local z = math.sin(angle) * HVH_SETTINGS.OrbitDistance
            
            local targetPos = tRoot.Position + Vector3.new(x, 2, z)
            myRoot.CFrame = CFrame.new(targetPos, tRoot.Position)
        end
    end
end)

-- INIT
for _, p in pairs(Players:GetPlayers()) do if p ~= player then createPlayerEsp(p) end end
Players.PlayerAdded:Connect(createPlayerEsp)

-- DRAG
local d, s, sp; mainFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d=true s=i.Position sp=mainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then 
    local delta = i.Position-s; mainFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+delta.X, sp.Y.Scale, sp.Y.Offset+delta.Y)
end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d=false end end)
UserInputService.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Enum.KeyCode.RightShift then mainFrame.Visible = not mainFrame.Visible end end)

-- ══════════════════════════════════════════
--  MISC TAB
-- ══════════════════════════════════════════
local mFrame = Instance.new("ScrollingFrame", container)
mFrame.Size = UDim2.new(1,0,1,0); mFrame.BackgroundTransparency = 1
mFrame.Visible = false; mFrame.ScrollBarThickness = 0
local mLayout = Instance.new("UIListLayout", mFrame); mLayout.Padding = UDim.new(0, 10)
table.insert(layouts, mFrame)

makeTab("Misc", 145, mFrame)

-- FLY
local flyEnabled = false
local flyConnection
local bodyVelocity, bodyGyro

createToggle("Fly", mFrame, false, function(v)
    flyEnabled = v
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if v then
        bodyVelocity = Instance.new("BodyVelocity", hrp)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)

        bodyGyro = Instance.new("BodyGyro", hrp)
        bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
        bodyGyro.D = 100

        flyConnection = RunService.RenderStepped:Connect(function()
            if not flyEnabled then return end
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            bodyVelocity.Velocity = dir * 50
            bodyGyro.CFrame = camera.CFrame
        end)
    else
        if flyConnection then flyConnection:Disconnect() end
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
    end
end)

-- NOCLIP
local noclipEnabled = false
createToggle("Noclip", mFrame, false, function(v)
    noclipEnabled = v
end)
RunService.Stepped:Connect(function()
    if noclipEnabled and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- SPEED
createSlider("Walk Speed", 16, 200, 16, mFrame, function(v)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end)

-- JUMP POWER
createSlider("Jump Power", 50, 300, 50, mFrame, function(v)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v end
end)

-- INFINITE JUMP
createToggle("Infinite Jump", mFrame, false, function(v)
    if v then
        UserInputService.JumpRequest:Connect(function()
            if player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end
end)

-- ══════════════════════════════════════════
--  SETTINGS TAB (CFG SAVE/LOAD + COLOR + CREDITS)
-- ══════════════════════════════════════════
local function makeButton(txt, parent, cb)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0.95, 0, 0, 32)
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    b.Text = txt; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Code; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(cb)
end

local function getCurrentCfg()
    return HttpService:JSONEncode({
        ESP = ESP_SETTINGS,
        AIM = {
            Enabled = AIM_SETTINGS.Enabled,
            FOV = AIM_SETTINGS.FOV,
            Smoothness = AIM_SETTINGS.Smoothness,
            TargetPart = AIM_SETTINGS.TargetPart
        },
        HVH = {
            OrbitEnabled = HVH_SETTINGS.OrbitEnabled,
            OrbitSpeed = HVH_SETTINGS.OrbitSpeed,
            OrbitDistance = HVH_SETTINGS.OrbitDistance
        },
        AccentColor = color3ToHex(accentColor)
    })
end

-- ══════════════════════════════════════════
--  CFG FILE MANAGER
-- ══════════════════════════════════════════
local CFG_FOLDER = "KikiaHook/cfgs"

-- Ensure folder exists
pcall(function()
    if not isfolder("KikiaHook") then makefolder("KikiaHook") end
    if not isfolder(CFG_FOLDER) then makefolder(CFG_FOLDER) end
end)

local function getCfgList()
    local files = {}
    local ok, result = pcall(listfiles, CFG_FOLDER)
    if ok and result then
        for _, path in ipairs(result) do
            -- strip folder prefix and .json extension for display
            local name = path:match("([^/\\]+)%.json$") or path:match("([^/\\]+)$")
            if name then table.insert(files, name) end
        end
    end
    return files
end

local function saveCfgToFile(name)
    local path = CFG_FOLDER .. "/" .. name .. ".json"
    local ok, err = pcall(writefile, path, getCurrentCfg())
    return ok, err
end

local function loadCfgFromFile(name)
    local path = CFG_FOLDER .. "/" .. name .. ".json"
    local ok, raw = pcall(readfile, path)
    if not ok then return false end
    local dok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not dok or not data then return false end
    if data.ESP then for k,v in pairs(data.ESP) do ESP_SETTINGS[k] = v end end
    if data.AIM then
        AIM_SETTINGS.Enabled = data.AIM.Enabled or false
        AIM_SETTINGS.FOV = data.AIM.FOV or 110
        AIM_SETTINGS.Smoothness = data.AIM.Smoothness or 0.5
    end
    if data.AccentColor then
        local col = hexToColor3(data.AccentColor)
        if col then setAccent(col); if hexBox then hexBox.Text = color3ToHex(col) end end
    end
    return true
end

local function deleteCfgFile(name)
    local path = CFG_FOLDER .. "/" .. name .. ".json"
    pcall(delfile, path)
end

-- ── CFG Section Label ──
local cfgSectionLabel = Instance.new("TextLabel", sFrame)
cfgSectionLabel.Size = UDim2.new(0.95, 0, 0, 20)
cfgSectionLabel.BackgroundTransparency = 1
cfgSectionLabel.Text = "─── CFG Manager ───"
cfgSectionLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
cfgSectionLabel.Font = Enum.Font.Code
cfgSectionLabel.TextSize = 13

-- ── Name input row ──
local cfgNameRow = Instance.new("Frame", sFrame)
cfgNameRow.Size = UDim2.new(0.95, 0, 0, 32)
cfgNameRow.BackgroundTransparency = 1

local cfgNameBox = Instance.new("TextBox", cfgNameRow)
cfgNameBox.Size = UDim2.new(1, 0, 1, 0)
cfgNameBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
cfgNameBox.BorderSizePixel = 0
cfgNameBox.Text = ""
cfgNameBox.TextColor3 = Color3.new(1, 1, 1)
cfgNameBox.Font = Enum.Font.Code
cfgNameBox.TextSize = 13
cfgNameBox.PlaceholderText = "CFG name..."
cfgNameBox.ClearTextOnFocus = false
Instance.new("UICorner", cfgNameBox).CornerRadius = UDim.new(0, 5)
local cfgNameStroke = Instance.new("UIStroke", cfgNameBox)
cfgNameStroke.Color = Color3.fromRGB(40, 40, 40)
cfgNameStroke.Thickness = 1

-- ── Save & Delete button row ──
local cfgBtnRow = Instance.new("Frame", sFrame)
cfgBtnRow.Size = UDim2.new(0.95, 0, 0, 32)
cfgBtnRow.BackgroundTransparency = 1

local statusLabel = Instance.new("TextLabel", sFrame)
statusLabel.Size = UDim2.new(0.95, 0, 0, 18)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = accentColor
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
onAccent(function(c) statusLabel.TextColor3 = c end)

local function flashStatus(msg, isErr)
    statusLabel.Text = msg
    statusLabel.TextColor3 = isErr and Color3.fromRGB(255, 80, 80) or accentColor
    task.delay(3, function() if statusLabel.Text == msg then statusLabel.Text = "" end end)
end

-- ── CFG Dropdown ──
local dropLabel = Instance.new("TextLabel", sFrame)
dropLabel.Size = UDim2.new(0.95, 0, 0, 18)
dropLabel.BackgroundTransparency = 1
dropLabel.Text = "Saved CFGs:"
dropLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
dropLabel.Font = Enum.Font.Code
dropLabel.TextSize = 13
dropLabel.TextXAlignment = Enum.TextXAlignment.Left

local selectedCfg = nil

-- Dropdown button
local cfgDropBtn = Instance.new("TextButton", sFrame)
cfgDropBtn.Size = UDim2.new(0.95, 0, 0, 30)
cfgDropBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
cfgDropBtn.Text = "▾  Select a CFG..."
cfgDropBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
cfgDropBtn.Font = Enum.Font.Code
cfgDropBtn.TextSize = 13
cfgDropBtn.BorderSizePixel = 0
cfgDropBtn.TextXAlignment = Enum.TextXAlignment.Left
cfgDropBtn.TextTruncate = Enum.TextTruncate.AtEnd
local cfgDropPad = Instance.new("UIPadding", cfgDropBtn); cfgDropPad.PaddingLeft = UDim.new(0, 8)
Instance.new("UICorner", cfgDropBtn).CornerRadius = UDim.new(0, 6)

-- Dropdown list (injected into container so it overlays)
local cfgDropList = Instance.new("ScrollingFrame", container)
cfgDropList.Size = UDim2.new(0.95, 0, 0, 0)
cfgDropList.Position = UDim2.new(0, 0, 0, 0)
cfgDropList.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
cfgDropList.BorderSizePixel = 0
cfgDropList.Visible = false
cfgDropList.ZIndex = 20
cfgDropList.ScrollBarThickness = 2
cfgDropList.ClipsDescendants = true
Instance.new("UICorner", cfgDropList).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", cfgDropList).Color = Color3.fromRGB(50, 50, 50)
local cfgDropLayout = Instance.new("UIListLayout", cfgDropList)
cfgDropLayout.Padding = UDim.new(0, 1)

local function refreshDropdown()
    for _, c in ipairs(cfgDropList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local list = getCfgList()
    if #list == 0 then
        local empty = Instance.new("TextLabel", cfgDropList)
        empty.Size = UDim2.new(1, 0, 0, 28)
        empty.BackgroundTransparency = 1
        empty.Text = "  No CFGs saved yet"
        empty.TextColor3 = Color3.fromRGB(100, 100, 100)
        empty.Font = Enum.Font.Code
        empty.TextSize = 12
        empty.ZIndex = 21
        cfgDropList.CanvasSize = UDim2.new(0, 0, 0, 30)
        cfgDropList.Size = UDim2.new(0.95, 0, 0, 32)
    else
        local itemH = 28
        for _, name in ipairs(list) do
            local item = Instance.new("TextButton", cfgDropList)
            item.Size = UDim2.new(1, 0, 0, itemH)
            item.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            item.Text = "  " .. name
            item.TextColor3 = Color3.new(1, 1, 1)
            item.Font = Enum.Font.Code
            item.TextSize = 13
            item.BorderSizePixel = 0
            item.ZIndex = 21
            item.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)
            item.MouseEnter:Connect(function() item.BackgroundColor3 = Color3.fromRGB(35, 35, 35) end)
            item.MouseLeave:Connect(function() item.BackgroundColor3 = Color3.fromRGB(25, 25, 25) end)
            item.MouseButton1Click:Connect(function()
                selectedCfg = name
                cfgDropBtn.Text = "▾  " .. name
                cfgDropBtn.TextColor3 = Color3.new(1, 1, 1)
                cfgNameBox.Text = name
                cfgDropList.Visible = false
                cfgDropList.Size = UDim2.new(0.95, 0, 0, 0)
            end)
        end
        local totalH = math.min(#list * itemH + 4, 120)
        cfgDropList.CanvasSize = UDim2.new(0, 0, 0, #list * itemH)
        cfgDropList.Size = UDim2.new(0.95, 0, 0, totalH)
    end
end

cfgDropBtn.MouseButton1Click:Connect(function()
    if cfgDropList.Visible then
        cfgDropList.Visible = false
        cfgDropList.Size = UDim2.new(0.95, 0, 0, 0)
    else
        refreshDropdown()
        cfgDropList.Visible = true
    end
end)

-- Position dropdown below its button dynamically
cfgDropBtn:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    local relY = cfgDropBtn.AbsolutePosition.Y - container.AbsolutePosition.Y + cfgDropBtn.AbsoluteSize.Y + 2
    cfgDropList.Position = UDim2.new(0, 0, 0, relY)
end)

-- ── Load button ──
local loadCfgBtn = Instance.new("TextButton", cfgBtnRow)
loadCfgBtn.Size = UDim2.new(0.48, 0, 1, 0)
loadCfgBtn.Position = UDim2.new(0, 0, 0, 0)
loadCfgBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
loadCfgBtn.Text = "📂 Load"
loadCfgBtn.TextColor3 = Color3.new(1, 1, 1)
loadCfgBtn.Font = Enum.Font.Code
loadCfgBtn.TextSize = 13
loadCfgBtn.BorderSizePixel = 0
Instance.new("UICorner", loadCfgBtn).CornerRadius = UDim.new(0, 6)

loadCfgBtn.MouseButton1Click:Connect(function()
    local name = selectedCfg or cfgNameBox.Text
    if name == "" then flashStatus("✖ Select or type a CFG name", true) return end
    local ok = loadCfgFromFile(name)
    if ok then
        flashStatus("✔ Loaded: " .. name)
    else
        flashStatus("✖ CFG not found: " .. name, true)
    end
end)

-- ── Save button ──
local saveCfgBtn = Instance.new("TextButton", cfgBtnRow)
saveCfgBtn.Size = UDim2.new(0.48, 0, 1, 0)
saveCfgBtn.Position = UDim2.new(0.52, 0, 0, 0)
saveCfgBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
saveCfgBtn.Text = "💾 Save"
saveCfgBtn.TextColor3 = Color3.new(1, 1, 1)
saveCfgBtn.Font = Enum.Font.Code
saveCfgBtn.TextSize = 13
saveCfgBtn.BorderSizePixel = 0
Instance.new("UICorner", saveCfgBtn).CornerRadius = UDim.new(0, 6)

saveCfgBtn.MouseButton1Click:Connect(function()
    local name = cfgNameBox.Text
    if name == "" then flashStatus("✖ Enter a CFG name first", true) return end
    -- strip illegal characters
    name = name:gsub('[/\\:*?"<>|]', "_")
    local ok, err = saveCfgToFile(name)
    if ok then
        flashStatus("✔ Saved: " .. name)
        selectedCfg = name
        cfgDropBtn.Text = "▾  " .. name
        cfgDropBtn.TextColor3 = Color3.new(1, 1, 1)
    else
        flashStatus("✖ Save failed", true)
    end
end)

-- ── Delete button (full width below) ──
local deleteCfgBtn = Instance.new("TextButton", sFrame)
deleteCfgBtn.Size = UDim2.new(0.95, 0, 0, 28)
deleteCfgBtn.BackgroundColor3 = Color3.fromRGB(35, 15, 15)
deleteCfgBtn.Text = "🗑 Delete Selected CFG"
deleteCfgBtn.TextColor3 = Color3.fromRGB(220, 80, 80)
deleteCfgBtn.Font = Enum.Font.Code
deleteCfgBtn.TextSize = 13
deleteCfgBtn.BorderSizePixel = 0
Instance.new("UICorner", deleteCfgBtn).CornerRadius = UDim.new(0, 6)

deleteCfgBtn.MouseButton1Click:Connect(function()
    local name = selectedCfg
    if not name then flashStatus("✖ No CFG selected", true) return end
    deleteCfgFile(name)
    selectedCfg = nil
    cfgDropBtn.Text = "▾  Select a CFG..."
    cfgDropBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
    cfgNameBox.Text = ""
    flashStatus("🗑 Deleted: " .. name)
    if cfgDropList.Visible then refreshDropdown() end
end)

-- ══════════════════════════════════════════
--  GUI COLOR PICKER
-- ══════════════════════════════════════════
-- Section label
local colorLabel = Instance.new("TextLabel", sFrame)
colorLabel.Size = UDim2.new(0.95, 0, 0, 20)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "─── GUI Color ───"
colorLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
colorLabel.Font = Enum.Font.Code
colorLabel.TextSize = 13

-- Hex input row
local hexRow = Instance.new("Frame", sFrame)
hexRow.Size = UDim2.new(0.95, 0, 0, 32)
hexRow.BackgroundTransparency = 1

local hexLabel = Instance.new("TextLabel", hexRow)
hexLabel.Size = UDim2.new(0, 30, 1, 0)
hexLabel.Position = UDim2.new(0, 0, 0, 0)
hexLabel.BackgroundTransparency = 1
hexLabel.Text = "#"
hexLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
hexLabel.Font = Enum.Font.Code
hexLabel.TextSize = 14

local hexBox = Instance.new("TextBox", hexRow)
hexBox.Size = UDim2.new(0, 110, 1, 0)
hexBox.Position = UDim2.new(0, 22, 0, 0)
hexBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hexBox.BorderSizePixel = 0
hexBox.Text = color3ToHex(accentColor)
hexBox.TextColor3 = Color3.new(1, 1, 1)
hexBox.Font = Enum.Font.Code
hexBox.TextSize = 13
hexBox.PlaceholderText = "00FF00"
hexBox.ClearTextOnFocus = false
Instance.new("UICorner", hexBox).CornerRadius = UDim.new(0, 5)

local applyHexBtn = Instance.new("TextButton", hexRow)
applyHexBtn.Size = UDim2.new(0, 60, 1, 0)
applyHexBtn.Position = UDim2.new(0, 138, 0, 0)
applyHexBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
applyHexBtn.Text = "Apply"
applyHexBtn.TextColor3 = accentColor
applyHexBtn.Font = Enum.Font.Code
applyHexBtn.TextSize = 13
applyHexBtn.BorderSizePixel = 0
Instance.new("UICorner", applyHexBtn).CornerRadius = UDim.new(0, 5)
onAccent(function(c) applyHexBtn.TextColor3 = c end)

-- Preview swatch
local swatch = Instance.new("Frame", hexRow)
swatch.Size = UDim2.new(0, 26, 0, 26)
swatch.Position = UDim2.new(0, 204, 0.5, -13)
swatch.BackgroundColor3 = accentColor
swatch.BorderSizePixel = 0
Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 5)
onAccent(function(c) swatch.BackgroundColor3 = c end)

applyHexBtn.MouseButton1Click:Connect(function()
    local col = hexToColor3(hexBox.Text)
    if col then
        setAccent(col)
        hexBox.Text = color3ToHex(col)
    end
end)

-- Quick-pick preset colors
local presetLabel = Instance.new("TextLabel", sFrame)
presetLabel.Size = UDim2.new(0.95, 0, 0, 18)
presetLabel.BackgroundTransparency = 1
presetLabel.Text = "Presets:"
presetLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
presetLabel.Font = Enum.Font.Code
presetLabel.TextSize = 13
presetLabel.TextXAlignment = Enum.TextXAlignment.Left

local presetRow = Instance.new("Frame", sFrame)
presetRow.Size = UDim2.new(0.95, 0, 0, 28)
presetRow.BackgroundTransparency = 1

local presets = {
    {name="Green",  hex="00FF00"},
    {name="Cyan",   hex="00FFFF"},
    {name="Purple", hex="AA00FF"},
    {name="Red",    hex="FF2222"},
    {name="Orange", hex="FF8800"},
    {name="White",  hex="FFFFFF"},
    {name="Pink",   hex="FF69B4"},
}

for i, preset in ipairs(presets) do
    local col = hexToColor3(preset.hex)
    local pb = Instance.new("TextButton", presetRow)
    pb.Size = UDim2.new(0, 26, 0, 26)
    pb.Position = UDim2.new(0, (i-1) * 32, 0, 0)
    pb.BackgroundColor3 = col
    pb.Text = ""
    pb.BorderSizePixel = 0
    pb.ToolTipService = nil
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0, 5)
    local stroke = Instance.new("UIStroke", pb)
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 1
    pb.MouseButton1Click:Connect(function()
        setAccent(col)
        hexBox.Text = preset.hex
    end)
    pb.MouseEnter:Connect(function() stroke.Color = Color3.fromRGB(200, 200, 200) end)
    pb.MouseLeave:Connect(function() stroke.Color = Color3.fromRGB(60, 60, 60) end)
end

-- ══════════════════════════════════════════
--  CREDITS SECTION
-- ══════════════════════════════════════════
local creditsLabel = Instance.new("TextLabel", sFrame)
creditsLabel.Size = UDim2.new(0.95, 0, 0, 20)
creditsLabel.BackgroundTransparency = 1
creditsLabel.Text = "─── Credits ───"
creditsLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
creditsLabel.Font = Enum.Font.Code
creditsLabel.TextSize = 13

local creditsBox = Instance.new("Frame", sFrame)
creditsBox.Size = UDim2.new(0.95, 0, 0, 110)
creditsBox.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
creditsBox.BorderSizePixel = 0
Instance.new("UICorner", creditsBox).CornerRadius = UDim.new(0, 7)
local creditsStroke = Instance.new("UIStroke", creditsBox)
creditsStroke.Color = Color3.fromRGB(40, 40, 40)
creditsStroke.Thickness = 1

local creditsList = Instance.new("UIListLayout", creditsBox)
creditsList.Padding = UDim.new(0, 0)
creditsList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function makeCredit(role, name, color)
    local row = Instance.new("Frame", creditsBox)
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1

    local roleLabel = Instance.new("TextLabel", row)
    roleLabel.Size = UDim2.new(0.48, 0, 1, 0)
    roleLabel.Position = UDim2.new(0, 10, 0, 0)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = role
    roleLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
    roleLabel.Font = Enum.Font.Code
    roleLabel.TextSize = 13
    roleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local nameLabel = Instance.new("TextLabel", row)
    nameLabel.Size = UDim2.new(0.5, -10, 1, 0)
    nameLabel.Position = UDim2.new(0.5, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = color or accentColor
    nameLabel.Font = Enum.Font.Code
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    if not color then
        onAccent(function(c) nameLabel.TextColor3 = c end)
    end
end

makeCredit("Developer",  "Kikia",         nil)           -- uses accent color, updates live
makeCredit("UI Design",  "Kikia",         nil)
makeCredit("Version",    "v3.0",          Color3.fromRGB(180, 180, 180))
makeCredit("Framework",  "KikiaHook",     Color3.fromRGB(180, 180, 180))

local pad = Instance.new("UIPadding", creditsBox)
pad.PaddingTop = UDim.new(0, 4)
