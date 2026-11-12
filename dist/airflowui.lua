--[[ gerado por airflowui/build.py -- nao editar a mao ]]
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
-- Correr no Delta: cola este ficheiro. Ele carrega a biblioteca de
-- /sdcard/Download/AirFlowLibrary.luau e as abas de
-- /sdcard/Delta/Workspace/AirflowUI/tabs.
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
	if readfile and loadstring then
		local ok, lib = pcall(function()
			return loadstring(readfile(LIBRARY_PATH))()
		end)
		if ok and type(lib) == "table" then
			return lib
		end
	end
	return nil
end

local AirFlow = loadLibrary()
assert(AirFlow, "[Airflow] nao foi possivel carregar " .. LIBRARY_PATH)

-- ---------------------------------------------------------------------
-- 2. TEMA ROXO
-- ---------------------------------------------------------------------
local PURPLE_THEME = {
	Accent = Color3.fromRGB(170, 80, 255),
	Background = Color3.fromRGB(10, 8, 15),
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
-- 4. ESTADO PARTILHADO
--
-- Uma unica tabela para todas as abas: assim uma feature que cruza abas
-- (o som, o crosshair, o FOV) le e escreve sempre no mesmo sitio.
-- ---------------------------------------------------------------------
local Settings = {}

-- O BBC Hub nao usa a barra do groupbox (titulo + chevron): cada secao
-- tem o seu proprio cabecalho. Escondemos essa barra para as colunas
-- ficarem iguais as do BBC Hub.
local function plainColumn(column)
	for _, child in column.Frame:GetChildren() do
		if child:IsA("GuiObject") and (child.LayoutOrder == 1 or child.LayoutOrder == 2) then
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
}

-- ---------------------------------------------------------------------
-- 5. ABAS
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
local EMBEDDED = {
	["tabs/combat.lua"] = [==[-- =====================================================================
-- tabs/combat.lua - aba COMBAT
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : AIM
--   coluna direita  : GUN + TRIGGERBOT + KILL AURA
--
-- A logica pesada fica em marcadores: cada callback escreve o valor na
-- tabela Settings e onde estao os "-- [LOGICA ... AQUI]".
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

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

	-- [LOGICA DO SILENT AIM AQUI]
	leftColumn:Toggle({
		Name = "Silent Aim",
		Flag = "CombatSilentAim",
		Callback = function(value)
			Settings.combat_silent_aim = value
		end,
	})

	-- [LOGICA DO FOV DA MIRA AQUI]
	leftColumn:Slider({
		Name = "Aim FOV",
		Flag = "CombatAimFov",
		Min = 0,
		Max = 720,
		Step = 5,
		Default = 120,
		Suffix = " px",
		Callback = function(value)
			Settings.combat_aim_fov = value
		end,
	})

	-- [LOGICA DO SMOOTHING AQUI]
	leftColumn:Slider({
		Name = "Smoothing",
		Flag = "CombatSmoothing",
		Min = 0,
		Max = 100,
		Step = 1,
		Default = 30,
		Suffix = " %",
		Callback = function(value)
			Settings.combat_smoothing = value
		end,
	})

	-- [LOGICA DA PREDICTION AQUI]
	leftColumn:Toggle({
		Name = "Prediction",
		Flag = "CombatPrediction",
		Callback = function(value)
			Settings.combat_prediction = value
		end,
	})

	-- [LOGICA DO AUTO SHOOT AQUI]
	leftColumn:Toggle({
		Name = "Auto Shoot",
		Flag = "CombatAutoShoot",
		Callback = function(value)
			Settings.combat_auto_shoot = value
		end,
	})

	-- [LOGICA DO STICKY TARGET AQUI]
	leftColumn:Toggle({
		Name = "Sticky Target",
		Flag = "CombatStickyTarget",
		Callback = function(value)
			Settings.combat_sticky_target = value
		end,
	})

	-- [LOGICA DO TEAM CHECK AQUI]
	leftColumn:Toggle({
		Name = "Team Check",
		Flag = "CombatTeamCheck",
		Callback = function(value)
			Settings.combat_team_check = value
		end,
	})

	-- [LOGICA DO FOV CIRCLE AQUI]
	leftColumn:Toggle({
		Name = "FOV Circle",
		Flag = "CombatFovCircle",
		Callback = function(value)
			Settings.combat_fov_circle = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "GUN" ---------------------------------------------------
	rightColumn:Section("GUN")

	-- [LOGICA DO NO RECOIL AQUI]
	rightColumn:Toggle({
		Name = "No Recoil",
		Flag = "CombatNoRecoil",
		Callback = function(value)
			Settings.combat_no_recoil = value
		end,
	})

	-- [LOGICA DA FIRE RATE AQUI]
	rightColumn:Toggle({
		Name = "Fire Rate",
		Flag = "CombatFireRate",
		Callback = function(value)
			Settings.combat_fire_rate = value
		end,
	})

	-- [LOGICA DO AUTO RELOAD AQUI]
	rightColumn:Toggle({
		Name = "Auto Reload",
		Flag = "CombatAutoReload",
		Callback = function(value)
			Settings.combat_auto_reload = value
		end,
	})

	-- [LOGICA DO FAKE SCOPE AQUI]
	rightColumn:Toggle({
		Name = "Fake Scope",
		Flag = "CombatFakeScope",
		Callback = function(value)
			Settings.combat_fake_scope = value
		end,
	})

	-- [LOGICA DA GRENADE PREDICTION AQUI]
	rightColumn:Toggle({
		Name = "Grenade Prediction",
		Flag = "CombatGrenadePrediction",
		Callback = function(value)
			Settings.combat_grenade_prediction = value
		end,
	})

	-- SECCAO "TRIGGERBOT" -------------------------------------------
	rightColumn:Section("TRIGGERBOT")

	-- [LOGICA DO TRIGGERBOT AQUI]
	rightColumn:Toggle({
		Name = "Triggerbot",
		Flag = "CombatTriggerbot",
		Callback = function(value)
			Settings.combat_triggerbot = value
		end,
	})

	-- [LOGICA DA DISTANCIA DO TRIGGERBOT AQUI]
	rightColumn:Slider({
		Name = "Triggerbot Distance",
		Flag = "CombatTriggerbotDistance",
		Min = 0,
		Max = 1000,
		Step = 10,
		Default = 50,
		Suffix = " px",
		Callback = function(value)
			Settings.combat_triggerbot_distance = value
		end,
	})

	-- [LOGICA DO TRIGGERBOT SO EM ADS AQUI]
	rightColumn:Toggle({
		Name = "Only ADS",
		Flag = "CombatTriggerbotOnlyAds",
		Callback = function(value)
			Settings.combat_triggerbot_only_ads = value
		end,
	})

	-- SECCAO "KILL AURA" ---------------------------------------------
	rightColumn:Section("KILL AURA")

	-- [LOGICA DO KILL AURA AQUI]
	rightColumn:Toggle({
		Name = "Kill Aura",
		Flag = "CombatKillAura",
		Callback = function(value)
			Settings.combat_kill_aura = value
		end,
	})

	-- [LOGICA DO ALCANCE DO KILL AURA AQUI]
	rightColumn:Slider({
		Name = "Kill Aura Range",
		Flag = "CombatKillAuraRange",
		Min = 0,
		Max = 100,
		Step = 1,
		Default = 10,
		Suffix = " studs",
		Callback = function(value)
			Settings.combat_kill_aura_range = value
		end,
	})

	-- [LOGICA DO TIPO DE ATAQUE AQUI]
	rightColumn:Dropdown({
		Name = "Attack Type",
		Flag = "CombatKillAuraAttackType",
		Options = { "Power Attack", "Normal", "Heavy", "Light" },
		Default = "Power Attack",
		Callback = function(value)
			Settings.combat_kill_aura_attack = value
		end,
	})

	return combatTab
end
]==],
	["tabs/players.lua"] = [==[-- =====================================================================
-- tabs/players.lua - aba PLAYERS
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : PLAYERS ESP
--   coluna direita  : ITEMS ESP + RADAR
--
-- A logica pesada fica em marcadores.
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

	-- -----------------------------------------------------------------
	-- ABA "PLAYERS" (icone "users")
	-- -----------------------------------------------------------------
	local playersTab = window:CreateTab({ Name = "PLAYERS" }, "users")

	local leftColumn = playersTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = playersTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "PLAYERS ESP" -------------------------------------------
	leftColumn:Section("PLAYERS ESP")

	-- [LOGICA DO ESP DE JOGADORES AQUI]
	leftColumn:Toggle({
		Name = "Master",
		Flag = "PlayersEspMaster",
		Callback = function(value)
			Settings.players_esp_master = value
		end,
	})

	-- [LOGICA DAS CAIXAS AQUI]
	leftColumn:Toggle({
		Name = "Boxes",
		Flag = "PlayersEspBoxes",
		Callback = function(value)
			Settings.players_esp_boxes = value
		end,
	})

	-- [LOGICA DAS NAME TAGS AQUI]
	leftColumn:Toggle({
		Name = "Name Tags",
		Flag = "PlayersEspNameTags",
		Callback = function(value)
			Settings.players_esp_name_tags = value
		end,
	})

	-- [LOGICA DAS DISTANCE TAGS AQUI]
	leftColumn:Toggle({
		Name = "Distance Tags",
		Flag = "PlayersEspDistanceTags",
		Callback = function(value)
			Settings.players_esp_distance_tags = value
		end,
	})

	-- [LOGICA DAS HEALTH BARS AQUI]
	leftColumn:Toggle({
		Name = "Health Bars",
		Flag = "PlayersEspHealthBars",
		Callback = function(value)
			Settings.players_esp_health_bars = value
		end,
	})

	-- [LOGICA DO SKELETON AQUI]
	leftColumn:Toggle({
		Name = "Skeleton",
		Flag = "PlayersEspSkeleton",
		Callback = function(value)
			Settings.players_esp_skeleton = value
		end,
	})

	-- [LOGICA DAS SETAS AQUI]
	leftColumn:Toggle({
		Name = "Arrows",
		Flag = "PlayersEspArrows",
		Callback = function(value)
			Settings.players_esp_arrows = value
		end,
	})

	-- [LOGICA DOS TRACERS AQUI]
	leftColumn:Toggle({
		Name = "Tracers",
		Flag = "PlayersEspTracers",
		Callback = function(value)
			Settings.players_esp_tracers = value
		end,
	})

	-- [LOGICA DOS HIGHLIGHTS AQUI]
	leftColumn:Toggle({
		Name = "Highlights",
		Flag = "PlayersEspHighlights",
		Callback = function(value)
			Settings.players_esp_highlights = value
		end,
	})

	-- [LOGICA DAS REPORTS TAGS AQUI]
	leftColumn:Toggle({
		Name = "Reports Tags",
		Flag = "PlayersEspReportsTags",
		Callback = function(value)
			Settings.players_esp_reports_tags = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "ITEMS ESP" ---------------------------------------------
	rightColumn:Section("ITEMS ESP")

	-- [LOGICA DO ESP DE NPCS AQUI]
	rightColumn:Toggle({
		Name = "NPCs ESP",
		Flag = "PlayersEspNpcs",
		Callback = function(value)
			Settings.players_esp_npcs = value
		end,
	})

	-- [LOGICA DO ESP DE CORPOS AQUI]
	rightColumn:Toggle({
		Name = "Corpses ESP",
		Flag = "PlayersEspCorpses",
		Callback = function(value)
			Settings.players_esp_corpses = value
		end,
	})

	-- [LOGICA DO ESP DE ITEMS LARADOS AQUI]
	rightColumn:Toggle({
		Name = "Dropped Items ESP",
		Flag = "PlayersEspDroppedItems",
		Callback = function(value)
			Settings.players_esp_dropped_items = value
		end,
	})

	-- [LOGICA DO ESP DE CONTAINERS (VAULTS) AQUI]
	rightColumn:Toggle({
		Name = "Containers ESP",
		Flag = "PlayersEspContainers",
		Callback = function(value)
			Settings.players_esp_containers = value
		end,
	})

	-- [LOGICA DO ESP DE QUESTS AQUI]
	rightColumn:Toggle({
		Name = "Quest Items ESP",
		Flag = "PlayersEspQuestItems",
		Callback = function(value)
			Settings.players_esp_quest_items = value
		end,
	})

	-- SECCAO "RADAR" -------------------------------------------------
	rightColumn:Section("RADAR")

	-- [LOGICA DO RADAR AQUI]
	rightColumn:Toggle({
		Name = "Radar",
		Flag = "PlayersRadarEnabled",
		Callback = function(value)
			Settings.players_radar_enabled = value
		end,
	})

	-- [LOGICA DO RADAR DE MAPA COMPLETO AQUI]
	rightColumn:Toggle({
		Name = "Full Map",
		Flag = "PlayersRadarFullMap",
		Callback = function(value)
			Settings.players_radar_full_map = value
		end,
	})

	-- [LOGICA DO RADAR SINCRONIZADO AQUI]
	rightColumn:Toggle({
		Name = "Sync Map",
		Flag = "PlayersRadarSyncMap",
		Callback = function(value)
			Settings.players_radar_sync_map = value
		end,
	})

	-- [LOGICA DA FORMA DO RADAR AQUI]
	rightColumn:Dropdown({
		Name = "Shape",
		Flag = "PlayersRadarShape",
		Options = { "Circle", "Square" },
		Default = "Circle",
		Callback = function(value)
			Settings.players_radar_shape = value
		end,
	})

	-- [LOGICA DO ZOOM DO RADAR AQUI]
	rightColumn:Slider({
		Name = "Zoom",
		Flag = "PlayersRadarZoom",
		Min = 1,
		Max = 10,
		Step = 1,
		Default = 4,
		Callback = function(value)
			Settings.players_radar_zoom = value
		end,
	})

	return playersTab
end
]==],
	["tabs/visuals.lua"] = [==[-- =====================================================================
-- tabs/visuals.lua - aba VISUALS
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : WORLD
--   coluna direita  : PLAYER + CROSSHAIR
--
-- A logica pesada fica em marcadores.
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

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

	-- [LOGICA DO FULLBRIGHT AQUI]
	leftColumn:Toggle({
		Name = "Fullbright",
		Flag = "VisualsFullbright",
		Callback = function(value)
			Settings.visuals_fullbright = value
		end,
	})

	-- [LOGICA DO NO FOG AQUI]
	leftColumn:Toggle({
		Name = "No Fog",
		Flag = "VisualsNoFog",
		Callback = function(value)
			Settings.visuals_no_fog = value
		end,
	})

	-- [LOGICA DO BLOOM AQUI]
	leftColumn:Toggle({
		Name = "Bloom",
		Flag = "VisualsBloom",
		Callback = function(value)
			Settings.visuals_bloom = value
		end,
	})

	-- [LOGICA DA GRAMA AQUI]
	leftColumn:Toggle({
		Name = "Grass",
		Flag = "VisualsGrass",
		Callback = function(value)
			Settings.visuals_grass = value
		end,
	})

	-- [LOGICA DAS ARVORES AQUI]
	leftColumn:Toggle({
		Name = "Trees",
		Flag = "VisualsTrees",
		Callback = function(value)
			Settings.visuals_trees = value
		end,
	})

	-- [LOGICA DO TERRENO AQUI]
	leftColumn:Toggle({
		Name = "Terrain",
		Flag = "VisualsTerrain",
		Callback = function(value)
			Settings.visuals_terrain = value
		end,
	})

	-- [LOGICA DA AGUA AQUI]
	leftColumn:Toggle({
		Name = "Water",
		Flag = "VisualsWater",
		Callback = function(value)
			Settings.visuals_water = value
		end,
	})

	-- [LOGICA DA HORA DO DIA AQUI]
	leftColumn:Slider({
		Name = "Time of Day",
		Flag = "VisualsTimeOfDay",
		Min = 0,
		Max = 24,
		Step = 1,
		Default = 14,
		Callback = function(value)
			Settings.visuals_time_of_day = value
		end,
	})

	-- [LOGICA DO BRILHO AQUI]
	leftColumn:Slider({
		Name = "Brightness",
		Flag = "VisualsBrightness",
		Min = 0,
		Max = 5,
		Step = 1,
		Default = 2,
		Callback = function(value)
			Settings.visuals_brightness = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "PLAYER" ------------------------------------------------
	rightColumn:Section("PLAYER")

	-- [LOGICA DOS CHAMS AQUI]
	rightColumn:Toggle({
		Name = "Chams",
		Flag = "VisualsChams",
		Callback = function(value)
			Settings.visuals_chams = value
		end,
	})

	-- [LOGICA DO FORCE FIELD AQUI]
	rightColumn:Toggle({
		Name = "Force Field",
		Flag = "VisualsForceField",
		Callback = function(value)
			Settings.visuals_force_field = value
		end,
	})

	-- [LOGICA DO HALO AQUI]
	rightColumn:Toggle({
		Name = "Halo",
		Flag = "VisualsHalo",
		Callback = function(value)
			Settings.visuals_halo = value
		end,
	})

	-- [LOGICA DO TRAIL AQUI]
	rightColumn:Toggle({
		Name = "Trail",
		Flag = "VisualsTrail",
		Callback = function(value)
			Settings.visuals_trail = value
		end,
	})

	-- [LOGICA DO AURA AQUI]
	rightColumn:Toggle({
		Name = "Aura",
		Flag = "VisualsAura",
		Callback = function(value)
			Settings.visuals_aura = value
		end,
	})

	-- [LOGICA DO CHARACTER CHANGER AQUI]
	rightColumn:Toggle({
		Name = "Character Changer",
		Flag = "VisualsCharacterChanger",
		Callback = function(value)
			Settings.visuals_character_changer = value
		end,
	})

	-- SECCAO "CROSSHAIR" ---------------------------------------------
	rightColumn:Section("CROSSHAIR")

	-- [LOGICA DO CROSSHAIR AQUI]
	rightColumn:Toggle({
		Name = "Crosshair",
		Flag = "VisualsCrosshair",
		Callback = function(value)
			Settings.visuals_crosshair = value
		end,
	})

	-- [LOGICA DO TAMANHO DO CROSSHAIR AQUI]
	rightColumn:Slider({
		Name = "Size",
		Flag = "VisualsCrosshairSize",
		Min = 0,
		Max = 50,
		Step = 1,
		Default = 10,
		Callback = function(value)
			Settings.visuals_crosshair_size = value
		end,
	})

	-- [LOGICA DA ESPESSURA DO CROSSHAIR AQUI]
	rightColumn:Slider({
		Name = "Thickness",
		Flag = "VisualsCrosshairThickness",
		Min = 0,
		Max = 20,
		Step = 1,
		Default = 2,
		Callback = function(value)
			Settings.visuals_crosshair_thickness = value
		end,
	})

	-- [LOGICA DO PONTO DO CROSSHAIR AQUI]
	rightColumn:Toggle({
		Name = "Dot",
		Flag = "VisualsCrosshairDot",
		Callback = function(value)
			Settings.visuals_crosshair_dot = value
		end,
	})

	-- [LOGICA DE ESCONDER O HUD AQUI]
	rightColumn:Toggle({
		Name = "Hide HUD",
		Flag = "VisualsHideHud",
		Callback = function(value)
			Settings.visuals_hide_hud = value
		end,
	})

	return visualsTab
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
-- O modulo devolve uma funcao que recebe o contexto (ctx) e constroi a
-- aba. A logica pesada fica em marcadores.
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

	-- -----------------------------------------------------------------
	-- ABA "MISC" (icone "settings")
	-- -----------------------------------------------------------------
	local miscTab = window:CreateTab({ Name = "MISC" }, "settings")

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

	-- [LOGICA FAST TRADE AQUI]
	leftColumn:Toggle({
		Name = "Fast Trade",
		Flag = "MiscFastTrade",
		Callback = function(value)
			Settings.misc_fast_trade = value
		end,
	})

	-- [LOGICA PANIC MODE AQUI]
	leftColumn:Toggle({
		Name = "Panic Mode",
		Flag = "MiscPanicMode",
		Callback = function(value)
			Settings.misc_panic_mode = value
		end,
	})

	-- [LOGICA PASS DOOR AQUI]
	leftColumn:Toggle({
		Name = "Pass Door",
		Flag = "MiscPassDoor",
		Callback = function(value)
			Settings.misc_pass_door = value
		end,
	})

	-- [LOGICA SCREEN EFFECTS AQUI]
	leftColumn:Toggle({
		Name = "Screen Effects",
		Flag = "MiscScreenEffects",
		Callback = function(value)
			Settings.misc_screen_effects = value
		end,
	})

	-- [LOGICA REPORT NOTIFY AQUI]
	leftColumn:Toggle({
		Name = "Report Notify",
		Flag = "MiscReportNotify",
		Callback = function(value)
			Settings.misc_report_notify = value
		end,
	})

	-- [LOGICA JOIN NOTIFY AQUI]
	leftColumn:Toggle({
		Name = "Join Notify",
		Flag = "MiscJoinNotify",
		Callback = function(value)
			Settings.misc_join_notify = value
		end,
	})

	-- SECCAO "SOUNDS" ------------------------------------------------
	leftColumn:Section("SOUNDS")

	-- [LOGICA DO SOUND ID AQUI]
	local soundId = leftColumn:Input({
		Name = "Add Sound ID",
		Placeholder = "Sound ID",
		Flag = "MiscSoundId",
		Callback = function(value)
			Settings.misc_sound_id = value
		end,
	})

	-- [LOGICA DO SOM DE PULO AQUI]
	leftColumn:Toggle({
		Name = "Jump",
		Flag = "MiscJumpSound",
		Callback = function(value)
			Settings.misc_jump_sound = value
		end,
	})

	-- [LOGICA DOS PASSOS AQUI]
	leftColumn:Toggle({
		Name = "Footsteps",
		Flag = "MiscFootstepsSound",
		Callback = function(value)
			Settings.misc_footsteps_sound = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "DETECT" ------------------------------------------------
	rightColumn:Section("DETECT")

	-- [LOGICA DE DETECTAR CONTENT CREATOR AQUI]
	rightColumn:Toggle({
		Name = "Content Creator",
		Flag = "MiscDetectContentCreator",
		Callback = function(value)
			Settings.misc_detect_content_creator = value
		end,
	})

	-- [LOGICA DE DETECTAR TESTER AQUI]
	rightColumn:Toggle({
		Name = "Tester",
		Flag = "MiscDetectTester",
		Callback = function(value)
			Settings.misc_detect_tester = value
		end,
	})

	-- [LOGICA DE DETECTAR MODERADOR AQUI]
	rightColumn:Toggle({
		Name = "Moderator",
		Flag = "MiscDetectModerator",
		Callback = function(value)
			Settings.misc_detect_moderator = value
		end,
	})

	-- [LOGICA DE DETECTAR CHEATER AQUI]
	rightColumn:Toggle({
		Name = "Cheater",
		Flag = "MiscDetectCheater",
		Callback = function(value)
			Settings.misc_detect_cheater = value
		end,
	})

	-- SECCAO "VAULT SORT" --------------------------------------------
	rightColumn:Section("VAULT SORT")

	-- [LOGICA DE ORDENAR POR VALOR AQUI]
	rightColumn:Toggle({
		Name = "Sort By Value",
		Flag = "MiscSortByValue",
		Callback = function(value)
			Settings.misc_sort_by_value = value
		end,
	})

	-- [LOGICA DE ORDENAR POR TIPO AQUI]
	rightColumn:Toggle({
		Name = "Sort By Type",
		Flag = "MiscSortByType",
		Callback = function(value)
			Settings.misc_sort_by_type = value
		end,
	})

	-- [LOGICA DE ORDENAR POR NOME AQUI]
	rightColumn:Toggle({
		Name = "Sort By Name",
		Flag = "MiscSortByName",
		Callback = function(value)
			Settings.misc_sort_by_name = value
		end,
	})

	-- SECCAO "INVENTORY VIEWER" -------------------------------------
	rightColumn:Section("INVENTORY VIEWER")

	-- [LOGICA DO INVENTORY VIEWER AQUI]
	rightColumn:Button({
		Name = "Show Inventory",
		Callback = function()
			print("[Airflow] Show Inventory")
		end,
	})

	return miscTab
end
]==],
	["tabs/utility.lua"] = [==[-- =====================================================================
-- tabs/utility.lua - aba UTILITY
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : LOOT
--   coluna direita  : MOVEMENT + FREECAM + BOSS CHECKER
--
-- A logica pesada fica em marcadores.
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

	-- -----------------------------------------------------------------
	-- ABA "UTILITY" (icone "wrench")
	-- -----------------------------------------------------------------
	local utilityTab = window:CreateTab({ Name = "UTILITY" }, "wrench")

	local leftColumn = utilityTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = utilityTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "LOOT" --------------------------------------------------
	leftColumn:Section("LOOT")

	-- [LOGICA DO AUTO LOOT AQUI]
	leftColumn:Toggle({
		Name = "Auto Loot",
		Flag = "UtilityAutoLoot",
		Callback = function(value)
			Settings.utility_auto_loot = value
		end,
	})

	-- [LOGICA DO INSTA LOOT AQUI]
	leftColumn:Toggle({
		Name = "Insta Loot",
		Flag = "UtilityInstaLoot",
		Callback = function(value)
			Settings.utility_insta_loot = value
		end,
	})

	-- [LOGICA DO LOOT FINDER AQUI]
	leftColumn:Toggle({
		Name = "Loot Finder",
		Flag = "UtilityLootFinder",
		Callback = function(value)
			Settings.utility_loot_finder = value
		end,
	})

	-- [LOGICA DO MAG FINDER AQUI]
	leftColumn:Toggle({
		Name = "Mag Finder",
		Flag = "UtilityMagFinder",
		Callback = function(value)
			Settings.utility_mag_finder = value
		end,
	})

	-- [LOGICA DE SUBSTITUIR POR MAIS BARATO AQUI]
	leftColumn:Toggle({
		Name = "Replace Cheaper",
		Flag = "UtilityReplaceCheaper",
		Callback = function(value)
			Settings.utility_replace_cheaper = value
		end,
	})

	-- [LOGICA DE PEGAR ITEMS LARADOS AQUI]
	leftColumn:Toggle({
		Name = "Pick Up Dropped",
		Flag = "UtilityPickUpDropped",
		Callback = function(value)
			Settings.utility_pick_up_dropped = value
		end,
	})

	-- SECCAO "LOOT RANGE" --------------------------------------------
	leftColumn:Section("LOOT RANGE")

	-- [LOGICA DO RAIO DO AUTO LOOT AQUI]
	leftColumn:Slider({
		Name = "Loot Radius",
		Flag = "UtilityLootRadius",
		Min = 0,
		Max = 100,
		Step = 1,
		Default = 10,
		Suffix = " studs",
		Callback = function(value)
			Settings.utility_loot_radius = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "MOVEMENT" ----------------------------------------------
	rightColumn:Section("MOVEMENT")

	-- [LOGICA DO ALWAYS SPRINT AQUI]
	rightColumn:Toggle({
		Name = "Always Sprint",
		Flag = "UtilityAlwaysSprint",
		Callback = function(value)
			Settings.utility_always_sprint = value
		end,
	})

	-- [LOGICA DO SPEEDHACK AQUI]
	rightColumn:Toggle({
		Name = "Speedhack",
		Flag = "UtilitySpeedhack",
		Callback = function(value)
			Settings.utility_speedhack = value
		end,
	})

	-- [LOGICA DO MULTIPLICADOR DO SPEEDHACK AQUI]
	rightColumn:Slider({
		Name = "Speed Multiplier",
		Flag = "UtilitySpeedMultiplier",
		Min = 1,
		Max = 5,
		Step = 0.1,
		Default = 1.3,
		Callback = function(value)
			Settings.utility_speed_multiplier = value
		end,
	})

	-- [LOGICA DO NO FALL AQUI]
	rightColumn:Toggle({
		Name = "No Fall",
		Flag = "UtilityNoFall",
		Callback = function(value)
			Settings.utility_no_fall = value
		end,
	})

	-- [LOGICA DO JESUS AQUI]
	rightColumn:Toggle({
		Name = "Jesus",
		Flag = "UtilityJesus",
		Callback = function(value)
			Settings.utility_jesus = value
		end,
	})

	-- SECCAO "FREECAM" -----------------------------------------------
	rightColumn:Section("FREECAM")

	-- [LOGICA DA FREECAM AQUI]
	rightColumn:Toggle({
		Name = "Freecam",
		Flag = "UtilityFreecam",
		Callback = function(value)
			Settings.utility_freecam = value
		end,
	})

	-- [LOGICA DA VELOCIDADE DA FREECAM AQUI]
	rightColumn:Slider({
		Name = "Freecam Speed",
		Flag = "UtilityFreecamSpeed",
		Min = 1,
		Max = 500,
		Step = 1,
		Default = 50,
		Callback = function(value)
			Settings.utility_freecam_speed = value
		end,
	})

	-- [LOGICA DO MODO CINEMATICO AQUI]
	rightColumn:Toggle({
		Name = "Cinematic",
		Flag = "UtilityFreecamCinematic",
		Callback = function(value)
			Settings.utility_freecam_cinematic = value
		end,
	})

	-- SECCAO "BOSS CHECKER" ------------------------------------------
	rightColumn:Section("BOSS CHECKER")

	-- [LOGICA DO BOSS CHECKER AQUI]
	rightColumn:Toggle({
		Name = "Boss Checker",
		Flag = "UtilityBossChecker",
		Callback = function(value)
			Settings.utility_boss_checker = value
		end,
	})

	-- [LOGICA DO INTERVALO DO BOSS CHECKER AQUI]
	rightColumn:Slider({
		Name = "Check Interval",
		Flag = "UtilityBossCheckerInterval",
		Min = 1,
		Max = 60,
		Step = 1,
		Default = 5,
		Suffix = " s",
		Callback = function(value)
			Settings.utility_boss_checker_interval = value
		end,
	})

	return utilityTab
end
]==],
	["tabs/settings.lua"] = [==[-- =====================================================================
-- tabs/settings.lua - aba SETTINGS
--
-- Layout do BBC Hub: DUAS COLUNAS lado a lado.
--   coluna esquerda : UI
--   coluna direita  : KEYBINDS + CONFIG
--
-- Esta aba e a unica que mexe no proprio menu: a libraria sabe
-- repintar-se sozinha quando o tema muda (Library:SetTheme).
-- =====================================================================

return function(ctx)
	local window = ctx.window
	local Library = ctx.Library
	local Settings = ctx.Settings

	-- -----------------------------------------------------------------
	-- ABA "SETTINGS" (icone "sliders")
	-- -----------------------------------------------------------------
	local settingsTab = window:CreateTab({ Name = "SETTINGS" }, "sliders")

	local leftColumn = settingsTab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local rightColumn = settingsTab:Groupbox({ Name = "", Side = "Right", PopOut = false })

	ctx.plainColumn(leftColumn)
	ctx.plainColumn(rightColumn)

	-- -----------------------------------------------------------------
	-- COLUNA ESQUERDA
	-- -----------------------------------------------------------------

	-- SECCAO "UI" ----------------------------------------------------
	leftColumn:Section("UI")

	-- [LOGICA DA MUDANCA DE TEMA AQUI]
	leftColumn:Dropdown({
		Name = "Theme",
		Flag = "SettingsTheme",
		Options = {
			"Midnight",
			"Ocean",
			"Rose",
			"Emerald",
			"Nebula",
			"Synthwave",
			"Toxic",
			"Aurora",
			"Frost",
			"Dracula",
		},
		Default = "Nebula",
		Callback = function(value)
			Settings.settings_theme = value
			local preset = Library.ThemePresets and Library.ThemePresets[value]
			if preset then
				Library:SetTheme(preset, false)
			end
		end,
	})

	-- [LOGICA DA COR DE ACCENT AQUI]
	leftColumn:ColorPicker({
		Name = "Accent Color",
		Flag = "SettingsAccent",
		Default = Color3.fromRGB(170, 80, 255),
		Callback = function(color)
			Settings.settings_accent = color
			local current = Library.Theme and Library.Theme.Accent
			if current and typeof(current) == "Color3" then
				Library:SetTheme({ Accent = color }, false)
			end
		end,
	})

	-- [LOGICA DAS ANIMACOES AQUI]
	leftColumn:Toggle({
		Name = "Animations",
		Flag = "SettingsAnimations",
		Default = true,
		Callback = function(value)
			Settings.settings_animations = value
		end,
	})

	-- [LOGICA DA WATERMARK AQUI]
	leftColumn:Toggle({
		Name = "Watermark",
		Flag = "SettingsWatermark",
		Default = true,
		Callback = function(value)
			Settings.settings_watermark = value
		end,
	})

	-- -----------------------------------------------------------------
	-- COLUNA DIREITA
	-- -----------------------------------------------------------------

	-- SECCAO "KEYBINDS" ----------------------------------------------
	rightColumn:Section("KEYBINDS")

	-- [LOGICA DO KEYBIND DO MENU AQUI]
	rightColumn:Keybind({
		Name = "Toggle UI",
		Flag = "SettingsToggleUiKeybind",
		Default = "RightControl",
		Callback = function(keyCode)
			Settings.settings_toggle_ui_keybind = keyCode
		end,
	})

	-- [LOGICA DA LISTA DE KEYBINDS AQUI]
	rightColumn:Toggle({
		Name = "Show Keybind List",
		Flag = "SettingsKeybindList",
		Callback = function(value)
			Settings.settings_keybind_list = value
		end,
	})

	-- SECCAO "CONFIG" ------------------------------------------------
	rightColumn:Section("CONFIG")

	-- [LOGICA DE GUARDAR/LER/APAGAR A CONFIG AQUI]
	rightColumn:ButtonRow({
		Buttons = {
			{
				Name = "Save",
				Callback = function()
					print("[Airflow] config guardada")
				end,
			},
			{
				Name = "Load",
				Callback = function()
					print("[Airflow] config lida")
				end,
			},
			{
				Name = "Reset",
				Style = "Danger",
				Callback = function()
					print("[Airflow] config reposta")
				end,
			},
		},
	})

	return settingsTab
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
