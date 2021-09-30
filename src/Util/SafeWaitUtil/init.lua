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
local Timer = require(script.Parent.Timer)

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

function SafeWaitUtil.WaitForChild(instance, childName, timeOut)
	assert(
		typeof(instance) == "Instance",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "SafeWaitForChild()", "instance", typeof(instance))
	)
	assert(
		typeof(childName) == "string",
		LocalConstants.ErrorMessages.InvalidArgument:format(2, "SafeWaitForChild()", "string", typeof(childName))
	)

	if timeOut then
		assert(
			typeof(timeOut) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				3,
				"SafeWaitUtil.WaitForChild()",
				"number or nil",
				typeof(timeOut)
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

	maid:AddTask(onChildAdded)
	maid:LinkToInstances(instance)

	maid:AddTask(instance.ChildAdded:Connect(function(child)
		if child.Name == childName and not onChildAdded:IsDestroyed() then
			onChildAdded:Fire(child)
		end
	end))

	if timeOut then
		local timer = maid:AddTask(Timer.new(timeOut))

		timer.OnTimerTick:Connect(function()
			if not timer:IsDestroyed() then
				onChildAdded:Fire(nil)
			end
		end)
	end

	local child = onChildAdded:Wait()
	maid:Destroy()

	return child
end

function SafeWaitUtil.WaitForFirstChildWhichIsA(instance, class, timeOut)
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
	if timeOut then
		assert(
			typeof(timeOut) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				3,
				"SafeWaitUtil.WaitForFirstChildWhichIsA()",
				"number or nil",
				typeof(timeOut)
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

	maid:AddTask(onChildAdded)
	maid:LinkToInstances(instance)

	maid:AddTask(instance.ChildAdded:Connect(function(child)
		if child:IsA(class) and not onChildAdded:IsDestroyed() then
			onChildAdded:Fire(child)
		end
	end))

	if timeOut then
		local timer = maid:AddTask(Timer.new(timeOut))

		timer.OnTimerTick:Connect(function()
			if not timer:IsDestroyed() then
				onChildAdded:Fire(nil)
			end
		end)
	end

	local child = onChildAdded:Wait()
	maid:Destroy()

	return child
end

function SafeWaitUtil.WaitForFirstChildOfClass(instance, class, timeOut)
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
	if timeOut then
		assert(
			typeof(timeOut) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				3,
				"SafeWaitUtil.WaitForFirstChildOfClass()",
				"number or nil",
				typeof(timeOut)
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

	maid:AddTask(onChildAdded)
	maid:LinkToInstances(instance)

	maid:AddTask(instance.ChildAdded:Connect(function(child)
		if child.ClassName == class and not onChildAdded:IsDestroyed() then
			onChildAdded:Fire(child)
		end
	end))

	if timeOut then
		local timer = maid:AddTask(Timer.new(timeOut))

		timer.OnTimerTick:Connect(function()
			if not timer:IsDestroyed() then
				onChildAdded:Fire(nil)
			end
		end)
	end

	local child = onChildAdded:Wait()
	maid:Destroy()

	return child
end

return SafeWaitUtil
