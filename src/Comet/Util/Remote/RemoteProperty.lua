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
		_callBacks = {},
	}, RemoteProperty)
end

function RemoteProperty:InitRemoteFunction(remoteFunction)
	self._remoteFunction = remoteFunction

	remoteFunction.OnServerInvoke = function()
		return self._currentValue
	end
end

function RemoteProperty:Destroy()
	self.OnUpdate:Destroy()

	if not self._remoteFunction then
		return
	end

	self._remoteFunction:Destroy()
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

	if not self._remoteFunction then
		return
	end

	for _, player in ipairs(specificPlayers or Players:GetPlayers()) do
		self._remoteFunction:InvokeClient(player, newValue)
	end
end

function RemoteProperty:Get()
	return self._currentValue
end

return RemoteProperty
