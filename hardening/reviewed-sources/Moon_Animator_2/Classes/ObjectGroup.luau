local _g = _G.MoonGlobal; _g.req("Object")
local ObjectGroup = super:new()

function ObjectGroup:new(name)
	local ctor = super:new(name)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if name then
		ctor.name = name
		ctor.Objects = {}
		ctor.GroupLookup = {}
		ctor.size = 0

		ctor.dict = {}
		ctor.inds = {}
	end

	return ctor
end

function ObjectGroup:Destroy()
	self:Clear()
	super.Destroy(self)
end

function ObjectGroup:Move(Object, index)
	assert(self.dict[tostring(Object)] ~= nil, "Object does not exist in ObjectGroup.")
	self:Remove(Object)
	self:Insert(Object, index)
end

function ObjectGroup:Add(Object)
	self:Insert(Object, self.size + 1)
end

function ObjectGroup:Insert(Object, index)
	assert(Object.ParentObjectGroups, "Object is not a Object.")
	assert(self.dict[tostring(Object)] == nil and index ~= nil, "Object already exists in ObjectGroup.")
	assert(index <= self.size + 1, "Index out of bounds.")

	for i = index, self.size, 1 do
		self.inds[tostring(self.Objects[i])] = i + 1
	end

	Object.ParentObjectGroups[tostring(self)] = self
	self.dict[tostring(Object)] = Object
	self.inds[tostring(Object)] = index
	table.insert(self.Objects, index, Object)
	if _g.objIsType(Object, "ObjectGroup") then
		self.GroupLookup[Object.name] = Object
	end

	self.size = self.size + 1
end

function ObjectGroup:Remove(Object)
	assert(self.dict[tostring(Object)] ~= nil, "Object does not exist in ObjectGroup.")
	
	local index = 1
	for ind, find in pairs(self.Objects) do
		if find == Object then
			index = ind
			Object.ParentObjectGroups[tostring(self)] = nil
			self.dict[tostring(Object)] = nil
			self.inds[tostring(Object)] = nil
			if _g.objIsType(Object, "ObjectGroup") then
				self.GroupLookup[Object.name] = nil
			end
			self.size = self.size - 1
			break
		end
	end
	table.remove(self.Objects, index)

	for i = index, self.size, 1 do
		local Target = self.Objects[i]
		self.inds[tostring(Target)] = i
	end

	return Object
end

function ObjectGroup:RemoveAt(index)
	assert(index <= self.size, "Index out of bounds.")
	return self:Remove(self.Objects[index])
end

function ObjectGroup:Clear()
	self:Iterate(function(Object, ContainingGroup)
		ContainingGroup:Remove(Object)
	end)
end

function ObjectGroup:IndexOf(Object)
	return self.inds[tostring(Object)]
end

function ObjectGroup:Iterate(func, object_filter)
	local copy = {}
	for _, Object in pairs(self.Objects) do
		table.insert(copy, Object)
	end

	for _, Object in pairs(copy) do
		if _g.objIsType(Object, "ObjectGroup") then
			Object:Iterate(func, object_filter)
		elseif object_filter == nil or _g.objIsType(Object, object_filter) then
			local res = func(Object, self)
			if res == false then
				break
			end
		end
	end
end

function ObjectGroup:Contains(Object)
	return self.dict[tostring(Object)] ~= nil
end

return ObjectGroup
