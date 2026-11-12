-- =====================================================================
-- teste_misc.lua
--
-- Teste da aba "MISC" do Airflow, com o layout do BBC Hub:
-- DUAS COLUNAS lado a lado, cada uma com as suas secoes.
--
-- A aba em si vive em tabs/misc.lua (o resto do menu usa o mesmo
-- modulo). Este ficheiro so cria a janela e carrega essa aba, para
-- poder testar a MISC sozinha.
--
-- Estrutura pedida -> estrutura do Airflow:
--   CreateGroup { direction = "row" }  ->  tab:Groupbox { Side = "Left" | "Right" }
--                                          (o Airflow ja traz o par de colunas
--                                           em row; empilha se a janela for estreita)
--   CreateSection { name = "..." }     ->  column:Section("...")
--   CreateToggle / CreateInput / CreateButton -> column:Toggle / :Input / :Button
--
-- Executar no Delta. Se a biblioteca ainda nao estiver no ambiente, este
-- ficheiro busca-a no GitHub com game:HttpGet.
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
-- ---------------------------------------------------------------------
local PURPLE_THEME = {
	Accent = Color3.fromRGB(170, 80, 255),
	Background = Color3.fromRGB(10, 8, 15),
}

AirFlow:SetTheme(PURPLE_THEME, true)

-- ---------------------------------------------------------------------
-- 3. MENU
-- ---------------------------------------------------------------------
local window = AirFlow:Window({
	Name = "AirflowUI",
	Title = "Airflow",
	Theme = PURPLE_THEME,
	Size = UDim2.fromOffset(760, 520),
})

-- ---------------------------------------------------------------------
-- 4. CONTEXTO DAS ABAS
--
-- O mesmo que o main.lua passa as abas: janela, estado partilhado e o
-- helper que esconde a barra do groupbox (as colunas do BBC Hub nao a
-- usam, cada secao tem o seu cabecalho).
-- ---------------------------------------------------------------------
local Settings = {}

local function plainColumn(column)
	for _, child in column.Frame:GetChildren() do
		if child:IsA("GuiObject") and (child.LayoutOrder == 1 or child.LayoutOrder == 2) then
			child.Visible = false
			child.Size = UDim2.new(1, 0, 0, 0)
		end
	end
end

local ctx = {
	Library = AirFlow,
	window = window,
	Settings = Settings,
	plainColumn = plainColumn,
}

-- ---------------------------------------------------------------------
-- 5. ABA "MISC"
--
-- Estrutura do BBC Hub -> estrutura do Airflow:
--   CreateGroup { direction = "row" }  ->  tab:Groupbox { Side = "Left" | "Right" }
--                                          (o Airflow ja traz o par de colunas
--                                           em row; empilha se a janela for estreita)
--   CreateSection { name = "..." }     ->  column:Section("...")
--   CreateToggle / CreateInput / CreateButton -> column:Toggle / :Input / :Button
-- ---------------------------------------------------------------------
assert(readfile and loadstring, "[Airflow] sem readfile/loadstring")

local chunk = loadstring(readfile(ROOT .. "/tabs/misc.lua"))
assert(chunk, "[Airflow] nao foi possivel ler tabs/misc.lua")

local build = chunk()
assert(type(build) == "function", "tabs/misc.lua tem de devolver uma funcao")

build(ctx)

-- ---------------------------------------------------------------------
-- 6. LIXO / DEBUG
-- ---------------------------------------------------------------------
print("[Airflow] aba MISC pronta | som = " .. tostring(Settings.misc_sound_id))
