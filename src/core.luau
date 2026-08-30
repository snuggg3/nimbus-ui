--[[
	Core library base classes and main Library table
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)

local Core = {}

-- ============================================
-- Base Component Class
-- ============================================

Core.BaseComponent = {}
Core.BaseComponent.__index = Core.BaseComponent

function Core.BaseComponent.new(componentType: string)
	local self = setmetatable({}, Core.BaseComponent)
	self.Type = componentType
	self.Instance = nil
	self.Connections = Utils.NewConnectionManager()
	self.Children = {}
	self.Parent = nil
	self.Visible = true
	self.Enabled = true
	return self
end

function Core.BaseComponent:SetParent(parent)
	self.Parent = parent
	if self.Instance and parent and parent.Instance then
		self.Instance.Parent = parent.Instance
	end
end

function Core.BaseComponent:AddChild(child)
	table.insert(self.Children, child)
	child:SetParent(self)
end

function Core.BaseComponent:RemoveChild(child)
	local index = table.find(self.Children, child)
	if index then
		table.remove(self.Children, index)
		if child.Instance then
			child.Instance.Parent = nil
		end
	end
end

function Core.BaseComponent:SetVisible(visible: boolean)
	self.Visible = visible
	if self.Instance then
		self.Instance.Visible = visible
	end
end

function Core.BaseComponent:SetEnabled(enabled: boolean)
	self.Enabled = enabled
	if self.Instance then
		-- Override in subclasses for specific behavior
	end
end

function Core.BaseComponent:Destroy()
	self.Connections:DisconnectAll()
	for _, child in ipairs(self.Children) do
		child:Destroy()
	end
	if self.Instance then
		self.Instance:Destroy()
	end
	table.clear(self.Children)
	self.Parent = nil
end

-- ============================================
-- Base Interactive Component
-- ============================================

Core.BaseInteractive = {}
Core.BaseInteractive.__index = Core.BaseInteractive
setmetatable(Core.BaseInteractive, { __index = Core.BaseComponent })

function Core.BaseInteractive.new(componentType: string)
	local self = setmetatable(Core.BaseComponent.new(componentType), Core.BaseInteractive)
	self.Callbacks = {}
	self.Hovering = false
	self.Pressed = false
	return self
end

function Core.BaseInteractive:On(event: string, callback: (...any) -> ())
	if not self.Callbacks[event] then
		self.Callbacks[event] = {}
	end
	table.insert(self.Callbacks[event], callback)
end

function Core.BaseInteractive:Fire(event: string, ...: any)
	if self.Callbacks[event] then
		for _, callback in ipairs(self.Callbacks[event]) do
			Utils.SafeCallback(callback, ...)
		end
	end
end

function Core.BaseInteractive:SetupHoverAnimations(hoverColor: Color3, unhoverColor: Color3, target: GuiObject?)
	target = target or self.Instance
	
	self.Connections:Add(target.MouseEnter:Connect(function()
		self.Hovering = true
		if self.Enabled then
			Utils.TweenColor(target, "BackgroundColor3", hoverColor, Theme.Animation.Fast)
		end
	end))
	
	self.Connections:Add(target.MouseLeave:Connect(function()
		self.Hovering = false
		if self.Enabled then
			Utils.TweenColor(target, "BackgroundColor3", unhoverColor, Theme.Animation.Fast)
		end
	end))
	
	-- Pressed state
	self.Connections:Add(target.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 
			or input.UserInputType == Enum.UserInputType.Touch then
			self.Pressed = true
			if self.Enabled then
				Utils.TweenColor(target, "BackgroundColor3", Utils.DarkenColor(hoverColor, 0.9), Theme.Animation.Fast)
			end
		end
	end))
	
	self.Connections:Add(target.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 
			or input.UserInputType == Enum.UserInputType.Touch then
			self.Pressed = false
			if self.Enabled then
				Utils.TweenColor(target, "BackgroundColor3", self.Hovering and hoverColor or unhoverColor, Theme.Animation.Fast)
			end
		end
	end))
end

function Core.BaseInteractive:SetEnabled(enabled: boolean)
	self.Enabled = enabled
	if self.Instance then
		self.Instance.Interactable = enabled
		if not enabled then
			Utils.TweenTransparency(self.Instance, 0.5, Theme.Animation.Fast)
		else
			Utils.TweenTransparency(self.Instance, 0, Theme.Animation.Fast)
		end
	end
end

-- ============================================
-- Main Library Table
-- ============================================

local Library = {
	Version = "1.0.0",
	Theme = Theme,
	Utils = Utils,
	
	-- State
	Windows = {},
	ActiveWindow = nil,
	Notifications = {},
	Dropdowns = {},
	Tooltips = {},
	
	-- Core GUI
	ScreenGui = nil,
	NotificationContainer = nil,
	DropdownContainer = nil,
}

function Library:Initialize()
	if self.ScreenGui then return self end
	
	-- Create main ScreenGui
	self.ScreenGui = Utils.Create("ScreenGui", {
		Name = "UILibrary",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 0,
		IgnoreGuiInset = true,
	})
	
	-- Notification container (top-right)
	self.NotificationContainer = Utils.Create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 320, 1, 0),
		Position = UDim2.new(1, -340, 0, 20),
		AnchorPoint = Vector2.new(0, 0),
	}, {
		Utils.CreateListLayout(Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right),
		Utils.CreatePadding({20, 20, 20, 20}),
	})
	self.NotificationContainer.Parent = self.ScreenGui
	
	-- Dropdown container (overlay)
	self.DropdownContainer = Utils.Create("Frame", {
		Name = "Dropdowns",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = Theme.ZIndex.Dropdown,
	})
	self.DropdownContainer.Parent = self.ScreenGui
	
	-- Parent to PlayerGui
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	self.ScreenGui.Parent = playerGui
	
	return self
end

function Library:CreateWindow(options: {Title: string, Size: Vector2?, Position: UDim2?, MinSize: Vector2?}): any
	local Window = require(script.Parent.components.window)
	return Window.new(self, options)
end

function Library:Notify(options: {Title: string, Content: string, Duration: number?, Type: string?})
	local Notification = require(script.Parent.components.notification)
	return Notification.new(self, options)
end

function Library:Destroy()
	Utils.CleanupAllTweens()
	for _, window in ipairs(self.Windows) do
		window:Destroy()
	end
	table.clear(self.Windows)
	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
end

-- ============================================
-- Library Metatable (allows Library:CreateWindow syntax)
-- ============================================

local LibraryMeta = {}
LibraryMeta.__index = Library

-- Expose component constructors
LibraryMeta.__index.CreateWindow = Library.CreateWindow
LibraryMeta.__index.Notify = Library.Notify
LibraryMeta.__index.Destroy = Library.Destroy

Core.Library = Library

return Core