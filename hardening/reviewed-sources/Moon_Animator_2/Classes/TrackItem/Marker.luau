local _g = _G.MoonGlobal; _g.req("TrackItem")
local Marker = super:new()

function Marker:new(frm_pos)
	local ctor = super:new(frm_pos and _g.new_ui.Marker_group:Clone() or nil, 0, frm_pos)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if frm_pos then
		ctor.name = ""
		ctor.codeBegin = ""
		ctor.codeEnd = ""
		ctor.KFMarkers = {}
		
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
		
		_g.GuiLib:AddInput(ctor.UI, {drag = {
			caller_obj = ctor, render_loop = true,
			func_start = super._TrackItemDragBegin, func_changed = super._TrackItemDragChanged, func_ended = super._TrackItemDragEnd,
		}})
	end

	return ctor
end

function Marker.Detableize(markerTbl)
	local newMarker = Marker:new(markerTbl.frm_pos)
	for propName, val in pairs(markerTbl) do
		if propName == "color" then
			newMarker:SetColor(val)
		elseif propName == "KFMarkers" then
			newMarker.KFMarkers = _g.deepcopy(val)
		elseif string.sub(propName, 1, 1) ~= "_" then
			newMarker[propName] = val
		end
	end
	return newMarker
end

function Marker.Deserialize(markerFolder)
	if tonumber(markerFolder.Name) == nil or markerFolder:FindFirstChild("width") == nil then 
		return false, 1
	end

	local NewMarker = Marker:new(tonumber(markerFolder.Name))

	for _, prop in pairs(markerFolder:GetChildren()) do
		if prop.Name == "KFMarkers" then
			for ind = 1, #prop:GetChildren() do
				local kfm = prop:FindFirstChild(ind)
				if kfm then
					table.insert(NewMarker.KFMarkers, {kfm.Value, kfm.Val.Value})
				end
			end
		else
			NewMarker[prop.Name] = prop.Value
		end
	end

	return NewMarker
end

function Marker:Destroy()
	if self.ParentTrack then
		self.ParentTrack:RemoveMarker(self)
	end
	super.Destroy(self)
end

function Marker:_Size(width)
	if width == nil then width = self.width end
	super._Size(self, width)
	self.UI.End.Visible = width > 0
end

function Marker:_SetSelect(value)
	super._SetSelect(self, value)
	
	local thick = value and 3 or 0
	
	self.UI.BG_Left.Border.Visible = not value
	self.UI.BG_Left.Select.UIStroke.Thickness = thick
	self.UI.BG_Right.Border.Visible = not value
	self.UI.BG_Right.Select.UIStroke.Thickness = thick
	self.UI.BG_Middle.Border.Visible = not value
	self.UI.BG_Middle.Select.UIStroke.Thickness = thick
end

function Marker:Tableize()
	return {_tblType = "Marker", frm_pos = self.frm_pos, name = self.name, width = self.width, codeBegin = self.codeBegin, codeEnd = self.codeEnd, KFMarkers = _g.deepcopy(self.KFMarkers)}
end

function Marker:Serialize()
	local markerFolder = Instance.new("Folder")
	markerFolder.Name = tostring(self.frm_pos)

	local widthVal = Instance.new("IntValue", markerFolder); widthVal.Name = "width"
	widthVal.Value = self.width

	if self.name ~= "" then
		local nameVal = Instance.new("StringValue", markerFolder); nameVal.Name = "name"
		nameVal.Value = self.name
	end
	if self.codeBegin ~= "" then
		local codeBeginVal = Instance.new("StringValue", markerFolder); codeBeginVal.Name = "codeBegin"
		codeBeginVal.Value = self.codeBegin
	end
	if self.codeEnd ~= "" then
		local codeEndVal = Instance.new("StringValue", markerFolder); codeEndVal.Name = "codeEnd"
		codeEndVal.Value = self.codeEnd
	end
	if #self.KFMarkers > 0 then
		local kfMarkerFolder = Instance.new("Folder", markerFolder)
		kfMarkerFolder.Name = "KFMarkers"

		for ind, kfMarker in pairs(self.KFMarkers) do
			local keyVal = Instance.new("StringValue", kfMarkerFolder)
			keyVal.Name = tostring(ind)
			keyVal.Value = kfMarker[1]

			local valueVal = Instance.new("StringValue", keyVal)
			valueVal.Name = "Val"
			valueVal.Value = kfMarker[2]
		end
	end

	return markerFolder
end

return Marker
