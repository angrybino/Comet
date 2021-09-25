-- SilentsReplacement
-- ClientRemoteProperty
-- September 23, 2021

--[[
    ClientRemoteProperty.IsClientRemoteProperty(self : any) --> boolean [IsClientRemoteProperty]
	ClientRemoteProperty.new(value : any) --> ClientRemoteProperty [] 

	 -- Only when accessed from a object returned by ClientRemoteProperty.new():
	 
    ClientRemoteProperty.OnValueUpdate : Signal (newValue : any)

	ClientRemoteProperty:IsDestroyed() --> boolean [IsDestroyed]
    ClientRemoteProperty:Destroy() --> void []
    ClientRemoteProperty:Set() --> void []
    ClientRemoteProperty:Get() --> any [value]
]]

local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty

local RunService = game:GetService("RunService")

local comet = script:FindFirstAncestor("Comet")
local Signal = require(comet.Util.Signal)

local LocalConstants = {
	ErrorMessages = {
		Destroyed = "ClientRemoteProperty object is destroyed",
	},
}

function ClientRemoteProperty.IsClientRemoteProperty(self)
	return getmetatable(self) == ClientRemoteProperty
end

function ClientRemoteProperty.new(currentValue)
	assert(RunService:IsClient(), "ClientRemoteProperty can only be created on the client")

	return setmetatable({
		OnValueUpdate = Signal.new(),
		_currentValue = currentValue,
		_callBacks = {},
		_isDestroyed = false,
	}, ClientRemoteProperty)
end

function ClientRemoteProperty:InitRemoteFunction(remoteFunction)
	self._remoteFunction = remoteFunction
	function self._remoteFunction.OnClientInvoke(newValue)
		self.OnValueUpdate:Fire(newValue)
	end
end

function ClientRemoteProperty:Destroy()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self.OnValueUpdate:Destroy()

	if self._remoteFunction then
		self._remoteFunction:Destroy()
	end

	self._isDestroyed = true
end

function ClientRemoteProperty:Set(newValue)
	assert(
		not self._remoteFunction,
		"Can't call ClientRemoteProperty:Set() on client as the current remote property is bound by the Server"
	)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	if self._currentValue ~= newValue then
		self._currentValue = newValue
		self.OnValueUpdate:Fire(newValue)
	end
end

function ClientRemoteProperty:Get()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	if self._remoteFunction then
		return self._remoteFunction:InvokeServer()
	else
		return self._currentValue
	end
end

function ClientRemoteProperty:IsDestroyed()
	return self._isDestroyed
end

return ClientRemoteProperty
