-- angrybino
-- RemoteSignal
-- September 26, 2021

--[[
    RemoteSignal.IsRemoteSignal(self : any) --> boolean [IsRemoteSignal]
    RemoteSignal.new() --> RemoteSignal []

    -- Only accessible from an object returned by RemoteSignal.new():  

	RemoteSignal:IsDestroyed() --> boolean [IsDestroyed]
    RemoteSignal:Destroy() --> void []
    RemoteSignal:FireClient(client : Player, ... : any) --> void []
    RemoteSignal:FireAllClients(... : any) --> void []
    RemoteSignal:FireClients(clients : table, ... : any) --> void []
]]

local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

local RunService = game:GetService("RunService")

local LocalConstants = {
	ErrorMessages = {
		Destroyed = "RemoteSignal object is destroyed",
	},
}

function RemoteSignal.IsRemoteSignal(self)
	return getmetatable(self) == RemoteSignal
end

function RemoteSignal.new()
	assert(RunService:IsServer(), "RemoteSignal can only be created on the server")

	return setmetatable({
		_callBacks = {},
		_isDestroyed = false,
	}, RemoteSignal)
end

function RemoteSignal:SetRemoteEvent(remote)
	self._remote = remote
end

function RemoteSignal:Destroy()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._isDestroyed = true
	self._remote:Destroy()
end

function RemoteSignal:FireClient(client, ...)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._remote:FireClient(client, ...)
end

function RemoteSignal:FireAllClients(...)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._remote:FireAllClients(...)
end

function RemoteSignal:FireClients(clients, ...)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	for _, client in ipairs(clients) do
		self:FireClient(client, ...)
	end
end

function RemoteSignal:IsDestroyed()
	return self._isDestroyed
end

return RemoteSignal
