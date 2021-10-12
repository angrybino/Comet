-- angrybino
-- Get
-- October 10, 2021

--[[
    Get(util : string).From(utilFolderName : string) --> Instance []
]]

local RunService = game:GetService("RunService")

local SharedConstants = require(script.Parent.SharedConstants)

local cachedLookups = {}

return function(util)
	assert(
		typeof(util) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Get()", "string", typeof(util))
	)

	return {
		From = function(utilFolderName)
			assert(
				typeof(utilFolderName) == "string",
				SharedConstants.ErrorMessages.InvalidArgument:format(1, "Get.From()", "string", typeof(utilFolderName))
			)

			local finalInstance = script.Parent.Util

			for _, value in ipairs(utilFolderName:split("/")) do
				finalInstance = finalInstance[value]
			end

			local module = finalInstance[util]
			if cachedLookups[module] then
				return cachedLookups[module]
			end

			if RunService:IsServer() then
				assert(
					not module:IsDescendantOf(script.Parent.Util.Client),
					("Can only get module [%s] on the client"):format(module.Name)
				)
			else
				assert(
					not module:IsDescendantOf(script.Parent.Util.Server),
					("Can only get module [%s] on the server"):format(module.Name)
				)
			end

			cachedLookups[module] = require(module)

			return cachedLookups[module]
		end,
	}
end
