-- angrybino
-- Get
-- October 09, 2021

--[[
    Get(name : string) --> ModuleScript []
]]

local RunService = game:GetService("RunService")

local util = script.Parent.Util
local SharedConstants = require(util.Shared.SharedConstants)
local Maid = require(util.Shared.Maid)

local cachedLookups = {}

return function(name)
	assert(
		typeof(name) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Get()", "string", typeof(name))
	)

	local folders = {
		util.Shared,
		util.Server,
		util.Client,
	}

	for _, folder in ipairs(folders) do
		-- Return cached results:
		if cachedLookups[folder] and cachedLookups[folder][name] then
			return cachedLookups[folder][name]
		end

		for _, child in ipairs(folder:GetChildren()) do
			if child.Name ~= name then
				continue
			end

			if folder == util.Client then
				assert(RunService:IsClient(), ("Can only get [%s] %s on the client!"):format(child.ClassName, name))
			elseif folder == util.Server then
				assert(RunService:IsServer(), ("Can only get [%s] %s on the server!"):format(child.ClassName, name))
			end

			cachedLookups[folder] = cachedLookups[folder] or {}
			cachedLookups[folder][name] = child

			if child:IsA("ModuleScript") then
				return require(child)
			else
				return child
			end
		end
	end

	for key, value in ipairs(folders) do
		folders[key] = ("%s.%s"):format(util.Name, value.Name)
	end

	error(("%s not found in [%s]"):format(name, table.concat(folders, ", ")))
end
