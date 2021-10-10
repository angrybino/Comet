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
		InputMethod = "InputMethod",
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

		Enum.UserInputType.Keyboard,
		Enum.UserInputType.Touch,
		Enum.UserInputType.Accelerometer,
		Enum.UserInputType.Gyro,
		Enum.UserInputType.Focus,
		Enum.UserInputType.TextInput,
		Enum.UserInputType.InputMethod,
	},

	_modulesInit = {},
	_isInit = false,
}

local UserInputService = game:GetService("UserInputService")

local comet = script:FindFirstAncestor("Comet")
local Signal = require(comet.Util.Shared.Signal)
local SharedConstants = require(comet.SharedConstants)

function UserInput.GetCurrentInputType()
	local enumInputType = UserInputService:GetLastInputType()

	for _, value in ipairs(UserInput._enumInputTypes) do
		if typeof(value) ~= "EnumItem" then
			continue
		end

		if enumInputType.Name == value.Name then
			return UserInput.InputType[value.Name]
		end
	end

	for _, enum in ipairs(UserInput._enumInputTypes.Mouse) do
		if enumInputType == enum then
			return UserInput.InputType.Mouse
		end
	end

	for _, enum in ipairs(UserInput._enumInputTypes.Gamepad) do
		if enumInputType == enum then
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
