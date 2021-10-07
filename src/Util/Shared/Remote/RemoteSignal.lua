-- angrybino
-- RemoteSignal
-- September 26, 2021

--[[
	-- Static methods:
	
    RemoteSignal.IsRemoteSignal(self : any) --> boolean [IsRemoteSignal]
    RemoteSignal.new() --> RemoteSignal []

    -- Instance methods:

	RemoteSignal:Connect(callback : function) --> RBXScriptConnection []
    RemoteSignal:Destroy() --> void []
    RemoteSignal:FireClient(client : Player, ... : any) --> void []
    RemoteSignal:FireAllClients(... : any) --> void []
    RemoteSignal:FireClients(clients : table, ... : any) --> void []
]]

local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

local RunService = game:GetService("RunService")

local shared = script:FindFirstAncestor("Shared")
local SharedConstants = require(shared.SharedConstants)
local Maid = require(shared.Maid)

function RemoteSignal.IsRemoteSignal(self)
	return getmetatable(self) == RemoteSignal
end

function RemoteSignal.new()
	assert(RunService:IsServer(), "RemoteSignal can only be created on the server")

	return setmetatable({
		_maid = Maid.new(),
	}, RemoteSignal)
end

function RemoteSignal:SetRemoteEvent(remote)
	self._remote = remote
	self._maid:AddTask(remote)
end

function RemoteSignal:Destroy()
	self._maid:Destroy()

	for key, _ in pairs(self) do
		self[key] = nil
	end

	setmetatable(self, nil)
end

function RemoteSignal:Connect(callback)
	assert(
		typeof(callback) == "function",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "RemoteSignal:Connect()", "function", typeof(callback))
	)

	return self._remote.OnServerEvent:Connect(callback)
end

function RemoteSignal:FireClient(client, ...)
	assert(
		typeof(client) == "Instance" and client:IsA("Player"),
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "RemoteSignal:FireClient()", "Player", typeof(client))
	)

	self._remote:FireClient(client, ...)
end

function RemoteSignal:FireAllClients(...)
	self._remote:FireAllClients(...)
end

function RemoteSignal:FireClients(clients, ...)
	assert(
		typeof(clients) == "table",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "RemoteSignal:FireClients()", "table", typeof(clients))
	)

	for _, client in ipairs(clients) do
		self:FireClient(client, ...)
	end
end

return RemoteSignal
