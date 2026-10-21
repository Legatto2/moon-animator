local _g = _G.MoonGlobal
local super = nil
local Object = {}

Object.DEBUG = false
if Object.DEBUG then
	Object.DEBUG.Name = "MoonAnimator2Debug"
end

function Object:new(create)
	local ctor = {type = {}}
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if create then
		ctor.ThemedItems = {}
		ctor.ParentObjectGroups = {}

		if Object.DEBUG then
			task.spawn(function()
				wait()
				if rawget(ctor, "destroyed") then return end

				if Object.DEBUG:FindFirstChild(ctor.type[1]) == nil then
					local folder = Instance.new("Folder", Object.DEBUG)
					folder.Name = ctor.type[1]
				end
				ctor.objVal = Instance.new("IntValue")
				ctor.objVal.Name = tostring(ctor)
				ctor.objVal.Parent = Object.DEBUG[ctor.type[1]]
			end)
		end
	end

	return ctor
end

local bad = function() assert(false, "Destroyed Object indexed.") end
function Object:Destroy()
	if self.objVal then
		if self.objVal.Parent then
			if #self.objVal.Parent:GetChildren() == 1 then
				self.objVal.Parent:Destroy()
			else
				self.objVal:Destroy()
			end
		end
		self.objVal = nil
	end

	_g.GuiLib:ClearInput(self)

	for _, ObjectGroup in pairs(self.ParentObjectGroups) do
		ObjectGroup:Remove(self)
	end

	for _, item in pairs(self.ThemedItems) do
		_g.Themer:RemovePaintedItem(item)
	end

	if self.UI and self.UI.LayoutOrder ~= nil then
		self.UI:Destroy()
	end
	if self.ListComponent and self.ListComponent.LayoutOrder ~= nil then
		self.ListComponent:Destroy()
	end
	if self.TimelineComponent and self.TimelineComponent.LayoutOrder ~= nil then
		self.TimelineComponent:Destroy()
	end

	local keys = {}
	for key, _ in pairs(self) do
		table.insert(keys, key)
	end
	for _, key in pairs(keys) do
		self[key] = nil
	end
	self.destroyed = true
	setmetatable(self, {__index = bad, __newindex = bad})
end

function Object:AddPaintedItem(item, paintData)
	_g.Themer:AddPaintedItem(item, paintData)
	self.ThemedItems[item:GetDebugId(8)] = item
end

function Object:RemovePaintedItem(item)
	for ind, check in pairs(self.ThemedItems) do
		if check == item then
			self.ThemedItems[ind] = nil
			break
		end
	end

	_g.Themer:RemovePaintedItem(item)
	self.ThemedItems[item:GetDebugId(8)] = nil
end

function Object:SetItemPaint(item, paintData, tweenTime)
	_g.Themer:SetItemPaint(item, paintData, tweenTime)
end

return Object
