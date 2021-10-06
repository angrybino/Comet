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
	Maid:IsDestroyed() --> boolean [IsDestroyed]
	Maid:RemoveTask(task : table | function | RBXScriptConnection | Instance) --> void []
	Maid:Destroy() --> void []
	Maid:LinkToInstances(instances : table) --> instances []
]]

local Maid = {}
Maid.__index = Maid

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)
local TableUtil = require(script.Parent.TableUtil)

local LocalConstants = {
	ErrorMessages = {
		Destroyed = "Maid object is destroyed",
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

		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Maid:AddTask()",
			"function or RBXScriptConnection or table with Destroy or Disconnect method or Instance",
			typeof(task)
		)
	)

	table.insert(self._tasks, task)

	return task
end

function Maid:RemoveTask(task)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	assert(
		typeof(task) == "function"
			or typeof(task) == "RBXScriptConnection"
			or typeof(task) == "table" and (typeof(task.Destroy) == "function" or typeof(task.Disconnect) == "function")
			or typeof(task) == "Instance",

		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Maid:RemoveTask()",
			"function or RBXScriptConnection or table with Destroy or Disconnect method or Instance",
			typeof(task)
		)
	)

	table.remove(self._tasks, table.remove(self._tasks, task))
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
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Maid:LinkToInstances()", "table", typeof(instances))
	)

	local function TrackInstanceConnection(instance, connection)
		while connection.Connected and not instance.Parent do
			task.wait()
		end

		if not self:IsDestroyed() and not connection.Connected then
			self:Destroy()
		end
	end

	for _, instance in ipairs(instances) do
		-- If the instance was parented to nil, then destroy the maid because its possible
		-- that the instance may have already been destroyed:
		if IsInstanceDestroyed(instance) then
			self:Destroy()
			break
		end

		local instanceParentChangedConnection
		instanceParentChangedConnection = self:AddTask(instance:GetPropertyChangedSignal("Parent"):Connect(function()
			if not instance.Parent then
				task.defer(function()
					-- If the connection has also been disconnected, then its
					-- guaranteed that the instance has been destroyed through
					-- Destroy():
					if not self:IsDestroyed() and not instanceParentChangedConnection.Connected then
						self:Destroy()
					else
						-- The instance was just parented to nil:
						TrackInstanceConnection(instance, instanceParentChangedConnection)
					end
				end)
			end
		end))

		if not instance.Parent then
			task.spawn(TrackInstanceConnection, instance, instanceParentChangedConnection)
		end
	end

	return instances
end

function Maid:Cleanup()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	local tasks = TableUtil.ShallowCopyTable(self._tasks)
	self._tasks = {}

	for index, task in pairs(tasks) do
		tasks[index] = nil

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

return Maid
