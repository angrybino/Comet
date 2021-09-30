-- angrybino
-- Clamp
-- September 26, 2021

-- Clamps a negative / positive value if it is lower than 0.1, to 0.

--[[
    Clamp(value : number) --> number [ClampedNumber]
]]

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)

local LocalConstants = {
	MaxToleratedNumber = 0.01
}

return function(value)
	assert(
		typeof(value) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Clamp()", "number", typeof(value))
	)

	-- If the number is negative, then make sure it is >= than 0.1 in its absolute form:
	if math.abs(value) < LocalConstants.MaxToleratedNumber then
		return 0
	end

	return value
end
