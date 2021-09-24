-- SilentsReplacement
-- SafeWaitForChild
-- July 01, 2021

--[[
	SafeWaitForChild(instance : Instance, childName : string, timeOut : number | nil) 
    --> Instance | void [Child]
]]

local Signal = require(script.Signal)
local Maid = require(script.Maid)

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

return function(instance, childName, timeOut)
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
				"SafeWaitForChild()",
				"number or nil",
				typeof(timeOut)
			)
		)
	end

	if instance:FindFirstChild(childName) then
		return instance[childName]
	end

	local maid = Maid.new()
	local onChildAdded = Signal.new()

	maid:AddTask(onChildAdded)

	maid:AddTask(instance:GetPropertyChangedSignal("Parent"):Connect(function(_, parent)
		if not parent then
			onChildAdded:Fire()
		end
	end))

	maid:AddTask(instance.ChildAdded:Connect(function(child)
		if child.Name == childName then
			onChildAdded:Fire(child)
		end
	end))

	if timeOut then
		task.spawn(function()
			task.wait(timeOut)
			onChildAdded:Fire()
		end)
	end

	local returnValue = onChildAdded:Wait()
	maid:Destroy()

	return returnValue
end
