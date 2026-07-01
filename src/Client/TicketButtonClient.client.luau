-- TicketButtonClient  (LocalScript in StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))
local submitTicket = Remotes.get("SubmitTicket")
local showNotification = Remotes.get("ShowNotification")
local getOwed = Remotes.get("GetOwed")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local mode = Shared.REFUND_MODE or "on"

local T = Shared.THEME
local PANEL_BG = T.panelBg
local STROKE_C = T.stroke
local TEXT_SUB = T.textSub
local GREEN_A  = T.successA
local GREEN_B  = T.successB
local GREY     = T.neutral

-- shared button colors (dark-on-top gradient so text reads)
local BTN_TOP  = Color3.fromRGB(176, 84, 56)
local BTN_BASE = Color3.fromRGB(206, 112, 78)
local BTN_HOVER_TOP  = Color3.fromRGB(206, 110, 78)
local BTN_HOVER_BASE = Color3.fromRGB(232, 132, 96)
local CARD_ISH = Color3.fromRGB(44, 39, 34)  -- ticket row bg

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = p end
local function stroke(p, col, th, tr) local s = Instance.new("UIStroke") s.Color = col or STROKE_C s.Thickness = th or 1.5 s.Transparency = tr or 0.4 s.Parent = p return s end
local function gradient(p, c1, c2, rot) local g = Instance.new("UIGradient") g.Color = ColorSequence.new(c1, c2) g.Rotation = rot or 90 g.Parent = p return g end

-- text outline so white labels stay crisp on terracotta
local function labelStroke(p)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(60, 32, 22)
	s.Thickness = 1
	s.Transparency = 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = p
end

-- clear hover: lighten gradient, brighten border, tiny lift
local function addHover(button, baseSize)
	local g = button:FindFirstChildOfClass("UIGradient")
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.fromRGB(255, 200, 170)
	edge.Thickness = 1.5
	edge.Transparency = 1 -- hidden until hover
	edge.Parent = button

	button.MouseEnter:Connect(function()
		if g then g.Color = ColorSequence.new(BTN_HOVER_TOP, BTN_HOVER_BASE) end
		TweenService:Create(edge, TweenInfo.new(0.12), { Transparency = 0.2 }):Play()
		TweenService:Create(button, TweenInfo.new(0.12), {
			Size = UDim2.fromOffset(baseSize.X.Offset + 4, baseSize.Y.Offset + 2)
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		if g then g.Color = ColorSequence.new(BTN_TOP, BTN_BASE) end
		TweenService:Create(edge, TweenInfo.new(0.12), { Transparency = 1 }):Play()
		TweenService:Create(button, TweenInfo.new(0.12), { Size = baseSize }):Play()
	end)
end

-- popup-button styler (kept simple, own hover via AutoButtonColor)
local function styleButton(b, cA, cB)
	b.BackgroundColor3 = cA
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = true
	corner(b, 11)
	gradient(b, cB, cA, 90)
end

local gui = Instance.new("ScreenGui")
gui.Name = "TicketButton"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 200
gui.Parent = player:WaitForChild("PlayerGui")

-- ===== Corner dock =====
local dock = Instance.new("Frame")
dock.Name = "Dock"
dock.Size = UDim2.fromOffset(150, 0)
dock.AutomaticSize = Enum.AutomaticSize.Y
dock.Position = UDim2.fromOffset(14, 70)
dock.BackgroundTransparency = 1
dock.Parent = gui

local dockLayout = Instance.new("UIListLayout")
dockLayout.Padding = UDim.new(0, 8)
dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
dockLayout.Parent = dock

-- ===== Refund button =====
local REFUND_SIZE = UDim2.fromOffset(150, 58)
local btn = Instance.new("TextButton")
btn.Size = REFUND_SIZE
btn.LayoutOrder = 2
btn.Text = ""
btn.BackgroundColor3 = BTN_TOP
btn.AutoButtonColor = false
btn.Parent = dock
corner(btn, 11)
gradient(btn, BTN_TOP, BTN_BASE, 90)
addHover(btn, REFUND_SIZE)

local btnLabel = Instance.new("TextLabel")
btnLabel.Size = UDim2.new(1, 0, 0, 24)
btnLabel.Position = UDim2.fromOffset(0, 8)
btnLabel.BackgroundTransparency = 1
btnLabel.Text = "Request Refund"
btnLabel.TextColor3 = Color3.new(1, 1, 1)
btnLabel.Font = Enum.Font.GothamBold
btnLabel.TextSize = 15
btnLabel.Parent = btn
labelStroke(btnLabel)

-- Status pill
local STATUS = {
	on     = { label = "ON",     color = Color3.fromRGB(56, 170, 100) },
	paused = { label = "PAUSED", color = Color3.fromRGB(120, 124, 132) },
	off    = { label = "OFF",    color = Color3.fromRGB(200, 70, 85) },
}
local s = STATUS[mode] or STATUS.on
local pill = Instance.new("TextLabel")
pill.Size = UDim2.fromOffset(78, 20)
pill.Position = UDim2.new(0.5, 0, 0, 32)
pill.AnchorPoint = Vector2.new(0.5, 0)
pill.BackgroundColor3 = s.color
pill.Text = s.label
pill.TextColor3 = Color3.new(1, 1, 1)
pill.Font = Enum.Font.GothamBold
pill.TextSize = 12
pill.Parent = btn
corner(pill, 10)

-- ===== MY TICKETS (player-facing, read-only own status) =====
local getMyTickets = Remotes.get("GetMyTickets")

local MYT_SIZE = UDim2.fromOffset(150, 44)
local mytBtn = Instance.new("TextButton")
mytBtn.Size = MYT_SIZE
mytBtn.LayoutOrder = 3 -- below Refund (2)
mytBtn.Text = ""
mytBtn.BackgroundColor3 = BTN_TOP
mytBtn.AutoButtonColor = false
mytBtn.Parent = dock
corner(mytBtn, 11)
gradient(mytBtn, BTN_TOP, BTN_BASE, 90)
addHover(mytBtn, MYT_SIZE)

local mytLabel = Instance.new("TextLabel")
mytLabel.Size = UDim2.fromScale(1, 1)
mytLabel.BackgroundTransparency = 1
mytLabel.Text = "My Tickets"
mytLabel.TextColor3 = Color3.new(1, 1, 1)
mytLabel.Font = Enum.Font.GothamBold
mytLabel.TextSize = 14
mytLabel.Parent = mytBtn
labelStroke(mytLabel)

-- Panel
local mytDim = Instance.new("Frame")
mytDim.Size = UDim2.fromScale(1, 1)
mytDim.BackgroundColor3 = Color3.new(0, 0, 0)
mytDim.BackgroundTransparency = 0.45
mytDim.Visible = false
mytDim.ZIndex = 15
mytDim.Parent = gui

local mytPanel = Instance.new("Frame")
mytPanel.Size = UDim2.fromOffset(420, 440)
mytPanel.Position = UDim2.fromScale(0.5, 0.5)
mytPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mytPanel.BackgroundColor3 = PANEL_BG
mytPanel.ZIndex = 16
mytPanel.Parent = mytDim
corner(mytPanel, 14)
stroke(mytPanel, STROKE_C, 1.5, 0.3)

local mytHeader = Instance.new("Frame")
mytHeader.Size = UDim2.new(1, 0, 0, 48)
mytHeader.BackgroundColor3 = BTN_TOP
mytHeader.ZIndex = 16
mytHeader.Parent = mytPanel
corner(mytHeader, 14)
gradient(mytHeader, BTN_BASE, BTN_TOP, 0)

local mytTitle = Instance.new("TextLabel")
mytTitle.Size = UDim2.new(1, -60, 1, 0)
mytTitle.Position = UDim2.fromOffset(16, 0)
mytTitle.BackgroundTransparency = 1
mytTitle.TextXAlignment = Enum.TextXAlignment.Left
mytTitle.Text = "My Refund Tickets"
mytTitle.TextColor3 = Color3.new(1, 1, 1)
mytTitle.Font = Enum.Font.GothamBold
mytTitle.TextSize = 17
mytTitle.ZIndex = 17
mytTitle.Parent = mytHeader

local mytClose = Instance.new("TextButton")
mytClose.Size = UDim2.fromOffset(30, 30)
mytClose.Position = UDim2.new(1, -40, 0.5, -15)
mytClose.BackgroundColor3 = Color3.fromRGB(70, 76, 92)
mytClose.Text = "X"
mytClose.TextColor3 = Color3.new(1, 1, 1)
mytClose.Font = Enum.Font.GothamBold
mytClose.TextSize = 14
mytClose.ZIndex = 17
mytClose.Parent = mytHeader
corner(mytClose, 8)

local mytList = Instance.new("ScrollingFrame")
mytList.Size = UDim2.new(1, -24, 1, -68)
mytList.Position = UDim2.fromOffset(12, 58)
mytList.BackgroundTransparency = 1
mytList.BorderSizePixel = 0
mytList.ScrollBarThickness = 6
mytList.ScrollBarImageColor3 = BTN_BASE
mytList.CanvasSize = UDim2.new(0, 0, 0, 0)
mytList.AutomaticCanvasSize = Enum.AutomaticSize.Y
mytList.ZIndex = 16
mytList.Parent = mytPanel
local mytLayout = Instance.new("UIListLayout")
mytLayout.Padding = UDim.new(0, 8)
mytLayout.SortOrder = Enum.SortOrder.LayoutOrder
mytLayout.Parent = mytList

local function fmtDate(t)
	if not t or t == 0 then return "" end
	return os.date("!%Y-%m-%d", t)
end

local function renderMyTickets()
	for _, c in ipairs(mytList:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local tickets = {}
	local ok = pcall(function() tickets = getMyTickets:InvokeServer() end)
	if not ok then tickets = {} end

	if #tickets == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -4, 0, 60)
		empty.BackgroundTransparency = 1
		empty.Text = "You have no refund tickets yet."
		empty.TextColor3 = TEXT_SUB
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
		empty.ZIndex = 16
		empty.Parent = mytList
		return
	end

	table.sort(tickets, function(a, b) return a.createdAt > b.createdAt end)
	for _, t in ipairs(tickets) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -4, 0, 72)
		row.BackgroundColor3 = t.status == "paid" and Color3.fromRGB(34, 44, 36) or CARD_ISH
		row.ZIndex = 16
		row.Parent = mytList
		corner(row, 10)
		stroke(row, STROKE_C, 1, 0.55)

		local paidVia = t.paidVia and (" · via " .. tostring(t.paidVia)) or ""
		local info = Instance.new("TextLabel")
		info.Size = UDim2.new(1, -120, 1, -10)
		info.Position = UDim2.fromOffset(12, 5)
		info.BackgroundTransparency = 1
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextYAlignment = Enum.TextYAlignment.Top
		info.RichText = true
		info.TextWrapped = true
		info.Font = Enum.Font.Gotham
		info.TextColor3 = Color3.new(1, 1, 1)
		info.TextSize = 13
		info.ZIndex = 17
		info.Text = string.format(
			"<b>%d Robux</b>\n<font color='#beb2a8'>Ticket %s · %s%s</font>",
			t.amount, tostring(t.id), fmtDate(t.createdAt),
			t.status == "paid" and (paidVia) or "")
		info.Parent = row

		local pill = Instance.new("TextLabel")
		pill.Size = UDim2.fromOffset(96, 24)
		pill.Position = UDim2.new(1, -108, 0.5, -12)
		pill.BackgroundColor3 = t.status == "paid" and Color3.fromRGB(56, 170, 100) or Color3.fromRGB(210, 150, 50)
		pill.Text = t.status == "paid" and "PAID" or "PENDING"
		pill.TextColor3 = Color3.new(1, 1, 1)
		pill.Font = Enum.Font.GothamBold
		pill.TextSize = 12
		pill.ZIndex = 17
		pill.Parent = row
		corner(pill, 10)
	end
end

mytBtn.MouseButton1Click:Connect(function()
	mytDim.Visible = true
	renderMyTickets()
end)
mytClose.MouseButton1Click:Connect(function() mytDim.Visible = false end)

-- ===== Confirm popup =====
local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.45
dim.Visible = false
dim.ZIndex = 10
dim.Parent = gui

local box = Instance.new("Frame")
box.Size = UDim2.fromOffset(360, 180)
box.Position = UDim2.fromScale(0.5, 0.5)
box.AnchorPoint = Vector2.new(0.5, 0.5)
box.BackgroundColor3 = PANEL_BG
box.ZIndex = 11
box.Parent = dim
corner(box, 14)
stroke(box, STROKE_C, 1.5, 0.3)
local boxPad = Instance.new("UIPadding")
boxPad.PaddingTop = UDim.new(0,16) boxPad.PaddingBottom = UDim.new(0,16)
boxPad.PaddingLeft = UDim.new(0,16) boxPad.PaddingRight = UDim.new(0,16)
boxPad.Parent = box

local msg = Instance.new("TextLabel")
msg.Size = UDim2.new(1, 0, 0, 26)
msg.BackgroundTransparency = 1
msg.TextXAlignment = Enum.TextXAlignment.Left
msg.TextYAlignment = Enum.TextYAlignment.Top
msg.Text = "Request a refund?"
msg.TextColor3 = TEXT_SUB
msg.Font = Enum.Font.Gotham
msg.TextSize = 14
msg.ZIndex = 12
msg.Parent = box

local owedLabel = Instance.new("TextLabel")
owedLabel.Size = UDim2.new(1, 0, 0, 28)
owedLabel.Position = UDim2.fromOffset(0, 34)
owedLabel.BackgroundTransparency = 1
owedLabel.TextXAlignment = Enum.TextXAlignment.Left
owedLabel.Font = Enum.Font.GothamBold
owedLabel.TextSize = 18
owedLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
owedLabel.Text = ""
owedLabel.ZIndex = 12
owedLabel.Parent = box

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(1, 0, 0, 36)
subLabel.Position = UDim2.fromOffset(0, 66)
subLabel.BackgroundTransparency = 1
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.TextYAlignment = Enum.TextYAlignment.Top
subLabel.TextWrapped = true
subLabel.Font = Enum.Font.Gotham
subLabel.TextSize = 13
subLabel.TextColor3 = TEXT_SUB
subLabel.Text = "The owner reviews and pays this out manually."
subLabel.ZIndex = 12
subLabel.Parent = box

local function popBtn(text, cA, cB, anchorX, xScale)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(150, 40)
	b.Position = UDim2.new(xScale, 0, 1, 0)
	b.AnchorPoint = Vector2.new(anchorX, 1)
	b.Text = text
	b.TextSize = 14
	b.ZIndex = 12
	b.Parent = box
	styleButton(b, cA, cB)
	return b
end
local confirmBtn = popBtn("Yes, request", GREEN_A, GREEN_B, 0, 0)
local cancelBtn  = popBtn("Cancel", GREY, Color3.fromRGB(98,104,120), 1, 1)

-- ===== Open / fire =====
btn.MouseButton1Click:Connect(function()
	if mode == "off" then
		owedLabel.Text = "Refunds Closed"
		owedLabel.TextColor3 = Color3.fromRGB(224, 86, 106)
		subLabel.Text = "Refunds are currently closed."
		confirmBtn.Visible = false
		cancelBtn.Text = "OK"
		dim.Visible = true
		box.Size = UDim2.fromOffset(344, 172)
		TweenService:Create(box, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(360, 180) }):Play()
		return
	end
	if mode == "paused" then
		owedLabel.Text = "Refunds Paused"
		owedLabel.TextColor3 = Color3.fromRGB(226, 162, 70)
		subLabel.Text = Shared.REFUND_PAUSED_MESSAGE
		confirmBtn.Visible = false
		cancelBtn.Text = "OK"
		dim.Visible = true
		box.Size = UDim2.fromOffset(344, 172)
		TweenService:Create(box, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(360, 180) }):Play()
		return
	end

	cancelBtn.Text = "Cancel"
	local owed = 0
	local ok = pcall(function() owed = getOwed:InvokeServer() end)
	if not ok then owed = 0 end
	if owed <= 0 then
		owedLabel.Text = "Nothing to refund yet"
		owedLabel.TextColor3 = Color3.fromRGB(200, 170, 90)
		subLabel.Text = "Make an eligible purchase first, then come back."
		confirmBtn.Visible = false
	else
		owedLabel.Text = ("Pending refund: %d Robux"):format(owed)
		owedLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
		subLabel.Text = "The owner reviews and pays this out manually."
		confirmBtn.Visible = true
	end
	dim.Visible = true
	box.Size = UDim2.fromOffset(344, 172)
	TweenService:Create(box, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(360, 180) }):Play()
end)

cancelBtn.MouseButton1Click:Connect(function() dim.Visible = false end)
confirmBtn.MouseButton1Click:Connect(function()
	dim.Visible = false
	submitTicket:FireServer("Requesting my refund")
end)

-- ===== Toast =====
local function toast(title, body)
	local t = Instance.new("Frame")
	t.Size = UDim2.fromOffset(320, 70)
	t.Position = UDim2.new(0.5, 0, 0, 16)
	t.AnchorPoint = Vector2.new(0.5, 0)
	t.BackgroundColor3 = PANEL_BG
	t.ZIndex = 20
	t.Parent = gui
	corner(t, 12)
	stroke(t, BTN_BASE, 1.5, 0.2)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0,10) p.PaddingBottom = UDim.new(0,10)
	p.PaddingLeft = UDim.new(0,12) p.PaddingRight = UDim.new(0,12)
	p.Parent = t

	local h = Instance.new("TextLabel")
	h.Size = UDim2.new(1, 0, 0, 22)
	h.BackgroundTransparency = 1
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.Text = title
	h.TextColor3 = Color3.fromRGB(130, 200, 255)
	h.Font = Enum.Font.GothamBold
	h.TextSize = 15
	h.ZIndex = 21
	h.Parent = t

	local b = Instance.new("TextLabel")
	b.Size = UDim2.new(1, 0, 1, -22)
	b.Position = UDim2.fromOffset(0, 22)
	b.BackgroundTransparency = 1
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.TextYAlignment = Enum.TextYAlignment.Top
	b.TextWrapped = true
	b.Text = body
	b.TextColor3 = TEXT_SUB
	b.Font = Enum.Font.Gotham
	b.TextSize = 13
	b.ZIndex = 21
	b.Parent = t

	t.Position = UDim2.new(0.5, 0, 0, 4)
	TweenService:Create(t, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 0, 16) }):Play()
	task.delay(4.5, function() t:Destroy() end)
end
showNotification.OnClientEvent:Connect(toast)