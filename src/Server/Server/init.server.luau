-- init.server.lua
-- src/server/init.server.lua -> becomes the "Server" Script in ServerScriptService
--- init.server.lua  (the "Server" Script in ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Requiring Remotes auto-creates all remotes on the server.
local Remotes = require(ReplicatedStorage.Shared:WaitForChild("Remotes"))
local DataManager = require(script:WaitForChild("DataManager"))

DataManager.init()