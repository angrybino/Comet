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

local LocalConstants = {
	DefaultUpdateSignal = RunService.Heartbeat,

	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
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

	return setmetatable({
		OnTick = Signal.new(),
		_customUpdateSignal = customUpdateSignal or LocalConstants.DefaultUpdateSignal,
		_timer = timer,
		_isPaused = false,
		_isStopped = true,
		_currentTimerTickDeltaTime = 0,
	}, Timer)
end

function Timer:Reset()
	self._currentTimerTickDeltaTime = 0
end

function Timer:Start()
	assert(self:IsStopped(), "Timer is already started")

	self._isStopped = false

	self._customUpdateSignalConnection = self._customUpdateSignal:Connect(function(deltaTime)
		if self._isPaused then
			return
		end

		if self._currentTimerTickDeltaTime >= self._timer then
			self.OnTick:Fire(self._currentTimerTickDeltaTime)
			self._currentTimerTickDeltaTime = 0
		end

		self._currentTimerTickDeltaTime += deltaTime
	end)
end

function Timer:IsStopped()
	return self._isStopped
end

function Timer:Pause()
	self._isPaused = true
end

function Timer:Unpause()
	self._isPaused = false
end

function Timer:IsPaused()
	return self._isPaused
end

function Timer:Destroy()
	self:Stop()
	self.OnTick:Destroy()

	for key, _ in pairs(self) do
		self[key] = nil
	end

	setmetatable(self, nil)
end

function Timer:Stop()
	self._isStopped = true

	if self._customUpdateSignalConnection then
		self._customUpdateSignalConnection:Disconnect()
		self._customUpdateSignalConnection = nil
	end
end

return Timer
