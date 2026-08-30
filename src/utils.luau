--[[
	Utility functions for the UI library
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Theme = require(script.Parent.themes)

local Utils = {}

-- ============================================
-- Instance Creation Helpers
-- ============================================

function Utils.Create(className: string, properties: {[string]: any}, children: {Instance}?): Instance
	local instance = Instance.new(className)
	
	for property, value in pairs(properties) do
		instance[property] = value
	end
	
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	
	return instance
end

function Utils.CreateCorner(radius: number?): UICorner
	return Utils.Create("UICorner", {
		CornerRadius = UDim.new(0, radius or Theme.Sizing.CornerRadius)
	})
end

function Utils.CreateStroke(color: Color3, thickness: number?, transparency: number?): UIStroke
	return Utils.Create("UIStroke", {
		Color = color,
		Thickness = thickness or Theme.Sizing.BorderWidth,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})
end

function Utils.CreatePadding(padding: {number}): UIPadding
	return Utils.Create("UIPadding", {
		PaddingTop = UDim.new(0, padding[1] or 0),
		PaddingBottom = UDim.new(0, padding[2] or 0),
		PaddingLeft = UDim.new(0, padding[3] or 0),
		PaddingRight = UDim.new(0, padding[4] or 0),
	})
end

function Utils.CreateListLayout(direction: Enum.FillDirection?, padding: number?, alignment: Enum.HorizontalAlignment?): UIListLayout
	return Utils.Create("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 0),
		HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder
	})
end

function Utils.CreateGridLayout(cellSize: UDim2?, cellPadding: UDim2?): UIGridLayout
	return Utils.Create("UIGridLayout", {
		CellSize = cellSize or UDim2.new(0, 100, 0, 100),
		CellPadding = cellPadding or UDim2.new(0, 8, 0, 8),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder
	})
end

-- ============================================
-- Animation/Tweening
-- ============================================

local activeTweens = {}

function Utils.Tween(instance: Instance, properties: {[string]: any}, duration: number?, easingStyle: Enum.EasingStyle?, easingDirection: Enum.EasingDirection?): Tween
	local tweenInfo = TweenInfo.new(
		duration or Theme.Animation.Normal,
		easingStyle or Theme.Animation.Easing,
		easingDirection or Theme.Animation.EasingDirection
	)
	
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	
	-- Track for cleanup
	table.insert(activeTweens, tween)
	tween.Completed:Connect(function()
		local index = table.find(activeTweens, tween)
		if index then
			table.remove(activeTweens, index)
		end
	end)
	
	return tween
end

function Utils.TweenColor(instance: Instance, property: string, targetColor: Color3, duration: number?): Tween
	return Utils.Tween(instance, { [property] = targetColor }, duration)
end

function Utils.TweenTransparency(instance: Instance, targetTransparency: number, duration: number?): Tween
	return Utils.Tween(instance, { BackgroundTransparency = targetTransparency }, duration)
end

function Utils.TweenSize(instance: Instance, targetSize: UDim2, duration: number?): Tween
	return Utils.Tween(instance, { Size = targetSize }, duration)
end

function Utils.TweenPosition(instance: Instance, targetPosition: UDim2, duration: number?): Tween
	return Utils.Tween(instance, { Position = targetPosition }, duration)
end

function Utils.StopTweens(instance: Instance)
	for _, tween in ipairs(activeTweens) do
		if tween.Instance == instance then
			tween:Cancel()
		end
	end
end

function Utils.CleanupAllTweens()
	for _, tween in ipairs(activeTweens) do
		tween:Cancel()
	end
	table.clear(activeTweens)
end

-- ============================================
-- Input Handling
-- ============================================

function Utils.IsMobile(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Utils.GetInputPosition(input: InputObject): Vector2
	if input.UserInputType == Enum.UserInputType.Touch then
		return input.Position
	elseif input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.MouseButton1 then
		return input.Position
	end
	return Vector2.zero
end

function Utils.IsMouseOver(guiObject: GuiObject, inputPosition: Vector2?): boolean
	local mousePos = inputPosition or UserInputService:GetMouseLocation()
	local absPos = guiObject.AbsolutePosition
	local absSize = guiObject.AbsoluteSize
	
	return mousePos.X >= absPos.X 
		and mousePos.X <= absPos.X + absSize.X
		and mousePos.Y >= absPos.Y
		and mousePos.Y <= absPos.Y + absSize.Y
end

-- Click detection with mobile support
function Utils.ConnectClick(button: GuiButton, callback: (() -> ())?): RBXScriptConnection
	local connections = {}
	
	local function onActivated()
		if callback then
			callback()
		end
	end
	
	-- Mouse
	table.insert(connections, button.MouseButton1Click:Connect(onActivated))
	
	-- Touch (for mobile)
	table.insert(connections, button.TouchTap:Connect(function()
		if Utils.IsMobile() then
			onActivated()
		end
	end))
	
	return {
		Disconnect = function()
			for _, conn in ipairs(connections) do
				conn:Disconnect()
			end
		end
	}
end

-- Hover state management
function Utils.ConnectHover(guiObject: GuiObject, onHover: (() -> ())?, onUnhover: (() -> ())?): {RBXScriptConnection}
	local connections = {}
	local isHovering = false
	
	local function checkHover(input: InputObject?)
		local wasHovering = isHovering
		isHovering = Utils.IsMouseOver(guiObject, input and Utils.GetInputPosition(input))
		
		if isHovering ~= wasHovering then
			if isHovering and onHover then onHover() end
			if not isHovering and onUnhover then onUnhover() end
		end
	end
	
	-- Mouse events
	table.insert(connections, guiObject.MouseEnter:Connect(function()
		isHovering = true
		if onHover then onHover() end
	end))
	
	table.insert(connections, guiObject.MouseLeave:Connect(function()
		isHovering = false
		if onUnhover then onUnhover() end
	end))
	
	-- Touch events for mobile
	if Utils.IsMobile() then
		table.insert(connections, UserInputService.TouchStarted:Connect(function(input)
			checkHover(input)
		end))
		
		table.insert(connections, UserInputService.TouchMoved:Connect(function(input)
			checkHover(input)
		end))
		
		table.insert(connections, UserInputService.TouchEnded:Connect(function()
			if isHovering then
				isHovering = false
				if onUnhover then onUnhover() end
			end
		end))
	end
	
	return connections
end

-- Drag handling
function Utils.MakeDraggable(frame: Frame, dragHandle: GuiObject?, onDragStart: (() -> ())?, onDragEnd: (() -> ())?)
	local dragging = false
	local dragStart = Vector2.zero
	local frameStart = UDim2.new()
	local connections = {}
	
	local handle = dragHandle or frame
	
	local function updateDrag(input: InputObject)
		local delta = Utils.GetInputPosition(input) - dragStart
		local newPosition = UDim2.new(
			frameStart.X.Scale,
			frameStart.X.Offset + delta.X,
			frameStart.Y.Scale,
			frameStart.Y.Offset + delta.Y
		)
		frame.Position = newPosition
	end
	
	table.insert(connections, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Utils.GetInputPosition(input)
			frameStart = frame.Position
			if onDragStart then onDragStart() end
		end
	end))
	
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateDrag(input)
		end
	end))
	
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if onDragEnd then onDragEnd() end
		end
	end))
	
	return {
		Disconnect = function()
			for _, conn in ipairs(connections) do
				conn:Disconnect()
			end
		end
	}
end

-- ============================================
-- Text Measurement
-- ============================================

function Utils.GetTextSize(text: string, font: Enum.Font, textSize: number, maxWidth: number?): Vector2
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = Font.fromEnum(font)
	params.Size = textSize
	params.Width = maxWidth or math.huge
	
	return TextService:GetTextBoundsAsync(params)
end

function Utils.TruncateText(text: string, font: Enum.Font, textSize: number, maxWidth: number, suffix: string?): string
	local textSizeVec = Utils.GetTextSize(text, font, textSize, maxWidth)
	
	if textSizeVec.X <= maxWidth then
		return text
	end
	
	suffix = suffix or "..."
	local suffixSize = Utils.GetTextSize(suffix, font, textSize).X
	local availableWidth = maxWidth - suffixSize
	
	-- Binary search for best fit
	local low, high = 1, #text
	local best = ""
	
	while low <= high do
		local mid = math.floor((low + high) / 2)
		local candidate = text:sub(1, mid) .. suffix
		local size = Utils.GetTextSize(candidate, font, textSize).X
		
		if size <= maxWidth then
			best = candidate
			low = mid + 1
		else
			high = mid - 1
		end
	end
	
	return best ~= "" and best or suffix
end

-- ============================================
-- Color Utilities
-- ============================================

function Utils.LerpColor(a: Color3, b: Color3, t: number): Color3
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

function Utils.DarkenColor(color: Color3, factor: number): Color3
	return Color3.new(
		color.R * factor,
		color.G * factor,
		color.B * factor
	)
end

function Utils.LightenColor(color: Color3, factor: number): Color3
	return Color3.new(
		color.R + (1 - color.R) * factor,
		color.G + (1 - color.G) * factor,
		color.B + (1 - color.B) * factor
	)
end

-- ============================================
-- Connection Management
-- ============================================

function Utils.NewConnectionManager(): {Connections: {RBXScriptConnection}, Add: (self, RBXScriptConnection) -> (), DisconnectAll: (self) -> ()}
	local manager = {
		Connections = {},
		
		Add = function(self, connection: RBXScriptConnection)
			table.insert(self.Connections, connection)
			return connection
		end,
		
		DisconnectAll = function(self)
			for _, conn in ipairs(self.Connections) do
				if conn.Connected then
					conn:Disconnect()
				end
			end
			table.clear(self.Connections)
		end
	}
	
	return manager
end

-- ============================================
-- Responsive/Layout Helpers
-- ============================================

function Utils.UpdateCanvasSize(scrollingFrame: ScrollingFrame, layout: UIListLayout, padding: number?)
	local contentHeight = layout.AbsoluteContentSize.Y + (padding or 0)
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
end

function Utils.AutoCanvasSize(scrollingFrame: ScrollingFrame, padding: number?): RBXScriptConnection
	local layout = scrollingFrame:FindFirstChildOfClass("UIListLayout") 
		or scrollingFrame:FindFirstChildOfClass("UIGridLayout")
	
	if not layout then return nil end
	
	local function update()
		Utils.UpdateCanvasSize(scrollingFrame, layout, padding)
	end
	
	local conn = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	update()
	
	return conn
end

-- ============================================
-- Safe Callback Execution
-- ============================================

function Utils.SafeCallback(callback: (() -> ())?, ...: any)
	if type(callback) == "function" then
		local success, err = pcall(callback, ...)
		if not success then
			warn("[UI Library] Callback error: " .. tostring(err))
		end
	end
end

-- ============================================
-- Unique ID Generation
-- ============================================

local idCounter = 0
function Utils.GenerateId(prefix: string?): string
	idCounter += 1
	return (prefix or "ui") .. "_" .. idCounter .. "_" .. math.random(1000, 9999)
end

-- ============================================
-- Deep Copy / Merge
-- ============================================

function Utils.DeepCopy(original: {[string]: any}): {[string]: any}
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = Utils.DeepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

function Utils.MergeTables(target: {[string]: any}, source: {[string]: any}): {[string]: any}
	local result = Utils.DeepCopy(target)
	for key, value in pairs(source) do
		if type(value) == "table" and type(result[key]) == "table" then
			result[key] = Utils.MergeTables(result[key], value)
		else
			result[key] = value
		end
	end
	return result
end

return Utils