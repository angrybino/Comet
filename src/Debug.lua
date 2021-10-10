-- angrybino
-- Debug
-- October 09, 2021

local SharedConstants = require(script.Parent.SharedConstants)

return function(message)
	warn(("%s %s"):format(SharedConstants.Comet, message))
end
