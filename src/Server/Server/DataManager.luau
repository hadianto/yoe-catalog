-- DataManager.lua
-- ModuleScript in ServerScriptService > Server, named "DataManager"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))

local DataManager = {}

local PROFILE_STORE_NAME = string.format("%s_Data_v%d", Shared.GAME_NAME, Shared.DATA_VERSION)
local ProfileStore = ProfileService.GetProfileStore(PROFILE_STORE_NAME, Shared.DEFAULT_PROFILE)

local profiles = {}
local profileLoadedCallbacks = {}

function DataManager.getProfile(player)
	local profile = profiles[player]
	if profile and profile:IsActive() then
		return profile.Data
	end
	return nil
end
function DataManager.viewProfile(userId)
	local key = "Player_" .. userId
	local profile = ProfileStore:ViewProfileAsync(key)
	if profile then
		return profile.Data
	end
	return nil
end
function DataManager.onProfileLoaded(callback)
	table.insert(profileLoadedCallbacks, callback)
end

function DataManager.updateProfile(player, callback)
	local profile = profiles[player]
	if not profile or not profile:IsActive() then return false end
	callback(profile.Data)
	Remotes.get("DataUpdated"):FireClient(player, profile.Data)
	return true
end

local function onRequestData(player)
	return DataManager.getProfile(player)
end

local function onPlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if not profile then
		player:Kick("Data failed to load. Please rejoin.")
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile:ListenToRelease(function()
		profiles[player] = nil
		player:Kick("Your session was released. Please rejoin.")
	end)
	if player.Parent ~= Players then
		profile:Release()
		return
	end
	profiles[player] = profile

	Remotes.get("DataUpdated"):FireClient(player, profile.Data)
	for _, cb in ipairs(profileLoadedCallbacks) do
		task.spawn(cb, player, profile.Data)
	end
end

local function onPlayerRemoving(player)
	local profile = profiles[player]
	if profile then profile:Release() end
end

function DataManager.init()
	Remotes.get("RequestData").OnServerInvoke = onRequestData
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	if RunService:IsStudio() then
		warn("[DataManager] ProfileService active in Studio; data may not persist as in production.")
	end
end

return DataManager