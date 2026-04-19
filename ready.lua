local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService") -- Für CFGs hinzugefügt

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ══════════════════════════════════════════
--  COMBINED SETTINGS
-- ══════════════════════════════════════════
local ESP_SETTINGS = {
    Enabled         = true,
    ShowBox         = false,
    ShowName        = false,
    ShowHealth      = false,
    ShowDistance    = false,
    ShowSkeletons   = false,
    ShowTracer      = false,
    ShowChams       = false,
    TeamCheck       = false,
    WallCheck       = false,
    UseTeamColor    = true,
    BoxColor        = Color3.fromRGB(0, 255, 0),
    BoxOutlineColor = Color3.fromRGB(0, 0, 0),
    TracerColor     = Color3.fromRGB(255, 255, 255),
    TracerThickness = 2,
    TracerPosition  = "Bottom",
    BoxType         = "2D",
}

local AIM_SETTINGS = {
    Enabled = false,
    WallCheck = false,
    TargetPart = "Head",
    Smoothness = 15,
    FOV = 110,
    AimKey = Enum.UserInputType.MouseButton2,
    FOVColor = Color3.fromRGB(0, 255, 0)
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
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"}
}

-- ══════════════════════════════════════════
--  ESP CORE LOGIC
-- ══════════════════════════════════════════
local cache = {}
local function newDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function getPlayerColor(plr)
    if not ESP_SETTINGS.UseTeamColor then return ESP_SETTINGS.BoxColor end
    return (plr.Team and plr.Team.TeamColor.Color) or Color3.fromRGB(0, 255, 0)
end

local function behindWall(plr)
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = char.HumanoidRootPart
    local ray = Ray.new(camera.CFrame.Position, (hrp.Position - camera.CFrame.Position).Unit * (hrp.Position - camera.CFrame.Position).Magnitude)
    return workspace:FindPartOnRayWithIgnoreList(ray, {player.Character, char}) ~= nil
end

local function createPlayerEsp(plr)
    local e = {}
    e.box = newDrawing("Square", {Thickness=1, Filled=false, Visible=false})
    e.boxOutline = newDrawing("Square", {Thickness=3, Filled=false, Visible=false})
    e.boxLines = {}
    e.name = newDrawing("Text", {Outline=true, Center=true, Size=14, Visible=false})
    e.healthBg = newDrawing("Square", {Filled=true, Visible=false})
    e.healthFill = newDrawing("Square", {Filled=true, Visible=false})
    e.tracer = newDrawing("Line", {Visible=false})
    e.skeleton = {}
    cache[plr] = e
end

local function hidePlayerEsp(e)
    e.box.Visible = false; e.boxOutline.Visible = false; e.name.Visible = false
    e.healthBg.Visible = false; e.healthFill.Visible = false; e.tracer.Visible = false
    for _, l in ipairs(e.boxLines) do l.Visible = false end
    for _, ld in ipairs(e.skeleton) do ld[1].Visible = false end
end

-- ══════════════════════════════════════════
--  KICIAHOOK V2 GUI SETUP
-- ══════════════════════════════════════════
if CoreGui:FindFirstChild("KikiaHookV2") then CoreGui.KikiaHookV2:Destroy() end
local screenGui = Instance.new("ScreenGui", CoreGui); screenGui.Name = "KikiaHookV2"
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 520, 0, 420); mainFrame.Position = UDim2.new(0.5, -260, 0.5, -210); mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12); mainFrame.BorderSizePixel = 0
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Color = Color3.fromRGB(0, 255, 0)

local sidebar = Instance.new("Frame", mainFrame); sidebar.Size = UDim2.new(0, 120, 1, 0); sidebar.BackgroundColor3 = Color3.fromRGB(8, 8, 8); sidebar.BorderSizePixel = 0
local container = Instance.new("Frame", mainFrame); container.Size = UDim2.new(1, -140, 1, -20); container.Position = UDim2.new(0, 130, 0, 10); container.BackgroundTransparency = 1

local vFrame = Instance.new("ScrollingFrame", container); vFrame.Size = UDim2.new(1,0,1,0); vFrame.BackgroundTransparency = 1; vFrame.Visible = true; vFrame.ScrollBarThickness = 0
local aFrame = Instance.new("ScrollingFrame", container); aFrame.Size = UDim2.new(1,0,1,0); aFrame.BackgroundTransparency = 1; aFrame.Visible = false; aFrame.ScrollBarThickness = 0
local hFrame = Instance.new("ScrollingFrame", container); hFrame.Size = UDim2.new(1,0,1,0); hFrame.BackgroundTransparency = 1; hFrame.Visible = false; hFrame.ScrollBarThickness = 0
local sFrame = Instance.new("Frame", container); sFrame.Size = UDim2.new(1,0,1,0); sFrame.BackgroundTransparency = 1; sFrame.Visible = false

Instance.new("UIListLayout", vFrame).Padding = UDim.new(0, 8)
Instance.new("UIListLayout", aFrame).Padding = UDim.new(0, 8)
Instance.new("UIListLayout", hFrame).Padding = UDim.new(0, 8)

local allTabButtons = {}
local function makeTab(txt, y, target, isBottom)
    local b = Instance.new("TextButton", sidebar); b.Size = UDim2.new(1, 0, 0, 40)
    if isBottom then b.Position = UDim2.new(0, 0, 1, -40) else b.Position = UDim2.new(0, 0, 0, y) end
    b.BackgroundColor3 = Color3.fromRGB(8, 8, 8); b.Text = txt; b.TextColor3 = Color3.fromRGB(150, 150, 150); b.Font = Enum.Font.Code; b.BorderSizePixel = 0; b.TextSize = 15
    table.insert(allTabButtons, b)
    b.MouseButton1Click:Connect(function() 
        vFrame.Visible = false; aFrame.Visible = false; hFrame.Visible = false; sFrame.Visible = false
        target.Visible = true 
        for _,v in pairs(allTabButtons) do v.TextColor3 = Color3.fromRGB(150, 150, 150) end
        b.TextColor3 = Color3.fromRGB(0, 255, 0)
    end)
end
makeTab("Visuals", 10, vFrame)
makeTab("Aimbot", 55, aFrame)
makeTab("HvH", 100, hFrame)
makeTab("Settings", 0, sFrame, true)

-- GUI COMPONENTS
local function createToggle(txt, parent, cb)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 25); f.BackgroundTransparency = 1
    local b = Instance.new("TextButton", f); b.Size = UDim2.new(0, 16, 0, 16); b.Position = UDim2.new(0, 0, 0.5, -8); b.BackgroundColor3 = Color3.fromRGB(30, 30, 30); b.Text = ""; b.BorderSizePixel = 0
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, -25, 1, 0); t.Position = UDim2.new(0, 25, 0, 0); t.Text = txt; t.TextColor3 = Color3.fromRGB(200, 200, 200); t.Font = Enum.Font.Code; t.TextSize = 14; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
    local on = false
    b.MouseButton1Click:Connect(function() on = not on; b.BackgroundColor3 = on and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(30, 30, 30); cb(on) end)
end

local function createSlider(txt, min, max, start, parent, cb)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 0, 45); f.BackgroundTransparency = 1
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1, 0, 0, 20); t.Text = txt .. ": " .. start; t.TextColor3 = Color3.fromRGB(200, 200, 200); t.Font = Enum.Font.Code; t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
    local b = Instance.new("Frame", f); b.Size = UDim2.new(0.9, 0, 0, 4); b.Position = UDim2.new(0, 0, 0, 28); b.BackgroundColor3 = Color3.fromRGB(30, 30, 30); b.BorderSizePixel = 0
    local fi = Instance.new("Frame", b); fi.Size = UDim2.new((start-min)/(max-min), 0, 1, 0); fi.BackgroundColor3 = Color3.fromRGB(0, 255, 0); fi.BorderSizePixel = 0
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

local function createDropdown(parent, text, callback)
    local frame = Instance.new("Frame", parent); frame.Size = UDim2.new(1, 0, 0, 30); frame.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", frame); btn.Size = UDim2.new(0.95, 0, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.Text = text .. ": None"; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.Code; btn.BorderSizePixel = 0; btn.ZIndex = 2
    
    local list = Instance.new("ScrollingFrame", parent); list.Size = UDim2.new(0.95, 0, 0, 100); list.BackgroundColor3 = Color3.fromRGB(15, 15, 15); list.Visible = false; list.ScrollBarThickness = 2; list.BorderSizePixel = 0; list.ZIndex = 3
    local layout = Instance.new("UIListLayout", list); layout.SortOrder = Enum.SortOrder.LayoutOrder

    btn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        if list.Visible then
            for _, v in pairs(list:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player then
                    local pBtn = Instance.new("TextButton", list)
                    pBtn.Size = UDim2.new(1, 0, 0, 25); pBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); pBtn.Text = p.Name; pBtn.TextColor3 = Color3.new(1,1,1); pBtn.Font = Enum.Font.Code; pBtn.TextSize = 14; pBtn.BorderSizePixel = 0; pBtn.ZIndex = 4
                    pBtn.MouseButton1Click:Connect(function() btn.Text = text .. ": " .. p.Name; list.Visible = false; callback(p) end)
                end
            end
            list.CanvasSize = UDim2.new(0, 0, 0, #list:GetChildren() * 25)
        end
    end)
end

-- ══════════════════════════════════════════
--  SETTINGS TAB DESIGN (LIKE IMAGE)
-- ══════════════════════════════════════════
local leftPanel = Instance.new("Frame", sFrame); leftPanel.Size = UDim2.new(0.48, 0, 1, 0); leftPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15); leftPanel.BorderSizePixel = 0
local rightPanel = Instance.new("Frame", sFrame); rightPanel.Size = UDim2.new(0.48, 0, 1, 0); rightPanel.Position = UDim2.new(0.52, 0, 0, 0); rightPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15); rightPanel.BorderSizePixel = 0

local function createPanel(name, parent)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(1, 0, 1, 0); f.BackgroundTransparency = 1
    Instance.new("UIStroke", f).Color = Color3.fromRGB(30, 30, 30)
    local title = Instance.new("TextLabel", f); title.Size = UDim2.new(0, 80, 0, 20); title.Position = UDim2.new(0, 10, 0, -10); title.BackgroundColor3 = Color3.fromRGB(12, 12, 12); title.Text = name; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.Code; title.TextSize = 12
    local content = Instance.new("ScrollingFrame", f); content.Size = UDim2.new(1, -10, 1, -20); content.Position = UDim2.new(0, 5, 0, 10); content.BackgroundTransparency = 1; content.ScrollBarThickness = 0
    Instance.new("UIListLayout", content).Padding = UDim.new(0, 5)
    return content
end

local menuContent = createPanel("Menu", leftPanel)
local configContent = createPanel("Configuration", rightPanel)

-- Left Panel Items
createToggle("Invisible Open Button", menuContent, function() end)
local themeBtn = Instance.new("TextButton", menuContent); themeBtn.Size = UDim2.new(0.95, 0, 0, 30); themeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); themeBtn.Text = "Cycle Theme Color"; themeBtn.TextColor3 = Color3.new(1,1,1); themeBtn.Font = Enum.Font.Code; themeBtn.BorderSizePixel = 0
themeBtn.MouseButton1Click:Connect(function()
    local colors = {Color3.fromRGB(0,255,0), Color3.fromRGB(255,0,0), Color3.fromRGB(0,150,255), Color3.fromRGB(255,255,255)}
    local nextC = colors[math.random(1, #colors)]
    uiStroke.Color = nextC
    for _,v in pairs(allTabButtons) do if v.TextColor3 ~= Color3.fromRGB(150,150,150) then v.TextColor3 = nextC end end
end)

-- Right Panel (Configs)
local cfgInput = Instance.new("TextBox", configContent); cfgInput.Size = UDim2.new(0.95, 0, 0, 30); cfgInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25); cfgInput.Text = "config_name"; cfgInput.TextColor3 = Color3.new(1,1,1); cfgInput.Font = Enum.Font.Code; cfgInput.BorderSizePixel = 0

local function cfgBtn(txt, cb)
    local b = Instance.new("TextButton", configContent); b.Size = UDim2.new(0.95, 0, 0, 30); b.BackgroundColor3 = Color3.fromRGB(30, 30, 30); b.Text = txt; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.Code; b.BorderSizePixel = 0
    b.MouseButton1Click:Connect(cb)
end

cfgBtn("Create", function()
    local data = {ESP = ESP_SETTINGS, AIM = AIM_SETTINGS, HVH = HVH_SETTINGS}
    writefile(cfgInput.Text..".json", HttpService:JSONEncode(data))
end)

cfgBtn("Save", function()
    local data = {ESP = ESP_SETTINGS, AIM = AIM_SETTINGS, HVH = HVH_SETTINGS}
    writefile(cfgInput.Text..".json", HttpService:JSONEncode(data))
end)

cfgBtn("Load", function()
    if isfile(cfgInput.Text..".json") then
        local data = HttpService:JSONDecode(readfile(cfgInput.Text..".json"))
        ESP_SETTINGS = data.ESP; AIM_SETTINGS = data.AIM; HVH_SETTINGS = data.HVH
    end
end)

-- TAB CONTENT (Visuals / Aimbot / HvH)
createToggle("Box ESP", vFrame, function(v) ESP_SETTINGS.ShowBox = v end)
createToggle("Name ESP", vFrame, function(v) ESP_SETTINGS.ShowName = v end)
createToggle("Health ESP", vFrame, function(v) ESP_SETTINGS.ShowHealth = v end)
createToggle("Skeleton ESP", vFrame, function(v) ESP_SETTINGS.ShowSkeletons = v end)
createToggle("Tracer ESP", vFrame, function(v) ESP_SETTINGS.ShowTracer = v end)

createToggle("Aimbot Master", aFrame, function(v) AIM_SETTINGS.Enabled = v end)
createToggle("Wall Check", aFrame, function(v) AIM_SETTINGS.WallCheck = v end)
createSlider("Smoothness", 1, 100, 15, aFrame, function(v) AIM_SETTINGS.Smoothness = v end)
createSlider("FOV Radius", 10, 500, 110, aFrame, function(v) AIM_SETTINGS.FOV = v end)

createToggle("Orbit Enabled", hFrame, function(v) HVH_SETTINGS.OrbitEnabled = v end)
createDropdown(hFrame, "Select Player", function(p) HVH_SETTINGS.OrbitTarget = p end)
createSlider("Orbit Speed", 1, 100, 10, hFrame, function(v) HVH_SETTINGS.OrbitSpeed = v end)
createSlider("Orbit Distance", 2, 50, 5, hFrame, function(v) HVH_SETTINGS.OrbitDistance = v end)

-- ══════════════════════════════════════════
--  ENGINE
-- ══════════════════════════════════════════
local fovCircle = Drawing.new("Circle"); fovCircle.Thickness = 1; fovCircle.Visible = true

RunService.RenderStepped:Connect(function()
    fovCircle.Radius = AIM_SETTINGS.FOV
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Color = AIM_SETTINGS.FOVColor
    fovCircle.Visible = AIM_SETTINGS.Enabled

    -- ESP UPDATE
    for plr, e in pairs(cache) do
        local char = plr.Character
        if ESP_SETTINGS.Enabled and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local rootPos, onScreen = camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                if onScreen and not (ESP_SETTINGS.WallCheck and behindWall(plr)) then
                    local color = getPlayerColor(plr)
                    local dist = rootPos.Z
                    local sizeY = math.clamp((1500/dist)*1.3, 10, 800)
                    local sizeX = sizeY * 0.6
                    local boxPos = Vector2.new(rootPos.X - sizeX/2, rootPos.Y - sizeY/2)

                    e.box.Visible = ESP_SETTINGS.ShowBox; e.box.Size = Vector2.new(sizeX, sizeY); e.box.Position = boxPos; e.box.Color = color
                    e.boxOutline.Visible = ESP_SETTINGS.ShowBox; e.boxOutline.Size = e.box.Size; e.boxOutline.Position = boxPos; e.boxOutline.Color = Color3.new(0,0,0)
                    e.name.Visible = ESP_SETTINGS.ShowName; e.name.Text = plr.Name; e.name.Position = Vector2.new(rootPos.X, boxPos.Y - 16); e.name.Color = color
                    
                    if ESP_SETTINGS.ShowHealth then
                        local hp = hum.Health / hum.MaxHealth
                        e.healthBg.Visible = true; e.healthBg.Size = Vector2.new(4, sizeY); e.healthBg.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
                        e.healthFill.Visible = true; e.healthFill.Size = Vector2.new(2, sizeY * hp); e.healthFill.Position = Vector2.new(boxPos.X - 5, boxPos.Y + (sizeY * (1-hp))); e.healthFill.Color = Color3.fromRGB(255*(1-hp), 255*hp, 0)
                    else e.healthBg.Visible = false; e.healthFill.Visible = false end

                    if ESP_SETTINGS.ShowSkeletons then
                        if #e.skeleton == 0 then for _,bp in pairs(bones) do table.insert(e.skeleton, {newDrawing("Line",{Thickness=1}), bp[1], bp[2]}) end end
                        for _,ld in pairs(e.skeleton) do
                            local p1, p2 = char:FindFirstChild(ld[2]), char:FindFirstChild(ld[3])
                            if p1 and p2 then
                                local s1, o1 = camera:WorldToViewportPoint(p1.Position); local s2, o2 = camera:WorldToViewportPoint(p2.Position)
                                if o1 and o2 then ld[1].From = Vector2.new(s1.X, s1.Y); ld[1].To = Vector2.new(s2.X, s2.Y); ld[1].Color = color; ld[1].Visible = true else ld[1].Visible = false end
                            end
                        end
                    end
                else hidePlayerEsp(e) end
            else hidePlayerEsp(e) end
        else hidePlayerEsp(e) end
    end

    -- AIMBOT UPDATE
    if AIM_SETTINGS.Enabled and UserInputService:IsMouseButtonPressed(AIM_SETTINGS.AimKey) then
        local target = nil; local dist = AIM_SETTINGS.FOV
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild(AIM_SETTINGS.TargetPart) then
                local pos, on = camera:WorldToViewportPoint(p.Character[AIM_SETTINGS.TargetPart].Position)
                local mDist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if on and mDist < dist then
                    if not AIM_SETTINGS.WallCheck or not behindWall(p) then target = p.Character[AIM_SETTINGS.TargetPart]; dist = mDist end
                end
            end
        end
        if target then
            local tPos = camera:WorldToViewportPoint(target.Position); local mPos = UserInputService:GetMouseLocation()
            mousemoverel((tPos.X - mPos.X)/(AIM_SETTINGS.Smoothness/5), (tPos.Y - mPos.Y)/(AIM_SETTINGS.Smoothness/5))
        end
    end

    -- ORBIT UPDATE
    if HVH_SETTINGS.OrbitEnabled and HVH_SETTINGS.OrbitTarget and HVH_SETTINGS.OrbitTarget.Character then
        local tRoot = HVH_SETTINGS.OrbitTarget.Character:FindFirstChild("HumanoidRootPart")
        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if tRoot and myRoot then
            local angle = tick() * HVH_SETTINGS.OrbitSpeed
            local offset = Vector3.new(math.sin(angle) * HVH_SETTINGS.OrbitDistance, 2, math.cos(angle) * HVH_SETTINGS.OrbitDistance)
            myRoot.CFrame = CFrame.new(tRoot.Position + offset, tRoot.Position)
            myRoot.Velocity = Vector3.new(0,0,0)
        end
    end
end)

-- INIT
for _, p in pairs(Players:GetPlayers()) do if p ~= player then createPlayerEsp(p) end end
Players.PlayerAdded:Connect(function(p) createPlayerEsp(p) end)
UserInputService.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Enum.KeyCode.RightShift then mainFrame.Visible = not mainFrame.Visible end end)

-- DRAG
local d, s, sp; mainFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d=true s=i.Position sp=mainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position-s mainFrame.Position=UDim2.new(sp.X.Scale, sp.X.Offset+delta.X, sp.Y.Scale, sp.Y.Offset+delta.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d=false end end)
