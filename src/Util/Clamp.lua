-- SilentsReplacement
-- Clamp
-- September 14, 2021

-- Clamps a negative / positive value if it is lower than 0.1, to 0.

--[[
    Clamp(value : number) --> number [ClampedNumber]
]]

local LocalConstants = {
	MaxToleratedNumber = 0.1,

	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

return function(value)
	assert(
		typeof(value) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "Clamp()", "number", typeof(value))
	)

	-- If the number is negative, then make sure it is >= than 0.1 in its absolute form:
	if value < 0 and math.abs(value) >= LocalConstants.MaxToleratedNumber then
		return value
	end

	return value < LocalConstants.MaxToleratedNumber and 0 or value
end
