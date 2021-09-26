-- angrybino
-- Raycast
-- September 26, 2021

--[[
    Raycast.new(origin : Vector3, direction : Vector3, params : RaycastParams ?) --> Raycast []

    -- Only accessible from an object returned by Raycast.new():

    Raycast.OnInstanceHit : Signal (instance : Instance)

	Raycast:IsDestroyed() --> boolean [IsDestroyed]
    Raycast:Visualize(color : BrickColor3) --> void []
    Raycast:GetTouchingParts(maxTouchingParts : number ?) --> table [TouchingParts]
    Raycast:Resize(size : number ?) --> void []
    Raycast:Destroy() --> void []
]]

local Raycast = {}
Raycast.__index = Raycast

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
		Destroyed = "Ray object is destroyed",
	},

	Surfaces = {
		TopSurface = Vector3.new(0, 1, 0),
		BottomSurface = Vector3.new(0, -1, 0),
		FrontSurface = Vector3.new(0, 0, -1),
		RightSurface = Vector3.new(1, 0, 0),
		LeftSurface = Vector3.new(-1, 0, 0),
		BackSurface = Vector3.new(0, 0, 1),
	},

	DefaultBrickColor = BrickColor.White(),
	DefaultMaxTouchingParts = 10,
	DefaultRaySize = 1,
	RayVisualizerThickness = 0.5,
}

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
		OnInstanceHit = Signal.new(),
		Visualizer = Instance.new("Part"),
		_maid = Maid.new(),
		_params = params,
		_isRayVisualized = false,
	}, Raycast)

	self._maid:AddTask(self.Visualizer)
	self._maid:AddTask(self.OnInstanceHit)
	self.Size = (origin - (origin + direction)).Magnitude
	self:_init()

	return self
end

function Raycast:Visualize(color)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	if color then
		assert(
			typeof(color) == "BrickColor",
			LocalConstants.ErrorMessages.InvalidArgument:format(1, "Raycast:Visualize()", "Color", typeof(color))
		)
	end

	assert(not self._isRayVisualized, "Ray is already being visualized")

	color = color or LocalConstants.DefaultBrickColor
	self:_setupRayVisualizer(color)
	self._isRayVisualized = true
end

function Raycast:GetTouchingParts(maxTouchingParts)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

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
	params.FilterDescendantsInstances = self._params and self._params.FilterDescendantsInstances

	local capturedInstances = {}
	local touchingInstances = {}

	-- Keep on adding all the touching parts to the table unless there are none:
	while #capturedInstances < maxTouchingParts do
		local ray = Workspace:Raycast(self.Origin, self.Direction, params)

		if not ray then
			break
		end

		local instance = ray.Instance

		table.insert(capturedInstances, ray.Instance)
		touchingInstances[ray.Instance] = Raycast._getRayHitSurface(ray)
		params.FilterDescendantsInstances = capturedInstances
		RunService.Heartbeat:Wait()
	end

	return touchingInstances
end

function Raycast:Resize(size)
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	if size then
		assert(
			typeof(size) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(1, "Raycast:Resize()", "number", typeof(size))
		)
	end

	size = size or LocalConstants.DefaultRaySize
	local finalPosition = (self.Origin + self.Direction)

	self.Direction = self.Direction.Unit * size
	self.Size = (self.Origin - finalPosition).Magnitude

	self:_updateVisualizerSize(size)
end

function Raycast:IsDestroyed()
	return self._isDestroyed
end

function Raycast:Destroy()
	assert(not self:IsDestroyed(), LocalConstants.ErrorMessages.Destroyed)

	self._maid:Destroy()
	self._isDestroyed = true
end

function Raycast:_init()
	self._maid:AddTask(RunService.Heartbeat:Connect(function()
		local ray = Workspace:Raycast(self.Origin, self.Direction, self._params)

		if ray then
			self.OnInstanceHit:Fire(ray.Instance, Raycast._getRayHitSurface(ray))
		end
	end))
end

function Raycast:_updateVisualizerSize(size)
	local finalPosition = (self.Origin + self.Direction)
	local visualizer = self.Visualizer

	visualizer.Size = Vector3.new(visualizer.Size.X, visualizer.Size.Y, size)
	visualizer.CFrame = CFrame.lookAt(self.Origin, finalPosition) * CFrame.new(0, 0, -size / 2)
end

function Raycast:_setupRayVisualizer(color)
	local origin = self.Origin
	local direction = self.Direction
	local visualizer = self.Visualizer

	local thickness = LocalConstants.RayVisualizerThickness
	local finalPosition = (origin + direction)
	local distance = (origin - finalPosition).Magnitude

	visualizer.Anchored = true
	visualizer.CanCollide = false
	visualizer.CanQuery = false
	visualizer.Size = Vector3.new(thickness / 2, thickness / 2, distance)
	visualizer.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -distance / 2)
	visualizer.BrickColor = color
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
