-- angrybino
-- Get
-- October 09, 2021

--[[
    Get(name : string, specifiedFolder : string | Instance) --> ModuleScript []
]]

local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local util = script.Parent.Util
local SharedConstants = require(util.Shared.SharedConstants)
local Maid = require(util.Shared.Maid)

local LocalConstants = {
	Folders = {
		Shared = util.Shared,
		Server = util.Server,
		Client = util.Client,
	},
}

local cachedLookups = {}

local function GetFolderNames()
	local folderNames = {}

	for key, value in pairs(LocalConstants.Folders) do
		table.insert(folderNames, ("%s.%s"):format(util.Name, value.Name))
	end

	return table.concat(folderNames, ", ")
end

local function CheckIfFolderIsValidForCurrentState(child, folder)
	local name = child.Name

	if folder == LocalConstants.Folders.Client or folder:IsDescendantOf(LocalConstants.Folders.Client) then
		assert(RunService:IsClient(), ("Can only get [%s] %s on the client!"):format(child.ClassName, name))
	elseif folder == LocalConstants.Folders.Server or folder:IsDescendantOf(util.Server) then
		assert(RunService:IsServer(), ("Can only get [%s] %s on the server!"):format(child.ClassName, name))
	end
end

local function IsSpecifiedFolderValid(specifiedFolder)
	local isFolderValid

	for _, folder in pairs(LocalConstants.Folders) do
		isFolderValid = specifiedFolder:IsDescendantOf(folder) or specifiedFolder == folder

		if isFolderValid then
			break
		end
	end

	return isFolderValid
end

return function(name, specifiedFolder)
	assert(
		typeof(name) == "string",
		SharedConstants.ErrorMessages.InvalidArgument:format(1, "Comet.Get()", "string", typeof(name))
	)
	if specifiedFolder then
		assert(
			typeof(specifiedFolder) == "string" or typeof(specifiedFolder) == "Instance",
			SharedConstants.ErrorMessages.InvalidArgument:format(
				2,
				"Comet.Get()",
				"string or Instance or nil",
				typeof(specifiedFolder)
			)
		)
	end

	if typeof(specifiedFolder) == "Instance" then
		assert(IsSpecifiedFolderValid(specifiedFolder), "Invalid folder")
		local child = specifiedFolder:FindFirstChild(name)

		assert(child, ("%s not found in [%s]"):format(name, specifiedFolder.Name))
		CheckIfFolderIsValidForCurrentState(child, specifiedFolder)

		if child:IsA("ModuleScript") then
			return require(child)
		else
			return child
		end
	end

	for _, folder in pairs(LocalConstants.Folders) do
		-- Return cached results:
		local cachedResult = cachedLookups[folder] and cachedLookups[folder][name]
		local cachedResultWithSpecifiedFolder = cachedLookups[specifiedFolder] and cachedLookups[specifiedFolder][name]

		if cachedResult or cachedResultWithSpecifiedFolder then
			return cachedResult or cachedResultWithSpecifiedFolder
		end

		for _, child in ipairs(folder:GetChildren()) do
			local specifiedFolder = specifiedFolder and folder:FindFirstChild(specifiedFolder)

			if specifiedFolder then
				child = specifiedFolder:FindFirstChild(name)
			elseif child.Name ~= name then
				continue
			end

			CheckIfFolderIsValidForCurrentState(child, specifiedFolder)

			local key = specifiedFolder or folder.Name
			cachedLookups[key] = cachedLookups[key] or {}
			cachedLookups[key][name] = child

			if child:IsA("ModuleScript") then
				return require(child)
			else
				return child
			end
		end
	end

	error(("%s not found in [%s]"):format(name, GetFolderNames()))
end
