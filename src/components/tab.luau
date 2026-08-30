--[[
	Tab Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Tab = {}
Tab.__index = Tab
setmetatable(Tab, { __index = Core.BaseComponent })

function Tab.new(window, options)
	local self = setmetatable(Core.BaseComponent.new("Tab"), Tab)
	
	self.Window = window
	self.Name = options.Name or "Tab"
	self.Icon = options.Icon
	
	self.Sections = {}
	self.ActiveSection = nil
	self.IsActive = false
	
	self:BuildUI()
	
	table.insert(window.Tabs, self)
	if #window.Tabs == 1 then
		self:Select()
	end
	
	return self
end

function Tab:BuildUI()
	-- Tab button
	self.TabButton = Utils.Create("TextButton", {
		Name = "TabButton_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 100, 1, 0),
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextSecondary,
		Text = self.Name,
		AutoButtonColor = false,
		LayoutOrder = #self.Window.Tabs,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadiusSmall),
		Utils.CreatePadding({0, 0, 16, 16}),
	})
	self.TabButton.Parent = self.Window.TabBar
	
	-- Active indicator
	self.Indicator = Utils.Create("Frame", {
		Name = "Indicator",
		BackgroundColor3 = Theme.Colors.Primary,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 3),
		Position = UDim2.new(0, 0, 1, -3),
		Visible = false,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadiusSmall),
	})
	self.Indicator.Parent = self.TabButton
	
	-- Tab content frame
	self.ContentFrame = Utils.Create("ScrollingFrame", {
		Name = "Content_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Colors.ScrollbarThumb,
		ScrollBarImageTransparency = 0.3,
		BorderSizePixel = 0,
		Visible = false,
	}, {
		Utils.CreateListLayout(Enum.FillDirection.Vertical, 12),
		Utils.CreatePadding({16, 16, 16, 16}),
	})
	self.ContentFrame.Parent = self.Window.TabContainer
	
	-- Auto canvas size
	Utils.AutoCanvasSize(self.ContentFrame)
	
	-- Tab button click
	self.Connections:Add(self.TabButton.MouseButton1Click:Connect(function()
		self:Select()
	end))
	
	-- Hover effect
	Utils.ConnectHover(self.TabButton,
		function() 
			if not self.IsActive then
				Utils.TweenColor(self.TabButton, "TextColor3", Theme.Colors.TextPrimary, Theme.Animation.Fast)
				Utils.TweenColor(self.TabButton, "BackgroundColor3", Theme.Colors.BackgroundTertiary, Theme.Animation.Fast)
			end
		end,
		function()
			if not self.IsActive then
				Utils.TweenColor(self.TabButton, "TextColor3", Theme.Colors.TextSecondary, Theme.Animation.Fast)
				Utils.TweenColor(self.TabButton, "BackgroundColor3", Color3.new(1,1,1), Theme.Animation.Fast)
			end
		end
	)
end

function Tab:Select()
	if self.Window.ActiveTab and self.Window.ActiveTab ~= self then
		self.Window.ActiveTab:Deselect()
	end
	
	self.IsActive = true
	self.Window.ActiveTab = self
	
	self.ContentFrame.Visible = true
	self.Indicator.Visible = true
	Utils.TweenColor(self.TabButton, "TextColor3", Theme.Colors.Primary, Theme.Animation.Fast)
	Utils.TweenColor(self.TabButton, "BackgroundColor3", Theme.Colors.Background, Theme.Animation.Fast)
	
	self:Fire("Selected")
end

function Tab:Deselect()
	self.IsActive = false
	self.ContentFrame.Visible = false
	self.Indicator.Visible = false
	Utils.TweenColor(self.TabButton, "TextColor3", Theme.Colors.TextSecondary, Theme.Animation.Fast)
	Utils.TweenColor(self.TabButton, "BackgroundColor3", Color3.new(1,1,1), Theme.Animation.Fast)
end

function Tab:CreateSection(options)
	local Section = require(script.Parent.section)
	return Section.new(self, options)
end

function Tab:Destroy()
	local index = table.find(self.Window.Tabs, self)
	if index then
		table.remove(self.Window.Tabs, index)
	end
	
	for _, section in ipairs(self.Sections) do
		section:Destroy()
	end
	
	Core.BaseComponent.Destroy(self)
end

return Tab