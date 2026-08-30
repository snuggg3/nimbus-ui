--[[
	Keybind Component
]]

local Theme = require(script.Parent.themes)
local Utils = require(script.Parent.utils)
local Core = require(script.Parent.core)

local UserInputService = game:GetService("UserInputService")

local Keybind = {}
Keybind.__index = Keybind
setmetatable(Keybind, { __index = Core.BaseInteractive })

function Keybind.new(section, options)
	local self = setmetatable(Core.BaseInteractive.new("Keybind"), Keybind)
	
	self.Section = section
	self.Name = options.Name or "Keybind"
	self.Default = options.Default
	self.Callback = options.Callback
	self.Flag = options.Flag
	self.Mode = options.Mode or "Toggle" -- "Toggle", "Hold", "Always"
	
	self.Value = self.Default
	self.Listening = false
	self.Active = false
	self.KeybindConnection = nil
	
	self:BuildUI()
	self:UpdateDisplay()
	
	-- Register global keybind listener
	if self.Value then
		self:RegisterKeybind(self.Value)
	end
	
	return self
end

function Keybind:BuildUI()
	-- Main container
	self.Instance = Utils.Create("Frame", {
		Name = "Keybind_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Theme.Sizing.Height),
	})
	self.Instance.Parent = self.Section.ContentFrame
	
	-- Label
	self.Label = Utils.Create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -100, 1, 0),
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = self.Name,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	self.Label.Parent = self.Instance
	
	-- Keybind button
	self.Button = Utils.Create("TextButton", {
		Name = "Button",
		BackgroundColor3 = Theme.Colors.InputBackground,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 90, 1, 0),
		Position = UDim2.new(1, -90, 0, 0),
		Font = Theme.Typography.FontMedium,
		TextSize = Theme.Typography.Size.SM,
		TextColor3 = Theme.Colors.TextPrimary,
		Text = self.Value and self.Value.Name or "None",
		AutoButtonColor = false,
	}, {
		Utils.CreateCorner(Theme.Sizing.CornerRadius),
		Utils.CreateStroke(Theme.Colors.InputBorder),
		Utils.CreatePadding({8, 0, 8, 0}),
	})
	self.Button.Parent = self.Instance
	
	-- Click to listen
	self.Connections:Add(self.Button.MouseButton1Click:Connect(function()
		if self.Enabled then
			self:StartListening()
		end
	end))
	
	-- Right-click to clear
	self.Connections:Add(self.Button.MouseButton2Click:Connect(function()
		if self.Enabled then
			self:SetValue(nil, true)
		end
	end))
	
	-- Hover effect
	Utils.ConnectHover(self.Button,
		function()
			if self.Enabled and not self.Listening then
				Utils.TweenColor(self.Button, "BackgroundColor3", Theme.Colors.BackgroundSecondary, Theme.Animation.Fast)
				Utils.TweenColor(self.Button.UIStroke, "Color", Theme.Colors.PrimaryLight, Theme.Animation.Fast)
			end
		end,
		function()
			if self.Enabled and not self.Listening then
				Utils.TweenColor(self.Button, "BackgroundColor3", Theme.Colors.InputBackground, Theme.Animation.Fast)
				Utils.TweenColor(self.Button.UIStroke, "Color", Theme.Colors.InputBorder, Theme.Animation.Fast)
			end
		end
	)
end

function Keybind:StartListening()
	if self.Listening then return end
	
	self.Listening = true
	self.Button.Text = "..."
	Utils.TweenColor(self.Button, "BackgroundColor3", Theme.Colors.PrimaryLight, Theme.Animation.Fast)
	Utils.TweenColor(self.Button.UIStroke, "Color", Theme.Colors.Primary, Theme.Animation.Fast)
	Utils.TweenColor(self.Button, "TextColor3", Theme.Colors.TextOnPrimary, Theme.Animation.Fast)
	
	-- Listen for any key
	self.KeybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		local keyCode = input.KeyCode
		local userInputType = input.UserInputType
		
		-- Ignore modifier keys alone
		if keyCode == Enum.KeyCode.LeftShift or keyCode == Enum.KeyCode.RightShift
			or keyCode == Enum.KeyCode.LeftControl or keyCode == Enum.KeyCode.RightControl
			or keyCode == Enum.KeyCode.LeftAlt or keyCode == Enum.KeyCode.RightAlt
			or keyCode == Enum.KeyCode.Unknown then
			return
		end
		
		-- Convert mouse buttons
		local keyName
		if userInputType == Enum.UserInputType.MouseButton1 then
			keyName = "Mouse1"
		elseif userInputType == Enum.UserInputType.MouseButton2 then
			keyName = "Mouse2"
		elseif userInputType == Enum.UserInputType.MouseButton3 then
			keyName = "Mouse3"
		else
			keyName = keyCode.Name
		end
		
		self:StopListening(keyCode, userInputType, keyName)
	end)
end

function Keybind:StopListening(keyCode: Enum.KeyCode, userInputType: Enum.UserInputType, keyName: string)
	self.Listening = false
	
	if self.KeybindConnection then
		self.KeybindConnection:Disconnect()
		self.KeybindConnection = nil
	end
	
	-- Update display
	local keyEnum = keyCode ~= Enum.KeyCode.Unknown and keyCode or nil
	self:SetValue({ KeyCode = keyEnum, UserInputType = userInputType, Name = keyName }, true)
	
	-- Restore button appearance
	Utils.TweenColor(self.Button, "BackgroundColor3", Theme.Colors.InputBackground, Theme.Animation.Fast)
	Utils.TweenColor(self.Button.UIStroke, "Color", Theme.Colors.InputBorder, Theme.Animation.Fast)
	Utils.TweenColor(self.Button, "TextColor3", Theme.Colors.TextPrimary, Theme.Animation.Fast)
end

function Keybind:RegisterKeybind(keyData)
	-- Unregister old
	self:UnregisterKeybind()
	
	if not keyData then return end
	
	self.KeybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		local matches = false
		if keyData.UserInputType and input.UserInputType == keyData.UserInputType then
			matches = true
		elseif keyData.KeyCode and input.KeyCode == keyData.KeyCode then
			matches = true
		end
		
		if matches then
			self:OnKeyPressed()
		end
	end)
	
	-- For hold mode, also listen for release
	if self.Mode == "Hold" then
		self.KeybindReleaseConnection = UserInputService.InputEnded:Connect(function(input)
			local matches = false
			if keyData.UserInputType and input.UserInputType == keyData.UserInputType then
				matches = true
			elseif keyData.KeyCode and input.KeyCode == keyData.KeyCode then
				matches = true
			end
			
			if matches then
				self:OnKeyReleased()
			end
		end)
	end
end

function Keybind:UnregisterKeybind()
	if self.KeybindConnection then
		self.KeybindConnection:Disconnect()
		self.KeybindConnection = nil
	end
	if self.KeybindReleaseConnection then
		self.KeybindReleaseConnection:Disconnect()
		self.KeybindReleaseConnection = nil
	end
end

function Keybind:OnKeyPressed()
	if self.Mode == "Toggle" then
		self.Active = not self.Active
		self:Fire("Toggled", self.Active)
		Utils.SafeCallback(self.Callback, self.Active)
	elseif self.Mode == "Hold" then
		self.Active = true
		self:Fire("Pressed", true)
		Utils.SafeCallback(self.Callback, true)
	elseif self.Mode == "Always" then
		self:Fire("Pressed", true)
		Utils.SafeCallback(self.Callback, true)
	end
end

function Keybind:OnKeyReleased()
	if self.Mode == "Hold" then
		self.Active = false
		self:Fire("Pressed", false)
		Utils.SafeCallback(self.Callback, false)
	end
end

function Keybind:SetValue(keyData: {KeyCode: Enum.KeyCode?, UserInputType: Enum.UserInputType?, Name: string}?, fireCallback: boolean?)
	self.Value = keyData
	self:UpdateDisplay()
	self:RegisterKeybind(keyData)
	
	if fireCallback and keyData then
		self:Fire("Changed", keyData)
		Utils.SafeCallback(self.Callback, keyData)
	end
end

function Keybind:UpdateDisplay()
	if self.Value then
		self.Button.Text = self.Value.Name
	else
		self.Button.Text = "None"
		self.Button.TextColor3 = Theme.Colors.TextMuted
	end
end

function Keybind:GetValue()
	return self.Value
end

function Keybind:SetCallback(callback: (any) -> ())
	self.Callback = callback
end

function Keybind:SetMode(mode: string)
	self.Mode = mode
	if self.Value then
		self:RegisterKeybind(self.Value)
	end
end

function Keybind:SetEnabled(enabled: boolean)
	self.Enabled = enabled
	if self.Instance then
		self.Button.Interactable = enabled
		local transparency = enabled and 0 or 0.5
		Utils.TweenTransparency(self.Button, transparency, Theme.Animation.Fast)
	end
	
	if not enabled then
		self:UnregisterKeybind()
	elseif self.Value then
		self:RegisterKeybind(self.Value)
	end
end

function Keybind:Destroy()
	self:UnregisterKeybind()
	if self.KeybindConnection then
		self.KeybindConnection:Disconnect()
	end
	Core.BaseInteractive.Destroy(self)
end

return Keybind