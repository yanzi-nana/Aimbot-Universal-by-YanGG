--[[ CheatGUI_Mobile_LocalScript.lua
 
	Onde colocar:
	  StarterPlayer > StarterPlayerScripts > (cole este script como um LocalScript)
]]
 
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
 
local LocalPlayer = Players.LocalPlayer
 
----------------------------------------------------------------
-- CONFIGURAÇÕES INICIAIS
----------------------------------------------------------------
local CONFIG = {
	AimbotRange = 300,        -- Distância máxima em studs
	AimbotSpeed = 12,         -- Velocidade do snap
	AimPart = "Head",         -- "Head" ou "HumanoidRootPart"
	FOVRadius = 120,          -- Raio do círculo de FOV em pixels
	
	HitboxSize = 6,           -- Tamanho da Hitbox expandida
	CameraFOV = 70,           -- FOV da câmera (padrão Roblox = 70)
 
	ESPColor = Color3.fromRGB(255, 60, 60),
	ESPFillTransparency = 0.7,
	ESPOutlineTransparency = 0,
 
	TracerColor = Color3.fromRGB(255, 30, 30),
	TracerThickness = 2,
	TracerOriginY = 0,
}
 
local state = {
	aimbotEnabled = false,
	wallCheckEnabled = false, -- Wall Check para Aimbot
	showFOVCircle = true,
	hitboxEnabled = false,
	cameraFOVEnabled = false,
	espEnabled = false,
	chamsEnabled = false,    -- Chams (Wallhack)
	espInfoEnabled = false,
	tracersEnabled = false,
	bhopEnabled = false,      -- Auto Bhop / Jump
	selectedTeamIndex = 1,
	minimized = false,
}
 
local espHighlights = {}  -- [player] = Highlight instance
local chamsHighlights = {} -- [player] = Highlight instance
local espBillboards = {}  -- [player] = BillboardGui instance
local tracerLines = {}    -- [player] = Frame
local originalHitboxSizes = {} -- [player] = Vector3
local isBhopHolding = false
 
----------------------------------------------------------------
-- OPÇÕES DE TIME
----------------------------------------------------------------
local function getTeamOptions()
	local options = {"Inimigos", "Todos"}
	for _, team in ipairs(Teams:GetTeams()) do
		table.insert(options, team)
	end
	return options
end
 
----------------------------------------------------------------
-- GUI BASE
----------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CheatMenuMobile"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
 
local FULL_HEIGHT = 480
local COLLAPSED_HEIGHT = 44
local MENU_WIDTH = 270
 
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0, 0.5)
mainFrame.Size = UDim2.new(0, MENU_WIDTH, 0, FULL_HEIGHT)
mainFrame.Position = UDim2.new(0, 16, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui
 
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame
 
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 60, 60)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.5
mainStroke.Parent = mainFrame
 
-- Barra de Título
local title = Instance.new("TextLabel")
title.Name = "TitleBar"
title.Size = UDim2.new(1, 0, 0, COLLAPSED_HEIGHT)
title.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
title.BackgroundTransparency = 1
title.BorderSizePixel = 0
title.Text = "  aimbot by YanGG🩸"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 70, 70)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.Parent = mainFrame
 
local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 36, 0, 36)
minimizeButton.Position = UDim2.new(1, -40, 0, 4)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 22
minimizeButton.ZIndex = 2
minimizeButton.Parent = title

-- BOLINHA FLUTUANTE (QUANDO MINIMIZADO)
local floatBall = Instance.new("TextButton")
floatBall.Name = "FloatBall"
floatBall.Size = UDim2.new(0, 45, 0, 45)
floatBall.Position = mainFrame.Position
floatBall.AnchorPoint = Vector2.new(0, 0.5)
floatBall.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
floatBall.Text = "🩸"
floatBall.TextSize = 22
floatBall.Visible = true
floatBall.Active = true
floatBall.Draggable = true
floatBall.Parent = screenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = floatBall

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(255, 60, 60)
floatStroke.Thickness = 1.5
floatStroke.Parent = floatBall

-- BOTÃO DE PULO PARA BHOP MOBILE
local bhopMobileBtn = Instance.new("TextButton")
bhopMobileBtn.Name = "BhopMobileButton"
bhopMobileBtn.Size = UDim2.new(0, 55, 0, 55)
bhopMobileBtn.Position = UDim2.new(1, -70, 1, -120)
bhopMobileBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
bhopMobileBtn.BackgroundTransparency = 0.3
bhopMobileBtn.Text = "🐰"
bhopMobileBtn.TextSize = 24
bhopMobileBtn.Visible = false
bhopMobileBtn.Active = true
bhopMobileBtn.Draggable = true
bhopMobileBtn.Parent = screenGui

local bhopCorner = Instance.new("UICorner")
bhopCorner.CornerRadius = UDim.new(1, 0)
bhopCorner.Parent = bhopMobileBtn

bhopMobileBtn.MouseButton1Down:Connect(function()
	isBhopHolding = true
end)

bhopMobileBtn.MouseButton1Up:Connect(function()
	isBhopHolding = false
end)
 
-- CÍRCULO VISUAL DE FOV
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.Size = UDim2.new(0, CONFIG.FOVRadius * 2, 0, CONFIG.FOVRadius * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = state.showFOVCircle
fovCircle.Parent = screenGui
 
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle
 
local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 70, 70)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.3
fovStroke.Parent = fovCircle
 
-- CONTAINER ROLÁVEL (SCROLLING FRAME)
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollContent"
scrollFrame.Size = UDim2.new(1, 0, 1, -COLLAPSED_HEIGHT)
scrollFrame.Position = UDim2.new(0, 0, 0, COLLAPSED_HEIGHT)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 60, 60)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 660)
scrollFrame.Parent = mainFrame
 
----------------------------------------------------------------
-- GERADORES DE INTERFACE
----------------------------------------------------------------
local function createToggleButton(yPos, labelText, iconText, defaultState)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -24, 0, 38)
	button.Position = UDim2.new(0, 12, 0, yPos)
	button.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
	button.Text = ""
	button.AutoButtonColor = true
	button.Parent = scrollFrame
 
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button
 
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = iconText .. "  " .. labelText
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.Parent = button
 
	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(0, 40, 0, 20)
	pill.Position = UDim2.new(1, -48, 0.5, -10)
	pill.BackgroundColor3 = defaultState and Color3.fromRGB(40, 170, 80) or Color3.fromRGB(60, 60, 60)
	pill.Parent = button
 
	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0)
	pillCorner.Parent = pill
 
	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = defaultState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	knob.Parent = pill
 
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob
 
	return button, pill, knob
end
 
local function createSelectorButton(yPos, labelText, defaultValText)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -24, 0, 38)
	button.Position = UDim2.new(0, 12, 0, yPos)
	button.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
	button.Text = ""
	button.AutoButtonColor = true
	button.Parent = scrollFrame
 
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button
 
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 110, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.Parent = button
 
	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(1, -120, 1, 0)
	valLabel.Position = UDim2.new(0, 110, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = defaultValText
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	valLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	valLabel.Font = Enum.Font.GothamBold
	valLabel.TextSize = 13
	valLabel.Parent = button
 
	return button, valLabel
end
 
local function createAdjuster(yPos, labelText, initialVal, minVal, maxVal, step, onUpdate)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -24, 0, 38)
	frame.Position = UDim2.new(0, 12, 0, yPos)
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
	frame.Parent = scrollFrame
 
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = frame
 
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 110, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.Parent = frame
 
	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0, 40, 1, 0)
	valLabel.Position = UDim2.new(1, -110, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = tostring(initialVal)
	valLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	valLabel.Font = Enum.Font.GothamBold
	valLabel.TextSize = 12
	valLabel.Parent = frame
 
	local minusBtn = Instance.new("TextButton")
	minusBtn.Size = UDim2.new(0, 26, 0, 26)
	minusBtn.Position = UDim2.new(1, -62, 0.5, -13)
	minusBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
	minusBtn.Text = "-"
	minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	minusBtn.Font = Enum.Font.GothamBold
	minusBtn.TextSize = 15
	minusBtn.Parent = frame
 
	local plusBtn = Instance.new("TextButton")
	plusBtn.Size = UDim2.new(0, 26, 0, 26)
	plusBtn.Position = UDim2.new(1, -30, 0.5, -13)
	plusBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
	plusBtn.Text = "+"
	plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	plusBtn.Font = Enum.Font.GothamBold
	plusBtn.TextSize = 15
	plusBtn.Parent = frame
 
	local btnCorner1 = Instance.new("UICorner")
	btnCorner1.CornerRadius = UDim.new(0, 6)
	btnCorner1.Parent = minusBtn
	local btnCorner2 = Instance.new("UICorner")
	btnCorner2.CornerRadius = UDim.new(0, 6)
	btnCorner2.Parent = plusBtn
 
	local currentVal = initialVal
 
	minusBtn.MouseButton1Click:Connect(function()
		currentVal = math.max(minVal, currentVal - step)
		valLabel.Text = tostring(currentVal)
		onUpdate(currentVal)
	end)
 
	plusBtn.MouseButton1Click:Connect(function()
		currentVal = math.min(maxVal, currentVal + step)
		valLabel.Text = tostring(currentVal)
		onUpdate(currentVal)
	end)
end
 
----------------------------------------------------------------
-- COMPOSIÇÃO DOS BOTÕES
----------------------------------------------------------------
local aimbotBtn, aimbotPill, aimbotKnob = createToggleButton(6, "Aimbot", "🎯", state.aimbotEnabled)
local wallCheckBtn, wallCheckPill, wallCheckKnob = createToggleButton(48, "Wall Check", "🧱", state.wallCheckEnabled)
local fovCircleBtn, fovCirclePill, fovCircleKnob = createToggleButton(90, "Mostrar FOV", "⭕", state.showFOVCircle)
local aimPartBtn, aimPartLabel = createSelectorButton(132, "Mira Em:", "Cabeça")
local teamSelectBtn, teamSelectLabel = createSelectorButton(174, "🛡️ Alvo Time:", "Inimigos")
 
local hitboxBtn, hitboxPill, hitboxKnob = createToggleButton(216, "Expandir Hitbox", "📦", state.hitboxEnabled)
local camFovBtn, camFovPill, camFovKnob = createToggleButton(258, "Câmera FOV", "🎥", state.cameraFOVEnabled)
 
local espBtn, espPill, espKnob = createToggleButton(300, "ESP Highlight", "👁", state.espEnabled)
local chamsBtn, chamsPill, chamsKnob = createToggleButton(342, "Wallhack Chams", "✨", state.chamsEnabled)
local espInfoBtn, espInfoPill, espInfoKnob = createToggleButton(384, "ESP Info (Nome/HP)", "🏷️", state.espInfoEnabled)
local tracerBtn, tracerPill, tracerKnob = createToggleButton(426, "Tracers", "📡", state.tracersEnabled)
local bhopBtn, bhopPill, bhopKnob = createToggleButton(468, "Auto Bhop (Mobile)", "🐰", state.bhopEnabled)

createAdjuster(514, "Velocidade", CONFIG.AimbotSpeed, 1, 50, 2, function(v) CONFIG.AimbotSpeed = v end)
createAdjuster(556, "Raio do FOV", CONFIG.FOVRadius, 30, 500, 10, function(v)
	CONFIG.FOVRadius = v
	fovCircle.Size = UDim2.new(0, v * 2, 0, v * 2)
end)
createAdjuster(598, "Tam. Hitbox", CONFIG.HitboxSize, 2, 20, 1, function(v) CONFIG.HitboxSize = v end)
createAdjuster(640, "Câmera Zoom", CONFIG.CameraFOV, 60, 120, 5, function(v) CONFIG.CameraFOV = v end)
 
local function setToggleVisual(pill, knob, enabled)
	local pillColor = enabled and Color3.fromRGB(40, 170, 80) or Color3.fromRGB(60, 60, 60)
	local knobPos = enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	TweenService:Create(pill, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundColor3 = pillColor }):Play()
	TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Position = knobPos }):Play()
end
 
----------------------------------------------------------------
-- ANIMAÇÃO E MINIMIZAR (BOLINHA)
----------------------------------------------------------------
mainFrame.Size = UDim2.new(0, MENU_WIDTH, 0, 0)
task.defer(function()
	TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Size = UDim2.new(0, MENU_WIDTH, 0, FULL_HEIGHT),
	}):Play()
end)
 
local function toggleMinimize()
	state.minimized = not state.minimized
	
	if state.minimized then
		floatBall.Position = mainFrame.Position
		mainFrame.Visible = false
		floatBall.Visible = true
	else
		mainFrame.Position = floatBall.Position
		floatBall.Visible = false
		mainFrame.Visible = true
	end
end

minimizeButton.MouseButton1Click:Connect(toggleMinimize)
floatBall.MouseButton1Click:Connect(toggleMinimize)
 
----------------------------------------------------------------
-- LÓGICA DE VALIDAÇÃO DE ALVO E WALL CHECK
----------------------------------------------------------------
local function isTargetValid(player)
	if player == LocalPlayer or not player.Character then return false end
 
	local options = getTeamOptions()
	local selectedOption = options[state.selectedTeamIndex] or "Inimigos"
 
	if selectedOption == "Inimigos" then
		if player.Team ~= nil and player.Team == LocalPlayer.Team then
			return false
		end
	elseif typeof(selectedOption) == "Instance" and selectedOption:IsA("Team") then
		if player.Team ~= selectedOption then
			return false
		end
	end
 
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local part = player.Character:FindFirstChild(CONFIG.AimPart)
 
	return humanoid and humanoid.Health > 0 and part ~= nil
end

local function isPartVisible(part)
	if not state.wallCheckEnabled then return true end
	
	local ignoreList = {LocalPlayer.Character, part.Parent}
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = ignoreList
	
	local rayOrigin = Camera.CFrame.Position
	local rayDirection = (part.Position - rayOrigin)
	
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	return rayResult == nil
end
 
----------------------------------------------------------------
-- ESP HIGHLIGHT, CHAMS & INFO
----------------------------------------------------------------
local function removeESP(player)
	if espHighlights[player] then
		espHighlights[player]:Destroy()
		espHighlights[player] = nil
	end
	if chamsHighlights[player] then
		chamsHighlights[player]:Destroy()
		chamsHighlights[player] = nil
	end
	if espBillboards[player] then
		espBillboards[player]:Destroy()
		espBillboards[player] = nil
	end
end
 
local function updatePlayerESP(player)
	if not isTargetValid(player) then
		removeESP(player)
		return
	end
 
	-- ESP Highlight Padrao
	if state.espEnabled then
		if not espHighlights[player] or espHighlights[player].Parent ~= player.Character then
			removeESP(player)
			local highlight = Instance.new("Highlight")
			highlight.FillColor = CONFIG.ESPColor
			highlight.OutlineColor = CONFIG.ESPColor
			highlight.FillTransparency = CONFIG.ESPFillTransparency
			highlight.OutlineTransparency = CONFIG.ESPOutlineTransparency
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = player.Character
			espHighlights[player] = highlight
		end
	elseif espHighlights[player] then
		espHighlights[player]:Destroy()
		espHighlights[player] = nil
	end

	-- Chams (Wallhack de Cores)
	if state.chamsEnabled then
		if not chamsHighlights[player] or chamsHighlights[player].Parent ~= player.Character then
			local chams = Instance.new("Highlight")
			chams.FillColor = Color3.fromRGB(0, 255, 150)
			chams.OutlineColor = Color3.fromRGB(255, 255, 255)
			chams.FillTransparency = 0.2
			chams.OutlineTransparency = 0
			chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			chams.Parent = player.Character
			chamsHighlights[player] = chams
		end
	elseif chamsHighlights[player] then
		chamsHighlights[player]:Destroy()
		chamsHighlights[player] = nil
	end
 
	-- ESP Info (Billboard)
	if state.espInfoEnabled then
		local head = player.Character:FindFirstChild("Head")
		if head and not espBillboards[player] then
			local bb = Instance.new("BillboardGui")
			bb.Name = "ESPInfo"
			bb.Adornee = head
			bb.Size = UDim2.new(0, 140, 0, 40)
			bb.StudsOffset = Vector3.new(0, 2.5, 0)
			bb.AlwaysOnTop = true
 
			local txt = Instance.new("TextLabel")
			txt.Name = "InfoText"
			txt.Size = UDim2.new(1, 0, 1, 0)
			txt.BackgroundTransparency = 1
			txt.TextColor3 = Color3.fromRGB(255, 255, 255)
			txt.TextStrokeTransparency = 0.2
			txt.Font = Enum.Font.GothamBold
			txt.TextSize = 11
			txt.Parent = bb
 
			bb.Parent = head
			espBillboards[player] = bb
		end
	elseif espBillboards[player] then
		espBillboards[player]:Destroy()
		espBillboards[player] = nil
	end
end
 
local function refreshAllESP()
	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerESP(player)
	end
end
 
----------------------------------------------------------------
-- TRACERS
----------------------------------------------------------------
local function getOrCreateTracer(player)
	local line = tracerLines[player]
	if not line then
		line = Instance.new("Frame")
		line.Name = "Tracer_" .. player.Name
		line.AnchorPoint = Vector2.new(0, 0.5)
		line.BackgroundColor3 = CONFIG.TracerColor
		line.BorderSizePixel = 0
		line.ZIndex = 1
		line.Parent = screenGui
		tracerLines[player] = line
	end
	return line
end
 
local function updateTracer(line, fromPos, toPos)
	local diff = toPos - fromPos
	local distance = diff.Magnitude
	local angle = math.deg(math.atan2(diff.Y, diff.X))
 
	line.Size = UDim2.new(0, distance, 0, CONFIG.TracerThickness)
	line.Position = UDim2.new(0, fromPos.X, 0, fromPos.Y)
	line.Rotation = angle
	line.Visible = true
end
 
----------------------------------------------------------------
-- AIMBOT COM FOV E WALL CHECK
----------------------------------------------------------------
local function getClosestTargetInFOV()
	local myCharacter = LocalPlayer.Character
	if not myCharacter then return nil end
	local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end
 
	local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local closestPlayer, closestDist = nil, CONFIG.AimbotRange
 
	for _, player in ipairs(Players:GetPlayers()) do
		if isTargetValid(player) then
			local part = player.Character:FindFirstChild(CONFIG.AimPart)
			if part and isPartVisible(part) then
				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
					if distFromCenter <= CONFIG.FOVRadius then
						local dist3D = (part.Position - myRoot.Position).Magnitude
						if dist3D < closestDist then
							closestDist = dist3D
							closestPlayer = player
						end
					end
				end
			end
		end
	end
 
	return closestPlayer
end
 
----------------------------------------------------------------
-- LOOP PRINCIPAL (RenderStepped)
----------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	-- Auto Bhop (Segurar botão no Mobile)
	if state.bhopEnabled and isBhopHolding then
		local char = LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.FloorMaterial ~= Enum.Material.Air then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end

	-- Câmera FOV
	if state.cameraFOVEnabled then
		Camera.FieldOfView = CONFIG.CameraFOV
	end
 
	-- Aimbot
	if state.aimbotEnabled then
		local target = getClosestTargetInFOV()
		if target and target.Character then
			local part = target.Character:FindFirstChild(CONFIG.AimPart)
			if part then
				local currentCFrame = Camera.CFrame
				local targetCFrame = CFrame.new(currentCFrame.Position, part.Position)
				local alpha = 1 - math.exp(-CONFIG.AimbotSpeed * dt)
				Camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
			end
		end
	end
 
	-- Atualização de Hitbox, ESP Info e Tracers
	local centerOrigin = Vector2.new(Camera.ViewportSize.X / 2, CONFIG.TracerOriginY)
	local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 
	for _, player in ipairs(Players:GetPlayers()) do
		if isTargetValid(player) then
			local char = player.Character
			local part = char:FindFirstChild(CONFIG.AimPart)
			local hum = char:FindFirstChildOfClass("Humanoid")
 
			-- Hitbox Expander
			if state.hitboxEnabled and part then
				if not originalHitboxSizes[player] then
					originalHitboxSizes[player] = part.Size
				end
				part.Size = Vector3.new(CONFIG.HitboxSize, CONFIG.HitboxSize, CONFIG.HitboxSize)
				part.Transparency = 0.6
				part.CanCollide = false
			elseif originalHitboxSizes[player] and part then
				part.Size = originalHitboxSizes[player]
				part.Transparency = 0
				originalHitboxSizes[player] = nil
			end
 
			-- Atualização do Texto do ESP Info
			if state.espInfoEnabled and espBillboards[player] and hum and myRoot and part then
				local dist = math.floor((part.Position - myRoot.Position).Magnitude)
				local hp = math.floor(hum.Health)
				local txtLabel = espBillboards[player]:FindFirstChild("InfoText")
				if txtLabel then
					txtLabel.Text = string.format("%s\n[%d m] | HP: %d", player.DisplayName, dist, hp)
				end
			end
 
			-- Tracers
			if state.tracersEnabled and part then
				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				local line = getOrCreateTracer(player)
				if onScreen then
					updateTracer(line, centerOrigin, Vector2.new(screenPos.X, screenPos.Y))
				else
					line.Visible = false
				end
			elseif tracerLines[player] then
				tracerLines[player].Visible = false
			end
		else
			if tracerLines[player] then tracerLines[player].Visible = false end
			removeESP(player)
		end
	end
end)
 
----------------------------------------------------------------
-- EVENTOS DE BOTÕES
----------------------------------------------------------------
aimbotBtn.MouseButton1Click:Connect(function()
	state.aimbotEnabled = not state.aimbotEnabled
	setToggleVisual(aimbotPill, aimbotKnob, state.aimbotEnabled)
end)

wallCheckBtn.MouseButton1Click:Connect(function()
	state.wallCheckEnabled = not state.wallCheckEnabled
	setToggleVisual(wallCheckPill, wallCheckKnob, state.wallCheckEnabled)
end)
 
fovCircleBtn.MouseButton1Click:Connect(function()
	state.showFOVCircle = not state.showFOVCircle
	fovCircle.Visible = state.showFOVCircle
	setToggleVisual(fovCirclePill, fovCircleKnob, state.showFOVCircle)
end)
 
aimPartBtn.MouseButton1Click:Connect(function()
	if CONFIG.AimPart == "Head" then
		CONFIG.AimPart = "HumanoidRootPart"
		aimPartLabel.Text = "Peito"
	else
		CONFIG.AimPart = "Head"
		aimPartLabel.Text = "Cabeça"
	end
end)
 
teamSelectBtn.MouseButton1Click:Connect(function()
	local options = getTeamOptions()
	state.selectedTeamIndex = state.selectedTeamIndex + 1
	if state.selectedTeamIndex > #options then
		state.selectedTeamIndex = 1
	end
 
	local currentChoice = options[state.selectedTeamIndex]
	if typeof(currentChoice) == "Instance" then
		teamSelectLabel.Text = currentChoice.Name
		teamSelectLabel.TextColor3 = currentChoice.TeamColor.Color
	else
		teamSelectLabel.Text = tostring(currentChoice)
		teamSelectLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	end
 
	refreshAllESP()
end)
 
hitboxBtn.MouseButton1Click:Connect(function()
	state.hitboxEnabled = not state.hitboxEnabled
	setToggleVisual(hitboxPill, hitboxKnob, state.hitboxEnabled)
end)
 
camFovBtn.MouseButton1Click:Connect(function()
	state.cameraFOVEnabled = not state.cameraFOVEnabled
	setToggleVisual(camFovPill, camFovKnob, state.cameraFOVEnabled)
	if not state.cameraFOVEnabled then
		Camera.FieldOfView = 70
	end
end)
 
espBtn.MouseButton1Click:Connect(function()
	state.espEnabled = not state.espEnabled
	setToggleVisual(espPill, espKnob, state.espEnabled)
	refreshAllESP()
end)

chamsBtn.MouseButton1Click:Connect(function()
	state.chamsEnabled = not state.chamsEnabled
	setToggleVisual(chamsPill, chamsKnob, state.chamsEnabled)
	refreshAllESP()
end)
 
espInfoBtn.MouseButton1Click:Connect(function()
	state.espInfoEnabled = not state.espInfoEnabled
	setToggleVisual(espInfoPill, espInfoKnob, state.espInfoEnabled)
	refreshAllESP()
end)
 
tracerBtn.MouseButton1Click:Connect(function()
	state.tracersEnabled = not state.tracersEnabled
	setToggleVisual(tracerPill, tracerKnob, state.tracersEnabled)
	if not state.tracersEnabled then
		for _, line in pairs(tracerLines) do
			line.Visible = false
		end
	end
end)

bhopBtn.MouseButton1Click:Connect(function()
	state.bhopEnabled = not state.bhopEnabled
	bhopMobileBtn.Visible = state.bhopEnabled
	setToggleVisual(bhopPill, bhopKnob, state.bhopEnabled)
end)
 
----------------------------------------------------------------
-- MONITORAMENTO DE JOGADORES
----------------------------------------------------------------
local function setupPlayerListeners(player)
	if player == LocalPlayer then return end
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		updatePlayerESP(player)
	end)
	player:GetPropertyChangedSignal("Team"):Connect(function()
		task.wait(0.1)
		updatePlayerESP(player)
	end)
end
 
for _, p in ipairs(Players:GetPlayers()) do setupPlayerListeners(p) end
Players.PlayerAdded:Connect(setupPlayerListeners)
 
Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
	if tracerLines[player] then
		tracerLines[player]:Destroy()
		tracerLines[player] = nil
	end
end)