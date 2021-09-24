-- SilentsReplacement
-- Server
-- September 23, 2021

--[[
	Server.Util : Folder
	Server.Services : table
	Server.Version : string

	Server.SetServicesFolder(servicesFolder : Folder) --> void []
	Server.GetService(serviceName : string) --> table | nil [Service]
	Server.Start() --> Promise []
]]

local Server = {
	Util = script.Parent.Util,
	Services = {},

	_isStarted = false,
}

local Promise = require(Server.Util.Promise)
local RemoteSignal = require(Server.Util.Remote.RemoteSignal)
local SharedConstants = require(script.Parent.SharedConstants)
local Signal = require(Server.Util.Signal)
local RemoteProperty = require(Server.Util.Remote.RemoteProperty)

Server.Version = SharedConstants.Version

function Server.SetServicesFolder(servicesFolder)
	assert(
		typeof(servicesFolder) == "Instance" and servicesFolder:IsA("Folder"),
		SharedConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Comet.SetServicesFolder()",
			"Folder",
			typeof(servicesFolder)
		)
	)

	Server._servicesFolder = servicesFolder
end

function Server.Start()
	if Server._isStarted then
		return Promise.reject("Can't start Comet as it is already started")
	end

	Server._isStarted = true

	return Promise.async(function(resolve)
		local promises = Server._initServices(Server._servicesFolder)
		resolve(Promise.All(promises))
	end):andThen(function()
		-- Start all services now as we know it is safe:
		Server._startServices(Server._servicesFolder)
		Server._clientExposedServicesFolder.Parent = script.Parent.Client
	end)
end

function Server.GetService(serviceName)
	assert(
		typeof(serviceName) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Comet.GetService()", "string", typeof(serviceName))
	)

	assert(Server.Services[serviceName], ("Service [%s] not found!"):format(serviceName))

	return Server.Services[serviceName]
end

function Server._startServices(folder)
	if not folder then
		return
	end

	-- Start all services:
	for _, service in ipairs(folder:GetChildren()) do
		if not service:IsA("ModuleScript") then
			if service:IsA("Folder") then
				Server._startServices(service)
			end

			continue
		end

		local requiredService = require(service)

		if typeof(requiredService.Start) == "function" then
			requiredService.Start()
		end
	end
end

function Server._initServices(folder)
	local function SetupServiceClientExposedStuff(service, folder)
		local serviceRemotesFolder = Instance.new("Folder")
		serviceRemotesFolder.Name = service.Name
		serviceRemotesFolder.Parent = folder

		local clientExposedMethodsFolder = Instance.new("Folder")
		clientExposedMethodsFolder.Name = "ClientExposedMethods"
		clientExposedMethodsFolder.Parent = serviceRemotesFolder

		local clientExposedRemotePropertiesFolder = Instance.new("Folder")
		clientExposedRemotePropertiesFolder.Name = "ClientExposedRemoteProperties"
		clientExposedRemotePropertiesFolder.Parent = serviceRemotesFolder

		local clientExposedRemoteSignalsFolder = Instance.new("Folder")
		clientExposedRemoteSignalsFolder.Name = "ClientExposedRemoteSignals"
		clientExposedRemoteSignalsFolder.Parent = serviceRemotesFolder

		local clientExposedMembersFolder = Instance.new("Folder")
		clientExposedMembersFolder.Name = "ClientExposedMembers"
		clientExposedMembersFolder.Parent = serviceRemotesFolder

		local requiredService = require(service)

		if typeof(requiredService.Client) ~= "table" then
			return
		end

		for key, value in pairs(requiredService.Client) do
			if typeof(value) == "function" then
				Server._bindRemoteFunctionToClientExposedMethod(requiredService.Client, key, clientExposedMethodsFolder)
			elseif RemoteSignal.IsRemoteSignal(value) then
				Server._bindRemoteFunctionToClientExposedRemoteSignal(
					requiredService.Client,
					key,
					clientExposedRemoteSignalsFolder
				)
			elseif RemoteProperty.IsRemoteProperty(value) then
				Server._bindRemoteFunctionToClientExposedRemoteProperty(
					requiredService.Client,
					key,
					clientExposedRemotePropertiesFolder
				)
			elseif Signal.IsSignal(value) then
				warn(
					("%s Service [%s] attempted to expose a signal to the client which isn't possible!"):format(
						SharedConstants.Comet,
						service.Name
					)
				)
			else
				Server._bindRemoteFunctionToClientExposedMember(requiredService.Client, key, clientExposedMembersFolder)
			end
		end
	end

	local promises = {}
	local clientExposedServicesFolder = Instance.new("Folder")
	clientExposedServicesFolder.Name = "ClientExposedServices"
	Server._clientExposedServicesFolder = clientExposedServicesFolder

	-- Init all services:
	if folder then
		for _, service in ipairs(folder:GetChildren()) do
			if not service:IsA("ModuleScript") then
				if service:IsA("Folder") then
					Server._initServices(service)
				end

				continue
			end

			local requiredService = require(service)
			SetupServiceClientExposedStuff(service, clientExposedServicesFolder)
			requiredService.Comet = Server

			if typeof(requiredService.Init) == "function" then
				table.insert(
					promises,
					Promise.async(function(resolve)
						requiredService.Init()
						resolve()
					end)
				)
			end
		end
	end

	return promises
end

function Server._bindRemoteFunctionToClientExposedMethod(clientTable, methodName, parent)
	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = methodName
	remoteFunction.OnServerInvoke = function(...)
		return clientTable[methodName](...)
	end

	remoteFunction.Parent = parent
end

function Server._bindRemoteFunctionToClientExposedMember(clientTable, member, parent)
	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = member
	remoteFunction.OnServerInvoke = function()
		return clientTable[member]
	end

	remoteFunction.Parent = parent
end

function Server._bindRemoteFunctionToClientExposedRemoteSignal(clientTable, remoteSignalName, parent)
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = remoteSignalName
	remoteEvent.Parent = parent

	local remoteSignal = clientTable[remoteSignalName]
	remoteSignal:Init(remoteEvent)
end

function Server._bindRemoteFunctionToClientExposedRemoteProperty(clientTable, remotePropertyName, parent)
	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = remotePropertyName
	remoteFunction.Parent = parent

	local remoteProperty = clientTable[remotePropertyName]
	remoteProperty:InitRemoteFunction(remoteFunction)
end

return Server
