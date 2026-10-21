local Connection = {}
Connection.__index = Connection

function Connection:new(Signal, Callback)
	local self = setmetatable({}, Connection)
	self.signal = Signal
	self.callback = Callback
	
	return self
end

function Connection:Disconnect()
	local index = table.find(self.signal.connections, self)
	if index then
		table.remove(self.signal.connections)
		self.callback = nil
	end
end

function Connection:disconnect()
	self:Disconnect()
end

return Connection
