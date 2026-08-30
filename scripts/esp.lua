-- =============================================
-- VOLCANO GAKURAN ESP
-- by vulcalypse
-- =============================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESP_COLOR = Color3.fromRGB(64, 224, 208)
local HIT_GREEN = Color3.fromRGB(30, 255, 90)
local HIT_RED = Color3.fromRGB(255, 40, 55)
local HEALTH_NEAR, HEALTH_HIDE = 18, 160
local HITBOX_RADIUS, HITBOX_DIST = 6.6, 140
local FAN_SEGMENTS, FAN_ANGLE, FACE_ANGLE = 8, 100, 62
local FAN_TRANS_GREEN, FAN_TRANS_RED = 0.42, 0.32

local parentGui = gethui and gethui() or game:GetService("CoreGui")
for _, v in ipairs(parentGui:GetChildren()) do
	if v.Name == "VolcanoGakuranESP" then v:Destroy() end
end

local highlightsEnabled, namesEnabled, healthEnabled, selfHealthEnabled = true, true, true, true
local hitboxEnabled = false
local maxDistance = 2000
local hitboxConnection
local scriptAlive, lastESP = true, 0
local connections = table.create(16)
local function track(c) connections[#connections + 1] = c return c end

local function hpCol(r)
	if r > 0.6 then return Color3.fromRGB(255, 170, 200) end
	if r > 0.3 then return Color3.fromRGB(255, 190, 90) end
	return Color3.fromRGB(255, 80, 90)
end

local function healthFade(dist)
	if dist <= HEALTH_NEAR then return 0 end
	if dist >= HEALTH_HIDE then return 1 end
	local t = (dist - HEALTH_NEAR) / (HEALTH_HIDE - HEALTH_NEAR)
	return t * t
end

local function updateHealthTag(player)
	local char = player.Character
	if not char then return end
	local tag = char:FindFirstChild("VolcanoHealthTag")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not tag or not hum then return end
	local myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
	local root = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
	local dist = 0
	if myRoot and root then dist = (myRoot.Position - root.Position).Magnitude end
	if dist >= HEALTH_HIDE and player ~= LocalPlayer then tag.Enabled = false return end
	tag.Enabled = true
	local fade = (player == LocalPlayer) and 0 or healthFade(dist)
	local scale = player == LocalPlayer and 1 or math.clamp(1 - fade * 0.85, 0.18, 1)
	tag.Size = UDim2.new(0, math.floor(118 * scale), 0, math.floor(28 * scale))
	local wrap = tag:FindFirstChild("Wrap")
	if wrap then
		wrap.BackgroundTransparency = 0.12 + fade * 0.82
		local stroke = wrap:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Transparency = 0.15 + fade * 0.85 end
		for _, child in ipairs(wrap:GetChildren()) do
			if child:IsA("TextLabel") then
				child.TextTransparency = fade
				child.TextStrokeTransparency = 0.35 + fade * 0.65
			end
		end
	end
	local fill = wrap and wrap:FindFirstChild("BarBg") and wrap.BarBg:FindFirstChild("Fill")
	local bg = wrap and wrap:FindFirstChild("BarBg")
	local label = wrap and wrap:FindFirstChild("HPText")
	local ratio = hum.Health / math.max(hum.MaxHealth, 1)
	if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
	local col = hpCol(ratio)
	if bg then bg.BackgroundTransparency = fade * 0.7 end
	if fill then
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		fill.BackgroundColor3 = col
		fill.BackgroundTransparency = fade * 0.6
	end
	if label then
		label.Text = math.floor(hum.Health + 0.5) .. "/" .. math.floor(hum.MaxHealth + 0.5)
		label.TextColor3 = col
		label.Visible = fade < 0.55
	end
end

local function createHealthTag(player)
	if player == LocalPlayer then
		if not selfHealthEnabled then return end
	elseif not healthEnabled then
		return
	end
	local char = player.Character
	if not char or char:FindFirstChild("VolcanoHealthTag") then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name, bb.Adornee, bb.Size = "VolcanoHealthTag", head, UDim2.new(0, 118, 0, 28)
	bb.StudsOffset, bb.AlwaysOnTop, bb.MaxDistance, bb.ResetOnSpawn = Vector3.new(0, 2.15, 0), true, HEALTH_HIDE, false
	local wrap = Instance.new("Frame")
	wrap.Name, wrap.Size, wrap.BackgroundColor3, wrap.BackgroundTransparency, wrap.BorderSizePixel, wrap.Parent = "Wrap", UDim2.new(1, 0, 1, 0), Color3.fromRGB(36, 18, 28), 0.12, 0, bb
	Instance.new("UICorner", wrap).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent = Color3.fromRGB(255, 150, 190), 1.2, 0.15, wrap
	local left = Instance.new("TextLabel")
	left.Size, left.Position, left.BackgroundTransparency, left.Text, left.TextScaled, left.Font, left.Parent = UDim2.new(0, 16, 1, 0), UDim2.new(0, 2, 0, 0), 1, "🌸", true, Enum.Font.GothamBold, wrap
	local right = Instance.new("TextLabel")
	right.Size, right.Position, right.BackgroundTransparency, right.Text, right.TextScaled, right.Font, right.Parent = UDim2.new(0, 16, 1, 0), UDim2.new(1, -18, 0, 0), 1, "🌸", true, Enum.Font.GothamBold, wrap
	local bg = Instance.new("Frame")
	bg.Name, bg.Size, bg.Position, bg.BackgroundColor3, bg.BorderSizePixel, bg.Parent = "BarBg", UDim2.new(1, -40, 0, 7), UDim2.new(0, 20, 0, 5), Color3.fromRGB(22, 10, 16), 0, wrap
	Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.Name, fill.Size, fill.BackgroundColor3, fill.BorderSizePixel, fill.Parent = "Fill", UDim2.new(1, 0, 1, 0), Color3.fromRGB(255, 170, 200), 0, bg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	local hp = Instance.new("TextLabel")
	hp.Name, hp.Size, hp.Position, hp.BackgroundTransparency, hp.Font, hp.TextSize = "HPText", UDim2.new(1, -36, 0, 12), UDim2.new(0, 18, 0, 13), 1, Enum.Font.GothamBold, 10
	hp.TextStrokeTransparency, hp.TextColor3, hp.Text, hp.Parent = 0.35, Color3.fromRGB(255, 170, 200), "0/0", wrap
	bb.Parent = char
	updateHealthTag(player)
end

local function removeHealthTag(player)
	local char = player.Character
	local tag = char and char:FindFirstChild("VolcanoHealthTag")
	if tag then tag:Destroy() end
end

local function createNameTag(player)
	if not namesEnabled then return end
	local char = player.Character
	if not char or char:FindFirstChild("VolcanoNameTag") then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name, bb.Adornee, bb.Size = "VolcanoNameTag", head, UDim2.new(4, 0, 1.15, 0)
	bb.StudsOffset, bb.AlwaysOnTop, bb.MaxDistance = Vector3.new(0, 3.15, 0), true, maxDistance
	local t = Instance.new("TextLabel")
	t.Size, t.BackgroundTransparency, t.Text = UDim2.new(1, 0, 1, 0), 1, "🌸 " .. player.Name
	t.TextColor3, t.TextStrokeTransparency, t.TextScaled, t.Font, t.Parent = ESP_COLOR, 0, true, Enum.Font.GothamBold, bb
	bb.Parent = char
end

local function createHighlight(player)
	local char = player.Character
	if not char or char:FindFirstChild("VolcanoHighlight") then return end
	local hl = Instance.new("Highlight")
	hl.Name, hl.Adornee, hl.FillColor, hl.OutlineColor = "VolcanoHighlight", char, ESP_COLOR, ESP_COLOR
	hl.FillTransparency, hl.OutlineTransparency, hl.Parent = 0.55, 0.15, char
end

local function removeHighlight(player)
	local char = player.Character
	local hl = char and char:FindFirstChild("VolcanoHighlight")
	if hl then hl:Destroy() end
end

local function styleHitPart(p, color, trans)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.Transparency = trans
end

local function isFacingMe(hrp)
	local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return false end
	local toMe = myRoot.Position - hrp.Position
	toMe = Vector3.new(toMe.X, 0, toMe.Z)
	local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	if toMe.Magnitude < 0.2 or look.Magnitude < 0.05 then return false end
	return look.Unit:Dot(toMe.Unit) >= math.cos(math.rad(FACE_ANGLE))
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local groundCache = {}

local function groundPos(hrp, char, player)
	local now = os.clock()
	local cached = groundCache[player]
	if cached and (now - cached.t) < 0.15 then
		return Vector3.new(hrp.Position.X, cached.y, hrp.Position.Z)
	end
	rayParams.FilterDescendantsInstances = {char}
	local hit = workspace:Raycast(hrp.Position + Vector3.new(0, 1.2, 0), Vector3.new(0, -10, 0), rayParams)
	local y = hit and (hit.Position.Y + 0.03) or (hrp.Position.Y - 3.05)
	groundCache[player] = {y = y, t = now}
	return Vector3.new(hrp.Position.X, y, hrp.Position.Z)
end

local function removeHitbox(player)
	local char = player.Character
	local folder = char and char:FindFirstChild("VolcanoHitbox")
	if folder then folder:Destroy() end
end

local function createHitbox(player)
	if player == LocalPlayer then return end
	local char = player.Character
	if not char or char:FindFirstChild("VolcanoHitbox") then return end
	if not char:FindFirstChild("HumanoidRootPart") then return end
	local folder = Instance.new("Folder")
	folder.Name = "VolcanoHitbox"
	folder.Parent = char
	local step = FAN_ANGLE / FAN_SEGMENTS
	local width = 2 * HITBOX_RADIUS * math.tan(math.rad(step * 0.58))
	for i = 1, FAN_SEGMENTS do
		local w = Instance.new("WedgePart")
		w.Name = "Fan" .. i
		w.Size = Vector3.new(width, 0.04, HITBOX_RADIUS)
		styleHitPart(w, HIT_GREEN, FAN_TRANS_GREEN)
		w.Parent = folder
	end
end

local function updateHitbox(player)
	if player == LocalPlayer then removeHitbox(player) return end
	local char = player.Character
	local folder = char and char:FindFirstChild("VolcanoHitbox")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not folder or not hrp then return end
	local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	if look.Magnitude < 0.05 then look = Vector3.new(0, 0, -1) else look = look.Unit end
	local pos = groundPos(hrp, char, player)
	local base = CFrame.lookAt(pos, pos + look)
	local facing = isFacingMe(hrp)
	local col = facing and HIT_RED or HIT_GREEN
	local fanTrans = facing and FAN_TRANS_RED or FAN_TRANS_GREEN
	local step = FAN_ANGLE / FAN_SEGMENTS
	local startAng = -FAN_ANGLE * 0.5
	for i = 1, FAN_SEGMENTS do
		local fan = folder:FindFirstChild("Fan" .. i)
		if fan then
			local mid = math.rad(startAng + (i - 0.5) * step)
			fan.CFrame = base * CFrame.Angles(0, mid, 0) * CFrame.new(0, 0, -HITBOX_RADIUS * 0.5)
			fan.Color = col
			fan.Transparency = fanTrans
		end
	end
end

local function clearAllHitboxes()
	for _, p in ipairs(Players:GetPlayers()) do removeHitbox(p) end
	table.clear(groundCache)
end

local function stopHitbox()
	if hitboxConnection then hitboxConnection:Disconnect() hitboxConnection = nil end
	clearAllHitboxes()
end

local function startHitbox()
	stopHitbox()
	hitboxConnection = RunService.Heartbeat:Connect(function()
		if not (scriptAlive and hitboxEnabled) then return end
		local myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
		if not myRoot then return end
		local pos = myRoot.Position
		removeHitbox(LocalPlayer)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				local char = p.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and (pos - root.Position).Magnitude <= HITBOX_DIST then
					if not char:FindFirstChild("VolcanoHitbox") then createHitbox(p) end
					updateHitbox(p)
				else
					removeHitbox(p)
					groundCache[p] = nil
				end
			end
		end
	end)
end

local function clearAllESP()
	for _, p in ipairs(Players:GetPlayers()) do
		removeHighlight(p)
		removeHealthTag(p)
		removeHitbox(p)
		local char = p.Character
		local tag = char and char:FindFirstChild("VolcanoNameTag")
		if tag then tag:Destroy() end
	end
end

local function updateESP()
	if not scriptAlive then return end
	local now = os.clock()
	if now - lastESP < 0.25 then return end
	lastESP = now
	local myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
	if not myRoot then return end
	local pos = myRoot.Position
	if selfHealthEnabled then createHealthTag(LocalPlayer) updateHealthTag(LocalPlayer) end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local char = p.Character
			local root = char and char.PrimaryPart
			if root then
				local ok = (pos - root.Position).Magnitude <= maxDistance
				if highlightsEnabled then
					if ok then createHighlight(p) else removeHighlight(p) end
				else
					removeHighlight(p)
				end
				if namesEnabled then
					if ok then createNameTag(p) else
						local tag = char:FindFirstChild("VolcanoNameTag")
						if tag then tag:Destroy() end
					end
				end
				if healthEnabled then
					if ok then createHealthTag(p) updateHealthTag(p) else removeHealthTag(p) end
				end
			end
		end
	end
end

-- GUI ESP only
local COL_BG = Color3.fromRGB(22, 14, 20)
local COL_ROW = Color3.fromRGB(38, 22, 34)
local COL_ACCENT = Color3.fromRGB(255, 145, 190)
local COL_TEXT = Color3.fromRGB(255, 230, 238)
local COL_MUTED = Color3.fromRGB(190, 150, 168)

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "VolcanoGakuranESP", false, true, 99999
gui.Parent = parentGui

local main = Instance.new("Frame")
main.Size, main.Position = UDim2.new(0, 320, 0, 430), UDim2.new(0, 24, 0.5, -215)
main.BackgroundColor3, main.BorderSizePixel = COL_BG, 0
main.Active, main.Draggable, main.Visible, main.Parent = true, true, true, gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
local stk = Instance.new("UIStroke")
stk.Color, stk.Thickness, stk.Parent = Color3.fromRGB(255, 140, 185), 1.4, main

local title = Instance.new("TextLabel")
title.Size, title.Position, title.BackgroundTransparency = UDim2.new(1, -50, 0, 42), UDim2.new(0, 14, 0, 8), 1
title.Text, title.Font, title.TextSize, title.TextColor3, title.TextXAlignment = "🌸  volcano esp", Enum.Font.GothamBold, 16, COL_ACCENT, Enum.TextXAlignment.Left
title.Parent = main

local function iconBtn(txt, x)
	local b = Instance.new("TextButton")
	b.Size, b.Position = UDim2.new(0, 42, 0, 28), UDim2.new(1, x, 0, 12)
	b.BackgroundColor3, b.Text, b.Font, b.TextSize, b.TextColor3 = Color3.fromRGB(50, 28, 42), txt, Enum.Font.GothamBold, 12, COL_TEXT
	b.Parent = main
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end
local endBtn = iconBtn("End", -92)
local closeBtn = iconBtn("✕", -44)

local list = Instance.new("Frame")
list.Size, list.Position, list.BackgroundTransparency = UDim2.new(1, -24, 1, -70), UDim2.new(0, 12, 0, 54), 1
list.Parent = main
local lay = Instance.new("UIListLayout")
lay.Padding, lay.Parent = UDim.new(0, 8), list

local refreshUI
local rows = {}

local function makeToggle(label, getter, setter)
	local row = Instance.new("TextButton")
	row.Size, row.BackgroundColor3, row.Text, row.Parent = UDim2.new(1, 0, 0, 40), COL_ROW, "", list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
	local name = Instance.new("TextLabel")
	name.Size, name.Position, name.BackgroundTransparency = UDim2.new(1, -90, 1, 0), UDim2.new(0, 12, 0, 0), 1
	name.Text, name.Font, name.TextSize, name.TextColor3, name.TextXAlignment = label, Enum.Font.Gotham, 14, COL_TEXT, Enum.TextXAlignment.Left
	name.Parent = row
	local val = Instance.new("TextLabel")
	val.Size, val.Position = UDim2.new(0, 70, 0, 24), UDim2.new(1, -82, 0.5, -12)
	val.Font, val.TextSize, val.Parent = Enum.Font.GothamBold, 12, row
	Instance.new("UICorner", val).CornerRadius = UDim.new(0, 8)
	rows[#rows + 1] = {val = val, getter = getter}
	row.MouseButton1Click:Connect(function()
		if scriptAlive then setter() refreshUI() end
	end)
end

makeToggle("highlights", function() return highlightsEnabled end, function()
	highlightsEnabled = not highlightsEnabled
	if not highlightsEnabled then
		for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then removeHighlight(p) end end
	end
end)
makeToggle("names", function() return namesEnabled end, function()
	namesEnabled = not namesEnabled
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local char = p.Character
			local tag = char and char:FindFirstChild("VolcanoNameTag")
			if tag then tag:Destroy() end
			if namesEnabled then createNameTag(p) end
		end
	end
end)
makeToggle("vie joueurs", function() return healthEnabled end, function()
	healthEnabled = not healthEnabled
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			removeHealthTag(p)
			if healthEnabled then createHealthTag(p) end
		end
	end
end)
makeToggle("ma vie", function() return selfHealthEnabled end, function()
	selfHealthEnabled = not selfHealthEnabled
	removeHealthTag(LocalPlayer)
	if selfHealthEnabled then createHealthTag(LocalPlayer) end
end)
makeToggle("hitbox vis", function() return hitboxEnabled end, function()
	hitboxEnabled = not hitboxEnabled
	if hitboxEnabled then startHitbox() else stopHitbox() end
end)

local distRow = Instance.new("Frame")
distRow.Size, distRow.BackgroundColor3, distRow.Parent = UDim2.new(1, 0, 0, 40), COL_ROW, list
Instance.new("UICorner", distRow).CornerRadius = UDim.new(0, 10)
local distLab = Instance.new("TextLabel")
distLab.Size, distLab.Position, distLab.BackgroundTransparency = UDim2.new(0.45, 0, 1, 0), UDim2.new(0, 12, 0, 0), 1
distLab.Text, distLab.Font, distLab.TextSize, distLab.TextColor3, distLab.TextXAlignment = "distance", Enum.Font.Gotham, 14, COL_TEXT, Enum.TextXAlignment.Left
distLab.Parent = distRow
local function mini(txt, x, fn)
	local b = Instance.new("TextButton")
	b.Size, b.Position = UDim2.new(0, 36, 0, 24), UDim2.new(1, x, 0.5, -12)
	b.BackgroundColor3, b.Text, b.Font, b.TextSize, b.TextColor3 = Color3.fromRGB(55, 30, 45), txt, Enum.Font.GothamBold, 12, COL_ACCENT
	b.Parent = distRow
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(fn)
end
local distVal = Instance.new("TextLabel")
distVal.Size, distVal.Position = UDim2.new(0, 58, 0, 24), UDim2.new(1, -110, 0.5, -12)
distVal.BackgroundColor3, distVal.Font, distVal.TextSize, distVal.TextColor3 = Color3.fromRGB(55, 30, 45), Enum.Font.GothamBold, 12, COL_ACCENT
distVal.Parent = distRow
Instance.new("UICorner", distVal).CornerRadius = UDim.new(0, 8)
mini("-", -168, function() maxDistance = math.max(200, maxDistance - 200) refreshUI() end)
mini("+", -44, function() maxDistance += 200 refreshUI() end)

refreshUI = function()
	for _, r in ipairs(rows) do
		local on = r.getter()
		r.val.Text = on and "ON" or "OFF"
		r.val.BackgroundColor3 = Color3.fromRGB(55, 30, 45)
		r.val.TextColor3 = on and Color3.fromRGB(120, 255, 180) or Color3.fromRGB(255, 140, 160)
	end
	distVal.Text = tostring(maxDistance)
end

local function UnloadScript()
	if not scriptAlive then return end
	scriptAlive = false
	highlightsEnabled, namesEnabled, healthEnabled, selfHealthEnabled, hitboxEnabled = false, false, false, false, false
	stopHitbox()
	clearAllESP()
	for i = 1, #connections do pcall(function() connections[i]:Disconnect() end) end
	if gui then gui:Destroy() end
end

closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)
endBtn.MouseButton1Click:Connect(UnloadScript)

track(UIS.InputBegan:Connect(function(input)
	if not scriptAlive then return end
	if input.KeyCode == Enum.KeyCode.Insert then
		main.Visible = not main.Visible
	elseif input.KeyCode == Enum.KeyCode.End then
		UnloadScript()
	end
end))

local function setupPlayer(player)
	if player == LocalPlayer then return end
	track(player.CharacterAdded:Connect(function()
		task.wait(0.4)
		if not scriptAlive then return end
		if namesEnabled then createNameTag(player) end
		if healthEnabled then createHealthTag(player) end
	end))
	if player.Character then
		if namesEnabled then createNameTag(player) end
		if healthEnabled then createHealthTag(player) end
	end
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
track(Players.PlayerAdded:Connect(setupPlayer))
track(Players.PlayerRemoving:Connect(function(p)
	removeHitbox(p)
	groundCache[p] = nil
end))
track(LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.35)
	if scriptAlive and selfHealthEnabled then createHealthTag(LocalPlayer) end
end))

task.spawn(function()
	while scriptAlive do
		updateESP()
		task.wait(0.25)
	end
end)

refreshUI()
print("volcano esp | by vulcalypse | Insert = menu")
