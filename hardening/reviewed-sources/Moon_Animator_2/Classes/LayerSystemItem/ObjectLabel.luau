local _g = _G.MoonGlobal; _g.req("LayerSystemItem")
local ObjectLabel = super:new()

function ObjectLabel:new(LayerSystem, ItemObject)
	local ui_store = _g.new_ui.LayerSystemItem.ObjectLabel
	local ctor = super:new(LayerSystem, ItemObject, 0, ui_store.List:Clone(), ui_store.Timeline:Clone(), ui_store.List.Size.Y.Offset)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if LayerSystem then
		ctor.ItemObject = ItemObject
		
		if ItemObject.Path.ItemType == "Humanoid" then
			ctor.ListComponent.Label.Text = ItemObject.Path:GetItem().Parent.Name
		else
			ctor.ListComponent.Label.Text = ItemObject.Path:GetItem().Name
		end
		
		local cir = _g.new_ui.LayerSystemItem.TrackButtons.TrackEnable:Clone(); cir.Parent = ctor.ListComponent
		cir.Name = "AllTracksEnable"
		
		
		
		local icon
		if ItemObject.Path.ItemType == "Model" then
			icon = ui_store.ModelIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.BG_col, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.BG_col2, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.BG_col3, {BackgroundColor3 = "second"})
			ctor.icon_highlight = {icon.BG_col}
		elseif ItemObject.Path.ItemType == "Humanoid" or ItemObject.Path.ItemType == "FaceControls" then
			icon = ui_store.FaceControlsIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.Circle_col1, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle_col1.UIStroke, {Color = "third"})
			ctor:AddPaintedItem(icon.Circle_col2, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle_col2.UIStroke, {Color = "third"})
			ctor.icon_highlight = {icon.Circle_col1, icon.Circle_col2}
		elseif ItemObject.Path.ItemType == "Rig" then
			icon = ui_store.ModelIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.BG_col, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.BG_col2, {BackgroundColor3 = "main"})
			ctor:AddPaintedItem(icon.BG_col3, {BackgroundColor3 = "main"})
			ctor.icon_highlight = {icon.BG_col}
		elseif ItemObject.Path.Item.ClassName == "Sound" or ItemObject.Path.Item.ClassName == "SoundGroup" or ItemObject.Path.Item.ClassName == "SoundService" then
			icon = ui_store.SoundIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.BG_clip.Frame, {BackgroundColor3 = "main"})
			ctor:AddPaintedItem(icon.Border_clip.Frame, {BackgroundColor3 = "third"})
			ctor.icon_highlight = {icon.Circle}
		elseif ItemObject.Path.ItemType == "BasePart" then
			icon = ui_store.PartIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.Circle1, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle1.UIStroke, {Color = "third"})
			ctor:AddPaintedItem(icon.Circle2, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle2.UIStroke, {Color = "third"})
			ctor.icon_highlight = {icon.Circle1, icon.Circle2}
		elseif ItemObject.Path.Item:IsA("GuiBase") or ItemObject.Path.ItemType == "Decal" then
			icon = ui_store.ImageLabelIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.Circle1, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle1.UIStroke, {Color = "third"})
			ctor.icon_highlight = {icon.Circle1}
		elseif ItemObject.Path.Item:IsA("DataModelMesh") then
			icon = ui_store.MeshIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.Circle1, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle1.UIStroke, {Color = "third"})
			ctor:AddPaintedItem(icon.Circle2, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle2.UIStroke, {Color = "third"})
			ctor.icon_highlight = {icon.Circle1, icon.Circle2}
		elseif ItemObject.Path.ItemType == "Camera" then
			icon = ui_store.CameraIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.Circle_col, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle_col.UIStroke, {Color = "third"})
			ctor.icon_highlight = {icon.Circle_col}
		elseif ItemObject.Path.ItemType == "Lighting" or ItemObject.Path.Item:IsA("Light") then
			icon = ui_store.LightIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.BG_col, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle_col, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle_col.UIStroke, {Color = "third"})
			ctor.icon_highlight = {icon.Circle_col}
		elseif ItemObject.Path.Item:IsA("PostEffect") then
			icon = ui_store.PostEffectIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.Circle_col, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle_col.UIStroke, {Color = "third"})
			ctor.icon_highlight = {icon.Circle_col}
		elseif ItemObject.Path.Item.ClassName == "ParticleEmitter" then
			icon = ui_store.PEIcon:Clone(); icon.Parent = ctor.ListComponent
			ctor:AddPaintedItem(icon.Circle_col1, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle_col1.UIStroke, {Color = "third"})
			ctor:AddPaintedItem(icon.Circle_col2, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle_col2.UIStroke, {Color = "third"})
			ctor:AddPaintedItem(icon.Circle_col3, {BackgroundColor3 = "second"})
			ctor:AddPaintedItem(icon.Circle_col3.UIStroke, {Color = "third"})
			ctor.icon_highlight = {icon.Circle_col1, icon.Circle_col2, icon.Circle_col3}
		else
			ui_store.Icon:Clone().Parent = ctor.ListComponent
			_g.ItemTable.SetIcon(ctor.ListComponent.Icon, ItemObject.Path.ItemType)
		end
		
		if icon then
			for _, obj in pairs(icon:GetChildren()) do
				if obj.Name == "Border" then
					ctor:AddPaintedItem(obj, {BackgroundColor3 = "third"})
				elseif obj.Name == "BG" then
					ctor:AddPaintedItem(obj, {BackgroundColor3 = "main"})
				elseif obj.Name == "Circle" then
					ctor:AddPaintedItem(obj, {BackgroundColor3 = "second"})
					ctor:AddPaintedItem(obj.UIStroke, {Color = "third"})
				end
			end
		end
		
		ctor:AddPaintedItem(ctor.ListComponent.BG, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.ListComponent.BG.Corner, {BackgroundColor3 = "second"})
		ctor.edit_frames = {}
		for _, frame in pairs(ctor.ListComponent.Edit:GetChildren()) do
			ctor:AddPaintedItem(frame, {BackgroundColor3 = "text"})
			table.insert(ctor.edit_frames, frame)
		end
		ctor:AddPaintedItem(ctor.ListComponent.AllTracksEnable.Open.UIStroke, {Color = "text"})
		ctor:AddPaintedItem(ctor.ListComponent.AllTracksEnable.Closed, {BackgroundColor3 = "text"})

		ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowDown, {TextColor3 = "text"})
		ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowRight, {TextColor3 = "text"})
		
		local tween_time = _g.Themer.QUICK_TWEEN
		
		_g.GuiLib:AddInput(ctor.ListComponent, {hover = {caller_obj = ctor,
			func_start = function()
				ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowDown, {TextColor3 = "main"}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowRight, {TextColor3 = "main"}, tween_time)
				for _, frame in pairs(ctor.edit_frames) do
					ctor:SetItemPaint(frame, {BackgroundColor3 = "main"}, tween_time)
				end
			end,
			func_ended = function()
				ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowDown, {TextColor3 = "text"}, tween_time)
				ctor:SetItemPaint(ctor.ListComponent.Arrow.ArrowRight, {TextColor3 = "text"}, tween_time)
				for _, frame in pairs(ctor.edit_frames) do
					ctor:SetItemPaint(frame, {BackgroundColor3 = "text"}, tween_time)
				end
			end,
		}})
	end

	return ctor
end

function ObjectLabel:Collapse(value)
	super.Collapse(self, value)
	self.ListComponent.BG.Corner.Visible = not self.collapsed
end

function ObjectLabel:GetItemsBelow(recursive)
	assert(self.ParentContainer ~= nil, "ObjectLabel not parented in a LSIContainer.")

	local GroupsBelow = {}
	local index = self.ParentContainer:IndexOf(self)
	for i = index + 1, #self.ParentContainer.Objects do
		if _g.objIsType(self.ParentContainer.Objects[i], "ObjectGroup") then
			table.insert(GroupsBelow, self.ParentContainer.Objects[i])
		end
	end

	local ret = {}
	if self.ItemObject.MarkerTrack then
		table.insert(ret, self.ItemObject.MarkerTrack)
	end
	for _, Group in pairs(GroupsBelow) do
		local objs = Group.Objects
		for iter = 1, #objs, 1 do
			if objs[iter].hierLevel and ((not recursive and objs[iter].hierLevel == 0) or recursive) then
				table.insert(ret, objs[iter])
			end
		end
	end

	return ret
end

return ObjectLabel
