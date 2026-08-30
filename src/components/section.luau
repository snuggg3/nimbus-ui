--[[
	Section Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Section = {}
Section.__index = Section
setmetatable(Section, { __index = Core.BaseComponent })

function Section.new(tab, options)
	local self = setmetatable(Core.BaseComponent.new("Section"), Section)
	
	self.Tab = tab
	self.Name = options.Name or "Section"
	self.Side = options.Side or "Left"
	
	self.Elements = {}
	
	self:BuildUI()
	
	table.insert(tab.Sections, self)
	
	return self
end

function Section:BuildUI()
	self.Instance = Utils.Create("Frame", {
		Name = "Section_" .. self.Name,
		BackgroundColor3 = Theme.Colors.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadius),
		Utils.CreateStroke(Theme.Colors.SurfaceBorder),
		Utils.CreateListLayout(Enum.FillDirection.Vertical, 8),
		Utils.CreatePadding({12, 12, 12, 12}),
	})
	self.Instance.Parent = self.Tab.ContentFrame
	
	-- Section header
	if self.Name and self.Name ~= "" then
		local header = Utils.Create("Frame", {
			Name = "Header",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, {
			Utils.CreateListLayout(Enum.FillDirection.Horizontal, 8),
		})
		header.Parent = self.Instance
		
		local title = Utils.Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.XY,
			Font = Theme.Typography.FontSemibold,
			TextSize = Theme.Typography.Size.SM,
			TextColor3 = Theme.Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = self.Name,
		})
		title.Parent = header
		
		-- Divider line
		local divider = Utils.Create("Frame", {
			Name = "Divider",
			BackgroundColor3 = Theme.Colors.SurfaceBorder,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1),
		})
		divider.Parent = header
	end
	
	-- Content container
	self.ContentFrame = Utils.Create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		Utils.CreateListLayout(Enum.FillDirection.Vertical, 8),
	})
	self.ContentFrame.Parent = self.Instance
end

-- Generic element creator
function Section:AddElement(element)
	table.insert(self.Elements, element)
	element:SetParent(self)
	return element
end

-- Button
function Section:CreateButton(options)
	local Button = require(script.Parent.button)
	return self:AddElement(Button.new(self, options))
end

-- Toggle
function Section:CreateToggle(options)
	local Toggle = require(script.Parent.toggle)
	return self:AddElement(Toggle.new(self, options))
end

-- Slider
function Section:CreateSlider(options)
	local Slider = require(script.Parent.slider)
	return self:AddElement(Slider.new(self, options))
end

-- Dropdown
function Section:CreateDropdown(options)
	local Dropdown = require(script.Parent.dropdown)
	return self:AddElement(Dropdown.new(self, options))
end

-- MultiDropdown
function Section:CreateMultiDropdown(options)
	local MultiDropdown = require(script.Parent.multidropdown)
	return self:AddElement(MultiDropdown.new(self, options))
end

-- Textbox
function Section:CreateTextbox(options)
	local Textbox = require(script.Parent.textbox)
	return self:AddElement(Textbox.new(self, options))
end

-- Keybind
function Section:CreateKeybind(options)
	local Keybind = require(script.Parent.keybind)
	return self:AddElement(Keybind.new(self, options))
end

-- Label
function Section:CreateLabel(options)
	local Label = require(script.Parent.label)
	return self:AddElement(Label.new(self, options))
end

-- Divider
function Section:CreateDivider(options)
	local Divider = require(script.Parent.divider)
	return self:AddElement(Divider.new(self, options))
end

function Section:Destroy()
	for _, element in ipairs(self.Elements) do
		element:Destroy()
	end
	Core.BaseComponent.Destroy(self)
end

return Section