-- =============================================
-- 🌋🌸 VOLCANO GAKURAN HUB 🌸🌋
-- by vulcalypse
-- =============================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local ZERO = Vector3.zero
local ESP_COLOR = Color3.fromRGB(64, 224, 208)
local HIT_GREEN = Color3.fromRGB(30, 255, 90)
local HIT_RED = Color3.fromRGB(255, 40, 55)

local HEALTH_NEAR, HEALTH_FAR, HEALTH_HIDE = 18, 90, 160
local HITBOX_RADIUS, HITBOX_DIST = 6.6, 140
local FAN_SEGMENTS, FAN_ANGLE, FACE_ANGLE = 8, 100, 62
local FAN_TRANS_GREEN, FAN_TRANS_RED = 0.42, 0.32
local HIT_RANGE = 10

local parentGui = gethui and gethui() or game:GetService("CoreGui")
for _, v in ipairs(parentGui:GetChildren()) do
	if v.Name == "VolcanoGakuranHub" then v:Destroy() end
end

local highlightsEnabled, namesEnabled, healthEnabled, selfHealthEnabled = true, true, true, true
local hitboxEnabled, combatEnabled = false, true
local maxDistance, flySpeed, walkSpeed = 2000, 60, 100
local noclip, infiniteJump, speedEnabled, flyEnabled, turbo = false, false, false, false, false
local flyKey, noclipKey, waitingBind = Enum.KeyCode.G, Enum.KeyCode.N, nil
local isAttached, currentTarget, attachConnection, wasFlyingBeforeAttach = false, nil, nil, false
local attachMode, attachSpeed = "cercle", 5.2
local ATTACH_Y, DOS_Z, ORBIT_RADIUS = 0.65, 2.05, 2.05
local character, humanoid, rootPart
local bodyVelocity, bodyGyro, flyConnection, noclipConnection, speedConnection, hitboxConnection
local scriptAlive, lastESP = true, 0

local connections, noclipParts = table.create(32), table.create(16)
local lastHealth = {}
local lastDealt, dealtStamp, lastAttack = 0, 0, 0
local cachedUlt, cachedUltT = nil, 0
local function track(c) connections[#connections+1] = c return c end

local function keyName(k)
	return k and k.Name or "?"
end

local function updateCharacter()
	character = LocalPlayer.Character
	if not character then humanoid, rootPart = nil, nil return end
	humanoid = character:FindFirstChildOfClass("Humanoid")
	rootPart = character:FindFirstChild("HumanoidRootPart")
end

local function stopFly()
	if flyConnection then flyConnection:Disconnect() flyConnection = nil end
	if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	if humanoid then humanoid.PlatformStand = false end
end

local function startFly()
	if not scriptAlive then return end
	stopFly()
	updateCharacter()
	if not humanoid or not rootPart then return end
	humanoid.PlatformStand = true
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce, bodyVelocity.Velocity, bodyVelocity.Parent = Vector3.new(1e9, 1e9, 1e9), ZERO, rootPart
	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque, bodyGyro.P, bodyGyro.Parent = Vector3.new(1e9, 1e9, 1e9), 9e4, rootPart
	flyConnection = RunService.Heartbeat:Connect(function()
		if not (scriptAlive and flyEnabled and not isAttached and rootPart and bodyVelocity and bodyGyro) then return end
		local cf = workspace.CurrentCamera.CFrame
		local move = ZERO
		if UIS:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end
		bodyVelocity.Velocity = move.Magnitude > 0 and move.Unit * (flySpeed * (turbo and 2.2 or 1)) or ZERO
		bodyGyro.CFrame = cf
	end)
end

local function toggleFly()
	flyEnabled = not flyEnabled
	if flyEnabled then startFly() else stopFly() if speedEnabled then startSpeed() end end
end

local function stopSpeed()
	if speedConnection then speedConnection:Disconnect() speedConnection = nil end
	if humanoid and not flyEnabled then humanoid.WalkSpeed = 16 humanoid.PlatformStand = false end
end

local function startSpeed()
	if speedConnection then speedConnection:Disconnect() end
	speedConnection = RunService.Heartbeat:Connect(function(dt)
		if not (scriptAlive and speedEnabled) or flyEnabled or isAttached then return end
		if not humanoid or not rootPart or not humanoid.Parent then updateCharacter() if not humanoid or not rootPart then return end end
		humanoid.PlatformStand = false
		local spd = turbo and walkSpeed * 2 or walkSpeed
		if humanoid.WalkSpeed ~= spd then humanoid.WalkSpeed = spd end
		local md, v = humanoid.MoveDirection, rootPart.AssemblyLinearVelocity
		local tx, tz = 0, 0
		if md.Magnitude > 0.08 then
			local d = Vector3.new(md.X, 0, md.Z)
			if d.Magnitude > 0 then d = d.Unit tx, tz = d.X * spd, d.Z * spd end
		end
		local a = dt * 14
		if a > 1 then a = 1 end
		rootPart.AssemblyLinearVelocity = Vector3.new(v.X + (tx - v.X) * a, v.Y, v.Z + (tz - v.Z) * a)
	end)
end

local function cacheNoclipParts()
	table.clear(noclipParts)
	if not character then return end
	for _, p in ipairs(character:GetDescendants()) do
		if p:IsA("BasePart") then noclipParts[#noclipParts+1] = p end
	end
end

local function stopNoclip()
	if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end

local function startNoclip()
	stopNoclip()
	cacheNoclipParts()
	noclipConnection = RunService.Stepped:Connect(function()
		if not (scriptAlive and noclip) then return end
		for i = 1, #noclipParts do
			local p = noclipParts[i]
			if p and p.Parent then p.CanCollide = false end
		end
	end)
end

local function toggleNoclip()
	noclip = not noclip
	if noclip then startNoclip() else stopNoclip() end
end

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

local CD_KEYS = {
	"UltimateCooldown", "UltCooldown", "UltCD", "UltimateCD", "StyleCooldown",
	"StyleCD", "M2Cooldown", "CritCooldown", "HeavyCooldown", "AbilityCooldown",
	"Cooldown", "CD", "Ult", "Ultimate"
}

local function attrNum(inst, key)
	if not inst then return nil end
	local v = inst:GetAttribute(key)
	if typeof(v) == "number" then return v end
	return nil
end

local function looksLikeCD(name)
	name = string.lower(name or "")
	return string.find(name, "ult", 1, true)
		or string.find(name, "style", 1, true)
		or string.find(name, "m2", 1, true)
		or string.find(name, "crit", 1, true)
		or string.find(name, "heavy", 1, true)
		or string.find(name, "cooldown", 1, true)
		or name == "cd"
end

local function readNumberish(v)
	if v:IsA("NumberValue") or v:IsA("IntValue") then return v.Value end
	if v:IsA("StringValue") then return tonumber(v.Value) end
	return nil
end

local function findUltCD()
	local now = os.clock()
	if now - cachedUltT < 0.35 then return cachedUlt end
	cachedUltT = now
	local player, char = LocalPlayer, LocalPlayer.Character
	for i = 1, #CD_KEYS do
		local a = attrNum(player, CD_KEYS[i]) or (char and attrNum(char, CD_KEYS[i]))
		if a then cachedUlt = a return a end
	end
	local bag = player:FindFirstChild("Cooldowns") or (char and char:FindFirstChild("Cooldowns"))
	if bag then
		for _, d in ipairs(bag:GetChildren()) do
			if looksLikeCD(d.Name) then
				local n = readNumberish(d) or attrNum(d, "Cooldown") or attrNum(d, "Time")
				if typeof(n) == "number" then cachedUlt = n return n end
			end
		end
	end
	cachedUlt = nil
	return nil
end

local function formatUlt()
	local cd = findUltCD()
	if typeof(cd) ~= "number" then return "ULT ?" end
	if cd <= 0.08 then return "ULT READY" end
	if cd <= 20 then return string.format("ULT %.1fs", cd) end
	return "ULT " .. tostring(math.floor(cd + 0.5)) .. "s"
end

local hitHud, hitDmgLab, hitCdLab

local function hideHitHud()
	if hitHud then hitHud.Visible = false end
end

local function showHitHud(amount)
	if not combatEnabled or not hitHud then return end
	hitDmgLab.Text = "+" .. tostring(amount)
	hitCdLab.Text = formatUlt()
	hitHud.Visible = true
	hitHud.BackgroundTransparency = 0.18
end

local function isAttacking()
	if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return true end
	if UIS:IsKeyDown(Enum.KeyCode.R) or UIS:IsKeyDown(Enum.KeyCode.T) then return true end
	return os.clock() - lastAttack <= 0.55
end

local function canClaimHit(myRoot, root)
	if not myRoot or not root then return false end
	if not isAttacking() then return false end
	local offset = root.Position - myRoot.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude > HIT_RANGE then return false end
	local look = Vector3.new(myRoot.CFrame.LookVector.X, 0, myRoot.CFrame.LookVector.Z)
	if look.Magnitude < 0.05 then return flat.Magnitude <= 4.5 end
	return look.Unit:Dot(flat.Unit) >= 0.15
end

local function trackHits()
	if not combatEnabled then return end
	local attacking = isAttacking()
	local myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
	if not myRoot then return end
	local bestAmt, bestDist = nil, 1e9
	local listP = Players:GetPlayers()
	for i = 1, #listP do
		local p = listP[i]
		if p ~= LocalPlayer then
			local char = p.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
			if hum and root then
				local id = p.UserId
				local hp = hum.Health
				local prev = lastHealth[id]
				if attacking and prev and hp < prev - 0.4 and canClaimHit(myRoot, root) then
					local dist = (myRoot.Position - root.Position).Magnitude
					if dist < bestDist then
						bestDist = dist
						bestAmt = math.floor((prev - hp) + 0.5)
					end
				end
				lastHealth[id] = hp
			end
		end
	end
	if bestAmt then
		lastDealt, dealtStamp = bestAmt, os.clock()
		showHitHud(bestAmt)
	end
end

local function updateCombatHud()
	if not combatEnabled then hideHitHud() return end
	trackHits()
	if dealtStamp > 0 and os.clock() - dealtStamp < 1.8 then
		if hitCdLab then hitCdLab.Text = formatUlt() end
		local t = (os.clock() - dealtStamp) / 1.8
		if t > 0.65 and hitHud then
			hitHud.BackgroundTransparency = 0.18 + (t - 0.65) / 0.35 * 0.82
		end
	else
		hideHitHud()
	end
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
	p.Anchored = false
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

local function hitboxName(player)
	return "VolcanoHitbox_" .. tostring(player.UserId)
end

local function getHitbox(player)
	return workspace:FindFirstChild(hitboxName(player))
end

local function groundYOffset(hrp, char, player)
	local now = os.clock()
	local cached = groundCache[player]
	if cached and (now - cached.t) < 0.2 then
		return cached.off
	end
	rayParams.FilterDescendantsInstances = {char, getHitbox(player)}
	local hit = workspace:Raycast(hrp.Position + Vector3.new(0, 1.2, 0), Vector3.new(0, -10, 0), rayParams)
	local off
	if hit then
		off = (hit.Position.Y + 0.03) - hrp.Position.Y
	else
		off = -3.05
	end
	groundCache[player] = {off = off, t = now}
	return off
end

local function removeHitbox(player)
	local folder = workspace:FindFirstChild(hitboxName(player))
	if folder then folder:Destroy() end
	local char = player.Character
	local old = char and char:FindFirstChild("VolcanoHitbox")
	if old then old:Destroy() end
end

local function createHitbox(player)
	if player == LocalPlayer then return end
	if getHitbox(player) then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local folder = Instance.new("Folder")
	folder.Name = hitboxName(player)
	folder.Parent = workspace
	local step = FAN_ANGLE / FAN_SEGMENTS
	local width = 2 * HITBOX_RADIUS * math.tan(math.rad(step * 0.58))
	for i = 1, FAN_SEGMENTS do
		local w = Instance.new("WedgePart")
		w.Name = "Fan" .. i
		w.Size = Vector3.new(width, 0.04, HITBOX_RADIUS)
		styleHitPart(w, HIT_GREEN, FAN_TRANS_GREEN)
		w.Parent = folder
		local weld = Instance.new("Weld")
		weld.Name = "W"
		weld.Part0 = hrp
		weld.Part1 = w
		weld.Parent = w
	end
end

local function updateHitbox(player)
	if player == LocalPlayer then removeHitbox(player) return end
	local char = player.Character
	local folder = getHitbox(player)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not folder or not hrp then return end
	local yOff = groundYOffset(hrp, char, player)
	local facing = isFacingMe(hrp)
	local col = facing and HIT_RED or HIT_GREEN
	local fanTrans = facing and FAN_TRANS_RED or FAN_TRANS_GREEN
	local step = FAN_ANGLE / FAN_SEGMENTS
	local startAng = -FAN_ANGLE * 0.5
	for i = 1, FAN_SEGMENTS do
		local fan = folder:FindFirstChild("Fan" .. i)
		if fan then
			local weld = fan:FindFirstChild("W")
			local mid = math.rad(startAng + (i - 0.5) * step)
			if weld then
				weld.C0 = CFrame.new(0, yOff, 0) * CFrame.Angles(0, mid, 0) * CFrame.new(0, 0, -HITBOX_RADIUS * 0.5)
			end
			if fan.Color ~= col then fan.Color = col end
			if fan.Transparency ~= fanTrans then fan.Transparency = fanTrans end
		end
	end
end

local function clearAllHitboxes()
	for _, p in ipairs(Players:GetPlayers()) do removeHitbox(p) end
	for _, v in ipairs(workspace:GetChildren()) do
		if typeof(v.Name) == "string" and string.sub(v.Name, 1, 14) == "VolcanoHitbox_" then
			v:Destroy()
		end
	end
	table.clear(groundCache)
end

local function stopHitbox()
	if hitboxConnection then hitboxConnection:Disconnect() hitboxConnection = nil end
	clearAllHitboxes()
end

local function startHitbox()
	stopHitbox()
	local acc = 0
	hitboxConnection = RunService.Heartbeat:Connect(function(dt)
		if not (scriptAlive and hitboxEnabled) then return end
		acc += dt
		if acc < 0.08 then return end
		acc = 0
		local myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
		if not myRoot then return end
		local pos = myRoot.Position
		removeHitbox(LocalPlayer)
		local listP = Players:GetPlayers()
		for i = 1, #listP do
			local p = listP[i]
			if p ~= LocalPlayer then
				local char = p.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and (pos - root.Position).Magnitude <= HITBOX_DIST then
					if not getHitbox(p) then createHitbox(p) end
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
		removeHighlight(p) removeHealthTag(p) removeHitbox(p)
		local char = p.Character
		if char then
			local tag = char:FindFirstChild("VolcanoNameTag")
			if tag then tag:Destroy() end
			local ctag = char:FindFirstChild("VolcanoCombatTag")
			if ctag then ctag:Destroy() end
		end
	end
	hideHitHud()
end

local function updateESP()
	if not scriptAlive then return end
	local now = os.clock()
	if now - lastESP < 0.25 then return end
	lastESP = now
	local myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
	if not myRoot then return end
	local pos = myRoot.Position
	if selfHealthEnabled then
		if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("VolcanoHealthTag")) then
			createHealthTag(LocalPlayer)
		end
		updateHealthTag(LocalPlayer)
	end
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
					if ok then
						if not char:FindFirstChild("VolcanoHealthTag") then createHealthTag(p) end
						updateHealthTag(p)
					else
						removeHealthTag(p)
					end
				end
			end
		end
	end
end

local function onCharacterAdded(char)
	if not scriptAlive then return end
	character = char
	humanoid = char:WaitForChild("Humanoid", 8)
	rootPart = char:WaitForChild("HumanoidRootPart", 8)
	isAttached, currentTarget, wasFlyingBeforeAttach = false, nil, false
	if attachConnection then attachConnection:Disconnect() attachConnection = nil end
	stopFly()
	cacheNoclipParts()
	char.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then noclipParts[#noclipParts+1] = d end
	end)
	task.wait(0.35)
	if not scriptAlive then return end
	if speedEnabled then startSpeed() end
	if flyEnabled then startFly() end
	if noclip then startNoclip() end
	if selfHealthEnabled then createHealthTag(LocalPlayer) end
	removeHitbox(LocalPlayer)
end

if LocalPlayer.Character then task.spawn(onCharacterAdded, LocalPlayer.Character) end
track(LocalPlayer.CharacterAdded:Connect(onCharacterAdded))
track(LocalPlayer.CharacterRemoving:Connect(function()
	stopFly() stopNoclip() stopSpeed()
	character, humanoid, rootPart = nil, nil, nil
	table.clear(noclipParts)
end))

local refreshUI

local function StopAttach()
	isAttached, currentTarget = false, nil
	if attachConnection then attachConnection:Disconnect() attachConnection = nil end
	if rootPart then rootPart.AssemblyLinearVelocity = ZERO rootPart.AssemblyAngularVelocity = ZERO end
	if scriptAlive and wasFlyingBeforeAttach then
		wasFlyingBeforeAttach = false
		flyEnabled = true
		task.delay(0.12, function() if scriptAlive then startFly() end if refreshUI then refreshUI() end end)
	else
		wasFlyingBeforeAttach = false
	end
	if refreshUI then refreshUI() end
end

local function AttachToPlayer(target)
	if not (scriptAlive and target and target.Character) then return end
	local th0 = target.Character:FindFirstChild("HumanoidRootPart")
	updateCharacter()
	if not th0 or not rootPart then return end
	StopAttach()
	wasFlyingBeforeAttach = flyEnabled
	if flyEnabled then flyEnabled = false stopFly() end
	currentTarget, isAttached = target, true
	for i = 1, #noclipParts do
		local p = noclipParts[i]
		if p and p.Parent then p.CanCollide = false end
	end
	attachConnection = RunService.Heartbeat:Connect(function(dt)
		if not isAttached or not scriptAlive or not currentTarget then
			if attachConnection then attachConnection:Disconnect() attachConnection = nil end
			return
		end
		local tchar = currentTarget.Character
		local th = tchar and tchar:FindFirstChild("HumanoidRootPart")
		local mh = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not th or not mh then StopAttach() return end
		local vel = th.AssemblyLinearVelocity
		local predicted = th.Position + vel * (dt > 0.04 and 0.08 or dt * 2)
		if attachMode == "dos" then
			mh.CFrame = CFrame.new(predicted) * (th.CFrame - th.Position) * CFrame.new(0, ATTACH_Y, DOS_Z)
		else
			local ang = os.clock() * attachSpeed
			mh.CFrame = CFrame.new(predicted + Vector3.new(math.cos(ang) * ORBIT_RADIUS, ATTACH_Y, math.sin(ang) * ORBIT_RADIUS), predicted + Vector3.new(0, 1.2, 0))
		end
		mh.AssemblyLinearVelocity = vel
		mh.AssemblyAngularVelocity = ZERO
	end)
	if refreshUI then refreshUI() end
end

local function TeleportTo(player)
	local a, b = LocalPlayer.Character, player.Character
	if a and a.PrimaryPart and b and b.PrimaryPart then
		a:PivotTo(b.PrimaryPart.CFrame + Vector3.new(0, 3, 0))
		if flyEnabled then task.delay(0.2, startFly) end
	end
end

local COL_BG = Color3.fromRGB(22, 14, 20)
local COL_PANEL = Color3.fromRGB(34, 20, 30)
local COL_ROW = Color3.fromRGB(38, 22, 34)
local COL_ACCENT = Color3.fromRGB(255, 145, 190)
local COL_TEXT = Color3.fromRGB(255, 230, 238)
local COL_MUTED = Color3.fromRGB(190, 150, 168)

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "VolcanoGakuranHub", false, true, 99999
gui.Parent = parentGui

hitHud = Instance.new("Frame")
hitHud.Name, hitHud.Size, hitHud.Position = "HitHud", UDim2.new(0, 168, 0, 54), UDim2.new(0.5, -84, 0.72, 0)
hitHud.BackgroundColor3, hitHud.BackgroundTransparency, hitHud.BorderSizePixel = Color3.fromRGB(28, 16, 24), 0.18, 0
hitHud.Visible, hitHud.Parent = false, gui
Instance.new("UICorner", hitHud).CornerRadius = UDim.new(0, 10)
local hitStroke = Instance.new("UIStroke")
hitStroke.Color, hitStroke.Thickness, hitStroke.Transparency, hitStroke.Parent = COL_ACCENT, 1.2, 0.25, hitHud
hitDmgLab = Instance.new("TextLabel")
hitDmgLab.Size, hitDmgLab.BackgroundTransparency = UDim2.new(1, 0, 0, 28), 1
hitDmgLab.Font, hitDmgLab.TextSize, hitDmgLab.TextColor3 = Enum.Font.GothamBold, 22, Color3.fromRGB(120, 255, 170)
hitDmgLab.Text, hitDmgLab.Parent = "+0", hitHud
hitCdLab = Instance.new("TextLabel")
hitCdLab.Size, hitCdLab.Position, hitCdLab.BackgroundTransparency = UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 28), 1
hitCdLab.Font, hitCdLab.TextSize, hitCdLab.TextColor3 = Enum.Font.GothamBold, 13, Color3.fromRGB(255, 210, 140)
hitCdLab.Text, hitCdLab.Parent = "ULT ?", hitHud

local main = Instance.new("Frame")
main.Size, main.Position = UDim2.new(0, 540, 0, 580), UDim2.new(0.5, -270, 0.5, -290)
main.BackgroundColor3, main.BorderSizePixel = COL_BG, 0
main.Active, main.Draggable, main.Visible, main.Parent = true, true, false, gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
local stk = Instance.new("UIStroke")
stk.Color, stk.Thickness, stk.Parent = Color3.fromRGB(255, 140, 185), 1.4, main

local top = Instance.new("Frame")
top.Size, top.BackgroundColor3, top.BorderSizePixel, top.Parent = UDim2.new(1, 0, 0, 3), COL_ACCENT, 0, main
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 14)

local header = Instance.new("Frame")
header.Size, header.Position, header.BackgroundTransparency, header.Parent = UDim2.new(1, -16, 0, 42), UDim2.new(0, 8, 0, 10), 1, main

local brand = Instance.new("TextLabel")
brand.Size, brand.BackgroundTransparency, brand.Text = UDim2.new(1, -280, 1, 0), 1, "🌸  volcano gakuran  🌸"
brand.Font, brand.TextSize, brand.TextColor3, brand.TextXAlignment, brand.Parent = Enum.Font.GothamBold, 16, COL_ACCENT, Enum.TextXAlignment.Left, header

local byline = Instance.new("TextLabel")
byline.Size, byline.Position = UDim2.new(0, 110, 1, 0), UDim2.new(1, -260, 0, 0)
byline.BackgroundTransparency, byline.Text = 1, "by vulcalypse"
byline.Font, byline.TextSize, byline.TextColor3, byline.TextXAlignment, byline.Parent = Enum.Font.Gotham, 12, COL_MUTED, Enum.TextXAlignment.Right, header

local function iconBtn(txt, x)
	local b = Instance.new("TextButton")
	b.Size, b.Position = UDim2.new(0, 42, 0, 28), UDim2.new(1, x, 0.5, -14)
	b.BackgroundColor3, b.Text, b.Font, b.TextSize, b.TextColor3, b.Parent = Color3.fromRGB(50, 28, 42), txt, Enum.Font.GothamBold, 12, COL_TEXT, header
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end
local endBtn, closeBtn = iconBtn("End", -140), iconBtn("✕", -90)

local search = Instance.new("TextBox")
search.Size, search.Position = UDim2.new(1, -24, 0, 36), UDim2.new(0, 12, 0, 56)
search.BackgroundColor3, search.PlaceholderText, search.PlaceholderColor3 = COL_PANEL, "Search commands...", COL_MUTED
search.Text, search.TextColor3, search.Font, search.TextSize, search.ClearTextOnFocus, search.Parent = "", COL_TEXT, Enum.Font.Gotham, 14, false, main
Instance.new("UICorner", search).CornerRadius = UDim.new(0, 10)

local chipBar = Instance.new("ScrollingFrame")
chipBar.Size, chipBar.Position, chipBar.BackgroundTransparency = UDim2.new(1, -24, 0, 34), UDim2.new(0, 12, 0, 100), 1
chipBar.ScrollBarThickness, chipBar.CanvasSize, chipBar.Parent = 0, UDim2.new(0, 520, 0, 0), main
local chipLay = Instance.new("UIListLayout")
chipLay.FillDirection, chipLay.Padding, chipLay.Parent = Enum.FillDirection.Horizontal, UDim.new(0, 6), chipBar

local currentCat, chips = "all", {}
local function makeChip(id, label)
	local b = Instance.new("TextButton")
	b.Size, b.BackgroundColor3, b.Text = UDim2.new(0, 88, 0, 28), Color3.fromRGB(48, 28, 40), label
	b.Font, b.TextSize, b.TextColor3, b.Parent = Enum.Font.GothamBold, 12, COL_MUTED, chipBar
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	chips[id] = b
	b.MouseButton1Click:Connect(function() currentCat = id refreshUI() end)
end
makeChip("all", "all") makeChip("move", "move") makeChip("esp", "esp") makeChip("players", "players") makeChip("extra", "extra")

local list = Instance.new("ScrollingFrame")
list.Size, list.Position, list.BackgroundTransparency = UDim2.new(1, -24, 1, -196), UDim2.new(0, 12, 0, 142), 1
list.ScrollBarThickness, list.CanvasSize, list.Parent = 4, UDim2.new(0, 0, 0, 0), main
local listLay = Instance.new("UIListLayout")
listLay.Padding, listLay.SortOrder, listLay.Parent = UDim.new(0, 7), Enum.SortOrder.LayoutOrder, list

local exec = Instance.new("TextBox")
exec.Size, exec.Position = UDim2.new(1, -24, 0, 36), UDim2.new(0, 12, 1, -48)
exec.BackgroundColor3, exec.PlaceholderText, exec.PlaceholderColor3 = COL_PANEL, "Execute command...", COL_MUTED
exec.Text, exec.TextColor3, exec.Font, exec.TextSize, exec.Parent = "", COL_TEXT, Enum.Font.Gotham, 14, main
Instance.new("UICorner", exec).CornerRadius = UDim.new(0, 10)

local commandDefs = {}
local function addHeader(cat, title) commandDefs[#commandDefs+1] = {kind="header", cat=cat, title=title} end
local function addCmd(cat, name, getter, runner) commandDefs[#commandDefs+1] = {kind="cmd", cat=cat, name=name, getter=getter, runner=runner} end
local function stt(on) return on and "ON" or "OFF" end

addHeader("move", "MOVE")
addCmd("move", "noclip", function() return stt(noclip) end, toggleNoclip)
addCmd("move", "noclip key", function() return waitingBind == "noclip" and "..." or keyName(noclipKey) end, function() waitingBind = "noclip" end)
addCmd("move", "speed", function() return stt(speedEnabled) end, function() speedEnabled = not speedEnabled if speedEnabled then startSpeed() else stopSpeed() end end)
addCmd("move", "speed value", function() return tostring(walkSpeed) end, function() end)
addCmd("move", "speed +10", function() return tostring(walkSpeed) end, function() walkSpeed = math.clamp(walkSpeed + 10, 16, 300) end)
addCmd("move", "speed -10", function() return tostring(walkSpeed) end, function() walkSpeed = math.clamp(walkSpeed - 10, 16, 300) end)
addCmd("move", "infinite jump", function() return stt(infiniteJump) end, function() infiniteJump = not infiniteJump end)
addCmd("move", "fly", function() return stt(flyEnabled) end, toggleFly)
addCmd("move", "fly key", function() return waitingBind == "fly" and "..." or keyName(flyKey) end, function() waitingBind = "fly" end)
addCmd("move", "fly speed", function() return tostring(flySpeed) end, function() end)
addCmd("move", "fly speed +10", function() return tostring(flySpeed) end, function() flySpeed = math.clamp(flySpeed + 10, 10, 500) end)
addCmd("move", "fly speed -10", function() return tostring(flySpeed) end, function() flySpeed = math.clamp(flySpeed - 10, 10, 500) end)

addHeader("esp", "ESP")
addCmd("esp", "highlights", function() return stt(highlightsEnabled) end, function()
	highlightsEnabled = not highlightsEnabled
	if not highlightsEnabled then for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then removeHighlight(p) end end end
end)
addCmd("esp", "names", function() return stt(namesEnabled) end, function()
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
addCmd("esp", "vie joueurs", function() return stt(healthEnabled) end, function()
	healthEnabled = not healthEnabled
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then removeHealthTag(p) if healthEnabled then createHealthTag(p) end end
	end
end)
addCmd("esp", "ma vie", function() return stt(selfHealthEnabled) end, function()
	selfHealthEnabled = not selfHealthEnabled
	removeHealthTag(LocalPlayer)
	if selfHealthEnabled then createHealthTag(LocalPlayer) end
end)
addCmd("esp", "degats / ultime", function() return stt(combatEnabled) end, function()
	combatEnabled = not combatEnabled
	if not combatEnabled then hideHitHud() end
end)
addCmd("esp", "hitbox vis", function() return stt(hitboxEnabled) end, function()
	hitboxEnabled = not hitboxEnabled
	if hitboxEnabled then startHitbox() else stopHitbox() end
end)
addCmd("esp", "distance max", function() return tostring(maxDistance) end, function() end)
addCmd("esp", "distance +200", function() return tostring(maxDistance) end, function() maxDistance += 200 end)
addCmd("esp", "distance -200", function() return tostring(maxDistance) end, function() maxDistance = math.max(200, maxDistance - 200) end)

addHeader("extra", "EXTRA")
addCmd("extra", "desactiver le script", function() return "END" end, function() end)

local function makeRow(def)
	if def.kind == "header" then
		local lab = Instance.new("TextLabel")
		lab.Size, lab.BackgroundTransparency, lab.Text = UDim2.new(1, 0, 0, 22), 1, def.title
		lab.Font, lab.TextSize, lab.TextColor3, lab.TextXAlignment, lab.Parent = Enum.Font.GothamBold, 12, COL_MUTED, Enum.TextXAlignment.Left, list
		return
	end
	local row = Instance.new("TextButton")
	row.Size, row.BackgroundColor3, row.Text, row.Parent = UDim2.new(1, -4, 0, 44), COL_ROW, "", list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
	local name = Instance.new("TextLabel")
	name.Size, name.Position, name.BackgroundTransparency = UDim2.new(1, -120, 1, 0), UDim2.new(0, 14, 0, 0), 1
	name.Text, name.Font, name.TextSize, name.TextColor3, name.TextXAlignment, name.Parent = ": "..def.name, Enum.Font.Gotham, 15, COL_TEXT, Enum.TextXAlignment.Left, row
	local valTxt = def.getter and def.getter() or ""
	local val = Instance.new("TextLabel")
	val.Size, val.Position = UDim2.new(0, 96, 0, 26), UDim2.new(1, -108, 0.5, -13)
	val.BackgroundColor3, val.Text = Color3.fromRGB(55, 30, 45), valTxt
	val.Font, val.TextSize, val.Parent = Enum.Font.GothamBold, 13, row
	val.TextColor3 = valTxt == "ON" and Color3.fromRGB(120, 255, 180) or valTxt == "OFF" and Color3.fromRGB(255, 140, 160) or valTxt == "..." and Color3.fromRGB(255, 220, 120) or COL_ACCENT
	Instance.new("UICorner", val).CornerRadius = UDim.new(0, 8)
	row.MouseButton1Click:Connect(function()
		if scriptAlive and def.runner then def.runner() end
		refreshUI()
	end)
end

local function pill(parent, txt, x, w, on, fn)
	local b = Instance.new("TextButton")
	b.Size, b.Position = UDim2.new(0, w, 0, 26), UDim2.new(1, x, 0.5, -13)
	b.BackgroundColor3 = on and COL_ACCENT or Color3.fromRGB(55, 30, 45)
	b.Text, b.Font, b.TextSize = txt, Enum.Font.GothamBold, 11
	b.TextColor3 = on and Color3.fromRGB(40, 16, 28) or COL_ACCENT
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(fn)
end

local function makeDetachBar()
	local row = Instance.new("TextButton")
	row.Size, row.BackgroundColor3, row.Text, row.Parent = UDim2.new(1, -4, 0, 40), Color3.fromRGB(70, 28, 48), "", list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
	local lab = Instance.new("TextLabel")
	lab.Size, lab.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
	lab.Text = isAttached and ("DÉTACHER  —  " .. (currentTarget and currentTarget.Name or "") .. "  (X)") or "DÉTACHER  (X)"
	lab.Font, lab.TextSize, lab.TextColor3, lab.Parent = Enum.Font.GothamBold, 14, COL_ACCENT, row
	row.MouseButton1Click:Connect(StopAttach)
	local mode = Instance.new("Frame")
	mode.Size, mode.BackgroundColor3, mode.Parent = UDim2.new(1, -4, 0, 40), COL_ROW, list
	Instance.new("UICorner", mode).CornerRadius = UDim.new(0, 10)
	local t = Instance.new("TextLabel")
	t.Size, t.Position, t.BackgroundTransparency = UDim2.new(0.28, 0, 1, 0), UDim2.new(0, 12, 0, 0), 1
	t.Text, t.Font, t.TextSize, t.TextColor3, t.TextXAlignment = "mode attach", Enum.Font.Gotham, 13, COL_MUTED, Enum.TextXAlignment.Left
	t.Parent = mode
	pill(mode, "DOS", -286, 58, attachMode == "dos", function() attachMode = "dos" refreshUI() end)
	pill(mode, "CERCLE", -222, 64, attachMode == "cercle", function() attachMode = "cercle" refreshUI() end)
	pill(mode, "−", -150, 32, false, function() attachSpeed = math.clamp(math.floor((attachSpeed - 0.8) * 10 + 0.5) / 10, 1, 14) refreshUI() end)
	local spd = Instance.new("TextLabel")
	spd.Size, spd.Position = UDim2.new(0, 48, 0, 26), UDim2.new(1, -112, 0.5, -13)
	spd.BackgroundColor3, spd.Text = Color3.fromRGB(55, 30, 45), tostring(attachSpeed)
	spd.Font, spd.TextSize, spd.TextColor3, spd.Parent = Enum.Font.GothamBold, 12, COL_ACCENT, mode
	Instance.new("UICorner", spd).CornerRadius = UDim.new(0, 8)
	pill(mode, "+", -56, 32, false, function() attachSpeed = math.clamp(math.floor((attachSpeed + 0.8) * 10 + 0.5) / 10, 1, 14) refreshUI() end)
end

local function makePlayerRows(filter)
	makeDetachBar()
	local seen = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and not seen[p.UserId] then
			seen[p.UserId] = true
			if filter == "" or string.find(string.lower(p.Name), filter, 1, true) then
				local row = Instance.new("Frame")
				row.Size, row.BackgroundColor3, row.Parent = UDim2.new(1, -4, 0, 46), COL_ROW, list
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)
				local name = Instance.new("TextLabel")
				name.Size, name.Position, name.BackgroundTransparency = UDim2.new(1, -210, 1, 0), UDim2.new(0, 14, 0, 0), 1
				name.Text = (currentTarget == p and "● " or "🌸 ") .. p.Name
				name.Font, name.TextSize, name.TextColor3, name.TextXAlignment, name.Parent = Enum.Font.GothamMedium, 15, ESP_COLOR, Enum.TextXAlignment.Left, row
				pill(row, "TP", -210, 58, false, function() TeleportTo(p) end)
				pill(row, "ATTACH", -144, 64, currentTarget == p, function() AttachToPlayer(p) end)
				pill(row, "DETACH", -72, 64, false, function() if currentTarget == p or isAttached then StopAttach() end end)
			end
		end
	end
end

refreshUI = function()
	local cat, q = currentCat, string.lower(search.Text)
	for _, c in ipairs(list:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
	for id, chip in pairs(chips) do
		if id == cat then chip.BackgroundColor3, chip.TextColor3 = COL_ACCENT, Color3.fromRGB(40, 16, 28)
		else chip.BackgroundColor3, chip.TextColor3 = Color3.fromRGB(48, 28, 40), COL_MUTED end
	end
	for i = 1, #commandDefs do
		local def = commandDefs[i]
		if cat == "all" or def.cat == cat then
			if def.kind == "header" then
				if q == "" then makeRow(def) end
			elseif q == "" or string.find(string.lower(def.name), q, 1, true) then
				makeRow(def)
			end
		end
	end
	if cat == "players" then makePlayerRows(q) end
	list.CanvasSize = UDim2.new(0, 0, 0, listLay.AbsoluteContentSize.Y + 10)
end

local function UnloadScript()
	if not scriptAlive then return end
	scriptAlive = false
	flyEnabled, noclip, speedEnabled, infiniteJump, turbo = false, false, false, false, false
	highlightsEnabled, namesEnabled, healthEnabled, selfHealthEnabled, hitboxEnabled, combatEnabled = false, false, false, false, false, false
	StopAttach() stopFly() stopNoclip() stopSpeed() stopHitbox()
	if humanoid then humanoid.WalkSpeed = 16 humanoid.PlatformStand = false end
	clearAllESP()
	for i = 1, #connections do pcall(function() connections[i]:Disconnect() end) end
	table.clear(connections)
	if gui then gui:Destroy() end
end
commandDefs[#commandDefs].runner = UnloadScript

search:GetPropertyChangedSignal("Text"):Connect(refreshUI)
exec.FocusLost:Connect(function(enter)
	if not enter then return end
	local q = string.lower(exec.Text)
	if q == "x" or q == "detacher" or q == "detach" then StopAttach() exec.Text = "" refreshUI() return end
	if q == "dos" then attachMode = "dos" exec.Text = "" refreshUI() return end
	if q == "cercle" then attachMode = "cercle" exec.Text = "" refreshUI() return end
	for i = 1, #commandDefs do
		local def = commandDefs[i]
		if def.kind == "cmd" and string.find(def.name, q, 1, true) then def.runner() exec.Text = "" refreshUI() return end
	end
end)
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)
endBtn.MouseButton1Click:Connect(UnloadScript)

task.spawn(function()
	while scriptAlive do
		if highlightsEnabled or namesEnabled or healthEnabled or selfHealthEnabled then updateESP() end
		if combatEnabled then updateCombatHud() end
		task.wait(combatEnabled and 0.06 or 0.25)
	end
end)

track(UIS.JumpRequest:Connect(function()
	if scriptAlive and infiniteJump and humanoid and humanoid.Parent then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))
track(UIS.InputBegan:Connect(function(input, gp)
	if not scriptAlive then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then lastAttack = os.clock() end
	local k = input.KeyCode
	if k == Enum.KeyCode.Unknown then return end
	if waitingBind then
		if k ~= Enum.KeyCode.Escape and k ~= Enum.KeyCode.Insert and k ~= Enum.KeyCode.End then
			if waitingBind == "fly" then flyKey = k else noclipKey = k end
		end
		waitingBind = nil
		refreshUI()
		return
	end
	if k == Enum.KeyCode.R or k == Enum.KeyCode.T then lastAttack = os.clock()
	elseif k == flyKey then toggleFly() refreshUI()
	elseif k == noclipKey then toggleNoclip() refreshUI()
	elseif k == Enum.KeyCode.X then StopAttach()
	elseif k == Enum.KeyCode.Insert then main.Visible = not main.Visible
	elseif k == Enum.KeyCode.End then UnloadScript()
	elseif k == Enum.KeyCode.LeftShift then turbo = true end
end))
track(UIS.InputEnded:Connect(function(input)
	if scriptAlive and input.KeyCode == Enum.KeyCode.LeftShift then turbo = false end
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
	if currentTarget == p then StopAttach() end
	removeHitbox(p)
	groundCache[p] = nil
	lastHealth[p.UserId] = nil
	if scriptAlive and currentCat == "players" then refreshUI() end
end))

refreshUI()
print("🌸 volcano gakuran 🌸 | by vulcalypse")
