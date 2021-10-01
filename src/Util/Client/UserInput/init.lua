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
		KeyboardMouse = "KeyboardMouse",
		Gamepad = "Gamepad",
		Touch = "Touch",
	},

	_modulesInit = {},
	_isInit = false,
}

local UserInputService = game:GetService("UserInputService")

local Signal = require(script.Parent.Signal)
local comet = require(script:FindFirstAncestor("Comet"))
local SharedConstants = require(comet.SharedConstants)

function UserInput.GetCurrentInputType()
	return UserInput._currentInputType
end

function UserInput.Get(moduleName)
	assert(
		typeof(moduleName) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "UserInput.Get()", "string", typeof(moduleName))
	)
	return UserInput._modulesInit[moduleName]
end

function UserInput._initializeInputType()
	if UserInputService.MouseEnabled then
		UserInput._currentInputType = "KeyboardMouse"
	elseif #UserInputService:GetConnectedGamepads() > 0 then
		UserInput._currentInputType = "Gamepad"
	elseif UserInputService.TouchEnabled then
		UserInput._currentInputType = "Touch"
	end
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
	UserInput._initializeInputType()
	UserInput._initModules()

	UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
		local previousLastInputType = UserInput._currentInputType

		if lastInputType.Name:find("Gamepad") then
			UserInput._currentInputType = "Gamepad"
		elseif lastInputType.Name == "Keyboard" or lastInputType.Name:find("Mouse") then
			UserInput._currentInputType = "KeyboardMouse"
		elseif lastInputType.Name == "Touch" then
			UserInput._currentInputType = "Touch"
		end

		if previousLastInputType ~= UserInput._currentInputType then
			UserInput.OnInputTypeChange:Fire(UserInput._currentInputType)
		end
	end)
end

if not UserInput._isInit then
	UserInput._init()
end

return UserInput
