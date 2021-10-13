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
	Maid:LinkToInstance(instance : Instance) --> (instance, ManualConnection) []
	Maid:Destroy() --> void []
]]

local Maid = {}
Maid.__index = Maid

local Players = game:GetService("Players")

local comet = script:FindFirstAncestor("Comet")
local Task = require(script.Parent.Task)
local SharedConstants = require(comet.SharedConstants)

local function IsInstanceDestroyed(instance)
	-- This function call is used to determine if an instance is ALREADY destroyed,
	-- and has been edited to be more reliable but still quite hacky due to Roblox
	-- not giving us a method to determine if an instance is already destroyed
	local _, response = pcall(function()
		instance.Parent = instance
	end)

	return (response:find("locked") and response:find("NULL") or nil) ~= nil
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

		SharedConstants.ErrorMessages.InvalidArgument:format(
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

		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Maid:RemoveTask()",
			"function or RBXScriptConnection or table with Destroy or Disconnect method or Instance",
			typeof(task)
		)
	)

	self._tasks[task] = nil
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

function Maid:Destroy()
	self:Cleanup()

	for key, _ in pairs(self) do
		self[key] = nil
	end

	setmetatable(self, nil)
end

local ManualConnection = {}
ManualConnection.__index = ManualConnection

do
	function ManualConnection.new()
		return setmetatable({ _isConnected = true }, ManualConnection)
	end

	function ManualConnection:Disconnect()
		self._isConnected = false
	end

	function ManualConnection:IsConnected()
		return self._isConnected
	end
end

function Maid:LinkToInstance(instance)
	assert(
		typeof(instance) == "Instance",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Maid:LinkToInstance()", "Instance", typeof(instance))
	)

	local mainConnection
	local manualConnection = ManualConnection.new()
	self:AddTask(manualConnection)

	local function TrackInstanceConnectionForCleanup()
		while mainConnection.Connected and not instance.Parent and manualConnection:IsConnected() do
			Task.Wait()
		end

		if not instance.Parent and manualConnection:IsConnected() then
			self:Cleanup()
		end
	end

	mainConnection = self:AddTask(instance:GetPropertyChangedSignal("Parent"):Connect(function()
		if not instance.Parent then
			Task.SafeDefer(function()
				if not manualConnection:IsConnected() then
					return
				end

				-- If the connection has also been disconnected, then its
				-- guaranteed that the instance has been destroyed through
				-- Destroy():
				if not mainConnection.Connected then
					self:Cleanup()
				else
					-- The instance was just parented to nil:
					TrackInstanceConnectionForCleanup()
				end
			end)
		end
	end))

	-- Special case for players as they are destroyed late when they leave which won't work out well:
	if instance:IsA("Player") then
		self:AddTask(Players.PlayerRemoving:Connect(function(playerRemoved)
			if instance == playerRemoved and manualConnection:IsConnected() then
				self:Cleanup()
			end
		end))
	end

	if not instance.Parent then
		Task.SafeSpawn(TrackInstanceConnectionForCleanup)
	end

	if IsInstanceDestroyed(instance) then
		self:Cleanup()
	end

	return manualConnection
end

return Maid
