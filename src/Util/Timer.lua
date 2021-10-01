-- angrybino
-- Timer
-- September 26, 2021

--[[
	-- Static methods:

    Timer.new(timer : number) --> Timer []
    Timer.IsTimer(self : any) --> boolean [IsTimer]

   	-- Instance members:

	Timer.OnTimerTick : Signal (deltaTime : number)

	-- Instance methods:

    Timer:Start() --> void []
    Timer:Stop() --> void []
	Timer:Destroy() --> void []
	Timer:IsDestroyed() --> boolean [IsDestroyed]
    Timer:IsPaused() --> boolean [IsPaused]
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
}

function Timer.IsTimer(self)
	return getmetatable(self) == Timer
end

function Timer.new(timer)
	assert(
		typeof(timer) == "number",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Timer.new()", "number", typeof(timer))
	)

	local self = setmetatable({
		OnTimerTick = Signal.new(),
		_timer = timer,
		_maid = Maid.new(),
		_isPaused = false,
		_isDestroyed = false,
		_currentTimerTickDeltaTime = 0,
	}, Timer)

	self._maid:AddTask(self.OnTimerTick)
	self._maid:AddTask(function()
		self._currentTimerTickDeltaTime = 0
	end)

	return self
end

function Timer:Start()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._maid:AddTask(RunService.Heartbeat:Connect(function(deltaTime)
		if self._isPaused or self:IsDestroyed() then
			return
		end

		if self._currentTimerTickDeltaTime >= self._timer then
			self.OnTimerTick:Fire(self._currentTimerTickDeltaTime)
			self._currentTimerTickDeltaTime = 0
		end

		self._currentTimerTickDeltaTime += deltaTime
	end))
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

	self._isDestroyed = true
	self._maid:Destroy()
end

function Timer:Stop()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._maid:Cleanup()
end

return Timer
