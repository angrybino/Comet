-- angrybino
-- SmoothVector
-- September 28, 2021

--[[
	SmoothVector.new(startVector : Vector3 ?, speed : number ?) --> SmoothVector []

	-- Only accessible from a object returned by SmoothVector.new():

	SmoothVector:GetSpeed() --> void []
	SmoothVector:QuadraticInterpolate(goalVector : Vector3) --> void []
	SmoothVector:Interpolate(goalVector : Vector3) --> void []
	SmoothVector:SetSpeed(speed : number) --> void []
]]

local SmoothVector = {}
SmoothVector.__index = SmoothVector

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)
local Clamp = require(comet.Util.Clamp)

local LocalConstants = {
	InitialSpeed = 1,
	InitalStartVector = Vector3.new(),
}

local function QuadraticLerp(start, goal, alpha)
	return Clamp((start - goal) * alpha * (alpha - 2) + start)
end

local function Lerp(start, goal, alpha)
	return Clamp(start + (goal - start) * alpha)
end

function SmoothVector.new(startVector, speed)
	if startVector then
		assert(
			typeof(startVector) == "Vector3",
			SharedConstants.ErrorMessages.InvalidArgument:format(
				1,
				"SmoothVector.new()",
				"Vector3 or nil",
				typeof(startVector)
			)
		)
	end

	if speed then
		assert(
			typeof(speed) == "number",
			SharedConstants.ErrorMessages.InvalidArgument:format(
				2,
				"SmoothVector.new() or nil",
				"number",
				typeof(speed)
			)
		)
	end

	startVector = startVector or LocalConstants.InitalStartVector
	speed = speed or LocalConstants.InitialSpeed

	return setmetatable({
		_vector = startVector,
		_speed = speed,
	}, SmoothVector)
end

function SmoothVector:SetSpeed(speed)
	assert(
		typeof(speed) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "SmoothVector:SetSpeed()", "number", typeof(speed))
	)

	self._speed = speed
end

function SmoothVector:GetSpeed()
	return self._speed
end

function SmoothVector:QuadraticInterpolate(goalVector)
	assert(
		typeof(goalVector) == "Vector3",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"SmoothVector:QuadraticInterpolate()",
			"Vector3",
			typeof(goalVector)
		)
	)

	local startVector = self._vector
	local alpha = self._speed

	self._vector = Vector3.new(
		QuadraticLerp(startVector.X, goalVector.X, alpha),
		QuadraticLerp(startVector.Y, goalVector.Y, alpha),
		QuadraticLerp(startVector.Z, goalVector.Z, alpha)
	)

	return self._vector
end

function SmoothVector:Interpolate(goalVector)
	assert(
		typeof(goalVector) == "Vector3",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"SmoothVector:Interpolate()",
			"Vector3",
			typeof(goalVector)
		)
	)

	local startVector = self._vector
	local alpha = self._speed

	self._vector = Vector3.new(
		Lerp(startVector.X, goalVector.X, alpha),
		Lerp(startVector.Y, goalVector.Y, alpha),
		Lerp(startVector.Z, goalVector.Z, alpha)
	)

	return self._vector
end

return SmoothVector
