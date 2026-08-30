--[[
	Divider Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Divider = {}
Divider.__index = Divider
setmetatable(Divider, { __index = Core.BaseComponent })

function Divider.new(section, options)
	local self = setmetatable(Core.BaseComponent.new("Divider"), Divider)
	
	self.Section = section
	self.Text = options.Text or nil
	self.Thickness = options.Thickness or 1
	
	self:BuildUI()
	
	return self
end

function Divider:BuildUI()
	if self.Text then
		-- Divider with text in middle
		self.Instance = Utils.Create("Frame", {
			Name = "Divider_" .. Utils.GenerateId(),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
		}, {
			Utils.CreateListLayout(Enum.FillDirection.Horizontal, 8),
			Utils.Create("Frame", {
				Name = "LeftLine",
				BackgroundColor3 = Theme.Colors.SurfaceBorder,
				BorderSizePixel = 0,
				Size = UDim2.new(0.5, -4, 0, self.Thickness),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
			}),
			Utils.Create("TextLabel", {
				Name = "Text",
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.XY,
				Font = Theme.Typography.FontMedium,
				TextSize = Theme.Typography.Size.XS,
				TextColor3 = Theme.Colors.TextMuted,
				Text = self.Text,
			}),
			Utils.Create("Frame", {
				Name = "RightLine",
				BackgroundColor3 = Theme.Colors.SurfaceBorder,
				BorderSizePixel = 0,
				Size = UDim2.new(0.5, -4, 0, self.Thickness),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
			}),
		})
	else
		-- Simple divider line
		self.Instance = Utils.Create("Frame", {
			Name = "Divider_" .. Utils.GenerateId(),
			BackgroundColor3 = Theme.Colors.SurfaceBorder,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, self.Thickness),
		})
	end
	
	self.Instance.Parent = self.Section.ContentFrame
end

function Divider:SetText(text: string?)
	self.Text = text
	-- Would need to rebuild for text changes, not implemented for simplicity
end

function Divider:Destroy()
	Core.BaseComponent.Destroy(self)
end

return Divider