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
local ACCENT_A = T.accentA
local ACCENT_B = T.accentB
local PANEL_BG = T.panelBg
local STROKE_C = T.stroke
local TEXT_SUB = T.textSub
local GREEN_A  = T.successA
local GREEN_B  = T.successB
local GREY     = T.neutral

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = p end
local function stroke(p, col, th, tr) local s = Instance.new("UIStroke") s.Color = col or STROKE_C s.Thickness = th or 1.5 s.Transparency = tr or 0.4 s.Parent = p return s end
local function gradient(p, c1, c2, rot) local g = Instance.new("UIGradient") g.Color = ColorSequence.new(c1, c2) g.Rotation = rot or 90 g.Parent = p return g end
local function styleButton(b, cA, cB)
	b.BackgroundColor3 = cA
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = false
	corner(b, 11)
	gradient(b, cB, cA, 90)
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.13), { BackgroundColor3 = cB }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.13), { BackgroundColor3 = cA }):Play() end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "TicketButton"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 200
gui.Parent = player:WaitForChild("PlayerGui")

-- ===== Corner dock: a tidy vertical stack, top-left, below Roblox's topbar =====
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
dockLayout.Parent = dock

-- Refund button (LayoutOrder 2 so admin Tickets sits above at 1)
local btn = Instance.new("TextButton")
btn.Size = UDim2.fromOffset(150, 54)
btn.LayoutOrder = 2
btn.Text = "Request Refund"
btn.TextSize = 15
btn.Parent = dock
styleButton(btn, ACCENT_A, ACCENT_B)
stroke(btn, Color3.fromRGB(120, 175, 255), 1.5, 0.35)
-- Status badge appended to the button label, colored via RichText
btn.RichText = true
btn.TextWrapped = true
local function badgeFor(m)
	if m == "on" then
		return '  <font color="#46b46c">[ON]</font>'      -- green
	elseif m == "paused" then
		return '  <font color="#e2a246">[PAUSED]</font>'   -- amber
	else
		return '  <font color="#e0566a">[OFF]</font>'      -- red
	end
end
btn.Text = '<font size="15">Request Refund</font>\n<font size="12">' .. badgeFor(mode) .. '</font>'

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

-- Title
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

-- Owed amount (big)
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

-- Sub line
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

-- Popup buttons
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

-- ===== Open / fire (single handler, defined AFTER confirmBtn exists) =====
btn.MouseButton1Click:Connect(function()
	if mode == "off" then
		owedLabel.Text = "Refunds Closed"
		owedLabel.TextColor3 = Color3.fromRGB(224, 86, 106) -- red
		subLabel.Text = "Refunds are currently closed."
		confirmBtn.Visible = false
		cancelBtn.Text = "OK"
		dim.Visible = true
		box.Size = UDim2.fromOffset(344, 172)
		TweenService:Create(box, TweenInfo.new(0.18, Enum.EasingStyle.Back),
			{ Size = UDim2.fromOffset(360, 180) }):Play()
		return
	end
	if mode == "paused" then
		-- (the paused info popup from before)
		owedLabel.Text = "Refunds Paused"
		owedLabel.TextColor3 = Color3.fromRGB(226, 162, 70)
		subLabel.Text = Shared.REFUND_PAUSED_MESSAGE
		confirmBtn.Visible = false
		cancelBtn.Text = "OK"
		dim.Visible = true
		box.Size = UDim2.fromOffset(344, 172)
		TweenService:Create(box, TweenInfo.new(0.18, Enum.EasingStyle.Back),
			{ Size = UDim2.fromOffset(360, 180) }):Play()
		return
	end

	-- mode == "on": the normal owed-check flow you already have
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
	TweenService:Create(box, TweenInfo.new(0.18, Enum.EasingStyle.Back),
		{ Size = UDim2.fromOffset(360, 180) }):Play()
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
	stroke(t, ACCENT_A, 1.5, 0.2)
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