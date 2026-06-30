-- AdminTicketsClient  (LocalScript in StarterPlayerScripts) 
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer


local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
if not table.find(Shared.ADMIN_IDS, player.UserId) then
	return
end

local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))
local getTickets = Remotes.get("GetTickets")
local updateTicket = Remotes.get("UpdateTicket")

local T = Shared.THEME
local ACCENT_A = T.accentA
local ACCENT_B = T.accentB
local PANEL_BG = T.panelBg
local CARD_BG  = T.cardBg
local CARD_PAID = T.cardPaid
local STROKE_C = T.stroke
local GREEN_A  = T.successA
local GREEN_B  = T.successB
local AMBER    = T.warn
local IDLE_FILTER = T.idle

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
gui.Name = "AdminTickets"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 210
gui.Parent = player:WaitForChild("PlayerGui")

local ticketGui = player.PlayerGui:WaitForChild("TicketButton", 10)
local dock = ticketGui and ticketGui:WaitForChild("Dock", 5)
if not dock then
	dock = Instance.new("Frame")
	dock.Name = "Dock"
	dock.Size = UDim2.fromOffset(150, 0)
	dock.AutomaticSize = Enum.AutomaticSize.Y
	dock.Position = UDim2.fromOffset(14, 70)
	dock.BackgroundTransparency = 1
	dock.Parent = gui
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.HorizontalAlignment = Enum.HorizontalAlignment.Left
	l.Parent = dock
end

local TICKET_SIZE = UDim2.fromOffset(150, 58)
local toggle = Instance.new("TextButton")
toggle.Size = TICKET_SIZE
toggle.LayoutOrder = 1
toggle.Text = ""
toggle.BackgroundColor3 = BTN_TOP
toggle.AutoButtonColor = false
toggle.Parent = dock
corner(toggle, 11)
gradient(toggle, BTN_TOP, BTN_BASE, 90)
addHover(toggle, TICKET_SIZE)

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.fromScale(1, 1)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Tickets"
toggleLabel.TextColor3 = Color3.new(1, 1, 1)
toggleLabel.Font = Enum.Font.GothamBold
toggleLabel.TextSize = 15
toggleLabel.Parent = toggle
labelStroke(toggleLabel)

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(560, 480)
panel.Position = UDim2.new(0.5, -280, 0.5, -240)
panel.BackgroundColor3 = PANEL_BG
panel.Visible = false
panel.Parent = gui
corner(panel, 14)
stroke(panel, STROKE_C, 1.5, 0.3)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = ACCENT_A
header.Parent = panel
corner(header, 14)
gradient(header, ACCENT_B, ACCENT_A, 0)

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -190, 1, 0)
headerLabel.Position = UDim2.fromOffset(16, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Text = "Ticket Queue"
headerLabel.TextColor3 = Color3.new(1, 1, 1)
headerLabel.Font = Enum.Font.GothamBold
headerLabel.TextSize = 18
headerLabel.Parent = header

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.fromOffset(86, 32)
refreshBtn.Position = UDim2.new(1, -98, 0.5, -16)
refreshBtn.BackgroundColor3 = GREEN_A
refreshBtn.Text = "Refresh"
refreshBtn.TextColor3 = Color3.new(1, 1, 1)
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.TextSize = 14
refreshBtn.AutoButtonColor = true
refreshBtn.Parent = header
corner(refreshBtn, 9)
gradient(refreshBtn, GREEN_B, GREEN_A, 90)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -190, 0.5, -16)
closeBtn.BackgroundColor3 = Color3.fromRGB(70, 76, 92)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = true
closeBtn.Parent = header
corner(closeBtn, 8)

local filterBar = Instance.new("Frame")
filterBar.Size = UDim2.new(1, -24, 0, 34)
filterBar.Position = UDim2.fromOffset(12, 62)
filterBar.BackgroundTransparency = 1
filterBar.Parent = panel

local currentFilter = "outstanding"
local filterButtons = {}
local render

local function makeFilter(name, label, order)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(124, 30)
	b.Position = UDim2.fromOffset((order - 1) * 132, 2)
	b.Text = label
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.AutoButtonColor = true
	b.BackgroundColor3 = IDLE_FILTER
	b.Parent = filterBar
	corner(b, 9)
	filterButtons[name] = b
	b.MouseButton1Click:Connect(function() currentFilter = name render() end)
end
makeFilter("outstanding", "Outstanding", 1)
makeFilter("paid", "Paid", 2)
makeFilter("all", "All", 3)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -24, 1, -110)
list.Position = UDim2.fromOffset(12, 100)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = ACCENT_B
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function makeRow(ticket)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 78)
	row.BackgroundColor3 = ticket.status == "paid" and CARD_PAID or CARD_BG
	row.Parent = list
	corner(row, 11)
	stroke(row, STROKE_C, 1, 0.55)

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -130, 1, -12)
	info.Position = UDim2.fromOffset(12, 6)
	info.BackgroundTransparency = 1
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.RichText = true
	info.TextWrapped = true
	info.Font = Enum.Font.Gotham
	info.TextColor3 = Color3.new(1, 1, 1)
	info.TextSize = 13
	info.Text = string.format(
		"<b>%s</b>  <font color='#9aa6c0'>(%d)</font>\n<font color='#9aa6c0'>ID %s  ·  owed</font> <b>%d</b> <font color='#9aa6c0'>Robux</font>\n<font color='#9aa6c0'>%s</font>",
		ticket.userName, ticket.userId, ticket.id, ticket.amount,
		ticket.note ~= "" and ticket.note or "(no note)")
	info.Parent = row

	local pill = Instance.new("TextLabel")
	pill.Size = UDim2.fromOffset(104, 22)
	pill.Position = UDim2.new(1, -114, 0, 8)
	pill.BackgroundColor3 = ticket.status == "paid" and GREEN_A or AMBER
	pill.Text = ticket.status == "paid" and "PAID" or "OUTSTANDING"
	pill.TextColor3 = Color3.new(1, 1, 1)
	pill.Font = Enum.Font.GothamBold
	pill.TextSize = 11
	pill.Parent = row
	corner(pill, 11)

	if ticket.status == "outstanding" then
		local pay = Instance.new("TextButton")
		pay.Size = UDim2.fromOffset(104, 32)
		pay.Position = UDim2.new(1, -114, 1, -40)
		pay.BackgroundColor3 = GREEN_A
		pay.Text = "Mark Paid"
		pay.TextColor3 = Color3.new(1, 1, 1)
		pay.Font = Enum.Font.GothamBold
		pay.TextSize = 13
		pay.AutoButtonColor = true
		pay.Parent = row
		corner(pay, 9)
		gradient(pay, GREEN_B, GREEN_A, 90)
		pay.MouseButton1Click:Connect(function()
			pay.Text = "..."
			updateTicket:FireServer(ticket.id, "paid")
			task.wait(0.6)
			render()
		end)
	end
end

render = function()
	for name, b in pairs(filterButtons) do
		b.BackgroundColor3 = (name == currentFilter) and ACCENT_A or IDLE_FILTER
	end
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local tickets = getTickets:InvokeServer()
	table.sort(tickets, function(a, b)
		if a.status ~= b.status then return a.status == "outstanding" end
		return a.createdAt > b.createdAt
	end)
	local openCount, owed = 0, 0
	for _, t in ipairs(tickets) do
		if t.status == "outstanding" then openCount += 1 owed += t.amount end
		if currentFilter == "all" or t.status == currentFilter then makeRow(t) end
	end
	headerLabel.Text = ("Tickets · %d open · %d owed"):format(openCount, owed)
end

local function openPanel(open)
	if open then
		panel.Visible = true
		panel.Size = UDim2.fromOffset(540, 460)
		TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(560, 480) }):Play()
		render()
	else
		panel.Visible = false
	end
end

toggle.MouseButton1Click:Connect(function() openPanel(not panel.Visible) end)
refreshBtn.MouseButton1Click:Connect(render)
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)