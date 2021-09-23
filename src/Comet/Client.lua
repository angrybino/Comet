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

	assert(
		servicesFolder:FindFirstChild(service),
		("%s Service [%s] not found!"):format(SharedConstants.Comet, service)
	)

	return Client._servicesBuilt[service] or Client._buildService(service)
end

function Client.GetController(controllerName)
	assert(
		typeof(controllerName) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Client.GetController()",
			"string",
			typeof(controllerName)
		)
	)

	assert(
		Client.Controllers[controllerName],
		("%s Controller [%s] not found!"):format(SharedConstants.Comet, controllerName)
	)

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

	Client._controllersSet = controllersFolder:GetChildren()
end

function Client.Start()
	if Client._isStarted then
		return Promise.reject(("%s Already started"):format(SharedConstants.Comet))
	end

	Client._controllersSet = Client._controllersSet or {}
	Client._isStarted = true

	return Promise.async(function(resolve, reject)
		local success, errorMessage = pcall(function()
			-- Init all controllers first and inject the framework reference:
			for _, controller in ipairs(Client._controllersSet) do
				local requiredController = require(controller)
				requiredController.Comet = Client

				if typeof(requiredController.Init) == "function" then
					requiredController.Init()
				end
			end

			-- Start all controllers now as we know it is safe:
			for _, controller in ipairs(Client._controllersSet) do
				local requiredController = require(controller)

				if typeof(requiredController.Start) == "function" then
					task.spawn(requiredController.Start)
				end

				Client.Controllers[controller.Name] = requiredController
			end
		end)

		if success then
			resolve()
		else
			reject(errorMessage)
		end
	end)
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
