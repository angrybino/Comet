-- angrybino
-- WeldModel
-- September 26, 2021

-- Welds all parts in a model to the primary part of the model

--[[
	WeldModel(model : Model) --> void []
]]

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

return function(model)
	assert(
		typeof(model) == "Instance" and model:IsA("Model"),
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "WeldModel()", "Model", typeof(model))
	)

	assert(model.PrimaryPart, ("Can't weld model %s as it doesn't have a primary part"):format(model:GetFullName()))

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			if part ~= model.PrimaryPart then
				local weldConstraint = Instance.new("WeldConstraint")
				weldConstraint.Part0 = part
				weldConstraint.Part1 = model.PrimaryPart
				weldConstraint.Parent = part
			end

			part.Anchored = false
		end
	end
end
