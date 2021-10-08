-- angrybino
-- Import
-- October 07, 2021

--[[
    Import(name : string, instance : Instance ?) --> Instance ? []
]]

local RunService = game:GetService("RunService")

local Maid = require(script.Parent.Util.Shared.Maid)
local SharedConstants = require(script.Parent.Util.Shared.SharedConstants)

local cachedLookups = {}
local maids = {}

return function(name, instance)
	assert(
		typeof(name) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Import()", "string", typeof(name))
	)

	if instance then
		assert(
			typeof(instance) == "Instance",
			SharedConstants.ErrorMessages.InvalidArgument:format(2, "Import()", "Instance or nil", typeof(instance))
		)
	end

	instance = instance or script.Parent.Util
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

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant.Name == name then
			if descendant:IsDescendantOf(script.Parent.Util.Client) then
				assert(
					RunService:IsClient(),
					("Can't import %s on the server as it is client sided"):format(descendant.Name)
				)
			elseif descendant:IsDescendantOf(script.Parent.Utill.Server) then
				assert(
					RunService:IsServer(),
					("Can't import %s on the client as it is server sided"):format(descendant.Name)
				)
			end

			cachedLookups[instance][name] = descendant

			if descendant:IsA("ModuleScript") then
				return require(descendant)
			else
				return descendant
			end
		end
	end
end
