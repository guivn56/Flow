--[[ gerado por airflowui/build.py -- nao editar a mao ]]
-- =====================================================================
-- main.lua - AirflowUI
--
-- Menu do Airflow (biblioteca AirFlowLibrary.luau) com o layout do
-- BBC Hub: cada aba tem DUAS COLUNAS lado a lado, cada secao tem o
-- seu cabecalho e a logica pesada fica em marcadores.
--
-- Ficheiros:
--   main.lua          este: biblioteca, tema, janela, fundo hexagonal,
--                     watermark, painel de keybinds, Settings e abas
--   tabs/visuals.lua  aba VISUALS
--   tabs/players.lua  aba PLAYER
--   tabs/combat.lua   aba COMBAT
--   tabs/world.lua    aba WORLD
--   tabs/misc.lua     aba MISC
--   tabs/lootfinder.lua aba LOOTFINDER
--   tabs/server.lua   aba SERVER
--
-- Correr no Delta: cola este ficheiro. A biblioteca e buscada na internet
-- (game:HttpGet), por isso funciona no telemóvel sem ficheiro local. As
-- abas vêm embutidas no bundle (ou de /sdcard/Delta/Workspace/AirflowUI/tabs
-- quando se corre o projecto em claro).
-- =====================================================================

local ROOT = "/sdcard/Delta/Workspace/AirflowUI"
local LIBRARY_PATH = "/sdcard/Download/AirFlowLibrary.luau"

-- ---------------------------------------------------------------------
-- 1. AJUDANTES
-- ---------------------------------------------------------------------
-- O IsA do Roblox devolve true para as subclasses ("GuiObject" e true
-- para um Frame). Alguns ambientes (e o mock de testes) só devolvem true
-- para o nome exato, por isso o teste e feito classe a classe.
local GUI_CLASSES = {
	"GuiObject",
	"Frame",
	"TextLabel",
	"TextButton",
	"TextBox",
	"ScrollingFrame",
	"ImageLabel",
	"ViewportFrame",
}

local function isGui(object)
	-- No Roblox uma Instance e um "userdata", no mock e uma "table".
	if not object then
		return false
	end
	local kind = type(object)
	if kind ~= "table" and kind ~= "userdata" then
		return false
	end
	for _, class in ipairs(GUI_CLASSES) do
		if object:IsA(class) then
			return true
		end
	end
	return false
end

-- ---------------------------------------------------------------------
-- 2. BIBLIOTECA
-- ---------------------------------------------------------------------
local function loadLibrary()
	local env = getgenv and getgenv()
	if env and type(env.AirFlow) == "table" then
		return env.AirFlow
	end
	if env and type(env.Library) == "table" then
		return env.Library
	end
	-- Biblioteca veio do GitHub: funciona no Delta/mobile, onde nao ha
	-- ficheiro local da biblioteca.
	local ok, lib = pcall(function()
		local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/guivn56/Flow/main/AirFlowLibrary.luau"))()
		return Library
	end)
	if ok and type(lib) == "table" then
		return lib
	end
	-- Rede fora: tenta o ficheiro local (executores de PC).
	if readfile and loadstring then
		local okFile, libFile = pcall(function()
			return loadstring(readfile(LIBRARY_PATH))()
		end)
		if okFile and type(libFile) == "table" then
			return libFile
		end
	end
	return nil
end

local AirFlow = loadLibrary()
assert(AirFlow, "[Airflow] nao foi possivel carregar a biblioteca (HttpGet + " .. LIBRARY_PATH .. ")")

-- ---------------------------------------------------------------------
-- 3. TEMA (BBC Hub: cinza escuro + roxo so nos botoes)
-- ---------------------------------------------------------------------
local DARK_THEME = {
	Accent = Color3.fromRGB(170, 80, 255),
	AccentDark = Color3.fromRGB(90, 40, 160),
	Background = Color3.fromRGB(15, 15, 15),
	Surface = Color3.fromRGB(22, 22, 22),
	Surface2 = Color3.fromRGB(30, 30, 30),
	Surface3 = Color3.fromRGB(40, 40, 40),
	Stroke = Color3.fromRGB(50, 50, 50),
	StrokeHover = Color3.fromRGB(80, 80, 80),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(160, 160, 160),
}

-- O tema e aplicado ANTES da janela: assim tudo ja nasce com as cores
-- certas (sem o "flash" da paleta antiga).
AirFlow:SetTheme(DARK_THEME, true)

-- ---------------------------------------------------------------------
-- 4. JANELA
-- ---------------------------------------------------------------------
local window = AirFlow:Window({
	Name = "AirflowUI",
	Title = "Airflow",
	Theme = DARK_THEME,
	Size = UDim2.fromOffset(760, 520),
})

-- ---------------------------------------------------------------------
-- 5. FUNDO HEXAGONAL
--
-- Um ImageLabel com o padrao hexagonal em mosaico (50x50) por baixo de
-- tudo o que esta dentro da janela (ZIndex -1). Vive no Body para
-- ficar preso a janela e desaparecer com ela.
-- ---------------------------------------------------------------------
local function createHexBackground(win)
	local host = win.Body or win.Root
	if not host then
		return nil
	end
	local hex = Instance.new("ImageLabel")
	hex.Name = "HexBackground"
	hex.Size = UDim2.fromScale(1, 1)
	hex.Position = UDim2.fromOffset(0, 0)
	hex.BackgroundTransparency = 1
	hex.BorderSizePixel = 0
	hex.Image = "rbxassetid://12629542321"
	hex.ScaleType = Enum.ScaleType.Tile
	hex.TileSize = UDim2.fromOffset(50, 50)
	hex.ImageColor3 = Color3.fromRGB(20, 20, 20)
	hex.ImageTransparency = 0.8
	hex.ZIndex = -1
	hex.Parent = host
	return hex
end

createHexBackground(window)

-- ---------------------------------------------------------------------
-- 6. WATERMARK E TIMER
--
-- Uma caixa no topo central da tela: o nome do hub e o tempo que o
-- script esta a correr (os segundos desde que a biblioteca carregou).
-- Fica acima de tudo e nunca rouba o input do menu.
-- ---------------------------------------------------------------------
local watermark = window:CreateWatermark({
	Name = "Airflow",
})

-- A posicao e corrigida aqui: topo central da tela (0.5, 0), com a
-- margem de 10 px do topo.
do
	local guis = window._watermarks
	local gui = guis and guis[#guis]
	local box = gui and gui:FindFirstChild("Watermark")
	if box and isGui(box) then
		box.Position = UDim2.new(0.5, 0, 0, 10)
		box.AnchorPoint = Vector2.new(0.5, 0)
		box.ZIndex = 1
	end
end

-- ---------------------------------------------------------------------
-- 7. PAINEL DE KEYBINDS (canto superior direito)
--
-- Lista dos atalhos do hub. So UI: nenhuma tecla e lida aqui, a lista
-- e apenas informativa.
-- ---------------------------------------------------------------------
local KEYBINDS = {
	{ key = "RShift", label = "UI" },
	{ key = "LAlt", label = "Cursor" },
	{ key = "Equals", label = "Auto Run" },
	{ key = "G", label = "Fly" },
	{ key = "X", label = "Third Person" },
	{ key = "Z", label = "Zoom" },
	{ key = "C", label = "Lock" },
	{ key = "B", label = "Activation" },
	{ key = "J", label = "Aim Parts" },
	{ key = "MB3", label = "Add Friend" },
	{ key = "U", label = "Underground" },
}

local function guiParent()
	local hidden
	pcall(function()
		if typeof(gethui) == "function" then
			hidden = gethui()
		end
	end)
	if typeof(hidden) == "Instance" then
		return hidden
	end
	local core
	pcall(function()
		core = game:GetService("CoreGui")
		local probe = Instance.new("Folder")
		probe.Parent = core
		probe:Destroy()
	end)
	if core then
		return core
	end
	return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

local function createKeybindPanel()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AirflowKeybinds"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 998
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = guiParent()

	local panel = Instance.new("Frame")
	panel.Name = "KeybindPanel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -14, 0, 10)
	panel.Size = UDim2.fromOffset(190, 34 + #KEYBINDS * 18 + 10)
	panel.BackgroundColor3 = DARK_THEME.Surface
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Active = false
	panel.ZIndex = 1
	panel.Parent = gui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = DARK_THEME.Stroke
	panelStroke.Thickness = 1
	panelStroke.Transparency = 0.35
	panelStroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(12, 8)
	title.Size = UDim2.new(1, -24, 0, 16)
	title.Font = Enum.Font.GothamBold
	title.Text = "KEYBINDS"
	title.TextSize = 11
	title.TextColor3 = DARK_THEME.Muted
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 2
	title.Parent = panel

	local rows = Instance.new("Frame")
	rows.Name = "Rows"
	rows.BackgroundTransparency = 1
	rows.Position = UDim2.fromOffset(0, 28)
	rows.Size = UDim2.new(1, 0, 1, -34)
	rows.ZIndex = 2
	rows.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = rows

	for index, entry in ipairs(KEYBINDS) do
		local row = Instance.new("Frame")
		row.Name = entry.key
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -12, 0, 16)
		row.Position = UDim2.fromOffset(6, 0)
		row.LayoutOrder = index
		row.ZIndex = 2
		row.Parent = rows

		local chip = Instance.new("TextLabel")
		chip.Name = "Key"
		chip.BackgroundColor3 = DARK_THEME.Surface2
		chip.BackgroundTransparency = 0.1
		chip.BorderSizePixel = 0
		chip.Position = UDim2.fromOffset(0, 0)
		chip.Size = UDim2.fromOffset(62, 16)
		chip.Font = Enum.Font.GothamBold
		chip.Text = entry.key
		chip.TextSize = 11
		chip.TextColor3 = DARK_THEME.Accent
		chip.TextXAlignment = Enum.TextXAlignment.Center
		chip.ZIndex = 3
		chip.Parent = row

		local chipCorner = Instance.new("UICorner")
		chipCorner.CornerRadius = UDim.new(1, 0)
		chipCorner.Parent = chip

		local chipStroke = Instance.new("UIStroke")
		chipStroke.Color = DARK_THEME.Stroke
		chipStroke.Thickness = 1
		chipStroke.Transparency = 0.2
		chipStroke.Parent = chip

		local name = Instance.new("TextLabel")
		name.Name = "Label"
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromOffset(72, 0)
		name.Size = UDim2.new(1, -78, 1, 0)
		name.Font = Enum.Font.Gotham
		name.Text = entry.label
		name.TextSize = 12
		name.TextColor3 = DARK_THEME.Text
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.ZIndex = 3
		name.Parent = row
	end

	return gui
end

createKeybindPanel()

-- ---------------------------------------------------------------------
-- 8. ESTADO PARTILHADO
--
-- Uma unica tabela para todas as abas: assim uma feature que cruza abas
-- (o som, o crosshair, o FOV) le e escreve sempre no mesmo sitio.
-- ---------------------------------------------------------------------
local Settings = {}

-- O BBC Hub nao usa a barra do groupbox (titulo + chevron): cada secao
-- tem o seu proprio cabecalho. Escondemos essa barra e o painel da
-- coluna para as colunas ficarem iguais as do BBC Hub: cada control
-- (toggle, slider) e um cartao com fundo, cantos e contorno proprios.
local function plainColumn(column)
	local box = column.Frame
	box.BackgroundTransparency = 1
	for _, child in ipairs(box:GetChildren()) do
		if child:IsA("UIStroke") then
			child.Transparency = 1
		elseif isGui(child) and (child.LayoutOrder == 1 or child.LayoutOrder == 2) then
			child.Visible = false
			child.Size = UDim2.new(1, 0, 0, 0)
		end
	end
end

-- O que cada aba recebe: a janela onde criar o tab, a tabela de estado
-- e o helper das colunas.
local ctx = {
	Library = AirFlow,
	window = window,
	Settings = Settings,
	plainColumn = plainColumn,
	watermark = watermark,
}

-- ---------------------------------------------------------------------
-- 9. ABAS
--
-- A ordem e a ordem em que aparecem na sidebar. Uma aba que falhe nao
-- leva o menu inteiro abaixo: o resto continua a funcionar.
-- ---------------------------------------------------------------------
local TABS = {
	{ file = "tabs/visuals.lua", name = "VISUALS" },
	{ file = "tabs/players.lua", name = "PLAYER" },
	{ file = "tabs/combat.lua", name = "COMBAT" },
	{ file = "tabs/world.lua", name = "WORLD" },
	{ file = "tabs/misc.lua", name = "MISC" },
	{ file = "tabs/lootfinder.lua", name = "LOOTFINDER" },
	{ file = "tabs/server.lua", name = "SERVER" },
}

-- O build (airflowui/build.py) troca esta linha pela tabela com as abas
-- embutidas: assim o bundle e um unico ficheiro e nao precisa da pasta
-- tabs/ no telemóvel. Fora do bundle a tabela fica vazia e as abas vem
-- do disco (ROOT).
local EMBEDDED = {
	["tabs/visuals.lua"] = [==[-- =====================================================================
-- tabs/visuals.lua - aba VISUALS
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : WORLD
--   coluna direita  : PLAYER + CROSSHAIR
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "VISUALS" (icone "eye")
	-- -----------------------------------------------------------------
	local visualsTab = window:CreateTab({ Name = "VISUALS" }, "eye")

	local leftColumn = visualsTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = visualsTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "WORLD" -------------------------------------------------
	leftColumn:Section("WORLD")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Fullbright",
		Flag = "VisualsFullbright",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Intensity",
				Flag = "VisualsFullbrightIntensity",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 50,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "No Fog",
		Flag = "VisualsNoFog",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Fog End",
				Flag = "VisualsNoFogEnd",
				Min = 0,
				Max = 1000,
				Step = 10,
				Default = 100,
				Suffix = " studs",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Bloom",
		Flag = "VisualsBloom",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Bloom Intensity",
				Flag = "VisualsBloomIntensity",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 20,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Grass",
		Flag = "VisualsGrass",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Grass State",
				Flag = "VisualsGrassState",
				Options = { "Keep", "Low", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Trees",
		Flag = "VisualsTrees",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Tree State",
				Flag = "VisualsTreesState",
				Options = { "Keep", "Low", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Terrain",
		Flag = "VisualsTerrain",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Detail",
				Flag = "VisualsTerrainDetail",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 50,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Water",
		Flag = "VisualsWater",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Water Style",
				Flag = "VisualsWaterStyle",
				Options = { "Keep", "Clear", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Time of Day",
		Flag = "VisualsTimeOfDay",
		Min = 0,
		Max = 24,
		Step = 1,
		Default = 14,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Brightness",
		Flag = "VisualsBrightness",
		Min = 0,
		Max = 5,
		Step = 1,
		Default = 2,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "PLAYER" ------------------------------------------------
	rightColumn:Section("PLAYER")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Chams",
		Flag = "VisualsChams",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Chams Style",
				Flag = "VisualsChamsStyle",
				Options = { "Outline", "Fill", "Both" },
				Default = "Outline",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Slider",
				Name = "Chams Size",
				Flag = "VisualsChamsSize",
				Min = 0,
				Max = 20,
				Step = 1,
				Default = 4,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Force Field",
		Flag = "VisualsForceField",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Hide Others",
				Flag = "VisualsForceFieldHideOthers",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Halo",
		Flag = "VisualsHalo",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Halo Size",
				Flag = "VisualsHaloSize",
				Min = 0,
				Max = 20,
				Step = 1,
				Default = 6,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Trail",
		Flag = "VisualsTrail",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Trail Style",
				Flag = "VisualsTrailStyle",
				Options = { "Line", "Particle", "Both" },
				Default = "Line",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Aura",
		Flag = "VisualsAura",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Aura Size",
				Flag = "VisualsAuraSize",
				Min = 0,
				Max = 20,
				Step = 1,
				Default = 4,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Character Changer",
		Flag = "VisualsCharacterChanger",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Body",
				Flag = "VisualsCharacterBody",
				Options = { "Default", "Blocky", "Pro", "Slim" },
				Default = "Default",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "CROSSHAIR" ---------------------------------------------
	rightColumn:Section("CROSSHAIR")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Crosshair",
		Flag = "VisualsCrosshair",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Style",
				Flag = "VisualsCrosshairStyle",
				Options = { "Cross", "Dot", "Circle", "T" },
				Default = "Cross",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Slider({
		Name = "Size",
		Flag = "VisualsCrosshairSize",
		Min = 0,
		Max = 50,
		Step = 1,
		Default = 10,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Slider({
		Name = "Thickness",
		Flag = "VisualsCrosshairThickness",
		Min = 0,
		Max = 20,
		Step = 1,
		Default = 2,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Dot",
		Flag = "VisualsCrosshairDot",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Dot Size",
				Flag = "VisualsCrosshairDotSize",
				Min = 0,
				Max = 20,
				Step = 1,
				Default = 3,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Hide HUD",
		Flag = "VisualsHideHud",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Hide Chat",
				Flag = "VisualsHideHudChat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Hide Hotbar",
				Flag = "VisualsHideHudHotbar",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	return visualsTab
end
]==],
	["tabs/players.lua"] = [==[-- =====================================================================
-- tabs/players.lua - aba PLAYER
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : PLAYERS ESP
--   coluna direita  : ITEMS ESP + RADAR
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "PLAYER" (icone "user")
	-- -----------------------------------------------------------------
	local playersTab = window:CreateTab({ Name = "PLAYER" }, "user")

	local leftColumn = playersTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = playersTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "PLAYERS ESP" -------------------------------------------
	leftColumn:Section("PLAYERS ESP")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Master",
		Flag = "PlayerEspMaster",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Max Distance",
				Flag = "PlayerEspMaxDistance",
				Min = 0,
				Max = 2000,
				Step = 10,
				Default = 500,
				Suffix = " studs",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Dropdown",
				Name = "Team Filter",
				Flag = "PlayerEspTeamFilter",
				Options = { "All", "Team", "Enemy", "Other" },
				Default = "All",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Boxes",
		Flag = "PlayerEspBoxes",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Box Style",
				Flag = "PlayerEspBoxStyle",
				Options = { "Outline", "Corner", "Full" },
				Default = "Outline",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Name Tags",
		Flag = "PlayerEspNameTags",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Tag Size",
				Flag = "PlayerEspNameTagSize",
				Min = 8,
				Max = 32,
				Step = 1,
				Default = 14,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Distance Tags",
		Flag = "PlayerEspDistanceTags",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Tag Offset",
				Flag = "PlayerEspDistanceTagOffset",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 20,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Health Bars",
		Flag = "PlayerEspHealthBars",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Bar Style",
				Flag = "PlayerEspHealthBarStyle",
				Options = { "Left", "Right", "Bottom" },
				Default = "Left",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Skeleton",
		Flag = "PlayerEspSkeleton",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Head",
				Flag = "PlayerEspSkeletonHead",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Arrows",
		Flag = "PlayerEspArrows",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Arrow Position",
				Flag = "PlayerEspArrowPosition",
				Options = { "Above", "Below", "Side" },
				Default = "Above",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Tracers",
		Flag = "PlayerEspTracers",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Tracer Thickness",
				Flag = "PlayerEspTracerThickness",
				Min = 1,
				Max = 10,
				Step = 1,
				Default = 2,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Highlights",
		Flag = "PlayerEspHighlights",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Highlight Style",
				Flag = "PlayerEspHighlightStyle",
				Options = { "Outline", "Fill", "Both" },
				Default = "Outline",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Reports Tags",
		Flag = "PlayerEspReportsTags",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Report Count",
				Flag = "PlayerEspReportsCount",
				Min = 1,
				Max = 20,
				Step = 1,
				Default = 3,
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "ITEMS ESP" ---------------------------------------------
	rightColumn:Section("ITEMS ESP")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "NPCs ESP",
		Flag = "PlayerEspNpcs",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "NPC Distance",
				Flag = "PlayerEspNpcsDistance",
				Min = 0,
				Max = 500,
				Step = 10,
				Default = 100,
				Suffix = " studs",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Corpses ESP",
		Flag = "PlayerEspCorpses",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Name",
				Flag = "PlayerEspCorpsesName",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Dropped Items ESP",
		Flag = "PlayerEspDroppedItems",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Item Distance",
				Flag = "PlayerEspDroppedItemsDistance",
				Min = 0,
				Max = 500,
				Step = 10,
				Default = 100,
				Suffix = " studs",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Containers ESP",
		Flag = "PlayerEspContainers",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Loot",
				Flag = "PlayerEspContainersLoot",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Quest Items ESP",
		Flag = "PlayerEspQuestItems",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Quest Type",
				Flag = "PlayerEspQuestItemsType",
				Options = { "All", "Active", "Daily", "Event" },
				Default = "All",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "RADAR" -------------------------------------------------
	rightColumn:Section("RADAR")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Radar",
		Flag = "PlayerRadarEnabled",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Radar Size",
				Flag = "PlayerRadarSize",
				Min = 100,
				Max = 600,
				Step = 10,
				Default = 240,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Full Map",
		Flag = "PlayerRadarFullMap",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Grid",
				Flag = "PlayerRadarFullMapGrid",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Sync Map",
		Flag = "PlayerRadarSyncMap",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Sync Delay",
				Flag = "PlayerRadarSyncMapDelay",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 10,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Dropdown({
		Name = "Shape",
		Flag = "PlayerRadarShape",
		Options = { "Circle", "Square" },
		Default = "Circle",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Slider({
		Name = "Zoom",
		Flag = "PlayerRadarZoom",
		Min = 1,
		Max = 10,
		Step = 1,
		Default = 4,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	return playersTab
end
]==],
	["tabs/combat.lua"] = [==[-- =====================================================================
-- tabs/combat.lua - aba COMBAT
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : AIM
--   coluna direita  : GUN + TRIGGERBOT + KILL AURA
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
--
-- O toggle traz um SUB MENU: o icone da esquerda (o "☰") vira um
-- botao que abre uma caixa por baixo do toggle, com as opcoes extras.
-- O painel cresce com a coluna, por isso a rolagem no telemóvel
-- continua a funcionar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "COMBAT" (icone "crosshair")
	-- -----------------------------------------------------------------
	local combatTab = window:CreateTab({ Name = "COMBAT" }, "crosshair")

	local leftColumn = combatTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = combatTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "AIM" ---------------------------------------------------
	leftColumn:Section("AIM")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Silent Aim",
		Flag = "CombatSilentAim",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Hit Chance",
				Flag = "CombatSilentAimHitChance",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 50,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Dropdown",
				Name = "Target Part",
				Flag = "CombatSilentAimTargetPart",
				Options = { "Head", "Torso", "Nearest" },
				Default = "Head",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Aim FOV",
		Flag = "CombatAimFov",
		Min = 0,
		Max = 720,
		Step = 5,
		Default = 120,
		Suffix = " px",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Aimbot",
		Flag = "CombatAimbot",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Smoothness",
				Flag = "CombatAimbotSmoothness",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 30,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Prediction",
				Flag = "CombatAimbotPrediction",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Auto Shoot",
		Flag = "CombatAutoShoot",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Delay",
				Flag = "CombatAutoShootDelay",
				Min = 0,
				Max = 500,
				Step = 10,
				Default = 50,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Sticky Target",
		Flag = "CombatStickyTarget",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Stick Delay",
				Flag = "CombatStickyTargetDelay",
				Min = 0,
				Max = 500,
				Step = 10,
				Default = 100,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Team Check",
		Flag = "CombatTeamCheck",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Team Mode",
				Flag = "CombatTeamCheckMode",
				Options = { "Skip", "Ignore", "Block" },
				Default = "Skip",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "FOV Circle",
		Flag = "CombatFovCircle",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Circle Size",
				Flag = "CombatFovCircleSize",
				Min = 10,
				Max = 720,
				Step = 5,
				Default = 120,
				Suffix = " px",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "GUN" ---------------------------------------------------
	rightColumn:Section("GUN")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "No Recoil",
		Flag = "CombatNoRecoil",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Recoil Power",
				Flag = "CombatNoRecoilPower",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 100,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Fire Rate",
		Flag = "CombatFireRate",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Rate",
				Flag = "CombatFireRateValue",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 50,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Auto Reload",
		Flag = "CombatAutoReload",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Reload Delay",
				Flag = "CombatAutoReloadDelay",
				Min = 0,
				Max = 1000,
				Step = 10,
				Default = 100,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Fake Scope",
		Flag = "CombatFakeScope",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Zoom",
				Flag = "CombatFakeScopeZoom",
				Min = 1,
				Max = 10,
				Step = 1,
				Default = 3,
				Suffix = " x",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Grenade Prediction",
		Flag = "CombatGrenadePrediction",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Prediction Mode",
				Flag = "CombatGrenadePredictionMode",
				Options = { "Line", "Arc", "Both" },
				Default = "Line",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "TRIGGERBOT" -------------------------------------------
	rightColumn:Section("TRIGGERBOT")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Triggerbot",
		Flag = "CombatTriggerbot",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Only ADS",
				Flag = "CombatTriggerbotOnlyAds",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Slider",
				Name = "Trigger Delay",
				Flag = "CombatTriggerbotDelay",
				Min = 0,
				Max = 500,
				Step = 10,
				Default = 50,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Slider({
		Name = "Triggerbot Distance",
		Flag = "CombatTriggerbotDistance",
		Min = 0,
		Max = 1000,
		Step = 10,
		Default = 50,
		Suffix = " px",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- SECCAO "KILL AURA" ---------------------------------------------
	rightColumn:Section("KILL AURA")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Kill Aura",
		Flag = "CombatKillAura",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Attack Type",
				Flag = "CombatKillAuraAttackType",
				Options = { "Power Attack", "Normal", "Heavy", "Light" },
				Default = "Power Attack",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Slider",
				Name = "Kill Aura Range",
				Flag = "CombatKillAuraRange",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 10,
				Suffix = " studs",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Dropdown({
		Name = "Target Team",
		Flag = "CombatKillAuraTargetTeam",
		Options = { "Enemy", "Other", "All" },
		Default = "Enemy",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	return combatTab
end
]==],
	["tabs/world.lua"] = [==[-- =====================================================================
-- tabs/world.lua - aba WORLD
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : ENVIRONMENT + PHYSICS
--   coluna direita  : WORLD + INTERACTION
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "WORLD" (icone "globe")
	-- -----------------------------------------------------------------
	local worldTab = window:CreateTab({ Name = "WORLD" }, "globe")

	local leftColumn = worldTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = worldTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "ENVIRONMENT" -------------------------------------------
	leftColumn:Section("ENVIRONMENT")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Time of Day",
		Flag = "WorldTimeOfDay",
		Min = 0,
		Max = 24,
		Step = 1,
		Default = 14,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Dropdown({
		Name = "Weather",
		Flag = "WorldWeather",
		Options = { "Clear", "Rain", "Storm", "Snow" },
		Default = "Clear",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Brightness",
		Flag = "WorldBrightness",
		Min = 0,
		Max = 5,
		Step = 1,
		Default = 2,
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Fog",
		Flag = "WorldFog",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Fog Density",
				Flag = "WorldFogDensity",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 50,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Clouds",
		Flag = "WorldClouds",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Cloud Style",
				Flag = "WorldCloudsStyle",
				Options = { "Keep", "Light", "Heavy", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "PHYSICS" -----------------------------------------------
	leftColumn:Section("PHYSICS")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Gravity",
		Flag = "WorldGravity",
		Min = 0,
		Max = 500,
		Step = 5,
		Default = 196,
		Suffix = " studs/s",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Jump Power",
		Flag = "WorldJumpPower",
		Min = 0,
		Max = 200,
		Step = 1,
		Default = 50,
		Suffix = " studs",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Walk Speed",
		Flag = "WorldWalkSpeed",
		Min = 0,
		Max = 100,
		Step = 1,
		Default = 16,
		Suffix = " studs/s",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Bunny Hop",
		Flag = "WorldBunnyHop",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Hop Height",
				Flag = "WorldBunnyHopHeight",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 20,
				Suffix = " studs",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "WORLD" -------------------------------------------------
	rightColumn:Section("WORLD")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Doors",
		Flag = "WorldDoors",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Door State",
				Flag = "WorldDoorsState",
				Options = { "Keep", "Open", "Closed", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Windows",
		Flag = "WorldWindows",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Window State",
				Flag = "WorldWindowsState",
				Options = { "Keep", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Props",
		Flag = "WorldProps",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Prop State",
				Flag = "WorldPropsState",
				Options = { "Keep", "Remove" },
				Default = "Keep",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Vehicles",
		Flag = "WorldVehicles",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Name",
				Flag = "WorldVehiclesName",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "INTERACTION" -------------------------------------------
	rightColumn:Section("INTERACTION")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Auto Open",
		Flag = "WorldAutoOpen",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Open Delay",
				Flag = "WorldAutoOpenDelay",
				Min = 0,
				Max = 2000,
				Step = 10,
				Default = 100,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Auto Close",
		Flag = "WorldAutoClose",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Close Delay",
				Flag = "WorldAutoCloseDelay",
				Min = 0,
				Max = 5000,
				Step = 10,
				Default = 1000,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Slider({
		Name = "Interact Distance",
		Flag = "WorldInteractDistance",
		Min = 0,
		Max = 100,
		Step = 1,
		Default = 10,
		Suffix = " studs",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	return worldTab
end
]==],
	["tabs/misc.lua"] = [==[-- =====================================================================
-- tabs/misc.lua - aba MISC
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : MISC (6 toggles) + SOUNDS (input + 2 toggles)
--   coluna direita  : DETECT (4 toggles) + VAULT SORT (3 toggles)
--                      + INVENTORY VIEWER (1 botao)
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "MISC" (icone "grid")
	-- -----------------------------------------------------------------
	local miscTab = window:CreateTab({ Name = "MISC" }, "grid")

	-- DUAS COLUNAS LADO A LADO
	local leftColumn = miscTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = miscTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "MISC" --------------------------------------------------
	leftColumn:Section("MISC")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Fast Trade",
		Flag = "MiscFastTrade",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Trade Delay",
				Flag = "MiscFastTradeDelay",
				Min = 0,
				Max = 1000,
				Step = 10,
				Default = 100,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Panic Mode",
		Flag = "MiscPanicMode",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Panic Action",
				Flag = "MiscPanicModeAction",
				Options = { "Close Menu", "Hide HUD", "Reset" },
				Default = "Close Menu",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Pass Door",
		Flag = "MiscPassDoor",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Auto Open",
				Flag = "MiscPassDoorAutoOpen",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Screen Effects",
		Flag = "MiscScreenEffects",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Effect",
				Flag = "MiscScreenEffectsType",
				Options = { "None", "Blur", "Vignette", "Flash" },
				Default = "None",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Report Notify",
		Flag = "MiscReportNotify",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Sound",
				Flag = "MiscReportNotifySound",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Join Notify",
		Flag = "MiscJoinNotify",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Sound",
				Flag = "MiscJoinNotifySound",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "SOUNDS" ------------------------------------------------
	leftColumn:Section("SOUNDS")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Input({
		Name = "Add Sound ID",
		Placeholder = "Sound ID",
		Flag = "MiscSoundId",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Jump",
		Flag = "MiscJumpSound",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Volume",
				Flag = "MiscJumpSoundVolume",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 50,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Footsteps",
		Flag = "MiscFootstepsSound",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Volume",
				Flag = "MiscFootstepsSoundVolume",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 50,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "DETECT" ------------------------------------------------
	rightColumn:Section("DETECT")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Content Creator",
		Flag = "MiscDetectContentCreator",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Notify Style",
				Flag = "MiscDetectContentCreatorStyle",
				Options = { "Chat", "Window", "Both" },
				Default = "Chat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Tester",
		Flag = "MiscDetectTester",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Notify Style",
				Flag = "MiscDetectTesterStyle",
				Options = { "Chat", "Window", "Both" },
				Default = "Chat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Moderator",
		Flag = "MiscDetectModerator",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Notify Style",
				Flag = "MiscDetectModeratorStyle",
				Options = { "Chat", "Window", "Both" },
				Default = "Chat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Cheater",
		Flag = "MiscDetectCheater",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Notify Style",
				Flag = "MiscDetectCheaterStyle",
				Options = { "Chat", "Window", "Both" },
				Default = "Chat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "VAULT SORT" --------------------------------------------
	rightColumn:Section("VAULT SORT")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Sort By Value",
		Flag = "MiscSortByValue",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Order",
				Flag = "MiscSortByValueOrder",
				Options = { "High to Low", "Low to High" },
				Default = "High to Low",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Sort By Type",
		Flag = "MiscSortByType",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Order",
				Flag = "MiscSortByTypeOrder",
				Options = { "A to Z", "Z to A" },
				Default = "A to Z",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Sort By Name",
		Flag = "MiscSortByName",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Order",
				Flag = "MiscSortByNameOrder",
				Options = { "A to Z", "Z to A" },
				Default = "A to Z",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "INVENTORY VIEWER" -------------------------------------
	rightColumn:Section("INVENTORY VIEWER")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Button({
		Name = "Show Inventory",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	return miscTab
end
]==],
	["tabs/lootfinder.lua"] = [==[-- =====================================================================
-- tabs/lootfinder.lua - aba LOOTFINDER
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : LOOT (toggles + slider de distancia)
--   coluna direita  : FILTERS (dropdowns) + NOTIFY (toggles)
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "LOOTFINDER" (icone "search")
	-- -----------------------------------------------------------------
	local lootTab = window:CreateTab({ Name = "LOOTFINDER" }, "search")

	local leftColumn = lootTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = lootTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "LOOT" ---------------------------------------------------
	leftColumn:Section("LOOT")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Loot ESP",
		Flag = "LootLootEsp",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Box",
				Flag = "LootLootEspBox",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Name",
				Flag = "LootLootEspName",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Distance",
				Flag = "LootLootEspDistance",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Loot Highlight",
		Flag = "LootHighlight",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Style",
				Flag = "LootHighlightStyle",
				Options = { "Outline", "Fill", "Text" },
				Default = "Outline",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Slider({
		Name = "Loot Range",
		Flag = "LootRange",
		Min = 0,
		Max = 500,
		Step = 5,
		Default = 100,
		Suffix = " studs",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Chests",
		Flag = "LootChests",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Show Opened",
				Flag = "LootChestsShowOpened",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Button({
		Name = "Refresh Loot",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "FILTERS" ------------------------------------------------
	rightColumn:Section("FILTERS")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Dropdown({
		Name = "Rarity",
		Flag = "LootFilterRarity",
		Options = { "All", "Common", "Rare", "Epic", "Legendary" },
		Default = "All",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Dropdown({
		Name = "Item Type",
		Flag = "LootFilterType",
		Options = { "All", "Weapons", "Armor", "Items", "Keys" },
		Default = "All",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Input({
		Name = "Item Name",
		Placeholder = "Search item",
		Flag = "LootFilterName",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Hide Empty",
		Flag = "LootHideEmpty",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Delay",
				Flag = "LootHideEmptyDelay",
				Min = 0,
				Max = 2000,
				Step = 10,
				Default = 100,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "NOTIFY" -------------------------------------------------
	rightColumn:Section("NOTIFY")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Rare Notify",
		Flag = "LootRareNotify",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Dropdown",
				Name = "Notify Style",
				Flag = "LootRareNotifyStyle",
				Options = { "Chat", "Window", "Both" },
				Default = "Chat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Loot Sound",
		Flag = "LootSound",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Volume",
				Flag = "LootSoundVolume",
				Min = 0,
				Max = 100,
				Step = 1,
				Default = 50,
				Suffix = " %",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	return lootTab
end
]==],
	["tabs/server.lua"] = [==[-- =====================================================================
-- tabs/server.lua - aba SERVER
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : SERVER (botoes e informacao do servidor)
--   coluna direita  : HOPPER (troca de servidor) + MISC (opcoes)
--
-- Nenhum botao tem logica: cada callback imprime "Botão alterado" e
-- fica o marcador "-- [INSERIR LOGICA AQUI]" para a logica entrar.
-- =====================================================================

return function(ctx)
	local window = ctx.window

	-- -----------------------------------------------------------------
	-- ABA "SERVER" (icone "server")
	-- -----------------------------------------------------------------
	local serverTab = window:CreateTab({ Name = "SERVER" }, "server")

	local leftColumn = serverTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = serverTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "SERVER" -------------------------------------------------
	leftColumn:Section("SERVER")

	-- [INSERIR LOGICA AQUI]
	leftColumn:Button({
		Name = "Copy Server Link",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Button({
		Name = "Rejoin Server",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Auto Rejoin",
		Flag = "ServerAutoRejoin",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Delay",
				Flag = "ServerAutoRejoinDelay",
				Min = 0,
				Max = 10000,
				Step = 100,
				Default = 1000,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	leftColumn:Toggle({
		Name = "Teleport To Spawn",
		Flag = "ServerTeleportSpawn",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Safe Spot",
				Flag = "ServerTeleportSpawnSafe",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "HOPPER" ------------------------------------------------
	rightColumn:Section("HOPPER")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Button({
		Name = "Server Hop",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Button({
		Name = "Random Server",
		Callback = function()
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Input({
		Name = "Join Code",
		Placeholder = "Server code",
		Flag = "ServerJoinCode",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Low Ping Only",
		Flag = "ServerLowPing",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Slider",
				Name = "Max Ping",
				Flag = "ServerLowPingMax",
				Min = 0,
				Max = 500,
				Step = 10,
				Default = 100,
				Suffix = " ms",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- SECCAO "MISC" ---------------------------------------------------
	rightColumn:Section("MISC")

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Server Notifications",
		Flag = "ServerNotifications",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Sound",
				Flag = "ServerNotificationsSound",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	-- [INSERIR LOGICA AQUI]
	rightColumn:Toggle({
		Name = "Hide Server HUD",
		Flag = "ServerHideHud",
		Callback = function(value)
			print("Botão alterado")
			-- [INSERIR LOGICA AQUI]
		end,
		SubElements = {
			{
				Type = "Toggle",
				Name = "Hide Chat",
				Flag = "ServerHideHudChat",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
			{
				Type = "Toggle",
				Name = "Hide Hotbar",
				Flag = "ServerHideHudHotbar",
				Callback = function(value)
					print("Botão alterado")
					-- [INSERIR LOGICA AQUI]
				end,
			},
		},
	})

	return serverTab
end
]==],
}

-- Le um modulo do projecto: primeiro o que esta embutido, depois o que
-- esta no disco.
local function readModule(relPath)
	local embedded = EMBEDDED[relPath]
	if embedded then
		return embedded
	end
	if readfile then
		return readfile(ROOT .. "/" .. relPath)
	end
	return nil
end

local loaded = 0

for _, entry in ipairs(TABS) do
	local path = ROOT .. "/" .. entry.file
	local ok, err = pcall(function()
		assert(loadstring, "sem loadstring")
		local chunk = loadstring(readModule(entry.file))
		assert(chunk, "nao foi possivel ler " .. path)
		local build = chunk()
		assert(type(build) == "function", entry.file .. " tem de devolver uma funcao")
		build(ctx)
	end)
	if ok then
		loaded += 1
	else
		warn("[Airflow] aba " .. entry.name .. " nao carregou: " .. tostring(err))
	end
end

print("[Airflow] pronto: " .. tostring(loaded) .. "/" .. tostring(#TABS) .. " abas")

-- ---------------------------------------------------------------------
-- 10. ROLAGEM DAS ABAS
--
-- O conteudo de cada aba vive num ScrollingFrame: a barra de rolagem
-- fica com 4 px (fina, como no BBC Hub) e o canvas segue o conteudo,
-- para a ultima linha nunca ficar presa.
-- ---------------------------------------------------------------------
for _, tab in ipairs(window.Tabs or {}) do
	local list = tab.List
	if list and list:IsA("ScrollingFrame") then
		list.ScrollBarThickness = 4
		list.ScrollBarImageColor3 = DARK_THEME.Muted
		list.ScrollBarImageTransparency = 0.55
		-- A biblioteca calcula o canvas a medida que o conteudo muda
		-- (quando um sub menu abre). Pedimos um novo calculo para o
		-- canvas ficar certo desde o inicio.
		if type(tab._refreshCanvas) == "function" then
			pcall(tab._refreshCanvas)
		end
	end
end
