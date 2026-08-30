--!nonstrict
--[=[
	TsUI — game-agnostic Roblox UI library
	Visual language inspired by typescriptlang.org

	Place this ModuleScript anywhere (e.g. ReplicatedStorage) and require it from the client:

		local TsUI = require(game:GetService("ReplicatedStorage"):WaitForChild("TsUI"))
		local Window = TsUI:CreateWindow({ Title = "My UI", Size = UDim2.fromOffset(700, 500) })
		local Tab = Window:CreateTab({ Name = "Main" })
		Tab:CreateButton({ Name = "Example", Callback = function() print("Clicked") end })
		Tab:CreateToggle({ Id = "example.enabled", Name = "Enabled", Default = false,
			Callback = function(value) print(value) end })

	Extension points:
		TsUI:RegisterComponent(name, builder)          -> adds Tab/Section:Create<name>(options)
		TsUI:SetTheme({ Primary = ..., Font = ... })   -> tokens for newly built elements
		TsUI:SerializeConfig() / ApplyConfig(tbl)      -> config is plain { [Id] = value } data
]=]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

export type OptionWindow = {
	Title: string?,
	Size: UDim2?,
	Position: UDim2?,
	LogoText: string?,
	ToggleKey: Enum.KeyCode?,
	Scale: number?,
	CloseBehavior: ("Hide" | "Destroy")?,
}

export type OptionTab = { Name: string? }
export type OptionSection = { Name: string? }

export type OptionButton = {
	Name: string?,
	Callback: (() -> ())?,
	Style: ("Primary" | "Secondary")?,
	Disabled: boolean?,
}

export type OptionToggle = {
	Id: string?,
	Name: string?,
	Default: boolean?,
	Callback: ((value: boolean) -> ())?,
}

export type OptionSlider = {
	Id: string?,
	Name: string?,
	Min: number?,
	Max: number?,
	Step: number?,
	Default: number?,
	Suffix: string?,
	Callback: ((value: number) -> ())?,
}

export type OptionDropdown = {
	Id: string?,
	Name: string?,
	Options: { string }?,
	Default: string?,
	Callback: ((value: string?) -> ())?,
}

export type OptionInput = {
	Id: string?,
	Name: string?,
	Placeholder: string?,
	Default: string?,
	Width: number?,
	Callback: ((text: string) -> ())?,
}

export type OptionKeybind = {
	Id: string?,
	Name: string?,
	Default: Enum.KeyCode?,
	Callback: ((key: Enum.KeyCode) -> ())?,
	OnChanged: ((key: Enum.KeyCode?) -> ())?,
}

export type OptionLabel = { Text: string?, SubText: string? }
export type OptionDivider = { Name: string? }

export type OptionNotification = {
	Title: string?,
	Message: string?,
	Duration: number?,
	Type: ("Info" | "Success" | "Warning" | "Error")?,
	Callback: (() -> ())?,
}

export type ValueHandle = {
	Get: (self: ValueHandle) -> any,
	Set: (self: ValueHandle, value: any, fireCallback: boolean?) -> (),
	SetName: (self: ValueHandle, name: string) -> (),
	Destroy: (self: ValueHandle) -> (),
}

export type WindowHandle = {
	CreateTab: (self: WindowHandle, options: OptionTab?) -> any,
	SelectTab: (self: WindowHandle, tab: any) -> any?,
	SetVisible: (self: WindowHandle, visible: boolean) -> (),
	Toggle: (self: WindowHandle) -> (),
	SetMinimized: (self: WindowHandle, minimized: boolean) -> (),
	SetTitle: (self: WindowHandle, title: string) -> (),
	Destroy: (self: WindowHandle) -> (),
	Title: string,
}

local Theme = {
	Primary = Color3.fromRGB(49, 120, 198),
	PrimaryHover = Color3.fromRGB(35, 90, 158),
	PrimaryPressed = Color3.fromRGB(27, 73, 130),
	AccentLight = Color3.fromRGB(91, 160, 224),
	TitleBar = Color3.fromRGB(47, 116, 192),
	Rail = Color3.fromRGB(30, 58, 102),
	RailHover = Color3.fromRGB(39, 80, 127),
	RailText = Color3.fromRGB(186, 205, 229),
	Content = Color3.fromRGB(255, 255, 255),
	Page = Color3.fromRGB(248, 250, 252),
	Border = Color3.fromRGB(226, 232, 240),
	Hover = Color3.fromRGB(241, 245, 249),
	Track = Color3.fromRGB(203, 213, 225),
	Text = Color3.fromRGB(30, 41, 59),
	TextSecondary = Color3.fromRGB(100, 116, 139),
	TextMuted = Color3.fromRGB(148, 163, 184),
	Success = Color3.fromRGB(22, 163, 74),
	Warning = Color3.fromRGB(217, 119, 6),
	Danger = Color3.fromRGB(220, 38, 38),
	Font = Enum.Font.Gotham,
	FontMedium = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontCode = Enum.Font.Code,
	CornerRadius = 4,
	Animation = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	FastAnimation = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local function roundToStep(value: number, min: number, max: number, step: number?): number
	step = step or 1
	if step <= 0 then
		step = 1
	end
	local snapped = min + math.floor((value - min) / step + 0.5) * step
	snapped = math.clamp(snapped, math.min(min, max), math.max(min, max))
	return math.floor(snapped * 1e6 + 0.5) / 1e6
end

local function formatNumber(value: number): string
	return ("%g"):format(value)
end

local function normalizeKeyCode(value: any): Enum.KeyCode?
	if typeof(value) == "EnumItem" then
		return value
	end
	if type(value) == "string" and value ~= "" and value ~= "None" then
		local ok, code = pcall(function()
			return Enum.KeyCode[value]
		end)
		if ok and code then
			return code
		end
	end
	return nil
end

local KeyShortNames = {
	[Enum.KeyCode.LeftShift] = "LShift",
	[Enum.KeyCode.RightShift] = "RShift",
	[Enum.KeyCode.LeftControl] = "LCtrl",
	[Enum.KeyCode.RightControl] = "RCtrl",
	[Enum.KeyCode.LeftAlt] = "LAlt",
	[Enum.KeyCode.RightAlt] = "RAlt",
	[Enum.KeyCode.Return] = "Enter",
	[Enum.KeyCode.CapsLock] = "Caps",
	[Enum.KeyCode.Backquote] = "`",
	[Enum.KeyCode.Minus] = "-",
	[Enum.KeyCode.Equals] = "=",
	[Enum.KeyCode.LeftBracket] = "[",
	[Enum.KeyCode.RightBracket] = "]",
	[Enum.KeyCode.Semicolon] = ";",
	[Enum.KeyCode.Quote] = "'",
	[Enum.KeyCode.Comma] = ",",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Slash] = "/",
	[Enum.KeyCode.BackSlash] = "\\",
}

local function keyDisplayName(code: Enum.KeyCode?): string
	if not code then
		return "None"
	end
	local short = KeyShortNames[code]
	if short then
		return short
	end
	local ok, name = pcall(function()
		return UserInputService:GetStringForKeyCode(code)
	end)
	if ok and name and name ~= "" then
		return name
	end
	return code.Name
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(callback)
	local handlers = self._handlers
	local connection = { Connected = true }
	function connection.Disconnect()
		if not connection.Connected then
			return
		end
		connection.Connected = false
		local index = table.find(handlers, connection)
		if index then
			table.remove(handlers, index)
		end
	end
	connection._callback = callback
	table.insert(handlers, connection)
	return connection
end

function Signal:Fire(...)
	local snapshot = table.clone(self._handlers)
	for _, connection in ipairs(snapshot) do
		if connection.Connected then
			connection._callback(...)
		end
	end
end

local Trove = {}
Trove.__index = Trove

function Trove.new()
	return setmetatable({ _objects = {} }, Trove)
end

function Trove:Add(object)
	table.insert(self._objects, object)
	return object
end

function Trove:Connect(signal, callback)
	return self:Add(signal:Connect(callback))
end

function Trove:Clean()
	local objects = self._objects
	self._objects = {}
	for index = #objects, 1, -1 do
		local object = objects[index]
		local objectType = typeof(object)
		if objectType == "Instance" then
			pcall(function()
				object:Destroy()
			end)
		elseif objectType == "RBXScriptConnection" then
			pcall(function()
				object:Disconnect()
			end)
		elseif objectType == "table" and type(object.Disconnect) == "function" then
			pcall(function()
				object:Disconnect()
			end)
		elseif objectType == "function" then
			pcall(object)
		end
	end
end

local function make(class: string, props: {[string]: any}?, children: {Instance}?): any
	local inst = Instance.new(class)
	if props then
		for key, value in pairs(props) do
			if key ~= "Parent" then
				inst[key] = value
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if props and props.Parent ~= nil then
		inst.Parent = props.Parent
	end
	return inst
end

local function tween(inst: Instance, info: TweenInfo?, props: {[string]: any}): Tween
	local created = TweenService:Create(inst, info or Theme.Animation, props)
	created:Play()
	return created
end

local function getPlayerGui(): Instance
	local player = Players.LocalPlayer
	assert(player, "[TsUI] TsUI must be used from the client (LocalScript), not the server.")
	return player:WaitForChild("PlayerGui")
end

local State = {}
State.entries = {}

function State.register(id: string, defaultValue: any, apply: (value: any, fireCallback: boolean?) -> ()): any
	local entry = State.entries[id]
	if not entry then
		entry = { value = defaultValue, apply = nil, changed = Signal.new() }
		State.entries[id] = entry
	end
	entry.apply = apply
	apply(entry.value, false)
	return entry.value
end

function State.set(id: string, value: any, fireCallback: boolean?): boolean
	local entry = State.entries[id]
	if not entry then
		entry = { value = value, apply = nil, changed = Signal.new() }
		State.entries[id] = entry
	else
		entry.value = value
	end
	if entry.apply then
		entry.apply(value, fireCallback ~= false)
	end
	entry.changed:Fire(value)
	return true
end

local Library = {}
Library.Version = "1.0.0"
Library.Theme = Theme
Library._windows = {}

local function addCorner(parent: Instance, radius: number?)
	make("UICorner", { CornerRadius = UDim.new(0, radius or Theme.CornerRadius), Parent = parent })
end

local function addStroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	return make("UIStroke", {
		Color = color or Theme.Border,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		Parent = parent,
	})
end

local function addPadding(parent: Instance, left: number, top: number, right: number, bottom: number)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, left),
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		Parent = parent,
	})
end

local function addList(parent: Instance, padding: number?)
	make("UIListLayout", {
		Padding = UDim.new(0, padding or 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local function makeRow(content: Instance, height: number?): (TextButton, TextLabel)
	local row = make("TextButton", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, height or 34),
		BackgroundColor3 = Theme.Hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = content,
	})
	local label = make("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -170, 1, 0),
		Font = Theme.FontMedium,
		TextSize = 14,
		TextColor3 = Theme.Text,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	return row, label
end

local function enableRowHover(trove: any, row: TextButton)
	trove:Connect(row.MouseEnter, function()
		if not row:GetAttribute("TsUIDisabled") then
			tween(row, Theme.FastAnimation, { BackgroundTransparency = 0.55 })
		end
	end)
	trove:Connect(row.MouseLeave, function()
		tween(row, Theme.FastAnimation, { BackgroundTransparency = 1 })
	end)
end

local function makeChevron(parent: Instance, color: Color3?): Frame
	local holder = make("Frame", {
		Name = "Chevron",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(10, 10),
		Parent = parent,
	})
	local barColor = color or Theme.TextSecondary
	make("Frame", {
		BackgroundColor3 = barColor,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(3, 5),
		Size = UDim2.fromOffset(6, 2),
		Rotation = 45,
		Parent = holder,
	})
	make("Frame", {
		BackgroundColor3 = barColor,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(7, 5),
		Size = UDim2.fromOffset(6, 2),
		Rotation = -45,
		Parent = holder,
	})
	return holder
end

local function bindState(options: {[string]: any}, defaultValue: any, apply: (value: any, fireCallback: boolean?) -> ())
	local bound = { value = defaultValue }
	if options.Id then
		bound.value = State.register(options.Id, defaultValue, apply)
		function bound.unregister()
			local entry = State.entries[options.Id]
			if entry and entry.apply == apply then
				entry.apply = nil
			end
		end
	else
		apply(bound.value, false)
	end
	function bound.get(): any
		return bound.value
	end
	function bound.set(value: any, fireCallback: boolean?)
		if options.Id then
			State.set(options.Id, value, fireCallback)
		else
			bound.value = value
			apply(value, fireCallback ~= false)
		end
	end
	return bound
end

-- Shared Get/Set/SetName surface for stateful component handles.
local function bindHandle(label: any, bound: any): {[string]: any}
	local handle = {}
	function handle:Get(): any
		return bound.get()
	end
	function handle:Set(value: any, fireCallback: boolean?)
		bound.set(value, fireCallback)
	end
	function handle:SetName(name: string)
		label.Text = tostring(name)
	end
	return handle
end

local Registry = {}
local Container = {}
Container.__index = Container

local ActiveDropdown = nil
local dropdownWatcherConn = nil

local function ensureDropdownWatcher()
	if dropdownWatcherConn then
		return
	end
	dropdownWatcherConn = UserInputService.InputBegan:Connect(function(input)
		if not ActiveDropdown then
			return
		end
		local inputType = input.UserInputType
		if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
			return
		end
		local inset = GuiService:GetGuiInset()
		local pos = Vector2.new(input.Position.X - inset.X, input.Position.Y - inset.Y)
		local list = ActiveDropdown.list
		local row = ActiveDropdown.row
		local withinList = pos.X >= list.AbsolutePosition.X
			and pos.X <= list.AbsolutePosition.X + list.AbsoluteSize.X
			and pos.Y >= list.AbsolutePosition.Y
			and pos.Y <= list.AbsolutePosition.Y + list.AbsoluteSize.Y
		local withinRow = pos.X >= row.AbsolutePosition.X
			and pos.X <= row.AbsolutePosition.X + row.AbsoluteSize.X
			and pos.Y >= row.AbsolutePosition.Y
			and pos.Y <= row.AbsolutePosition.Y + row.AbsoluteSize.Y
		if not withinList and not withinRow then
			ActiveDropdown.close()
		end
	end)
end

function Container:_create(name: string, options: {[string]: any}?): any
	local builder = Registry[name]
	assert(builder, "[TsUI] Unknown component type: " .. tostring(name))
	local handle = builder(self, options or {})
	table.insert(self._components, handle)
	return handle
end

function Container:Destroy()
	for index = #self._components, 1, -1 do
		local component = self._components[index]
		if type(component) == "table" and component.Destroy then
			component:Destroy()
		end
	end
	table.clear(self._components)
	self._trove:Clean()
end

local function buildButton(container, options)
	options = options or {}
	local trove = Trove.new()
	local destroyed = false
	local style = options.Style == "Secondary" and "Secondary" or "Primary"
	local disabled = options.Disabled == true
	local callback = options.Callback

	local colors
	if style == "Primary" then
		colors = {
			normal = Theme.Primary,
			hover = Theme.PrimaryHover,
			pressed = Theme.PrimaryPressed,
			text = Color3.fromRGB(255, 255, 255),
		}
	else
		colors = { normal = Theme.Content, hover = Theme.Hover, pressed = Theme.Border, text = Theme.Text }
	end

	local row = make("TextButton", {
		Name = "Button",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = colors.normal,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = container._content,
	})
	addCorner(row, 4)
	local stroke = nil
	if style == "Secondary" then
		stroke = addStroke(row)
	end
	local text = make("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -16, 1, 0),
		Font = Theme.FontMedium,
		TextSize = 13,
		TextColor3 = colors.text,
		Text = options.Name or "Button",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local function applyDisabled()
		row:SetAttribute("TsUIDisabled", disabled)
		if disabled then
			row.BackgroundColor3 = Theme.Hover
			text.TextColor3 = Theme.TextMuted
			if stroke then
				stroke.Transparency = 0.5
			end
		else
			row.BackgroundColor3 = colors.normal
			text.TextColor3 = colors.text
			if stroke then
				stroke.Transparency = 0
			end
		end
	end
	applyDisabled()

	trove:Connect(row.MouseEnter, function()
		if not disabled then
			tween(row, Theme.FastAnimation, { BackgroundColor3 = colors.hover })
		end
	end)
	trove:Connect(row.MouseLeave, function()
		if not disabled then
			tween(row, Theme.FastAnimation, { BackgroundColor3 = colors.normal })
		end
	end)
	trove:Connect(row.MouseButton1Down, function()
		if not disabled then
			tween(row, Theme.FastAnimation, { BackgroundColor3 = colors.pressed })
		end
	end)
	trove:Connect(row.MouseButton1Up, function()
		if not disabled then
			tween(row, Theme.FastAnimation, { BackgroundColor3 = colors.hover })
		end
	end)
	local function fire()
		if not destroyed and not disabled and callback then
			callback()
		end
	end
	trove:Connect(row.MouseButton1Click, fire)

	local handle = {}
	function handle:Click()
		fire()
	end
	function handle:SetDisabled(value: boolean)
		disabled = value == true
		applyDisabled()
	end
	function handle:SetName(name: string)
		text.Text = tostring(name)
	end
	function handle:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		trove:Clean()
	end
	return handle
end

local function buildToggle(container, options)
	options = options or {}
	local trove = Trove.new()
	local destroyed = false
	local row, label = makeRow(container._content, 34)
	label.Text = options.Name or "Toggle"
	enableRowHover(trove, row)

	local track = make("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(36, 20),
		BackgroundColor3 = Theme.Track,
		BorderSizePixel = 0,
		Parent = row,
	})
	addCorner(track, 4)
	local knob = make("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Parent = track,
	})
	addCorner(knob, 2)

	local bound
	local function apply(value: any, fireCallback: boolean?)
		if destroyed then
			return
		end
		value = value == true
		bound.value = value
		tween(track, Theme.Animation, { BackgroundColor3 = value and Theme.Primary or Theme.Track })
		tween(knob, Theme.Animation, { Position = value and UDim2.new(0, 19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
		if fireCallback and options.Callback then
			options.Callback(value)
		end
	end
	bound = bindState(options, options.Default == true, apply)
	trove:Connect(row.MouseButton1Click, function()
		if not destroyed then
			bound.set(not bound.value)
		end
	end)
	local handle = bindHandle(label, bound)
	function handle:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		if bound.unregister then
			bound.unregister()
		end
		trove:Clean()
	end
	return handle
end

local function buildSlider(container, options)
	options = options or {}
	local trove = Trove.new()
	local destroyed = false
	local minValue = tonumber(options.Min) or 0
	local maxValue = tonumber(options.Max) or 100
	if maxValue < minValue then
		minValue, maxValue = maxValue, minValue
	end
	local step = tonumber(options.Step) or 1
	local suffix = options.Suffix and tostring(options.Suffix) or ""

	local row = make("TextButton", {
		Name = "Slider",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.Hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = container._content,
	})
	local label = make("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 7),
		Size = UDim2.new(0.5, -12, 0, 16),
		Font = Theme.FontMedium,
		TextSize = 14,
		TextColor3 = Theme.Text,
		Text = options.Name or "Slider",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	local valueLabel = make("TextLabel", {
		Name = "Value",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 7),
		Size = UDim2.new(0.5, -12, 0, 16),
		Font = Theme.FontCode,
		TextSize = 12,
		TextColor3 = Theme.Primary,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	local track = make("Frame", {
		Name = "Track",
		BackgroundColor3 = Theme.Track,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0, 28),
		Size = UDim2.new(1, -24, 0, 4),
		Parent = row,
	})
	addCorner(track, 2)
	local fill = make("Frame", {
		Name = "Fill",
		BackgroundColor3 = Theme.Primary,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = track,
	})
	addCorner(fill, 2)
	local knob = make("Frame", {
		Name = "Handle",
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 12, 0, 30),
		Size = UDim2.fromOffset(12, 12),
		Parent = row,
	})
	addCorner(knob, 2)
	addStroke(knob, Theme.Border)

	local bound
	local function apply(value: any, fireCallback: boolean?)
		if destroyed then
			return
		end
		value = roundToStep(tonumber(value) or minValue, minValue, maxValue, step)
		bound.value = value
		local frac = (value - minValue) / math.max(maxValue - minValue, 1e-9)
		tween(fill, Theme.Animation, { Size = UDim2.new(frac, 0, 1, 0) })
		tween(knob, Theme.Animation, { Position = UDim2.new(frac, 12 * (1 - frac), 0, 30) })
		valueLabel.Text = formatNumber(value) .. suffix
		if fireCallback and options.Callback then
			options.Callback(value)
		end
	end
	bound = bindState(options, tonumber(options.Default) or minValue, apply)

	local dragging = false
	local function updateFromX(screenX: number)
		local insetX = GuiService:GetGuiInset().X
		local relative = screenX - insetX - track.AbsolutePosition.X
		local frac = math.clamp(relative / math.max(track.AbsoluteSize.X, 1), 0, 1)
		bound.set(minValue + (maxValue - minValue) * frac)
	end

	trove:Connect(row.InputBegan, function(input)
		local inputType = input.UserInputType
		if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	trove:Connect(UserInputService.InputChanged, function(input)
		if not dragging then
			return
		end
		local inputType = input.UserInputType
		if inputType == Enum.UserInputType.MouseMovement or inputType == Enum.UserInputType.Touch then
			updateFromX(input.Position.X)
		end
	end)
	trove:Connect(UserInputService.InputEnded, function(input)
		local inputType = input.UserInputType
		if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local handle = bindHandle(label, bound)
	function handle:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		if bound.unregister then
			bound.unregister()
		end
		trove:Clean()
	end
	return handle
end

local function buildDropdown(container, options)
	options = options or {}
	local trove = Trove.new()
	local optionTrove = Trove.new()
	local destroyed = false
	local optionList: { string } = options.Options or {}
	local row, label = makeRow(container._content, 34)
	label.Text = options.Name or "Dropdown"
	enableRowHover(trove, row)

	local valueLabel = make("TextLabel", {
		Name = "Value",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -28, 0.5, 0),
		Size = UDim2.new(0.55, -16, 1, 0),
		Font = Theme.FontMedium,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
		Parent = row,
	})
	local chevron = makeChevron(row, Theme.TextSecondary)

	local list = make("Frame", {
		Name = "DropdownList",
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, 6),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 10,
		Parent = row,
	})
	addCorner(list, 4)
	addStroke(list)
	local scroll = make("ScrollingFrame", {
		Name = "Options",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Track,
		ZIndex = 2,
		Parent = list,
	})
	addPadding(scroll, 4, 4, 4, 4)
	addList(scroll, 2)

	local bound
	local selected = nil
	local optionRows = {}
	local isOpen = false
	local zRestore = {}
	local setOpen

	local function refreshRows()
		for value, entry in pairs(optionRows) do
			local isSelected = value == selected
			entry.label.TextColor3 = isSelected and Theme.Primary or Theme.Text
			entry.label.Font = isSelected and Theme.FontBold or Theme.Font
		end
	end

	local function buildOptionRows()
		optionTrove:Clean()
		table.clear(optionRows)
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for _, value in ipairs(optionList) do
			local optRow = make("TextButton", {
				Name = "Option",
				BackgroundColor3 = Theme.Hover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, 28),
				Text = "",
				ZIndex = 3,
				Parent = scroll,
			})
			local optLabel = make("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -20, 1, 0),
				Font = Theme.Font,
				TextSize = 13,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = tostring(value),
				Parent = optRow,
			})
			optionTrove:Connect(optRow.MouseEnter, function()
				tween(optRow, Theme.FastAnimation, { BackgroundTransparency = 0 })
			end)
			optionTrove:Connect(optRow.MouseLeave, function()
				tween(optRow, Theme.FastAnimation, { BackgroundTransparency = 1 })
			end)
			optionTrove:Connect(optRow.MouseButton1Click, function()
				setOpen(false)
				if not destroyed then
					bound.set(value)
				end
			end)
			optionRows[value] = { label = optLabel }
		end
		refreshRows()
	end

	local function listHeight(): number
		return math.min(#optionList * 30 + 8, 156)
	end

	setOpen = function(open: boolean)
		if destroyed or isOpen == open then
			return
		end
		isOpen = open
		if open then
			ensureDropdownWatcher()
			if ActiveDropdown and ActiveDropdown.close then
				ActiveDropdown.close()
			end
			local height = listHeight()
			local ancestor = row:FindFirstAncestorOfClass("ScrollingFrame")
			local openUpward = false
			if ancestor then
				local rowBottom = row.AbsolutePosition.Y + row.AbsoluteSize.Y
				local scrollBottom = ancestor.AbsolutePosition.Y + ancestor.AbsoluteSize.Y
				openUpward = rowBottom + height + 10 > scrollBottom
					and (row.AbsolutePosition.Y - height - 6) > ancestor.AbsolutePosition.Y
			end
			list.Position = openUpward and UDim2.new(0, 0, 0, -(height + 6)) or UDim2.new(0, 0, 1, 6)
			local node: Instance? = row
			while node and node:IsA("GuiObject") and not node:IsA("ScrollingFrame") do
				table.insert(zRestore, { node, node.ZIndex })
				node.ZIndex = 500
				node = node.Parent
			end
			list.Visible = true
			list.Size = UDim2.new(1, 0, 0, 0)
			tween(list, Theme.FastAnimation, { Size = UDim2.new(1, 0, 0, height) })
			tween(chevron, Theme.FastAnimation, { Rotation = 180 })
			ActiveDropdown = {
				close = function()
					setOpen(false)
				end,
				row = row,
				list = list,
				gui = row:FindFirstAncestorOfClass("ScreenGui"),
			}
		else
			for _, item in ipairs(zRestore) do
				if item[1].Parent then
					item[1].ZIndex = item[2]
				end
			end
			table.clear(zRestore)
			tween(list, Theme.FastAnimation, { Size = UDim2.new(1, 0, 0, 0) })
			tween(chevron, Theme.FastAnimation, { Rotation = 0 })
			task.delay(0.13, function()
				if not isOpen then
					list.Visible = false
				end
			end)
			if ActiveDropdown and ActiveDropdown.row == row then
				ActiveDropdown = nil
			end
		end
	end

	local function apply(value: any, fireCallback: boolean?)
		if destroyed then
			return
		end
		selected = value
		valueLabel.Text = value ~= nil and tostring(value) or "Select..."
		refreshRows()
		if fireCallback and options.Callback then
			options.Callback(value)
		end
	end

	bound = bindState(options, options.Default ~= nil and options.Default or optionList[1], apply)
	buildOptionRows()

	trove:Connect(row.MouseButton1Click, function()
		setOpen(not isOpen)
	end)

	local handle = bindHandle(label, bound)
	function handle:SetOptions(newOptions: { string }?, keepSelection: boolean?)
		optionList = newOptions or {}
		if not keepSelection or selected == nil or table.find(optionList, selected) == nil then
			selected = nil
		end
		buildOptionRows()
		apply(selected or optionList[1], false)
	end
	function handle:Destroy()
		if destroyed then
			return
		end
		setOpen(false)
		destroyed = true
		if bound.unregister then
			bound.unregister()
		end
		optionTrove:Clean()
		trove:Clean()
	end
	return handle
end

local function buildInput(container, options)
	options = options or {}
	local trove = Trove.new()
	local destroyed = false
	local row, label = makeRow(container._content, 34)
	label.Text = options.Name or "Input"

	local box = make("TextBox", {
		Name = "Input",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, options.Width or 150, 0, 26),
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.Text,
		PlaceholderColor3 = Theme.TextMuted,
		PlaceholderText = options.Placeholder or "",
		Text = options.Default or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Parent = row,
	})
	addCorner(box, 4)
	addPadding(box, 8, 0, 8, 0)
	local stroke = addStroke(box)

	local bound
	local function apply(value: any, fireCallback: boolean?)
		if destroyed then
			return
		end
		value = tostring(value or "")
		if box.Text ~= value then
			box.Text = value
		end
		if fireCallback and options.Callback then
			options.Callback(value)
		end
	end
	bound = bindState(options, options.Default or "", apply)

	trove:Connect(box.Focused, function()
		tween(stroke, Theme.FastAnimation, { Color = Theme.Primary })
	end)
	trove:Connect(box.FocusLost, function()
		tween(stroke, Theme.FastAnimation, { Color = Theme.Border })
		if not destroyed then
			bound.set(box.Text)
		end
	end)

	local handle = bindHandle(label, bound)
	function handle:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		if bound.unregister then
			bound.unregister()
		end
		trove:Clean()
	end
	return handle
end

local function buildKeybind(container, options)
	options = options or {}
	local trove = Trove.new()
	local destroyed = false
	local row, label = makeRow(container._content, 34)
	label.Text = options.Name or "Keybind"

	local keyButton = make("TextButton", {
		Name = "Key",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(88, 26),
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Theme.FontMedium,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Text = "",
		Parent = row,
	})
	addCorner(keyButton, 4)
	addStroke(keyButton)

	local bound
	local currentKey = nil
	local listening = false
	local listenConn = nil

	local function apply(value: any, fireCallback: boolean?)
		if destroyed then
			return
		end
		currentKey = normalizeKeyCode(value)
		bound.value = currentKey
		keyButton.Text = keyDisplayName(currentKey)
		keyButton.TextColor3 = currentKey and Theme.Text or Theme.TextMuted
		if fireCallback and options.OnChanged then
			options.OnChanged(currentKey)
		end
	end
	bound = bindState(options, options.Default, apply)

	trove:Connect(keyButton.MouseEnter, function()
		if not listening then
			tween(keyButton, Theme.FastAnimation, { BackgroundColor3 = Theme.Hover })
		end
	end)
	trove:Connect(keyButton.MouseLeave, function()
		if not listening then
			tween(keyButton, Theme.FastAnimation, { BackgroundColor3 = Theme.Content })
		end
	end)
	trove:Connect(keyButton.MouseButton1Click, function()
		if listening or destroyed then
			return
		end
		listening = true
		keyButton.Text = "..."
		keyButton.TextColor3 = Theme.Primary
		listenConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			listenConn:Disconnect()
			listenConn = nil
			listening = false
			if input.KeyCode == Enum.KeyCode.Escape then
				apply(bound.value, false)
				return
			end
			bound.set(input.KeyCode)
		end)
	end)

	trove:Connect(UserInputService.InputBegan, function(input, gameProcessed)
		if destroyed or listening or gameProcessed then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if currentKey and input.KeyCode == currentKey and input.UserInputType == Enum.UserInputType.Keyboard then
			if options.Callback then
				options.Callback(currentKey)
			end
		end
	end)

	local handle = bindHandle(label, bound)
	function handle:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		if listenConn then
			listenConn:Disconnect()
			listenConn = nil
		end
		if bound.unregister then
			bound.unregister()
		end
		trove:Clean()
	end
	return handle
end

local function buildLabel(container, options)
	options = options or {}
	local trove = Trove.new()
	local holder = make("Frame", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = container._content,
	})
	addPadding(holder, 12, 2, 12, 2)
	addList(holder, 3)
	local main = make("TextLabel", {
		Name = "Text",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Theme.FontMedium,
		TextSize = 14,
		TextColor3 = Theme.Text,
		Text = options.Text or "Label",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = holder,
	})
	local sub = make("TextLabel", {
		Name = "SubText",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.TextSecondary,
		Text = options.SubText or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Visible = (options.SubText or "") ~= "",
		Parent = holder,
	})

	local handle = {}
	function handle:SetText(value: string)
		main.Text = tostring(value or "")
	end
	function handle:SetSubText(value: string)
		sub.Text = tostring(value or "")
		sub.Visible = sub.Text ~= ""
	end
	function handle:Destroy()
		trove:Clean()
	end
	return handle
end

local function buildDivider(container, options)
	options = options or {}
	local trove = Trove.new()
	local hasName = options.Name ~= nil and options.Name ~= ""
	local holder = make("Frame", {
		Name = "Divider",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, hasName and 30 or 10),
		Parent = container._content,
	})
	if hasName then
		make("TextLabel", {
			Name = "Header",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 2),
			Size = UDim2.new(1, -24, 0, 14),
			Font = Theme.FontBold,
			TextSize = 11,
			TextColor3 = Theme.TextSecondary,
			Text = string.upper(tostring(options.Name)),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = holder,
		})
	end
	make("Frame", {
		Name = "Line",
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 1, -1),
		Size = UDim2.new(1, -24, 0, 1),
		Parent = holder,
	})
	local handle = {}
	function handle:Destroy()
		trove:Clean()
	end
	return handle
end

local function buildSection(container, options)
	options = options or {}
	local trove = Trove.new()
	local card = make("Frame", {
		Name = "Section",
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = container._content,
	})
	trove:Add(card)
	addCorner(card, 4)
	addStroke(card)
	addList(card, 8)
	addPadding(card, 10, options.Name and 10 or 12, 10, 12)

	if options.Name then
		make("TextLabel", {
			Name = "Header",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Font = Theme.FontBold,
			TextSize = 11,
			TextColor3 = Theme.TextSecondary,
			Text = string.upper(tostring(options.Name)),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
	end

	local content = make("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	addList(content, 4)

	local section = setmetatable({
		_content = content,
		_components = {},
		_trove = Trove.new(),
		Name = options.Name,
	}, Container)

	function section:SetName(name: string)
		self.Name = name
		local header = card:FindFirstChild("Header")
		if header then
			header.Text = string.upper(tostring(name))
		end
	end
	function section:Destroy()
		Container.Destroy(self)
		trove:Clean()
	end
	return section
end

function Library:RegisterComponent(name: string, builder: (container: any, options: {[string]: any}) -> any)
	assert(type(name) == "string" and #name > 0, "[TsUI] Component name must be a non-empty string")
	assert(type(builder) == "function", "[TsUI] Component builder must be a function")
	Registry[name] = builder
	local methodName = "Create" .. name
	if Container[methodName] == nil then
		Container[methodName] = function(self, options)
			return self:_create(name, options)
		end
	end
end

Library:RegisterComponent("Button", buildButton)
Library:RegisterComponent("Toggle", buildToggle)
Library:RegisterComponent("Slider", buildSlider)
Library:RegisterComponent("Dropdown", buildDropdown)
Library:RegisterComponent("Input", buildInput)
Library:RegisterComponent("Keybind", buildKeybind)
Library:RegisterComponent("Label", buildLabel)
Library:RegisterComponent("Divider", buildDivider)
Library:RegisterComponent("Section", buildSection)

local WindowMethods = {}
WindowMethods.__index = WindowMethods

local function createTab(window, options)
	options = options or {}
	local name = tostring(options.Name or "Tab")

	local railButton = make("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.RailHover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = window._rail,
	})
	local indicator = make("Frame", {
		Name = "Indicator",
		BackgroundColor3 = Theme.AccentLight,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 18),
		Visible = false,
		Parent = railButton,
	})
	local railLabel = make("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Font = Theme.FontMedium,
		TextSize = 13,
		TextColor3 = Theme.RailText,
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = railButton,
	})
	local page = make("ScrollingFrame", {
		Name = "Page",
		BackgroundColor3 = Theme.Page,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Track,
		Visible = false,
		Parent = window._contentArea,
	})
	addPadding(page, 14, 14, 14, 14)
	addList(page, 12)

	local tab = setmetatable({
		_content = page,
		_page = page,
		_components = {},
		_trove = Trove.new(),
		_window = window,
		_railButton = railButton,
		_indicator = indicator,
		_railLabel = railLabel,
		Name = name,
	}, Container)
	tab._trove:Add(railButton)
	tab._trove:Add(page)

	tab._trove:Connect(railButton.MouseButton1Click, function()
		window:SelectTab(tab)
	end)
	tab._trove:Connect(railButton.MouseEnter, function()
		if window._activeTab ~= tab then
			tween(railButton, Theme.FastAnimation, { BackgroundTransparency = 0.5 })
		end
	end)
	tab._trove:Connect(railButton.MouseLeave, function()
		if window._activeTab ~= tab then
			tween(railButton, Theme.FastAnimation, { BackgroundTransparency = 1 })
		end
	end)

	function tab:Select()
		window:SelectTab(self)
		return self
	end
	function tab:SetName(newName: string)
		self.Name = tostring(newName)
		railLabel.Text = self.Name
	end
	function tab:Destroy()
		local tabs = window._tabs
		local index = table.find(tabs, self)
		if index then
			table.remove(tabs, index)
		end
		if window._activeTab == self then
			window._activeTab = nil
			if tabs[1] then
				window:SelectTab(tabs[1])
			end
		end
		Container.Destroy(self)
	end

	table.insert(window._tabs, tab)
	if #window._tabs == 1 then
		window:SelectTab(tab)
	end
	return tab
end

function WindowMethods:CreateTab(options): any
	return createTab(self, options)
end

function WindowMethods:SelectTab(target): any?
	local tab = nil
	if typeof(target) == "table" then
		tab = target
	else
		for _, existing in ipairs(self._tabs) do
			if existing.Name == target then
				tab = existing
				break
			end
		end
	end
	if not tab or tab == self._activeTab then
		return tab
	end
	local previous = self._activeTab
	self._activeTab = tab
	if previous then
		previous._page.Visible = false
		previous._railButton.BackgroundTransparency = 1
		previous._indicator.Visible = false
		previous._railLabel.TextColor3 = Theme.RailText
		previous._railLabel.Font = Theme.FontMedium
	end
	tab._page.Visible = true
	tab._railButton.BackgroundTransparency = 0
	tab._indicator.Visible = true
	tab._railLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	tab._railLabel.Font = Theme.FontBold
	return tab
end

function WindowMethods:SetVisible(visible: boolean)
	self._gui.Enabled = visible == true
end

function WindowMethods:Toggle()
	self._gui.Enabled = not self._gui.Enabled
end

function WindowMethods:SetMinimized(minimized: boolean)
	if self._minimized == minimized then
		return
	end
	self._minimized = minimized
	local full = self._size
	local target = minimized and UDim2.new(full.X.Scale, full.X.Offset, 0, 44) or full
	tween(self._main, Theme.Animation, { Size = target })
end

function WindowMethods:SetTitle(title: string)
	self.Title = tostring(title)
	self._titleLabel.Text = self.Title
	self._gui.Name = "TsUI_" .. self.Title
end

function WindowMethods:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	for index = #self._tabs, 1, -1 do
		self._tabs[index]:Destroy()
	end
	if ActiveDropdown and ActiveDropdown.gui == self._gui and ActiveDropdown.close then
		ActiveDropdown.close()
	end
	local index = table.find(Library._windows, self)
	if index then
		table.remove(Library._windows, index)
	end
	self._trove:Clean()
end

function Library:CreateWindow(options): any
	options = options or {}
	local playerGui = getPlayerGui()

	local gui = make("ScreenGui", {
		Name = "TsUI_" .. tostring(options.Title or "Window"),
		ResetOnSpawn = false,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})

	local size = options.Size or UDim2.fromOffset(680, 480)
	local trove = Trove.new()
	trove:Add(gui)

	make("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.6,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, 90, 1, 90),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 0,
		Parent = gui,
	})

	local main = make("Frame", {
		Name = "Main",
		Size = size,
		Position = options.Position or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Page,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = gui,
	})
	addCorner(main, 6)
	addStroke(main, Theme.Border, 1, 0.3)
	if options.Scale then
		make("UIScale", { Scale = options.Scale, Parent = main })
	end

	local titleBar = make("Frame", {
		Name = "TitleBar",
		BackgroundColor3 = Theme.TitleBar,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = main,
	})
	addCorner(titleBar, 6)
	make("Frame", {
		Name = "CornerPatch",
		BackgroundColor3 = Theme.TitleBar,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 1, -8),
		Parent = titleBar,
	})

	local logo = make("Frame", {
		Name = "Logo",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(24, 24),
		Parent = titleBar,
	})
	addCorner(logo, 4)
	make("TextLabel", {
		Name = "LogoText",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = Theme.Primary,
		Text = tostring(options.LogoText or "TS"),
		Parent = logo,
	})

	local titleLabel = make("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(44, 0),
		Size = UDim2.new(1, -130, 1, 0),
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = tostring(options.Title or "Window"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleBar,
	})

	local function makeTitleButton(glyph: string, xOffset: number): TextButton
		local button = make("TextButton", {
			Name = "TitleButton",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Theme.Font,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Text = glyph,
			Parent = titleBar,
		})
		addCorner(button, 4)
		trove:Connect(button.MouseEnter, function()
			tween(button, Theme.FastAnimation, { BackgroundTransparency = 0.85 })
		end)
		trove:Connect(button.MouseLeave, function()
			tween(button, Theme.FastAnimation, { BackgroundTransparency = 1 })
		end)
		return button
	end

	local closeButton = makeTitleButton("×", -10)
	local minButton = makeTitleButton("–", -42)

	local rail = make("ScrollingFrame", {
		Name = "Rail",
		BackgroundColor3 = Theme.Rail,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(0, 168, 1, -44),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.RailHover,
		Parent = main,
	})
	addList(rail, 2)
	addPadding(rail, 0, 8, 0, 8)

	local contentArea = make("Frame", {
		Name = "Content",
		BackgroundColor3 = Theme.Page,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 168, 0, 44),
		Size = UDim2.new(1, -168, 1, -44),
		Parent = main,
	})

	local window = setmetatable({
		_gui = gui,
		_main = main,
		_rail = rail,
		_contentArea = contentArea,
		_titleLabel = titleLabel,
		_tabs = {},
		_activeTab = nil,
		_trove = trove,
		_size = size,
		_minimized = false,
		_destroyed = false,
		Title = tostring(options.Title or "Window"),
	}, WindowMethods)

	local dragging = false
	local dragStart = nil
	local startPosition = nil

	trove:Connect(titleBar.InputBegan, function(input)
		local inputType = input.UserInputType
		if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = UserInputService:GetMouseLocation()
			startPosition = main.Position
		end
	end)
	trove:Connect(UserInputService.InputChanged, function(input)
		if not dragging then
			return
		end
		local inputType = input.UserInputType
		if inputType == Enum.UserInputType.MouseMovement or inputType == Enum.UserInputType.Touch then
			local delta = UserInputService:GetMouseLocation() - dragStart
			main.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
	trove:Connect(UserInputService.InputEnded, function(input)
		local inputType = input.UserInputType
		if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	if options.ToggleKey ~= nil then
		trove:Connect(UserInputService.InputBegan, function(input, gameProcessed)
			if gameProcessed or window._destroyed then
				return
			end
			if UserInputService:GetFocusedTextBox() then
				return
			end
			if input.KeyCode == options.ToggleKey then
				window:Toggle()
			end
		end)
	end

	trove:Connect(closeButton.MouseButton1Click, function()
		if options.CloseBehavior == "Destroy" then
			window:Destroy()
		else
			gui.Enabled = false
		end
	end)
	trove:Connect(minButton.MouseButton1Click, function()
		window:SetMinimized(not window._minimized)
	end)

	table.insert(Library._windows, window)
	return window
end

local notifGui = nil
local notifList = nil
local activeToasts = {}

local function ensureNotificationGui()
	if notifGui then
		return
	end
	notifGui = make("ScreenGui", {
		Name = "TsUI_Notifications",
		ResetOnSpawn = false,
		DisplayOrder = 200,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = getPlayerGui(),
	})
	notifList = make("Frame", {
		Name = "Stack",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 320, 1, -32),
		Parent = notifGui,
	})
	make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Parent = notifList,
	})
end

function Library:Notify(options)
	options = options or {}
	ensureNotificationGui()

	local kind = options.Type or "Info"
	local accents = {
		Info = Theme.Primary,
		Success = Theme.Success,
		Warning = Theme.Warning,
		Error = Theme.Danger,
	}
	local accent = accents[kind] or Theme.Primary
	local title = tostring(options.Title or kind)
	local message = options.Message ~= nil and tostring(options.Message) or ""
	local duration = math.max(tonumber(options.Duration) or 5, 1)

	local messageHeight = 0
	if message ~= "" then
		messageHeight = TextService:GetTextSize(message, 12, Theme.Font, Vector2.new(288, 10000)).Y
	end
	local height = 12 + 18 + (message ~= "" and 4 + messageHeight or 0) + 12

	local wrapper = make("Frame", {
		Name = "Toast",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 320, 0, height),
		Parent = notifList,
	})
	local toast = make("CanvasGroup", {
		Name = "Card",
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 340, 0, 0),
		GroupTransparency = 1,
		Parent = wrapper,
	})
	addCorner(toast, 4)
	addStroke(toast)
	make("Frame", {
		Name = "Accent",
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 1),
		Size = UDim2.new(0, 4, 1, -2),
		Parent = toast,
	})
	make("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -32, 0, 16),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = toast,
	})
	if message ~= "" then
		make("TextLabel", {
			Name = "Message",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 26),
			Size = UDim2.new(1, -32, 0, messageHeight),
			Font = Theme.Font,
			TextSize = 12,
			TextColor3 = Theme.TextSecondary,
			Text = message,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = toast,
		})
	end
	local progressTrack = make("Frame", {
		Name = "Progress",
		BackgroundColor3 = Theme.Hover,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 1, -6),
		Size = UDim2.new(1, -16, 0, 2),
		Parent = toast,
	})
	local progressFill = make("Frame", {
		Name = "Fill",
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = progressTrack,
	})

	local dismissed = false
	local dismissSelf
	dismissSelf = function()
		if dismissed then
			return
		end
		dismissed = true
		local index = table.find(activeToasts, dismissSelf)
		if index then
			table.remove(activeToasts, index)
		end
		tween(toast, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 340, 0, 0),
			GroupTransparency = 1,
		})
		task.delay(0.16, function()
			wrapper:Destroy()
		end)
		if options.Callback then
			pcall(options.Callback)
		end
	end

	toast.InputBegan:Connect(function(input)
		local inputType = input.UserInputType
		if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
			dismissSelf()
		end
	end)

	table.insert(activeToasts, dismissSelf)
	while #activeToasts > 6 do
		local oldest = table.remove(activeToasts, 1)
		oldest()
	end

	tween(toast, Theme.Animation, { Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 })
	local fillTween = TweenService:Create(
		progressFill,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ Size = UDim2.new(0, 0, 1, 0) }
	)
	fillTween:Play()
	task.delay(duration, function()
		if not dismissed then
			dismissSelf()
		end
	end)
end

function Library:Get(id: string): any
	local entry = State.entries[id]
	return entry and entry.value
end

function Library:Set(id: string, value: any, fireCallback: boolean?): boolean
	return State.set(id, value, fireCallback)
end

function Library:Toggle(id: string, fireCallback: boolean?): boolean
	local entry = State.entries[id]
	if entry and type(entry.value) == "boolean" then
		return Library:Set(id, not entry.value, fireCallback)
	end
	return false
end

function Library:OnChanged(id: string, callback: (value: any) -> ())
	local entry = State.entries[id]
	if not entry then
		entry = { value = nil, apply = nil, changed = Signal.new() }
		State.entries[id] = entry
	end
	return entry.changed:Connect(callback)
end

function Library:SerializeConfig(): {[string]: any}
	local config = {}
	for id, entry in pairs(State.entries) do
		local value = entry.value
		if typeof(value) == "EnumItem" then
			value = value.Name
		end
		config[id] = value
	end
	return config
end

function Library:ApplyConfig(config: {[string]: any})
	assert(type(config) == "table", "[TsUI] ApplyConfig expects a table of { [Id] = value }")
	for id, value in pairs(config) do
		Library:Set(id, value)
	end
end

local fsAvailable = typeof(writefile) == "function"
	and typeof(readfile) == "function"
	and typeof(isfile) == "function"
	and typeof(isfolder) == "function"
	and typeof(makefolder) == "function"

local configFolder = "TsUI_Configs"

function Library:SetConfigFolder(folder: string)
	configFolder = tostring(folder)
end

function Library:SaveConfig(name: string): boolean
	if not fsAvailable then
		return false
	end
	local ok = pcall(function()
		if not isfolder(configFolder) then
			makefolder(configFolder)
		end
		writefile(configFolder .. "/" .. tostring(name) .. ".json", HttpService:JSONEncode(Library:SerializeConfig()))
	end)
	return ok
end

function Library:LoadConfig(name: string): boolean
	if not fsAvailable then
		return false
	end
	local ok, result = pcall(function()
		local path = configFolder .. "/" .. tostring(name) .. ".json"
		if isfile(path) then
			return HttpService:JSONDecode(readfile(path))
		end
		return nil
	end)
	if ok and type(result) == "table" then
		Library:ApplyConfig(result)
		return true
	end
	return false
end

function Library:SetTheme(overrides: {[string]: any})
	for key, value in pairs(overrides or {}) do
		Theme[key] = value
	end
end

function Library:Destroy()
	for index = #Library._windows, 1, -1 do
		Library._windows[index]:Destroy()
	end
	table.clear(Library._windows)
	if ActiveDropdown and ActiveDropdown.close then
		ActiveDropdown.close()
	end
	if dropdownWatcherConn then
		dropdownWatcherConn:Disconnect()
		dropdownWatcherConn = nil
	end
	if notifGui then
		notifGui:Destroy()
		notifGui = nil
		notifList = nil
	end
	table.clear(activeToasts)
end

return Library
