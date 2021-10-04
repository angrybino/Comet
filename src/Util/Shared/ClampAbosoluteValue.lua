-- angrybino
-- ClampAbosoluteValue
-- September 26, 2021

-- Clamps a value to 0 if it's abosolute form is < maxAbsoluteValue or 0.01 by default.

--[[
    ClampAbosoluteValue(value : number, maxAbsoluteValue : number ?) --> number [ClampedNumber]
]]

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)

local LocalConstants = {
	DefaultMaxAbosluteNumber = 0.01,
}

return function(value, maxAbsoluteValue)
	assert(
		typeof(value) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "ClampAbosoluteValue()", "number", typeof(value))
	)

	if maxAbsoluteValue then
		assert(
			typeof(maxAbsoluteValue) == "number",
			SharedConstants.ErrorMessages.InvalidArgument:format(
				2,
				"ClampAbosoluteValue()",
				"number or nil",
				typeof(maxAbsoluteValue)
			)
		)
	end

	if math.abs(value) < (maxAbsoluteValue or LocalConstants.DefaultMaxAbosluteNumber) then
		value = 0
	end

	return value
end
