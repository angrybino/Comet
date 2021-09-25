-- SilentsReplacement
-- ClientRemoteSignal
-- September 23, 2021

--[[
	ClientRemoteSignal.IsClientRemoteSignal(self : any) --> boolean [IsClientRemoteSignal]

	 -- Only when accessed from a object returned by ClientRemoteSignal.new():
	 
	ClientRemoteSignal:Connect(callBack : function) --> Connection []
	ClientRemoteSignal:Wait() --> any []
	ClientRemoteSignal:IsDestroyed() --> boolean [IsDestroyed]
	ClientRemoteSignal:Destroy() --> void []
	ClientRemoteSignal:DisconnectAllConnections() --> void []
]]

local ClientRemoteSignal = {}
ClientRemoteSignal.__index = ClientRemoteSignal

local RunService = game:GetService("RunService")

local comet = script:FindFirstAncestor("Comet")
local Signal = require(comet.Util.Signal)

local LocalConstants = {
	ErrorMessages = {
		Destroyed = "ClientRemoteSignal object is destroyed",
	},
}

function ClientRemoteSignal.IsClientRemoteSignal(self)
	return getmetatable(self) == ClientRemoteSignal
end

function ClientRemoteSignal.new()
	assert(RunService:IsClient(), "ClientRemoteSignal can only be created on the client")

	local self = setmetatable({
		_signal = Signal.new(),
		_isDestroyed = false,
	}, ClientRemoteSignal)

	return self
end

function ClientRemoteSignal:InitRemoteEvent(remoteEvent)
	self._remoteEvent = remoteEvent

	self._remoteEvent.OnClientEvent:Connect(function(...)
		self._signal:Fire(...)
	end)
end

function ClientRemoteSignal:Connect(callBack)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	return self._signal:Connect(callBack)
end

function ClientRemoteSignal:DisconnectAllConnections()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._signal:DisconnectAllConnections()
end

function ClientRemoteSignal:Destroy()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._isDestroyed = true
	self._remoteEvent:Destroy()
	self._signal:Destroy()
end

function ClientRemoteSignal:IsDestroyed()
	return self._isDestroyed
end

function ClientRemoteSignal:Wait()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	return self._signal:Wait()
end

return ClientRemoteSignal
