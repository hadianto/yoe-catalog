-- ItemBuyerLocalScript  (StarterPlayer > StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))
local trackRemote = Remotes.get("TrackPurchase")

-- Membership block (toggleable in Shared)
local blockedMember = false
task.spawn(function()
	local gid = Shared.COMMUNITY_GROUP_ID
	if Shared.BLOCK_MEMBERS_FROM_BUYING and gid and gid ~= 0 then
		local ok, inGroup = pcall(function() return player:IsInGroup(gid) end)
		if ok and inGroup then blockedMember = true end
	end
end)

local screenGui = player:WaitForChild("PlayerGui"):WaitForChild("ItemBuyer")
local panel = screenGui:WaitForChild("Frame"):WaitForChild("Frame")
local button_frame = panel:WaitForChild("ButtonFrame")
local catalog_button = button_frame:WaitForChild("Catalog")
local bundles_button = button_frame:WaitForChild("Bundles")
local plus_button = button_frame:WaitForChild("Plus")
local topbar = panel:WaitForChild("TopBar")
local topbar_title = topbar:WaitForChild("TextLabel")
local text_box = panel:WaitForChild("TextBox")
local button = panel:WaitForChild("TextButton")
local back_button = topbar:WaitForChild("Back")
local soundsFolder = screenGui:WaitForChild("UISounds")
local UIClickSound = soundsFolder:WaitForChild("UIClick")
------------------------------------------------------------------------
local function change_tab(title)
	topbar_title.Text = title
	text_box.Visible = not text_box.Visible
	button.Visible = not button.Visible
	button_frame.Visible = not button_frame.Visible
	back_button.Visible = not back_button.Visible
end
local function check_tab()
	return topbar_title.Text
end
------------------------------------------------------------------------
catalog_button.MouseButton1Click:Connect(function()
	UIClickSound:Play()
	change_tab("Catalog")
end)
bundles_button.MouseButton1Click:Connect(function()
	UIClickSound:Play()
	change_tab("Bundles")
end)
plus_button.MouseButton1Click:Connect(function()
	UIClickSound:Play()
	MarketplaceService:PromptRobloxSubscriptionPurchase(player)
end)
-- Show the Plus refund reward under the Plus button (flat, from config)
local plusReward = math.floor((Shared.PLUS_BONUS or 0) * (Shared.PLUS_REFUND_SHARE or 0))
if Shared.PLUS_REWARD_ENABLED and plusReward > 0 then
	local rewardTag = Instance.new("TextLabel")
	rewardTag.Name = "PlusRewardTag"
	rewardTag.Size = UDim2.new(1, 0, 0, 16)
	rewardTag.Position = UDim2.new(0, 0, 1, 2)  -- just below the button
	rewardTag.BackgroundTransparency = 1
	rewardTag.Text = ("Get %d Robux back on signup"):format(plusReward)
	rewardTag.TextColor3 = Color3.fromRGB(96, 200, 132)  -- green, reads as a perk
	rewardTag.Font = Enum.Font.GothamMedium
	rewardTag.TextSize = 11
	rewardTag.TextXAlignment = Enum.TextXAlignment.Center
	rewardTag.Parent = plus_button
end
------------------------------------------------------------------------
back_button.MouseButton1Click:Connect(function()
	UIClickSound:Play()
	change_tab("By Yoe | Version 1.0")
end)
button.MouseButton1Click:Connect(function()
	if blockedMember then
		topbar_title.Text = "Members can't purchase here"
		return
	end
	if check_tab() == "Catalog" then
		MarketplaceService:PromptPurchase(player, tonumber(text_box.Text))
	elseif check_tab() == "Bundles" then
		MarketplaceService:PromptBundlePurchase(player, tonumber(text_box.Text))
	elseif check_tab() == "Plus" then
		MarketplaceService:PromptRobloxSubscriptionPurchase(player)
	end
end)
------------------------------------------------------------------------
MarketplaceService.PromptPurchaseFinished:Connect(function(plr, assetId, isPurchased)
	if isPurchased then trackRemote:FireServer("Catalog", assetId) end
end)
MarketplaceService.PromptBundlePurchaseFinished:Connect(function(plr, bundleId, wasPurchased)
	if wasPurchased then trackRemote:FireServer("Bundle", bundleId) end
end)