-- SilentsReplacement
-- RemoteProperty
-- September 23, 2021

--[[
    RemoteProperty.IsRemoteProperty(self : any) --> boolean [IsRemoteProperty]
    RemoteProperty.new(value : any) --> RemoteProperty []

    -- Only accessible from an object returned by RemoteProperty.new(): 

    RemoteProperty.OnValueUpdate : Signal (newValue : any)
	RemoteProperty.OnPlayerValueUpdate : Signal (player : Player, newValue : any)

	RemoteProperty:GetDefaultValue() --> any [DefaultValue]
    RemoteProperty:Destroy() --> void []
    RemoteProperty:Set(value : any, specificPlayers : table ?) --> void []
    RemoteProperty:Get() --> any [value]
	RemoteProperty:GetPlayerValue(player : Player) --> any [PlayerSpecificValue]
]]

local RemoteProperty = {}
RemoteProperty.__index = RemoteProperty

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local comet = script:FindFirstAncestor("Comet")
local Signal = require(comet.Util.Signal)
local SharedConstants = require(comet.SharedConstants)

function RemoteProperty.IsRemoteProperty(self)
	return getmetatable(self) == RemoteProperty
end

function RemoteProperty.new(defaultValue)
	assert(RunService:IsServer(), "RemoteProperty can only be created on the server")

	return setmetatable({
		OnValueUpdate = Signal.new(),
		OnPlayerValueUpdate = Signal.new(),
		_defaultValue = defaultValue,
		_currentValue = defaultValue,
		_playerSpecificValues = {},
	}, RemoteProperty)
end

function RemoteProperty:InitRemoteFunction(remoteFunction)
	self._remoteFunction = remoteFunction

	function remoteFunction.OnServerInvoke(player)
		return self._playerSpecificValues[player.UserId] or self._defaultValue
	end
end

function RemoteProperty:Destroy()
	self.OnValueUpdate:Destroy()
	self.OnPlayerValueUpdate:Destroy()

	if self._remoteFunction then
		self._remoteFunction:Destroy()
	end
end

function RemoteProperty:GetPlayerValue(player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"RemoteProperty:GetPlayerValue()",
			"Player",
			typeof(player)
		)
	)

	return self._playerSpecificValues[player.UserId]
end

function RemoteProperty:GetDefaultValue()
	return self._defaultValue
end

function RemoteProperty:Set(newValue, specificPlayers)
	if specificPlayers then
		assert(
			typeof(specificPlayers) == "table",
			SharedConstants.ErrorMessages.InvalidArgument:format(
				2,
				"RemoteProperty:Set()",
				"table",
				typeof(specificPlayers)
			)
		)
	end

	if self._currentValue ~= newValue then
		self._currentValue = newValue
		self.OnValueUpdate:Fire(newValue)
	end

	if self._remoteFunction then
		local players = specificPlayers or Players:GetPlayers()

		for _, player in ipairs(players) do
			local currentPlayerValue = self._playerSpecificValues[player.UserId]
			if currentPlayerValue ~= newValue and newValue ~= self._defaultValue then
				self._playerSpecificValues[player.UserId] = newValue
				self.OnPlayerValueUpdate:Fire(player, newValue)
				self._remoteFunction:InvokeClient(player, newValue)
			end
		end
	end
end

function RemoteProperty:Get()
	return self._currentValue
end

return RemoteProperty
