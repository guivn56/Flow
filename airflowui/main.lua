-- =====================================================================
-- main.lua - AirflowUI
--
-- Menu do Airflow (biblioteca AirFlowLibrary.luau) com o layout do
-- BBC Hub: cada aba tem DUAS COLUNAS lado a lado, cada secao tem o
-- seu cabecalho e a logica pesada fica em marcadores.
--
-- Ficheiros:
--   main.lua          este: biblioteca, tema, janela, tabela Settings
--   tabs/misc.lua     aba MISC
--   tabs/combat.lua   aba COMBAT
--   tabs/players.lua  aba PLAYERS
--   tabs/visuals.lua  aba VISUALS
--   tabs/utility.lua  aba UTILITY
--   tabs/settings.lua aba SETTINGS
--
-- Correr no Delta: cola este ficheiro. A biblioteca e buscada na internet
-- (game:HttpGet), por isso funciona no telemóvel sem ficheiro local. As
-- abas vêm embutidas no bundle (ou de /sdcard/Delta/Workspace/AirflowUI/tabs
-- quando se corre o projecto em claro).
-- =====================================================================

local ROOT = "/sdcard/Delta/Workspace/AirflowUI"
local LIBRARY_PATH = "/sdcard/Download/AirFlowLibrary.luau"

-- ---------------------------------------------------------------------
-- 1. BIBLIOTECA
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
-- 2. TEMA ROXO
--
-- O tema completo, nao so a cor de destaque: os paineis, os cartoes e
-- os tracos tambem sao roxos, para o menu ficar com o mesmo ar do
-- BBC Hub.
-- ---------------------------------------------------------------------
local PURPLE_THEME = {
	Accent = Color3.fromRGB(170, 80, 255),
	AccentDark = Color3.fromRGB(16, 7, 26),
	Background = Color3.fromRGB(10, 8, 15),
	Surface = Color3.fromRGB(16, 14, 22),
	Surface2 = Color3.fromRGB(20, 18, 26),
	Surface3 = Color3.fromRGB(38, 30, 56),
	Card = Color3.fromRGB(25, 25, 30),
	Stroke = Color3.fromRGB(44, 36, 62),
	StrokeHover = Color3.fromRGB(96, 72, 150),
	Text = Color3.fromRGB(236, 232, 245),
	Muted = Color3.fromRGB(138, 130, 160),
}

AirFlow:SetTheme(PURPLE_THEME, true)

-- ---------------------------------------------------------------------
-- 3. JANELA
-- ---------------------------------------------------------------------
local window = AirFlow:Window({
	Name = "AirflowUI",
	Title = "Airflow",
	Theme = PURPLE_THEME,
	Size = UDim2.fromOffset(760, 520),
})

-- ---------------------------------------------------------------------
-- 4. WATERMARK E TIMER
--
-- Uma caixa no topo central da tela: o nome do hub e o tempo que o
-- script esta a correr (os segundos desde que a biblioteca carregou).
-- Fica acima de tudo e nunca rouba o input do menu.
-- ---------------------------------------------------------------------
local watermark = window:CreateWatermark({
	Name = "Airflow",
})

-- ---------------------------------------------------------------------
-- 5. ESTADO PARTILHADO
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
		elseif child:IsA("GuiObject") and (child.LayoutOrder == 1 or child.LayoutOrder == 2) then
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
-- 6. ABAS
--
-- A ordem e a ordem em que aparecem na sidebar. Uma aba que falhe nao
-- leva o menu inteiro abaixo: o resto continua a funcionar.
-- ---------------------------------------------------------------------
local TABS = {
	{ file = "tabs/combat.lua", name = "COMBAT" },
	{ file = "tabs/players.lua", name = "PLAYERS" },
	{ file = "tabs/visuals.lua", name = "VISUALS" },
	{ file = "tabs/misc.lua", name = "MISC" },
	{ file = "tabs/utility.lua", name = "UTILITY" },
	{ file = "tabs/settings.lua", name = "SETTINGS" },
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
