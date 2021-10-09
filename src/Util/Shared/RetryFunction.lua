-- angrybino
-- RetryFunction
-- September 26, 2021

--[[
    RetryFunction(
        maxTries : number ?, 
        retryInterval : number ?, 
        argsData : table
    ) --> boolean [wasSuccessful], response : any [tuple]
]]

local LocalConstants = {
	DefaultFailedPcallTries = 5,
	DefaultFailedPcallRetryInterval = 5,
}

local LocalConstants = {
	ErrorMessages = {
		InvalidArgument = "Invalid argument#%d to %s: expected %s, got %s",
	},
}

return function(callBack, arguments, maxTries, retryInterval)
	assert(
		typeof(callBack) == "function",
		LocalConstants.ErrorMessages.InvalidArgument:format(1, "RetryFunction()", "function", typeof(callBack))
	)
	assert(
		typeof(arguments) == "table",
		LocalConstants.ErrorMessages.InvalidArgument:format(2, "RetryFunction()", "table", typeof(arguments))
	)

	if maxTries then
		assert(
			typeof(maxTries) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				3,
				"RetryFunction()",
				"number or nil",
				typeof(maxTries)
			)
		)
	end

	if retryInterval then
		assert(
			typeof(retryInterval) == "number",
			LocalConstants.ErrorMessages.InvalidArgument:format(
				4,
				"RetryFunction()",
				"number or nil",
				typeof(retryInterval)
			)
		)
	end

	local retryInterval = retryInterval or LocalConstants.DefaultFailedPcallRetryInterval
	local maxTries = maxTries or LocalConstants.DefaultFailedPcallTries

	local tries = 0
	local wasSuccessfull, response

	while tries < maxTries do
		wasSuccessfull, response = pcall(callBack, select(2, table.unpack(arguments)))

		if wasSuccessfull then
			break
		else
			tries += 1

			task.wait(retryInterval)
		end
	end

	return wasSuccessfull, response
end
