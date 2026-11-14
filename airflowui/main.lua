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
		chip.TextColor3 = DARK_THEME.Text
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
local EMBEDDED = {}

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
