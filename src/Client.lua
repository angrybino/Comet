-- SilentsReplacement
-- Client
-- September 23, 2021

--[[
	Client.Util : Folder
	Client.Controllers : table
	Client.Version : string
	
	Client.SetControllersFolder(controllersFolder : Folder) --> void []
	Client.Start() --> Promise []
	Client.GetService(service : string) --> table [Service]
	Client.GetController(controllerName : string) --> table [Controller]
]]

local Client = {
	Util = script.Parent.Util,
	Controllers = {},

	_servicesBuilt = {},
	_controllersSet = {},
	_isStarted = false,
}

local Players = game:GetService("Players")

local Promise = require(Client.Util.Promise)
local ClientRemoteSignal = require(Client.Util.Remote.ClientRemoteSignal)
local ClientRemoteProperty = require(Client.Util.Remote.ClientRemoteProperty)
local SharedConstants = require(script.Parent.SharedConstants)
local SafeWaitForChild = require(Client.Util.SafeWaitForChild)

local servicesFolder = SafeWaitForChild(script, "ClientExposedServices")

Client.Version = SharedConstants.Version
Client.LocalPlayer = Players.LocalPlayer

function Client.GetService(service)
	assert(
		typeof(service) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Client.GetService()", "string", typeof(service))
	)

	assert(servicesFolder:FindFirstChild(service), ("%s Service [%s] not found!"):format(SharedConstants.Comet, service))

	return Client._servicesBuilt[service] or Client._buildService(service)
end

function Client.GetController(controllerName)
	assert(
		typeof(controllerName) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Client.GetController()", "string", typeof(controllerName))
	)

	assert(Client.Controllers[controllerName], ("Controller [%s] not found!"):format(controllerName))

	return Client.Controllers[controllerName]
end

function Client.SetControllersFolder(controllersFolder)
	assert(
		typeof(controllersFolder) == "Instance" and controllersFolder:IsA("Folder"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Comet.SetControllersFolder()",
			"Folder",
			typeof(controllersFolder)
		)
	)

	Client._controllersFolder = controllersFolder:GetChildren()
end

function Client.Start()
	if Client._isStarted then
		return Promise.reject("Can't start Comet as it is already started")
	end

	Client._isStarted = true

	return Promise.async(function(resolve)
		local promises = Client._initControllers(Client._controllersFolder)
		resolve(Promise.All(promises))
	end):andThen(function()
		-- Start all controllers now as we know it is safe:
		Client._startControllers()
	end)
end

function Client._startControllers(folder)
	if not folder then
		return
	end

	-- Init all controllers:
	for _, controller in ipairs(folder:GetChildren()) do
		if not controller:IsA("ModuleScript") then
			if controller:IsA("Folder") then
				Client._startControllers(folder)
			end

			continue
		end

		local requiredController = require(controller)

		if typeof(requiredController.Start) == "function" then
			task.spawn(requiredController.Start)
			Client.Controllers[controller.Name] = requiredController
		end
	end
end

function Client._initControllers(folder)
	local promises = {}

	if folder then
		-- Init all controllers:
		for _, controller in ipairs(folder:GetChildren()) do
			if not controller:IsA("ModuleScript") then
				if controller:IsA("Folder") then
					Client._initControllers(folder)
				end

				continue
			end

			local requiredController = require(controller)
			requiredController.Comet = Client

			if typeof(requiredController.Init) == "function" then
				table.insert(
					promises,
					Promise.async(function(resolve)
						requiredController.Init()
						resolve()
					end)
				)
			end

			Client.Controllers[controller.Name] = requiredController
		end
	end

	return promises
end

function Client._buildService(serviceName)
	local service = servicesFolder[serviceName]
	local clientExposedMethods = service.ClientExposedMethods:GetChildren()
	local clientExposedRemoteSignals = service.ClientExposedRemoteSignals:GetChildren()
	local clientExposedRemoteProperties = service.ClientExposedRemoteProperties:GetChildren()
	local clientExposedMembers = service.ClientExposedMembers:GetChildren()
	local builtService = {}

	-- Expose methods to the client:
	for _, method in ipairs(clientExposedMethods) do
		builtService[method.Name] = function(...)
			return method:InvokeServer(...)
		end
	end

	-- Expose members to the client:
	for _, member in ipairs(clientExposedMembers) do
		builtService[member.Name] = member:InvokeServer()
	end

	-- Expose remote signals to the client:
	for _, remoteSignal in ipairs(clientExposedRemoteSignals) do
		builtService[remoteSignal.Name] = ClientRemoteSignal.new(remoteSignal)
	end

	-- Expose remote properties to the client:
	for _, remoteProperty in ipairs(clientExposedRemoteProperties) do
		builtService[remoteProperty.Name] = ClientRemoteProperty.new(remoteProperty)
	end

	Client._servicesBuilt[service] = builtService

	return builtService
end

return Client