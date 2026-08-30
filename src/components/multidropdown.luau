--[[
	Multi-Dropdown Component (Multiple Selection)
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local MultiDropdown = {}
MultiDropdown.__index = MultiDropdown
setmetatable(MultiDropdown, { __index = Core.BaseInteractive })

function MultiDropdown.new(section, options)
	local self = setmetatable(Core.BaseInteractive.new("MultiDropdown"), MultiDropdown)
	
	self.Section = section
	self.Name = options.Name or "MultiDropdown"
	self.Options = options.Options or {}
	self.Default = options.Default or {}
	self.Callback = options.Callback
	self.Flag = options.Flag
	self.Placeholder = options.Placeholder or "Select..."
	self.MaxVisibleOptions = options.MaxVisibleOptions or 6
	
	self.Value = {}
	self.Open = false
	self.OptionButtons = {}
	self.DropdownFrame = nil
	
	-- Initialize value
	for _, v in ipairs(self.Default) do
		if table.find(self.Options, v) then
			table.insert(self.Value, v)
		end
	end
	
	self:BuildUI()
	self:UpdateDisplay()
	
	return self
end

function MultiDropdown:BuildUI()
	-- Main container
	self.Instance = Utils.Create("Frame", {
		Name = "MultiDropdown_" .. self.Name,
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
			Image = "rbxassetid://10709790948",
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

function MultiDropdown:Toggle()
	if self.Open then
		self:Close()
	else
		self:Open()
	end
end

function MultiDropdown:Open()
	if self.Open then return end
	self.Open = true
	
	local library = self.Section.Tab.Window.Library
	self.DropdownFrame = Utils.Create("Frame", {
		Name = "MultiDropdownList_" .. Utils.GenerateId(),
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
	
	-- Position
	local buttonPos = self.Button.AbsolutePosition
	local buttonSize = self.Button.AbsoluteSize
	local screenSize = library.ScreenGui.AbsoluteSize
	
	local xPos = buttonPos.X
	local yPos = buttonPos.Y + buttonSize.Y + 4
	
	if yPos + 200 > screenSize.Y then
		yPos = buttonPos.Y - 4
	end
	
	self.DropdownFrame.Position = UDim2.fromOffset(xPos, yPos)
	self.DropdownFrame.Size = UDim2.new(0, buttonSize.X, 0, 0)
	
	-- Populate
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
	
	self.ScrollConn = Utils.GetService("UserInputService").InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			self:Close()
		end
	end)
end

function MultiDropdown:PopulateOptions()
	if not self.DropdownFrame then return end
	
	for _, btn in ipairs(self.OptionButtons) do
		btn:Destroy()
	end
	table.clear(self.OptionButtons)
	
	local visibleCount = 0
	for i, option in ipairs(self.Options) do
		if visibleCount >= self.MaxVisibleOptions then break end
		
		local isSelected = table.find(self.Value, option) ~= nil
		
		local btn = Utils.Create("Frame", {
			Name = "Option_" .. option,
			BackgroundColor3 = isSelected and Theme.Colors.PrimaryLight or Theme.Colors.Surface,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 32),
			LayoutOrder = i,
		}, {
			Utils.CreateCorner(Theme.Sizing.CornerRadiusSmall),
			Utils.CreatePadding({10, 0, 10, 0}),
			Utils.CreateListLayout(Enum.FillDirection.Horizontal, 8),
		})
		btn.Parent = self.DropdownFrame
		
		-- Checkbox
		local checkbox = Utils.Create("Frame", {
			Name = "Checkbox",
			BackgroundColor3 = isSelected and Theme.Colors.Primary or Theme.Colors.Surface,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 20, 0, 20),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
		}, {
			Utils.CreateCorner(4),
			Utils.CreateStroke(isSelected and Theme.Colors.Primary or Theme.Colors.InputBorder),
		})
		checkbox.Parent = btn
		
		-- Checkmark
		local checkmark = Utils.Create("ImageLabel", {
			Name = "Checkmark",
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 14, 0, 14),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://10709790644", -- Check icon
			ImageColor3 = Theme.Colors.TextOnPrimary,
			ImageTransparency = isSelected and 0 or 1,
		})
		checkmark.Parent = checkbox
		
		-- Label
		local label = Utils.Create("TextLabel", {
			Name = "Label",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -36, 1, 0),
			Font = Theme.Typography.FontMedium,
			TextSize = Theme.Typography.Size.SM,
			TextColor3 = Theme.Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = option,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		label.Parent = btn
		
		-- Click area
		local clickArea = Utils.Create("TextButton", {
			Name = "ClickArea",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 2,
		})
		clickArea.Parent = btn
		
		-- Hover effect
		Utils.ConnectHover(btn,
			function() Utils.TweenColor(btn, "BackgroundColor3", isSelected and Theme.Colors.Primary or Theme.Colors.BackgroundTertiary, Theme.Animation.Fast) end,
			function() Utils.TweenColor(btn, "BackgroundColor3", isSelected and Theme.Colors.PrimaryLight or Theme.Colors.Surface, Theme.Animation.Fast) end
		)
		
		-- Click handler
		self.Connections:Add(clickArea.MouseButton1Click:Connect(function()
			self:ToggleOption(option)
		end))
		
		table.insert(self.OptionButtons, btn)
		visibleCount += 1
	end
	
	local maxHeight = visibleCount * 32 + 8
	self.DropdownFrame.Size = UDim2.new(0, self.Button.AbsoluteSize.X, 0, math.min(maxHeight, 200))
end

function MultiDropdown:Close()
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
	
	local arrow = self.Button:FindFirstChild("Arrow")
	if arrow then
		Utils.Tween(arrow, { Rotation = 0 }, Theme.Animation.Fast)
	end
end

function MultiDropdown:ToggleOption(option: string)
	if not table.find(self.Options, option) then return end
	
	local index = table.find(self.Value, option)
	if index then
		table.remove(self.Value, index)
	else
		table.insert(self.Value, option)
	end
	
	self:UpdateDisplay()
	self:RefreshOptions()
	
	self:Fire("Changed", self.Value)
	Utils.SafeCallback(self.Callback, self.Value)
end

function MultiDropdown:RefreshOptions()
	if not self.Open or not self.DropdownFrame then return end
	
	for _, btn in ipairs(self.OptionButtons) do
		local option = btn.Name:gsub("Option_", "")
		local isSelected = table.find(self.Value, option) ~= nil
		
		btn.BackgroundColor3 = isSelected and Theme.Colors.PrimaryLight or Theme.Colors.Surface
		
		local checkbox = btn:FindFirstChild("Checkbox")
		if checkbox then
			checkbox.BackgroundColor3 = isSelected and Theme.Colors.Primary or Theme.Colors.Surface
			checkbox.UIStroke.Color = isSelected and Theme.Colors.Primary or Theme.Colors.InputBorder
			
			local checkmark = checkbox:FindFirstChild("Checkmark")
			if checkmark then
				Utils.TweenTransparency(checkmark, isSelected and 0 or 1, Theme.Animation.Fast)
			end
		end
	end
end

function MultiDropdown:UpdateDisplay()
	if #self.Value > 0 then
		self.Button.Text = table.concat(self.Value, ", ")
		self.Button.TextColor3 = Theme.Colors.TextPrimary
	else
		self.Button.Text = self.Placeholder
		self.Button.TextColor3 = Theme.Colors.TextMuted
	end
end

function MultiDropdown:SetOptions(options: {string}, default: {string}?)
	self.Options = options
	self.Default = default or {}
	
	-- Filter value to only valid options
	local newValue = {}
	for _, v in ipairs(self.Value) do
		if table.find(options, v) then
			table.insert(newValue, v)
		end
	end
	self.Value = newValue
	
	self:UpdateDisplay()
	
	if self.Open then
		self:PopulateOptions()
	end
end

function MultiDropdown:SetValue(value: {string}, fireCallback: boolean?)
	local newValue = {}
	for _, v in ipairs(value) do
		if table.find(self.Options, v) then
			table.insert(newValue, v)
		end
	end
	
	self.Value = newValue
	self:UpdateDisplay()
	self:RefreshOptions()
	
	if fireCallback ~= false then
		self:Fire("Changed", self.Value)
		Utils.SafeCallback(self.Callback, self.Value)
	end
end

function MultiDropdown:GetValue(): {string}
	return self.Value
end

function MultiDropdown:SetCallback(callback: ({string}) -> ())
	self.Callback = callback
end

function MultiDropdown:SetEnabled(enabled: boolean)
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

function MultiDropdown:Destroy()
	self:Close()
	Core.BaseInteractive.Destroy(self)
end

return MultiDropdown