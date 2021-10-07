-- angrybino
-- Maid
-- September 26, 2021

--[[
	-- Static methods:

	Maid.new() --> Maid []
	Maid.IsMaid(self : any) --> boolean [IsMaid]

	-- Instance methods:
	
	Maid:AddTask(task : table | function | RBXScriptConnection | Instance) --> task []
	Maid:Cleanup() --> void []
	Maid:RemoveTask(task : table | function | RBXScriptConnection | Instance) --> void []
	Maid:LinkToInstances(instances : table) --> instances []

	Maid.Destroy = Maid.Cleanup (Alias)
]]

local Maid = {}
Maid.__index = Maid

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

local function IsInstanceDestroyed(instance)
	local _, response = pcall(function()
		instance.Parent = instance
	end)

	return response:find("locked") ~= nil
end

function Maid.new()
	return setmetatable({
		_tasks = {},
	}, Maid)
end

function Maid.IsMaid(self)
	return getmetatable(self) == Maid
end

function Maid:AddTask(task)
	assert(
		typeof(task) == "function"
			or typeof(task) == "RBXScriptConnection"
			or typeof(task) == "table" and (typeof(task.Destroy) == "function" or typeof(task.Disconnect) == "function")
			or typeof(task) == "Instance",

		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Maid:AddTask()",
			"function or RBXScriptConnection or table with Destroy or Disconnect method or Instance",
			typeof(task)
		)
	)

	self._tasks[task] = task

	return task
end

function Maid:RemoveTask(task)
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

function Maid:LinkToInstances(instances)
	assert(
		typeof(instances) == "table",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "Maid:LinkToInstances()", "table", typeof(instances))
	)

	local function TrackInstanceConnectionForCleanup(instance, connection)
		while connection.Connected and not instance.Parent do
			task.wait()
		end

		if not connection.Connected then
			self:Cleanup()
		end
	end

	for _, instance in ipairs(instances) do
		-- If the instance was parented to nil, then destroy the maid because its possible
		-- that the instance may have already been destroyed:
		if IsInstanceDestroyed(instance) then
			self:Cleanup()
			break
		end

		local instanceParentChangedConnection
		instanceParentChangedConnection = self:AddTask(instance:GetPropertyChangedSignal("Parent"):Connect(function()
			if not instance.Parent then
				task.defer(function()
					-- If the connection has also been disconnected, then its
					-- guaranteed that the instance has been destroyed through
					-- Destroy():
					if not instanceParentChangedConnection.Connected then
						self:Cleanup()
					else
						-- The instance was just parented to nil:
						TrackInstanceConnectionForCleanup(instance, instanceParentChangedConnection)
					end
				end)
			end
		end))

		if not instance.Parent then
			task.defer(TrackInstanceConnectionForCleanup, instance, instanceParentChangedConnection)
		end
	end

	return instances
end

function Maid:Cleanup()
	local tasks = self._tasks
	self._tasks = {}

	for _, task in pairs(tasks) do
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
end

Maid.Destroy = Maid.Cleanup

return Maid
