------------------------------------------------------------
	local GuiLib = {}; local _g = _G.MoonGlobal
------------------------------------------------------------
do
	function GuiLib:AddInput(button, params)
		button.Active = true
		
		if params.click then
			button.MouseButton1Click:Connect(params.click.func)
		end
		if params.focus_lost then
			button.FocusLost:Connect(params.focus_lost.func)
		end

		if params.hover then
			self:add_hover_ui(button, params.hover)
		end
		if params.scroll then
			self:add_scroll_ui(button, params.scroll)
		end
		if params.drag then
			self:add_drag_ui(button, params.drag)
		end
		if params.down then
			self:add_down_ui(button, params.down)
		end
	end

	function GuiLib:ClearInput(obj)
		if obj then
			if _g.GuiLib.drag_data.caller_obj == obj or _g.GuiLib.drag_data.ui == obj then
				_g.GuiLib:clear_drag()
			end
			if _g.GuiLib.hover_data.caller_obj == obj or _g.GuiLib.hover_data.ui == obj then
				_g.GuiLib:clear_hover()
			end
			if _g.GuiLib.up_data.caller_obj == obj or _g.GuiLib.up_data.ui == obj then
				_g.GuiLib:clear_up_ui()
			end
		else
			if _g.GuiLib.drag_data.caller_obj then
				_g.GuiLib:clear_drag()
			end
			if _g.GuiLib.hover_data.caller_obj then
				_g.GuiLib:clear_hover()
			end
			if _g.GuiLib.up_data.caller_obj then
				_g.GuiLib:clear_up_ui()
			end
		end
	end

	do
		GuiLib.hover_data = {
			ui = nil, caller_obj = nil,
			func_start = nil, func_ended = nil,
			con_focus = nil,
		}; local hover_data = GuiLib.hover_data
		function GuiLib:add_hover_ui(button, params)
			button.MouseEnter:Connect(function(x, y)
				start_hover(button, params)
			end)
			button.MouseMoved:Connect(function(x, y)
				start_hover(button, params)
			end)
			button.MouseLeave:Connect(function(x, y)
				if hover_data.ui == button then 
					self:clear_hover()
				end
			end)
		end
		function start_hover(button, params)
			if GuiLib.drag_data.started then return end
			if hover_data.ui == button then return end

			local clickoff_check = _g.ClickOff.CheckInBounds(_g.Mouse.X, _g.Mouse.Y)
			if clickoff_check and not button:IsDescendantOf(clickoff_check) then return end

			if hover_data.ui then GuiLib:clear_hover() end

			hover_data.func_start = params.func_start; hover_data.func_ended = params.func_ended
			hover_data.ui = button; hover_data.caller_obj = params.caller_obj
			if hover_data.func_start then
				hover_data.func_start(hover_data.caller_obj, hover_data.ui)
			end

			hover_data.con_focus = _g.input_serv.WindowFocusReleased:Connect(function() 
				GuiLib:clear_hover()
			end)
		end
		function GuiLib:clear_hover()
			assert(hover_data.ui ~= nil, "No hover.")

			hover_data.con_focus:Disconnect(); hover_data.con_focus = nil

			if hover_data.func_ended then
				hover_data.func_ended(hover_data.caller_obj, hover_data.ui)
			end
			hover_data.func_start = nil; hover_data.func_ended = nil
			hover_data.ui = nil; hover_data.caller_obj = nil
		end
	end

	do
		function GuiLib:add_scroll_ui(button, params)
			button.MouseWheelForward:Connect(function(x, y)
				params.func(1)
			end)
			button.MouseWheelBackward:Connect(function(x, y)
				params.func(-1)
			end)
		end
	end

	do
		GuiLib.drag_data = {
			ui = nil, mouse_but = nil, caller_obj = nil, pixel_delay = nil,
			func_start = nil, func_changed = nil, func_ended = nil,
			started = false, old_cam_state = nil, ini_pos = nil,
			con_rel = nil, con_move = nil, con_focus = nil,
		}; local drag_data = GuiLib.drag_data
		function GuiLib:add_drag_ui(button, params)
			if params.mouse_but == nil then params.mouse_but = Enum.UserInputType.MouseButton1 end
			if params.func_start == nil then params.func_start = _g.BLANK_FUNC end
			if params.func_changed == nil then params.func_changed = _g.BLANK_FUNC end
			if params.func_ended == nil then params.func_ended = _g.BLANK_FUNC end

			local function input_began(input)
				if self.drag_data.ui then return end
				_g.Input:ClearInput()

				drag_data.old_cam_state = workspace.CurrentCamera.CameraType; drag_data.ini_pos = input.Position
				workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

				drag_data.ui = params.pass_obj and params.pass_obj or button
				drag_data.caller_obj = params.caller_obj; drag_data.mouse_but = params.mouse_but; drag_data.pixel_delay = params.pixel_delay
				drag_data.func_start = params.func_start; drag_data.func_changed = params.func_changed; drag_data.func_ended = params.func_ended

				if params.render_loop then
					drag_data.con_move = _g.run_serv.RenderStepped:Connect(function(step)
						drag_tick(Vector3.new(_g.Mouse.X, _g.Mouse.Y, 0) - drag_data.ini_pos)
					end)
				else
					drag_data.con_move = _g.input_serv.InputChanged:Connect(function(input, proc)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							drag_tick(input.Position - drag_data.ini_pos)
						end
					end)
				end

				drag_data.con_rel = _g.input_serv.InputEnded:Connect(function(input, proc)
					if input.UserInputType == drag_data.mouse_but then
						self:clear_drag()
					end
				end)
				drag_data.con_focus = _g.input_serv.WindowFocusReleased:Connect(function() 
					self:clear_drag()
				end)
			end

			if params.mouse_but == Enum.UserInputType.MouseButton1 then
				button.MouseButton1Down:Connect(function(x, y) input_began({Position = Vector3.new(x, y, 0)}) end)
			else
				button.InputBegan:Connect(function(input)
					if input.UserInputType == params.mouse_but then
						input_began(input)
					end
				end)
			end
		end
		function drag_tick(delta)
			local drag_data = GuiLib.drag_data
			if not drag_data.started then
				if drag_data.pixel_delay == nil or math.abs(delta[drag_data.pixel_delay[1]]) >= drag_data.pixel_delay[2] then
					drag_data.started = true
					if GuiLib.hover_data.ui then GuiLib:clear_hover() end
					if GuiLib.up_data.ui then GuiLib:clear_up_ui() end
					drag_data.func_start(drag_data.caller_obj, drag_data.ui, drag_data.ini_pos)
					drag_data.func_changed(drag_data.caller_obj, drag_data.ui, delta)
				end
			else
				drag_data.func_changed(drag_data.caller_obj, drag_data.ui, delta)
			end
		end
		function GuiLib:clear_drag()
			assert(drag_data.ui ~= nil, "No drag.")

			local save_started = drag_data.started; local save_fe = drag_data.func_ended
			local save_co = drag_data.caller_obj; local save_ui = drag_data.ui

			drag_data.con_move:Disconnect();  drag_data.con_move = nil
			drag_data.con_rel:Disconnect();   drag_data.con_rel = nil
			drag_data.con_focus:Disconnect(); drag_data.con_focus = nil

			drag_data.func_start = nil; drag_data.func_changed = nil; drag_data.func_ended = nil

			drag_data.started = false
			workspace.CurrentCamera.CameraType = drag_data.old_cam_state
			drag_data.old_cam_state = nil
			drag_data.ini_pos = nil

			drag_data.caller_obj = nil; drag_data.ui = nil; drag_data.mouse_but = nil; drag_data.pixel_delay = nil

			if save_started then
				save_fe(save_co, save_ui)
			end
		end
	end

	do
		GuiLib.up_data = {
			ui = nil, mouse_but = nil, func = nil,
			con_rel = nil, con_leave = nil, con_focus = nil,
		}; local up_data = GuiLib.up_data
		function GuiLib:add_down_ui(button, params)
			if params.mouse_but == nil then params.mouse_but = Enum.UserInputType.MouseButton1 end

			local function input_began()
				if params.up_func then
					if not params.func() then
						up_data.ui = button; up_data.mouse_but = params.mouse_but; up_data.func = params.up_func

						up_data.con_rel = _g.input_serv.InputEnded:Connect(function(input, proc)
							if input.UserInputType == up_data.mouse_but then
								up_data.func()
								self:clear_up_ui()
							end
						end)
						up_data.con_leave = button.MouseLeave:Connect(function(x, y)
							self:clear_up_ui()
						end)
						up_data.con_focus = _g.input_serv.WindowFocusReleased:Connect(function() 
							self:clear_up_ui()
						end)
					end
				else
					params.func()
				end
			end

			if params.mouse_but == Enum.UserInputType.MouseButton1 then
				button.MouseButton1Down:Connect(input_began)
			else
				button.InputBegan:Connect(function(input)
					if input.UserInputType == params.mouse_but then
						input_began()
					end
				end)
			end
		end
		function GuiLib:clear_up_ui()
			assert(up_data.ui ~= nil, "No button up.")

			up_data.con_leave:Disconnect(); up_data.con_leave = nil
			up_data.con_rel:Disconnect();   up_data.con_rel = nil
			up_data.con_focus:Disconnect(); up_data.con_focus = nil

			up_data.ui = nil; up_data.mouse_but = nil; up_data.func = nil
		end
	end
end
------------------------------------------------------------
do
	function GuiLib:is_mouse_in(button)
		local ui_pos = button.AbsolutePosition; local ui_size = button.AbsoluteSize
		local mouse_pos = Vector2.new(_g.Mouse.X, _g.Mouse.Y)
		return (mouse_pos.X >= ui_pos.X and mouse_pos.X <= ui_pos.X + ui_size.X) and (mouse_pos.Y >= ui_pos.Y and mouse_pos.Y <= ui_pos.Y + ui_size.Y)
	end
end

return GuiLib
