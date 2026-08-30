--[[
	Slider Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local Slider = {}
Slider.__index = Slider
setmetatable(Slider, { __index = Core.BaseInteractive })

function Slider.new(section, options)
	local self = setmetatable(Core.BaseInteractive.new("Slider"), Slider)
	
	self.Section = section
	self.Name = options.Name or "Slider"
	self.Min = options.Min or 0
	self.Max = options.Max or 100
	self.Value = options.Default or self.Min
	self.Increment = options.Increment or 1
	self.Suffix = options.Suffix or ""
	self.Callback = options.Callback
	self.Flag = options.Flag
	
	-- Clamp value
	self.Value = math.clamp(self.Value, self.Min, self.Max)
	self.Value = self:RoundToIncrement(self.Value)
	
	self.Dragging = false
	
	self:BuildUI()
	
	-- Set initial visual state
	self:UpdateVisuals(false)
	
	return self
end

function Slider:RoundToIncrement(value: number): number
	if self.Increment >= 1 then
		return math.floor(value / self.Increment + 0.5) * self.Increment
	else
		-- For decimal increments
		local mult = 1 / self.Increment
		return math.floor(value * mult + 0.5) / mult
	end
end

function Slider:BuildUI()
	-- Main container
	self.Instance = Utils.Create("Frame", {
		Name = "Slider_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 56),
	})
	self.Instance.Parent = self.Section.ContentFrame
	
	-- Label row
	local labelRow = Utils.Create("Frame", {
		Name = "LabelRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
	}, {
		Utils.CreateListLayout(Enum.FillDirection.Horizontal, 8),
	})
	labelRow.Parent = self.Instance
	
	-- Name label
	self.Label = Utils.Create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = self.Name,
	})
	self.Label.Parent = labelRow
	
	-- Value label
	self.ValueLabel = Utils.Create("TextLabel", {
		Name = "ValueLabel",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = self:FormatValue(self.Value),
	})
	self.ValueLabel.Parent = labelRow
	
	-- Track background
	self.TrackBg = Utils.Create("Frame", {
		Name = "TrackBg",
		BackgroundColor3 = Theme.Colors.BackgroundTertiary,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 1, -6),
		AnchorPoint = Vector2.new(0, 0),
	}, {
		Utils.CreateCorner(3),
	})
	self.TrackBg.Parent = self.Instance
	
	-- Track fill (progress)
	self.TrackFill = Utils.Create("Frame", {
		Name = "TrackFill",
		BackgroundColor3 = Theme.Colors.Primary,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
	}, {
		Utils.CreateCorner(3),
	})
	self.TrackFill.Parent = self.TrackBg
	
	-- Thumb
	self.Thumb = Utils.Create("Frame", {
		Name = "Thumb",
		BackgroundColor3 = Theme.Colors.Primary,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 16, 0, 16),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 2,
	}, {
		Utils.CreateCorner(8),
		Utils.CreateStroke(Theme.Colors.Surface, 2),
	})
	self.Thumb.Parent = self.TrackBg
	
	-- Click/drag area
	self.DragArea = Utils.Create("TextButton", {
		Name = "DragArea",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	})
	self.DragArea.Parent = self.TrackBg
	
	-- Input handling
	self.Connections:Add(self.DragArea.InputBegan:Connect(function(input)
		if self.Enabled and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			self.Dragging = true
			self:UpdateFromInput(input)
		end
	end))
	
	self.Connections:Add(Utils.GetService("UserInputService").InputChanged:Connect(function(input)
		if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			self:UpdateFromInput(input)
		end
	end))
	
	self.Connections:Add(Utils.GetService("UserInputService").InputEnded:Connect(function(input)
		if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			self.Dragging = false
			self:Fire("DragEnded", self.Value)
		end
	end))
	
	-- Hover effect on thumb
	Utils.ConnectHover(self.DragArea,
		function() 
			if self.Enabled then
				Utils.Tween(self.Thumb, { Size = UDim2.new(0, 20, 0, 20) }, Theme.Animation.Fast)
			end
		end,
		function()
			if self.Enabled then
				Utils.Tween(self.Thumb, { Size = UDim2.new(0, 16, 0, 16) }, Theme.Animation.Fast)
			end
		end
	)
end

function Slider:UpdateFromInput(input: InputObject)
	local trackAbsPos = self.TrackBg.AbsolutePosition.X
	local trackAbsSize = self.TrackBg.AbsoluteSize.X
	local mouseX = Utils.GetInputPosition(input).X
	
	local relativeX = math.clamp(mouseX - trackAbsPos, 0, trackAbsSize)
	local percentage = relativeX / trackAbsSize
	
	local newValue = self.Min + (self.Max - self.Min) * percentage
	newValue = self:RoundToIncrement(newValue)
	newValue = math.clamp(newValue, self.Min, self.Max)
	
	if newValue ~= self.Value then
		self.Value = newValue
		self:UpdateVisuals(true)
		self:Fire("Changed", self.Value)
		Utils.SafeCallback(self.Callback, self.Value)
	end
end

function Slider:UpdateVisuals(animate: boolean?)
	local percentage = (self.Value - self.Min) / (self.Max - self.Min)
	local targetSize = UDim2.new(percentage, 0, 1, 0)
	local targetPos = UDim2.new(percentage, 0, 0.5, 0)
	
	if animate then
		Utils.Tween(self.TrackFill, { Size = targetSize }, Theme.Animation.Fast)
		Utils.Tween(self.Thumb, { Position = targetPos }, Theme.Animation.Fast)
	else
		self.TrackFill.Size = targetSize
		self.Thumb.Position = targetPos
	end
	
	self.ValueLabel.Text = self:FormatValue(self.Value)
end

function Slider:FormatValue(value: number): string
	if self.Increment >= 1 then
		return tostring(math.floor(value)) .. self.Suffix
	else
		return string.format("%.2f", value) .. self.Suffix
	end
end

function Slider:SetValue(value: number, fireCallback: boolean?)
	value = math.clamp(value, self.Min, self.Max)
	value = self:RoundToIncrement(value)
	self.Value = value
	self:UpdateVisuals(true)
	
	if fireCallback ~= false then
		self:Fire("Changed", value)
		Utils.SafeCallback(self.Callback, value)
	end
end

function Slider:GetValue(): number
	return self.Value
end

function Slider:SetCallback(callback: (number) -> ())
	self.Callback = callback
end

function Slider:SetMinMax(min: number, max: number)
	self.Min = min
	self.Max = max
	self.Value = math.clamp(self.Value, self.Min, self.Max)
	self:UpdateVisuals(true)
end

function Slider:SetEnabled(enabled: boolean)
	self.Enabled = enabled
	if self.Instance then
		self.DragArea.Interactable = enabled
		local transparency = enabled and 0 or 0.5
		Utils.TweenTransparency(self.TrackBg, transparency, Theme.Animation.Fast)
		Utils.TweenTransparency(self.TrackFill, transparency, Theme.Animation.Fast)
		Utils.TweenTransparency(self.Thumb, transparency, Theme.Animation.Fast)
	end
end

function Slider:Destroy()
	Core.BaseInteractive.Destroy(self)
end

return Slider