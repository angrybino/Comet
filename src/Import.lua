-- angrybino
-- Import
-- October 07, 2021

--[[
    Import(instance : Instance, name : string) --> Instance ? []
]]

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
			cachedLookups[instance][name] = descendant
			return descendant
		end
	end
end
