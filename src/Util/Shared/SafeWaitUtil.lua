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

local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)
local SharedConstants = require(script.Parent.SharedConstants)

function SafeWaitUtil.WaitForChild(instance, childName, timeout)
	assert(
		typeof(instance) == "Instance",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "SafeWaitForChild()", "instance", typeof(instance))
	)
	assert(
		typeof(childName) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(2, "SafeWaitForChild()", "string", typeof(childName))
	)

	if timeout then
		assert(
			typeof(timeout) == "number",
			SharedConstants.ErrorMessages.InvalidArgument:format(
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
	local onChildAdded = Signal.new()

	maid:AddTask(function()
		onChildAdded:DeferredFire(child)
	end)

	maid:AddTask(instance.ChildAdded:Connect(function(childAdded)
		if childAdded.Name == childName then
			onChildAdded:DeferredFire(childAdded)
		end
	end))

	maid:LinkToInstance(instance)

	if timeout then
		task.delay(timeout, maid.Cleanup, maid)
	end

	local child = onChildAdded:Wait()
	onChildAdded:Destroy()
	maid:Destroy()

	return child
end

function SafeWaitUtil.WaitForFirstChildWhichIsA(instance, class, timeout)
	assert(
		typeof(instance) == "Instance",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"SafeWaitUtil.WaitForFirstChildWhichIsA()",
			"instance",
			typeof(instance)
		)
	)
	assert(
		typeof(class) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"SafeWaitUtil.WaitForFirstChildWhichIsA()",
			"string",
			typeof(class)
		)
	)
	if timeout then
		assert(
			typeof(timeout) == "number",
			SharedConstants.ErrorMessages.InvalidArgument:format(
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
	local onChildAdded = Signal.new()

	maid:AddTask(function()
		onChildAdded:DeferredFire(child)
	end)

	maid:AddTask(instance.ChildAdded:Connect(function(childAdded)
		if childAdded:IsA(class) then
			onChildAdded:DeferredFire(childAdded)
		end
	end))

	maid:LinkToInstance(instance)

	if timeout then
		task.delay(timeout, maid.Cleanup, maid)
	end

	local child = onChildAdded:Wait()
	onChildAdded:Destroy()
	maid:Destroy()

	return child
end

function SafeWaitUtil.WaitForFirstChildOfClass(instance, class, timeout)
	assert(
		typeof(instance) == "Instance",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"SafeWaitUtil.WaitForFirstChildOfClass()",
			"instance",
			typeof(instance)
		)
	)
	assert(
		typeof(class) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			2,
			"SafeWaitUtil.WaitForFirstChildOfClass()",
			"string",
			typeof(class)
		)
	)
	if timeout then
		assert(
			typeof(timeout) == "number",
			SharedConstants.ErrorMessages.InvalidArgument:format(
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
	local onChildAdded = Signal.new()

	maid:AddTask(function()
		onChildAdded:DeferredFire(child)
	end)

	maid:AddTask(instance.ChildAdded:Connect(function(childAdded)
		if childAdded.ClassName == class then
			onChildAdded:DeferredFire(childAdded)
		end
	end))

	maid:LinkToInstance(instance)

	if timeout then
		task.delay(timeout, maid.Cleanup, maid)
	end

	local child = onChildAdded:Wait()
	onChildAdded:Destroy()
	maid:Destroy()

	return child
end

return SafeWaitUtil
