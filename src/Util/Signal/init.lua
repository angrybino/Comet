-- SilentsReplacement
-- Signal
-- July 13, 2021

--[[
	Signal.new() --> Signal []
	Signal.IsSignal(self : any) --> boolean [IsSignal]
	-- Only when accessed from an object returned by Signal.new:
	
	Signal.ConnectedConnectionCount : number
	Signal.ConnectionListHead : function | nil
	Signal:Connect(callBack : function) --> Connection []
	Signal:Fire(tuple : any) --> void []
	Signal:DeferredFire(tuple : any) --> void []
	Signal:Wait() --> any [tuple]
	Signal:WaitUntilArgumentsPassed(tuple : any) --> any [tuple]
    Signal:DisconnectAllConnections() --> void []
	Signal:Destroy() -->  void []
	Signal:IsDestroyed() --> boolean [IsDestroyed]
]]

local Signal = {}
Signal.__index = Signal

local Connection = require(script.Connection)

local LocalConstants = {
	MinArgumentCount = 1,

	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
		Destroyed = "Signal object is destroyed",
	},
}

function Signal.IsSignal(self)
	return getmetatable(self) == Signal
end

function Signal.new()
	return setmetatable({
		ConnectedConnectionCount = 0,
		_isDestroyed = false,
	}, Signal)
end

function Signal:Connect(callBack)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	assert(
		typeof(callBack) == "function",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "Signal:Connect", "function", typeof(callBack))
	)

	local connection = Connection.new(self, callBack)

	if self.ConnectionListHead then
		connection.Next = self.ConnectionListHead
		self.ConnectionListHead = connection
	else
		self.ConnectionListHead = connection
	end

	return connection
end

function Signal:DisconnectAllConnections()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self.ConnectionListHead = nil
end

function Signal:IsDestroyed()
	return self._isDestroyed
end

function Signal:Destroy()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self:DisconnectAllConnections()
	self._isDestroyed = true
end

function Signal:Wait()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

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
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	local expectedArguments = { ... }

	while true do
		-- Signal:Wait() returns any arguments passed to Signal:Fire()
		local returnValues = { self:Wait() }

		-- Case of multiple return and expected return values:
		if #returnValues > LocalConstants.MinArgumentCount and #expectedArguments > LocalConstants.MinArgumentCount then
			local areReturnValuesEqual = true

			for index, value in ipairs(returnValues) do
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
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

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
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

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

function Signal._acquireRunnerThreadAndCallEventHandler(callBack, ...)
	local acquiredRunnerThread = Signal._freeRunnerThread
	Signal._freeRunnerThread = nil

	callBack(...)
	Signal._freeRunnerThread = acquiredRunnerThread
end

function Signal._runEventHandlerInFreeThread(...)
	Signal._acquireRunnerThreadAndCallEventHandler(...)

	while true do
		Signal._acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

return Signal
