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
    Timer:IsPaused() --> boolean [IsPaused]
	Timer:Reset() --> void []
    Timer:Pause() --> void []
	Timer:Destroy() --> void []
]]

local Timer = {}
Timer.__index = Timer

local RunService = game:GetService("RunService")

local Signal = require(script.Signal)
local Maid = require(script.Maid)

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},

	DefaultUpdateSignal = RunService.Heartbeat,
}

function Timer.IsTimer(self)
	return getmetatable(self) == Timer
end

function Timer.new(timer, customUpdateSignal)
	assert(
		typeof(timer) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "Timer.new()", "number", typeof(timer))
	)

	if customUpdateSignal then
		assert(
			typeof(customUpdateSignal) == "RBXScriptSignal",
			LocalConstants.ErrorMessages.InvalidArgument:format(
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
		_isStopped = false,
		_currentTimerTickDeltaTime = 0,
	}, Timer)

	self._maid:AddTask(self.OnTick)
	self._maid:AddTask(function()
		self:Stop()
	end)
	self._timerUpdateMaid:AddTask(function()
		self._isPaused = false
		self._isStopped = true
	end)

	return self
end

function Timer:Reset()
	self._currentTimerTickDeltaTime = 0
end

function Timer:Start()
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
	self._isStopped = false
	self._isPaused = true
end

function Timer:Unpause()
	self._isPaused = false
end

function Timer:IsPaused()
	return self._isPaused
end

function Timer:Destroy()
	self._maid:Destroy()
end

function Timer:Stop()
	self._timerUpdateMaid:Destroy()
end

return Timer
