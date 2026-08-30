--[[
	Notification Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Notification = {}
Notification.__index = Notification
setmetatable(Notification, { __index = Core.BaseComponent })

function Notification.new(library, options)
	local self = setmetatable(Core.BaseComponent.new("Notification"), Notification)
	
	self.Library = library
	self.Title = options.Title or "Notification"
	self.Content = options.Content or ""
	self.Duration = options.Duration or 5
	self.Type = options.Type or "Info" -- "Info", "Success", "Warning", "Error"
	
	self:BuildUI()
	self:Show()
	
	-- Auto dismiss
	if self.Duration > 0 then
		task.delay(self.Duration, function()
			self:Dismiss()
		end)
	end
	
	-- Register
	table.insert(library.Notifications, self)
	
	return self
end

function Notification:BuildUI()
	-- Type colors
	local typeColors = {
		Info = { bg = Theme.Colors.Primary, icon = "rbxassetid://10709790787" },
		Success = { bg = Theme.Colors.Success, icon = "rbxassetid://10709790644" },
		Warning = { bg = Theme.Colors.Warning, icon = "rbxassetid://10709790834" },
		Error = { bg = Theme.Colors.Error, icon = "rbxassetid://10709790881" },
	}
	local colors = typeColors[self.Type] or typeColors.Info
	
	self.Instance = Utils.Create("Frame", {
		Name = "Notification_" .. Utils.GenerateId(),
		BackgroundColor3 = colors.bg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		BackgroundTransparency = 1, -- Start invisible for animation
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadius),
		Utils.CreatePadding({12, 12, 12, 12}),
		Utils.CreateListLayout(Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left),
	})
	self.Instance.Parent = self.Library.NotificationContainer
	
	-- Icon
	local icon = Utils.Create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 20, 0, 20),
		Image = colors.icon,
		ImageColor3 = Theme.Colors.TextOnPrimary,
	})
	icon.Parent = self.Instance
	
	-- Content container
	local contentFrame = Utils.Create("Frame", {
		Name = "ContentFrame",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		Utils.CreateListLayout(Enum.FillDirection.Vertical, 4),
	})
	contentFrame.Parent = self.Instance
	
	-- Title
	local titleLabel = Utils.Create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Theme.Typography.FontSemibold,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextOnPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = self.Title,
		TextWrapped = true,
	})
	titleLabel.Parent = contentFrame
	
	-- Content
	local contentLabel = Utils.Create("TextLabel", {
		Name = "Content",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextOnPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = self.Content,
		TextWrapped = true,
		TextTransparency = 0.1,
	})
	contentLabel.Parent = contentFrame
	
	-- Close button
	local closeBtn = Utils.Create("TextButton", {
		Name = "CloseBtn",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(1, -10, 0, 10),
		AnchorPoint = Vector2.new(1, 0),
		Font = Theme.Typography.FontBold,
		TextSize = 14,
		TextColor3 = Theme.Colors.TextOnPrimary,
		Text = "✕",
		AutoButtonColor = false,
	})
	closeBtn.Parent = self.Instance
	
	self.Connections:Add(closeBtn.MouseButton1Click:Connect(function()
		self:Dismiss()
	end))
	
	-- Hover effect on close
	Utils.ConnectHover(closeBtn,
		function() Utils.TweenTransparency(closeBtn, 0.2, Theme.Animation.Fast) end,
		function() Utils.TweenTransparency(closeBtn, 0, Theme.Animation.Fast) end
	)
	
	-- Progress bar (duration indicator)
	if self.Duration > 0 then
		self.ProgressBar = Utils.Create("Frame", {
			Name = "ProgressBar",
			BackgroundColor3 = Theme.Colors.TextOnPrimary,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 3),
			Position = UDim2.new(0, 0, 1, 0),
		}, {
			Utils.CreateCorner(Theme.Sizing.CornerRadius),
		})
		self.ProgressBar.Parent = self.Instance
	end
end

function Notification:Show()
	-- Animate in
	self.Instance.BackgroundTransparency = 1
	Utils.TweenTransparency(self.Instance, 0, Theme.Animation.Normal)
	
	-- Slide in from right
	local startPos = UDim2.new(1, 20, 0, 0)
	local endPos = UDim2.new(0, 0, 0, 0)
	self.Instance.Position = startPos
	Utils.TweenPosition(self.Instance, endPos, Theme.Animation.Normal)
	
	-- Animate progress bar
	if self.ProgressBar and self.Duration > 0 then
		self.ProgressBar.Size = UDim2.new(1, 0, 0, 3)
		Utils.Tween(self.ProgressBar, { Size = UDim2.new(0, 0, 0, 3) }, self.Duration, Enum.EasingStyle.Linear)
	end
end

function Notification:Dismiss()
	if self.Dismissed then return end
	self.Dismissed = true
	
	-- Animate out
	local endPos = UDim2.new(1, 20, 0, 0)
	local tween = Utils.TweenPosition(self.Instance, endPos, Theme.Animation.Normal)
	Utils.TweenTransparency(self.Instance, 1, Theme.Animation.Normal)
	
	tween.Completed:Connect(function()
		self:Destroy()
	end)
end

function Notification:Destroy()
	-- Remove from library
	local index = table.find(self.Library.Notifications, self)
	if index then
		table.remove(self.Library.Notifications, index)
	end
	
	Core.BaseComponent.Destroy(self)
end

return Notification