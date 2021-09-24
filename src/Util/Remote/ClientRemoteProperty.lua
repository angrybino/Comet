-- SilentsReplacement
-- ClientRemoteProperty
-- September 23, 2021

--[[
    ClientRemoteProperty.IsClientRemoteProperty(self : any) --> boolean [IsClientRemoteProperty]
	ClientRemoteProperty.new(value : any) --> ClientRemoteProperty [] 

	 -- Only when accessed from a object returned by ClientRemoteProperty.new():
	 
    ClientRemoteProperty.OnUpdate : Signal (newValue : any)
    ClientRemoteProperty:Destroy() --> void []
    RemoteProperty:Set() --> void []
    RemoteProperty:Get() --> any [value]
]]

local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty

local RunService = game:GetService("RunService")

local comet = script:FindFirstAncestor("Comet")
local Signal = require(comet.Util.Signal)

function ClientRemoteProperty.IsClientRemoteProperty(self)
	return getmetatable(self) == ClientRemoteProperty
end

function ClientRemoteProperty.new(currentValue)
	assert(RunService:IsClient(), "ClientRemoteProperty can only be created on the client")

	return setmetatable({
		OnUpdate = Signal.new(),
		_currentValue = currentValue,

		_callBacks = {},
	}, ClientRemoteProperty)
end

function ClientRemoteProperty:InitRemoteFunction(remoteFunction)
	self._remoteFunction = remoteFunction
	self._remoteFunction.OnClientInvoke = function(newValue)
		self.OnUpdate:Fire(newValue)
	end
end

function ClientRemoteProperty:Destroy()
	self.OnUpdate:Destroy()

	if self._remoteFunction then
		return
	end

	self._remoteFunction:Destroy()
end

function ClientRemoteProperty:Set(newValue)
	assert(
		not self._remoteFunction,
		"Can't call ClientRemoteProperty:Set() on client as ClientRemoteProperty is bound by the Server"
	)

	if self._currentValue ~= newValue then
		self._currentValue = newValue
		self.OnUpdate:Fire(newValue)
	end
end

function ClientRemoteProperty:Get()
	if self._remoteFunction then
		return self._remoteFunction:InvokeServer()
	else
		return self._currentValue
	end
end

return ClientRemoteProperty
