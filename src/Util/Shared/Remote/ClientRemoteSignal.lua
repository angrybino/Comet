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
	ClientRemoteSignal:Destroy() --> void []
]]

local ClientRemoteSignal = {}
ClientRemoteSignal.__index = ClientRemoteSignal

local shared = script:FindFirstAncestor("Shared")
local SharedConstants = require(shared.SharedConstants)
local Maid = require(shared.Maid)

function ClientRemoteSignal.IsClientRemoteSignal(self)
	return getmetatable(self) == ClientRemoteSignal
end

function ClientRemoteSignal.new()
	return setmetatable({
		_maid = Maid.new(),
	}, ClientRemoteSignal)
end

function ClientRemoteSignal:InitRemoteEvent(remoteEvent)
	self._remoteEvent = remoteEvent
	self._maid:AddTask(remoteEvent)
end

function ClientRemoteSignal:Connect(callback)
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
	self._remoteEvent:FireServer(...)
end

function ClientRemoteSignal:Destroy()
	self._maid:Destroy()

	for key, _ in pairs(self) do
		self[key] = nil
	end

	setmetatable(self, nil)
end

function ClientRemoteSignal:Wait()
	return self._signal:Wait()
end

return ClientRemoteSignal
