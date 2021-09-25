-- SilentsReplacement
-- Maid
-- July 06, 2021

--[[
	Maid.new() --> Maid []
	Maid.IsMaid(self : any) --> boolean [IsMaid]
	-- Only when accessed from an object created by Maid.new():
	
	Maid:AddTask(task : table | function | RBXScriptConnection) --> task []
	Maid:Cleanup() --> void []
	Maid:IsDestroyed() --> boolean [IsDestroyed]
	Maid:RemoveTask(task) --> void []
	Maid:Destroy() --> void []
	Maid:LinkToInstances(instances : table) --> instances []
]]

local Maid = {}
Maid.__index = Maid

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
		Destroyed = "Maid object is destroyed",
	},
}

function Maid.new()
	return setmetatable({
		_tasks = {},
		_isDestroyed = false,
	}, Maid)
end

function Maid.IsMaid(self)
	return getmetatable(self) == Maid
end

function Maid:AddTask(task)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	assert(
		typeof(task) == "function"
			or typeof(task) == "RBXScriptConnection"
			or typeof(task) == "table" and (typeof(task.Destroy) == "function" or typeof(task.Disconnect) == "function")
			or typeof(task) == "Instance",

		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Maid.new()",
			"function or RBXScriptConnection or table with Destroy or Disconnect method or Instance",
			typeof(task)
		)
	)

	self._tasks[task] = task

	return task
end

function Maid:RemoveTask(task)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	assert(
		typeof(task) == "function"
			or typeof(task) == "RBXScriptConnection"
			or typeof(task) == "table" and (typeof(task.Destroy) == "function" or typeof(task.Disconnect) == "function")
			or typeof(task) == "Instance",

		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Maid:RemoveTask()",
			"function or RBXScriptConnection or table with Destroy or Disconnect method or Instance",
			typeof(task)
		)
	)

	self._tasks[task] = nil
end

function Maid:IsDestroyed()
	return self._isDestroyed
end

function Maid:Destroy()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self:Cleanup()
	self._isDestroyed = true
end

function Maid:LinkToInstances(instances)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	assert(
		typeof(instances) == "table",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "Maid:LinkToInstances()", "table", typeof(table))
	)

	for _, instance in ipairs(instances) do
		-- If the instance was parented to nil, then destroy the maid because its possible
		-- that the instance may have already been destroyed:
		if not instance.Parent then
			self:Destroy()
			break
		end

		local instanceParentChangedConnection
		instanceParentChangedConnection = self:AddTask(instance:GetPropertyChangedSignal("Parent"):Connect(function()
			if not instance.Parent and not self:IsDestroyed() then
				task.defer(function()
					-- If the connection has also been disconnected, then its
					-- guaranteed that the instance has been destroyed through
					-- Destroy():
					if not instanceParentChangedConnection.Connected then
						self:Destroy()
					end
				end)
			end
		end))
	end

	return instances
end

function Maid:Cleanup()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	local tasks = self._tasks

	-- Spawn a new thread to cleanup the current tasks, and immediately cleanup self._tasks
	-- to prevent cleaning up newly added tasks while this code is still running:
	task.spawn(function()
		for key, task in pairs(tasks) do
			if typeof(task) == "function" then
				task()
			elseif typeof(task) == "RBXScriptConnection" then
				task:Disconnect()
			elseif typeof(task) == "Instance" then
				task:Destroy()
			else
				if task.Disconnect then
					task:Disconnect()
				end

				if task.Destroy then
					task:Destroy()
				end
			end
		end
	end)

	self._tasks = {}
end

return Maid