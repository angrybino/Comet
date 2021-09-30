-- angrybino
-- ClientRemoteSignal
-- September 26, 2021

--[[
	ClientRemoteSignal.IsClientRemoteSignal(self : any) --> boolean [IsClientRemoteSignal]

	 -- Only when accessed from a object returned by ClientRemoteSignal.new():
	 
	ClientRemoteSignal:Connect(callBack : function) --> RBXScriptConnection []
	ClientRemoteSignal:Wait() --> any []
	ClientRemoteSignal:Fire(... : any) --> void []
	ClientRemoteSignal:IsDestroyed() --> boolean [IsDestroyed]
	ClientRemoteSignal:Destroy() --> void []
	ClientRemoteSignal:DisconnectAllConnections() --> void []
]]

local ClientRemoteSignal = {}
ClientRemoteSignal.__index = ClientRemoteSignal

local RunService = game:GetService("RunService")

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)

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

	return setmetatable({
		_isDestroyed = false,
	}, ClientRemoteSignal)
end

function ClientRemoteSignal:InitRemoteEvent(remoteEvent)
	self._remoteEvent = remoteEvent
end

function ClientRemoteSignal:Connect(callback)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)
	assert(
		typeof(callback) == "function",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"ClientRemoteSignal:Connect()",
			"function",
			typeof(callback)
		)
	)

	return self._remoteEvent.OnClientEvent:Connect(callback)
end

function ClientRemoteSignal:Fire(...)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._remoteEvent:FireServer(...)
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
