--[[
	Nimbus UI Library - Main Entry Point
	
	A clean, TypeScript-inspired UI library for Roblox.
	
	Usage:
		local Library = loadstring(game:HttpGet("RAW_GITHUB_URL"))()
		
		local Window = Library:CreateWindow({ Title = "Example" })
		local Tab = Window:CreateTab({ Name = "Main" })
		
		Tab:CreateButton({
			Name = "Test Button",
			Callback = function() print("Clicked!") end
		})
		
		Tab:CreateToggle({
			Name = "Enabled",
			Default = false,
			Callback = function(value) print("Toggle:", value) end
		})
		
		Tab:CreateDropdown({
			Name = "Mode",
			Options = {"One", "Two", "Three"},
			Default = "One",
			Callback = function(value) print("Selected:", value) end
		})
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Load modules
local Theme = require(script.themes)
local Utils = require(script.utils)
local Core = require(script.core)
local Components = require(script.components)

-- Initialize library
local Library = Core.Library
Library:Initialize()

-- ============================================
-- Public API
-- ============================================

-- Window creation
function Library:CreateWindow(options)
	local Window = require(script.components.window)
	return Window.new(self, options)
end

-- Notifications
function Library:Notify(options)
	local Notification = require(script.components.notification)
	return Notification.new(self, options)
end

-- Theme access
function Library:GetTheme()
	return Theme
end

function Library:SetTheme(newTheme)
	-- Merge new theme with defaults
	Theme.Colors = Utils.MergeTables(Theme.Colors, newTheme.Colors or {})
	Theme.Sizing = Utils.MergeTables(Theme.Sizing, newTheme.Sizing or {})
	Theme.Typography = Utils.MergeTables(Theme.Typography, newTheme.Typography or {})
	Theme.Animation = Utils.MergeTables(Theme.Animation, newTheme.Animation or {})
end

-- Utility functions exposed
Library.Utils = Utils
Library.Theme = Theme

-- Cleanup
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

-- Handle character respawn (re-parent ScreenGui)
Players.LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if Library.ScreenGui then
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		Library.ScreenGui.Parent = playerGui
	end
end)

-- Return the library table
return Library