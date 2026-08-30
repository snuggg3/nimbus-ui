--[[
	Label Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Label = {}
Label.__index = Label
setmetatable(Label, { __index = Core.BaseComponent })

function Label.new(section, options)
	local self = setmetatable(Core.BaseComponent.new("Label"), Label)
	
	self.Section = section
	self.Text = options.Text or ""
	self.Alignment = options.Alignment or "Left" -- "Left", "Center", "Right"
	self.TextSize = options.TextSize or Theme.Typography.Size.SM
	self.TextColor = options.TextColor or Theme.Colors.TextPrimary
	self.Font = options.Font or Theme.Typography.FontMedium
	
	self:BuildUI()
	
	return self
end

function Label:BuildUI()
	local alignmentMap = {
		Left = Enum.TextXAlignment.Left,
		Center = Enum.TextXAlignment.Center,
		Right = Enum.TextXAlignment.Right,
	}
	
	self.Instance = Utils.Create("TextLabel", {
		Name = "Label_" .. Utils.GenerateId(),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = self.Font,
		TextSize = self.TextSize,
		TextColor3 = self.TextColor,
		TextXAlignment = alignmentMap[self.Alignment] or Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = self.Text,
	})
	self.Instance.Parent = self.Section.ContentFrame
end

function Label:SetText(text: string)
	self.Text = text
	if self.Instance then
		self.Instance.Text = text
	end
end

function Label:SetColor(color: Color3)
	self.TextColor = color
	if self.Instance then
		self.Instance.TextColor3 = color
	end
end

function Label:Destroy()
	Core.BaseComponent.Destroy(self)
end

return Label