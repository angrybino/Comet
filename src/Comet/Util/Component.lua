-- SilentsReplacement
-- Component
-- September 23, 2021

--[[
	Component.SetComponentsFolder(componentsFolder : Folder) --> void []
	Component.GetFromInstance(instance : Instance) --> table | nil [ComponentObject]
	Component.GetAll() --> table | nil [ComponentObjects]
	Component.Start() --> void []
]]

local Component = {
	_activeComponentObjects = {},
	_globalComponentId = 0,
}

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)
local Maid = require(comet.Util.Maid)

local LocalConstants = {
	WhitelistedServices = { Workspace },
	IsClient = RunService:IsClient(),
	RenderPriority = Enum.RenderPriority.Last.Value,
	RenderUpdateLabel = "%sRenderUpdate",
}

function Component.GetAll()
	return Component._activeComponentObjects
end

function Component.GetFromInstance(instance)
	assert(
		typeof(instance) == "Instance",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Component.GetFromInstance()",
			"Instance",
			typeof(instance)
		)
	)

	return Component._activeComponentObjects[instance]
end

function Component.SetComponentsFolder(componentsFolder)
	assert(
		typeof(componentsFolder) == "Instance" and componentsFolder:IsA("Folder"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Component.SetComponentsFolder()",
			"Folder",
			typeof(componentsFolder)
		)
	)

	Component._components = componentsFolder:GetChildren()
end

function Component.Start()
	local maid = Maid.new()
	Component._maid = maid
	Component._components = Component._components or {}

	local function IsInstanceDescendantOfAnyWhiteListedService(instance)
		for _, whiteListedService in ipairs(LocalConstants.WhitelistedServices) do
			if instance:IsDescendantOf(whiteListedService) then
				return true
			end
		end
	end

	local function DoesInstanceHaveRequiredTags(instance, requiredTags)
		for _, tag in ipairs(requiredTags) do
			if not CollectionService:HasTag(instance, tag) then
				return false
			end
		end

		return true
	end

	local function DoesInstanceHaveAnyOptionalTags(instance, optionalTags)
		for _, tag in ipairs(optionalTags) do
			if CollectionService:HasTag(instance, tag) then
				return true
			end
		end

		return false
	end

	local function ObserveComponentForTags(requiredComponent)
		local tags = requiredComponent.OptionalTags or requiredComponent.RequiredTags
		local areAllTagsRequired = requiredComponent.RequiredTags ~= nil

		for _, tag in ipairs(tags) do
			CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
				if
					not IsInstanceDescendantOfAnyWhiteListedService(instance)
					or Component._activeComponentObjects[instance]
				then
					return
				end

				-- If all tags are required, make sure that the instance has all the tags.
				-- If any tags are required, make sure that the instance has any of those tags and
				-- the instance will be deemed valid:
				if not areAllTagsRequired then
					if not DoesInstanceHaveAnyOptionalTags(instance, tags) then
						return
					end
				elseif not DoesInstanceHaveRequiredTags(instance, tags) then
					return
				end

				local componentObject = Component._new(requiredComponent.new(instance), instance)
				Component._instanceAdded(componentObject)
			end)

			CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
				if not Component._activeComponentObjects[instance] then
					return
				end

				-- If all tags aren't required and the instance still has optional tags, the instance
				-- will be invalid for subject to removal:
				if not areAllTagsRequired and DoesInstanceHaveAnyOptionalTags(instance, tags) then
					return
				end

				Component._instanceRemoved(instance)
			end)
		end

		local validInstanceFound = false

		for _, tag in ipairs(tags) do
			-- CollectionService:GetTagged() should accept a table...
			for _, instance in ipairs(CollectionService:GetTagged(tag)) do
				if
					areAllTagsRequired and DoesInstanceHaveRequiredTags(instance, tags)
					or not areAllTagsRequired and DoesInstanceHaveAnyOptionalTags(instance, tags)
				then
					local componentObject = Component._new(requiredComponent.new(instance), instance)
					Component._instanceAdded(componentObject)
					validInstanceFound = true
					break
				end
			end

			if validInstanceFound then
				break
			end
		end
	end

	for _, component in ipairs(Component._components) do
		local requiredComponent = require(component)

		assert(
			(typeof(requiredComponent.RequiredTags) == "table" and not requiredComponent.OptionalTags)
				or (typeof(requiredComponent.OptionalTags) == "table" and not requiredComponent.RequiredTags),
			("Component [%s] must only have one RequiredTags or OptionalTags table"):format(component.Name)
		)
		assert(
			typeof(requiredComponent.new) == "function",
			("Component [%s] must have a .new constructor method!"):format(component.Name)
		)
		assert(
			typeof(requiredComponent.Destroy) == "function",
			("Component [%s] must have a Destroy method!"):format(component.Name)
		)

		if not LocalConstants.IsClient then
			assert(
				typeof(requiredComponent.RenderUpdate) ~= "function",
				("RenderUpdate method can't be called for a serverside bound component [%s]"):format(component.Name)
			)
		end

		ObserveComponentForTags(requiredComponent)
	end
end

function Component._instanceAdded(componentObject)
	if componentObject._hasInitMethod then
		componentObject._component:Init()
	end

	Component._activeComponentObjects[componentObject._instance] = componentObject
end

function Component._new(component, instance)
	Component._globalComponentId += 1

	local componentObject = {}
	componentObject._maid = Maid.new()
	componentObject._id = Component._globalComponentId
	componentObject._component = component
	componentObject._instance = instance
	componentObject._hasInitMethod = typeof(component.Init) == "function"
	componentObject._hasDeinitMethod = typeof(component.Deinit) == "function"
	componentObject._hasHeartbeatUpdateMethod = typeof(component.HeartbeatUpdate) == "function"
	componentObject._hasPhysicsUpdateMethod = typeof(component.PhysicsUpdate) == "function"
	componentObject._hasRenderUpdateMethod = typeof(component.RenderUpdate) == "function"
	componentObject._renderUpdatePriority = component.RenderUpdatePriority or LocalConstants.RenderPriority

	local renderUpdateLabel = LocalConstants.RenderUpdateLabel:format(componentObject._id)
	componentObject._maid:AddTask(function()
		RunService:UnbindFromRenderStep(renderUpdateLabel)
	end)

	if componentObject._hasHeartbeatUpdateMethod then
		componentObject._maid:AddTask(RunService.Heartbeat:Connect(function(deltaTime)
			componentObject._component:HeartbeatUpdate(deltaTime)
		end))
	end

	if componentObject._hasPhysicsUpdateMethod then
		componentObject._maid:AddTask(RunService.Stepped:Connect(function(deltaTime)
			componentObject._component:PhysicsUpdate(deltaTime)
		end))
	end

	if LocalConstants.IsClient and componentObject._hasRenderUpdateMethod then
		RunService:BindToRenderStep(renderUpdateLabel, componentObject._renderUpdatePriority, function(deltaTime)
			componentObject._component:RenderUpdate(deltaTime)
		end)
	end

	return componentObject
end

function Component._instanceRemoved(instance)
	Component._globalComponentId -= 1
	local componentObject = Component._activeComponentObjects[instance]

	if componentObject._hasDeinitMethod then
		componentObject._component:Deinit()
	end

	componentObject._component:Destroy()
	componentObject._maid:Destroy()
	Component._activeComponentObjects[instance] = nil
end

return Component
