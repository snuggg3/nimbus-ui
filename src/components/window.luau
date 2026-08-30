--[[
	Window Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

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
	self.Minimized = false
	
	self:BuildUI()
	
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
		Utils.Create("Frame", {
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
	
	-- Window controls
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
	
	-- Parent to ScreenGui
	self.Instance.Parent = self.Library.ScreenGui
	
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
	local Tab = require(script.Parent.tab)
	return Tab.new(self, options)
end

function Window:SetTitle(title: string)
	self.Title = title
	if self.TitleLabel then
		self.TitleLabel.Text = title
	end
end

function Window:Destroy()
	local index = table.find(self.Library.Windows, self)
	if index then
		table.remove(self.Library.Windows, index)
	end
	
	if self.Library.ActiveWindow == self then
		self.Library.ActiveWindow = self.Library.Windows[#self.Library.Windows] or nil
	end
	
	for _, tab in ipairs(self.Tabs) do
		tab:Destroy()
	end
	
	if self.DragConnection then
		self.DragConnection:Disconnect()
	end
	
	Core.BaseComponent.Destroy(self)
end

return Window