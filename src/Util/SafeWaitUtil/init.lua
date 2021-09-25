-- SilentsReplacement
-- init
-- September 25, 2021

--[[
	SafeWaitUtil.WaitForChild(instance : Instance, childName : string, timeOut : number ?) 
    --> Instance | nil [Child]

	SafeWaitUtil.WaitForChildWhichIsA(instance : Instance, class : string, timeOut : number  ?) 
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

	maid:AddTask(instance:GetPropertyChangedSignal("Parent"):Connect(function()
		if not instance.Parent and not onChildAdded:IsDestroyed() then
			onChildAdded:Fire(nil)
		end
	end))

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

function SafeWaitUtil.WaitForChildWhichIsA(instance, class, timeOut)
	assert(
		typeof(instance) == "Instance",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"SafeWaitUtil.WaitForChildWhichIsA()",
			"instance",
			typeof(instance)
		)
	)
	assert(
		typeof(class) == "string",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			2,
			"SafeWaitUtil.WaitForChildWhichIsA()",
			"string",
			typeof(class)
		)
	)
	if timeOut then
		assert(
			typeof(timeOut) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				3,
				"SafeWaitUtil.WaitForChildWhichIsA()",
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

	maid:AddTask(instance:GetPropertyChangedSignal("Parent"):Connect(function()
		if not instance.Parent and not onChildAdded:IsDestroyed() then
			onChildAdded:Fire(nil)
		end
	end))

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

return SafeWaitUtil
