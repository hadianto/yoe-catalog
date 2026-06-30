-- AdminCommands.server.lua  (Script in ServerScriptService > Server)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local DataManager = require(ServerScriptService.Server:WaitForChild("DataManager"))
local TicketStore = require(ServerScriptService.Server:WaitForChild("TicketStore"))

local function isAdmin(p) return table.find(Shared.ADMIN_IDS, p.UserId) ~= nil end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		if not isAdmin(player) then return end
		local cmd = msg:lower()

		-- /clearme : wipe YOUR OWN purchase record (test data cleanup)
		if cmd == "/clearme" then
			local data = DataManager.getProfile(player)
			if data then
				local p = data.Purchases
				p.History = {}
				p.CatalogSpend = 0
				p.BundleSpend = 0
				p.RefundClaimedSpend = 0
				p.PlusConversions = 0
				p.PlusEligibleConversions = 0
				p.RefundClaimedPlus = 0
				p.DevProductSpend = 0
				p.DevProductCount = 0
				p.GamepassCount = 0
				p.ReceiptIds = {}
				-- refresh leaderstats if present
				local stats = player:FindFirstChild("leaderstats")
				if stats then
					if stats:FindFirstChild("Plus") then stats.Plus.Value = 0 end
					if stats:FindFirstChild("Catalog") then stats.Catalog.Value = 0 end
					if stats:FindFirstChild("Bundles") then stats.Bundles.Value = 0 end
				end
				print(("[Admin] %s cleared their own record"):format(player.Name))
			end

			-- /cleartickets : WIPE ALL TICKETS from the store (use before going live)
		elseif cmd == "/cleartickets" then
			local ok = TicketStore.clearAll()
			print(("[Admin] %s cleared all tickets (ok=%s)"):format(player.Name, tostring(ok)))
		end
	end)
end)