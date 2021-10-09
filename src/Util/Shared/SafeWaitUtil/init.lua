-- angrybino
-- init
-- September 26, 2021

--[[
	SafeWaitUtil.WaitForChild(instance : Instance, childName : string, timeOut : number ?) 
    --> Instance ? [Child]

	SafeWaitUtil.WaitForFirstChildWhichIsA(instance : Instance, class : string, timeOut : number  ?) 
    --> Instance ? [Child]

	SafeWaitUtil.WaitForFirstChildOfClass(instance : Instance, class : string, timeOut : number  ?) 
    --> Instance ? [Child]
]]

local SafeWaitUtil = {}

local RunService = game:GetService("RunService")

local Maid = require(script.Maid)
local Timer = require(script.Timer)

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

local function DeferredFireBindable(bindable, ...)
	task.defer(bindable.Fire, bindable, ...)
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

	local child = instance:FindFirstChild(childName)
	if child then
		return child
	end

	local maid = Maid.new()
	local onChildAdded = Instance.new("BindableEvent")

	maid:AddTask(function()
		DeferredFireBindable(onChildAdded, nil)
	end)

	maid:AddTask(instance.ChildAdded:Connect(function(childAdded)
		if childAdded.Name == childName then
			DeferredFireBindable(onChildAdded, childAdded)
		end
	end))

	maid:LinkToInstance(instance)

	if timeout then
		local timer = Timer.new(timeout)
		maid:AddTask(timer)

		timer.OnTick:Connect(function()
			maid:Cleanup()
		end)

		timer:Start()
	end

	local child = onChildAdded.Event:Wait()
	maid:Destroy()
	onChildAdded:Destroy()

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

	local child = instance:FindFirstChildWhichIsA(class)
	if child then
		return child
	end

	local maid = Maid.new()
	local onChildAdded = Instance.new("BindableEvent")

	maid:AddTask(function()
		DeferredFireBindable(onChildAdded, nil)
	end)

	maid:AddTask(instance.ChildAdded:Connect(function(childAdded)
		if childAdded:IsA(class) then
			DeferredFireBindable(onChildAdded, childAdded)
		end
	end))

	maid:LinkToInstance(instance)

	if timeout then
		local timer = Timer.new(timeout)
		maid:AddTask(timer)

		timer.OnTick:Connect(function()
			maid:Cleanup()
		end)

		timer:Start()
	end

	local child = onChildAdded.Event:Wait()
	maid:Destroy()
	onChildAdded:Destroy()

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
	local child = instance:FindFirstChildOfClass(class)
	if child then
		return child
	end

	local maid = Maid.new()
	local onChildAdded = Instance.new("BindableEvent")

	maid:AddTask(function()
		DeferredFireBindable(onChildAdded, nil)
	end)

	maid:AddTask(instance.ChildAdded:Connect(function(childAdded)
		if childAdded.ClassName == class then
			DeferredFireBindable(onChildAdded, childAdded)
		end
	end))

	maid:LinkToInstance(instance)

	if timeout then
		local timer = Timer.new(timeout)
		maid:AddTask(timer)

		timer.OnTick:Connect(function()
			maid:Cleanup()
		end)

		timer:Start()
	end

	local child = onChildAdded.Event:Wait()
	maid:Destroy()
	onChildAdded:Destroy()

	return child
end

return SafeWaitUtil
