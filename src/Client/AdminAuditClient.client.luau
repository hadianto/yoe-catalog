-- AdminAuditClient  (LocalScript in StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
if not table.find(Shared.ADMIN_IDS, player.UserId) then return end

local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))
local getHistory = Remotes.get("GetHistory")

local T = Shared.THEME
local ACCENT_A = T.accentA
local ACCENT_B = T.accentB
local PANEL_BG = T.panelBg
local CARD_BG  = T.cardBg
local STROKE_C = T.stroke
local TEXT_SUB = T.textSub
local GREEN_A  = T.successA
local AMBER    = T.warn

local BTN_TOP  = Color3.fromRGB(176, 84, 56)
local BTN_BASE = Color3.fromRGB(206, 112, 78)
local BTN_HOVER_TOP  = Color3.fromRGB(206, 110, 78)
local BTN_HOVER_BASE = Color3.fromRGB(232, 132, 96)

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = p end
local function stroke(p, col, th, tr) local s = Instance.new("UIStroke") s.Color = col or STROKE_C s.Thickness = th or 1.5 s.Transparency = tr or 0.45 s.Parent = p return s end
local function gradient(p, c1, c2, rot) local g = Instance.new("UIGradient") g.Color = ColorSequence.new(c1, c2) g.Rotation = rot or 90 g.Parent = p return g end
local function labelStroke(p)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(60, 32, 22)
	s.Thickness = 1; s.Transparency = 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = p
end
local function addHover(button, baseSize)
	local g = button:FindFirstChildOfClass("UIGradient")
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.fromRGB(255, 200, 170); edge.Thickness = 1.5; edge.Transparency = 1
	edge.Parent = button
	button.MouseEnter:Connect(function()
		if g then g.Color = ColorSequence.new(BTN_HOVER_TOP, BTN_HOVER_BASE) end
		TweenService:Create(edge, TweenInfo.new(0.12), { Transparency = 0.2 }):Play()
		TweenService:Create(button, TweenInfo.new(0.12), { Size = UDim2.fromOffset(baseSize.X.Offset + 4, baseSize.Y.Offset + 2) }):Play()
	end)
	button.MouseLeave:Connect(function()
		if g then g.Color = ColorSequence.new(BTN_TOP, BTN_BASE) end
		TweenService:Create(edge, TweenInfo.new(0.12), { Transparency = 1 }):Play()
		TweenService:Create(button, TweenInfo.new(0.12), { Size = baseSize }):Play()
	end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "AdminAudit"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 211
gui.Parent = player:WaitForChild("PlayerGui")

-- reuse shared dock
local ticketGui = player.PlayerGui:WaitForChild("TicketButton", 5)
local dock = ticketGui and ticketGui:FindFirstChild("Dock")
if not dock then
	dock = Instance.new("Frame")
	dock.Name = "Dock"; dock.Size = UDim2.fromOffset(150, 0)
	dock.AutomaticSize = Enum.AutomaticSize.Y; dock.Position = UDim2.fromOffset(14, 70)
	dock.BackgroundTransparency = 1; dock.Parent = gui
	local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder; l.HorizontalAlignment = Enum.HorizontalAlignment.Left
	l.Parent = dock
end

local AUDIT_SIZE = UDim2.fromOffset(150, 44)
local btn = Instance.new("TextButton")
btn.Size = AUDIT_SIZE
btn.LayoutOrder = 0 -- sits ABOVE Tickets (1) and Refund (2)
btn.Text = ""
btn.BackgroundColor3 = BTN_TOP
btn.AutoButtonColor = false
btn.Parent = dock
corner(btn, 11)
gradient(btn, BTN_TOP, BTN_BASE, 90)
addHover(btn, AUDIT_SIZE)

local btnLabel = Instance.new("TextLabel")
btnLabel.Size = UDim2.fromScale(1, 1); btnLabel.BackgroundTransparency = 1
btnLabel.Text = "Audit"; btnLabel.TextColor3 = Color3.new(1, 1, 1)
btnLabel.Font = Enum.Font.GothamBold; btnLabel.TextSize = 15
btnLabel.Parent = btn
labelStroke(btnLabel)

-- panel
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(560, 480)
panel.Position = UDim2.new(0.5, -280, 0.5, -240)
panel.BackgroundColor3 = PANEL_BG; panel.Visible = false
panel.Parent = gui
corner(panel, 14); stroke(panel, STROKE_C, 1.5, 0.3)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52); header.BackgroundColor3 = ACCENT_A
header.Parent = panel
corner(header, 14); gradient(header, ACCENT_B, ACCENT_A, 0)

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -60, 1, 0); headerLabel.Position = UDim2.fromOffset(16, 0)
headerLabel.BackgroundTransparency = 1; headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Text = "Purchase Audit"; headerLabel.TextColor3 = Color3.new(1, 1, 1)
headerLabel.Font = Enum.Font.GothamBold; headerLabel.TextSize = 18
headerLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(32, 32); closeBtn.Position = UDim2.new(1, -44, 0.5, -16)
closeBtn.BackgroundColor3 = Color3.fromRGB(70, 76, 92); closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1); closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14; closeBtn.AutoButtonColor = true; closeBtn.Parent = header
corner(closeBtn, 8)

-- search row
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -130, 0, 34); searchBox.Position = UDim2.fromOffset(12, 62)
searchBox.BackgroundColor3 = T.field; searchBox.PlaceholderText = "UserId or username"
searchBox.PlaceholderColor3 = TEXT_SUB; searchBox.Text = ""
searchBox.TextColor3 = Color3.new(1, 1, 1); searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14; searchBox.ClearTextOnFocus = false; searchBox.Parent = panel
corner(searchBox, 9); stroke(searchBox, STROKE_C, 1, 0.4)

local lookupBtn = Instance.new("TextButton")
lookupBtn.Size = UDim2.fromOffset(104, 34); lookupBtn.Position = UDim2.new(1, -116, 0, 62)
lookupBtn.BackgroundColor3 = GREEN_A; lookupBtn.Text = "Look up"
lookupBtn.TextColor3 = Color3.new(1, 1, 1); lookupBtn.Font = Enum.Font.GothamBold
lookupBtn.TextSize = 14; lookupBtn.AutoButtonColor = true; lookupBtn.Parent = panel
corner(lookupBtn, 9)

-- summary line
local summary = Instance.new("TextLabel")
summary.Size = UDim2.new(1, -24, 0, 40); summary.Position = UDim2.fromOffset(12, 102)
summary.BackgroundTransparency = 1; summary.TextXAlignment = Enum.TextXAlignment.Left
summary.TextYAlignment = Enum.TextYAlignment.Top; summary.RichText = true
summary.TextWrapped = true; summary.Text = "Enter a player to view their purchase log."
summary.TextColor3 = TEXT_SUB; summary.Font = Enum.Font.Gotham; summary.TextSize = 13
summary.Parent = panel

-- list
local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -24, 1, -156); list.Position = UDim2.fromOffset(12, 146)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0
list.ScrollBarThickness = 6; list.ScrollBarImageColor3 = ACCENT_B
list.CanvasSize = UDim2.new(0, 0, 0, 0); list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6); layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function clearList()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
end

local function fmtTime(t)
	if not t or t == 0 then return "?" end
	return os.date("!%Y-%m-%d %H:%M", t)
end

local function makeEntry(e)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 56); row.BackgroundColor3 = CARD_BG
	row.Parent = list
	corner(row, 9); stroke(row, STROKE_C, 1, 0.6)

	local memberTag = e.inGroup and "<font color='#e2a246'>MEMBER</font>" or "<font color='#46b46c'>NON-MEMBER</font>"
	local refundTag = e.refundable and "refundable" or "not refundable"
	local extra = ""
	if e.kind == "Plus" then
		extra = e.likelyEarned and "  ·  likely earned" or "  ·  not counted"
	end

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -16, 1, -8); info.Position = UDim2.fromOffset(10, 4)
	info.BackgroundTransparency = 1; info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top; info.RichText = true
	info.TextWrapped = true; info.Font = Enum.Font.Gotham; info.TextSize = 12
	info.TextColor3 = Color3.new(1, 1, 1)
	info.Text = string.format(
		"<b>%s</b>  <font color='#beb2a8'>%s Robux</font>  %s\n<font color='#beb2a8'>id %s · rank %d · %s%s · %s</font>",
		tostring(e.kind), tostring(e.robux or 0), memberTag,
		tostring(e.id or "-"), tonumber(e.groupRank) or 0, refundTag, extra, fmtTime(e.at))
	info.Parent = row
end

local function doLookup()
	local q = searchBox.Text
	if q == "" then return end
	summary.Text = "Looking up..."
	clearList()
	local ok, res = pcall(function() return getHistory:InvokeServer(q) end)
	if not ok or res == nil then
		summary.Text = "<font color='#e25050'>Lookup failed (not admin or server error).</font>"
		return
	end
	if res.error then
		summary.Text = ("<font color='#e2a246'>%s</font>"):format(res.error)
		return
	end
	summary.Text = string.format(
		"<b>UserId %d</b>\nCatalog %d · Bundle %d · claimed %d  |  Plus eligible %d (total %d), claimed %d",
		res.userId, res.catalogSpend, res.bundleSpend, res.refundClaimedSpend,
		res.plusEligible, res.plusTotal, res.refundClaimedPlus)

	local h = res.history
	if #h == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -4, 0, 40); empty.BackgroundTransparency = 1
		empty.Text = "No purchases logged."; empty.TextColor3 = TEXT_SUB
		empty.Font = Enum.Font.Gotham; empty.TextSize = 13; empty.Parent = list
		return
	end
	-- newest first
	for i = #h, 1, -1 do makeEntry(h[i]) end
end

lookupBtn.MouseButton1Click:Connect(doLookup)
searchBox.FocusLost:Connect(function(enter) if enter then doLookup() end end)

btn.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		panel.Size = UDim2.fromOffset(540, 460)
		TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(560, 480) }):Play()
	end
end)
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)