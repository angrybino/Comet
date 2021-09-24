-- SilentsReplacement
-- ClientRemoteSignal
-- September 23, 2021

--[[
	ClientRemoteSignal.IsClientRemoteSignal(self : any) --> boolean [IsClientRemoteSignal]

	 -- Only when accessed from a object returned by ClientRemoteSignal.new():
	 
	ClientRemoteSignal:Connect(callBack : function) --> void []
	ClientRemoteSignal:Wait() --> void []
	ClientRemoteSignal:Destroy() --> void []
	ClientRemoteSignal:DisconnectAllConnections() --> void []
]]

local ClientRemoteSignal = {}
ClientRemoteSignal.__index = ClientRemoteSignal

local RunService = game:GetService("RunService")

local comet = script:FindFirstAncestor("Comet")
local Signal = require(comet.Util.Signal)
local SharedConstants = require(comet.SharedConstants)

function ClientRemoteSignal.IsClientRemoteSignal(self)
	return getmetatable(self) == ClientRemoteSignal
end

function ClientRemoteSignal.new(remote)
	assert(RunService:IsClient(), "ClientRemoteSignal can only be created on the client")

	local self = setmetatable({
		_signal = Signal.new(),
		_remote = remote,
	}, ClientRemoteSignal)

	self._remote.OnClientEvent:Connect(function(...)
		self._signal:Fire(...)
	end)

	return self
end

function ClientRemoteSignal:Connect(callBack)
	return self._signal:Connect(callBack)
end

function ClientRemoteSignal:DisconnectAllConnections()
	self._signal:DisconnectAllConnections()
end

function ClientRemoteSignal:Destroy()
	self._remote:Destroy()
	self._signal:Destroy()
end

function ClientRemoteSignal:Wait()
	return self._signal:Wait()
end

return ClientRemoteSignal
