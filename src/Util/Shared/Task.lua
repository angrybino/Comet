-- angrybino
-- Task
-- October 13, 2021

--[[
    Complete safe version of the task library and also omits errors without stack traces

    Task.SafeSpawn(callBackOrThread : function | thread, tableArgs : table | void) --> void []
    Task.SafeDefer(callBackOrThread : function | thread, tableArgs : table | void) --> void []
    Task.SafeWait(timer : number | void) --> void []
    Task.SafeDelay(timer : number, callBackOrThread : function | thread) --> void []
]]

local Task = {
	_threadsScheduledForResumption = {},
}

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)

function Task.SafeSpawn(callBackOrThread, tableArgs, _forceNoCheck)
	assert(
		typeof(callBackOrThread) == "thread" or typeof(callBackOrThread) == "function",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Task.SafeSpawn()",
			"function or thread",
			typeof(callBackOrThread)
		)
	)

	if tableArgs then
		assert(
			typeof(tableArgs) == "table",
			SharedConstants.ErrorMessages.InvalidArgument:format(
				2,
				"Task.SafeSpawn()",
				"table or void",
				typeof(tableArgs)
			)
		)
	end

	tableArgs = tableArgs or {}

	if typeof(callBackOrThread) == "thread" and coroutine.status(callBackOrThread) ~= "suspended" then
		return
	end

	if not _forceNoCheck then
		Task._checkAndWaitForEngineResumption(callBackOrThread)
	end

	task.spawn(callBackOrThread, table.unpack(tableArgs))
end

function Task.SafeDelay(timer, callBackOrThread)
	Task.Wait(timer)
	Task.SafeSpawn(callBackOrThread)
end

function Task.Wait(timer)
	if timer then
		assert(
			typeof(timer) == "number",
			SharedConstants.ErrorMessages.InvalidArgument:format(1, "Task.Wait()", "number or nil", typeof(timer))
		)
	end

	task.wait(timer)
end

function Task.SafeDefer(callBackOrThread, ...)
	assert(
		typeof(callBackOrThread) == "thread" or typeof(callBackOrThread) == "function",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Task.SafeDefer()",
			"function or thread",
			typeof(callBackOrThread)
		)
	)

	Task._checkAndWaitForEngineResumption(callBackOrThread)

	local args = { ... }
	local bindable = Instance.new("BindableEvent")
	Task._threadsScheduledForResumption[callBackOrThread] = bindable

	task.defer(function()
		Task.SafeSpawn(callBackOrThread, args, true)

		bindable:Fire()
		bindable:Destroy()
		Task._threadsScheduledForResumption[callBackOrThread] = nil
	end)
end

function Task._checkAndWaitForEngineResumption(callBackOrThread)
	local currentState = Task._threadsScheduledForResumption[callBackOrThread]

	if typeof(currentState) == "Instance" and currentState:IsA("BindableEvent") then
		-- Wait until the thread / callback has been resumed by the engine:
		currentState.Event:Wait()
	end
end

return Task
