-- angrybino
-- Mouse
-- September 26, 2021

--[[
	Mouse.OnLeftClick : Signal (isInputProcessed : boolean)
	Mouse.OnRightClick : Signal (isInputProcessed : boolean)
	Mouse.OnScrollClick : Signal (isInputProcessed : boolean)
	Mouse.OnMove : Signal (deltaPosition : Vector3)
	Mouse.OnTargetChanged : Signal (newTarget : Instance | nil)

	Mouse.TargetFilters : table
	Mouse.UnitRay : Vector3
	Mouse.Hit : CFrame
	Mouse.X : number
	Mouse.Y : number
	Mouse.Target : Instance | nil
	Mouse.Origin : CFrame
	Mouse.IgnoreCharacter : boolean

	Mouse.CastRay(rayCastParams : RaycastParams, distance : number ?) --> RayCastResults
	Mouse.LockCurrentPosition() --> void []
	Mouse.SetLock() --> void []
	Mouse.Unlock() --> void []
	Mouse.SetLockOnCenter() --> void []
	Mouse.GetDeltaPosition() --> Vector3 [DeltaPosition]
]]

local Mouse = {
	TargetFilters = {},
	IgnoreCharacter = false,
	_lastPosition = nil,
}

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalConstants = {
	MaxMouseRayDistance = 15000,
	MinDelta = 1e-5,
}

local Signal = require(script.Parent.Signal)
local SharedConstants = require(script.Parent.SharedConstants)

setmetatable(Mouse, {
	__index = function(_, key)
		if key == "UnitRay" then
			return Mouse._getViewPointToRay()
		elseif key == "Hit" then
			return Mouse._getHitCFrame()
		elseif key == "X" then
			return UserInputService:GetMouseLocation().X
		elseif key == "Y" then
			return UserInputService:GetMouseLocation().Y
		elseif key == "Target" then
			return Mouse._getMouseTarget()
		elseif key == "Origin" then
			return Workspace.CurrentCamera.CFrame
		end
	end,
})

function Mouse.GetDeltaPosition()
	return Mouse.Hit.Position - (Mouse._lastPosition or Mouse.Hit.Position)
end

function Mouse.CastRay(rayCastParams, distance)
	assert(
		typeof(rayCastParams) == "RaycastParams" or rayCastParams == nil,
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Mouse.CastRay()",
			"RaycastParams",
			typeof(rayCastParams)
		)
	)

	assert(
		typeof(distance) == "number" or distance == nil,
		SharedConstants.ErrorMessages.InvalidArgument:format(2, "Mouse.CastRay()", "number or nil", typeof(distance))
	)

	local ray = Mouse._getViewPointToRay()

	return Workspace:Raycast(
		ray.Origin,
		ray.Direction * (distance or LocalConstants.MaxMouseRayDistance),
		rayCastParams
	)
end

function Mouse.LockCurrentPosition()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end

function Mouse.SetLock()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end

function Mouse.Unlock()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function Mouse.SetLockOnCenter()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function Mouse.Init()
	Mouse.OnLeftClick = Signal.new()
	Mouse.OnRightClick = Signal.new()
	Mouse.OnMove = Signal.new()
	Mouse.OnTargetChanged = Signal.new()
	Mouse.OnScrollClick = Signal.new()

	local lastTarget = Mouse.Target

	RunService.RenderStepped:Connect(function()
		local deltaPosition = Mouse.GetDeltaPosition()

		if
			math.abs(deltaPosition.X) >= LocalConstants.MinDelta
			or math.abs(deltaPosition.Y) >= LocalConstants.MinDelta
		then
			Mouse.OnMove:Fire(deltaPosition)
		end

		Mouse._lastPosition = Mouse.Hit.Position
	end)

	Mouse.OnMove:Connect(function()
		if Mouse.Target ~= lastTarget then
			Mouse.OnTargetChanged:Fire(Mouse.Target)
		end

		lastTarget = Mouse.Target
	end)

	UserInputService.InputBegan:Connect(function(input, isInputProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			Mouse.OnLeftClick:Fire(isInputProcessed)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			Mouse.OnRightClick:Fire(isInputProcessed)
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			Mouse.OnScrollClick:Fire(isInputProcessed)
		end
	end)
end

function Mouse._getViewPointToRay()
	local mouseLocation = UserInputService:GetMouseLocation()

	return Workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
end

function Mouse._getMouseTarget()
	local mouseRay = Mouse._getViewPointToRay()
	local rayCastParams = RaycastParams.new()
	rayCastParams.FilterDescendantsInstances = {
		not Mouse.IgnoreCharacter and Players.LocalPlayer.Character,
		table.unpack(Mouse.TargetFilters),
	}

	local ray = Workspace:Raycast(
		mouseRay.Origin,
		mouseRay.Direction * LocalConstants.MaxMouseRayDistance,
		rayCastParams
	)

	return ray and ray.Instance or nil
end

function Mouse._getHitCFrame()
	local mouseRay = Mouse._getViewPointToRay()
	local rayCastParams = RaycastParams.new()

	rayCastParams.FilterDescendantsInstances = {
		not Mouse.IgnoreCharacter and Players.LocalPlayer.Character,
		table.unpack(Mouse.TargetFilters),
	}

	local ray = Workspace:Raycast(
		mouseRay.Origin,
		mouseRay.Direction * LocalConstants.MaxMouseRayDistance,
		rayCastParams
	)

	return CFrame.new(ray and ray.Position or mouseRay.Origin + mouseRay.Direction * LocalConstants.MaxMouseRayDistance)
end

return Mouse
