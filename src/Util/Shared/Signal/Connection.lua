-- angrybino
-- Connection
-- September 26, 2021

--[[
	-- Static methods:

	Connection.new() --> Connection []
	Connection.IsConnection(self : any) --> boolean [IsConnection]
	
	-- Instance methods:

	Connection:Disconnect() --> void []
	Connection:IsConnected() -- > boolean [IsConnected]
]]

local Connection = {}
Connection.__index = Connection

local comet = script:FindFirstAncestor("Comet")
local Maid = require(comet.Util.Shared.Maid)

local LocalConstants = {
	ErrorMessages = {
		Disconnected = "Connection object is disconnected",
	},
}

function Connection.IsConnection(self)
	return getmetatable(self) == Connection
end

function Connection.new(signal, callBack)
	signal.ConnectedConnectionCount += 1

	local self = setmetatable({
		Callback = callBack,
		_isConnected = true,
		_signal = signal,
		_maid = Maid.new(),
	}, Connection)

	self._maid:AddTask(function()
		self._signal.ConnectedConnectionCount -= 1

		-- Unhook the node, but DON'T clear it. That way any fire calls that are
		-- currently sitting on this node will be able to iterate forwards off of
		-- it, but any subsequent fire calls will not hit it, and it will be GCed
		-- when no more fire calls are sitting on it.
		if self._signal.ConnectionListHead == self then
			self._signal.ConnectionListHead = self.Next
		else
			local previousConnectionListHead = self._signal.ConnectionListHead
			while previousConnectionListHead and previousConnectionListHead.Next ~= self do
				previousConnectionListHead = previousConnectionListHead.Next
			end

			if previousConnectionListHead then
				previousConnectionListHead.Next = self.Next
			end
		end

		for key, _ in pairs(self) do
			self[key] = nil
		end

		self._connected = false
	end)

	return self
end

function Connection:Disconnect()
	assert(self:IsConnected(), LocalConstants.ErrorMessages.Disconnected)

	self._maid:Destroy()
end

function Connection:IsConnected()
	return self._isConnected
end

return Connection
