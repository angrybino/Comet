-- angrybino
-- init
-- September 26, 2021

--[[
	SafeWaitUtil.WaitForChild(instance : Instance, childName : string, timeOut : number ?) 
    --> Instance | nil [Child]

	SafeWaitUtil.WaitForFirstChildWhichIsA(instance : Instance, class : string, timeOut : number  ?) 
    --> Instance | nil [Child]

	SafeWaitUtil.WaitForFirstChildOfClass(instance : Instance, class : string, timeOut : number  ?) 
    --> Instance | nil [Child]
]]

local SafeWaitUtil = {}

local Signal = require(script.Signal)
local Maid = require(script.Maid)

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

local function DeferredFireSignalOnTimeout(timeout, signal)
	task.delay(timeout, function()
		if not signal:IsDestroyed() then
			signal:DeferredFire(nil)
		end
	end)
end

function SafeWaitUtil.WaitForChild(instance, childName, timeout)
	assert(
		typeof(instance) == "Instance",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "SafeWaitForChild()", "instance", typeof(instance))
	)
	assert(
		typeof(childName) == "string",
		LocalConstants.ErrorMessages.InvalidArgument:format(2, "SafeWaitForChild()", "string", typeof(childName))
	)

	if timeout then
		assert(
			typeof(timeout) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				3,
				"SafeWaitUtil.WaitForChild()",
				"number or nil",
				typeof(timeout)
			)
		)
	end

	do
		local instance = instance:FindFirstChild(childName)
		if instance then
			return instance
		end
	end

	local maid = Maid.new()
	local onChildAdded = Signal.new()

	maid:AddTask(function()
		onChildAdded:DeferredFire(nil)
		onChildAdded:Destroy()
	end)
	maid:LinkToInstances({ instance })

	maid:AddTask(instance.ChildAdded:Connect(function(child)
		if child.Name == childName and not onChildAdded:IsDestroyed() then
			onChildAdded:DeferredFire(child)
		end
	end))

	if timeout then
		DeferredFireSignalOnTimeout(timeout, onChildAdded)
	end

	local child = onChildAdded:Wait()
	if not maid:IsDestroyed() then
		maid:Destroy()
	end

	return child
end

function SafeWaitUtil.WaitForFirstChildWhichIsA(instance, class, timeout)
	assert(
		typeof(instance) == "Instance",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"SafeWaitUtil.WaitForFirstChildWhichIsA()",
			"instance",
			typeof(instance)
		)
	)
	assert(
		typeof(class) == "string",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"SafeWaitUtil.WaitForFirstChildWhichIsA()",
			"string",
			typeof(class)
		)
	)
	if timeout then
		assert(
			typeof(timeout) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				3,
				"SafeWaitUtil.WaitForFirstChildWhichIsA()",
				"number or nil",
				typeof(timeout)
			)
		)
	end

	do
		local instance = instance:FindFirstChildWhichIsA(class)
		if instance then
			return instance
		end
	end

	local maid = Maid.new()
	local onChildAdded = Signal.new()

	maid:AddTask(function()
		onChildAdded:DeferredFire(nil)
		onChildAdded:Destroy()
	end)
	maid:LinkToInstances({ instance })

	maid:AddTask(instance.ChildAdded:Connect(function(child)
		if child:IsA(class) and not onChildAdded:IsDestroyed() then
			onChildAdded:DeferredFire(child)
		end
	end))

	if timeout then
		DeferredFireSignalOnTimeout(timeout, onChildAdded)
	end

	local child = onChildAdded:Wait()
	if not maid:IsDestroyed() then
		maid:Destroy()
	end

	return child
end

function SafeWaitUtil.WaitForFirstChildOfClass(instance, class, timeout)
	assert(
		typeof(instance) == "Instance",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"SafeWaitUtil.WaitForFirstChildOfClass()",
			"instance",
			typeof(instance)
		)
	)
	assert(
		typeof(class) == "string",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"SafeWaitUtil.WaitForFirstChildOfClass()",
			"string",
			typeof(class)
		)
	)
	if timeout then
		assert(
			typeof(timeout) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				3,
				"SafeWaitUtil.WaitForFirstChildOfClass()",
				"number or nil",
				typeof(timeout)
			)
		)
	end

	do
		local instance = instance:FindFirstChildOfClass(class)
		if instance then
			return instance
		end
	end

	local maid = Maid.new()
	local onChildAdded = Signal.new()

	maid:AddTask(function()
		onChildAdded:DeferredFire(nil)
		onChildAdded:Destroy()
	end)
	maid:LinkToInstances({ instance })

	maid:AddTask(instance.ChildAdded:Connect(function(child)
		if child.ClassName == class and not onChildAdded:IsDestroyed() then
			onChildAdded:DeferredFire(child)
		end
	end))

	if timeout then
		DeferredFireSignalOnTimeout(timeout, onChildAdded)
	end

	local child = onChildAdded:Wait()
	if not maid:IsDestroyed() then
		maid:Destroy()
	end

	return child
end

return SafeWaitUtil
