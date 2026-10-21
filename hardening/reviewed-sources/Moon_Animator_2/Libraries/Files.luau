local _g = _G.MoonGlobal
local Files = {}

------------------------------------------------------------
	local SS = game:GetService("ServerStorage")
	local root_folder
------------------------------------------------------------
do
	Files.RefreshFiles = function()
		if SS:FindFirstChild("MoonAnimatorSaves") then
			SS.MoonAnimatorSaves.Name = "MoonAnimator2Saves"
		end
		root_folder = SS:FindFirstChild("MoonAnimator2Saves")
		if not root_folder then
			Files.GetRoot()
		end
		local function scan(dir)
			for _, file in pairs(dir:GetChildren()) do
				if file.ClassName == "StringValue" and string.sub(file.Name, #file.Name - 5, #file.Name) == ".xsixx" then
					file.Name = file.Name:sub(1, #file.Name - 6) -- subtract the six
				elseif file.ClassName == "Folder" then
					scan(file)
				end
			end
		end
		scan(root_folder)
	end
	
	Files.GetRoot = function()
		if root_folder then
			return root_folder
		end
		root_folder = Instance.new("Folder"); root_folder.Name = "MoonAnimator2Saves"
		return root_folder
	end

	Files.NewFile = function(name, file_type)
		local file = Instance.new("StringValue")
		file.Name = name
		local Data = {}
		if file_type == "moon2" then
			Data.Information = {
				  Length = _g.DEFAULT_FRAMES,
				  Looped = false,
		  ExportPriority = "Action",
				Modified = os.time(),
				 Created = os.time(),
			}
			Data.Items = {}
		end
		file.Value = game:GetService("HttpService"):JSONEncode(Data)
		return file
	end

	Files.OpenFile = function(file)
		local tryOpen
		local succ, err = pcall(function() tryOpen = game:GetService("HttpService"):JSONDecode(file.Value) end)
		if not succ or type(tryOpen) ~= "table" then return nil end
		if tryOpen.Information == nil then return nil end
		return tryOpen 
	end
end

return Files
