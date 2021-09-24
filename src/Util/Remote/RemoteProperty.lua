-- SilentsReplacement
-- RemoteProperty
-- September 23, 2021

--[[
    RemoteProperty.IsRemoteProperty(self : any) --> boolean [IsRemoteProperty]
    RemoteProperty.new(value : any) --> RemoteProperty []

    -- Only accessible from an object returned by RemoteProperty.new(): 

    RemoteProperty.OnUpdate : Signal (newValue : any)
    RemoteProperty:Destroy() --> void []
    RemoteProperty:Set(value : any, specificPlayers : table ?) --> void []
    RemoteProperty:Get() --> any [value]
	RemoteProperty:GetForPlayer(player : Player) --> any [PlayerSpecificValue]
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

function RemoteProperty.new(currentValue)
	assert(RunService:IsServer(), "RemoteProperty can only be created on the server")

	return setmetatable({
		OnUpdate = Signal.new(),
		_currentValue = currentValue,
		_playerSpecificValues = {},
		_callBacks = {},
	}, RemoteProperty)
end

function RemoteProperty:InitRemoteFunction(remoteFunction)
	self._remoteFunction = remoteFunction

	remoteFunction.OnServerInvoke = function(player)
		return self._playerSpecificValues[player.UserId]
	end
end

function RemoteProperty:Destroy()
	self.OnUpdate:Destroy()

	if not self._remoteFunction then
		return
	end

	self._remoteFunction:Destroy()
end

function RemoteProperty:GetForPlayer(player)
	assert(RunService:IsServer(), "RemoteProperty:GetForPlayer() can only be called on the server")
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"RemoteProperty:GetForPlayer()",
			"Player",
			typeof(player)
		)
	)

	return self._playerSpecificValues[player.UserId]
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
		self.OnUpdate:Fire(newValue)
	end

	if self._remoteFunction then
		local players = specificPlayers or Players:GetPlayers()

		for _, player in ipairs(players) do
			self._playerSpecificValues[player.UserId] = newValue
			self._remoteFunction:InvokeClient(player, newValue)
		end
	end
end

function RemoteProperty:Get()
	return self._currentValue
end

return RemoteProperty
