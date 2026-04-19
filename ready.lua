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
local uiStroke = Instance.new("UIStroke", mainFrame); uiStroke.Color = Color3.fromRGB(0, 255, 0); uiStroke.Thickness = 1.5

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
        b.TextColor3 = Color3.fromRGB(0, 255, 0)
    end)
end

makeTab("Visuals", 10, vFrame); makeTab("Aimbot", 55, aFrame); makeTab("HvH", 100, hFrame); makeTab("Settings", 0, sFrame, true)

-- UI COMPONENTS
local function createToggle(txt, parent, default, cb)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 30); f.BackgroundTransparency = 1
    local b = Instance.new("TextButton", f); b.Size = UDim2.new(0, 18, 0, 18); b.Position = UDim2.new(0, 5, 0.5, -9); b.BackgroundColor3 = default and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(30, 30, 30); b.Text = ""; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, -35, 1, 0); t.Position = UDim2.new(0, 30, 0, 0); t.Text = txt; t.TextColor3 = Color3.fromRGB(200, 200, 200); t.Font = Enum.Font.Code; t.TextSize = 14; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
    local on = default
    b.MouseButton1Click:Connect(function() on = not on; b.BackgroundColor3 = on and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(30, 30, 30); cb(on) end)
end

local function createSlider(txt, min, max, start, parent, cb)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 45); f.BackgroundTransparency = 1
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, 0, 0, 20); t.Text = txt .. ": " .. start; t.TextColor3 = Color3.fromRGB(200, 200, 200); t.Font = Enum.Font.Code; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
    local b = Instance.new("Frame", f); b.Size = UDim2.new(1, 0, 0, 6); b.Position = UDim2.new(0, 0, 0, 28); b.BackgroundColor3 = Color3.fromRGB(30, 30, 30); b.BorderSizePixel = 0
    Instance.new("UICorner", b)
    local fi = Instance.new("Frame", b); fi.Size = UDim2.new((start-min)/(max-min), 0, 1, 0); fi.BackgroundColor3 = Color3.fromRGB(0, 255, 0); fi.BorderSizePixel = 0
    Instance.new("UICorner", fi)
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
    fovCircle.Color = Color3.fromRGB(0, 255, 0)
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
            
            -- Setzt Position relativ zum Ziel und lässt dich zum Ziel schauen
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
