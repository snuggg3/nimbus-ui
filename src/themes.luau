--[[
	Theme definitions for the UI library
	TypeScript-inspired color palette
]]

local Theme = {}

-- TypeScript Blue Palette
Theme.Colors = {
	-- Primary accent (TypeScript blue)
	Primary = Color3.fromRGB(49, 120, 198),        -- #3178C6 - Main brand blue
	PrimaryHover = Color3.fromRGB(37, 99, 174),    -- Darker on hover
	PrimaryPressed = Color3.fromRGB(28, 79, 148),  -- Even darker when pressed
	PrimaryLight = Color3.fromRGB(73, 143, 214),   -- Lighter variant
	
	-- Backgrounds
	Background = Color3.fromRGB(250, 250, 252),    -- #FAFAFC - Main background
	BackgroundSecondary = Color3.fromRGB(243, 244, 248), -- #F3F4F8 - Secondary background
	BackgroundTertiary = Color3.fromRGB(235, 237, 243),  -- #EBEDF3 - Tertiary/Hover backgrounds
	
	-- Surfaces (cards, panels, windows)
	Surface = Color3.fromRGB(255, 255, 255),       -- Pure white
	SurfaceHover = Color3.fromRGB(248, 249, 252),  -- Subtle hover
	SurfaceBorder = Color3.fromRGB(218, 220, 228), -- #DADCE4 - Subtle borders
	
	-- Text
	TextPrimary = Color3.fromRGB(31, 35, 45),      -- #1F232D - Main text
	TextSecondary = Color3.fromRGB(96, 102, 116),  -- #606674 - Secondary text
	TextMuted = Color3.fromRGB(148, 154, 168),     -- #949AA8 - Muted/disabled text
	TextOnPrimary = Color3.fromRGB(255, 255, 255), -- White text on primary
	
	-- States
	Success = Color3.fromRGB(34, 166, 92),         -- #22A65C
	SuccessHover = Color3.fromRGB(28, 143, 79),
	Warning = Color3.fromRGB(230, 161, 0),         -- #E6A100
	WarningHover = Color3.fromRGB(196, 137, 0),
	Error = Color3.fromRGB(219, 68, 55),           -- #DB4437
	ErrorHover = Color3.fromRGB(196, 55, 44),
	
	-- Interactive
	InputBackground = Color3.fromRGB(255, 255, 255),
	InputBorder = Color3.fromRGB(218, 220, 228),
	InputBorderFocus = Color3.fromRGB(49, 120, 198),
	InputPlaceholder = Color3.fromRGB(148, 154, 168),
	
	-- Scrollbar
	ScrollbarBackground = Color3.fromRGB(235, 237, 243),
	ScrollbarThumb = Color3.fromRGB(189, 194, 208),
	ScrollbarThumbHover = Color3.fromRGB(168, 174, 191),
	
	-- Shadow/Overlay
	Shadow = Color3.fromRGB(0, 0, 0),
	Overlay = Color3.fromRGB(0, 0, 0),
}

-- Sizing & Spacing
Theme.Sizing = {
	-- Corner radius
	CornerRadius = 6,
	CornerRadiusSmall = 4,
	CornerRadiusLarge = 8,
	
	-- Spacing scale (base: 4px)
	Spacing = {
		XS = 4,
		SM = 8,
		MD = 16,
		LG = 24,
		XL = 32,
	}
	
	-- Sizing
	Height = 36,
	HeightSmall = 28,
	HeightLarge = 44,
	
	-- Borders
	BorderWidth = 1,
	BorderWidthFocus = 2,
	
	-- Shadows
	ShadowTransparency = 0.85,
	ShadowSize = 12,
}

-- Typography
Theme.Typography = {
	Font = Enum.Font.Gotham,
	FontBold = Enum.Font.GothamBold,
	FontMedium = Enum.Font.GothamMedium,
	FontSemibold = Enum.Font.GothamSemibold,
	
	Size = {
		XS = 11,
		SM = 13,
		MD = 14,
		LG = 16,
		XL = 18,
		XXL = 22,
	},
	
	LineHeight = 1.5,
}

-- Animation
Theme.Animation = {
	Fast = 0.1,
	Normal = 0.15,
	Slow = 0.25,
	Easing = Enum.EasingStyle.Quart,
	EasingDirection = Enum.EasingDirection.Out,
}

-- Z-Index layers
Theme.ZIndex = {
	Base = 1,
	Dropdown = 100,
	Tooltip = 200,
	Modal = 300,
	Notification = 400,
	ContextMenu = 500,
}

return Theme