--[[
	All UI Components for the library
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Components = {}

-- ============================================
-- Window Component
-- ============================================

local Window = {}
Window.__index = Window
setmetatable(Window, { __index = Core.BaseComponent })

function Window.new(library, options)
	local self = setmetatable(Core.BaseComponent.new("Window"), Window)
	
	self.Library = library
	self.Title = options.Title or "Window"
	self.Size = options.Size or Vector2.new(580, 460)
	self.Position = options.Position or UDim2.new(0.5, -self.Size.X/2, 0.5, -self.Size.Y/2)
	self.MinSize = options.MinSize or Vector2.new(400, 300)
	
	self.Tabs = {}
	self.ActiveTab = nil
	self.TabButtons = {}
	self.Minimized = false
	self.DragConnection = nil
	self.ResizeConnection = nil
	
	-- Create window UI
	self:BuildUI()
	
	-- Register with library
	table.insert(library.Windows, self)
	library.ActiveWindow = self
	
	return self
end

function Window:BuildUI()
	-- Main window frame
	self.Instance = Utils.Create("Frame", {
		Name = "Window_" .. Utils.GenerateId(),
		BackgroundColor3 = Theme.Colors.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(0, self.Size.X, 0, self.Size.Y),
		Position = self.Position,
		ClipsDescendants = true,
		Active = true,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadius),
		Utils.CreateStroke(Theme.Colors.SurfaceBorder),
	})
	
	-- Shadow
	local shadow = Utils.Create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = Theme.Colors.Shadow,
		ImageTransparency = Theme.Sizing.ShadowTransparency,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		Size = UDim2.new(1, 24, 1, 24),
		Position = UDim2.new(0, -12, 0, -12),
		ZIndex = -1,
	})
	shadow.Parent = self.Instance
	
	-- Title bar
	local titleBar = Utils.Create("Frame", {
		Name = "TitleBar",
		BackgroundColor3 = Theme.Colors.BackgroundSecondary,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadius),
		Utils.Create("Frame", { -- Corner cover for bottom
			BackgroundColor3 = Theme.Colors.BackgroundSecondary,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, Theme.Sizing.CornerRadius),
			Position = UDim2.new(0, 0, 1, -Theme.Sizing.CornerRadius),
		}),
	})
	titleBar.Parent = self.Instance
	
	-- Title text
	local titleLabel = Utils.Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		Font = Theme.Typography.FontSemibold,
		TextSize = Theme.Typography.Size.MD,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = self.Title,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	titleLabel.Parent = titleBar
	
	-- Window controls (minimize, close)
	local controls = Utils.Create("Frame", {
		Name = "Controls",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 80, 1, 0),
		Position = UDim2.new(1, -80, 0, 0),
	}, {
		Utils.CreateListLayout(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right),
		Utils.CreatePadding({8, 8, 8, 8}),
	})
	controls.Parent = titleBar
	
	-- Minimize button
	local minimizeBtn = Utils.Create("TextButton", {
		Name = "Minimize",
		BackgroundColor3 = Theme.Colors.BackgroundTertiary,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 28, 0, 28),
		Font = Theme.Typography.FontBold,
		TextSize = 16,
		TextColor3 = Theme.Colors.TextSecondary,
		Text = "−",
		AutoButtonColor = false,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadiusSmall),
	})
	minimizeBtn.Parent = controls
	
	-- Close button
	local closeBtn = Utils.Create("TextButton", {
		Name = "Close",
		BackgroundColor3 = Theme.Colors.BackgroundTertiary,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 28, 0, 28),
		Font = Theme.Typography.FontBold,
		TextSize = 14,
		TextColor3 = Theme.Colors.TextSecondary,
		Text = "✕",
		AutoButtonColor = false,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadiusSmall),
	})
	closeBtn.Parent = controls
	
	-- Content area
	local contentFrame = Utils.Create("Frame", {
		Name = "Content",
		BackgroundColor3 = Theme.Colors.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -44),
		Position = UDim2.new(0, 0, 0, 44),
		ClipsDescendants = true,
	})
	contentFrame.Parent = self.Instance
	
	-- Tab bar
	local tabBar = Utils.Create("Frame", {
		Name = "TabBar",
		BackgroundColor3 = Theme.Colors.BackgroundSecondary,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
	}, {
		Utils.CreateListLayout(Enum.FillDirection.Horizontal, 0, Enum.HorizontalAlignment.Left),
		Utils.CreatePadding({8, 0, 8, 0}),
	})
	tabBar.Parent = contentFrame
	
	-- Tab content container
	local tabContainer = Utils.Create("Frame", {
		Name = "TabContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -40),
		Position = UDim2.new(0, 0, 0, 40),
	})
	tabContainer.Parent = contentFrame
	
	-- Resize handle
	local resizeHandle = Utils.Create("Frame", {
		Name = "ResizeHandle",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(1, -20, 1, -20),
		ZIndex = 10,
	})
	resizeHandle.Parent = self.Instance
	
	-- Store references
	self.TitleBar = titleBar
	self.TitleLabel = titleLabel
	self.MinimizeBtn = minimizeBtn
	self.CloseBtn = closeBtn
	self.ContentFrame = contentFrame
	self.TabBar = tabBar
	self.TabContainer = tabContainer
	self.ResizeHandle = resizeHandle
	
	-- Setup interactions
	self:SetupInteractions()
end

function Window:SetupInteractions()
	-- Drag window
	self.DragConnection = Utils.MakeDraggable(self.Instance, self.TitleBar)
	
	-- Resize window
	local resizing = false
	local resizeStart = Vector2.zero
	local startSize = Vector2.zero
	
	self.ResizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 
			or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = Utils.GetInputPosition(input)
			startSize = Vector2.new(self.Instance.AbsoluteSize.X, self.Instance.AbsoluteSize.Y)
		end
	end)
	
	Utils.GetService("UserInputService").InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = Utils.GetInputPosition(input) - resizeStart
			local newWidth = math.max(self.MinSize.X, startSize.X + delta.X)
			local newHeight = math.max(self.MinSize.Y, startSize.Y + delta.Y)
			self.Instance.Size = UDim2.new(0, newWidth, 0, newHeight)
			self.Size = Vector2.new(newWidth, newHeight)
		end
	end)
	
	Utils.GetService("UserInputService").InputEnded:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			resizing = false
		end
	end)
	
	-- Minimize button
	self.Connections:Add(self.MinimizeBtn.MouseButton1Click:Connect(function()
		self:ToggleMinimize()
	end))
	
	-- Close button
	self.Connections:Add(self.CloseBtn.MouseButton1Click:Connect(function()
		self:Destroy()
	end))
	
	-- Hover effects for buttons
	for _, btn in ipairs({self.MinimizeBtn, self.CloseBtn}) do
		Utils.ConnectHover(btn, 
			function() Utils.TweenColor(btn, "BackgroundColor3", Theme.Colors.Background, Theme.Animation.Fast) end,
			function() Utils.TweenColor(btn, "BackgroundColor3", Theme.Colors.BackgroundTertiary, Theme.Animation.Fast) end
		)
	end
end

function Window:ToggleMinimize()
	self.Minimized = not self.Minimized
	
	if self.Minimized then
		Utils.TweenSize(self.Instance, UDim2.new(0, self.Size.X, 0, 44), Theme.Animation.Normal)
		self.ContentFrame.Visible = false
		self.ResizeHandle.Visible = false
		self.MinimizeBtn.Text = "+"
	else
		Utils.TweenSize(self.Instance, UDim2.new(0, self.Size.X, 0, self.Size.Y), Theme.Animation.Normal)
		self.ContentFrame.Visible = true
		self.ResizeHandle.Visible = true
		self.MinimizeBtn.Text = "−"
	end
end

function Window:CreateTab(options)
	local Tab = require(script.Parent.components.tab)
	return Tab.new(self, options)
end

function Window:SetTitle(title: string)
	self.Title = title
	if self.TitleLabel then
		self.TitleLabel.Text = title
	end
end

function Window:Destroy()
	-- Remove from library
	local index = table.find(self.Library.Windows, self)
	if index then
		table.remove(self.Library.Windows, index)
	end
	
	if self.Library.ActiveWindow == self then
		self.Library.ActiveWindow = self.Library.Windows[#self.Library.Windows] or nil
	end
	
	-- Destroy all tabs
	for _, tab in ipairs(self.Tabs) do
		tab:Destroy()
	end
	
	Core.BaseComponent.Destroy(self)
end

Components.Window = Window

-- ============================================
-- Tab Component
-- ============================================

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
	
	-- Create tab UI
	self:BuildUI()
	
	-- Register with window
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
	-- Deselect current tab
	if self.Window.ActiveTab and self.Window.ActiveTab ~= self then
		self.Window.ActiveTab:Deselect()
	end
	
	self.IsActive = true
	self.Window.ActiveTab = self
	
	-- Show this tab
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
	local Section = require(script.Parent.components.section)
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

Components.Tab = Tab

-- ============================================
-- Section Component
-- ============================================

local Section = {}
Section.__index = Section
setmetatable(Section, { __index = Core.BaseComponent })

function Section.new(tab, options)
	local self = setmetatable(Core.BaseComponent.new("Section"), Section)
	
	self.Tab = tab
	self.Name = options.Name or "Section"
	self.Side = options.Side or "Left" -- "Left" or "Right" for future use
	
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
		Size = UDim2.new(1, 0, 0, 0), -- Height auto
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
	local Button = require(script.Parent.components.button)
	return self:AddElement(Button.new(self, options))
end

-- Toggle
function Section:CreateToggle(options)
	local Toggle = require(script.Parent.components.toggle)
	return self:AddElement(Toggle.new(self, options))
end

-- Slider
function Section:CreateSlider(options)
	local Slider = require(script.Parent.components.slider)
	return self:AddElement(Slider.new(self, options))
end

-- Dropdown
function Section:CreateDropdown(options)
	local Dropdown = require(script.Parent.components.dropdown)
	return self:AddElement(Dropdown.new(self, options))
end

-- MultiDropdown
function Section:CreateMultiDropdown(options)
	local MultiDropdown = require(script.Parent.components.multidropdown)
	return self:AddElement(MultiDropdown.new(self, options))
end

-- Textbox
function Section:CreateTextbox(options)
	local Textbox = require(script.Parent.components.textbox)
	return self:AddElement(Textbox.new(self, options))
end

-- Keybind
function Section:CreateKeybind(options)
	local Keybind = require(script.Parent.components.keybind)
	return self:AddElement(Keybind.new(self, options))
end

-- Label
function Section:CreateLabel(options)
	local Label = require(script.Parent.components.label)
	return self:AddElement(Label.new(self, options))
end

-- Divider
function Section:CreateDivider(options)
	local Divider = require(script.Parent.components.divider)
	return self:AddElement(Divider.new(self, options))
end

function Section:Destroy()
	for _, element in ipairs(self.Elements) do
		element:Destroy()
	end
	Core.BaseComponent.Destroy(self)
end

Components.Section = Section

return Components