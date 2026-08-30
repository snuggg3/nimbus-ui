--[[
	Toggle Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Toggle = {}
Toggle.__index = Toggle
setmetatable(Toggle, { __index = Core.BaseInteractive })

function Toggle.new(section, options)
	local self = setmetatable(Core.BaseInteractive.new("Toggle"), Toggle)
	
	self.Section = section
	self.Name = options.Name or "Toggle"
	self.Value = options.Default or false
	self.Callback = options.Callback
	self.Flag = options.Flag
	
	self:BuildUI()
	
	-- Set initial state
	if self.Value then
		self:SetValue(true, false) -- Don't fire callback on init
	end
	
	return self
end

function Toggle:BuildUI()
	-- Main container
	self.Instance = Utils.Create("Frame", {
		Name = "Toggle_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Theme.Sizing.Height),
	})
	self.Instance.Parent = self.Section.ContentFrame
	
	-- Label
	local label = Utils.Create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = self.Name,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	label.Parent = self.Instance
	
	-- Toggle track
	self.Track = Utils.Create("Frame", {
		Name = "Track",
		BackgroundColor3 = Theme.Colors.BackgroundTertiary,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 44, 0, 24),
		Position = UDim2.new(1, -44, 0.5, -12),
		AnchorPoint = Vector2.new(0, 0),
	}, {
		Utils.CreateCorner(12), -- Fully rounded
		Utils.CreateStroke(Theme.Colors.SurfaceBorder),
	})
	self.Track.Parent = self.Instance
	
	-- Toggle thumb
	self.Thumb = Utils.Create("Frame", {
		Name = "Thumb",
		BackgroundColor3 = Theme.Colors.TextOnPrimary,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0, 2, 0.5, -10),
	}, {
		Utils.CreateCorner(10),
		Utils.CreateStroke(Theme.Colors.SurfaceBorder, 1, 0.5),
	})
	self.Thumb.Parent = self.Track
	
	-- Click area (invisible button over entire toggle)
	self.ClickArea = Utils.Create("TextButton", {
		Name = "ClickArea",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
	})
	self.ClickArea.Parent = self.Instance
	
	-- Animations
	self:SetupHoverAnimations(Theme.Colors.Background, Theme.Colors.BackgroundTertiary, self.Track)
	
	-- Click handler
	self.Connections:Add(self.ClickArea.MouseButton1Click:Connect(function()
		if self.Enabled then
			self:SetValue(not self.Value)
		end
	end))
	
	-- Keyboard support (Space/Enter when focused)
	self.Connections:Add(self.ClickArea.InputBegan:Connect(function(input)
		if self.Enabled and (input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return) then
			self:SetValue(not self.Value)
		end
	end))
end

function Toggle:SetValue(value: boolean, fireCallback: boolean?)
	self.Value = value
	
	local targetPos = value and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
	local targetColor = value and Theme.Colors.Primary or Theme.Colors.BackgroundTertiary
	
	Utils.Tween(self.Thumb, { Position = targetPos }, Theme.Animation.Fast)
	Utils.TweenColor(self.Track, "BackgroundColor3", targetColor, Theme.Animation.Fast)
	
	if fireCallback ~= false then
		self:Fire("Changed", value)
		Utils.SafeCallback(self.Callback, value)
	end
end

function Toggle:GetValue(): boolean
	return self.Value
end

function Toggle:SetCallback(callback: (boolean) -> ())
	self.Callback = callback
end

function Toggle:SetEnabled(enabled: boolean)
	self.Enabled = enabled
	if self.Instance then
		self.ClickArea.Interactable = enabled
		local transparency = enabled and 0 or 0.5
		Utils.TweenTransparency(self.Track, transparency, Theme.Animation.Fast)
		Utils.TweenTransparency(self.Thumb, transparency, Theme.Animation.Fast)
	end
end

function Toggle:Destroy()
	Core.BaseInteractive.Destroy(self)
end

return Toggle