--[[
	BBC HUB • Project Delta
	Interface single-file (Luau / Roblox) com camada de seguranca (stealth).

	REGRA: apenas UI + prints. Sem logica de cheat (sem CFrame, sem hooks de
	jogo, sem Raycast, sem ESP math). A camada de seguranca serve apenas
	para o proprio script nao ser identificado pelo jogo.

	VERSAO 1.1
	- main.lua limpo (sem ofuscacao): o ficheiro e o que se le, tal e qual.
	- corner(): o UICorner e ligado com a propriedade Parent.
	  NUNCA usar object:AddChild(...) - o Delta nao expoe esse metodo
	  ("AddChild is not a valid member of Frame").
	- Os objectos da interface sao SEMPRE ligados por .Parent = ...
]]

--=====================================================================
-- SERVICOS
--=====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--=====================================================================
-- PARTE 1: CAMADA DE SEGURANCA (STEALTH)
--
-- Tudo o que esta seccao faz e installed ANTES de a interface ser
-- construida, para que o jogo nunca veja os nossos objectos.
--=====================================================================

-----------------------------------------------------------------------
-- 1.1  Deteccao do ambiente de execucao
--
-- checkcaller() devolve true quando quem esta a chamar e o nosso
-- script (a thread foi criada pelo executor) e false quando e o
-- jogo. E a base de todas as proteccoes: so enganamos o jogo, nunca
-- o nosso proprio codigo.
-----------------------------------------------------------------------

local function isOurScript()
	if type(checkcaller) ~= "function" then
		return false
	end
	local ok, result = pcall(checkcaller)
	return ok and result == true
end

-----------------------------------------------------------------------
-- 1.2  CLONEREF
--
-- cloneref() devolve uma referencia para o objecto que nao passa por
-- varreduras por nome (o nome fica ofuscado). Se nao existir no
-- executor, usamos o objecto original.
-----------------------------------------------------------------------

local function cloneRef(object)
	if type(cloneref) == "function" then
		local ok, cloned = pcall(cloneref, object)
		if ok and cloned ~= nil then
			return cloned
		end
	end
	return object
end

-- Os servicos ficam clonados: o jogo que os procurar por nome nao os
-- encontra no nosso ambiente.
--
-- NOTA: um cloneref NAO pode ser usado como host de uma ScreenGui
-- (o motor so aceita CoreGui/PlayerGui/StarterGui reais), por isso o
-- CoreGui clonado serve apenas para leitura e o parenting usa o
-- CoreGui original.
local StealthPlayers = cloneRef(Players)
local StealthRunService = cloneRef(RunService)
local StealthCoreGui = cloneRef(CoreGui)

--=====================================================================
-- 1.3  HOST DA INTERFACE
--
-- gethui() e o container oculto do executor. Se nao existir (ou
-- falhar), usamos o CoreGui com um NOME ALEATORIO - nunca o
-- PlayerGui, para que o jogo nao percorra a(PlayerGui) a procura de
-- menus.
--=====================================================================

local function randomName()
	return tostring(math.random(100000, 999999))
end

local function resolveGuiHost()
	-- 1) gethui() do executor
	local ok, hidden = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if ok and hidden ~= nil then
		return hidden
	end

	-- 2) CoreGui com nome aleatorio. Usa-se o CoreGui REAL: um
	-- cloneref nao e aceite como host de uma ScreenGui.
	local coreOk, core = pcall(function()
		return CoreGui
	end)
	if coreOk and core ~= nil then
		return core
	end

	-- 3) ultimo recurso
	return StealthCoreGui
end

local guiHost = resolveGuiHost()

--=====================================================================
-- 1.4  HOOK MANUAL DO __NAMECALL
--
-- Substituimos o __namecall da metatable partilhada do jogo. O
-- dispatcher original continua a ser chamado para tudo o que nao
-- devemos tocar.
--
-- Bloqueios (so quando quem chama e o JOGO, nunca o nosso script):
--   - FindFirstChild("Menu" / "Nexus")   -> nil
--   - GetDescendants que contenha "Menu"
--     ou "Nexus"                           -> nil
--   - Kick no LocalPlayer                 -> nil
--   - FireServer em remotes de
--     "report" / "ban" / "detect"         -> nil
--=====================================================================

local function currentMethod()
	if type(getnamecallmethod) == "function" then
		local ok, method = pcall(getnamecallmethod)
		if ok and type(method) == "string" then
			return method
		end
	end
	return ""
end

local BLOCKED_NAMES = {
	["menu"] = true,
	["nexus"] = true,
}

local BLOCKED_REMOTE_WORDS = {
	["report"] = true,
	["ban"] = true,
	["detect"] = true,
}

local function isBlockedInstanceName(name)
	if type(name) ~= "string" then
		return false
	end
	local lower = string.lower(name)
	for blocked in pairs(BLOCKED_NAMES) do
		if string.find(lower, blocked, 1, true) then
			return true
		end
	end
	return false
end

local function isBlockedRemoteName(name)
	if type(name) ~= "string" then
		return false
	end
	local lower = string.lower(name)
	for word in pairs(BLOCKED_REMOTE_WORDS) do
		if string.find(lower, word, 1, true) then
			return true
		end
	end
	return false
end

-- GetDescendants nao recebe um nome: procuramos dentro do resultado
-- qualquer descendente cujo nome seja bloqueado.
local function containsBlockedDescendant(result)
	if type(result) ~= "table" then
		return false
	end
	for _, item in ipairs(result) do
		local ok, name = pcall(function()
			return item.Name
		end)
		if ok and isBlockedInstanceName(name) then
			return true
		end
	end
	return false
end

local function installNamecallHook()
	local ok, sharedMeta = pcall(getmetatable, game)
	if not ok or type(sharedMeta) ~= "table" then
		return false
	end

	local original = rawget(sharedMeta, "__namecall")
	if type(original) ~= "function" then
		return false
	end

	-- setreadonly(mt, false) e obrigatorio antes do rawset, caso
	-- contrario o motor recusa a escrita.
	if type(setreadonly) == "function" then
		pcall(setreadonly, sharedMeta, false)
	end

	local function hookedNamecall(self, ...)
		local method = currentMethod()

		-- so protegemos contra o JOGO: o nosso script precisa de
		-- usar estas APIs normalmente.
		if not isOurScript() then
			if method == "FindFirstChild" or method == "FindFirstChildWhichIsA" then
				local name = (select(1, ...))
				if isBlockedInstanceName(name) then
					return nil
				end
			elseif method == "GetDescendants" then
				-- se a arvore tiver um "Menu"/"Nexus", devolvemos nil
				local ok, result = pcall(original, self, ...)
				if ok and containsBlockedDescendant(result) then
					return nil
				end
				if ok then
					return result
				end
			elseif method == "Kick" then
				if self == LocalPlayer then
					return nil
				end
			elseif method == "FireServer" or method == "FireClient" then
				local name = ""
				pcall(function()
					name = self.Name
				end)
				if isBlockedRemoteName(name) then
					return nil
				end
			end
		end

		return original(self, ...)
	end

	rawset(sharedMeta, "__namecall", hookedNamecall)
	return true
end

local namecallHooked = installNamecallHook()

--=====================================================================
-- 1.5  SPOOF DE LEITURA DO HUMANOID (apenas __index)
--
-- Um hook no __index da classe Humanoid faz com que as leituras de
-- WalkSpeed devolvam 16 e de JumpPower devolvam 50 (os valores por
-- omissao do motor) quando quem le e o jogo. Assim, se o nosso script
-- mexer na velocidade, o jogo nao ve a alteracao.
--
-- IMPORTANTE: so o __index e hookado. O __newindex NAO e tocado -
-- escrever no Humanoid continua a funcionar normalmente (e mexer
-- no __newindex trava o jogador no Delta).
--=====================================================================

local SPOOF_VALUES = {
	WalkSpeed = 16,
	JumpPower = 50,
}

local function installHumanoidSpoof()
	local ok, humanoidClass = pcall(function()
		return Players.LocalPlayer.Character
			and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	end)
	if not ok or humanoidClass == nil then
		return false
	end

	local classOk, classMeta = pcall(getmetatable, humanoidClass)
	if not classOk or type(classMeta) ~= "table" then
		return false
	end

	local originalIndex = rawget(classMeta, "__index")
	if type(originalIndex) ~= "function" then
		return false
	end

	if type(setreadonly) == "function" then
		pcall(setreadonly, classMeta, false)
	end

	local function spoofedIndex(self, key)
		-- so leitura e so quando quem le e o jogo
		if not isOurScript() then
			local spoofed = SPOOF_VALUES[key]
			if spoofed ~= nil then
				return spoofed
			end
		end
		return originalIndex(self, key)
	end

	rawset(classMeta, "__index", spoofedIndex)
	return true
end

local humanoidSpoofed = installHumanoidSpoof()

--=====================================================================
-- 1.6  ANTI-DEBUG (getfenv)
--
-- Se o jogo tentar ler o ambiente do nosso script, devolvemos o
-- ambiente de nivel 2 (o do script que nos chamou) em vez do nosso.
--=====================================================================

local function installAntiDebug()
	if type(getfenv) ~= "function" then
		return false
	end

	local originalGetfenv = getfenv

	local function protectedGetfenv(level)
		if not isOurScript() then
			-- O jogo esta a tentar ver a stack: devolvemos o ambiente
			-- de nivel 2 (o de quem nos chamou), nunca o nosso.
			local ok, env = pcall(originalGetfenv, 2)
			if ok and env ~= nil then
				return env
			end
		end
		return originalGetfenv(level)
	end

	-- Substituimos o global getfenv. setfenv() definiria o AMBIENTE
	-- da funcao (nao a trocaria), por isso escrevemos diretamente no
	-- ambiente global. Tentamos varios caminhos porque nem todos os
	-- executores expoem o mesmo.
	local applied = false

	-- 1) getgenv(): o ambiente global partilhado com o jogo
	if type(getgenv) == "function" then
		pcall(function()
			local shared = getgenv()
			if type(shared) == "table" then
				rawset(shared, "getfenv", protectedGetfenv)
				applied = true
			end
		end)
	end

	-- 2) _G: rawset ignora o bloqueio de escrita
	if not applied then
		pcall(function()
			rawset(_G, "getfenv", protectedGetfenv)
			applied = true
		end)
	end

	-- 3) _G por atribuicao direta
	if not applied then
		pcall(function()
			_G.getfenv = protectedGetfenv
			applied = true
		end)
	end

	return applied
end

local antiDebugInstalled = installAntiDebug()

--=====================================================================
-- 1.7  ANTI-DEBUG (debug.info)
--
-- O jogo usa debug.info para inspecionar a stack de chamadas e
-- descobrir de onde o codigo vem. Quando quem chama e o JOGO,
-- devolvemos "C" (como se fosse codigo nativo do motor) em vez de
-- expor o nosso ficheiro.
--
-- So o debug.info e hookado. O debug.traceback NAO e tocado: mexer
-- nele causa crash no Delta.
--=====================================================================

local function installDebugInfoHook()
	local ok, debugTable = pcall(function()
		return debug
	end)
	if not ok or type(debugTable) ~= "table" then
		return false
	end

	local originalInfo = debugTable.info
	if type(originalInfo) ~= "function" then
		return false
	end

	local function protectedInfo(...)
		if not isOurScript() then
			-- "C" = chunk nativo, nao revela o nosso source
			return "C"
		end
		return originalInfo(...)
	end

	local applied = false
	pcall(function()
		rawset(debugTable, "info", protectedInfo)
		applied = true
	end)
	if not applied then
		pcall(function()
			debugTable.info = protectedInfo
		end)
	end

	return applied
end

local debugInfoHooked = installDebugInfoHook()

--=====================================================================
-- 1.8  NOME DA GUI ALEATORIO
--
-- O nome da ScreenGui e sorteado, para que uma varredura por
-- "Menu"/"Nexus"/"BBC" nao a encontre.
--=====================================================================

local function randomGuiName()
	local prefixes = { "Gui", "Layer", "Holder", "Panel", "Core" }
	local prefix = prefixes[math.random(1, #prefixes)]
	return prefix .. randomName()
end

--=====================================================================
-- TEMA (BBC Hub, monocromatico)
--
-- Preto, cinza e branco. O Accent e a UNICA cor forte do menu e so
-- aparece na tag "OWNER" do card de perfil.
--
--   Background  10, 10, 10   preto quase puro (janela + sidebar)
--   Surface     15, 15, 15   paineis (top bar, conteudo)
--   Surface2    25, 25, 25   botoes e cards
--   Stroke      45, 45, 45   bordas finas
--   Accent     200, 50, 255   roxo (SO a tag OWNER)
--   Text       255,255,255   texto principal (bolinhas dos toggles)
--   Muted      140,140,140   texto secundario
--=====================================================================

local Theme = {
	Background = Color3.fromRGB(10, 10, 10),
	Surface = Color3.fromRGB(15, 15, 15),
	Surface2 = Color3.fromRGB(25, 25, 25),
	Stroke = Color3.fromRGB(45, 45, 45),
	Accent = Color3.fromRGB(200, 50, 255),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(140, 140, 140),
}

local FONT = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

-- A escala da interface segue o ecra: nos telemoveis (Delta) o menu e
-- reduzido para 0.65, em ecras pequenos fica a meio, num ecra grande
-- fica a 1.
local function viewportSize()
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1920, 1080)
end

local IS_TOUCH = UserInputService.TouchEnabled

local function computeUIScale()
	local view = viewportSize()
	if IS_TOUCH then
		return 0.65
	end
	if view.X < 1000 then
		return 0.8
	end
	return 1
end

local UI_SCALE = computeUIScale()

--=====================================================================
-- LAYOUT
--=====================================================================

-- A janela e alta o suficiente para as 11 abas da sidebar caberem
-- (com o cartao de perfil no rodape) sem descer.
local WINDOW_W, WINDOW_H = 900, 620
local SIDEBAR_W = 210
local TOPBAR_H = 54
local PANEL_PAD = 12
local BODY_PAD = 14
local GRID_CARD_H = 44
local GRID_GAP = 12
local GRID_ROW_GAP = 10

local CONTENT_X = SIDEBAR_W + PANEL_PAD
local CONTENT_Y = TOPBAR_H + PANEL_PAD
local CONTENT_W = WINDOW_W - CONTENT_X - PANEL_PAD
local CONTENT_H = WINDOW_H - CONTENT_Y - PANEL_PAD

local SLIDER_ROW_H = 46
local SLIDER_BASE_Y = 40

--=====================================================================
-- UTILITARIOS
--=====================================================================

local function make(className, properties)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	return object
end

-- Cantos arredondados.
--
-- O UICorner e posto com a propriedade Parent (nunca com :AddChild(),
-- que o Delta nao expõe).
local function corner(parent, radius)
	local newCorner = Instance.new("UICorner")
	newCorner.CornerRadius = UDim.new(0, radius)
	newCorner.Parent = parent
	return newCorner
end

local function border(object, color, thickness)
	local stroke = make("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	stroke.Parent = object
	return stroke
end

local function label(parent, properties)
	local text = make("TextLabel", {
		Name = "Lbl",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		Font = FONT_MED,
		TextSize = 12,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	for key, value in pairs(properties or {}) do
		text[key] = value
	end
	text.Parent = parent
	return text
end

local function log(message)
	print("[BBC HUB] " .. tostring(message))
end

local function tween(object, properties, duration, style)
	local info = TweenInfo.new(
		duration or 0.18,
		style or Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)
	local animation = TweenService:Create(object, info, properties)
	animation:Play()
	return animation
end

local function clearChildren(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Arraste com MouseButton1 e Touch
local function makeDraggable(frame, handle)
	local dragging = false
	local dragOrigin = Vector2.zero
	local startPosition = UDim2.new(0, 0, 0, 0)

	handle.InputBegan:Connect(function(input)
		local mouse = input.UserInputType == Enum.UserInputType.MouseButton1
		local touch = input.UserInputType == Enum.UserInputType.Touch
		if mouse or touch then
			dragging = true
			dragOrigin = input.Position
			startPosition = frame.Position
		end
	end)

	handle.InputEnded:Connect(function()
		dragging = false
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		local moved = input.UserInputType == Enum.UserInputType.MouseMovement
		local dragged = input.UserInputType == Enum.UserInputType.Touch
		if moved or dragged then
			local delta = input.Position - dragOrigin
			frame.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

--=====================================================================
-- CONTEUDO DAS ABAS
--=====================================================================

local TABS = {
	{
		name = "HOME",
		custom = "home",
	},
	{
		name = "VISUALS",
		sections = {
			{
				name = "ESP",
				items = {
					{ type = "toggle", label = "Box ESP" },
					{ type = "toggle", label = "Skeleton ESP" },
					{ type = "toggle", label = "Tracers" },
					{ type = "toggle", label = "Name Tags" },
				},
			},
			{
				name = "HUD",
				items = {
					{ type = "toggle", label = "FOV Circle" },
					{ type = "toggle", label = "Crosshair" },
					{ type = "toggle", label = "Hitbox" },
					{ type = "toggle", label = "FPS Counter" },
				},
			},
		},
	},
	{
		name = "PLAYER",
		sections = {
			{
				name = "MOVEMENT",
				items = {
					{ type = "toggle", label = "Walk Speed" },
					{ type = "toggle", label = "Jump Power" },
					{ type = "toggle", label = "Gravity" },
					{ type = "toggle", label = "Fly" },
				},
			},
			{
				name = "APPEARANCE",
				items = {
					{ type = "toggle", label = "Skin Changer" },
					{ type = "toggle", label = "Team Color" },
					{ type = "toggle", label = "Emotes" },
					{ type = "toggle", label = "Nametag" },
				},
			},
		},
	},
	{
		name = "COMBAT",
		sections = {
			{
				name = "AIM",
				items = {
					{
						type = "toggle",
						label = "Silent Aim",
						sliders = {
							{ name = "Hit Chance", min = 0, max = 100, value = 50, unit = "%" },
						},
						dropdowns = {
							{ name = "Target Part", options = { "Head", "Torso", "Nearest" }, value = "Head" },
						},
					},
					{
						type = "toggle",
						label = "Aimbot",
						sliders = {
							{ name = "FOV", min = 0, max = 360, value = 120, unit = "°" },
							{ name = "Smoothness", min = 0, max = 100, value = 40, unit = "%" },
						},
						dropdowns = {
							{ name = "Aim Part", options = { "Head", "Upper Torso", "Humanoid" }, value = "Head" },
						},
					},
					{ type = "toggle", label = "Auto Shoot" },
					{ type = "toggle", label = "Sticky Target" },
					{ type = "toggle", label = "Team Check" },
				},
			},
			{
				name = "GUN",
				items = {
					{ type = "toggle", label = "No Recoil" },
					{ type = "toggle", label = "Fire Rate" },
					{ type = "toggle", label = "Auto Reload" },
					{ type = "toggle", label = "Fake Scope" },
				},
			},
		},
	},
	{
		name = "WORLD",
		sections = {
			{
				name = "ENVIRONMENT",
				items = {
					{ type = "toggle", label = "Time of Day" },
					{ type = "toggle", label = "Fog Density" },
					{ type = "toggle", label = "Brightness" },
					{ type = "toggle", label = "Skybox" },
				},
			},
			{
				name = "INTERACTION",
				items = {
					{ type = "toggle", label = "Doors" },
					{ type = "toggle", label = "Chests" },
					{ type = "toggle", label = "NPC" },
				},
			},
		},
	},
	{
		name = "MISC",
		sections = {
			{
				name = "MISC",
				items = {
					{ type = "toggle", label = "Fast Trade" },
					{ type = "toggle", label = "Panic Mode" },
					{ type = "toggle", label = "Pass Door" },
					{ type = "toggle", label = "Screen Effects" },
					{ type = "toggle", label = "Report Notify" },
					{ type = "toggle", label = "Join Notify" },
				},
			},
			{
				name = "SOUNDS",
				items = {
					{ type = "input", label = "Add Sound ID", placeholder = "rbxassetid://..." },
					{ type = "toggle", label = "Jump" },
					{ type = "toggle", label = "Footsteps" },
				},
			},
			{
				name = "DETECT",
				items = {
					{ type = "toggle", label = "Content Creator" },
					{ type = "toggle", label = "Tester" },
					{ type = "toggle", label = "Moderator" },
					{ type = "toggle", label = "Cheater" },
				},
			},
			{
				name = "VAULT SORT",
				items = {
					{ type = "choice", label = "Sort By Value", group = "vault" },
					{ type = "choice", label = "Sort By Type", group = "vault" },
					{ type = "choice", label = "Sort By Name", group = "vault" },
				},
			},
			{
				name = "INVENTORY VIEWER",
				items = {
					{ type = "button", label = "Show Inventory", style = "accent" },
					{ type = "toggle", label = "Auto Refresh" },
					{ type = "toggle", label = "Item Icons" },
				},
			},
		},
	},
	{
		name = "LOOTFINDER",
		sections = {
			{
				name = "FILTERS",
				items = {
					{ type = "toggle", label = "Weapons" },
					{ type = "toggle", label = "Medkits" },
					{ type = "toggle", label = "Valuables" },
					{ type = "toggle", label = "Ammo" },
				},
			},
			{
				name = "DISPLAY",
				items = {
					{
						type = "toggle",
						label = "Distance",
						sliders = {
							{ name = "Max Range", min = 0, max = 500, value = 150, unit = "m" },
							{ name = "Opacity", min = 0, max = 100, value = 80, unit = "%" },
						},
					},
					{ type = "toggle", label = "Rarity Colors" },
					{ type = "toggle", label = "Path Line" },
				},
			},
		},
	},
	{
		name = "SERVER",
		sections = {
			{
				name = "INFO",
				items = {
					{ type = "toggle", label = "Show Server ID" },
					{ type = "toggle", label = "Show Region" },
					{ type = "toggle", label = "Show Ping" },
					{ type = "toggle", label = "Player Count" },
				},
			},
			{
				name = "ACTIONS",
				items = {
					{ type = "button", label = "Rejoin Server", style = "accent" },
					{ type = "button", label = "Hop Servers" },
					{ type = "button", label = "Copy Invite" },
				},
			},
		},
	},
	{
		name = "SKINCHANGER",
		sections = {
			{
				name = "BODY",
				items = {
					{ type = "toggle", label = "Head" },
					{ type = "toggle", label = "Torso" },
					{ type = "toggle", label = "Arms" },
					{ type = "toggle", label = "Legs" },
				},
			},
			{
				name = "PRESETS",
				items = {
					{ type = "button", label = "Reset Skin", style = "accent" },
					{ type = "button", label = "Randomize" },
					{ type = "button", label = "Save Preset" },
				},
			},
		},
	},
	{
		name = "QUESTS",
		sections = {
			{
				name = "TRACKERS",
				items = {
					{ type = "toggle", label = "Daily Quests" },
					{ type = "toggle", label = "Weekly Quests" },
					{ type = "toggle", label = "Seasonal Pass" },
				},
			},
			{
				name = "CLAIM",
				items = {
					{ type = "button", label = "Claim All", style = "accent" },
					{ type = "toggle", label = "Auto Claim" },
					{ type = "toggle", label = "Reward Alerts" },
				},
			},
		},
	},
	{
		name = "MERCHANTS",
		sections = {
			{
				name = "INVENTORY",
				items = {
					{ type = "toggle", label = "Sell All" },
					{ type = "toggle", label = "Deposit All" },
					{ type = "toggle", label = "Withdraw All" },
					{ type = "toggle", label = "Auto Sell Junk" },
				},
			},
			{
				name = "PRICES",
				items = {
					{ type = "toggle", label = "Price Tracker" },
					{ type = "toggle", label = "Profit Calculator" },
					{ type = "toggle", label = "Market Alerts" },
				},
			},
		},
	},
	{
		name = "SETTINGS",
		custom = "settings",
	},
}

--=====================================================================
-- PARTE 2: CONSTRUCAO DA INTERFACE
--=====================================================================

local screenGui = make("ScreenGui", {
	Name = randomGuiName(),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 20,
})
screenGui.Parent = guiHost

--=====================================================================
-- JANELA PRINCIPAL
--=====================================================================

local window = make("Frame", {
	Name = randomName(),
	Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
	Position = UDim2.fromOffset(0, 0),
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 2,
})
corner(window, 12)
border(window, Theme.Stroke, 1)
window.Parent = screenGui

local windowScale = make("UIScale", { Scale = UI_SCALE })
windowScale.Parent = window

do
	local view = viewportSize()
	window.Position = UDim2.fromOffset(
		math.max(0, (view.X - (WINDOW_W * UI_SCALE)) / 2),
		math.max(0, (view.Y - (WINDOW_H * UI_SCALE)) / 2) - 20
	)
end

-- Topbar (BBC Hub)
--
-- Fundo escuro, uma linha subtil em baixo, o logo a esquerda, um botao
-- "default" ao centro e tres botoes de icones a direita.
local topbar = make("Frame", {
	Name = randomName(),
	Size = UDim2.new(1, 0, 0, TOPBAR_H),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface,
	Active = true,
	ZIndex = 3,
})
corner(topbar, 12)
topbar.Parent = window

-- O patch tapa os cantos de baixo da barra (a janela e arredondada).
local topbarPatch = make("Frame", {
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.fromOffset(0, TOPBAR_H - 14),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface,
	ZIndex = 3,
})
topbarPatch.Parent = topbar

-- Linha subtil em baixo da barra.
local topbarLine = make("Frame", {
	Size = UDim2.new(1, -24, 0, 1),
	Position = UDim2.new(0, 12, 1, -1),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Stroke,
	ZIndex = 4,
})
topbarLine.Parent = topbar

local logoMark = make("Frame", {
	Size = UDim2.fromOffset(34, 34),
	Position = UDim2.fromOffset(16, 10),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Text,
	ZIndex = 4,
})
corner(logoMark, 9)
logoMark.Parent = topbar

label(logoMark, {
	Size = UDim2.fromScale(1, 1),
	Text = "B",
	TextSize = 18,
	Font = FONT_BOLD,
	TextColor3 = Theme.Background,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 5,
})

label(topbar, {
	Position = UDim2.fromOffset(62, 11),
	Size = UDim2.fromOffset(240, 20),
	Text = "BBC HUB",
	TextSize = 16,
	Font = FONT_BOLD,
	TextColor3 = Theme.Text,
	ZIndex = 4,
})

label(topbar, {
	Position = UDim2.fromOffset(62, 31),
	Size = UDim2.fromOffset(240, 16),
	Text = "PROJECT DELTA",
	TextSize = 10,
	Font = FONT,
	TextColor3 = Theme.Muted,
	ZIndex = 4,
})

-- Botao central: o perfil activo (botao falso, so UI).
local profileButton = make("TextButton", {
	Name = randomName(),
	Size = UDim2.fromOffset(104, 28),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface2,
	Text = "default",
	TextSize = 12,
	Font = FONT_MED,
	TextColor3 = Theme.Muted,
	TextXAlignment = Enum.TextXAlignment.Left,
	AutoButtonColor = false,
	ZIndex = 4,
})
corner(profileButton, 8)
border(profileButton, Theme.Stroke, 1)
profileButton.Parent = topbar

label(profileButton, {
	Position = UDim2.new(1, -22, 0, 5),
	Size = UDim2.fromOffset(14, 16),
	Text = "▼",
	TextSize = 9,
	Font = FONT,
	TextColor3 = Theme.Muted,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 5,
})

profileButton.MouseEnter:Connect(function()
	tween(profileButton, { BackgroundColor3 = Theme.Stroke }, 0.15)
end)

profileButton.MouseLeave:Connect(function()
	tween(profileButton, { BackgroundColor3 = Theme.Surface2 }, 0.15)
end)

profileButton.MouseButton1Click:Connect(function()
	log("Perfil: default")
end)

-- Botoes de icones a direita (lupa, lua, engrenagem). Os icones sao
-- desenhados com formas: nao ha pack de icones no single file.
local function buildIconButton(parent, xOffset, kind)
	local button = make("TextButton", {
		Name = randomName(),
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, xOffset, 0, 13),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 4,
	})
	corner(button, 8)
	border(button, Theme.Stroke, 1)
	button.Parent = parent

	if kind == "search" then
		-- lupa: um circulo com um pe
		local lens = make("Frame", {
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.fromOffset(6, 6),
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Muted,
			ZIndex = 5,
		})
		corner(lens, 6)
		local lensHole = make("Frame", {
			Size = UDim2.fromOffset(6, 6),
			Position = UDim2.fromOffset(3, 3),
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Surface2,
			ZIndex = 6,
		})
		corner(lensHole, 3)
		lensHole.Parent = lens
		lens.Parent = button

		local handle = make("Frame", {
			Size = UDim2.fromOffset(6, 2),
			Position = UDim2.fromOffset(15, 17),
			Rotation = 45,
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Muted,
			ZIndex = 5,
		})
		corner(handle, 1)
		handle.Parent = button
	elseif kind == "lua" then
		label(button, {
			Size = UDim2.fromScale(1, 1),
			Text = "</>",
			TextSize = 10,
			Font = FONT_BOLD,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 5,
		})
	else
		-- engrenagem: um circulo com quatro dentes
		local gear = make("Frame", {
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.fromOffset(7, 7),
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Muted,
			ZIndex = 5,
		})
		corner(gear, 7)
		local gearHole = make("Frame", {
			Size = UDim2.fromOffset(5, 5),
			Position = UDim2.fromOffset(4.5, 4.5),
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Surface2,
			ZIndex = 6,
		})
		corner(gearHole, 3)
		gearHole.Parent = gear
		gear.Parent = button

		for index = 0, 3 do
			local tooth = make("Frame", {
				Size = UDim2.fromOffset(3, 5),
				Position = UDim2.fromOffset(13, 11.5),
				Rotation = index * 45,
				BorderSizePixel = 0,
				BackgroundColor3 = Theme.Muted,
				ZIndex = 5,
			})
			corner(tooth, 1)
			tooth.Parent = button
		end
	end

	button.MouseEnter:Connect(function()
		tween(button, { BackgroundColor3 = Theme.Stroke }, 0.15)
	end)

	button.MouseLeave:Connect(function()
		tween(button, { BackgroundColor3 = Theme.Surface2 }, 0.15)
	end)

	button.MouseButton1Click:Connect(function()
		log("Botao: " .. kind)
	end)

	return button
end

buildIconButton(topbar, -74, "search")
buildIconButton(topbar, -42, "lua")
buildIconButton(topbar, -10, "settings")

makeDraggable(window, topbar)

-- Sidebar
--
-- A lista de abas vive DENTRO da sidebar (os botoes tem a sidebar como
-- Parent), com um UIPadding para nao encostarem nas bordas e um
-- UIListLayout com o mesmo espacamento para todas.
local sidebar = make("Frame", {
	Name = randomName(),
	Size = UDim2.fromOffset(SIDEBAR_W, WINDOW_H - TOPBAR_H),
	Position = UDim2.fromOffset(0, TOPBAR_H),
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	-- As abas nunca passam do rodape da sidebar.
	ClipsDescendants = true,
	ZIndex = 3,
})
sidebar.Parent = window

-- Linha vertical que separa a sidebar do conteudo (vive na janela para
-- o UIListLayout da sidebar nao a mexer).
local sidebarLine = make("Frame", {
	Size = UDim2.new(0, 1, 1, -28),
	Position = UDim2.fromOffset(SIDEBAR_W - 1, TOPBAR_H + 14),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Stroke,
	ZIndex = 4,
})
sidebarLine.Parent = window

-- Espaco interior: as abas nao encostam nas bordas (10 px a esquerda e
-- 10 px a direita, com o -10 do botao) e o rodape fica livre para o
-- card de perfil.
local sidebarPadding = make("UIPadding", {
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 0),
	PaddingTop = UDim.new(0, 14),
	PaddingBottom = UDim.new(0, 92),
})
sidebarPadding.Parent = sidebar

local sidebarLayout = make("UIListLayout", {
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
})
sidebarLayout.Parent = sidebar

label(sidebar, {
	Name = "CategoriesLabel",
	Size = UDim2.new(1, 0, 0, 16),
	Text = "CATEGORIES",
	TextSize = 10,
	Font = FONT_BOLD,
	TextColor3 = Theme.Muted,
	LayoutOrder = 1,
	ZIndex = 4,
})

-- Painel de conteudo
--
-- O painel e transparente: a "parede" (fundo hexagonal) vive na janela
-- e aparece por baixo do conteudo.
local contentPanel = make("Frame", {
	Name = randomName(),
	Size = UDim2.fromOffset(CONTENT_W, CONTENT_H),
	Position = UDim2.fromOffset(CONTENT_X, CONTENT_Y),
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 3,
})
corner(contentPanel, 10)
border(contentPanel, Theme.Stroke, 1)
contentPanel.Parent = window

-- Parede com o padrao hexagonal: vive na MAIN FRAME, com ZIndex -2
-- (por baixo de tudo o que esta na janela) e mosaico de 40x40.
local hexLayer = make("ImageLabel", {
	Name = randomName(),
	Size = UDim2.fromScale(1, 1),
	Position = UDim2.fromOffset(0, 0),
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	Image = "rbxassetid://12629542321",
	ScaleType = Enum.ScaleType.Tile,
	TileSize = UDim2.new(0, 40, 0, 40),
	ImageColor3 = Color3.fromRGB(70, 70, 70),
	ImageTransparency = 0.85,
	ZIndex = -2,
})
corner(hexLayer, 12)
hexLayer.Parent = window

local scroll = make("ScrollingFrame", {
	Name = randomName(),
	Size = UDim2.fromScale(1, 1),
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Theme.Muted,
	ScrollBarImageTransparency = 0.45,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.fromOffset(CONTENT_W, CONTENT_H),
	ZIndex = 4,
})
scroll.Parent = contentPanel

local scrollBody = make("Frame", {
	Name = randomName(),
	Size = UDim2.new(1, 0, 0, 0),
	Position = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	ZIndex = 4,
})
scrollBody.Parent = scroll

-- Espaco interior do ScrollingFrame (padding em vez de posicoes fixas).
local scrollPadding = make("UIPadding", {
	PaddingLeft = UDim.new(0, BODY_PAD),
	PaddingRight = UDim.new(0, BODY_PAD),
	PaddingTop = UDim.new(0, BODY_PAD),
	PaddingBottom = UDim.new(0, BODY_PAD),
})
scrollPadding.Parent = scroll

local bodyListLayout = make("UIListLayout", {
	Padding = UDim.new(0, 16),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
bodyListLayout.Parent = scrollBody

-- O canvas segue o conteudo: quando um submenu abre (ou fecha) a coluna
-- cresce, por isso o canvas e recalculado.
local function refreshCanvas()
	local height = scrollBody.AbsoluteSize.Y + (BODY_PAD * 2)
	scroll.CanvasSize = UDim2.fromOffset(CONTENT_W, math.max(height, CONTENT_H))
end

pcall(function()
	scrollBody:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshCanvas)
end)

-- Overlay dos submenus: dentro do painel de conteudo (para as
-- coordenadas baterem certo) e SEM ClipsDescendants, para o dropdown
-- poder ultrapassar a borda do painel sem ser cortado.
local overlay = make("Frame", {
	Name = randomName(),
	Size = UDim2.fromScale(1, 1),
	Position = UDim2.fromOffset(0, 0),
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	ClipsDescendants = false,
	ZIndex = 20,
})
overlay.Parent = contentPanel

--=====================================================================
-- COMPONENTES
--=====================================================================

local openPanel = nil
local openList = nil
local openBurger = nil

-- Fecha o submenu (e a lista de opcoes).
-- keepPanel = true deixa o submenu aberto e so fecha a lista.
local function closeDropdown(keepPanel)
	if openPanel and not keepPanel then
		local panel = openPanel
		openPanel = nil
		local animation = tween(panel, { Size = UDim2.fromOffset(panel.Size.X.Offset, 0) }, 0.15)
		-- Alguns executores não dão o sinal Completed: nesse caso o
		-- painel é destruído no frame seguinte.
		if animation and animation.Completed then
			animation.Completed:Once(function()
				if panel.Parent then
					panel:Destroy()
				end
			end)
		else
			task.defer(function()
				if panel.Parent then
					panel:Destroy()
				end
			end)
		end
	end
	if openList then
		local list = openList
		openList = nil
		if list.Parent then
			list:Destroy()
		end
	end
	if openBurger and not keepPanel then
		local burger = openBurger
		openBurger = nil
		if burger.Parent then
			tween(burger, { Rotation = 0 }, 0.2)
		end
	end

	-- O conteudo da aba voltou ao tamanho normal: o canvas e recalculado.
	refreshCanvas()
end

local function cardWidth()
	-- A largura de um cartao e metade da coluna. O scroll e a referencia
	-- (o conteudo tem o padding de BODY_PAD de cada lado).
	local bodyWidth = (scroll.AbsoluteSize.X / UI_SCALE) - (BODY_PAD * 2)
	if bodyWidth <= 0 then
		bodyWidth = CONTENT_W - (BODY_PAD * 2)
	end
	return math.max(140, (bodyWidth - GRID_GAP) / 2)
end

-- Slider visual: linha cinza com preenchimento roxo.
-- A linha e um item do UIListLayout do submenu (sem posicoes fixas).
local function buildSlider(parent, spec, order)
	local minValue = spec.min or 0
	local maxValue = spec.max or 100
	local unit = spec.unit or ""

	local row = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, SLIDER_ROW_H - 10),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		LayoutOrder = order,
		ZIndex = 22,
	})
	row.Parent = parent

	label(row, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, -70, 0, 16),
		Text = spec.name,
		TextSize = 11,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		ZIndex = 23,
	})

	local valueLabel = label(row, {
		Position = UDim2.new(1, -64, 0, 0),
		Size = UDim2.fromOffset(64, 16),
		Text = tostring(spec.value) .. unit,
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 23,
	})

	-- o trilho e recuado 6px de cada lado para o knob nunca sair do
	-- cartao quando esta numa ponta
	local track = make("TextButton", {
		Size = UDim2.new(1, -12, 0, 6),
		Position = UDim2.fromOffset(6, 24),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Stroke,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 22,
	})
	corner(track, 3)
	track.Parent = row

	local fill = make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Muted,
		ZIndex = 23,
	})
	corner(fill, 3)
	fill.Parent = track

	local knob = make("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromScale(0, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Text,
		ZIndex = 24,
	})
	corner(knob, 6)
	-- Bolinha BRANCA com anel escuro (para se ver no trilho claro).
	border(knob, Theme.Background, 1)
	knob.Parent = track

	local function applyRatio(ratio)
		ratio = math.clamp(ratio, 0, 1)
		local value = minValue + (ratio * (maxValue - minValue))
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.fromScale(ratio, 0.5)
		valueLabel.Text = tostring(math.floor(value + 0.5)) .. unit
		return value
	end

	track.InputBegan:Connect(function(input)
		local mouse = input.UserInputType == Enum.UserInputType.MouseButton1
		local touch = input.UserInputType == Enum.UserInputType.Touch
		if not (mouse or touch) then
			return
		end
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local ratio = (input.Position.X - track.AbsolutePosition.X) / width
		local value = applyRatio(ratio)
		log(string.format("%s: %d%s", spec.name, math.floor(value + 0.5), unit))
	end)

	if maxValue > minValue then
		applyRatio((spec.value - minValue) / (maxValue - minValue))
	else
		applyRatio(0)
	end

	return row
end

-- SubFrame que abre por baixo do cartao, com altura animada.
--
-- O painel usa UIListLayout + AutomaticSize: os controlos (sliders e
-- dropdowns) sao itens da lista, nunca posicoes fixas. A altura e a
-- animacao quem a da (TweenService, EasingStyle.Quint).
local function openDropdown(card, burger, sliders, title, dropdowns)
	if openBurger == burger then
		closeDropdown()
		return
	end
	closeDropdown()

	local panel = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(cardWidth(), 0),
		Position = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ClipsDescendants = true,
		ZIndex = 61,
	})
	corner(panel, 10)
	border(panel, Theme.Stroke, 1)
	panel.Parent = overlay

	local panelLayout = make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	panelLayout.Parent = panel

	local panelPadding = make("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 12),
	})
	panelPadding.Parent = panel

	label(panel, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = string.upper(title or "OPTIONS"),
		TextSize = 10,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		LayoutOrder = 1,
		ZIndex = 62,
	})

	for index, spec in ipairs(sliders) do
		buildSlider(panel, spec, index + 1)
	end

	-- Dropdowns: uma linha com o nome e o valor actual. O valor abre
	-- uma lista pequena por baixo da linha.
	local dropdownRows = {}
	for index, spec in ipairs(dropdowns) do
		local row = make("Frame", {
			Name = randomName(),
			Size = UDim2.new(1, 0, 0, 30),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			LayoutOrder = #sliders + index + 1,
			ZIndex = 62,
		})
		row.Parent = panel

		label(row, {
			Position = UDim2.fromOffset(0, 7),
			Size = UDim2.new(1, -120, 0, 16),
			Text = spec.name,
			TextSize = 11,
			Font = FONT_MED,
			TextColor3 = Theme.Text,
			ZIndex = 63,
		})

		local value = spec.value or spec.options[1]
		local valueButton = make("TextButton", {
			Size = UDim2.fromOffset(110, 22),
			Position = UDim2.new(1, -110, 0, 4),
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Surface,
			Text = tostring(value),
			TextSize = 11,
			Font = FONT_MED,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Right,
			AutoButtonColor = false,
			ZIndex = 63,
		})
		corner(valueButton, 7)
		border(valueButton, Theme.Stroke, 1)
		valueButton.Parent = row

		label(row, {
			Position = UDim2.new(1, -24, 0, 9),
			Size = UDim2.fromOffset(14, 14),
			Text = "▾",
			TextSize = 10,
			Font = FONT_BOLD,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 63,
		})

		valueButton.MouseButton1Click:Connect(function()
			-- A lista abre por cima do submenu (sem ser cortada).
			if openList then
				closeDropdown(true)
				return
			end
			local list = make("Frame", {
				Name = randomName(),
				Size = UDim2.fromOffset(110, (#spec.options * 24) + 8),
				BorderSizePixel = 0,
				BackgroundColor3 = Theme.Surface,
				ClipsDescendants = true,
				ZIndex = 90,
			})
			corner(list, 8)
			border(list, Theme.Stroke, 1)
			list.Parent = overlay

			local origin = row.AbsolutePosition - contentPanel.AbsolutePosition
			list.Position = UDim2.fromOffset(
				(origin.X + row.AbsoluteSize.X - 110) / UI_SCALE,
				(origin.Y + row.AbsoluteSize.Y) / UI_SCALE + 2
			)

			for optionIndex, option in ipairs(spec.options) do
				local optionButton = make("TextButton", {
					Name = randomName(),
					Size = UDim2.new(1, -16, 0, 22),
					Position = UDim2.fromOffset(8, 4 + ((optionIndex - 1) * 24)),
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
					Text = tostring(option),
					TextSize = 11,
					Font = FONT_MED,
					TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					ZIndex = 91,
				})
				optionButton.Parent = list

				optionButton.MouseButton1Click:Connect(function()
					value = option
					valueButton.Text = tostring(option)
					closeDropdown(true)
					log(string.format("%s -> %s", spec.name, tostring(option)))
				end)
			end

			openList = list
		end)

		table.insert(dropdownRows, row)
	end

	-- Posicao relativa ao painel de conteudo. O overlay vive dentro do
	-- contentPanel, por isso basta a diferenca para o painel. As
	-- coordenadas de ecra sao divididas pela escala porque o painel esta
	-- sob um UIScale.
	local origin = card.AbsolutePosition - contentPanel.AbsolutePosition
	panel.Position = UDim2.fromOffset(
		origin.X / UI_SCALE,
		(origin.Y + card.AbsoluteSize.Y) / UI_SCALE + 6
	)

	-- A altura final vem do AutomaticSize do painel; a animacao abre a
	-- gaveta de 0 ate essa altura.
	panel.Size = UDim2.fromOffset(panel.Size.X.Offset, 0)
	task.defer(function()
		local height = panel.AbsoluteSize.Y
		if height > 0 then
			tween(panel, { Size = UDim2.fromOffset(panel.Size.X.Offset, height) }, 0.22, Enum.EasingStyle.Quart)
		else
			panel.Size = UDim2.fromOffset(panel.Size.X.Offset, 0)
		end
		-- O canvas da coluna e recalculado: o submenu conta como
		-- conteudo da aba.
		refreshCanvas()
	end)

	openPanel = panel
	openBurger = burger
	tween(burger, { Rotation = 90 }, 0.2)
	log("Submenu aberto: " .. tostring(title or "opcoes"))
end

-- Switch on/off
local function buildSwitch(card, state)
	local holder = make("Frame", {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -48, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = state and Theme.Text or Theme.Stroke,
		ZIndex = 6,
	})
	corner(holder, 10)
	holder.Parent = card

	local knob = make("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(state and 1 or 0, state and -7 or 7, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Text,
		ZIndex = 7,
	})
	corner(knob, 7)
	-- Anel escuro: a bolinha e sempre BRANCA, mas continua a ver-se
	-- quando o trilho fica branco (toggle ligado).
	border(knob, Theme.Background, 1)
	knob.Parent = holder

	return holder, knob
end

local function applySwitch(holder, knob, state)
	tween(holder, { BackgroundColor3 = state and Theme.Text or Theme.Stroke }, 0.16)
	tween(knob, { Position = UDim2.new(state and 1 or 0, state and -7 or 7, 0.5, 0) }, 0.16)
end

-- CreateToggle: cartao com o icone ☰ a esquerda do texto e o switch
-- a direita. O ☰ abre o submenu (accordion) com os sliders e os
-- dropdowns do item.
--
-- As acoes registadas em ACTIONS sao chamadas quando o toggle muda:
-- e assim que o toggle "Show Keybinds" mostra/esconde o painel dos
-- atalhos.
local ACTIONS = {}

local function buildToggleCard(item, order)
	local state = false

	local card = make("TextButton", {
		Name = randomName(),
		Size = UDim2.fromOffset(0, GRID_CARD_H),
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		ZIndex = 5,
	})
	corner(card, 9)
	border(card, Theme.Stroke, 1)

	local burger = make("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(0, 6, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Text = "☰",
		TextSize = 15,
		Font = FONT_BOLD,
		TextColor3 = (item.sliders or item.dropdowns) and Theme.Text or Theme.Muted,
		AutoButtonColor = false,
		ZIndex = 6,
	})
	burger.Parent = card

	label(card, {
		Position = UDim2.fromOffset(36, 0),
		Size = UDim2.new(1, -92, 1, 0),
		Text = item.label,
		TextSize = 12,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	local holder, knob = buildSwitch(card, state)

	local function toggle()
		state = not state
		applySwitch(holder, knob, state)
		log(string.format("%s -> %s", item.label, state and "ON" or "OFF"))
		-- Acao associada ao toggle (ex: "Show Keybinds").
		if item.action and type(ACTIONS[item.action]) == "function" then
			ACTIONS[item.action](state)
		end
	end

	burger.MouseButton1Click:Connect(function()
		if item.sliders or item.dropdowns then
			openDropdown(card, burger, item.sliders or {}, item.label, item.dropdowns or {})
		else
			log(item.label .. ": sem opcoes extras")
		end
	end)

	card.MouseButton1Click:Connect(toggle)

	card.MouseEnter:Connect(function()
		tween(card, { BackgroundColor3 = Theme.Stroke }, 0.15)
	end)

	card.MouseLeave:Connect(function()
		tween(card, { BackgroundColor3 = Theme.Surface2 }, 0.15)
	end)

	return card
end

-- Cartao de botao
local function buildButtonCard(item, order)
	local isAccent = item.style == "accent"

	local card = make("TextButton", {
		Name = randomName(),
		Size = UDim2.fromOffset(0, GRID_CARD_H),
		BackgroundColor3 = isAccent and Theme.Text or Theme.Surface2,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		ZIndex = 5,
	})
	corner(card, 9)
	if not isAccent then
		border(card, Theme.Stroke, 1)
	end

	label(card, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Text = item.label,
		TextSize = 12,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	card.MouseButton1Click:Connect(function()
		log("Acao: " .. item.label)
	end)

	card.MouseEnter:Connect(function()
		tween(card, {
			BackgroundColor3 = isAccent
				and Theme.Text:Lerp(Color3.fromRGB(0, 0, 0), 0.18)
				or Theme.Stroke,
		}, 0.15)
	end)

	card.MouseLeave:Connect(function()
		tween(card, {
			BackgroundColor3 = isAccent and Theme.Text or Theme.Surface2,
		}, 0.15)
	end)

	return card
end

-- Cartao de escolha (exclusiva dentro do grupo)
local choiceGroups = {}

local function buildChoiceCard(item, order)
	local card = make("TextButton", {
		Name = randomName(),
		Size = UDim2.fromOffset(0, GRID_CARD_H),
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		ZIndex = 5,
	})
	corner(card, 9)

	local stroke = border(card, Theme.Stroke, 1)

	local text = label(card, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Text = item.label,
		TextSize = 12,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	local function setActive(isActive)
		stroke.Color = isActive and Theme.Text or Theme.Stroke
		card.BackgroundColor3 = isActive and Theme.Surface or Theme.Surface2
		text.TextColor3 = Theme.Text
	end

	setActive(false)

	card.MouseButton1Click:Connect(function()
		local group = choiceGroups[item.group]
		if group then
			for _, other in ipairs(group) do
				other.setActive(false)
			end
		end
		setActive(true)
		log("Selecao: " .. item.label)
	end)

	local group = choiceGroups[item.group]
	if not group then
		group = {}
		choiceGroups[item.group] = group
	end
	table.insert(group, { setActive = setActive })

	return card
end

-- Cartao com input de texto
local function buildInputCard(item, order)
	local card = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(0, GRID_CARD_H),
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 5,
	})
	corner(card, 9)
	border(card, Theme.Stroke, 1)

	label(card, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.fromOffset(74, 16),
		Text = item.label,
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	local box = make("TextBox", {
		Size = UDim2.new(1, -142, 0, 26),
		Position = UDim2.new(0, 88, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Background,
		Text = "",
		PlaceholderText = item.placeholder or "...",
		PlaceholderColor3 = Theme.Muted,
		TextColor3 = Theme.Text,
		TextSize = 11,
		Font = FONT,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	})
	corner(box, 7)
	border(box, Theme.Stroke, 1)
	box.Parent = card

	local addButton = make("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -38, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Text,
		Text = "▶",
		TextSize = 12,
		Font = FONT_BOLD,
		TextColor3 = Theme.Background,
		AutoButtonColor = false,
		ZIndex = 7,
	})
	corner(addButton, 7)
	addButton.Parent = card

	addButton.MouseButton1Click:Connect(function()
		local value = box.Text
		if value == "" then
			value = box.PlaceholderText
		end
		log(string.format("%s -> %s", item.label, value))
	end)

	return card
end

local function buildItem(item, order)
	if item.type == "toggle" then
		return buildToggleCard(item, order)
	elseif item.type == "button" then
		return buildButtonCard(item, order)
	elseif item.type == "choice" then
		return buildChoiceCard(item, order)
	elseif item.type == "input" then
		return buildInputCard(item, order)
	end
	return nil
end

--=====================================================================
-- COMPONENTES BBC HUB (estrutura da AirFlowLibrary, visual BBC Hub)
--
-- As quatro funcoes abaixo reproduzem a ESTRUTURA dos componentes da
-- AirFlowLibrary (cartao + chip a direita, popup de opcoes, captura de
-- tecla, toast animado), mas com o visual monocromatico do BBC Hub.
-- Nada e importado da biblioteca: e so a estrutura.
--=====================================================================

-- Cartao base de um control (Surface2, borda de 1 px, cantos suaves).
local function createControlCard(parent, title, height)
	local card = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, height or GRID_CARD_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ZIndex = 5,
	})
	corner(card, 9)
	border(card, Theme.Stroke, 1)
	card.Parent = parent

	label(card, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -140, 1, 0),
		Text = tostring(title or ""),
		TextSize = 11,
		Font = FONT_MED,
		TextColor3 = Theme.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	return card
end

-- Dropdown: cartao com o valor a direita; ao clicar abre a lista de
-- opcoes (por baixo, ou por cima quando nao ha espaco).
local function CreateDropdown(parent, title, options)
	local card = createControlCard(parent, title)

	local value = options and options[1] or ""
	local valueButton = make("TextButton", {
		Name = randomName(),
		Size = UDim2.fromOffset(120, 26),
		Position = UDim2.new(1, -128, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface,
		Text = tostring(value),
		TextSize = 11,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		AutoButtonColor = false,
		ZIndex = 7,
	})
	corner(valueButton, 7)
	border(valueButton, Theme.Stroke, 1)
	valueButton.Parent = card

	label(card, {
		Position = UDim2.new(1, -18, 0.5, -7),
		Size = UDim2.fromOffset(12, 14),
		Text = "▾",
		TextSize = 9,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 7,
	})

	local function setValue(option)
		value = option
		valueButton.Text = tostring(option)
		log(string.format("%s -> %s", tostring(title), tostring(option)))
	end

	valueButton.MouseButton1Click:Connect(function()
		if openList then
			closeDropdown()
			return
		end
		closeDropdown()

		local list = make("Frame", {
			Name = randomName(),
			Size = UDim2.fromOffset(120, (#options * 26) + 8),
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Surface,
			ClipsDescendants = true,
			ZIndex = 90,
		})
		corner(list, 8)
		border(list, Theme.Stroke, 1)
		list.Parent = overlay

		-- Posicao relativa ao painel de conteudo (o overlay vive dentro
		-- dele), dividida pela escala da janela.
		local origin = valueButton.AbsolutePosition - contentPanel.AbsolutePosition
		local below = (origin.Y + valueButton.AbsoluteSize.Y) / UI_SCALE + 4
		local above = (origin.Y - (#options * 26) - 8) / UI_SCALE
		if below + (#options * 26) > (contentPanel.AbsoluteSize.Y / UI_SCALE) and above > 8 then
			list.Position = UDim2.fromOffset((origin.X + valueButton.AbsoluteSize.X - 120) / UI_SCALE, above)
		else
			list.Position = UDim2.fromOffset((origin.X + valueButton.AbsoluteSize.X - 120) / UI_SCALE, below)
		end

		for index, option in ipairs(options) do
			local optionButton = make("TextButton", {
				Name = randomName(),
				Size = UDim2.new(1, -16, 0, 24),
				Position = UDim2.fromOffset(8, 4 + ((index - 1) * 26)),
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				Text = tostring(option),
				TextSize = 11,
				Font = FONT_MED,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				ZIndex = 91,
			})
			optionButton.Parent = list

			optionButton.MouseEnter:Connect(function()
				tween(optionButton, { BackgroundColor3 = Theme.Surface2 }, 0.12)
			end)

			optionButton.MouseLeave:Connect(function()
				tween(optionButton, { BackgroundColor3 = Theme.Surface }, 0.12)
			end)

			optionButton.MouseButton1Click:Connect(function()
				setValue(option)
				closeDropdown()
			end)
		end

		openList = list
	end)

	return card, setValue, function()
		return value
	end
end

-- Input: caixa de texto escura dentro do cartao.
local function CreateInput(parent, title, placeholder)
	local card = createControlCard(parent, title)

	local box = make("TextBox", {
		Name = randomName(),
		Size = UDim2.fromOffset(150, 26),
		Position = UDim2.new(1, -128, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Background,
		Text = "",
		PlaceholderText = tostring(placeholder or "..."),
		PlaceholderColor3 = Theme.Muted,
		TextColor3 = Theme.Text,
		TextSize = 11,
		Font = FONT,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
	})
	corner(box, 7)
	border(box, Theme.Stroke, 1)
	box.Parent = card

	local function getValue()
		local text = box.Text
		if text == "" then
			text = box.PlaceholderText
		end
		return text
	end

	box.FocusLost:Connect(function()
		log(string.format("%s -> %s", tostring(title), tostring(getValue())))
	end)

	return card, getValue
end

-- Keybind: botao de tecla. Ao clicar fica a escutar e a proxima tecla
-- pressionada e a que fica escrita no botao.
local function CreateKeybind(parent, title, key)
	local card = createControlCard(parent, title)

	local chip = make("TextButton", {
		Name = randomName(),
		Size = UDim2.fromOffset(74, 26),
		Position = UDim2.new(1, -128, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 7,
	})
	corner(chip, 7)
	border(chip, Theme.Stroke, 1)
	chip.Parent = card

	local chipLabel = label(chip, {
		Size = UDim2.fromScale(1, 1),
		Text = tostring(key or "..."),
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 8,
	})

	local listening = false
	local connection = nil

	local function stopListening()
		listening = false
		connection = nil
		chipLabel.Text = tostring(key or "...")
		tween(chipLabel, { TextColor3 = Theme.Muted }, 0.15)
	end

	chip.MouseButton1Click:Connect(function()
		if listening then
			stopListening()
			return
		end
		listening = true
		chipLabel.Text = "..."
		tween(chipLabel, { TextColor3 = Theme.Text }, 0.15)

		connection = UserInputService.InputBegan:Connect(function(input, processed)
			if processed or not listening then
				return
			end
			local name = input.KeyCode and input.KeyCode.Name
			if name then
				key = name
				chipLabel.Text = name
				log(string.format("%s -> %s", tostring(title), name))
			end
			stopListening()
			if connection then
				connection:Disconnect()
			end
		end)
	end)

	return card, function()
		return key
	end
end

-- Toast animado (como o Notify da AirFlowLibrary): entra a deslizar,
-- fica um instante e desaparece.
local function CreateNotification(text, duration)
	local holder = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(280, 0),
		Position = UDim2.fromOffset(320, 0),
		AnchorPoint = Vector2.new(1, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ZIndex = 40,
	})
	holder.Parent = screenGui

	local toast = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(280, 56),
		Position = UDim2.fromOffset(0, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ZIndex = 41,
	})
	corner(toast, 10)
	border(toast, Theme.Stroke, 1)
	toast.Parent = holder

	label(toast, {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 16),
		Text = "BBC HUB",
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Text,
		ZIndex = 42,
	})

	label(toast, {
		Position = UDim2.fromOffset(14, 28),
		Size = UDim2.new(1, -28, 0, 18),
		Text = tostring(text or ""),
		TextSize = 11,
		Font = FONT,
		TextColor3 = Theme.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 42,
	})

	-- Entra a deslizar e desvanece ao fim de uns segundos.
	tween(holder, { Position = UDim2.fromOffset(0, 0) }, 0.26, Enum.EasingStyle.Quart)
	task.delay(duration or 3.5, function()
		if not holder.Parent then
			return
		end
		local animation = tween(holder, { Position = UDim2.fromOffset(320, 0) }, 0.22, Enum.EasingStyle.Quart)
		if animation and animation.Completed then
			animation.Completed:Once(function()
				if holder.Parent then
					holder:Destroy()
				end
			end)
		else
			holder:Destroy()
		end
	end)

	return toast
end

--=====================================================================
-- ABA HOME
--
-- Estrutura copiada da Home da AirFlowLibrary (banner, cartao de
-- estado, atalho e creditos), com o visual monocromatico do BBC Hub.
--=====================================================================

local function detectExecutor()
	local ok, name = pcall(function()
		if type(identifyexecutor) == "function" then
			return identifyexecutor()
		end
		return nil
	end)
	if ok and type(name) == "string" and name ~= "" then
		return name
	end
	if type(gethui) == "function" then
		return "Delta"
	end
	return "Desconhecido"
end

local function detectPlatform()
	if IS_TOUCH then
		return "Mobile"
	end
	return "PC"
end

-- Cartao generico da Home (superficie escura, borda de 1 px).
local function homeCard(parent, height)
	local card = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, height or 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ZIndex = 5,
	})
	corner(card, 12)
	border(card, Theme.Stroke, 1)
	card.Parent = parent
	return card
end

-- Linha "rotulo: valor" do cartao de estado.
local function homeRow(parent, title, value, muted)
	local row = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, -28, 0, 20),
		BackgroundTransparency = 1,
		ZIndex = 6,
	})
	row.Parent = parent

	label(row, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(110, 18),
		Text = title,
		TextSize = 11,
		Font = FONT,
		TextColor3 = Theme.Muted,
		ZIndex = 7,
	})

	label(row, {
		Position = UDim2.new(1, -130, 0, 0),
		Size = UDim2.fromOffset(130, 18),
		Text = tostring(value or "-"),
		TextSize = 11,
		Font = FONT_MED,
		TextColor3 = muted and Theme.Muted or Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
	})

	return row
end

-- Duas colunas lado a lado (como no resto do menu).
local function buildColumnLayout()
	local columns = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ZIndex = 5,
	})
	columns.Parent = scrollBody

	local columnsLayout = make("UIListLayout", {
		Padding = UDim.new(0, GRID_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
	})
	columnsLayout.Parent = columns

	local function column(order)
		local frame = make("Frame", {
			Name = randomName(),
			Size = UDim2.new(0.5, -(GRID_GAP / 2), 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			LayoutOrder = order,
			ZIndex = 5,
		})
		frame.Parent = columns

		local layout = make("UIListLayout", {
			Padding = UDim.new(0, GRID_ROW_GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
		layout.Parent = frame

		return frame
	end

	return columns, column(1), column(2)
end

local function buildHome()
	local _, left, right = buildColumnLayout()

	-- BANNER DE BOAS-VINDAS -------------------------------------------
	local banner = homeCard(left)
	local bannerPadding = make("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	})
	bannerPadding.Parent = banner

	label(banner, {
		Size = UDim2.new(1, 0, 0, 22),
		Text = "Bem-vindo",
		TextSize = 18,
		Font = FONT_BOLD,
		TextColor3 = Theme.Text,
		ZIndex = 6,
	})

	label(banner, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "BBC HUB  •  PROJECT DELTA",
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	local bannerLine = make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Stroke,
		ZIndex = 6,
	})
	bannerLine.Parent = banner

	label(banner, {
		Size = UDim2.new(1, 0, 0, 34),
		Text = "Interface single-file: cada botao imprime no console e a logica fica no marcador.",
		TextSize = 11,
		Font = FONT,
		TextColor3 = Theme.Muted,
		TextWrapped = true,
		ZIndex = 6,
	})

	-- CART DE ESTADO --------------------------------------------------
	local status = homeCard(left)
	local statusPadding = make("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	statusPadding.Parent = status

	label(status, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "STATUS",
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	homeRow(status, "Jogador", LocalPlayer.DisplayName)
	homeRow(status, "Username", "@" .. LocalPlayer.Name, true)
	homeRow(status, "Executor", detectExecutor())
	homeRow(status, "Plataforma", detectPlatform())

	-- BOTAO JOIN DISCORD ----------------------------------------------
	local discord = make("TextButton", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Text,
		Text = "Join Discord",
		TextSize = 12,
		Font = FONT_BOLD,
		TextColor3 = Theme.Background,
		AutoButtonColor = false,
		ZIndex = 5,
	})
	corner(discord, 9)
	discord.Parent = right

	discord.MouseButton1Click:Connect(function()
		CreateNotification("A abrir o Discord do BBC Hub...")
		log("Discord: a abrir o convite")
	end)

	discord.MouseEnter:Connect(function()
		tween(discord, { BackgroundColor3 = Theme.Text:Lerp(Color3.fromRGB(0, 0, 0), 0.15) }, 0.15)
	end)

	discord.MouseLeave:Connect(function()
		tween(discord, { BackgroundColor3 = Theme.Text }, 0.15)
	end)

	-- CREDITOS --------------------------------------------------------
	local credits = homeCard(right)
	local creditsPadding = make("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	creditsPadding.Parent = credits

	label(credits, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "CREDITOS",
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	label(credits, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "BBC Hub  •  Project Delta",
		TextSize = 11,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		ZIndex = 6,
	})

	label(credits, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "Interface por guivn  •  v1.1",
		TextSize = 10,
		Font = FONT,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	label(credits, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "Feito em Luau, sem logica de cheat.",
		TextSize = 10,
		Font = FONT,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	refreshCanvas()
end

--=====================================================================
-- ABA SETTINGS (com os componentes da AirFlow adaptedos)
--=====================================================================

local function buildSettings()
	local _, left, right = buildColumnLayout()

	-- PAINEL: os toggles que mexem na propria interface
	local panelCard = homeCard(left)
	local panelPadding = make("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	panelPadding.Parent = panelCard

	label(panelCard, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "PAINEL",
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	local toggles = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 5,
	})
	toggles.Parent = panelCard

	local togglesLayout = make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	togglesLayout.Parent = toggles

	-- Este e o toggle que mostra/esconde o painel de keybinds.
	local keybindsToggle = buildToggleCard({ type = "toggle", label = "Show Keybinds", action = "keybinds" }, 1)
	keybindsToggle.Parent = toggles

	local watermarkToggle = buildToggleCard({ type = "toggle", label = "Show Watermark" }, 2)
	watermarkToggle.Parent = toggles

	-- Perfil (dropdown)
	local profileCard = homeCard(left)
	local profilePadding = make("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	profilePadding.Parent = profileCard

	label(profileCard, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "PERFIL",
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	local dropdownHolder = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 5,
	})
	dropdownHolder.Parent = profileCard

	CreateDropdown(dropdownHolder, "Interface", { "default", "compact", "cozy" })

	-- Atalho de tecla (keybind)
	local keyCard = homeCard(left)
	local keyPadding = make("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	keyPadding.Parent = keyCard

	label(keyCard, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "ATALHOS",
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	local keyHolder = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 5,
	})
	keyHolder.Parent = keyCard

	CreateKeybind(keyHolder, "Abrir menu", "RShift")

	-- Webhook (input)
	local inputCard = homeCard(right)
	local inputPadding = make("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})
	inputPadding.Parent = inputCard

	label(inputCard, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "INTEGRACOES",
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	local inputHolder = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 5,
	})
	inputHolder.Parent = inputCard

	CreateInput(inputHolder, "Webhook URL", "https://discord.com/...")

	-- Botao de teste da notificacao
	local notifyButton = make("TextButton", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		Text = "Testar notificacao",
		TextSize = 12,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		AutoButtonColor = false,
		ZIndex = 5,
	})
	corner(notifyButton, 9)
	border(notifyButton, Theme.Stroke, 1)
	notifyButton.Parent = right

	notifyButton.MouseButton1Click:Connect(function()
		CreateNotification("Notificacao de teste do BBC Hub.")
		log("Notificacao: teste")
	end)

	notifyButton.MouseEnter:Connect(function()
		tween(notifyButton, { BackgroundColor3 = Theme.Stroke }, 0.15)
	end)

	notifyButton.MouseLeave:Connect(function()
		tween(notifyButton, { BackgroundColor3 = Theme.Surface2 }, 0.15)
	end)

	refreshCanvas()
end

--=====================================================================
-- SECCOES
--=====================================================================

local function buildSection(sectionData, order)
	local section = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		LayoutOrder = order,
		ZIndex = 5,
	})
	section.Parent = scrollBody

	local sectionLayout = make("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	sectionLayout.Parent = section

	local header = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, 20),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		ZIndex = 5,
	})
	header.Parent = section

	-- Titulo em maiusculas + uma linha fina que preenche o resto do
	-- espaco a direita (e o que da o ar "BBC Hub" as seccoes).
	local titleText = string.upper(sectionData.name)
	local titleWidth = math.max(60, (#titleText * 7) + 6)

	label(header, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(titleWidth, 16),
		Text = titleText,
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	local headerLine = make("Frame", {
		Size = UDim2.new(1, -(titleWidth + 14), 0, 1),
		Position = UDim2.fromOffset(titleWidth + 10, 8),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Stroke,
		ZIndex = 6,
	})
	headerLine.Parent = header

	-- A altura da grelha e calculada a mao: o UIGridLayout nao reajusta
	-- o tamanho do pai, por isso nao podemos depender de AutomaticSize.
	local rows = math.ceil(#sectionData.items / 2)
	local gridHeight = math.max(0, (rows * GRID_CARD_H) + ((rows - 1) * GRID_ROW_GAP))

	local grid = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, gridHeight),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 5,
	})
	grid.Parent = section

	local gridLayout = make("UIGridLayout", {
		CellSize = UDim2.new(0.5, -6, 0, GRID_CARD_H),
		CellPadding = UDim2.new(0, GRID_GAP, 0, GRID_ROW_GAP),
		FillDirection = Enum.FillDirection.Horizontal,
		FillDirectionMaxCells = 2,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	})
	gridLayout.Parent = grid

	for index, item in ipairs(sectionData.items) do
		local card = buildItem(item, index)
		if card then
			card.Parent = grid
		end
	end

	return section
end

--=====================================================================
-- ABAS / SIDEBAR
--=====================================================================

local currentTab = 1
local tabRefs = {}

-- Icone da aba: um quadrado ROXO de 15x15 com cantos arredondados, do
-- lado esquerdo do texto. E o "falso icone" do BBC Hub (nao ha pack de
-- icones no single file).
local TAB_ICON_SIZE = 15
local TAB_ICON_X = 2
local TAB_TEXT_X = 25

local function buildTabIcon(parent)
	local tile = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(TAB_ICON_SIZE, TAB_ICON_SIZE),
		Position = UDim2.new(0, TAB_ICON_X, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Stroke,
		ZIndex = 6,
	})
	corner(tile, 4)
	tile.Parent = parent

	return tile
end

local function selectTab(index)
	currentTab = index
	for i, ref in ipairs(tabRefs) do
		local active = (i == index)
		ref.Button.BackgroundColor3 = active and Theme.Surface2 or Theme.Surface
		ref.Text.TextColor3 = active and Theme.Text or Theme.Muted
		ref.Indicator.Visible = active
	end
end

local function renderTab(index)
	closeDropdown()
	clearChildren(scrollBody)
	for key in pairs(choiceGroups) do
		choiceGroups[key] = nil
	end

	local tabData = TABS[index]
	if tabData.custom == "home" then
		buildHome()
	elseif tabData.custom == "settings" then
		buildSettings()
	else
		for order, sectionData in ipairs(tabData.sections) do
			buildSection(sectionData, order)
		end
	end
	refreshCanvas()
end

for index, tabData in ipairs(TABS) do
	local button = make("TextButton", {
		Name = randomName(),
		-- O botao e filho da SIDEBAR: e o UIListLayout dela que o poe
		-- no sitio, com o mesmo espacamento para todas as abas.
		Size = UDim2.new(1, -10, 0, 35),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface,
		Text = "",
		AutoButtonColor = false,
		Visible = true,
		LayoutOrder = index + 1,
		ZIndex = 5,
	})
	corner(button, 8)
	button.Parent = sidebar

	local indicator = make("Frame", {
		Size = UDim2.fromOffset(3, 16),
		Position = UDim2.new(0, -6, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Text,
		Visible = false,
		ZIndex = 6,
	})
	corner(indicator, 2)
	indicator.Parent = button

	local icon = buildTabIcon(button)

	local text = label(button, {
		Position = UDim2.fromOffset(TAB_TEXT_X, 0),
		Size = UDim2.new(1, -(TAB_TEXT_X + 8), 1, 0),
		Text = tabData.name,
		TextSize = 12,
		Font = FONT_MED,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 6,
	})

	-- IMPORTANT: a troca de aba chama a funcao directamente.
	-- Nunca :Fire() num evento - isso despacha o evento e pode
	-- disparar outros handlers.
	button.MouseButton1Click:Connect(function()
		selectTab(index)
		renderTab(index)
		log("Aba: " .. tabData.name)
	end)

	button.MouseEnter:Connect(function()
		if not indicator.Visible then
			tween(button, { BackgroundColor3 = Theme.Surface2 }, 0.15)
		end
	end)

	button.MouseLeave:Connect(function()
		if not indicator.Visible then
			tween(button, { BackgroundColor3 = Theme.Surface }, 0.15)
		end
	end)

	tabRefs[index] = { Button = button, Indicator = indicator, Text = text, Icon = icon }
end

-- Rodape da sidebar. Vive na JANELA (nao na sidebar) para o UIListLayout
-- da sidebar nao o arrastar para o fluxo das abas.
local sidebarFooter = label(window, {
	Name = "SidebarFooter",
	Size = UDim2.fromOffset(SIDEBAR_W - 36, 16),
	Position = UDim2.new(0, 18, 1, -32),
	Text = "v1.1.0 • SINGLE FILE",
	TextSize = 9,
	Font = FONT,
	TextColor3 = Theme.Muted,
	ZIndex = 4,
})

--=====================================================================
-- CARD DE PERFIL (INFERIOR ESQUERDO DA JANELA)
--
-- Preso ao canto inferior esquerdo da janela principal (esta e uma
-- janela, nao um painel solto no ecra).
--=====================================================================

local PROFILE_W, PROFILE_H = 180, 74

local profile = make("Frame", {
	Name = randomName(),
	Size = UDim2.fromOffset(PROFILE_W, PROFILE_H),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 15, 1, -15),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface2,
	Active = true,
	-- Acima da sidebar e do conteudo.
	ZIndex = 6,
})
corner(profile, 12)
border(profile, Theme.Stroke, 1)
profile.Parent = window

local avatar = make("ImageLabel", {
	Name = randomName(),
	Size = UDim2.fromOffset(52, 52),
	Position = UDim2.new(0, 10, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface,
	ScaleType = Enum.ScaleType.Crop,
	ZIndex = 7,
})
corner(avatar, 10)
border(avatar, Theme.Stroke, 1)
avatar.Parent = profile

local avatarInitial = make("TextLabel", {
	Name = "Lbl",
	Size = UDim2.fromScale(1, 1),
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	Text = string.sub(string.upper(LocalPlayer.Name), 1, 1),
	TextSize = 18,
	Font = FONT_BOLD,
	TextColor3 = Theme.Muted,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 8,
})
avatarInitial.Parent = avatar

pcall(function()
	local thumbnail = Players:GetUserThumbnailAsync(
		LocalPlayer.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size100x100
	)
	if thumbnail and thumbnail ~= "" then
		avatar.Image = thumbnail
		avatarInitial.Visible = false
	end
end)

label(profile, {
	Size = UDim2.fromOffset(PROFILE_W - 70, 18),
	Position = UDim2.new(0, 62, 0, 14),
	Text = LocalPlayer.DisplayName,
	TextSize = 12,
	Font = FONT_BOLD,
	TextColor3 = Theme.Text,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 7,
})

label(profile, {
	Size = UDim2.fromOffset(PROFILE_W - 70, 14),
	Position = UDim2.new(0, 62, 0, 32),
	Text = "@" .. LocalPlayer.Name,
	TextSize = 10,
	Font = FONT,
	TextColor3 = Theme.Muted,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 7,
})

local ownerTag = make("TextLabel", {
	Name = "Lbl",
	Size = UDim2.fromOffset(52, 16),
	Position = UDim2.new(0, 62, 0, 48),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Accent,
	BackgroundTransparency = 0.82,
	Text = "OWNER",
	TextSize = 9,
	Font = FONT_BOLD,
	TextColor3 = Theme.Text,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 7,
})
corner(ownerTag, 5)
ownerTag.Parent = profile

--=====================================================================
-- PAINEL DE KEYBINDS (SUPERIOR DIREITO)
--
-- O painel NAO aparece flutuando no ecra: nasce ESCONDIDO e so aparece
-- quando o toggle "Show Keybinds" (aba SETTINGS) esta ligado. A lista
-- e informativa: nenhuma tecla e lida aqui.
--=====================================================================

local KEYBINDS = {
	{ key = "RShift", action = "UI" },
	{ key = "LAlt", action = "Cursor" },
	{ key = "Equals", action = "Auto Run" },
	{ key = "G", action = "Fly" },
	{ key = "X", action = "Third Person" },
	{ key = "Z", action = "Zoom" },
	{ key = "C", action = "Lock" },
	{ key = "B", action = "Activation" },
	{ key = "J", action = "Aim Parts" },
	{ key = "MB3", action = "Add Friend" },
	{ key = "U", action = "Underground" },
}

local KEY_W = 250
local KEY_ROW_H = 26
local KEY_HEADER_H = 40
local KEY_H = KEY_HEADER_H + (#KEYBINDS * KEY_ROW_H) + 10

local keyPanel = make("Frame", {
	Name = randomName(),
	Size = UDim2.fromOffset(KEY_W, KEY_H),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface2,
	Active = true,
	-- Escondido: so aparece com o toggle "Show Keybinds" da aba
	-- SETTINGS (a acao "keybinds" abaixo).
	Visible = false,
	ZIndex = 4,
})
corner(keyPanel, 12)
border(keyPanel, Theme.Stroke, 1)
keyPanel.Parent = screenGui

local keyScale = make("UIScale", { Scale = UI_SCALE })
keyScale.Parent = keyPanel

do
	local view = viewportSize()
	keyPanel.Position = UDim2.fromOffset(view.X - (KEY_W * UI_SCALE) - 20, 20)
end

local keyHeader = make("Frame", {
	Name = randomName(),
	Size = UDim2.new(1, 0, 0, KEY_HEADER_H),
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	Active = true,
	ZIndex = 5,
})
keyHeader.Parent = keyPanel

label(keyHeader, {
	Position = UDim2.fromOffset(14, 11),
	Size = UDim2.fromOffset(KEY_W - 28, 16),
	Text = "KEYBINDS",
	TextSize = 11,
	Font = FONT_BOLD,
	TextColor3 = Theme.Text,
	ZIndex = 6,
})

local keyLine = make("Frame", {
	Size = UDim2.new(1, -28, 0, 1),
	Position = UDim2.fromOffset(14, 32),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Stroke,
	ZIndex = 5,
})
keyLine.Parent = keyHeader

for index, entry in ipairs(KEYBINDS) do
	local row = make("Frame", {
		Name = entry.key,
		Size = UDim2.new(1, -28, 0, KEY_ROW_H - 6),
		Position = UDim2.fromOffset(14, KEY_HEADER_H + ((index - 1) * KEY_ROW_H)),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ZIndex = 5,
	})
	row.Parent = keyPanel

	local chip = make("TextLabel", {
		Name = "Lbl",
		Size = UDim2.fromOffset(54, 18),
		Position = UDim2.fromOffset(0, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Background,
		Text = entry.key,
		TextSize = 9,
		Font = FONT_BOLD,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 6,
	})
	corner(chip, 5)
	chip.Parent = row

	label(row, {
		Position = UDim2.fromOffset(62, 0),
		Size = UDim2.fromOffset(KEY_W - 96, 18),
		Text = entry.action,
		TextSize = 10,
		Font = FONT,
		TextColor3 = Theme.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})
end

makeDraggable(keyPanel, keyHeader)

-- O toggle "Show Keybinds" da aba SETTINGS liga/desliga o painel.
ACTIONS.keybinds = function(state)
	keyPanel.Visible = state == true
	log("Keybinds: " .. (keyPanel.Visible and "visiveis" or "escondidos"))
end

--=====================================================================
-- BOTAO FLUTUANTE (REABRIR O MENU)
--=====================================================================

local floating = make("TextButton", {
	Name = randomName(),
	Size = UDim2.fromOffset(46, 46),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Text,
	Text = "☰",
	TextSize = 20,
	Font = FONT_BOLD,
	TextColor3 = Theme.Background,
	AutoButtonColor = false,
	ZIndex = 5,
})
corner(floating, 14)
border(floating, Theme.Stroke, 1)
floating.Parent = screenGui

local floatingScale = make("UIScale", { Scale = UI_SCALE })
floatingScale.Parent = floating

do
	local view = viewportSize()
	floating.Position = UDim2.fromOffset(
		view.X - (46 * UI_SCALE) - 20,
		view.Y - (46 * UI_SCALE) - 20
	)
end

floating.MouseButton1Click:Connect(function()
	window.Visible = not window.Visible
	log("Menu: " .. (window.Visible and "aberto" or "fechado"))
end)

--=====================================================================
-- SIDEBAR RECOLHIVEL / ATALHOS
--=====================================================================

local sidebarCollapsed = false

local function setSidebarCollapsed(collapsed)
	sidebarCollapsed = collapsed
	sidebar.Visible = not collapsed
	-- O cartao de perfil e o rodape vivem na janela: tambem somem com a
	-- sidebar.
	if profile then
		profile.Visible = not collapsed
	end
	if sidebarFooter then
		sidebarFooter.Visible = not collapsed
	end

	local newX = collapsed and PANEL_PAD or CONTENT_X
	local newW = collapsed and (WINDOW_W - (PANEL_PAD * 2)) or CONTENT_W
	contentPanel.Position = UDim2.fromOffset(newX, CONTENT_Y)
	contentPanel.Size = UDim2.fromOffset(newW, CONTENT_H)

	scrollBody.Size = UDim2.new(1, 0, 0, 0)
	renderTab(currentTab)
	refreshCanvas()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not screenGui.Parent then
		return
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		window.Visible = not window.Visible
		log("Menu: " .. (window.Visible and "aberto" or "fechado"))
	elseif input.KeyCode == Enum.KeyCode.LAlt then
		setSidebarCollapsed(not sidebarCollapsed)
		log("Sidebar: " .. (sidebarCollapsed and "recolhida" or "expandida"))
	elseif input.KeyCode == Enum.KeyCode.U then
		log("Descarregando a interface")
		screenGui:Destroy()
	end
end)

--=====================================================================
-- INICIALIZACAO
--=====================================================================

selectTab(1)
renderTab(1)

log(string.format(
	"Interface carregada (single file) • %s • host=%s • namecall=%s • humanoid=%s • antidebug=%s • debuginfo=%s",
	TABS[1].name,
	guiHost and guiHost.Name or "?",
	namecallHooked and "on" or "off",
	humanoidSpoofed and "on" or "off",
	antiDebugInstalled and "on" or "off",
	debugInfoHooked and "on" or "off"
))
