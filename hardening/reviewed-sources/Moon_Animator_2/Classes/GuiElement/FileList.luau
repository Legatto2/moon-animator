local _g = _G.MoonGlobal; _g.req("GuiElement", "MoonScroll")
local FileList = super:new()

function FileList:new(UI, changed)
	local ctor = super:new(UI)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if UI then
		ctor._changed = changed and changed or _g.BLANK_FUNC
		ctor.List = {}
		ctor.ScrollList = MoonScroll:new(UI.List, 16)
		ctor.ScrollList:SetItemPaint(UI.List.ScrollbarFrame.Scrollbar, {BackgroundColor3 = "second"})

		ctor:AddPaintedItem(UI.Background, {BackgroundColor3 = "bg"})
		ctor:AddPaintedItem(UI.Background.UIStroke, {Color = "third"})
		ctor:AddPaintedItem(UI.LabelFrame, {BackgroundColor3 = "bg"})
		ctor:AddPaintedItem(UI.LabelFrame.Label, {TextColor3 = "main"})
		ctor:AddPaintedItem(UI.List.Label, {TextColor3 = "third"})
	end

	return ctor
end

function FileList:SetList(list, label, is_import)
	if self.UI.List.Label.Visible and list == nil then return end
	
	for _, data in pairs(self.List) do
		self:RemovePaintedItem(data.ui.Frame)
		self:RemovePaintedItem(data.ui.LabelFrame.Label)
		if data.Type == "moon2" then
			self:RemovePaintedItem(data.ui.Frame.Frame)
			self:RemovePaintedItem(data.ui.Frame.Sel)
		elseif data.Type == "Folder" then
			self:RemovePaintedItem(data.ui.Frame.UIStroke)
			self:RemovePaintedItem(data.ui.Frame.Frame)
			self:RemovePaintedItem(data.ui.Frame.Frame.UIStroke)
		elseif data.combo then
			self:RemovePaintedItem(data.ui.LabelFrame.Divider.Frame)
			self:RemovePaintedItem(data.ui.LabelFrame.Prog)
		end
		data.ui:Destroy()
	end
	self.List = {}
	
	if list == nil then self.UI.List.Label.Text = "[      "..label.."      ]" self.UI.List.Label.Visible = true return end
	self.UI.List.Label.Visible = false
	
	if is_import then
		table.insert(list, 1, {"Roblox..."})
		table.insert(list, 2, {"Avatar Shop..."})
	end
	
	for _, file in pairs(list) do
		local back = file.back
		local combo = file[2]
		file = file[1]
		local new_but
		local but_data = {}
		if type(file) == "string" then
			if combo then
				new_but = _g.new_ui.Combo:Clone(); new_but.LabelFrame.Label.Text = file
				self:AddPaintedItem(new_but.Frame, {BackgroundColor3 = "main"})
				self:AddPaintedItem(new_but.LabelFrame.Label, {TextColor3 = "main"})
				
				self:AddPaintedItem(new_but.LabelFrame.Divider.Frame, {BackgroundColor3 = "main"})
				self:AddPaintedItem(new_but.LabelFrame.Prog, {TextColor3 = "main"})
				but_data.combo = combo
			else
				new_but = _g.new_ui.Import:Clone(); new_but.LabelFrame.Label.Text = file
				self:AddPaintedItem(new_but.Frame, {BackgroundColor3 = "second"})
				self:AddPaintedItem(new_but.LabelFrame.Label, {TextColor3 = "second"})
				but_data.import = file == "Roblox..."
				but_data.avatar_shop = file == "Avatar Shop..."
			end
		elseif file.ClassName == "Folder" then
			new_but = _g.new_ui.Folder:Clone(); new_but.LabelFrame.Label.Text = back and "..." or file.Name
			self:AddPaintedItem(new_but.Frame, {BackgroundColor3 = "main"})
			self:AddPaintedItem(new_but.LabelFrame.Label, {TextColor3 = "main"})
			
			self:AddPaintedItem(new_but.Frame.UIStroke, {Color = "main"})
			self:AddPaintedItem(new_but.Frame.Frame, {BackgroundColor3 = "main"})
			self:AddPaintedItem(new_but.Frame.Frame.UIStroke, {Color = "main"})
			but_data.Type = "Folder"
		elseif file.ClassName == "KeyframeSequence" then
			new_but = _g.new_ui.Import:Clone(); new_but.LabelFrame.Label.Text = file.Name
			self:AddPaintedItem(new_but.Frame, {BackgroundColor3 = "highlight"})
			self:AddPaintedItem(new_but.LabelFrame.Label, {TextColor3 = "highlight"})
			but_data.Type = "Import"
		elseif _g.Files.OpenFile(file) then
			new_but = _g.new_ui.Moon2File:Clone(); new_but.LabelFrame.Label.Text = file.Name
			self:AddPaintedItem(new_but.Frame, {BackgroundColor3 = "main"})
			self:AddPaintedItem(new_but.LabelFrame.Label, {TextColor3 = "main"})
			
			self:AddPaintedItem(new_but.Frame.Frame, {BackgroundColor3 = "bg"})
			self:AddPaintedItem(new_but.Frame.Sel, {BackgroundColor3 = "highlight"})
			but_data.Type = "moon2"
		end
		if new_but then
			but_data.ui = new_but; but_data.Target = file
			new_but.Parent = self.ScrollList.Canvas
			table.insert(self.List, but_data)
			if but_data.combo then
				_g.GuiLib:AddInput(new_but, {drag = {caller_obj = self, render_loop = true,
				func_start = function() 
					self._changed(but_data)
					self:SetItemPaint(new_but.Frame, {BackgroundColor3 = "third"})
				end, 
				func_ended = function() 
					self:SetItemPaint(new_but.Frame, {BackgroundColor3 = "main"}) 
				end}})
			else
				_g.GuiLib:AddInput(new_but, {down = {func = function() 
					self._changed(but_data)
				end}})
			end
		end
	end
	
	self.ScrollList:SetLineCount(#self.List)
end

return FileList
