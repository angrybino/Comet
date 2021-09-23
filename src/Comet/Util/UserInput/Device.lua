-- SilentsReplacement
-- Device
-- September 18, 2021

--[[
    Device.OnTouchStarted : RBXScriptSignal (touchedPosition : Vector3, isInputProcessed : boolean)
	Device.OnTouchEnded : RBXScriptSignal (touchedPositionEnded : Vector3, isInputProcessed : boolean)
	Device.TouchMoved : RBXScriptSignal (touchedPositionEnded : Vector3, isInputProcessed : boolean)
	Device.OnTouchTapInWorld : RBXScriptSignal (touchTapInWorldPosition : Vector2, isInputProcessed : boolean)
	Device.TouchLongPress : RBXScriptSignal (touchPositions : table, state : UserInputState, isInputProcessed : boolean)
	Device.OnTouchPinch : RBXScriptSignal (
		touchPositions : table, 
		scale : number, 
		velocity : number, 
		state : UserInputState, 
		isInputProcessed : boolean
	)
	Device.OnTouchPan : RBXScriptSignal (
		touchPositions : table,
		totalTranslation : Vector2,
		velocity : Vector2,
		state : UserInputState,
		isInputProcessed : boolean
	)
	Device.OnTouchRotate : RBXScriptSignal (
		touchPositions : table,
		rotation : number,
		velocity : Vector2,
		state : UserInputState,
		isInputProcessed : boolean
	)
	Device.OnTouchTap : RBXScriptSignal (touchPositions : table,isInputProcessed : boolean)
	Device.OnAccelerationChanged : RBXScriptSignal (acceleration : InputObject)
	Device.OnGravityChanged : RBXScriptSignal (gravity : InputObject)
	Device.OnGravityChanged : RBXScriptSignal (gravity : InputObject)
	Device.OnRotationChanged : RBXScriptSignal (rotation : InputObject, cframe : CFrame)

	Device.GetAcceleration() --> InputObject [Acceleration]
	Device.GetGravity() --> InputObject [Gravity]
	Device.GetRotation() --> (InputObject, CFrame) [Rotation]
]]

local Device = {}

local UserInputService = game:GetService("UserInputService")

function Device.Init()
	Device.OnTouchTapInWorld = UserInputService.TouchTapInWorld
	Device.OnTouchMoved = UserInputService.TouchMoved
	Device.OnTouchEnded = UserInputService.TouchMoved
	Device.OnTouchStarted = UserInputService.TouchStarted
	Device.OnTouchPinch = UserInputService.TouchPinch
	Device.OnTouchLongPress = UserInputService.TouchLongPress
	Device.OnTouchPan = UserInputService.TouchPan
	Device.OnTouchRotate = UserInputService.TouchRotate
	Device.OnTouchSwipe = UserInputService.TouchSwipe
	Device.OnTouchTap = UserInputService.TouchTap
	Device.OnAccelerationChanged = UserInputService.DeviceAccelerationChanged
	Device.OnGravityChanged = UserInputService.DeviceGravityChanged
	Device.OnRotationChanged = UserInputService.DeviceRotationChanged

	Device.GetAcceleration = UserInputService.GetDeviceAcceleration
	Device.GetGravity = UserInputService.GetDeviceGravity
	Device.GetRotation = UserInputService.GetDeviceRotation
end

return Device
