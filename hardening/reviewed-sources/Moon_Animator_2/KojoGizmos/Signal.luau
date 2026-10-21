-- Copyright © 2023 Kojocrash

local Signal = {}
Signal.__index = Signal

local Connection = require(script.Connection)
local TS = game:GetService("TestService")

function Signal.new()
	local self = setmetatable({}, Signal)
	self._connections = {}
	
	return self
end

function Signal:Connect(callback)
	local connection = Connection:new(self, callback)
	table.insert(self._connections, connection)
	return connection
end

function Signal:connect(callback)
	self:Connect(callback)
end

function Signal:Fire(...)
	local args = {...}
	local threadsDone = 0
	local threadCount = #self._connections
	
	local onThreadFinishCallback = nil
	local onThreadFinish = function(THREADS_FINISHED_OR_FUNCTION)
		if THREADS_FINISHED_OR_FUNCTION == "THREADS_FINISHED" then
			for i = 1, 2 do
				if onThreadFinishCallback then
					return onThreadFinishCallback()
				end
				task.wait()
			end
		else
			onThreadFinishCallback = THREADS_FINISHED_OR_FUNCTION
		end
	end
	
	for i = 1, #self._connections do
		local thread = task.spawn(function()
			xpcall(function()
				self._connections[i].callback(unpack(args))
			end, function(err)
				local traceback = debug.traceback(nil, 2)
				local stackTexts = {}

				for s in traceback:gmatch("[^\r\n]+") do
					local location, lineNum, functionName = string.match(s, "(.+):(%d+)%s?(.*)")
					table.insert(stackTexts, ("Script '%s', Line %d - %s"):format(location, lineNum, functionName))
				end

				local stackText = "Stack Begin\n  " .. table.concat(stackTexts, "\n  ", 1, #stackTexts-2) .. "\n  Stack End"
				TS:Error(err)
				TS:Message(stackText)
			end)
			
			threadsDone += 1
			if threadsDone >= threadCount then
				task.defer(onThreadFinish, "THREADS_FINISHED")
			end
		end) 
	end
	
	return onThreadFinish
end

return Signal