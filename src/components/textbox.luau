--[[
	Textbox Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Textbox = {}
Textbox.__index = Textbox
setmetatable(Textbox, { __index = Core.BaseInteractive })

function Textbox.new(section, options)
	local self = setmetatable(Core.BaseInteractive.new("Textbox"), Textbox)
	
	self.Section = section
	self.Name = options.Name or "Textbox"
	self.Default = options.Default or ""
	self.Placeholder = options.Placeholder or "Enter text..."
	self.Callback = options.Callback
	self.Flag = options.Flag
	self.Numeric = options.Numeric or false
	self.Finished = options.Finished or false -- Only callback on focus lost
	self.ClearTextOnFocus = options.ClearTextOnFocus or false
	
	self.Value = self.Default
	self.Focused = false
	
	self:BuildUI()
	self:UpdateDisplay()
	
	return self
end

function Textbox:BuildUI()
	-- Main container
	self.Instance = Utils.Create("Frame", {
		Name = "Textbox_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Theme.Sizing.Height + 20),
	})
	self.Instance.Parent = self.Section.ContentFrame
	
	-- Label
	self.Label = Utils.Create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = self.Name,
	})
	self.Label.Parent = self.Instance
	
	-- Textbox
	self.Input = Utils.Create("TextBox", {
		Name = "Input",
		BackgroundColor3 = Theme.Colors.InputBackground,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, Theme.Sizing.Height),
		Position = UDim2.new(0, 0, 0, 20),
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextPrimary,
		PlaceholderText = self.Placeholder,
		PlaceholderColor3 = Theme.Colors.InputPlaceholder,
		Text = self.Value,
		ClearTextOnFocus = self.ClearTextOnFocus,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadius),
		Utils.CreateStroke(Theme.Colors.InputBorder),
		Utils.CreatePadding({12, 0, 12, 0}),
	})
	self.Input.Parent = self.Instance
	
	-- Focus handling
	self.Connections:Add(self.Input.Focused:Connect(function()
		self.Focused = true
		if self.Enabled then
			Utils.TweenColor(self.Input.UIStroke, "Color", Theme.Colors.InputBorderFocus, Theme.Animation.Fast)
			Utils.Tween(self.Input.UIStroke, { Thickness = Theme.Sizing.BorderWidthFocus }, Theme.Animation.Fast)
		end
	end))
	
	self.Connections:Add(self.Input.FocusLost:Connect(function(enterPressed)
		self.Focused = false
		if self.Enabled then
			Utils.TweenColor(self.Input.UIStroke, "Color", Theme.Colors.InputBorder, Theme.Animation.Fast)
			Utils.Tween(self.Input.UIStroke, { Thickness = Theme.Sizing.BorderWidth }, Theme.Animation.Fast)
		end
		
		local text = self.Input.Text
		if self.Numeric then
			text = text:gsub("[^%d%.%-]", "")
		end
		
		if self.Finished or enterPressed then
			self:SetValue(text, true)
		else
			self:SetValue(text, false)
		end
	end))
	
	-- Text changed (for real-time if not Finished)
	self.Connections:Add(self.Input:GetPropertyChangedSignal("Text"):Connect(function()
		if not self.Finished and self.Focused then
			local text = self.Input.Text
			if self.Numeric then
				text = text:gsub("[^%d%.%-]", "")
				if text ~= self.Input.Text then
					self.Input.Text = text
				end
			end
			self:SetValue(text, false)
		end
	end))
	
	-- Hover effect
	Utils.ConnectHover(self.Input,
		function()
			if self.Enabled and not self.Focused then
				Utils.TweenColor(self.Input, "BackgroundColor3", Theme.Colors.BackgroundSecondary, Theme.Animation.Fast)
				Utils.TweenColor(self.Input.UIStroke, "Color", Theme.Colors.PrimaryLight, Theme.Animation.Fast)
			end
		end,
		function()
			if self.Enabled and not self.Focused then
				Utils.TweenColor(self.Input, "BackgroundColor3", Theme.Colors.InputBackground, Theme.Animation.Fast)
				Utils.TweenColor(self.Input.UIStroke, "Color", Theme.Colors.InputBorder, Theme.Animation.Fast)
			end
		end
	)
end

function Textbox:SetValue(value: string, fireCallback: boolean?)
	if self.Numeric then
		value = value:gsub("[^%d%.%-]", "")
	end
	
	self.Value = value
	self.Input.Text = value
	
	if fireCallback then
		self:Fire("Changed", value)
		Utils.SafeCallback(self.Callback, value)
	end
end

function Textbox:GetValue(): string
	return self.Value
end

function Textbox:SetCallback(callback: (string) -> ())
	self.Callback = callback
end

function Textbox:SetPlaceholder(placeholder: string)
	self.Placeholder = placeholder
	self.Input.PlaceholderText = placeholder
end

function Textbox:SetEnabled(enabled: boolean)
	self.Enabled = enabled
	if self.Instance then
		self.Input.Interactable = enabled
		local transparency = enabled and 0 or 0.5
		Utils.TweenTransparency(self.Input, transparency, Theme.Animation.Fast)
	end
end

function Textbox:Focus()
	self.Input:CaptureFocus()
end

function Textbox:Destroy()
	Core.BaseInteractive.Destroy(self)
end

return Textbox