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
	_components = {},
}
Component.__index = Component

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")

local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)
local Maid = require(comet.Util.Maid)
local Signal = require(comet.Util.Signal)

local LocalConstants = {
	WhitelistedServices = { Workspace },
	IsClient = RunService:IsClient(),
	RenderUpdatePriority = Enum.RenderPriority.Last.Value,
}

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

	for _, component in ipairs(Component._components) do
		local componentObject = component._objects[instance]
		if componentObject then
			return componentObject
		end
	end

	return nil
end

function Component.GetAll()
	local componentObjects = {}

	for _, component in ipairs(Component._components) do
		table.insert(componentObjects, component._objects)
	end

	return componentObjects
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

	Component._componentsFolder = componentsFolder
end

function Component.Start()
	local componentsFolder = Component._componentsFolder

	if not componentsFolder then
		return
	end

	for _, component in ipairs(componentsFolder:GetChildren()) do
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

		if LocalConstants.IsClient and requiredComponent.RenderUpdatePriority then
			assert(
				typeof(requiredComponent.RenderUpdatePriority) == "number",
				("RenderUpdatePriority in Component [%s] must be a number!"):format(component.Name)
			)
		end

		if not LocalConstants.IsClient then
			assert(
				typeof(requiredComponent.RenderUpdate) ~= "function",
				("Component [%s] must not have a RenderUpdate method as it is bound by the server"):format(
					component.Name
				)
			)
		end

		table.insert(Component._components, Component._new(requiredComponent))
	end
end

function Component._new(requiredComponent)
	local self = {
		_componentObjectAdded = Signal.new(),
		_componentObjectDestroyed = Signal.new(),
		_maid = Maid.new(),
		_requiredComponent = requiredComponent,
		_objects = {},
		_tags = requiredComponent.OptionalTags or requiredComponent.RequiredTags,
		_renderUpdatePriority = requiredComponent.RenderUpdatePriority or LocalConstants.RenderUpdatePriority,
		_areTagsRequired = requiredComponent.RequiredTags ~= nil,
		_hasPhysicsUpdateMethod = typeof(requiredComponent.PhysicsUpdate) == "function",
		_hasInitMethod = typeof(requiredComponent.Init) == "function",
		_hasDeinitMethod = typeof(requiredComponent.Deinit) == "function",
		_hasRenderUpdateMethod = typeof(requiredComponent.RenderUpdate) == "function",
		_heartbeatUpdateMethod = typeof(requiredComponent.HeartbeatUpdate) == "function",
		_lifeCycleStarted = false,
	}

	setmetatable(self, Component)
	self._memoryId = tostring(self)

	self._componentObjectAdded:Connect(function()
		if self._lifeCycleStarted then
			return
		end

		self:_startLifeCycle()
	end)

	self._componentObjectDestroyed:Connect(function()
		if self._lifeCycleStarted and not next(self._objects) then
			self:_stopLifeCycle()
		end
	end)

	for _, tag in ipairs(self._tags) do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			if not Component._isInstanceDescendantOfAnyWhiteListedService(instance) or self._objects[instance] then
				return
			end

			if
				self._areTagsRequired and Component._doesInstanceHaveRequiredTags(instance, self._tags)
				or not self._areTagsRequired and Component._doesInstanceHaveAnyOptionalTags(instance, self._tags)
			then
				self:_createAndSetupComponentObject(instance)
			end
		end)

		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
			if not Component._isInstanceDescendantOfAnyWhiteListedService(instance) or not self._objects[instance] then
				return
			end

			if not self._areTagsRequired and Component._doesInstanceHaveAnyOptionalTags(instance, self._tags) then
				return
			end

			self:_destroyComponentObject(self._objects[instance], instance)
		end)
	end

	for _, tag in ipairs(self._tags) do
		-- CollectionService:GetTagged() should accept a table...
		for _, instance in ipairs(CollectionService:GetTagged(tag)) do
			if
				self._areTagsRequired and Component._doesInstanceHaveRequiredTags(instance, self._tags)
				or not self._areTagsRequired
					and Component._doesInstanceHaveAnyOptionalTags(instance, self._tags)
			then
				self:_createAndSetupComponentObject(instance)
			end
		end
	end

	return self
end

function Component:_startLifeCycle()
	self._lifeCycleStarted = true

	if self._hasPhysicsUpdateMethod then
		self:_startPhysicsUpdate()
	end

	if self._heartbeatUpdateMethod then
		self:_startHeartbeatUpdate()
	end

	if self._hasRenderUpdateMethod and LocalConstants.IsClient then
		self:_startRenderUpdate()
	end
end

function Component:_stopLifeCycle()
	self._lifeCycleStarted = false
	self._maid:Cleanup()
end

function Component:_startHeartbeatUpdate()
	self._maid:AddTask(RunService.Heartbeat:Connect(function(deltaTime)
		for _, component in pairs(self._objects) do
			component:HeartbeatUpdate(deltaTime)
		end
	end))
end

function Component:_startRenderUpdate()
	RunService:BindToRenderStep(self._memoryId, self._renderUpdatePriority, function(deltaTime)
		for _, component in pairs(self._objects) do
			component:RenderUpdate(deltaTime)
		end
	end)
end

function Component:_startPhysicsUpdate()
	self._maid:AddTask(RunService.Stepped:Connect(function(deltaTime)
		for _, component in pairs(self._objects) do
			component:PhysicsUpdate(deltaTime)
		end
	end))
end

function Component:_createAndSetupComponentObject(instance)
	if self._objects[instance] then
		return
	end

	local componentObject = self._requiredComponent.new(instance)
	self._objects[instance] = componentObject

	if self._hasInitMethod then
		componentObject:Init()
	end

	self._componentObjectAdded:Fire(componentObject)

	local instanceParentChangedConnection
	instanceParentChangedConnection = instance:GetPropertyChangedSignal("Parent"):Connect(function()
		if not instanceParentChangedConnection.Connected then
			return
		end

		if Component._isInstanceDescendantOfAnyWhiteListedService(instance) then
			if
				self._areTagsRequired and Component._doesInstanceHaveRequiredTags(instance, self._tags)
				or not self._areTagsRequired and Component._doesInstanceHaveAnyOptionalTags(instance, self._tags)
			then
				instanceParentChangedConnection:Disconnect()
				self:_createAndSetupComponentObject(instance)
			end
		else
			self:_destroyComponentObject(componentObject, instance)
		end
	end)

	return componentObject
end

function Component:_destroyComponentObject(componentObject, instance)
	if not self._objects[instance] then
		return
	end

	self._objects[instance] = nil

	if self._hasDeinitMethod then
		componentObject:Deinit()
	end

	componentObject:Destroy()
	self._componentObjectDestroyed:Fire(componentObject)
end

function Component._doesInstanceHaveAnyOptionalTags(instance, optionalTags)
	for _, tag in ipairs(optionalTags) do
		if CollectionService:HasTag(instance, tag) then
			return true
		end
	end

	return false
end

function Component._doesInstanceHaveRequiredTags(instance, requiredTags)
	for _, tag in ipairs(requiredTags) do
		if not CollectionService:HasTag(instance, tag) then
			return false
		end
	end

	return true
end

function Component._isInstanceDescendantOfAnyWhiteListedService(instance)
	for _, whiteListedService in ipairs(LocalConstants.WhitelistedServices) do
		if instance:IsDescendantOf(whiteListedService) then
			return true
		end
	end

	return false
end

return Component
