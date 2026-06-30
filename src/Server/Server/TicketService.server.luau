-- TicketService.server.lua  (Script in ServerScriptService > Server)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))
local DataManager = require(ServerScriptService.Server:WaitForChild("DataManager"))
local TicketStore = require(ServerScriptService.Server:WaitForChild("TicketStore"))

local REFUND_RATE = Shared.REFUND_RATE or 0.2
-- Plus reward = a fraction of the bonus you actually earn per eligible signup
local PLUS_REWARD = math.floor((Shared.PLUS_BONUS or 0) * (Shared.PLUS_REFUND_SHARE or 0))

local function isAdmin(player)
	return table.find(Shared.ADMIN_IDS, player.UserId) ~= nil
end

Remotes.get("GetHistory").OnServerInvoke = function(player, query)
	if not isAdmin(player) then return nil end
	if type(query) ~= "string" then return nil end
	query = query:gsub("%s", "")
	if query == "" then return nil end

	-- Resolve query to a UserId: accept a numeric id or a username
	local userId = tonumber(query)
	if not userId then
		local ok, id = pcall(function()
			return Players:GetUserIdFromNameAsync(query)
		end)
		if ok and id then userId = id end
	end
	if not userId then return { error = "Player not found" } end

	local data = DataManager.viewProfile(userId)
	if not data then return { error = "No saved data for that player" } end

	local p = data.Purchases
	return {
		userId = userId,
		catalogSpend = p.CatalogSpend or 0,
		bundleSpend = p.BundleSpend or 0,
		refundClaimedSpend = p.RefundClaimedSpend or 0,
		plusEligible = p.PlusEligibleConversions or 0,
		plusTotal = p.PlusConversions or 0,
		refundClaimedPlus = p.RefundClaimedPlus or 0,
		history = p.History or {},
	}
end

-- Single source of truth for the owed calculation, used by BOTH preview and submit.
-- Returns: total owed, and the component breakdown needed to claim correctly.
local function computeOwed(p)
	local eligibleSpend = (p.CatalogSpend or 0) + (p.BundleSpend or 0)
	local unclaimedSpend = math.max(0, eligibleSpend - (p.RefundClaimedSpend or 0))
	local spendRefund = math.floor(unclaimedSpend * REFUND_RATE)

	local plusRefund = 0
	local eligiblePlus = p.PlusEligibleConversions or 0
	if Shared.PLUS_REWARD_ENABLED then
		local unclaimedPlus = math.max(0, eligiblePlus - (p.RefundClaimedPlus or 0))
		plusRefund = unclaimedPlus * PLUS_REWARD
	end

	return spendRefund + plusRefund, eligibleSpend, eligiblePlus
end

-- ===== SUBMIT (any player) =====
local lastSubmit = {}
Remotes.get("SubmitTicket").OnServerEvent:Connect(function(player, note)
	if (Shared.REFUND_MODE or "on") ~= "on" then return end
	note = type(note) == "string" and note:sub(1, 200) or ""
	local now = os.time()
	if lastSubmit[player] and now - lastSubmit[player] < 30 then return end
	lastSubmit[player] = now

	local data = DataManager.getProfile(player)
	if not data then return end
	local p = data.Purchases

	local owed, eligibleSpend, eligiblePlus = computeOwed(p)
	if owed <= 0 then
		Remotes.get("ShowNotification"):FireClient(player, "No Refund Due",
			"You have no new refundable spend yet.")
		return
	end

	-- claim BOTH pools now so neither can be re-ticketed
	local prevClaimedSpend = p.RefundClaimedSpend or 0
	local prevClaimedPlus  = p.RefundClaimedPlus or 0
	p.RefundClaimedSpend = eligibleSpend
	p.RefundClaimedPlus  = eligiblePlus

	local ticket = {
		id = HttpService:GenerateGUID(false):sub(1, 8),
		userId = player.UserId,
		userName = player.Name,
		kind = "Refund",
		note = note,
		amount = owed,
		status = "outstanding",
		createdAt = now,
		paidAt = 0,
	}
	local ok = TicketStore.create(ticket)
	if ok then
		Remotes.get("ShowNotification"):FireClient(player, "Ticket Created",
			("Refund of %d Robux logged. ID: %s"):format(owed, ticket.id))
		print(("[Ticket] %s filed %s for %d Robux"):format(player.Name, ticket.id, owed))
	else
		-- rollback BOTH claims on failure
		p.RefundClaimedSpend = prevClaimedSpend
		p.RefundClaimedPlus  = prevClaimedPlus
		Remotes.get("ShowNotification"):FireClient(player, "Error",
			"Could not save ticket. Try again shortly.")
	end
end)

-- ===== PREVIEW (any player): final owed only, no rate/breakdown disclosed =====
Remotes.get("GetOwed").OnServerInvoke = function(player)
	if (Shared.REFUND_MODE or "on") ~= "on" then return 0 end
	local data = DataManager.getProfile(player)
	if not data then return 0 end
	local owed = computeOwed(data.Purchases)
	return math.max(0, owed)
end

-- ===== FETCH (admin only) =====
Remotes.get("GetTickets").OnServerInvoke = function(player)
	if not isAdmin(player) then return {} end
	return TicketStore.getAll()
end

-- ===== UPDATE (admin only) =====
Remotes.get("UpdateTicket").OnServerEvent:Connect(function(player, ticketId, newStatus)
	if not isAdmin(player) then return end
	if type(ticketId) ~= "string" then return end
	if newStatus ~= "outstanding" and newStatus ~= "paid" then return end
	TicketStore.updateStatus(ticketId, newStatus, player.UserId)
	print(("[Ticket] %s set %s -> %s"):format(player.Name, ticketId, newStatus))
end)

Players.PlayerRemoving:Connect(function(player)
	lastSubmit[player] = nil
end)