-- angrybino
-- init
-- September 26, 2021

--[[
	UserInput.OnInputTypeChange : Signal (newInputType : string)
	UserInput.InputType : table	

	UserInput.GetCurrentInputType() --> string | nil [CurrentInputType]
	UserInput.Get(moduleName : string) --> table | nil [RequiredModule]
]]

local UserInput = {
	InputType = {
		Mouse = "Mouse",
		Keyboard = "Keyboard",
		Gamepad = "Gamepad",
		Touch = "Touch",
		Accelerometer = "Accelerometer",
		Gyro = "Gyro",
		Focus = "Focus",
		TextInput = "TextInput",
	},

	_enumInputTypes = {
		Mouse = {
			Enum.UserInputType.MouseButton1,
			Enum.UserInputType.MouseButton2,
			Enum.UserInputType.MouseButton3,
			Enum.UserInputType.MouseMovement,
			Enum.UserInputType.MouseWheel,
		},

		Gamepad = {
			Enum.UserInputType.Gamepad1,
			Enum.UserInputType.Gamepad2,
			Enum.UserInputType.Gamepad3,
			Enum.UserInputType.Gamepad4,
			Enum.UserInputType.Gamepad5,
			Enum.UserInputType.Gamepad6,
			Enum.UserInputType.Gamepad7,
			Enum.UserInputType.Gamepad8,
		},

		Keyboard = Enum.UserInputType.Keyboard,
		Touch = Enum.UserInputType.Touch,
		Accelerometer = Enum.UserInputType.Accelerometer,
		Gyro = Enum.UserInputType.Gyro,
		Focus = Enum.UserInputType.Focus,
		TextInput = Enum.UserInputType.TextInput,
	},

	_modulesInit = {},
	_isInit = false,
}

local LocalizationService = game:GetService("LocalizationService")
local UserInputService = game:GetService("UserInputService")

local comet = script:FindFirstAncestor("Comet")
local Signal = require(comet.Util.Shared.Signal)
local SharedConstants = require(comet.SharedConstants)

function UserInput.GetCurrentInputType()
	local inputType = UserInputService:GetLastInputType()

	if inputType == UserInput._enumInputTypes.Keyboard then
		return UserInput.InputType.Keyboard
	elseif inputType == UserInput._enumInputTypes.Touch then
		return UserInput.InputType.Touch
	elseif inputType == UserInput._enumInputTypes.Gyro then
		return UserInput.InputType.Gyro
	elseif inputType == UserInput._enumInputTypes.Focus then
		return UserInput.InputType.Focus
	elseif inputType == UserInput._enumInputTypes.TextInput then
		return UserInput.InputType.TextInput
	end

	for _, enum in ipairs(UserInput._enumInputTypes.Mouse) do
		if inputType == enum then
			return UserInput.InputType.Mouse
		end
	end

	for _, enum in ipairs(UserInput._enumInputTypes.Gamepad) do
		if inputType == enum then
			return UserInput.InputType.Gamepad
		end
	end

	return nil
end

function UserInput.Get(moduleName)
	assert(
		typeof(moduleName) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "UserInput.Get()", "string", typeof(moduleName))
	)

	return UserInput._modulesInit[moduleName]
end

function UserInput._initModules()
	for _, child in ipairs(script:GetChildren()) do
		local requiredModule = require(child)

		UserInput._modulesInit[child.Name] = requiredModule

		if typeof(requiredModule.Init) == "function" then
			requiredModule.Init()
		end
	end
end

function UserInput._init()
	UserInput._isInit = true
	UserInput.OnInputTypeChange = Signal.new()
	UserInput._initModules()

	local function OnInputTypeUpdate(newInputType)
		if UserInput._currentInputType ~= newInputType then
			UserInput._currentInputType = newInputType
			UserInput.OnInputTypeChange:Fire(newInputType)
		end
	end

	UserInput._currentInputType = UserInput.GetCurrentInputType()
	UserInputService.LastInputTypeChanged:Connect(function()
		OnInputTypeUpdate(UserInput.GetCurrentInputType())
	end)
end

if not UserInput._isInit then
	UserInput._init()
end

return UserInput
