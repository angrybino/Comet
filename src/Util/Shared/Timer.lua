-- angrybino
-- Timer
-- September 26, 2021

--[[
	-- Static methods:

    Timer.new(timer : number, customUpdateSignal : RBXScriptSignal ?) --> Timer []
    Timer.IsTimer(self : any) --> boolean [IsTimer]

   	-- Instance members:

	Timer.OnTick : Signal (deltaTime : number)

	-- Instance methods:

    Timer:Start() --> void []
    Timer:Stop() --> void []
	Timer:Destroy() --> void []
	Timer:IsDestroyed() --> boolean [IsDestroyed]
    Timer:IsPaused() --> boolean [IsPaused]
	Timer:IsStopped() --> boolean [IsStopped]
    Timer:Pause() --> void []
]]

local Timer = {}
Timer.__index = Timer

local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)
local comet = script:FindFirstAncestor("Comet")
local SharedConstants = require(comet.SharedConstants)

local LocalConstants = {
	ErrorMessages = {
		Destroyed = "Timer object is destroyed",
	},

	DefaultUpdateSignal = RunService.Heartbeat,
}

function Timer.IsTimer(self)
	return getmetatable(self) == Timer
end

function Timer.new(timer, customUpdateSignal)
	assert(
		typeof(timer) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Timer.new()", "number", typeof(timer))
	)

	if customUpdateSignal then
		assert(
			typeof(customUpdateSignal) == "RBXScriptSignal",
			SharedConstants.ErrorMessages.InvalidArgument:format(
				2,
				"Timer.new()",
				"RBXScriptSignal or nil",
				typeof(timer)
			)
		)
	end

	local self = setmetatable({
		OnTick = Signal.new(),
		_customUpdateSignal = customUpdateSignal or LocalConstants.DefaultUpdateSignal,
		_maid = Maid.new(),
		_timerUpdateMaid = Maid.new(),
		_timer = timer,
		_isPaused = false,
		_isDestroyed = false,
		_isStopped = false,
		_currentTimerTickDeltaTime = 0,
	}, Timer)

	self._maid:AddTask(self.OnTick)
	self._maid:AddTask(function()
		self:Stop()
		self._isDestroyed = true
	end)
	self._maid:AddTask(self._timerUpdateMaid)
	self._timerUpdateMaid:AddTask(function()
		self._isPaused = false
		self._isStopped = true
	end)

	return self
end

function Timer:Start()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._isStopped = false
	self._timerUpdateMaid:AddTask(self._customUpdateSignal:Connect(function(deltaTime)
		if self._isPaused then
			return
		end

		if self._currentTimerTickDeltaTime >= self._timer then
			self.OnTick:Fire(self._currentTimerTickDeltaTime)
			self._currentTimerTickDeltaTime = 0
		end

		self._currentTimerTickDeltaTime += deltaTime
	end))
end

function Timer:IsStopped()
	return self._isStopped
end

function Timer:Pause()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._isPaused = true
end

function Timer:Unpause()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._isPaused = false
end

function Timer:IsPaused()
	return self._isPaused
end

function Timer:IsDestroyed()
	return self._isDestroyed
end

function Timer:Destroy()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._maid:Destroy()
end

function Timer:Stop()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._timerUpdateMaid:Cleanup()
end

return Timer
