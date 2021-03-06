-- angrybino
-- Signal
-- October 09, 2021

--[[
	-- Static methods:
	
	Signal.new() --> Signal []
	Signal.IsSignal(self : any) --> boolean [IsSignal]
	
	-- Instance members:
	
	Signal.ConnectedConnectionCount : number

	-- Instance methods:

	Signal:Connect(callback : function) --> Connection []
	Signal:Fire(tuple : any) --> void []
	Signal:DeferredFire(tuple : any) --> void []
	Signal:Wait() --> any [tuple]
	Signal:WaitUntilArgumentsPassed(tuple : any) --> any [tuple]
	Signal:CleanupConnections() --> void []
	Signal:Destroy() --> void []
]]

local Signal = {}
Signal.__index = Signal

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)
local Maid = require(script.Parent.Maid)

local LocalConstants = {
	MinArgumentCount = 1,
}

function Signal.IsSignal(self)
	return getmetatable(self) == Signal
end

function Signal.new()
	local self = setmetatable({
		ConnectedConnectionCount = 0,
		_maid = Maid.new(),
	}, Signal)

	self._maid:AddTask(function()
		self:CleanupConnections()

		setmetatable(self, nil)

		for key, _ in pairs(self) do
			self[key] = nil
		end
	end)

	return self
end

local Connection = {}
Connection.__index = Connection

do
	function Connection.new(signal, callback)
		signal.ConnectedConnectionCount += 1

		return setmetatable({
			Callback = callback,
			_signal = signal,
			_isConnected = true,
		}, Connection)
	end

	function Connection:Disconnect()
		assert(self:IsConnected(), "Connection is already disconnected")

		self._isConnected = false
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
	end

	function Connection:IsConnected()
		return self._isConnected
	end
end

function Signal:Connect(callback)
	assert(
		typeof(callback) == "function",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Signal:Connect", "function", typeof(callback))
	)

	local connection = Connection.new(self, callback)

	if self.ConnectionListHead then
		connection.Next = self.ConnectionListHead
		self.ConnectionListHead = connection
	else
		self.ConnectionListHead = connection
	end

	return connection
end

function Signal:CleanupConnections()
	local connection = self.ConnectionListHead

	while connection do
		if connection:IsConnected() then
			connection:Disconnect()
		end

		connection = connection.Next
	end
end

function Signal:Destroy()
	self._maid:Destroy()
end

function Signal:Wait()
	-- This method of resuming a yielded coroutine is efficient as it doesn't
	-- cause any internal script errors (when resuming a yielded coroutine directly):
	local yieldedCoroutine = coroutine.running()

	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(yieldedCoroutine, ...)
	end)

	return coroutine.yield()
end

function Signal:WaitUntilArgumentsPassed(...)
	local expectedArguments = { ... }

	while true do
		-- Signal:Wait() returns any arguments passed to Signal:Fire()
		local returnValues = { self:Wait() }

		-- Case of multiple return and expected return values:
		if #returnValues > LocalConstants.MinArgumentCount and #expectedArguments > LocalConstants.MinArgumentCount then
			local areReturnValuesEqual = true

			for _, value in ipairs(returnValues) do
				if not table.find(expectedArguments, value) then
					areReturnValuesEqual = false
				end
			end

			if areReturnValuesEqual then
				return expectedArguments
			end
		else
			if returnValues[1] == expectedArguments[1] then
				return expectedArguments
			end
		end

		-- Prevent script execution timout incase of any thread concurrency issues:
		task.wait()
	end
end

function Signal:Fire(...)
	-- Call handlers in reverse order (end - start):
	local connection = self.ConnectionListHead

	while connection do
		if connection:IsConnected() then
			if not Signal._freeRunnerThread then
				Signal._freeRunnerThread = coroutine.create(Signal._runEventHandlerInFreeThread)
			end

			task.spawn(Signal._freeRunnerThread, connection.Callback, ...)
		end

		connection = connection.Next
	end
end

function Signal:DeferredFire(...)
	-- Call handlers in reverse order (end - start), except at a very slightly later
	-- time (next engine step):
	local connection = self.ConnectionListHead

	while connection do
		if connection:IsConnected() then
			if not Signal._freeRunnerThread then
				Signal._freeRunnerThread = coroutine.create(Signal._runEventHandlerInFreeThread)
			end

			task.defer(Signal._freeRunnerThread, connection.Callback, ...)
		end

		connection = connection.Next
	end
end

function Signal._acquireRunnerThreadAndCallEventHandler(callback, ...)
	local acquiredRunnerThread = Signal._freeRunnerThread
	Signal._freeRunnerThread = nil

	callback(...)
	Signal._freeRunnerThread = acquiredRunnerThread
end

function Signal._runEventHandlerInFreeThread(...)
	Signal._acquireRunnerThreadAndCallEventHandler(...)

	while true do
		Signal._acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

return Signal
