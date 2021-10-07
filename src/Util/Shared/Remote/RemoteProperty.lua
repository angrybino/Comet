-- angrybino
-- RemoteProperty
-- September 26, 2021

--[[
	-- Static methods:

    RemoteProperty.IsRemoteProperty(self : any) --> boolean [IsRemoteProperty]
    RemoteProperty.new(value : any) --> RemoteProperty []

    -- Instance members:

    RemoteProperty.OnValueUpdate : Signal (newValue : any)
	RemoteProperty.OnPlayerValueUpdate : Signal (player : Player, newValue : any)

	-- Instance methods:

	RemoteProperty:GetDefaultValue() --> any [DefaultValue]
    RemoteProperty:Destroy() --> void []
    RemoteProperty:SetValue(value : any, specificPlayers : table ?) --> void []
    RemoteProperty:GetValue() --> any [value]
	RemoteProperty:GetPlayerValue(player : Player) --> any [PlayerSpecificValue]
]]

local RemoteProperty = {}
RemoteProperty.__index = RemoteProperty

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local shared = script:FindFirstAncestor("Shared")
local Signal = require(script.Signal)
local SharedConstants = require(shared.SharedConstants)
local Maid = require(shared.Maid)

function RemoteProperty.IsRemoteProperty(self)
	return getmetatable(self) == RemoteProperty
end

function RemoteProperty.new(defaultValue)
	assert(RunService:IsServer(), "RemoteProperty can only be created on the server")

	local self = setmetatable({
		OnValueUpdate = Signal.new(),
		OnPlayerValueUpdate = Signal.new(),
		_maid = Maid.new(),
		_defaultValue = defaultValue,
		_currentValue = defaultValue,
		_playerSpecificValues = {},
	}, RemoteProperty)

	self._maid:AddTask(self.OnPlayerValueUpdate)
	self._maid:AddTask(self.OnValueUpdate)

	return self
end

function RemoteProperty:InitRemoteFunction(remoteFunction)
	self._remoteFunction = remoteFunction
	self._maid:AddTask(remoteFunction)

	function remoteFunction.OnServerInvoke(player)
		return self._playerSpecificValues[player.UserId] or self._defaultValue
	end
end

function RemoteProperty:Destroy()
	self._maid:Destroy()

	for key, _ in pairs(self) do
		self[key] = nil
	end

	setmetatable(self, nil)
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

function RemoteProperty:SetValue(newValue, specificPlayers)
	if specificPlayers then
		assert(
			typeof(specificPlayers) == "table",
			SharedConstants.ErrorMessages.InvalidArgument:format(
				2,
				"RemoteProperty:SetValue()",
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

			if currentPlayerValue ~= newValue then
				self._playerSpecificValues[player.UserId] = newValue
				self.OnPlayerValueUpdate:Fire(player, newValue)
				self._remoteFunction:InvokeClient(player, newValue)
			end
		end
	end
end

function RemoteProperty:GetValue()
	return self._currentValue
end

return RemoteProperty
