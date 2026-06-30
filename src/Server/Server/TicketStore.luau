-- TicketStore.lua  (ModuleScript in ServerScriptService > Server)
local DataStoreService = game:GetService("DataStoreService")

local TicketStore = {}
local store = DataStoreService:GetDataStore("Tickets_v1")
local KEY = "AllTickets"
local MAX = 500

function TicketStore.create(ticket)
	local ok, err = pcall(function()
		store:UpdateAsync(KEY, function(old)
			old = old or {}
			table.insert(old, ticket)
			-- prune: when over cap, drop the oldest PAID ticket first
			if #old > MAX then
				for i = 1, #old do
					if old[i].status == "paid" then
						table.remove(old, i)
						break
					end
				end
				if #old > MAX then table.remove(old, 1) end
			end
			return old
		end)
	end)
	return ok, err
end

function TicketStore.getAll()
	local ok, result = pcall(function() return store:GetAsync(KEY) end)
	if ok and type(result) == "table" then return result end
	return {}
end

function TicketStore.updateStatus(ticketId, newStatus, byUserId)
	local ok, err = pcall(function()
		store:UpdateAsync(KEY, function(old)
			old = old or {}
			for _, t in ipairs(old) do
				if t.id == ticketId then
					t.status = newStatus
					if newStatus == "paid" then
						t.paidAt = os.time()
						t.paidBy = byUserId
					end
					break
				end
			end
			return old
		end)
	end)
	return ok, err
end
function TicketStore.clearAll()
	local ok, err = pcall(function()
		store:SetAsync(KEY, {})  -- replace the whole ticket list with empty
	end)
	return ok, err
end
return TicketStore