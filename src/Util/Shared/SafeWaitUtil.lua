-- angrybino
-- init
-- October 09, 2021

--[[
	SafeWaitUtil.WaitForChild(instance : Instance, childName : string, timeOut : number ?) 
    --> Instance ? []

	SafeWaitUtil.WaitForFirstChildWhichIsA(instance : Instance, class : string, timeOut : number  ?) 
    --> Instance ? []

	SafeWaitUtil.WaitForFirstChildOfClass(instance : Instance, class : string, timeOut : number  ?) 
    --> Instance ? []
]]

local SafeWaitUtil = {}

local RunService = game:GetService("RunService")

local Maid = require(script.Parent.Maid)
local Timer = require(script.Parent.Timer)
local Signal = require(script.Parent.Signal)
local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)

local LocalConstants = {
	PossibleInfiniteYieldInterval = 10,
}

local function WaitAndThenRegisterForPossibleInfiniteYield(callInfo, yieldData)
	task.delay(LocalConstants.PossibleInfiniteYieldInterval, function()
		if yieldData.YieldFinished then
			return
		end

		warn(("Infinite yield possible on %s"):format(callInfo))
	end)
end

local function StartTimeoutTimer(timeout, maid)
	if not timeout then
		return
	end

	local timer = Timer.new(timeout)
	maid:AddTask(timer)

	timer.OnTick:Connect(function()
		maid:Cleanup()
	end)

	timer:Start()
end

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
	local yieldData = {}

	maid:AddTask(function()
		yieldData.YieldFinished = true
		onChildAdded:DeferredFire(nil)
	end)

	maid:AddTask(instance.ChildAdded:Connect(function(childAdded)
		if childAdded.Name == childName then
			onChildAdded:DeferredFire(childAdded)
		end
	end))

	maid:LinkToInstance(instance)
	StartTimeoutTimer(timeout, maid)
	WaitAndThenRegisterForPossibleInfiniteYield(
		("SafeWaitUtil.SafeWaitForChild(%s, %s)"):format(instance.Name, childName),
		yieldData
	)

	local child = onChildAdded:Wait()
	maid:Destroy()
	onChildAdded:Destroy()

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
	local yieldData = {}

	maid:AddTask(function()
		yieldData.YieldFinished = true
		onChildAdded:DeferredFire(nil)
	end)

	maid:AddTask(instance.ChildAdded:Connect(function(childAdded)
		if childAdded:IsA(class) then
			onChildAdded:DeferredFire(childAdded)
		end
	end))

	maid:LinkToInstance(instance)
	StartTimeoutTimer(timeout, maid)
	WaitAndThenRegisterForPossibleInfiniteYield(
		("SafeWaitUtil.WaitForFirstChildWhichIsA(%s, %s)"):format(instance.Name, class),
		yieldData
	)

	local child = onChildAdded:Wait()
	maid:Destroy()
	onChildAdded:Destroy()

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
	local yieldData = {}

	maid:AddTask(function()
		yieldData.YieldFinished = true
		onChildAdded:DeferredFire(nil)
	end)

	maid:AddTask(instance.ChildAdded:Connect(function(childAdded)
		if childAdded.ClassName == class then
			onChildAdded:DeferredFire(childAdded)
		end
	end))

	maid:LinkToInstance(instance)
	StartTimeoutTimer(timeout, maid)
	WaitAndThenRegisterForPossibleInfiniteYield(
		("SafeWaitUtil.WaitForFirstChildOfClass(%s, %s)"):format(instance.Name, class),
		yieldData
	)

	local child = onChildAdded:Wait()
	maid:Destroy()
	onChildAdded:Destroy()

	return child
end

return SafeWaitUtil
