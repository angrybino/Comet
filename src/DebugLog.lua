-- angrybino
-- DebugLog
-- October 10, 2021

local SharedConstants = require(script.Parent.SharedConstants)

return function(message)
	warn(("[Comet] [Debug]: %s"):format(message))
end
