-- =============================================
-- VOLCANO GAKURAN HUB
-- Fly / Noclip / Speed / Jump / ESP / TP / Attach
-- Vocalypse - lifetime + updates via loadstring
-- =============================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Anti-Double
for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
	if v.Name == "VolcanoGakuranHub" then
		v:Destroy()
	end
end

-- ====================== VARIABLES ======================
local highlightsEnabled = true
local namesEnabled = true
local maxDistance = 2000

local noclip = false
local infiniteJump = false
local speedEnabled = false
local flyEnabled = false
local flySpeed = 60
local turbo = false

local isAttached = false
local currentTarget = nil
local attachConnection = nil
local wasFlyingBeforeAttach = false

local character, humanoid, rootPart
local bodyVelocity, bodyGyro
local flyConnection
local noclipConnection
local hue = 0
local lastESPUpdate = 0

-- ====================== CHARACTER ======================
local function updateCharacter()
	character = LocalPlayer.Character
	if not character then
		humanoid = nil
		rootPart = nil
		return
	end
	humanoid = character:FindFirstChildOfClass("Humanoid")
	rootPart = character:FindFirstChild("HumanoidRootPart")
end

-- ====================== FLY ======================
local function stopFly()
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end
	if humanoid then
		humanoid.PlatformStand = false
	end
end

local function startFly()
	stopFly()
	updateCharacter()
	if not character or not humanoid or not rootPart then return end

	humanoid.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = rootPart

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 9e4
	bodyGyro.Parent = rootPart

	flyConnection = RunService.RenderStepped:Connect(function()
		if not flyEnabled or isAttached or not rootPart or not bodyVelocity or not bodyGyro then
			return
		end

		local cam = workspace.CurrentCamera
		local move = Vector3.zero

		if UIS:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end

		local speed = flySpeed * (turbo and 2.2 or 1)
		bodyVelocity.Velocity = move.Magnitude > 0 and move.Unit * speed or Vector3.zero
		bodyGyro.CFrame = cam.CFrame
	end)
end

-- ====================== NOCLIP ======================
local function stopNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
end

local function startNoclip()
	stopNoclip()
	noclipConnection = RunService.Stepped:Connect(function()
		if not noclip or not character then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
end

-- ====================== SETUP ======================
local function onCharacterAdded(char)
	character = char
	humanoid = char:WaitForChild("Humanoid", 8)
	rootPart = char:WaitForChild("HumanoidRootPart", 8)

	isAttached = false
	currentTarget = nil
	wasFlyingBeforeAttach = false
	if attachConnection then
		attachConnection:Disconnect()
		attachConnection = nil
	end

	stopFly()

	task.wait(0.5)

	if speedEnabled and humanoid then
		humanoid.WalkSpeed = turbo and 100 or 50
	end
	if flyEnabled then
		startFly()
	end
	if noclip then
		startNoclip()
	end
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

LocalPlayer.CharacterRemoving:Connect(function()
	stopFly()
	stopNoclip()
	character = nil
	humanoid = nil
	rootPart = nil
end)

-- ====================== ESP ======================
local function getTeamColor(player)
	return (player.Team and player.Team.TeamColor.Color) or Color3.fromRGB(255, 120, 50)
end

local function createNameTag(player)
	if not namesEnabled then return end
	local char = player.Character
	if not char or char:FindFirstChild("VolcanoNameTag") then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "VolcanoNameTag"
	billboard.Adornee = head
	billboard.Size = UDim2.new(4, 0, 1.4, 0)
	billboard.StudsOffset = Vector3.new(0, 3.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = maxDistance

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = player.Name
	text.TextColor3 = getTeamColor(player)
	text.TextStrokeTransparency = 0
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = billboard
	billboard.Parent = char
end

local function createHighlight(player)
	local char = player.Character
	if not char or char:FindFirstChild("VolcanoHighlight") then return end
	local hl = Instance.new("Highlight")
	hl.Name = "VolcanoHighlight"
	hl.Adornee = char
	hl.FillColor = getTeamColor(player)
	hl.OutlineColor = getTeamColor(player)
	hl.FillTransparency = 0.55
	hl.OutlineTransparency = 0.15
	hl.Parent = char
end

local function removeHighlight(player)
	local char = player.Character
	if char then
		local hl = char:FindFirstChild("VolcanoHighlight")
		if hl then hl:Destroy() end
	end
end

local function updateESP()
	local now = os.clock()
	if now - lastESPUpdate < 0.7 then return end
	lastESPUpdate = now

	local localChar = LocalPlayer.Character
	if not localChar or not localChar.PrimaryPart then return end
	local localPos = localChar.PrimaryPart.Position

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local char = p.Character
			if char and char.PrimaryPart then
				local dist = (localPos - char.PrimaryPart.Position).Magnitude
				if highlightsEnabled then
					if dist <= maxDistance then
						createHighlight(p)
					else
						removeHighlight(p)
					end
				end
				if namesEnabled and not char:FindFirstChild("VolcanoNameTag") then
					createNameTag(p)
				end
			end
		end
	end
end

-- ====================== ATTACH ======================
local OFFSET = CFrame.new(0, 0.6, 1.7)

local function StopAttach()
	isAttached = false
	currentTarget = nil
	if attachConnection then
		attachConnection:Disconnect()
		attachConnection = nil
	end

	if wasFlyingBeforeAttach then
		wasFlyingBeforeAttach = false
		flyEnabled = true
		task.delay(0.3, function()
			startFly()
			if flyBtn then
				flyBtn.Text = "FLY : ON (" .. flySpeed .. ")"
				flyBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 80)
			end
		end)
	end
end

local function AttachToPlayer(target)
	if not target or not target.Character then return end
	local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
	local myChar = LocalPlayer.Character
	if not myChar or not tHRP then return end
	local myHRP = myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then return end

	wasFlyingBeforeAttach = flyEnabled

	if flyEnabled then
		flyEnabled = false
		stopFly()
		if flyBtn then
			flyBtn.Text = "FLY : OFF (" .. flySpeed .. ")"
			flyBtn.BackgroundColor3 = Color3.fromRGB(32, 20, 38)
		end
	end

	if attachConnection then
		attachConnection:Disconnect()
		attachConnection = nil
	end

	currentTarget = target
	isAttached = true

	for _, part in ipairs(myChar:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	attachConnection = RunService.Heartbeat:Connect(function()
		if not isAttached or not currentTarget or not currentTarget.Character then
			StopAttach()
			return
		end
		local tHRP = currentTarget.Character:FindFirstChild("HumanoidRootPart")
		local mHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not tHRP or not mHRP then
			StopAttach()
			return
		end
		mHRP.CFrame = tHRP.CFrame * OFFSET
		mHRP.AssemblyLinearVelocity = Vector3.zero
		mHRP.AssemblyAngularVelocity = Vector3.zero
	end)
end

-- ====================== GUI ======================
local gui = Instance.new("ScreenGui")
gui.Name = "VolcanoGakuranHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999
gui.Parent = gethui and gethui() or game:GetService("CoreGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 440, 0, 540)
main.Position = UDim2.new(0.5, -220, 0.5, -270)
main.BackgroundColor3 = Color3.fromRGB(16, 12, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Visible = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 20)

local border = Instance.new("UIStroke")
border.Thickness = 3.5
border.Color = Color3.fromRGB(255, 105, 180)
border.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 55)
header.BackgroundColor3 = Color3.fromRGB(22, 14, 28)
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 20)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "VOLCANO GAKURAN"
title.Font = Enum.Font.GothamBlack
title.TextSize = 19
title.TextColor3 = Color3.fromRGB(255, 130, 180)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -45, 0, 10)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 25, 40)
closeBtn.TextColor3 = Color3.fromRGB(255, 180, 200)
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, -20, 0, 38)
tabFrame.Position = UDim2.new(0, 10, 0, 63)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = main

local function createTab(text, x)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 100, 1, 0)
	btn.Position = UDim2.new(0, x, 0, 0)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.BackgroundColor3 = Color3.fromRGB(35, 22, 40)
	btn.TextColor3 = Color3.fromRGB(220, 180, 200)
	btn.Parent = tabFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)
	return btn
end

local tabMove = createTab("MOVE", 0)
local tabESP = createTab("ESP", 105)
local tabTP = createTab("TP", 210)
local tabAttach = createTab("ATTACH", 315)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -115)
content.Position = UDim2.new(0, 10, 0, 108)
content.BackgroundTransparency = 1
content.Parent = main

local pageMove = Instance.new("Frame")
pageMove.Size = UDim2.new(1, 0, 1, 0)
pageMove.BackgroundTransparency = 1
pageMove.Visible = true
pageMove.Parent = content

local pageESP = Instance.new("Frame")
pageESP.Size = UDim2.new(1, 0, 1, 0)
pageESP.BackgroundTransparency = 1
pageESP.Visible = false
pageESP.Parent = content

local pageTP = Instance.new("Frame")
pageTP.Size = UDim2.new(1, 0, 1, 0)
pageTP.BackgroundTransparency = 1
pageTP.Visible = false
pageTP.Parent = content

local pageAttach = Instance.new("Frame")
pageAttach.Size = UDim2.new(1, 0, 1, 0)
pageAttach.BackgroundTransparency = 1
pageAttach.Visible = false
pageAttach.Parent = content

local function switchTab(tab)
	pageMove.Visible = tab == "MOVE"
	pageESP.Visible = tab == "ESP"
	pageTP.Visible = tab == "TP"
	pageAttach.Visible = tab == "ATTACH"
	tabMove.BackgroundColor3 = tab == "MOVE" and Color3.fromRGB(255, 90, 140) or Color3.fromRGB(35, 22, 40)
	tabESP.BackgroundColor3 = tab == "ESP" and Color3.fromRGB(255, 90, 140) or Color3.fromRGB(35, 22, 40)
	tabTP.BackgroundColor3 = tab == "TP" and Color3.fromRGB(255, 90, 140) or Color3.fromRGB(35, 22, 40)
	tabAttach.BackgroundColor3 = tab == "ATTACH" and Color3.fromRGB(255, 90, 140) or Color3.fromRGB(35, 22, 40)
end

tabMove.MouseButton1Click:Connect(function() switchTab("MOVE") end)
tabESP.MouseButton1Click:Connect(function() switchTab("ESP") end)
tabTP.MouseButton1Click:Connect(function() switchTab("TP") end)
tabAttach.MouseButton1Click:Connect(function() switchTab("ATTACH") end)

local function createMoveBtn(text, y)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 44)
	btn.Position = UDim2.new(0, 0, 0, y)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.BackgroundColor3 = Color3.fromRGB(32, 20, 38)
	btn.TextColor3 = Color3.fromRGB(255, 210, 230)
	btn.Parent = pageMove
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)
	return btn
end

local noclipBtn = createMoveBtn("NOCLIP : OFF", 8)
local speedBtn = createMoveBtn("SPEED : OFF", 62)
local jumpBtn = createMoveBtn("INFINITE JUMP : OFF", 116)
local flyBtn = createMoveBtn("FLY : OFF (" .. flySpeed .. ")", 170)

local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(1, 0, 0, 30)
sliderFrame.Position = UDim2.new(0, 0, 0, 235)
sliderFrame.BackgroundColor3 = Color3.fromRGB(40, 25, 48)
sliderFrame.Parent = pageMove
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 15)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(flySpeed / 500, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
sliderFill.Parent = sliderFrame
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 15)

local sliderKnob = Instance.new("TextButton")
sliderKnob.Size = UDim2.new(0, 28, 0, 28)
sliderKnob.Position = UDim2.new(sliderFill.Size.X.Scale - 0.05, 0, 0, 1)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 140, 200)
sliderKnob.Text = ""
sliderKnob.Parent = sliderFrame
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

local draggingSlider = false
sliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = true end
end)
sliderKnob.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
end)

local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(1, 0, 0, 25)
distLabel.Position = UDim2.new(0, 0, 0, 8)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Distance Max : " .. maxDistance
distLabel.TextColor3 = Color3.fromRGB(255, 200, 220)
distLabel.Font = Enum.Font.Gotham
distLabel.TextSize = 15
distLabel.Parent = pageESP

local distBox = Instance.new("TextBox")
distBox.Size = UDim2.new(1, 0, 0, 36)
distBox.Position = UDim2.new(0, 0, 0, 38)
distBox.BackgroundColor3 = Color3.fromRGB(35, 22, 42)
distBox.Text = tostring(maxDistance)
distBox.TextColor3 = Color3.fromRGB(255, 210, 230)
distBox.Font = Enum.Font.Gotham
distBox.TextSize = 15
distBox.Parent = pageESP
Instance.new("UICorner", distBox).CornerRadius = UDim.new(0, 9)

distBox.FocusLost:Connect(function()
	local num = tonumber(distBox.Text)
	if num and num > 0 then
		maxDistance = num
		distLabel.Text = "Distance Max : " .. maxDistance
	end
end)

local hlBtn = Instance.new("TextButton")
hlBtn.Size = UDim2.new(1, 0, 0, 44)
hlBtn.Position = UDim2.new(0, 0, 0, 90)
hlBtn.Text = "HIGHLIGHTS : ON"
hlBtn.Font = Enum.Font.GothamBold
hlBtn.TextSize = 15
hlBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 80)
hlBtn.TextColor3 = Color3.new(1, 1, 1)
hlBtn.Parent = pageESP
Instance.new("UICorner", hlBtn).CornerRadius = UDim.new(0, 11)

local nameBtn = Instance.new("TextButton")
nameBtn.Size = UDim2.new(1, 0, 0, 44)
nameBtn.Position = UDim2.new(0, 0, 0, 148)
nameBtn.Text = "NAMES : ON"
nameBtn.Font = Enum.Font.GothamBold
nameBtn.TextSize = 15
nameBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 80)
nameBtn.TextColor3 = Color3.new(1, 1, 1)
nameBtn.Parent = pageESP
Instance.new("UICorner", nameBtn).CornerRadius = UDim.new(0, 11)

local tpSearch = Instance.new("TextBox")
tpSearch.Size = UDim2.new(1, 0, 0, 36)
tpSearch.Position = UDim2.new(0, 0, 0, 5)
tpSearch.BackgroundColor3 = Color3.fromRGB(35, 22, 42)
tpSearch.PlaceholderText = "Rechercher un joueur..."
tpSearch.PlaceholderColor3 = Color3.fromRGB(160, 130, 150)
tpSearch.Text = ""
tpSearch.TextColor3 = Color3.fromRGB(255, 210, 230)
tpSearch.Font = Enum.Font.Gotham
tpSearch.TextSize = 14
tpSearch.ClearTextOnFocus = false
tpSearch.Parent = pageTP
Instance.new("UICorner", tpSearch).CornerRadius = UDim.new(0, 9)

local tpScroll = Instance.new("ScrollingFrame")
tpScroll.Size = UDim2.new(1, 0, 1, -50)
tpScroll.Position = UDim2.new(0, 0, 0, 50)
tpScroll.BackgroundColor3 = Color3.fromRGB(24, 15, 30)
tpScroll.BorderSizePixel = 0
tpScroll.ScrollBarThickness = 5
tpScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tpScroll.Parent = pageTP
Instance.new("UICorner", tpScroll).CornerRadius = UDim.new(0, 9)

local tpList = Instance.new("UIListLayout")
tpList.SortOrder = Enum.SortOrder.Name
tpList.Padding = UDim.new(0, 5)
tpList.Parent = tpScroll

local attachSearch = Instance.new("TextBox")
attachSearch.Size = UDim2.new(1, 0, 0, 36)
attachSearch.Position = UDim2.new(0, 0, 0, 5)
attachSearch.BackgroundColor3 = Color3.fromRGB(35, 22, 42)
attachSearch.PlaceholderText = "Rechercher un joueur..."
attachSearch.PlaceholderColor3 = Color3.fromRGB(160, 130, 150)
attachSearch.Text = ""
attachSearch.TextColor3 = Color3.fromRGB(255, 210, 230)
attachSearch.Font = Enum.Font.Gotham
attachSearch.TextSize = 14
attachSearch.ClearTextOnFocus = false
attachSearch.Parent = pageAttach
Instance.new("UICorner", attachSearch).CornerRadius = UDim.new(0, 9)

local attachScroll = Instance.new("ScrollingFrame")
attachScroll.Size = UDim2.new(1, 0, 1, -100)
attachScroll.Position = UDim2.new(0, 0, 0, 50)
attachScroll.BackgroundColor3 = Color3.fromRGB(24, 15, 30)
attachScroll.BorderSizePixel = 0
attachScroll.ScrollBarThickness = 5
attachScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
attachScroll.Parent = pageAttach
Instance.new("UICorner", attachScroll).CornerRadius = UDim.new(0, 9)

local attachList = Instance.new("UIListLayout")
attachList.SortOrder = Enum.SortOrder.Name
attachList.Padding = UDim.new(0, 5)
attachList.Parent = attachScroll

local detachBtn = Instance.new("TextButton")
detachBtn.Size = UDim2.new(1, 0, 0, 42)
detachBtn.Position = UDim2.new(0, 0, 1, -48)
detachBtn.Text = "DETACHER (X)"
detachBtn.Font = Enum.Font.GothamBold
detachBtn.TextSize = 15
detachBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 50)
detachBtn.TextColor3 = Color3.fromRGB(255, 200, 220)
detachBtn.Parent = pageAttach
Instance.new("UICorner", detachBtn).CornerRadius = UDim.new(0, 11)

local function createTPButton(player)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -8, 0, 34)
	btn.BackgroundColor3 = Color3.fromRGB(40, 25, 48)
	btn.Text = "->  " .. player.Name
	btn.TextColor3 = Color3.fromRGB(255, 210, 230)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = tpScroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

	btn.MouseButton1Click:Connect(function()
		local myChar = LocalPlayer.Character
		local targetChar = player.Character
		if myChar and myChar.PrimaryPart and targetChar and targetChar.PrimaryPart then
			myChar:PivotTo(targetChar.PrimaryPart.CFrame + Vector3.new(0, 3, 0))
			if flyEnabled then
				task.delay(0.25, startFly)
			end
		end
	end)
end

local function refreshTP(filter)
	for _, c in ipairs(tpScroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	filter = filter and string.lower(filter) or ""
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			if filter == "" or string.find(string.lower(p.Name), filter, 1, true) then
				createTPButton(p)
			end
		end
	end
	tpScroll.CanvasSize = UDim2.new(0, 0, 0, tpList.AbsoluteContentSize.Y + 10)
end

local function createAttachButton(player)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -8, 0, 34)
	btn.BackgroundColor3 = Color3.fromRGB(40, 25, 48)
	btn.Text = "->  " .. player.Name
	btn.TextColor3 = Color3.fromRGB(255, 210, 230)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = attachScroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
	btn.MouseButton1Click:Connect(function()
		AttachToPlayer(player)
	end)
end

local function refreshAttach(filter)
	for _, c in ipairs(attachScroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	filter = filter and string.lower(filter) or ""
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			if filter == "" or string.find(string.lower(p.Name), filter, 1, true) then
				createAttachButton(p)
			end
		end
	end
	attachScroll.CanvasSize = UDim2.new(0, 0, 0, attachList.AbsoluteContentSize.Y + 10)
end

noclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	noclipBtn.Text = noclip and "NOCLIP : ON" or "NOCLIP : OFF"
	noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(32, 20, 38)
	if noclip then startNoclip() else stopNoclip() end
end)

speedBtn.MouseButton1Click:Connect(function()
	speedEnabled = not speedEnabled
	if humanoid then
		humanoid.WalkSpeed = speedEnabled and (turbo and 100 or 50) or 16
	end
	speedBtn.Text = speedEnabled and "SPEED : ON" or "SPEED : OFF"
	speedBtn.BackgroundColor3 = speedEnabled and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(32, 20, 38)
end)

jumpBtn.MouseButton1Click:Connect(function()
	infiniteJump = not infiniteJump
	jumpBtn.Text = infiniteJump and "INFINITE JUMP : ON" or "INFINITE JUMP : OFF"
	jumpBtn.BackgroundColor3 = infiniteJump and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(32, 20, 38)
end)

flyBtn.MouseButton1Click:Connect(function()
	flyEnabled = not flyEnabled
	flyBtn.Text = flyEnabled and ("FLY : ON (" .. flySpeed .. ")") or ("FLY : OFF (" .. flySpeed .. ")")
	flyBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(32, 20, 38)
	if flyEnabled then startFly() else stopFly() end
end)

hlBtn.MouseButton1Click:Connect(function()
	highlightsEnabled = not highlightsEnabled
	hlBtn.Text = highlightsEnabled and "HIGHLIGHTS : ON" or "HIGHLIGHTS : OFF"
	hlBtn.BackgroundColor3 = highlightsEnabled and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(160, 40, 60)
	if not highlightsEnabled then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then removeHighlight(p) end
		end
	end
end)

nameBtn.MouseButton1Click:Connect(function()
	namesEnabled = not namesEnabled
	nameBtn.Text = namesEnabled and "NAMES : ON" or "NAMES : OFF"
	nameBtn.BackgroundColor3 = namesEnabled and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(160, 40, 60)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local char = p.Character
			if char then
				local tag = char:FindFirstChild("VolcanoNameTag")
				if tag then tag:Destroy() end
			end
			if namesEnabled then createNameTag(p) end
		end
	end
end)

detachBtn.MouseButton1Click:Connect(StopAttach)

tpSearch:GetPropertyChangedSignal("Text"):Connect(function()
	refreshTP(tpSearch.Text)
end)
attachSearch:GetPropertyChangedSignal("Text"):Connect(function()
	refreshAttach(attachSearch.Text)
end)

RunService.RenderStepped:Connect(function()
	if draggingSlider then
		local mouse = UIS:GetMouseLocation()
		local pos = sliderFrame.AbsolutePosition
		local size = sliderFrame.AbsoluteSize
		local relative = math.clamp(mouse.X - pos.X, 0, size.X)
		local scale = relative / size.X
		flySpeed = math.floor(scale * 490 + 10)
		sliderFill.Size = UDim2.new(scale, 0, 1, 0)
		sliderKnob.Position = UDim2.new(scale - 0.05, 0, 0, 1)
		flyBtn.Text = (flyEnabled and "FLY : ON (" or "FLY : OFF (") .. flySpeed .. ")"
	end

	hue = (hue + 0.004) % 1
	local color = Color3.fromHSV(hue, 0.85, 1)
	title.TextColor3 = color
	border.Color = color
	sliderFill.BackgroundColor3 = color
	sliderKnob.BackgroundColor3 = color
end)

task.spawn(function()
	while true do
		if highlightsEnabled or namesEnabled then
			updateESP()
		end
		task.wait(0.75)
	end
end)

UIS.JumpRequest:Connect(function()
	if infiniteJump and humanoid and humanoid.Parent then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		turbo = true
		if speedEnabled and humanoid then humanoid.WalkSpeed = 100 end
	elseif input.KeyCode == Enum.KeyCode.X then
		StopAttach()
	elseif input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.F4 then
		main.Visible = not main.Visible
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		turbo = false
		if speedEnabled and humanoid then humanoid.WalkSpeed = 50 end
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	main.Visible = false
end)

local function setupPlayer(player)
	if player == LocalPlayer then return end
	player.CharacterAdded:Connect(function()
		task.wait(0.6)
		if namesEnabled then createNameTag(player) end
	end)
	if player.Character and namesEnabled then
		task.delay(0.4, function() createNameTag(player) end)
	end
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end

Players.PlayerAdded:Connect(function(p)
	setupPlayer(p)
	task.wait(0.5)
	refreshTP(tpSearch.Text)
	refreshAttach(attachSearch.Text)
end)

Players.PlayerRemoving:Connect(function(p)
	if currentTarget == p then StopAttach() end
	refreshTP(tpSearch.Text)
	refreshAttach(attachSearch.Text)
end)

refreshTP("")
refreshAttach("")

print("VOLCANO GAKURAN HUB charge !")
print("-> RightShift ou F4 pour ouvrir / fermer")
print("-> X pour detacher")
