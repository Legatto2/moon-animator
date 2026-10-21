local _g = _G.MoonGlobal; _g.req("Object")
local Path = super:new()

function Path:new(Item)
	local ctor = super:new(Item)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if Item then
		ctor.Item = Item
		ctor.Format = nil
		ctor.ItemType = nil
		ctor.InstanceNames = nil
		ctor.InstanceTypes = nil

		local Format, ItemType, InstanceNames, InstanceTypes = Path.GetPath(Item)

		assert(Format ~= nil, "Path error.")

		ctor.Format = Format
		ctor.ItemType = ItemType
		ctor.InstanceNames = InstanceNames
		ctor.InstanceTypes = InstanceTypes
	end

	return ctor
end

function Path.Deserialize(tbl)
	if tbl.InstanceNames == nil or tbl.InstanceTypes == nil then return false, 1 end

	local GetItem = Path.ParsePath(tbl.ItemType, tbl.InstanceNames, tbl.InstanceTypes)
	if GetItem == nil then return false, 2 end

	return Path:new(GetItem)
end

function Path.GetPath(Item)
	local Format = ""
	local InstanceNames = {}
	local InstanceTypes = {}

	if Item == workspace.CurrentCamera then
		return "game.Workspace.CurrentCamera", "Camera", {"game", "Workspace", "CurrentCamera"}, {"DataModel", "Workspace", "Camera"}
	end

	local succ, err = pcall(function()
		local current = Item
		while current ~= nil do

			local GetFormattedName
			if current.ClassName == "DataModel" then
				GetFormattedName = "game"
			else
				GetFormattedName = current.Name
				if tonumber(string.sub(GetFormattedName, 1, 1)) or string.find(GetFormattedName, " ") or string.find(GetFormattedName, "%.") then
					GetFormattedName = "[\""..GetFormattedName.."\"]"
				end
			end
			if #Format == 0 then
				Format = GetFormattedName
			else
				if string.sub(Format, 1, 1) == "[" then
					Format = GetFormattedName..Format
				else
					Format = GetFormattedName.."."..Format
				end
			end

			if current.ClassName == "DataModel" then
				table.insert(InstanceNames, 1, "game")
				table.insert(InstanceTypes, 1, "DataModel")
				current = nil
			else
				table.insert(InstanceNames, 1, current.Name)
				table.insert(InstanceTypes, 1, current.ClassName)
				current = current.Parent
			end

		end
	end)

	if not succ or #InstanceNames < 2 then
		return nil
	end

	return Format, _g.ItemTable.GetItemType(Item), InstanceNames, InstanceTypes
end

function Path.ParsePath(ItemType, InstanceNames, InstanceTypes)
	local final

	local step = 2
	local succ, err = pcall(function()
		while true do
			local current = game
			for i = 2, step do
				current = current[InstanceNames[i]]
			end

			if (current == nil or current.Parent == nil)
			or (current.ClassName ~= InstanceTypes[step]) then
				break
			end

			if step == #InstanceNames then
				final = current
				break
			end

			step = step + 1
		end
	end)

	if succ and final ~= nil and _g.ItemTable.GetItemType(final) == ItemType then
		return final
	else
		return nil
	end
end

function Path.CheckIfUnique(Item)
	local sameNames = {}

	local curHier = Item.Parent
	local badInstance = Item

	pcall(function()
		while (curHier ~= game) do
			for _, v in pairs(curHier:GetChildren()) do
				if v ~= badInstance and v.Name == badInstance.Name and v.ClassName == badInstance.ClassName then
					table.insert(sameNames, v)
				end
			end
			if #sameNames > 0 then
				break
			end
			curHier = curHier.Parent
			badInstance = badInstance.Parent
		end
	end)

	if #sameNames > 0 then
		return false, sameNames, badInstance, curHier
	end

	return true
end

function Path:Serialize()
	return {
		ItemType = self.ItemType,
		InstanceNames = self.InstanceNames,
		InstanceTypes = self.InstanceTypes
	}
end

function Path:GetItem()
	if self.Item and self.Item.Parent then
		return self.Item
	else
		local Parse = Path.ParsePath(self.ItemType, self.InstanceNames, self.InstanceTypes)
		if Parse ~= nil then
			self.Item = Parse
		end
		return Parse
	end
end

return Path
