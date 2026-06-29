-- Remotes.lua
-- ModuleScript under ReplicatedStorage > Shared, named "Remotes"
--
-- Single source of truth for all RemoteEvents / RemoteFunctions in this place.
-- Add every new remote HERE once. A missing name throws "Unknown remote name".
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}
local IS_SERVER = RunService:IsServer()
local cachedFolder: Folder? = nil

export type RemoteNames =
	"DataUpdated" | "RequestData" | "ShowNotification" | "TrackPurchase" |
	"SubmitTicket" | "GetTickets" | "UpdateTicket" | "GetOwed"

local REMOTE_FOLDER_NAME = "Remotes"
local REMOTE_DEFINITIONS: { [RemoteNames]: "RemoteEvent" | "RemoteFunction" } = {
	DataUpdated      = "RemoteEvent",   -- server -> client: profile sync
	RequestData      = "RemoteFunction",-- client -> server: pull current profile
	ShowNotification = "RemoteEvent",   -- server -> client: toast
	TrackPurchase    = "RemoteEvent",   -- client -> server: report a verified purchase
	SubmitTicket     = "RemoteEvent",    -- player -> server: file a refund ticket
	GetTickets       = "RemoteFunction", -- admin -> server: fetch all tickets
	UpdateTicket     = "RemoteEvent",    -- admin -> server: mark a ticket paid/outstanding
	GetOwed          = "RemoteFunction",  -- player -> server: how much am I owed right now
}

local function getRemoteFolder(): Folder
	if cachedFolder then return cachedFolder end

	if IS_SERVER then
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		if not shared then
			shared = Instance.new("Folder")
			shared.Name = "Shared"
			shared.Parent = ReplicatedStorage
		end
		local folder = shared:FindFirstChild(REMOTE_FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = REMOTE_FOLDER_NAME
			folder.Parent = shared
		end
		cachedFolder = folder
		return folder :: Folder
	else
		local shared = ReplicatedStorage:WaitForChild("Shared")
		local folder = shared:WaitForChild(REMOTE_FOLDER_NAME) :: Folder
		cachedFolder = folder
		return folder
	end
end

function Remotes.init()
	assert(IS_SERVER, "Remotes.init() must run on the server")
	local folder = getRemoteFolder()
	for name, className in pairs(REMOTE_DEFINITIONS) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new(className)
			remote.Name = name
			remote.Parent = folder
		end
	end
end

function Remotes.get(name: RemoteNames): RemoteEvent | RemoteFunction
	local folder = getRemoteFolder()
	local remote = folder:FindFirstChild(name)
	if remote then
		return remote :: RemoteEvent | RemoteFunction
	end

	if IS_SERVER then
		local className = REMOTE_DEFINITIONS[name]
		assert(className, "Unknown remote name: " .. tostring(name))
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
		return remote :: RemoteEvent | RemoteFunction
	else
		return folder:WaitForChild(name) :: RemoteEvent | RemoteFunction
	end
end

function Remotes.waitFor(name: RemoteNames): RemoteEvent | RemoteFunction
	return getRemoteFolder():WaitForChild(name) :: RemoteEvent | RemoteFunction
end

if IS_SERVER then
	Remotes.init()
end

return Remotes