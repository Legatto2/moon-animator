local _g = _G.MoonGlobal; _g.req("TrackItem", "Ease")
local Keyframe = super:new()

local all_kfs = {}
local is_ease_colored = false

_g.set_kf_color = function(value)
	is_ease_colored = value
	for _, kf in pairs(all_kfs) do
		if kf.ease_colored ~= value then
			kf:_UpdateAppearance(value)
		end
	end
end

function Keyframe:new(frm_pos, Values, Eases)
	local ctor = super:new(frm_pos and _g.new_ui.Keyframe_single:Clone() or nil, 0, frm_pos)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if frm_pos then
		assert(Values ~= nil, "Value is nil.")

		ctor.TargetValues = Values
		ctor.value_count = 0
		ctor.EaseMap = Eases
		ctor.group = nil
		ctor.is_linear = true
		ctor.is_constant = false
		ctor.ease_colored = false
		
		if ctor.EaseMap == nil then
			ctor.EaseMap = {}
		end

		local maxInd = 0
		for ind, _ in pairs(ctor.TargetValues) do
			if ind > maxInd then
				maxInd = ind
			end
			if ctor.EaseMap[ind] == nil then
				ctor.EaseMap[ind] = Ease.LINEAR()
			end
			ctor.value_count = ctor.value_count + 1
		end
		ctor.width = maxInd
		ctor.group = maxInd > 0
		
		if ctor.group then
			ctor.UI:Destroy()
			ctor.UI = _g.new_ui.Keyframe_group:Clone()
			
			ctor:AddPaintedItem(ctor.UI.BG_Left.BG, {BackgroundColor3 = "main"})
			ctor:AddPaintedItem(ctor.UI.BG_Left.Border, {BackgroundColor3 = "third"})
			ctor:AddPaintedItem(ctor.UI.BG_Left.Select.UIStroke, {Color = "highlight"})
			ctor:AddPaintedItem(ctor.UI.BG_Right.BG, {BackgroundColor3 = "main"})
			ctor:AddPaintedItem(ctor.UI.BG_Right.Border, {BackgroundColor3 = "third"})
			ctor:AddPaintedItem(ctor.UI.BG_Right.Select.UIStroke, {Color = "highlight"})
			ctor:AddPaintedItem(ctor.UI.BG_Middle.BG, {BackgroundColor3 = "main"})
			ctor:AddPaintedItem(ctor.UI.BG_Middle.Border, {BackgroundColor3 = "third"})
			ctor:AddPaintedItem(ctor.UI.BG_Middle.Select.UIStroke, {Color = "highlight"})	
			ctor:AddPaintedItem(ctor.UI.BG_Middle.Line, {BackgroundColor3 = "third"})
			ctor:AddPaintedItem(ctor.UI.Start, {BackgroundColor3 = "third"})
			ctor:AddPaintedItem(ctor.UI.End, {BackgroundColor3 = "third"})
		else
			ctor:AddPaintedItem(ctor.UI.Middle, {BackgroundColor3 = "third"})
			ctor:AddPaintedItem(ctor.UI.BG, {BackgroundColor3 = "main"})
			ctor:AddPaintedItem(ctor.UI.Border, {BackgroundColor3 = "third"})
			ctor:AddPaintedItem(ctor.UI.Select.UIStroke, {Color = "highlight"})
		end	
		
		Keyframe._UpdateAppearance(ctor, is_ease_colored)
		all_kfs[tostring(ctor)] = ctor
		
		_g.GuiLib:AddInput(ctor.UI, {drag = {
			caller_obj = ctor, render_loop = true,
			func_start = super._TrackItemDragBegin, func_changed = super._TrackItemDragChanged, func_ended = super._TrackItemDragEnd,
		}})
	end

	return ctor
end

function Keyframe.Detableize(kf_tbl)
	local new_EaseMap
	if kf_tbl.EaseMap then
		new_EaseMap = {}
		if kf_tbl.EaseMap._tblType then
			new_EaseMap[0] = Ease.Detableize(kf_tbl.EaseMap)
		else
			for ind, ease_tbl in pairs(kf_tbl.EaseMap) do
				new_EaseMap[ind] = Ease.Detableize(ease_tbl)
			end
		end
	end
	if type(kf_tbl.TargetValues) ~= "table" then
		kf_tbl.TargetValues = {[0] = kf_tbl.TargetValues}
	end
	return Keyframe:new(kf_tbl.frm_pos, kf_tbl.TargetValues, new_EaseMap)
end

function Keyframe.Deserialize(kf_folder)
	if tonumber(kf_folder.Name) == nil or kf_folder:FindFirstChild("Values") == nil 
	or kf_folder.Values:FindFirstChild("0") == nil then return false, 1 end

	local Values = {}
	local maxInd = 0
	if kf_folder.Values:FindFirstChild("EnumType") then
		for _, val in pairs(kf_folder.Values:GetChildren()) do
			local ind = tonumber(val.Name)
			if ind then
				Values[ind] = Enum[kf_folder.Values.EnumType.Value][val.Value]
				if ind > maxInd then
					maxInd = ind
				end
			end
		end
	elseif kf_folder.Values:FindFirstChild("Vector2") then
		for _, val in pairs(kf_folder.Values:GetChildren()) do
			local ind = tonumber(val.Name)
			if ind then
				Values[ind] = Vector2.new(val.Value.X, val.Value.Y)
				if ind > maxInd then
					maxInd = ind
				end
			end
		end
	elseif kf_folder.Values:FindFirstChild("ColorSequence") then
		for _, val in pairs(kf_folder.Values:GetChildren()) do
			local ind = tonumber(val.Name)
			if ind then
				Values[ind] = ColorSequence.new(val.Value)
				if ind > maxInd then
					maxInd = ind
				end
			end
		end
	elseif kf_folder.Values:FindFirstChild("NumberSequence") then
		for _, val in pairs(kf_folder.Values:GetChildren()) do
			local ind = tonumber(val.Name)
			if ind then
				Values[ind] = NumberSequence.new(val.Value)
				if ind > maxInd then
					maxInd = ind
				end
			end
		end
	elseif kf_folder.Values:FindFirstChild("NumberRange") then
		for _, val in pairs(kf_folder.Values:GetChildren()) do
			local ind = tonumber(val.Name)
			if ind then
				Values[ind] = NumberRange.new(val.Value, val.Value)
				if ind > maxInd then
					maxInd = ind
				end
			end
		end
	else
		for _, val in pairs(kf_folder.Values:GetChildren()) do
			local ind = tonumber(val.Name)
			if ind then
				if val.Value == nil then
					Values[ind] = _g.NIL_VALUE
				else
					Values[ind] = val.Value
				end
				if ind > maxInd then
					maxInd = ind
				end
			end
		end
	end

	local Eases = {}
	if kf_folder:FindFirstChild("Eases") then
		for _, ease_folder in pairs(kf_folder.Eases:GetChildren()) do
			Eases[tonumber(ease_folder.Name)] = Ease.Deserialize(ease_folder)
		end
	elseif kf_folder:FindFirstChild("Ease") then
		Eases[maxInd] = Ease:new(kf_folder.Ease.Style.Value, {Direction = kf_folder.Ease.Direction.Value})
	end

	return Keyframe:new(tonumber(kf_folder.Name), Values, Eases)
end

function Keyframe:Destroy()
	all_kfs[tostring(self)] = nil
	if self.ParentTrack then
		self.ParentTrack:RemoveKeyframe(self)
	end
	for _, ease in pairs(self.EaseMap) do
		ease:Destroy()
	end
	super.Destroy(self)
end

function Keyframe:Tableize()
	local ease_tbls = {}
	for ind, ease in pairs(self.EaseMap) do
		ease_tbls[ind] = ease:Tableize()
	end
	return {_tblType = "Keyframe", frm_pos = self.frm_pos, EaseMap = ease_tbls, TargetValues = self.TargetValues, width = self.width}
end

function Keyframe:Serialize()
	local kf_folder = Instance.new("Folder")
	kf_folder.Name = tostring(self.frm_pos)

	local valuesFolder = Instance.new("Folder", kf_folder)
	valuesFolder.Name = "Values"

	local valType = self.ParentTrack.PropertyData[2]
	local holder = _g.ItemTable.PropertyTypeHolders[valType]

	if valType == "EnumItem" then
		if self.ParentTrack then
			local enumType = Instance.new("StringValue", valuesFolder)
			enumType.Name = "EnumType"
			enumType.Value = self.ParentTrack.PropertyData.SpecialEnum and self.ParentTrack.PropertyData.SpecialEnum or self.ParentTrack.property
		end

		for pos, val in pairs(self.TargetValues) do
			local newVal = holder:Clone()
			newVal.Name = tostring(pos)
			newVal.Value = val.Name
			newVal.Parent = valuesFolder
		end
	elseif valType == "Vector2" then
		local ind = Instance.new("IntValue", valuesFolder)
		ind.Name = "Vector2"

		for pos, val in pairs(self.TargetValues) do
			local newVal = holder:Clone()
			newVal.Name = tostring(pos)
			newVal.Value = Vector3.new(val.X, val.Y, 0)
			newVal.Parent = valuesFolder
		end
	elseif valType == "ColorSequence" or valType == "NumberSequence" then
		local ind = Instance.new("IntValue", valuesFolder)
		ind.Name = valType
		
		for pos, val in pairs(self.TargetValues) do
			local newVal = holder:Clone()
			newVal.Name = tostring(pos)
			newVal.Value = val.Keypoints[1].Value
			newVal.Parent = valuesFolder
		end
	elseif valType == "NumberRange" then
		local ind = Instance.new("IntValue", valuesFolder)
		ind.Name = valType

		for pos, val in pairs(self.TargetValues) do
			local newVal = holder:Clone()
			newVal.Name = tostring(pos)
			newVal.Value = val.Min
			newVal.Parent = valuesFolder
		end
	else
		for pos, val in pairs(self.TargetValues) do
			local newVal = holder:Clone()
			newVal.Name = tostring(pos)
			if val ~= _g.NIL_VALUE then
				newVal.Value = val
			end
			newVal.Parent = valuesFolder
		end
	end

	local eases_folder
	for ind, ease in pairs(self.EaseMap) do
		if ease.ease_type ~= "Linear" then
			if eases_folder == nil then
				eases_folder = Instance.new("Folder", kf_folder)
				eases_folder.Name = "Eases"
			end
			local ease_folder = ease:Serialize()
			ease_folder.Name = tostring(ind)
			ease_folder.Parent = eases_folder
		end
	end

	return kf_folder
end

function Keyframe:_UpdateAppearance(ease_colored)
	if ease_colored == nil then ease_colored = self.ease_colored end
	
	local target_ease = self.EaseMap[self.width]
	local ease_data = Ease.EASE_DATA[target_ease.ease_type]
	
	self.is_linear = target_ease.ease_type == "Linear"
	self.is_constant = target_ease.ease_type == "Constant"
	local track_sel = self.ParentTrack and self.ParentTrack.selected or false
	
	if self.group then 
		if ease_colored ~= self.ease_colored then
			self.ease_colored = ease_colored
			if ease_colored then
				self:RemovePaintedItem(self.UI.BG_Left.BG)
				self:RemovePaintedItem(self.UI.BG_Right.BG)
				self:RemovePaintedItem(self.UI.BG_Middle.BG)
			else
				self:AddPaintedItem(self.UI.BG_Left.BG, {BackgroundColor3 = "main"})
				self:AddPaintedItem(self.UI.BG_Right.BG, {BackgroundColor3 = "main"})
				self:AddPaintedItem(self.UI.BG_Middle.BG, {BackgroundColor3 = "main"})
				
				local has_left = self.UI:FindFirstChild("DirLeft"); if has_left then self:RemovePaintedItem(has_left.BG.UIStroke) has_left:Destroy() end
				local has_right = self.UI:FindFirstChild("DirRight"); if has_right then self:RemovePaintedItem(has_right.BG.UIStroke) has_right:Destroy() end
			end
		end

		if ease_colored then
			local color = Ease.EASE_DATA[self.EaseMap[self.width].ease_type].Color
			self.UI.BG_Left.BG.BackgroundColor3 = color
			self.UI.BG_Right.BG.BackgroundColor3 = color
			self.UI.BG_Middle.BG.BackgroundColor3 = color
			
			self:SetItemPaint(self.UI.BG_Middle.Border, {BackgroundColor3 = "main"})
			self:SetItemPaint(self.UI.BG_Left.Border, {BackgroundColor3 = "main"})
			self:SetItemPaint(self.UI.BG_Right.Border, {BackgroundColor3 = "main"})
			if not track_sel then
				self:SetItemPaint(self.UI.BG_Middle.Line, {BackgroundColor3 = "main"})
				self:SetItemPaint(self.UI.Start, {BackgroundColor3 = "main"})
				self:SetItemPaint(self.UI.End, {BackgroundColor3 = "main"})
			end
			
			local need_left = false; local has_left = self.UI:FindFirstChild("DirLeft")
			local need_right = false; local has_right = self.UI:FindFirstChild("DirRight")

			if ease_data.Params and ease_data.Params.Direction then
				if target_ease.params.Direction == "In" then
					need_left = true
				elseif target_ease.params.Direction == "Out" then
					need_right = true
				else
					need_left = true
					need_right = true
				end
			end
			
			if not need_left and has_left then 
				self:RemovePaintedItem(self.UI.DirLeft.BG.UIStroke) 
				self.UI.DirLeft:Destroy() 
			elseif need_left and not has_left then
				local new_left = _g.new_ui.DirLeft:Clone(); new_left.Parent = self.UI
				self:AddPaintedItem(new_left.BG.UIStroke, {Color = "text"})
			end
			
			if not need_right and has_right then 
				self:RemovePaintedItem(self.UI.DirRight.BG.UIStroke) 
				self.UI.DirRight:Destroy()
			elseif need_right and not has_right then
				local new_right = _g.new_ui.DirRight:Clone(); new_right.Parent = self.UI
				self:AddPaintedItem(new_right.BG.UIStroke, {Color = "text"})
			end
		else
			local border_color = (self.is_constant or self.is_linear) and "main" or "third"
			local def_color = self.is_constant and "bg" or (self.is_linear and "third" or "main")
			
			self:SetItemPaint(self.UI.BG_Middle.Border, {BackgroundColor3 = border_color})
			self:SetItemPaint(self.UI.BG_Left.Border, {BackgroundColor3 = border_color})
			self:SetItemPaint(self.UI.BG_Right.Border, {BackgroundColor3 = border_color})
			
			if not track_sel then
				self:SetItemPaint(self.UI.BG_Middle.Line, {BackgroundColor3 = border_color})
				self:SetItemPaint(self.UI.Start, {BackgroundColor3 = border_color})
				self:SetItemPaint(self.UI.End, {BackgroundColor3 = border_color})
			end
			
			self:SetItemPaint(self.UI.BG_Left.BG, {BackgroundColor3 = def_color})
			self:SetItemPaint(self.UI.BG_Right.BG, {BackgroundColor3 = def_color})
			self:SetItemPaint(self.UI.BG_Middle.BG, {BackgroundColor3 = def_color})
		end
	else
		if ease_colored ~= self.ease_colored then
			self.ease_colored = ease_colored
			if ease_colored then
				self:RemovePaintedItem(self.UI.BG)
			else
				self:AddPaintedItem(self.UI.BG, {BackgroundColor3 = "main"})
				local has_left = self.UI:FindFirstChild("DirLeft"); if has_left then self:RemovePaintedItem(has_left.BG.UIStroke) has_left:Destroy() end
				local has_right = self.UI:FindFirstChild("DirRight"); if has_right then self:RemovePaintedItem(has_right.BG.UIStroke) has_right:Destroy() end
			end
		end

		if ease_colored then
			self.UI.BG.BackgroundColor3 = Ease.EASE_DATA[self.EaseMap[self.width].ease_type].Color
			if not track_sel then
				self:SetItemPaint(self.UI.Middle, {BackgroundColor3 = "main"})
			end
			self:SetItemPaint(self.UI.Border, {BackgroundColor3 = "main"})
			
			local need_left = false; local has_left = self.UI:FindFirstChild("DirLeft")
			local need_right = false; local has_right = self.UI:FindFirstChild("DirRight")

			if ease_data.Params and ease_data.Params.Direction then
				if target_ease.params.Direction == "In" then
					need_left = true
				elseif target_ease.params.Direction == "Out" then
					need_right = true
				else
					need_left = true
					need_right = true
				end
			end

			if not need_left and has_left then 
				self:RemovePaintedItem(self.UI.DirLeft.BG.UIStroke) 
				self.UI.DirLeft:Destroy() 
			elseif need_left and not has_left then
				local new_left = _g.new_ui.DirLeft:Clone(); new_left.Parent = self.UI
				self:AddPaintedItem(new_left.BG.UIStroke, {Color = "text"})
			end

			if not need_right and has_right then 
				self:RemovePaintedItem(self.UI.DirRight.BG.UIStroke) 
				self.UI.DirRight:Destroy()
			elseif need_right and not has_right then
				local new_right = _g.new_ui.DirRight:Clone(); new_right.Parent = self.UI
				self:AddPaintedItem(new_right.BG.UIStroke, {Color = "text"})
			end
		else
			local border_color = (self.is_constant or self.is_linear) and "main" or "third"
			local def_line_color = self.selected and "highlight" or border_color
			local def_color = self.is_constant and "bg" or (self.is_linear and "third" or "main")
			
			self:SetItemPaint(self.UI.Border, {BackgroundColor3 = border_color})
			if not track_sel then
				self:SetItemPaint(self.UI.Middle, {BackgroundColor3 = border_color})
			end
			self:SetItemPaint(self.UI.BG, {BackgroundColor3 = def_color})
		end
	end
end

function Keyframe:_SetSelect(value)
	super._SetSelect(self, value)
	
	local def_line_color = self.ease_colored and "main" or ((self.is_constant or self.is_linear) and "main" or "third")
	local col = value and "highlight" or def_line_color
	local thick = value and 3 or 0
	
	if self.group then 
		self.UI.BG_Left.Border.Visible = not value
		self.UI.BG_Left.Select.UIStroke.Thickness = thick
		self.UI.BG_Right.Border.Visible = not value
		self.UI.BG_Right.Select.UIStroke.Thickness = thick
		self.UI.BG_Middle.Border.Visible = not value
		self.UI.BG_Middle.Select.UIStroke.Thickness = thick
	else
		self.UI.Select.UIStroke.Thickness = thick
		self.UI.Border.Visible = not value
	end
end

function Keyframe:IterateTargetValues(func)
	local allPos = {}
	for pos, _ in pairs(self.TargetValues) do
		table.insert(allPos, pos)
	end
	table.sort(allPos, function(a, b) return a < b end)

	for _, pos in pairs(allPos) do
		func(pos, self.TargetValues[pos], self.EaseMap[pos], pos + self.frm_pos)
	end
end

function Keyframe:GetTargetValue()
	return self.TargetValues[self.width]
end

function Keyframe:SetTargetValue(TargetValue)
	self.TargetValues[self.width] = TargetValue
end

function Keyframe:GetEase()
	return self.EaseMap[self.width]
end

function Keyframe:SetEase(Ease)
	self.EaseMap[self.width]:Destroy()
	self.EaseMap[self.width] = Ease
	self:_UpdateAppearance()
end

return Keyframe
