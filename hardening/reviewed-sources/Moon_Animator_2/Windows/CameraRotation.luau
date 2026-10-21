local _g = _G.MoonGlobal
------------------------------------------------------------
	local Camera

	local IniCFrame
	local IniAngles
	
	local WindowData = _g.WindowData:new("Camera Rotation", script.Contents)
	local Win  = _g.Window:new(script.Name, WindowData)

	AngleInput:new(Win.g_e.X, 0, nil); local AngX = Win.g_e.X
	AngleInput:new(Win.g_e.Y, 0, nil); local AngY = Win.g_e.Y
	AngleInput:new(Win.g_e.Z, 0, nil); local AngZ = Win.g_e.Z

	Button:new(Win.g_e.Confirm)
------------------------------------------------------------
do
	Win.OnOpen = function()
		Camera = workspace.CurrentCamera
		IniCFrame = Camera.CFrame

		local x, y, z = Camera.CFrame:ToEulerAnglesXYZ()
		x = math.deg(x); y = math.deg(y); z = math.deg(z);
		IniAngles = Vector3.new(x, y, z)

		AngX:Set(x)
		AngY:Set(y)
		AngZ:Set(z)

		return true
	end
	Win.OnClose = function(save)
		if not save then
			Camera.CFrame = IniCFrame
		end
		return true
	end

	function AngleChanged(value)
		Camera.CameraType = Enum.CameraType.Scriptable
		Camera.CFrame = IniCFrame * CFrame.fromEulerAnglesXYZ(math.rad(AngX.Value - IniAngles.X), math.rad(AngY.Value - IniAngles.Y), math.rad(AngZ.Value - IniAngles.Z))
		Camera.CameraType = Enum.CameraType.Custom
	end
	AngX._changed = AngleChanged
	AngY._changed = AngleChanged
	AngZ._changed = AngleChanged

	Win.g_e.Confirm.OnClick = function()
		Win:Close(true)
	end
end

return Win
