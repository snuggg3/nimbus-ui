--[[
	Button Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Button = {}
Button.__index = Button
setmetatable(Button, { __index = Core.BaseInteractive })

function Button.new(section, options)
	local self = setmetatable(Core.BaseInteractive.new("Button"), Button)
	
	self.Section = section
	self.Name = options.Name or "Button"
	self.Callback = options.Callback
	self.Disabled = options.Disabled or false
	
	self:BuildUI()
	
	if self.Disabled then
		self:SetEnabled(false)
	end
	
	return self
end

function Button:BuildUI()
	self.Instance = Utils.Create("TextButton", {
		Name = "Button_" .. self.Name,
		BackgroundColor3 = Theme.Colors.Primary,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, Theme.Sizing.Height),
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextOnPrimary,
		Text = self.Name,
		AutoButtonColor = false,
		Interactable = true,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadius),
	})
	self.Instance.Parent = self.Section.ContentFrame
	
	-- Setup hover/press animations
	self:SetupHoverAnimations(Theme.Colors.PrimaryHover, Theme.Colors.Primary)
	
	-- Click handler
	self.Connections:Add(self.Instance.MouseButton1Click:Connect(function()
		if self.Enabled then
			self:Fire("Click")
			Utils.SafeCallback(self.Callback)
		end
	end))
end

function Button:SetText(text: string)
	self.Name = text
	if self.Instance then
		self.Instance.Text = text
	end
end

function Button:SetCallback(callback: () -> ())
	self.Callback = callback
end

function Button:Destroy()
	Core.BaseInteractive.Destroy(self)
end

return Button