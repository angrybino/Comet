-- angrybino
-- ClampAbosoluteValue
-- September 26, 2021

-- Clamps a value to 0 if it's abosolute form is < maxAbsoluteValue or 1e-5 by default.

--[[
    ClampAbosoluteValue(value : number, maxAbsoluteValue : number ?) --> number [ClampedNumber]
]]

local LocalConstants = {
	DefaultMaxAbosluteNumber = 1e-5,
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

return function(value, maxAbsoluteValue)
	assert(
		typeof(value) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "ClampAbosoluteValue()", "number", typeof(value))
	)

	if maxAbsoluteValue then
		assert(
			typeof(maxAbsoluteValue) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
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
