-- angrybino
-- Keyboard
-- September 26, 2021

--[[
	Keyboard.OnKeyHold : Signal (keyCode : KeyCode, isInputProcessed : boolean)
	Keyboard.OnKeyRelease : Signal (keyCode : KeyCode, isInputProcessed : boolean)

    Keyboard.AreAllKeysHeld(... : KeyCodes) --> boolean [AreAllKeysHeld]
    Keyboard.AreAnyKeysHeld(... : keyCodes) --> boolean [AreAnyKeysHeld]
	Keyboard.IsKeyHeld(keyCode : KeyCode) --> boolean [IsKeyHeld]
]]

local Keyboard = {}

local UserInputService = game:GetService("UserInputService")

local comet = script:FindFirstAncestor("Comet")
local Signal = require(comet.Util.Shared.Signal)

function Keyboard.Init()
	Keyboard.OnKeyHold = Signal.new()
	Keyboard.OnKeyRelease = Signal.new()

	UserInputService.InputBegan:Connect(function(input, isInputProcessed)
		local keyCode = input.KeyCode

		while UserInputService:IsKeyDown(keyCode) do
			Keyboard.OnKeyHold:Fire(keyCode, isInputProcessed)
			task.wait()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, isInputProcessed)
		Keyboard.OnKeyRelease:Fire(input.KeyCode, isInputProcessed)
	end)
end

function Keyboard.AreAllKeysHeld(...)
	for _, keyCode in ipairs({ ... }) do
		if not UserInputService:IsKeyDown(keyCode) then
			return false
		end
	end

	return true
end

function Keyboard.AreAnyKeysHeld(...)
	for _, keyCode in ipairs({ ... }) do
		if UserInputService:IsKeyDown(keyCode) then
			return true
		end
	end

	return false
end

function Keyboard.IsKeyHeld(keyCode)
	return UserInputService:IsKeyDown(keyCode)
end

return Keyboard
