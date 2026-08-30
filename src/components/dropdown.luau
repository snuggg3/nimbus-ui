--[[
	Dropdown Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Dropdown = {}
Dropdown.__index = Dropdown
setmetatable(Dropdown, { __index = Core.BaseInteractive })

function Dropdown.new(section, options)
	local self = setmetatable(Core.BaseInteractive.new("Dropdown"), Dropdown)
	
	self.Section = section
	self.Name = options.Name or "Dropdown"
	self.Options = options.Options or {}
	self.Default = options.Default
	self.Callback = options.Callback
	self.Flag = options.Flag
	self.Placeholder = options.Placeholder or "Select..."
	self.MaxVisibleOptions = options.MaxVisibleOptions or 6
	
	self.Value = self.Default
	self.Open = false
	self.OptionButtons = {}
	self.DropdownFrame = nil
	
	-- Validate default
	if self.Value and not table.find(self.Options, self.Value) then
		self.Value = nil
	end
	if not self.Value and #self.Options > 0 then
		self.Value = self.Options[1]
	end
	
	self:BuildUI()
	self:UpdateDisplay()
	
	return self
end

function Dropdown:BuildUI()
	-- Main container
	self.Instance = Utils.Create("Frame", {
		Name = "Dropdown_" .. self.Name,
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
	
	-- Dropdown button
	self.Button = Utils.Create("TextButton", {
		Name = "Button",
		BackgroundColor3 = Theme.Colors.InputBackground,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, Theme.Sizing.Height),
		Position = UDim2.new(0, 0, 0, 20),
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = self.Placeholder,
		AutoButtonColor = false,
		ClipsDescendants = true,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadius),
		Utils.CreateStroke(Theme.Colors.InputBorder),
		Utils.CreatePadding({12, 0, 12, 0}),
		Utils.Create("ImageLabel", {
			Name = "Arrow",
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(1, -20, 0.5, -8),
			Image = "rbxassetid://10709790948", -- Chevron down
			ImageColor3 = Theme.Colors.TextSecondary,
		}),
	})
	self.Button.Parent = self.Instance
	
	-- Click handler
	self.Connections:Add(self.Button.MouseButton1Click:Connect(function()
		if self.Enabled then
			self:Toggle()
		end
	end))
	
	-- Hover effect
	Utils.ConnectHover(self.Button,
		function()
			if self.Enabled then
				Utils.TweenColor(self.Button, "BackgroundColor3", Theme.Colors.BackgroundSecondary, Theme.Animation.Fast)
				Utils.TweenColor(self.Button.UIStroke, "Color", Theme.Colors.PrimaryLight, Theme.Animation.Fast)
			end
		end,
		function()
			if self.Enabled then
				Utils.TweenColor(self.Button, "BackgroundColor3", Theme.Colors.InputBackground, Theme.Animation.Fast)
				Utils.TweenColor(self.Button.UIStroke, "Color", Theme.Colors.InputBorder, Theme.Animation.Fast)
			end
		end
	)
	
	-- Focus effect
	self.Connections:Add(self.Button.Focused:Connect(function()
		if self.Enabled then
			Utils.TweenColor(self.Button.UIStroke, "Color", Theme.Colors.InputBorderFocus, Theme.Animation.Fast)
			Utils.Tween(self.Button.UIStroke, { Thickness = Theme.Sizing.BorderWidthFocus }, Theme.Animation.Fast)
		end
	end))
	
	self.Connections:Add(self.Button.FocusLost:Connect(function()
		if self.Enabled then
			Utils.TweenColor(self.Button.UIStroke, "Color", Theme.Colors.InputBorder, Theme.Animation.Fast)
			Utils.Tween(self.Button.UIStroke, { Thickness = Theme.Sizing.BorderWidth }, Theme.Animation.Fast)
		end
	end))
end

function Dropdown:Toggle()
	if self.Open then
		self:Close()
	else
		self:Open()
	end
end

function Dropdown:Open()
	if self.Open then return end
	self.Open = true
	
	-- Create dropdown list in library's dropdown container
	local library = self.Section.Tab.Window.Library
	self.DropdownFrame = Utils.Create("Frame", {
		Name = "DropdownList_" .. Utils.GenerateId(),
		BackgroundColor3 = Theme.Colors.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(0, self.Button.AbsoluteSize.X, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		ZIndex = Theme.ZIndex.Dropdown,
		Visible = true,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadius),
		Utils.CreateStroke(Theme.Colors.SurfaceBorder),
		Utils.CreateListLayout(Enum.FillDirection.Vertical, 0),
		Utils.CreatePadding({4, 4, 4, 4}),
	})
	self.DropdownFrame.Parent = library.DropdownContainer
	
	-- Position dropdown below button
	local buttonPos = self.Button.AbsolutePosition
	local buttonSize = self.Button.AbsoluteSize
	local screenSize = library.ScreenGui.AbsoluteSize
	
	local xPos = buttonPos.X
	local yPos = buttonPos.Y + buttonSize.Y + 4
	
	-- Check if dropdown would go off screen
	if yPos + 200 > screenSize.Y then
		yPos = buttonPos.Y - 4 -- Open upward
	end
	
	self.DropdownFrame.Position = UDim2.fromOffset(xPos, yPos)
	self.DropdownFrame.Size = UDim2.new(0, buttonSize.X, 0, 0)
	
	-- Populate options
	self:PopulateOptions()
	
	-- Animate arrow
	local arrow = self.Button:FindFirstChild("Arrow")
	if arrow then
		Utils.Tween(arrow, { Rotation = 180 }, Theme.Animation.Fast)
	end
	
	-- Close on outside click
	self.OutsideClickConn = Utils.GetService("UserInputService").InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = Utils.GetInputPosition(input)
			if not Utils.IsMouseOver(self.Button, mousePos) and not Utils.IsMouseOver(self.DropdownFrame, mousePos) then
				self:Close()
			end
		end
	end)
	
	-- Close on scroll
	self.ScrollConn = Utils.GetService("UserInputService").InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			self:Close()
		end
	end)
end

function Dropdown:PopulateOptions()
	if not self.DropdownFrame then return end
	
	-- Clear existing
	for _, btn in ipairs(self.OptionButtons) do
		btn:Destroy()
	end
	table.clear(self.OptionButtons)
	
	local visibleCount = 0
	for i, option in ipairs(self.Options) do
		if visibleCount >= self.MaxVisibleOptions then break end
		
		local isSelected = option == self.Value
		
		local btn = Utils.Create("TextButton", {
			Name = "Option_" .. option,
			BackgroundColor3 = isSelected and Theme.Colors.PrimaryLight or Theme.Colors.Surface,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 32),
			Font = Theme.Typography.FontMedium,
			TextSize = Theme.Typography.Size.SM,
			TextColor3 = isSelected and Theme.Colors.TextOnPrimary or Theme.Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = option,
			AutoButtonColor = false,
			LayoutOrder = i,
		}, {
			Utils.CreateCorner(Theme.Sizing.CornerRadiusSmall),
			Utils.CreatePadding({10, 0, 10, 0}),
		})
		btn.Parent = self.DropdownFrame
		
		-- Hover effect
		Utils.ConnectHover(btn,
			function() Utils.TweenColor(btn, "BackgroundColor3", isSelected and Theme.Colors.Primary or Theme.Colors.BackgroundTertiary, Theme.Animation.Fast) end,
			function() Utils.TweenColor(btn, "BackgroundColor3", isSelected and Theme.Colors.PrimaryLight or Theme.Colors.Surface, Theme.Animation.Fast) end
		)
		
		-- Click handler
		self.Connections:Add(btn.MouseButton1Click:Connect(function()
			self:SelectOption(option)
			self:Close()
		end))
		
		table.insert(self.OptionButtons, btn)
		visibleCount += 1
	end
	
	-- Limit height
	local maxHeight = visibleCount * 32 + 8
	self.DropdownFrame.Size = UDim2.new(0, self.Button.AbsoluteSize.X, 0, math.min(maxHeight, 200))
end

function Dropdown:Close()
	if not self.Open then return end
	self.Open = false
	
	if self.DropdownFrame then
		self.DropdownFrame:Destroy()
		self.DropdownFrame = nil
	end
	
	if self.OutsideClickConn then
		self.OutsideClickConn:Disconnect()
		self.OutsideClickConn = nil
	end
	
	if self.ScrollConn then
		self.ScrollConn:Disconnect()
		self.ScrollConn = nil
	end
	
	-- Animate arrow back
	local arrow = self.Button:FindFirstChild("Arrow")
	if arrow then
		Utils.Tween(arrow, { Rotation = 0 }, Theme.Animation.Fast)
	end
end

function Dropdown:SelectOption(option: string)
	if not table.find(self.Options, option) then return end
	
	self.Value = option
	self:UpdateDisplay()
	
	self:Fire("Changed", option)
	Utils.SafeCallback(self.Callback, option)
end

function Dropdown:UpdateDisplay()
	if self.Value then
		self.Button.Text = self.Value
		self.Button.TextColor3 = Theme.Colors.TextPrimary
	else
		self.Button.Text = self.Placeholder
		self.Button.TextColor3 = Theme.Colors.TextMuted
	end
end

function Dropdown:SetOptions(options: {string}, default: string?)
	self.Options = options
	self.Default = default
	
	-- Validate current value
	if self.Value and not table.find(self.Options, self.Value) then
		self.Value = default or (options[1] or nil)
	end
	
	self:UpdateDisplay()
	
	-- Refresh if open
	if self.Open then
		self:PopulateOptions()
	end
end

function Dropdown:SetValue(value: string, fireCallback: boolean?)
	if value and not table.find(self.Options, value) then return end
	
	self.Value = value
	self:UpdateDisplay()
	
	if fireCallback ~= false then
		self:Fire("Changed", value)
		Utils.SafeCallback(self.Callback, value)
	end
end

function Dropdown:GetValue(): string?
	return self.Value
end

function Dropdown:SetCallback(callback: (string?) -> ())
	self.Callback = callback
end

function Dropdown:SetEnabled(enabled: boolean)
	self.Enabled = enabled
	if self.Instance then
		self.Button.Interactable = enabled
		local transparency = enabled and 0 or 0.5
		Utils.TweenTransparency(self.Button, transparency, Theme.Animation.Fast)
	end
	
	if not enabled and self.Open then
		self:Close()
	end
end

function Dropdown:Destroy()
	self:Close()
	Core.BaseInteractive.Destroy(self)
end

return Dropdown