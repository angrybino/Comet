-- angrybino
-- Client
-- September 26, 2021

--[[
	Client.Util : Folder
	Client.Controllers : table
	Client.Version : string

	Client.OnStart : Signal ()
	
	Client.SetControllersFolder(controllersFolder : Folder) --> void []
	Client.Start() --> Promise []
	Client.GetService(service : string) --> table [Service]
	Client.GetController(controllerName : string) --> table [Controller]
]]

local Client = {
	Util = script.Parent.Util,
	Controllers = {},

	_servicesBuilt = {},
	_isStarted = false,
}

local Players = game:GetService("Players")

local Promise = require(Client.Util.Shared.Promise)
local ClientRemoteSignal = require(Client.Util.Shared.Remote.ClientRemoteSignal)
local ClientRemoteProperty = require(Client.Util.Shared.Remote.ClientRemoteProperty)
local SharedConstants = require(script.Parent.SharedConstants)
local SafeWaitUtil = require(Client.Util.Shared.SafeWaitUtil)
local Signal = require(Client.Util.Shared.Signal)
local DebugLog = require(script.Parent.DebugLog)

local LocalConstants = {
	MaxYieldIntervalForServicesToLoad = 5,
	MaxYieldIntervalForCometToLoadServerside = 5,
}

local servicesFolder = script.ExposedServices
local server = script.Parent.Server

do
	local function WaitAndThenRegisterForPossibleInfiniteYield(timeout, message, yieldData)
		task.delay(timeout, function()
			if yieldData.YieldFinished then
				return
			end

			DebugLog(message)
		end)
	end

	local isCometStarted = server:GetAttribute("IsStarted")
	local areServicesLoaded = servicesFolder:GetAttribute("IsLoaded")

	if not isCometStarted then
		local signal = Signal.new()

		local attributeChangedConnection
		attributeChangedConnection = servicesFolder:GetAttributeChangedSignal("IsLoaded"):Connect(function()
			if not attributeChangedConnection.Connected then
				return
			end

			signal:Fire()
			attributeChangedConnection:Disconnect()
		end)

		local cometServersideStartYieldData = { YieldFinished = false }
		WaitAndThenRegisterForPossibleInfiniteYield(
			LocalConstants.MaxYieldIntervalForCometToLoadServerside,
			"Possible infinite yield on waiting for Comet to start on the server",
			cometServersideStartYieldData
		)

		signal:Wait()
		cometServersideStartYieldData.YieldFinished = true
		areServicesLoaded = servicesFolder:GetAttribute("IsLoaded")
	end

	if not areServicesLoaded then
		local servicesStartYieldData = { YieldFinished = false }

		WaitAndThenRegisterForPossibleInfiniteYield(
			LocalConstants.MaxYieldIntervalForCometToLoadServerside,
			"Possible infinite yield on waiting for services to load",
			servicesStartYieldData
		)

		servicesFolder:GetAttributeChangedSignal("IsLoaded"):Wait()
		servicesStartYieldData.YieldFinished = true
	end
end

Client.Version = SharedConstants.Version
Client.LocalPlayer = Players.LocalPlayer
Client.OnStart = Signal.new()

function Client.GetService(serviceName)
	assert(
		typeof(serviceName) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Client.GetService()", "string", typeof(serviceName))
	)

	assert(servicesFolder:FindFirstChild(serviceName), ("Service [%s] not found!"):format(serviceName))
	local onServiceBuilt = Client._servicesBuilt[serviceName]

	-- Prevent multiple service builds:
	if Signal.IsSignal(onServiceBuilt) then
		onServiceBuilt:Wait()
	end

	return Client._servicesBuilt[serviceName] or Client._buildService(serviceName)
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

	local controller = Client.Controllers[controllerName]
	assert(controller, ("Controller [%s] not found!"):format(controllerName))

	return controller
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

	local controllerNames = {}

	local function AddControllers(folder)
		for _, controller in ipairs(folder:GetChildren()) do
			if not controller:IsA("ModuleScript") then
				if controller:IsA("Folder") then
					AddControllers(controller)
				end

				continue
			end

			if controllerNames[controller.Name] then
				DebugLog(
					("%s Controller with duplicate name [%s] found in: %s"):format(
						SharedConstants.Comet,
						controller.Name,
						controller:GetFullName()
					)
				)
			end

			local requiredController = require(controller)
			controllerNames[controller.Name] = true
			Client.Controllers[controller.Name] = requiredController
		end
	end

	AddControllers(controllersFolder)
end

function Client.Start()
	if Client._isStarted then
		return Promise.reject("Can't start Comet as it is already started")
	end

	Client._isStarted = true

	return Promise.async(function(resolve)
		local promises = Client._initControllers()
		resolve(Promise.All(promises))
	end):andThen(function()
		-- Start all controllers now as we know it is safe:
		Client._startControllers()
		Client.OnStart:Fire()
	end)
end

function Client._startControllers()
	for _, requiredController in pairs(Client.Controllers) do
		if typeof(requiredController.Start) == "function" then
			task.spawn(requiredController.Start)
		end
	end
end

function Client._initControllers()
	local promises = {}

	for _, requiredController in pairs(Client.Controllers) do
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
	end

	return promises
end

function Client._buildService(serviceName)
	local onServiceBuilt = Signal.new()
	Client._servicesBuilt[serviceName] = onServiceBuilt

	local service = servicesFolder[serviceName]

	local clientExposedMethods = service.ClientExposedMethods
	local clientExposedRemoteSignals = service.ClientExposedRemoteSignals
	local clientExposedRemoteProperties = service.ClientExposedRemoteProperties
	local clientExposedMembers = service.ClientExposedMembers
	local builtService = {}

	local function ExposeMethodToClient(method)
		builtService[method.Name] = function(...)
			return method:InvokeServer(...)
		end
	end

	local function ExposeMemberToClient(member)
		builtService[member.Name] = member:InvokeServer()
	end

	local function ExposeRemoteSignalToClient(remoteSignal)
		builtService[remoteSignal.Name] = ClientRemoteSignal.new()
		builtService[remoteSignal.Name]:InitRemoteEvent(remoteSignal)
	end

	local function ExposeRemotePropertyToClient(remoteProperty)
		builtService[remoteProperty.Name] = ClientRemoteProperty.new()
		builtService[remoteProperty.Name]:InitRemoteFunction(remoteProperty)
	end

	-- Expose methods to the client:
	for _, method in ipairs(clientExposedMethods:GetChildren()) do
		ExposeMethodToClient(method)
	end

	-- Expose members to the client:
	for _, member in ipairs(clientExposedMembers:GetChildren()) do
		ExposeMemberToClient(member)
	end

	-- Expose remote signals to the client:
	for _, remoteSignal in ipairs(clientExposedRemoteSignals:GetChildren()) do
		ExposeRemoteSignalToClient(remoteSignal)
	end

	-- Expose remote properties to the client:
	for _, remoteProperty in ipairs(clientExposedRemoteProperties:GetChildren()) do
		ExposeRemotePropertyToClient(remoteProperty)
	end

	clientExposedMethods.ChildAdded:Connect(ExposeMethodToClient)
	clientExposedMembers.ChildAdded:Connect(ExposeMemberToClient)
	clientExposedRemoteSignals.ChildAdded:Connect(ExposeRemoteSignalToClient)
	clientExposedRemoteProperties.ChildAdded:Connect(ExposeRemotePropertyToClient)

	Client._servicesBuilt[serviceName] = builtService
	onServiceBuilt:Fire()
	onServiceBuilt:Destroy()

	return builtService
end

return Client
