-- angrybino
-- ClientRemoteSignal
-- September 26, 2021

--[[
	-- Static methods:

	ClientRemoteSignal.IsClientRemoteSignal(self : any) --> boolean [IsClientRemoteSignal]

	-- Instance methods:
	 
	ClientRemoteSignal:Connect(callback : function) --> RBXScriptConnection []
	ClientRemoteSignal:Wait() --> any []
	ClientRemoteSignal:Fire(... : any) --> void []
	ClientRemoteSignal:IsDestroyed() --> boolean [IsDestroyed]
	ClientRemoteSignal:Destroy() --> void []
]]

local ClientRemoteSignal = {}
ClientRemoteSignal.__index = ClientRemoteSignal

local RunService = game:GetService("RunService")

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)
local Maid = require(comet.Util.Shared.Maid)

local LocalConstants = {
	ErrorMessages = {
		Destroyed = "ClientRemoteSignal object is destroyed",
	},
}

function ClientRemoteSignal.IsClientRemoteSignal(self)
	return getmetatable(self) == ClientRemoteSignal
end

function ClientRemoteSignal.new()
	return setmetatable({
		_isDestroyed = false,
		_maid = Maid.new(),
	}, ClientRemoteSignal)
end

function ClientRemoteSignal:InitRemoteEvent(remoteEvent)
	self._remoteEvent = remoteEvent
	self._maid:AddTask(remoteEvent)
	self._maid:AddTask(function()
		for key, _ in pairs(self) do
			self[key] = nil
		end

		self._isDestroyed = true
	end)
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

function ClientRemoteSignal:Destroy()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._maid:Destroy()
end

function ClientRemoteSignal:IsDestroyed()
	return self._isDestroyed
end

function ClientRemoteSignal:Wait()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	return self._signal:Wait()
end

return ClientRemoteSignal