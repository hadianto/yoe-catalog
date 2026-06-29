-- PurchaseTracker.server.lua  (Script in ServerScriptService > Server)
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService:WaitForChild("Server"):WaitForChild("DataManager"))
local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))

local REFUND_RATE = 0.2 -- displayed as the player's pending cashback

local function getData(player)
	return DataManager.getProfile(player)
end

local function logHistory(data, entry)
	local h = data.Purchases.History
	table.insert(h, entry)
	if #h > 100 then table.remove(h, 1) end
end

-- ===== LEADERBOARD =====
-- Columns: Plus (conversion count), Catalog (20% of catalog spend),
-- Bundles (20% of bundle spend). Stored values are full Robux; we show 20%.
local function refreshLeaderstats(player)
	local data = getData(player)
	if not data then return end
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	stats.Plus.Value = data.Purchases.PlusConversions
	stats.Catalog.Value = math.floor(data.Purchases.CatalogSpend * REFUND_RATE)
	stats.Bundles.Value = math.floor(data.Purchases.BundleSpend * REFUND_RATE)
end

local function setupLeaderstats(player, data)
	if player:FindFirstChild("leaderstats") then return end
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local plus = Instance.new("IntValue")
	plus.Name = "Plus"
	plus.Value = data.Purchases.PlusConversions
	plus.Parent = stats

	local catalog = Instance.new("IntValue")
	catalog.Name = "Catalog"
	catalog.Value = math.floor(data.Purchases.CatalogSpend * REFUND_RATE)
	catalog.Parent = stats

	local bundles = Instance.new("IntValue")
	bundles.Name = "Bundles"
	bundles.Value = math.floor(data.Purchases.BundleSpend * REFUND_RATE)
	bundles.Parent = stats

	stats.Parent = player
end

DataManager.onProfileLoaded(setupLeaderstats)
-- Cover anyone whose profile already loaded before this script ran:
for _, p in ipairs(Players:GetPlayers()) do
	local data = getData(p)
	if data then setupLeaderstats(p, data) end
end

-- ===== DEVPRODUCTS (no column, but real-charge proof) =====
MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local data = getData(player)
	if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end

	if data.Purchases.ReceiptIds[receipt.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	data.Purchases.ReceiptIds[receipt.PurchaseId] = true

	local robux = receipt.CurrencySpent or 0
	data.Purchases.DevProductSpend += robux
	data.Purchases.DevProductCount += 1
	logHistory(data, { kind = "DevProduct", id = receipt.ProductId, robux = robux, at = os.time() })
	print(("[Tracker] %s bought devproduct %d for %d Robux"):format(player.Name, receipt.ProductId, robux))

	-- TODO grant the actual product effect here
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ===== ROBLOX PLUS (Plus column) =====
local watching = {}
local function watchPlus(player)
	if watching[player] or player.HasRobloxSubscription then return end
	local conn
	conn = player:GetPropertyChangedSignal("HasRobloxSubscription"):Connect(function()
		if player.HasRobloxSubscription then
			local data = getData(player)
			if data then
				data.Purchases.PlusConversions += 1
				data.Purchases.PlusLastConvertedAt = os.time()
				logHistory(data, { kind = "Plus", at = os.time() })
				refreshLeaderstats(player)
				print(("[Tracker] %s converted to Roblox Plus in-game"):format(player.Name))
			end
			conn:Disconnect()
			watching[player] = nil
		end
	end)
	watching[player] = conn
end

Players.PlayerAdded:Connect(watchPlus)
for _, p in ipairs(Players:GetPlayers()) do watchPlus(p) end
Players.PlayerRemoving:Connect(function(player)
	local conn = watching[player]
	if conn then conn:Disconnect(); watching[player] = nil end
end)

-- ===== GAMEPASS / CATALOG / BUNDLE (Catalog + Bundles columns) =====
local trackRemote = Remotes.get("TrackPurchase")
trackRemote.OnServerEvent:Connect(function(player, kind, id)
	if typeof(id) ~= "number" then return end
	local data = getData(player)
	if not data then return end

	if kind == "Gamepass" then
		local owns = false
		pcall(function() owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, id) end)
		if not owns then return end
		data.Purchases.GamepassCount += 1
		local price = 0
		pcall(function()
			price = MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass).PriceInRobux or 0
		end)
		logHistory(data, { kind = "Gamepass", id = id, robux = price, at = os.time() })

	elseif kind == "Catalog" then
		local owns = false
		pcall(function() owns = MarketplaceService:PlayerOwnsAssetAsync(player, id) end)
		if not owns then return end
		local price = 0
		pcall(function()
			price = MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset).PriceInRobux or 0
		end)
		data.Purchases.CatalogSpend += price
		logHistory(data, { kind = "Catalog", id = id, robux = price, at = os.time() })
		refreshLeaderstats(player)

	elseif kind == "Bundle" then
		local owns = false
		pcall(function() owns = MarketplaceService:PlayerOwnsBundleAsync(player, id) end)
		if not owns then return end
		local price = 0
		pcall(function()
			price = MarketplaceService:GetProductInfo(id, Enum.InfoType.Bundle).PriceInRobux or 0
		end)
		data.Purchases.BundleSpend += price
		logHistory(data, { kind = "Bundle", id = id, robux = price, at = os.time() })
		refreshLeaderstats(player)
	end
end)