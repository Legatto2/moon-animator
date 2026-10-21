local _g = _G.MoonGlobal; _g.req("GuiElement", "Button")
local ImageList = super:new()

function ImageList:new(UI, default, changed, List)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed
		ctor._list = nil
		ctor._curInd = nil
		ctor._leftButton = nil
		ctor._rightButton = nil
		ctor.Value = default

		ctor._leftButton = Button:new(UI.Left.Left)
			ctor._leftButton.OnClick = function()
				ImageList._Navigate(ctor, -1)
			end
		ctor._rightButton = Button:new(UI.Right.Right)
			ctor._rightButton.OnClick = function()
				ImageList._Navigate(ctor, 1)
			end
		
		ImageList.SetList(ctor, List)
		ImageList.Set(ctor, default, false)

		ctor:AddPaintedItem(UI.ImageId.Label, {TextColor3 = "main"})
		ctor:AddPaintedItem(UI.BottomSec.Label, {TextColor3 = "highlight"})
	end

	return ctor
end

function ImageList:_Navigate(dir)
	local targetIndex

	if #self._list == 0 then self:Set(nil, true) return false end

	if self._curInd == nil then
		targetIndex = dir == 1 and #self._list or 1
	else
		targetIndex = self._curInd + dir
	end
	if targetIndex > #self._list then
		targetIndex = 1
	elseif targetIndex < 1 then
		targetIndex = #self._list
	end

	self:Set(self._list[targetIndex].Id, true)
end

function ImageList:Set(value, inputted)
	self.Value = value

	if value == nil or self._list[value] == nil then
		self.UI.BottomSec.Label.Text = "-"
		self.UI.ImageId.Label.Text = "-"

		self.UI.CurrentImg.Image = ""

		if #self._list > 0 then
			self.UI.NextImg.Image = self._list[#self._list].Image
			self.UI.PrevImg.Image = self._list[1].Image
		else
			self.UI.NextImg.Image = ""
			self.UI.PrevImg.Image = ""
		end

		self._curInd = nil
	else
		local target = self._list[value]
		self.UI.BottomSec.Label.Text = target.index.." / "..#self._list
		self.UI.ImageId.Label.Text = target.Id
		self.UI.CurrentImg.Image = target.Image

		self.UI.NextImg.Image = self._list[((target.index + 1) > #self._list) and 1 or (target.index + 1)].Image
		self.UI.PrevImg.Image = self._list[((target.index - 1) < 1) and #self._list or (target.index - 1)].Image

		self._curInd = target.index
	end

	if inputted and self._changed then
		self._changed(self.Value)
	end
end

function ImageList:SetList(List)
	if List == nil or #List == 0 then
		self._list = {}
		self._curInd = nil
		self:Set(nil, true)
	else
		local FormattedList = _g.deepcopy(List)

		for i = 1, #FormattedList, 1 do
			local opt = FormattedList[i]
			assert(opt.Id and opt.Image, "Invalid list item.")
			opt.index = i
			FormattedList[opt.Id] = opt
		end
		
		self._list = FormattedList
		self:Set(self._list[1].Id, true)
	end
end

return ImageList
