--// Executor compatability
cloneref = cloneref or function(...) return ... end

--// Services
local function GetService(Name) return cloneref(game:GetService(Name)) end
local HttpService = GetService('HttpService')
local RunService = GetService('RunService') :: RunService

local IsStudio = RunService:IsStudio()

local ThemeManager = {
	Folder = 'LinoriaLibSettings',
	Library = nil,
	BuiltInThemes = {
		['Default'] 		= { 1, HttpService:JSONDecode('{"BorderRadius":0,"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}') },
		['BBot'] 			= { 2, HttpService:JSONDecode('{"BorderRadius":0,"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
		['Fatality']		= { 3, HttpService:JSONDecode('{"BorderRadius":0,"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
		['Jester'] 			= { 4, HttpService:JSONDecode('{"BorderRadius":0,"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Mint'] 			= { 5, HttpService:JSONDecode('{"BorderRadius":0,"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
		['Tokyo Night'] 	= { 6, HttpService:JSONDecode('{"BorderRadius":0,"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
		['Ubuntu'] 			= { 7, HttpService:JSONDecode('{"BorderRadius":0,"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
		['Quartz'] 			= { 8, HttpService:JSONDecode('{"BorderRadius":0,"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
	},
	KeyFunctions = {
		["BorderRadius"] = function(Value)
			return UDim.new(0, Value)
		end,
	}
} 

-- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end
function ThemeManager:ApplyTheme(theme)
	local customThemeData = self:GetCustomTheme(theme)
	
	local data = customThemeData or self.BuiltInThemes[theme]
	if not data then return end
	
	local Library = self.Library
	local Options = Library.Options

	-- custom themes are just regular dictionaries instead of an array with { index, dictionary }

	local scheme = data[2]
	for idx, col in next, customThemeData or scheme do
		local Value = col
		local Type = typeof(col)
		
		--// Convert hex
		if Type == "string" then
			Value = Color3.fromHex(col)
		end
		
		Library[idx] = self:CheckKey(idx, Value)
		
		local Option = Options[idx]
		if not Option then continue end
		
		if Type == "string" then
			Options[idx]:SetValueRGB(Value)
		else
			Options[idx]:SetValue(Value)
		end
	end

	self:ThemeUpdate()
end

function ThemeManager:CheckKey(Key, Value)
	local Func = self.KeyFunctions[Key]
	if not Func then return Value end
	
	return Func(Value)
end

function ThemeManager:ThemeUpdate()
	local Library = self.Library
	local Options = Library.Options
	if not Options then return end
	
	-- This allows us to force apply themes without loading the themes tab :)
	local options = { 
		"FontColor", 
		"MainColor", 
		"AccentColor", 
		"BackgroundColor", 
		"OutlineColor",
		"BorderRadius"
	}
	
	for _, Field in next, options do
		local Option = Options[Field]
		if Option == nil then continue end
		
		local Value = Option.Value
		Library[Field] = self:CheckKey(Field, Value)
	end

	Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);
	Library:UpdateColorsUsingRegistry()
end

function ThemeManager:LoadDefault()		
	local Library = self.Library
	local Folder = self.Folder
	local Options = Library.Options
	
	local theme = 'Default'
	local content = not IsStudio and isfile(Folder .. '/themes/default.txt') and readfile(Folder .. '/themes/default.txt')

	local isDefault = true
	if content then
		if self.BuiltInThemes[content] then
			theme = content
		elseif self:GetCustomTheme(content) then
			theme = content
			isDefault = false;
		end
	elseif self.BuiltInThemes[self.DefaultTheme] then
		theme = self.DefaultTheme
	end

	if isDefault then
		Options.ThemeManager_ThemeList:SetValue(theme)
	else
		self:ApplyTheme(theme)
	end
end

function ThemeManager:SaveDefault(theme)
	if IsStudio then return end
	writefile(self.Folder .. '/themes/default.txt', theme)
end

function ThemeManager:CreateThemeManager(groupbox)
	local Library = self.Library
	local Options = Library.Options
	
	--// Theme options
	groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = Library.BackgroundColor });
	groupbox:AddLabel('Main color')	:AddColorPicker('MainColor', { Default = Library.MainColor });
	groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = Library.AccentColor });
	groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = Library.OutlineColor });
	groupbox:AddLabel('Font color')	:AddColorPicker('FontColor', { Default = Library.FontColor });
	groupbox:AddLabel('Font color')	:AddColorPicker('FontColor', { Default = Library.FontColor });
	groupbox:AddSlider('BorderRadius', { Text = 'Border Radius', Default = 0, Min = 0, Max = 20, Rounding = 0 });

	local ThemesArray = {}
	for Name, Theme in next, self.BuiltInThemes do
		table.insert(ThemesArray, Name)
	end

	table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

	groupbox:AddDivider()
	groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })

	groupbox:AddButton('Set as default', function()
		self:SaveDefault(Options.ThemeManager_ThemeList.Value)
		Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_ThemeList.Value))
	end)

	Options.ThemeManager_ThemeList:OnChanged(function()
		self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
	end)

	groupbox:AddDivider()
	groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
	groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
	groupbox:AddDivider()
	
	groupbox:AddButton('Save theme', function() 
		self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)

		Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
		Options.ThemeManager_CustomThemeList:SetValue(nil)
	end):AddButton('Load theme', function() 
		self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value) 
	end)
	groupbox:AddButton('Refresh list', function()
		Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
		Options.ThemeManager_CustomThemeList:SetValue(nil)
	end)
	groupbox:AddButton('Set as default', function()
		if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
			self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
			self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value))
		end
	end)

	ThemeManager:LoadDefault()

	local function UpdateTheme()
		self:ThemeUpdate()
	end
	
	--// Callback connections
	Options.BorderRadius:OnChanged(UpdateTheme)
	Options.BackgroundColor:OnChanged(UpdateTheme)
	Options.MainColor:OnChanged(UpdateTheme)
	Options.AccentColor:OnChanged(UpdateTheme)
	Options.OutlineColor:OnChanged(UpdateTheme)
	Options.FontColor:OnChanged(UpdateTheme)
end

function ThemeManager:GetCustomTheme(file)
	if IsStudio then return end
	
	local path = self.Folder .. '/themes/' .. file
	if not isfile(path) then
		return nil
	end

	local data = readfile(path)
	local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)

	if not success then
		return nil
	end

	return decoded
end

function ThemeManager:SaveCustomTheme(file)
	local Library = self.Library
	local Options = Library.Options
	
	if IsStudio then return end
	
	if file:gsub(' ', '') == '' then
		return Library:Notify('Invalid file name for theme (empty)', 3)
	end

	local theme = {}
	local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

	for _, field in next, fields do
		theme[field] = Options[field].Value:ToHex()
	end

	writefile(self.Folder .. '/themes/' .. file .. '.json', HttpService:JSONEncode(theme))
end

function ThemeManager:ReloadCustomThemes()
	if IsStudio then return {} end
	
	local list = listfiles(self.Folder .. '/themes')

	local out = {}
	for i = 1, #list do
		local file = list[i]
		if file:sub(-5) == '.json' then
			-- i hate this but it has to be done ...

			local pos = file:find('.json', 1, true)
			local char = file:sub(pos, pos)

			while char ~= '/' and char ~= '\\' and char ~= '' do
				pos = pos - 1
				char = file:sub(pos, pos)
			end

			if char == '/' or char == '\\' then
				table.insert(out, file:sub(pos + 1))
			end
		end
	end

	return out
end

function ThemeManager:SetLibrary(lib)
	self.Library = lib
end

function ThemeManager:BuildFolderTree()
	if IsStudio then return end
	
	local paths = {}

	-- build the entire tree if a path is like some-hub/phantom-forces
	-- makefolder builds the entire tree on Synapse X but not other exploits

	local parts = self.Folder:split('/')
	for idx = 1, #parts do
		paths[#paths + 1] = table.concat(parts, '/', 1, idx)
	end

	table.insert(paths, self.Folder .. '/themes')
	table.insert(paths, self.Folder .. '/settings')

	for i = 1, #paths do
		local str = paths[i]
		if not isfolder(str) then
			makefolder(str)
		end
	end
end

function ThemeManager:SetFolder(folder)
	self.Folder = folder
	self:BuildFolderTree()
end

function ThemeManager:CreateGroupBox(tab)
	assert(self.Library, 'Must set ThemeManager.Library first!')
	return tab:AddLeftGroupbox('Themes')
end

function ThemeManager:ApplyToTab(tab)
	assert(self.Library, 'Must set ThemeManager.Library first!')
	local groupbox = self:CreateGroupBox(tab)
	self:CreateThemeManager(groupbox)
end

function ThemeManager:ApplyToGroupbox(groupbox)
	assert(self.Library, 'Must set ThemeManager.Library first!')
	self:CreateThemeManager(groupbox)
end

ThemeManager:BuildFolderTree()


return ThemeManager
