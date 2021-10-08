-- angrybino
-- Import
-- October 07, 2021

--[[
    Import(name : string) --> Instance ? []
]]

local RunService = game:GetService("RunService")

local Maid = require(script.Parent.Util.Shared.Maid)
local SharedConstants = require(script.Parent.Util.Shared.SharedConstants)

local cachedLookups = {}
local maids = {}

return function(name)
	assert(
		typeof(name) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Import()", "string", typeof(name))
	)

	local instance = script.Parent.Util
	local cachedInstanceLookups = cachedLookups[instance]

	if cachedInstanceLookups and cachedInstanceLookups[name] then
		return cachedInstanceLookups[name]
	end

	if not maids[instance] then
		local maid = Maid.new()
		maids[instance] = maid

		maid:AddTask(function()
			cachedLookups[instance] = nil
			maids[instance] = nil
		end)

		maid:LinkToInstances({ instance })
	end

	cachedLookups[instance] = cachedLookups[instance] or {}

	for _, child in ipairs(instance.Client:GetChildren()) do
		if child.Name == name then
			assert(RunService:IsClient(), ("Can't import %s on the server as it is client sided"):format(child.Name))

			cachedLookups[instance][name] = child

			if child:IsA("ModuleScript") then
				return require(child)
			else
				return child
			end
		end
	end

	for _, child in ipairs(instance.Server:GetChildren()) do
		if child.Name == name then
			assert(RunService:IsServer(), ("Can't import %s on the client as it is server sided"):format(child.Name))

			cachedLookups[instance][name] = child

			if child:IsA("ModuleScript") then
				return require(child)
			else
				return child
			end
		end
	end

	for _, child in ipairs(instance.Shared:GetChildren()) do
		if child.Name == name then
			cachedLookups[instance][name] = child

			if child:IsA("ModuleScript") then
				return require(child)
			else
				return child
			end
		end
	end
end
