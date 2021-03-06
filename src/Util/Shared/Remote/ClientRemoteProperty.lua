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

    ClientRemoteProperty:Destroy() --> void []
    ClientRemoteProperty:SetValue() --> void []
    ClientRemoteProperty:GetValue() --> any [value]
]]

local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty

local RunService = game:GetService("RunService")

local shared = script:FindFirstAncestor("Shared")
local Signal = require(shared.Signal)
local Maid = require(shared.Maid)

function ClientRemoteProperty.IsClientRemoteProperty(self)
	return getmetatable(self) == ClientRemoteProperty
end

function ClientRemoteProperty.new(currentValue)
	assert(RunService:IsClient(), "ClientRemoteProperty can only be created on the client")

	local self = setmetatable({
		OnValueUpdate = Signal.new(),
		_maid = Maid.new(),
		_currentValue = currentValue,
	}, ClientRemoteProperty)

	self._maid:AddTask(self.OnValueUpdate)

	return self
end

function ClientRemoteProperty:InitRemoteFunction(remoteFunction)
	self._remoteFunction = remoteFunction
	self._maid:AddTask(remoteFunction)

	function remoteFunction.OnClientInvoke(newValue)
		self.OnValueUpdate:Fire(newValue)
	end
end

function ClientRemoteProperty:Destroy()
	self._maid:Destroy()

	for key, _ in pairs(self) do
		self[key] = nil
	end

	setmetatable(self, nil)
end

function ClientRemoteProperty:SetValue(newValue)
	assert(
		not self._remoteFunction,
		"Can't call ClientRemoteProperty:SetValue() on client as the current remote property is bound by the Server"
	)

	if self._currentValue ~= newValue then
		self._currentValue = newValue
		self.OnValueUpdate:Fire(newValue)
	end
end

function ClientRemoteProperty:GetValue()
	if self._remoteFunction then
		return self._remoteFunction:InvokeServer()
	else
		return self._currentValue
	end
end

return ClientRemoteProperty
