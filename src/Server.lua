-- angrybino
-- Server
-- September 26, 2021

--[[
	Server.Util : Folder
	Server.Services : table
	Server.Version : string

	Server.SetServicesFolder(servicesFolder : Folder) --> void []
	Server.GetService(serviceName : string) --> table [Service]
	Server.Start() --> Promise []
]]

local Server = {
	Util = script.Parent.Util,
	Services = {},

	_clientExposedServicesFolder = Instance.new("Folder"),
	_isStarted = false,
}

local Promise = require(Server.Util.Shared.Promise)
local RemoteSignal = require(Server.Util.Shared.Remote.RemoteSignal)
local SharedConstants = require(script.Parent.SharedConstants)
local Signal = require(Server.Util.Shared.Signal)
local RemoteProperty = require(Server.Util.Shared.Remote.RemoteProperty)

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

	local serviceNames = {}

	local function AddServices(folder)
		for _, service in ipairs(folder:GetChildren()) do
			if not service:IsA("ModuleScript") then
				if service:IsA("Folder") then
					AddServices(service)
				end

				continue
			end

			if serviceNames[service.Name] then
				warn(
					("%s Service with duplicate name [%s] found in: %s"):format(
						SharedConstants.Comet,
						service.Name,
						service:GetFullName()
					)
				)
			end

			local requiredService = require(service)
			serviceNames[service.Name] = true
			Server.Services[service.Name] = requiredService
		end
	end

	AddServices(servicesFolder)
end

function Server.Start()
	if Server._isStarted then
		return Promise.reject(("%s Can't start Comet as it is already started"):format(SharedConstants.Comet))
	end

	Server._isStarted = true

	return Promise.async(function(resolve)
		local promises = Server._initServices()
		resolve(Promise.All(promises))
	end):andThen(function()
		-- Start all services now as we know it is safe:
		Server._startServices()
		Server._clientExposedServicesFolder.Name = "ClientExposedServices"
		Server._clientExposedServicesFolder.Parent = script.Parent.Client
	end)
end

function Server.GetService(serviceName)
	assert(
		typeof(serviceName) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Comet.GetService()", "string", typeof(serviceName))
	)

	local service = Server.Services[serviceName]
	assert(service, ("Service [%s] not found!"):format(serviceName))

	return service
end

function Server._startServices()
	-- Start all services:
	for _, requiredService in pairs(Server.Services) do
		if typeof(requiredService.Start) == "function" then
			task.spawn(requiredService.Start)
		end
	end
end

function Server._initServices()
	local function SetupServiceClientExposedStuff(requiredService, serviceName)
		local serviceRemotesFolder = Instance.new("Folder")
		serviceRemotesFolder.Name = serviceName
		serviceRemotesFolder.Parent = Server._clientExposedServicesFolder

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

		if typeof(requiredService.Client) ~= "table" then
			return
		end

		local function BindClientExposedValue(requiredService, key)
			local value = requiredService.Client[key]

			if typeof(value) == "function" then
				Server._bindRemoteFunctionToClientExposedMethod(requiredService.Client, key, clientExposedMethodsFolder)
			elseif RemoteSignal.IsRemoteSignal(value) then
				Server._bindRemoteEventToClientExposedRemoteSignal(
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
					("%s Service [%s] attempted to expose a signal to the client rather than a RemoteSignal"):format(
						SharedConstants.Comet,
						serviceName
					)
				)
			else
				Server._bindRemoteFunctionToClientExposedMember(requiredService.Client, key, clientExposedMembersFolder)
			end
		end

		setmetatable(requiredService.Client, {
			__newindex = function(self, key, value)
				rawset(self, key, value)
				BindClientExposedValue(requiredService, key)
			end,
		})

		for key, _ in pairs(requiredService.Client) do
			BindClientExposedValue(requiredService, key)
		end
	end

	local promises = {}

	-- Init all services:
	for serviceName, requiredService in pairs(Server.Services) do
		SetupServiceClientExposedStuff(requiredService, serviceName)
		requiredService.Comet = Server

		if typeof(requiredService.Init) == "function" then
			-- We want to make sure to capture any errors during the initialization of the service:
			table.insert(
				promises,
				Promise.async(function(resolve)
					requiredService.Init()
					resolve()
				end)
			)
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

function Server._bindRemoteEventToClientExposedRemoteSignal(clientTable, remoteSignalName, parent)
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = remoteSignalName
	remoteEvent.Parent = parent

	local remoteSignal = clientTable[remoteSignalName]
	remoteSignal:SetRemoteEvent(remoteEvent)
end

function Server._bindRemoteFunctionToClientExposedRemoteProperty(clientTable, remotePropertyName, parent)
	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = remotePropertyName
	remoteFunction.Parent = parent

	local remoteProperty = clientTable[remotePropertyName]
	remoteProperty:InitRemoteFunction(remoteFunction)
end

return Server
