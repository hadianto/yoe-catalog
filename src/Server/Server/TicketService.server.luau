-- TicketService.server.lua  (Script in ServerScriptService > Server)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))
local DataManager = require(ServerScriptService.Server:WaitForChild("DataManager"))
local TicketStore = require(ServerScriptService.Server:WaitForChild("TicketStore"))

local REFUND_RATE = 0.2

local function isAdmin(player)
	return table.find(Shared.ADMIN_IDS, player.UserId) ~= nil
end

-- ===== SUBMIT (any player) =====
local lastSubmit = {}
Remotes.get("SubmitTicket").OnServerEvent:Connect(function(player, note)
	if (Shared.REFUND_MODE or "on") ~= "on" then return end  -- only accept when fully on
	note = type(note) == "string" and note:sub(1, 200) or ""
	local now = os.time()
	if lastSubmit[player] and now - lastSubmit[player] < 30 then return end -- rate limit
	lastSubmit[player] = now

	local data = DataManager.getProfile(player)
	if not data then return end
	local p = data.Purchases

	local eligible = (p.CatalogSpend or 0) + (p.BundleSpend or 0)
	local unclaimed = eligible - (p.RefundClaimedSpend or 0)
	local owed = math.floor(unclaimed * REFUND_RATE)
	if owed <= 0 then
		Remotes.get("ShowNotification"):FireClient(player, "No Refund Due",
			"You have no new refundable spend yet.")
		return
	end
	p.RefundClaimedSpend = eligible -- claim it now so it cannot be re-ticketed

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
		p.RefundClaimedSpend = eligible - unclaimed -- rollback the claim on failure
		Remotes.get("ShowNotification"):FireClient(player, "Error",
			"Could not save ticket. Try again shortly.")
	end
end)
-- ===== PREVIEW (any player): current owed amount, no rate disclosed =====
Remotes.get("GetOwed").OnServerInvoke = function(player)
	if (Shared.REFUND_MODE or "on") ~= "on" then return 0 end
	local data = DataManager.getProfile(player)
	if not data then return 0 end
	local p = data.Purchases
	local eligible = (p.CatalogSpend or 0) + (p.BundleSpend or 0)
	local unclaimed = eligible - (p.RefundClaimedSpend or 0)
	return math.max(0, math.floor(unclaimed * REFUND_RATE))
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