-- angrybino
-- Get
-- October 10, 2021

--[[
    Get(util : string).From(utilFolderName : string) --> Instance []
]]

local SharedConstants = require(script.Parent.SharedConstants)

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

			return require(finalInstance[util])
		end,
	}
end
