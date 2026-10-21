local _g = _G.MoonGlobal; _g.req("Object")
local Window = super:new()

_g.CurrentWindowFocused = nil

function Window:new(name, WindowData)
	local ctor = super:new(name)
	table.insert(ctor.type, 1, script.Name)
	setmetatable(ctor, self)
	self.__index = self

	if name then
		getfenv(0).Win = ctor
		
		ctor.name = name
		ctor.WindowData = WindowData
		ctor.UI = nil
		ctor.Contents = nil
		ctor.TitleBarSize = 31
		ctor.g_e = {}
		ctor.MenuBar = nil
		ctor._position_set = false

		ctor.ChildModal = nil
		ctor.ModalParent = nil

		ctor.PaletteWindows = {}
		ctor.PaletteParent = nil

		ctor.Visible = false
		ctor.Focused = false

		ctor.OnClose = nil
		ctor.OnOpen = nil
		ctor.OnModalOpen = nil
		ctor.OnFocusLost = nil
		ctor.OnFocusGained = nil
		ctor.OnMouseDown = nil
			ctor.MouseDownCon = nil
		ctor.SelChangedCon = nil
		ctor.DeactiveCon = nil
		
		ctor.MouseEnabled = false
		ctor.NeedsMouse = WindowData.NeedsMouse

		ctor.ScreenGui = _g.new_ui.Window.Window:Clone()
		ctor.ScreenGui.Name = name
		ctor.UI = ctor.ScreenGui.Frame

		ctor:AddPaintedItem(ctor.UI.BG, {BackgroundColor3 = "bg"})
		ctor:AddPaintedItem(ctor.UI.Border, {BackgroundColor3 = "main"})

		if WindowData.PaletteWindows then
			ctor.PaletteWindows = WindowData.PaletteWindows
		end
		
		if WindowData.IsPalette then
			 ctor.TitleBarSize = 24
		end
		ctor.UI.TitleBar.Size = UDim2.new(1, -2, 0, ctor.TitleBarSize)
		ctor.UI.TitleBar.Title.Text = WindowData.title
		ctor.UI.Size = WindowData.Contents.Size + UDim2.new(0, 2, 0, 2)

		_g.GuiLib:AddInput(ctor.UI.TitleBar, {drag = {
			caller_obj = ctor, func_start = Window.WindowDragBegin, func_changed = Window.WindowDragChanged, func_ended = Window.WindowDragEnded,
		}})
		ctor:AddPaintedItem(ctor.UI.TitleBar, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.UI.TitleBar.Frame, {BackgroundColor3 = "second"})
		ctor:AddPaintedItem(ctor.UI.TitleBar.Title, {TextColor3 = "text"})
		
		ctor:AddPaintedItem(ctor.UI.Border.TopHover, {BackgroundColor3 = "highlight"})
		ctor:AddPaintedItem(ctor.UI.Border.BottomHover, {BackgroundColor3 = "highlight"})
		ctor:AddPaintedItem(ctor.UI.Border.LeftHover, {BackgroundColor3 = "highlight"})
		ctor:AddPaintedItem(ctor.UI.Border.RightHover, {BackgroundColor3 = "highlight"})

		if WindowData.img then
			local moon_img = _g.new_ui.Window.MoonImg:Clone(); ctor.moon_img = moon_img
			moon_img.Parent = ctor.UI.TitleBar
			
			ctor:AddPaintedItem(moon_img, {BackgroundColor3 = "bg"})
			ctor:AddPaintedItem(moon_img.Border.UIStroke, {Color = "main"})
			ctor:AddPaintedItem(moon_img.Circle1, {BackgroundColor3 = "main"})
			ctor:AddPaintedItem(moon_img.Circle2, {BackgroundColor3 = "bg"})
			
			ctor:AddPaintedItem(moon_img.Circle3, {BackgroundColor3 = "bg"})
			ctor:AddPaintedItem(moon_img.Circle4, {BackgroundColor3 = "bg"})
			ctor:AddPaintedItem(moon_img.Circle5, {BackgroundColor3 = "bg"})
			ctor:AddPaintedItem(moon_img.Circle6, {BackgroundColor3 = "bg"})
			ctor:AddPaintedItem(moon_img.Circle7, {BackgroundColor3 = "bg"})
			
			ctor.UI.TitleBar.Title.Size 	= UDim2.new(1, -60, 1, 0)
			ctor.UI.TitleBar.Title.Position = UDim2.new(0, 30, 0, -1)
		else
			ctor.UI.TitleBar.Title.Size 	 = UDim2.new(1, -22, 1, 0)
			ctor.UI.TitleBar.Title.Position = UDim2.new(0, 11, 0, -1)
		end

		for button, _ in pairs(WindowData.Buttons) do
			local getBut = _g.new_ui.Window.Buttons[button]:Clone()
			getBut.Parent = ctor.UI.TitleBar.TitleButtons
			if button == "Close" then
				_g.GuiLib:AddInput(getBut, {click = {func = function() Window.Close(ctor, false) end}})
				ctor:AddPaintedItem(getBut.Cross, {TextColor3 = "text"})
				_g.GuiLib:AddInput(getBut, {hover = {caller_obj = ctor,
					func_start = function()
						self:SetItemPaint(getBut.Cross, {TextColor3 = "highlight"}, 2 * _g.Themer.QUICK_TWEEN)
					end,
					func_ended = function()
						self:SetItemPaint(getBut.Cross, {TextColor3 = "text"}, 2 * _g.Themer.QUICK_TWEEN)
					end,
				}})
			end
		end
		
		ctor.Contents = ctor.UI.Contents
		for _, ui in pairs(WindowData.Contents:GetChildren()) do
			ui.Parent = ctor.Contents
		end
		WindowData.Contents:Destroy()
		getfenv(0).UI = ctor.Contents 

		for _, obj in pairs(ctor.Contents:GetDescendants()) do
			if obj.ClassName == "StringValue" and obj.Name == "Element" then
				ctor.g_e[obj.Parent.Name] = obj.Parent
				if obj.Value == "Section" then
					ctor:AddPaintedItem(obj.Parent, {BackgroundColor3 = "bg"})
					ctor:AddPaintedItem(obj.Parent.UIStroke, {Color = "third"})
				elseif obj.Value == "LabelFrame" then
					ctor:AddPaintedItem(obj.Parent.Background, {BackgroundColor3 = "bg"})
					ctor:AddPaintedItem(obj.Parent.Background.UIStroke, {Color = "third"})
					ctor:AddPaintedItem(obj.Parent.LabelFrame, {BackgroundColor3 = "bg"})
					ctor:AddPaintedItem(obj.Parent.LabelFrame.Label, {TextColor3 = "main"})
				elseif obj.Value == "Tip" then
					ctor:AddPaintedItem(obj.Parent, {TextColor3 = "main"})
				else
					getfenv(0)[obj.Value] = require(_g.class[obj.Value])
				end
			end
		end

		if WindowData.MenuBar then
			WindowData.MenuBar.Window = ctor
			ctor.MenuBar = WindowData.MenuBar
			ctor.MenuBar.UI.Parent = ctor.UI
			
			local menu_y = ctor.MenuBar.UI.Size.Y.Offset

			ctor.Contents.Position = ctor.Contents.Position + UDim2.new(0, 0, 0, menu_y + ctor.TitleBarSize)
			ctor.Contents.Size = ctor.Contents.Size + UDim2.new(0, 0, 0, -(menu_y + ctor.TitleBarSize))

			ctor.UI.Size = ctor.UI.Size + UDim2.new(0, 0, 0, menu_y + ctor.TitleBarSize)
		else
			ctor.UI.Size = ctor.UI.Size + UDim2.new(0, 0, 0, ctor.TitleBarSize)
			ctor.Contents.Position = ctor.Contents.Position + UDim2.new(0, 0, 0, ctor.TitleBarSize)
			ctor.Contents.Size = ctor.Contents.Size + UDim2.new(0, 0, 0, -(ctor.TitleBarSize))
		end

		for _, sizer in pairs(ctor.UI.Resizers:GetChildren()) do
			sizer.Visible = (WindowData.resize == true or WindowData.ResizeIncrement ~= nil)
			_g.GuiLib:AddInput(sizer, {
				drag = {
					caller_obj = ctor, func_start = Window.ResizeBegan, func_changed = Window.ResizeChanged, func_ended = Window.ResizeEnded,
				},
				down = {
					mouse_but = Enum.UserInputType.MouseButton3, func = function() ctor:SetSize(ctor.DefaultSize[1], ctor.DefaultSize[2]) end,
				},
				hover = {
					caller_obj = ctor, func_start = Window.ResizeHoverBegan, func_ended = Window.ResizeHoverEnded,
				},
			})
		end

		local focusFunc = function()
			Window.GetFocus(ctor)
		end
		_g.GuiLib:AddInput(ctor.UI.InputBlocker, {down = {func = focusFunc}})
		_g.GuiLib:AddInput(ctor.UI.TitleBar, {down = {func = focusFunc}})
		
		if ctor.Contents:FindFirstChild("MinSize") == nil then
			ctor.MinSize = {ctor.UI.Size.X.Offset, ctor.UI.Size.Y.Offset}
		else
			ctor.MinSize = {ctor.Contents.MinSize.Value.X, ctor.Contents.MinSize.Value.Y}
			ctor.Contents.MinSize:Destroy()
		end
		ctor.DefaultSize = {ctor.UI.Size.X.Offset, ctor.UI.Size.Y.Offset}

		_g.Input:BindAction(ctor, ctor.name.."_Close", function()
			Window.Close(ctor)
		end, {"Escape"}, false)
		
		if ctor.g_e.Confirm then
			_g.Input:BindAction(ctor, ctor.name.."_CloseEnter", function()
				Window.Close(ctor, true)
			end, {"Return"}, false)
		end
		
		ctor:_MorphWindowBasedOnFocus(false)
	end

	return ctor
end

function Window:Destroy()
	for _, PWin in pairs(self.PaletteWindows) do
		_g.Windows[PWin]:Destroy()
	end
	_g.Windows[self.name] = nil
	self.ScreenGui:Destroy()
	super.Destroy(self)
end

function Window:SetTitle(title)
	self.UI.TitleBar.Title.Text = title
end

do
	function Window:GetSavedValue(key, default)
		local value = _g.plugin:GetSetting("MoonAnimator2_"..self.name.."_"..key)
		if value == nil or value == "" then
			_g.plugin:SetSetting("MoonAnimator2_"..self.name.."_"..key, default)
			value = default
		end
		return value
	end

	function Window:SaveValue(key, value)
		_g.plugin:SetSetting("MoonAnimator2_"..self.name.."_"..key, value)
		return true
	end
end

do
	local tweenTime = _g.Themer.QUICK_TWEEN

	function Window:_MorphWindowBasedOnFocus(focus)
		if focus then
			if self.ModalParent then
				local cur = self
				repeat
					cur = cur.ModalParent
				until cur.ModalParent == nil
				repeat
					cur.ScreenGui.Parent = nil
					cur.ScreenGui.Parent = _g.window_folder
					if #cur.PaletteWindows > 0 then
						for _, PWin in pairs(cur.PaletteWindows) do
							_g.Windows[PWin].ScreenGui.Parent = nil
							_g.Windows[PWin].ScreenGui.Parent = _g.window_folder
						end
					end
					cur = cur.ChildModal
				until cur.ChildModal == nil
			end

			self.ScreenGui.Parent = nil
			self.ScreenGui.Parent = _g.window_folder

			if #self.PaletteWindows > 0 then
				for _, PWin in pairs(self.PaletteWindows) do
					_g.Windows[PWin]:_MorphWindowBasedOnFocus(focus)
				end
			end

			self:SetItemPaint(self.UI.TitleBar, {BackgroundColor3 = "second"}, tweenTime)
			self:SetItemPaint(self.UI.TitleBar.Frame, {BackgroundColor3 = "second"}, tweenTime)
			self:SetItemPaint(self.UI.Border, {BackgroundColor3 = "main"}, tweenTime)
			
			self.Focused = true

			if self.MenuBar then
				self.MenuBar:SetEnabled(true)
			end
			if self.moon_img then
				self:SetItemPaint(self.moon_img.Border.UIStroke, {Color = "main"}, 6 * tweenTime)
				self:SetItemPaint(self.moon_img.Circle1, {BackgroundColor3 = "main"}, 6 * tweenTime)
				_g.Themer:QuickTween(self.moon_img.Circle2, 6 * tweenTime, {Position = UDim2.new(0, 5, 0, -1)})
				_g.Themer:QuickTween(self.moon_img.Circle3, 3 * tweenTime, {BackgroundTransparency = 1})
				_g.Themer:QuickTween(self.moon_img.Circle4, 3 * tweenTime, {BackgroundTransparency = 1})
				_g.Themer:QuickTween(self.moon_img.Circle5, 3 * tweenTime, {BackgroundTransparency = 1})
				_g.Themer:QuickTween(self.moon_img.Circle6, 3 * tweenTime, {BackgroundTransparency = 1})
				_g.Themer:QuickTween(self.moon_img.Circle7, 3 * tweenTime, {BackgroundTransparency = 1})
			end
			self.UI.InputBlocker.Visible = false
			self.UI.Resizers.Visible = true
		else
			if #self.PaletteWindows > 0 then
				for _, PWin in pairs(self.PaletteWindows) do
					_g.Windows[PWin]:_MorphWindowBasedOnFocus(focus)
				end
			end

			self:SetItemPaint(self.UI.TitleBar, {BackgroundColor3 = "third"}, tweenTime)
			self:SetItemPaint(self.UI.TitleBar.Frame, {BackgroundColor3 = "third"}, tweenTime)
			self:SetItemPaint(self.UI.Border, {BackgroundColor3 = "second"}, tweenTime)

			if self.MenuBar then
				self.MenuBar:SetEnabled(false)
			end
			if self.moon_img then
				self:SetItemPaint(self.moon_img.Border.UIStroke, {Color = "highlight"}, 6 * tweenTime)
				self:SetItemPaint(self.moon_img.Circle1, {BackgroundColor3 = "highlight"}, 6 * tweenTime)
				_g.Themer:QuickTween(self.moon_img.Circle2, 6 * tweenTime, {Position = UDim2.new(0, 14, 0, -10)})
				_g.Themer:QuickTween(self.moon_img.Circle3, (math.random(80, 180) / 10) * tweenTime, {BackgroundTransparency = 0.9})
				_g.Themer:QuickTween(self.moon_img.Circle4, (math.random(80, 180) / 10) * tweenTime, {BackgroundTransparency = 0.9})
				_g.Themer:QuickTween(self.moon_img.Circle5, (math.random(80, 180) / 10) * tweenTime, {BackgroundTransparency = 0.9})
				_g.Themer:QuickTween(self.moon_img.Circle6, (math.random(80, 180) / 10) * tweenTime, {BackgroundTransparency = 0.9})
				_g.Themer:QuickTween(self.moon_img.Circle7, (math.random(80, 180) / 10) * tweenTime, {BackgroundTransparency = 0.9})
			end
			self.UI.InputBlocker.Visible = true
			self.UI.Resizers.Visible = false
		end
	end

	function Window:Open(args)
		if not self.Visible and self.OnOpen then
			local ret = self.OnOpen(args)
			if not ret then return false end
		end

		if not self.ModalParent and not self._position_set then
			self.UI.Position = UDim2.new(0, math.floor(workspace.CurrentCamera.ViewportSize.X / 2 - self.UI.Size.X.Offset / 2), 
										  0, math.floor(workspace.CurrentCamera.ViewportSize.Y / 2  - self.UI.Size.Y.Offset / 2))
			self._position_set = true
		end

		self.ScreenGui.Parent = _g.window_folder

		self.Visible = true

		self.UI.Position = UDim2.new(0, math.clamp(self.UI.Position.X.Offset, 1, workspace.CurrentCamera.ViewportSize.X - self.UI.Size.X.Offset - 1), 
									 0, math.clamp(self.UI.Position.Y.Offset, 1, workspace.CurrentCamera.ViewportSize.Y - self.UI.Size.Y.Offset - 1))

		if not self.PaletteParent then
			self:GetFocus(true)
		end
		
		if self.FocusedTextBox then
			task.delay(0, function()
				self.FocusedTextBox:CaptureFocus()
				self.FocusedTextBox.SelectionStart = 1
			end)
		end

		return true
	end

	function Window:OpenModal(Modal, args)
		assert(self.ChildModal == nil, "Window already has a Modal.")
		assert(Modal.ModalParent == nil, "Modal is already open in a Window.")
		
		self:SetHidden(false)
		
		if args and args.pos then
			Modal.UI.Position = UDim2.new(0, args.pos.X.Offset, 0, args.pos.Y.Offset)
		else
			Modal.UI.Position = UDim2.new(0, _g.Mouse.X - 10, 0, _g.Mouse.Y + 10)
		end

		self.ChildModal = Modal
		Modal.ModalParent = self
		local ret = Modal:Open(args)
		if not ret then
			self.ChildModal = nil
			Modal.ModalParent = nil
			return false
		end
		if self.OnModalOpen then
			self.OnModalOpen()
		end
		return true
	end

	function Window:Close(args)
		if not self.UI.Visible then self:SetHidden(false) return false end
		if self.ChildModal then return false end

		if self.Visible and self.OnClose then
			local ret = self.OnClose(args)
			if not ret then return false end
		end

		self:ReleaseFocus(self.ModalParent)

		self.Visible = false
		self.ScreenGui.Parent = nil

		if self.ModalParent then
			self.ModalParent.ChildModal = nil
			self.ModalParent:GetFocus()
			self.ModalParent = nil
		else
			if _g.Windows.MoonAnimator.Visible then
				_g.Windows.MoonAnimator:GetFocus()
			end
		end

		return true
	end

	function Window:Toggle(args)
		if not self.Visible then
			return self:Open(args)
		else
			return self:Close(false)
		end
	end
	
	function Window:SetHidden(value)
		self.UI.Visible = not value
		if value and not _g.no_hide_handles then
			_g.MouseFilter.Parent = nil
		else
			_g.MouseFilter.Parent = (self.NeedsMouse and self.Focused) and workspace.CurrentCamera or nil
		end
	end
	
	function Window:CaptureMouse()
		if self.Focused then
			game.Selection:Set({})
			_g.plugin:Activate(true)
			_g.MouseFilter.Parent = self.UI.Visible and workspace.CurrentCamera or nil

			local releaseFocusFunc = function() 
				self:ReleaseFocus()
			end

			self.SelChangedCon = game.Selection.SelectionChanged:Connect(releaseFocusFunc)
			self.DeactiveCon = _g.plugin.Deactivation:Connect(releaseFocusFunc)
			---------------------------------------------

			if self.OnMouseDown then
				self.MouseDownCon = _g.Mouse.Button1Down:Connect(self.OnMouseDown)
			end

			task.spawn(function()
				if _g.chs:GetCanUndo() or _g.chs:GetCanRedo() then
					_g.ResetUndoRedo()
				end
			end)
		end
	end
	
	function Window:ReleaseMouse(next_window)
		self.SelChangedCon:Disconnect()
		self.SelChangedCon = nil

		self.DeactiveCon:Disconnect()
		self.DeactiveCon = nil

		if self.MouseDownCon then
			self.MouseDownCon:Disconnect()
			self.MouseDownCon = nil
		end

		if next_window == nil or not next_window.NeedsMouse then
			_g.plugin:Deactivate()
			_g.MouseFilter.Parent = nil
			_g.Mouse.Icon = ""

			task.spawn(function()
				_g.ResetUndoRedo()
			end)
		end
	end
	
	function Window:SetMouseEnabled(value)
		self.MouseEnabled = value
		if self.Focused then
			if value and self.SelChangedCon == nil then
				self:CaptureMouse()
			elseif not value and self.SelChangedCon then
				self:ReleaseMouse()
			end
		end
	end

	function Window:GetFocus()
		if _g.CurrentWindowFocused == self then return end

		if self.ChildModal then
			self.ChildModal:GetFocus()
		elseif self.PaletteParent then
			self.PaletteParent:GetFocus()
		else
			if _g.CurrentWindowFocused then
				_g.CurrentWindowFocused:ReleaseFocus(self)
			end
			self:SetHidden(false)
			self:_MorphWindowBasedOnFocus(true)
			_g.CurrentWindowFocused = self
			
			if self.OnFocusGained then
				self.OnFocusGained()
			end

			if self.NeedsMouse and self.MouseEnabled then
				self:CaptureMouse()
			end
		end
	end

	function Window:ReleaseFocus(next_window)
		if _g.CurrentWindowFocused ~= self then return end

		_g.CurrentWindowFocused = nil
		self.Focused = false

		if self.OnFocusLost then
			self.OnFocusLost()
		end

		self:SetHidden(false)
		self:_MorphWindowBasedOnFocus(false)

		if self.NeedsMouse and self.MouseEnabled then
			self:ReleaseMouse(next_window)
		end
	end
end

do
	local iniDragPosition = nil

	function Window:WindowDragBegin(titleBar, ini_pos)
		local absPos = self.ScreenGui.Frame.AbsolutePosition
		self.ScreenGui.Frame.AnchorPoint = Vector2.new(0, 0)
		self.ScreenGui.Frame.Position = UDim2.new(0, absPos.X, 0, absPos.Y)

		iniDragPosition = titleBar.Parent.Position
	end
	function Window:WindowDragChanged(titleBar, changed)
		titleBar.Parent.Position = UDim2.new(0, iniDragPosition.X.Offset + changed.X, 0, iniDragPosition.Y.Offset + changed.Y)
	end
	function Window:WindowDragEnded(titleBar)
		
	end
end

do
	local Mouse = _g.Mouse

	local iniResizeSize = nil
	local changeX = {Right = 1, BottomRight = 1, TopRight = 1, Left = -1, BottomLeft = -1, TopLeft = -1}
	local changeY = {BottomRight = 1, Bottom = 1, BottomLeft = 1, Top = -1, TopRight = -1, TopLeft = -1}
	
	function Window:SetSize(x, y)
		self.UI.Size = UDim2.new(0, x, 0, y)
	end

	function Window:ResizeHoverBegan(sizer)
		if not self.Focused then return end

		if string.find(sizer.Name, "Top") then
			_g.Themer:QuickTween(self.UI.Border.TopHover, 5 * _g.Themer.QUICK_TWEEN, {BackgroundTransparency = 0}, true)
		elseif string.find(sizer.Name, "Bottom") then
			_g.Themer:QuickTween(self.UI.Border.BottomHover, 5 * _g.Themer.QUICK_TWEEN, {BackgroundTransparency = 0}, true)
		end

		if string.find(sizer.Name, "Left") then
			_g.Themer:QuickTween(self.UI.Border.LeftHover, 5 * _g.Themer.QUICK_TWEEN, {BackgroundTransparency = 0}, true)
		elseif string.find(sizer.Name, "Right") then
			_g.Themer:QuickTween(self.UI.Border.RightHover, 5 * _g.Themer.QUICK_TWEEN, {BackgroundTransparency = 0}, true)
		end
	end
	function Window:ResizeHoverEnded(sizer)
		_g.Themer:QuickTween(self.UI.Border.TopHover, 5 * _g.Themer.QUICK_TWEEN, {BackgroundTransparency = 1})
		_g.Themer:QuickTween(self.UI.Border.BottomHover, 5 * _g.Themer.QUICK_TWEEN, {BackgroundTransparency = 1})
		_g.Themer:QuickTween(self.UI.Border.LeftHover, 5 * _g.Themer.QUICK_TWEEN, {BackgroundTransparency = 1})
		_g.Themer:QuickTween(self.UI.Border.RightHover, 5 * _g.Themer.QUICK_TWEEN, {BackgroundTransparency = 1})
	end

	function Window:ResizeBegan(sizer)
		local frame = sizer.Parent.Parent
		iniResizeSize = frame.Size

		if not self.Focused then return end

		local absPos = self.ScreenGui.Frame.AbsolutePosition
		self.ScreenGui.Frame.AnchorPoint = Vector2.new(0, 0)
		self.ScreenGui.Frame.Position = UDim2.new(0, absPos.X, 0, absPos.Y)

		if sizer.Name == "Top" or sizer.Name == "TopRight" then
			frame.AnchorPoint = Vector2.new(0, 1)
			frame.Position = UDim2.new(0, frame.Position.X.Offset, 0, frame.Position.Y.Offset + frame.Size.Y.Offset)
		elseif sizer.Name == "Left" or sizer.Name == "BottomLeft" then
			frame.AnchorPoint = Vector2.new(1, 0)
			frame.Position = UDim2.new(0, frame.Position.X.Offset + frame.Size.X.Offset, 0, frame.Position.Y.Offset)
		elseif sizer.Name == "TopLeft" then
			frame.AnchorPoint = Vector2.new(1, 1)
			frame.Position = UDim2.new(0, frame.Position.X.Offset + frame.Size.X.Offset, 0, frame.Position.Y.Offset + frame.Size.Y.Offset)
		end
	end
	function Window:ResizeChanged(sizer, changed)
		if not self.Focused then return end

		local frame = sizer.Parent.Parent

		local xChange = changed.X
		local yChange = changed.Y
		if self.WindowData.ResizeIncrement and self.WindowData.ResizeIncrement.X > 0 then
			xChange = _g.round(xChange, self.WindowData.ResizeIncrement.X)
		end
		if self.WindowData.ResizeIncrement and self.WindowData.ResizeIncrement.Y > 0 then
			yChange = _g.round(yChange, self.WindowData.ResizeIncrement.Y)
		end

		local finalX = iniResizeSize.X.Offset + xChange * (changeX[sizer.Name] ~= nil and changeX[sizer.Name] or 0)
		if finalX < self.MinSize[1] then
			finalX = self.MinSize[1]
		end 
		local finalY = iniResizeSize.Y.Offset + yChange * (changeY[sizer.Name] ~= nil and changeY[sizer.Name] or 0)
		if finalY < self.MinSize[2] then
			finalY = self.MinSize[2]
		end 

		sizer.Parent.Parent.Size = UDim2.new(0, finalX, 0, finalY)
	end
	function Window:ResizeEnded(sizer)
		if not self.Focused then return end

		local frame = sizer.Parent.Parent

		if frame.AnchorPoint.X == 1 then
			frame.AnchorPoint = Vector2.new(0, frame.AnchorPoint.Y)
			frame.Position = UDim2.new(0, frame.Position.X.Offset - frame.Size.X.Offset, 0, frame.Position.Y.Offset)
		end
		if frame.AnchorPoint.Y == 1 then
			frame.AnchorPoint = Vector2.new(0, 0)
			frame.Position = UDim2.new(0, frame.Position.X.Offset, 0, frame.Position.Y.Offset - frame.Size.Y.Offset)
		end
	end
end

return Window
