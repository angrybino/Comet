-- angrybino
-- NumberUtil
-- October 12, 2021

--[[
    NumberUtil.E : number
    NumberUtil.Tau : number

    NumberUtil.InverseLerp(min : number, max : number, alpha : number) --> number []
    NumberUtil.Map(number : number, inMin : number, inMax : number, outMin : number, outMax : number) --> number []
    NumberUtil.RoundTo(number : number, to : number) --> number []
    NumberUtil.Lerp(number : number, to : number) --> number []
    NumberUtil.QuadraticLerp(number : number, to : number) --> number []
]]

local NumberUtil = {
	E = 2.7182818284590,
	Tau = 2 * math.pi,
}

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)

function NumberUtil.Lerp(number, goal, alpha)
	assert(
		typeof(number) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "NumberUtil.Lerp()", "number", typeof(number))
	)
	assert(
		typeof(goal) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(2, "NumberUtil.Lerp()", "number", typeof(goal))
	)
	assert(
		typeof(alpha) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(3, "NumberUtil.Lerp()", "number", typeof(alpha))
	)

	return number + (goal - number) * alpha
end

function NumberUtil.QuadraticLerp(number, goal, alpha)
	assert(
		typeof(number) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "NumberUtil.QuadraticLerp()", "number", typeof(number))
	)
	assert(
		typeof(goal) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(2, "NumberUtil.QuadraticLerp()", "number", typeof(goal))
	)
	assert(
		typeof(alpha) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(3, "NumberUtil.QuadraticLerp()", "number", typeof(alpha))
	)

	return (number - goal) * alpha * (alpha - 2) + number
end

function NumberUtil.InverseLerp(min, max, alpha)
	assert(
		typeof(min) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "NumberUtil.InverseLerp()", "number", typeof(min))
	)
	assert(
		typeof(max) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(2, "NumberUtil.InverseLerp()", "number", typeof(max))
	)
	assert(
		typeof(alpha) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(3, "NumberUtil.InverseLerp()", "number", typeof(alpha))
	)

	return ((alpha - min) / (max - min))
end

function NumberUtil.Map(number, inMin, inMax, outMin, outMax)
	assert(
		typeof(number) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "NumberUtil.Map()", "number", typeof(number))
	)
	assert(
		typeof(inMin) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(2, "NumberUtil.Map()", "number", typeof(inMin))
	)
	assert(
		typeof(inMax) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(3, "NumberUtil.Map()", "number", typeof(inMax))
	)
	assert(
		typeof(outMin) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(4, "NumberUtil.Map()", "number", typeof(outMin))
	)
	assert(
		typeof(outMax) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(5, "NumberUtil.Map()", "number", typeof(outMax))
	)

	return (outMin + ((outMax - outMin) * ((number - inMin) / (inMax - inMin))))
end

function NumberUtil.RoundTo(number, to)
	assert(
		typeof(number) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "NumberUtil.RoundTo()", "number", typeof(number))
	)
	assert(
		typeof(to) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(2, "NumberUtil.RoundTo()", "number", typeof(to))
	)

	return math.floor(number / to + 0.5) * to
end

return NumberUtil
