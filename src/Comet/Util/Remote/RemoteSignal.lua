-- SilentsReplacement
-- RemoteSignal
-- September 23, 2021

--[[
    RemoteSignal.IsRemoteSignal(self : any) --> boolean [IsRemoteSignal]
    RemoteSignal.new() --> RemoteSignal []

    -- Only accessible from an object returned by RemoteSignal.new():  

    RemoteSignal:Destroy() --> void []
    RemoteSignal:FireClient(client : Player, ... : any) --> void []
    RemoteSignal:FireAllClients(... : any) --> void []
    RemoteSignal:FireClients(clients : table, ... : any) --> void []
]]

local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

local RunService = game:GetService("RunService")

function RemoteSignal.IsRemoteSignal(self)
	return getmetatable(self) == RemoteSignal
end

function RemoteSignal.new()
	assert(RunService:IsServer(), "RemoteSignal can only be created on the client")

	return setmetatable({
		_callBacks = {},
	}, RemoteSignal)
end

function RemoteSignal:Init(remote)
	self._remote = remote
end

function RemoteSignal:Destroy()
	self._remote:Destroy()
end

function RemoteSignal:FireClient(client, ...)
	self._remote:FireClient(client, ...)
end

function RemoteSignal:FireAllClients(...)
	self._remote:FireAllClients(...)
end

function RemoteSignal:FireClients(clients, ...)
	for _, client in ipairs(clients) do
		self:FireClient(client, ...)
	end
end

return RemoteSignal
