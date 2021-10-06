-- angrybino
-- ClientRemoteProperty
-- September 26, 2021

--[[
	-- Static methods:

    ClientRemoteProperty.IsClientRemoteProperty(self : any) --> boolean [IsClientRemoteProperty]
	ClientRemoteProperty.new(value : any) --> ClientRemoteProperty [] 

	-- Instance members:
	 
    ClientRemoteProperty.OnValueUpdate : Signal (newValue : any)

	-- Instance methods:

	ClientRemoteProperty:IsDestroyed() --> boolean [IsDestroyed]
    ClientRemoteProperty:Destroy() --> void []
    ClientRemoteProperty:SetValue() --> void []
    ClientRemoteProperty:GetValue() --> any [value]
]]

local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty

local RunService = game:GetService("RunService")

local comet = script:FindFirstAncestor("Comet")
local Signal = require(comet.Util.Shared.Signal)
local Maid = require(comet.Util.Shared.Maid)

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

	local self = setmetatable({
		OnValueUpdate = Signal.new(),
		_maid = Maid.new(),
		_currentValue = currentValue,
		_isDestroyed = false,
	}, ClientRemoteProperty)

	self._maid:AddTask(self.OnValueUpdate)

	return self
end

function ClientRemoteProperty:InitRemoteFunction(remoteFunction)
	self._remoteFunction = remoteFunction

	self._maid:AddTask(remoteFunction)
	self._maid:AddTask(function()
		remoteFunction.OnClientInvoke = nil
		self._isDestroyed = true
	end)

	function remoteFunction.OnClientInvoke(newValue)
		self.OnValueUpdate:Fire(newValue)
	end
end

function ClientRemoteProperty:Destroy()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._maid:Destroy()
end

function ClientRemoteProperty:SetValue(newValue)
	assert(
		not self._remoteFunction,
		"Can't call ClientRemoteProperty:SetValue() on client as the current remote property is bound by the Server"
	)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	if self._currentValue ~= newValue then
		self._currentValue = newValue
		self.OnValueUpdate:Fire(newValue)
	end
end

function ClientRemoteProperty:GetValue()
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
