-- angrybino
-- LerpUtil
-- September 28, 2021

--[[
    LerpUtil.Lerp(initialValue : number, goalValue : number, alpha : number) --> number [LerpedValue]
	LerpUtil.QuadraticLerp(initialValue : number, goalValue : number, alpha : number) --> number [LerpedValue]
]]

local LerpUtil = {}

local SharedConstants = require(script.Parent.SharedConstants)

function LerpUtil.Lerp(initialValue, goalValue, alpha)
	assert(
		typeof(initialValue) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "LerpUtil.Lerp()", "number", typeof(initialValue))
	)

	assert(
		typeof(goalValue) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(2, "LerpUtil.Lerp()", "number", typeof(goalValue))
	)

	assert(
		typeof(alpha) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(3, "LerpUtil.Lerp()", "number", typeof(alpha))
	)

	return initialValue + (goalValue - initialValue) * alpha
end

function LerpUtil.QuadraticLerp(initialValue, goalValue, alpha)
	assert(
		typeof(initialValue) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"LerpUtil.QuadraticLerp()",
			"number",
			typeof(initialValue)
		)
	)

	assert(
		typeof(goalValue) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(2, "LerpUtil.QuadraticLerp()", "number", typeof(goalValue))
	)

	assert(
		typeof(alpha) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(3, "LerpUtil.QuadraticLerp()", "number", typeof(alpha))
	)

	return (initialValue - goalValue) * alpha * (alpha - 2) + initialValue
end

return LerpUtil
