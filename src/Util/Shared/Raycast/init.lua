-- angrybino
-- Raycast
-- September 26, 2021

--[[
	-- Static methods:

    Raycast.new(origin : Vector3, direction : Vector3, params : RaycastParams ?) --> Raycast []
	Raycast.IsRaycast(self : any) --> boolean [IsRayCast]

    -- Instance members:

    Raycast.OnInstanceHit : Signal (instance : Instance)
	Raycast.Origin : Vector3
	Raycast.Unit : Vector3 
	Raycast.Direction : Vector3
	Raycast.Size : number
	Raycast.Visualizer : Part
	Raycast.Results : table [RaycastResults]

	-- Instance methods:

	Raycast:Reverse() --> void []
    Raycast:Visualize() --> void []
	Raycast:Unvisualize() --> void []
	Raycast:SetVisualizerThickness(thickness : number) --> void []
    Raycast:GetTouchingParts(maxTouchingParts : number ?) --> table [TouchingParts]
    Raycast:Resize(size : number ?) --> void []
    Raycast:Destroy() --> void []
]]

local Raycast = {}
Raycast.__index = Raycast

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Signal = require(script.Signal)
local Maid = require(script.Maid)

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},

	Surfaces = {
		TopSurface = Vector3.new(0, 1, 0),
		BottomSurface = Vector3.new(0, -1, 0),
		FrontSurface = Vector3.new(0, 0, -1),
		RightSurface = Vector3.new(1, 0, 0),
		LeftSurface = Vector3.new(-1, 0, 0),
		BackSurface = Vector3.new(0, 0, 1),
	},

	DefaultRayVisualizerBrickColor = BrickColor.White(),
	DefaultMaxTouchingParts = 10,
	DefaultRayVisualizerThickness = 0.5,
}

function Raycast.IsRaycast(self)
	return getmetatable(self) == Raycast
end

function Raycast.new(origin, direction, params)
	assert(
		typeof(origin) == "Vector3",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "Raycast.new()", "Vector3", typeof(origin))
	)
	assert(
		typeof(origin) == "Vector3",
		LocalConstants.ErrorMessages.InvalidArgument:format(2, "Raycast.new()", "Vector3", typeof(direction))
	)

	if params then
		assert(
			typeof(params) == "RaycastParams",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				3,
				"Raycast.new()",
				"RaycastParams or nil",
				typeof(params)
			)
		)
	end

	local self = setmetatable({
		Origin = origin,
		Direction = direction,
		Unit = direction.Unit,
		Results = {},
		Visualizer = Instance.new("Part"),
		OnInstanceHit = Signal.new(),
		_maid = Maid.new(),
		_params = params,
	}, Raycast)

	self._maid:AddTask(self.Visualizer)
	self._maid:AddTask(self.OnInstanceHit)
	self:_init()

	return self
end

function Raycast:Reverse()
	self.Direction = -self.Direction
	self.Unit = self.Direction.Unit
	self.Origin += -self.Direction

	self:_updateResults()
	self:_updateVisualizerPosition()
end

function Raycast:Visualize()
	self.Visualizer.Transparency = 0
end

function Raycast:SetVisualizerThickness(thickness)
	assert(
		typeof(thickness) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(
			1,
			"Raycast:SetVisualizerThickness()",
			"number",
			typeof(thickness)
		)
	)

	self:_updateVisualizerThickness(thickness)
end

function Raycast:Unvisualize()
	self.Visualizer.Transparency = 1
end

function Raycast:GetTouchingParts(maxTouchingParts)
	if maxTouchingParts then
		assert(
			typeof(maxTouchingParts) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				1,
				"RayCast:GetTouchingParts()",
				"number or nil",
				typeof(maxTouchingParts)
			)
		)
	end

	maxTouchingParts = maxTouchingParts or LocalConstants.DefaultMaxTouchingParts

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {}

	if self._params then
		params.FilterDescendantsInstances = self._params.FilterDescendantsInstances
	end

	local capturedInstances = { self.Visualizer }
	local touchingInstances = {}

	-- Keep on adding all the touching parts to the table unless there are none:
	while #capturedInstances < maxTouchingParts do
		params.FilterDescendantsInstances = capturedInstances
		local ray = Workspace:Raycast(self.Origin, self.Direction, params)

		if not ray then
			break
		end

		table.insert(capturedInstances, ray.Instance)
		touchingInstances[ray.Instance] = Raycast._getRayHitSurface(ray)

		RunService.Heartbeat:Wait()
	end

	return touchingInstances
end

function Raycast:Resize(size)
	assert(
		typeof(size) == "number",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "Raycast:Resize()", "number", typeof(size))
	)

	local finalPosition = (self.Origin + self.Direction)

	self.Direction = self.Direction.Unit * size
	self.Unit = self.Direction.Unit
	self.Size = (self.Origin - finalPosition).Magnitude

	self:_updateResults()
	self:_updateVisualizerSize(size)
	self:_updateVisualizerPosition()
end

function Raycast:Destroy()
	self._maid:Destroy()

	for key, _ in pairs(self) do
		self[key] = nil
	end

	setmetatable(self, nil)
end

function Raycast:_updateResults()
	local ray = Workspace:Raycast(self.Origin, self.Direction, self._params)

	if not ray then
		return
	end

	self.Results.Instance = ray.Instance
	self.Results.Position = ray.Position
	self.Results.Normal = ray.Normal
	self.Results.Material = ray.Material
end

function Raycast:_init()
	self:_updateResults()
	self:_setupRayVisualizer()
	self.Size = self.Visualizer.Size.Magnitude

	self._maid:AddTask(RunService.Heartbeat:Connect(function()
		local ray = Workspace:Raycast(self.Origin, self.Direction, self._params)

		if ray then
			self.OnInstanceHit:Fire(ray.Instance, Raycast._getRayHitSurface(ray))
		end
	end))
end

function Raycast:_updateVisualizerThickness(thickness)
	local visualizer = self.Visualizer

	visualizer.Size = Vector3.new(thickness, thickness, visualizer.Size.Z)
end

function Raycast:_updateVisualizerPosition()
	local finalPosition = (self.Origin + self.Direction)
	local visualizer = self.Visualizer

	visualizer.CFrame = CFrame.lookAt(self.Origin, finalPosition) * CFrame.new(0, 0, -visualizer.Size.Magnitude / 2)
end

function Raycast:_updateVisualizerSize(size)
	local visualizer = self.Visualizer

	visualizer.Size = Vector3.new(visualizer.Size.X, visualizer.Size.Y, size)
end

function Raycast:_setupRayVisualizer()
	local origin = self.Origin
	local direction = self.Direction
	local visualizer = self.Visualizer

	local finalPosition = (origin + direction)
	local distance = (origin - finalPosition).Magnitude

	visualizer.Anchored = true
	visualizer.CanCollide = false
	visualizer.CanQuery = false
	visualizer.Transparency = 1
	self:SetVisualizerThickness(LocalConstants.DefaultRayVisualizerThickness)
	self:_updateVisualizerSize(distance)
	self:_updateVisualizerPosition()
	visualizer.CanCollide = false
	visualizer.Locked = true
	visualizer.Material = Enum.Material.Neon
	visualizer.Parent = Workspace
end

function Raycast._getRayHitSurface(ray)
	if not ray or not ray.Instance then
		return
	end

	local normal = ray.Instance.CFrame:VectorToObjectSpace(ray.Normal)
	local dotProducts = {}

	for surface, normalId in pairs(LocalConstants.Surfaces) do
		dotProducts[surface] = normal:Dot(normalId)
	end

	local highestDotProduct = 0
	local raySurface

	for surface, product in pairs(dotProducts) do
		if product > highestDotProduct then
			highestDotProduct = product
			raySurface = surface
		end
	end

	return raySurface
end

return Raycast
