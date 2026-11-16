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

--=====================================================================
-- LAYOUT
--=====================================================================

local WINDOW_W, WINDOW_H = 900, 620
local SIDEBAR_W = 210
local TOPBAR_H = 54
local PANEL_PAD = 12
local GRID_CARD_H = 44
local GRID_GAP = 12
local GRID_ROW_GAP = 10
local TAB_H = 35

local CONTENT_X = SIDEBAR_W + PANEL_PAD
local CONTENT_Y = TOPBAR_H + PANEL_PAD
local CONTENT_W = WINDOW_W - CONTENT_X - PANEL_PAD
local CONTENT_H = WINDOW_H - CONTENT_Y - PANEL_PAD

-- A escala da interface segue o ecra (tecnica do AirFlowLibrary):
--   1. escala base: 0.65 no telemóvel (Delta), 1 no PC;
--   2. no PC, fator adaptativo em passos de 0.05 (0.85 a 1.75);
--   3. "fit to screen": a escala nunca deixa a janela sair do ecra
--      (piso de 0.45, para nunca ficar ilegivel).
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

	local wanted = 1
	if IS_TOUCH then
		wanted = 0.65
	else
		local factor = math.min(view.X / 1920, view.Y / 1020)
		if factor > 0.9 and factor < 1.15 then
			factor = 1
		end
		wanted = math.clamp(math.floor(factor * 20 + 0.5) / 20, 0.85, 1.75)
	end

	-- A janela tem de caber no ecra (com uma margem de 24 px).
	local fit = math.min(
		(view.X - 24) / WINDOW_W,
		(view.Y - 24) / WINDOW_H
	)

	return math.max(math.min(wanted, fit), 0.45)
end

local UI_SCALE = computeUIScale()

--=====================================================================
-- DESIGN SYSTEM (tokens)
--
-- Todas as medidas do menu sao controladas aqui: padding, cantos,
-- bordas, tipografia e as cores de hover. Nao ha Offset solto pelo
-- codigo.
--=====================================================================

local Design = {
	Padding = 10,                       -- UIPadding de todos os contentores
	Corner = 6,                         -- cantos dos botoes/cards
	WindowCorner = 10,                  -- cantos da janela principal
	StrokeThickness = 1,                -- bordas de 1 px
	SectionTitleSize = 12,              -- titulos de secao (GothamBold)
	TextSize = 13,                      -- texto dos botoes (GothamMedium)
	Hover = Color3.fromRGB(35, 35, 35), -- cor de hover dos botoes
	HoverOut = Color3.fromRGB(25, 25, 25),
}

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
-- que o Delta nao expoe).
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
	print("[NEXUS HUB] " .. tostring(message))
end

-- Animacoes: TweenService com EasingStyle.Quart (o mesmo estilo do
-- AirFlowLibrary).
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

-- Arraste com efeito premium (drag ghost).
--
-- Enquanto a janela e arrastada fica um "fantasma" vermelho, do
-- tamanho dela e na posicao onde estava. A janela segue o rato/dedo e,
-- ao largar, o fantasma desaparece. (Tecnica do AirFlowLibrary: o
-- fantasma nasce quando o ponteiro passa do limiar de 3 px.)
local function makeDraggable(frame, handle)
	local dragging = false
	local moved = false
	local pressPoint = Vector2.zero
	local startPosition = UDim2.new(0, 0, 0, 0)
	local ghost = nil

	local function isPress(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end

	local function isMove(input)
		return input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
	end

	local function makeGhost()
		if ghost then
			return
		end
		ghost = make("Frame", {
			Name = randomName(),
			Size = UDim2.fromOffset(frame.AbsoluteSize.X, frame.AbsoluteSize.Y),
			Position = UDim2.fromOffset(frame.AbsolutePosition.X, frame.AbsolutePosition.Y),
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			BackgroundTransparency = 0.5,
			-- O fantasma fica ATRAS da janela.
			ZIndex = -1,
		})
		corner(ghost, Design.WindowCorner)
		ghost.Parent = frame.Parent
	end

	local function dropGhost()
		if ghost then
			if ghost.Parent then
				ghost:Destroy()
			end
			ghost = nil
		end
	end

	handle.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		dragging = true
		moved = false
		pressPoint = input.Position
		startPosition = frame.Position
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging or not isMove(input) then
			return
		end
		if not moved then
			if (input.Position - pressPoint).Magnitude <= 3 then
				return
			end
			moved = true
			makeGhost()
		end
		-- O delta do ecra e dividido pela escala (componente a
		-- componente: o Roblox nao divide um Vector2 por um numero). A
		-- posicao da janela e em unidades do pai, nao em pixels de ecra.
		local deltaX = (input.Position.X - pressPoint.X) / UI_SCALE
		local deltaY = (input.Position.Y - pressPoint.Y) / UI_SCALE
		frame.Position = UDim2.fromOffset(
			startPosition.X.Offset + deltaX,
			startPosition.Y.Offset + deltaY
		)
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not dragging then
			return
		end
		dragging = false
		moved = false
		dropGhost()
	end)
end

--=====================================================================
-- NEXUSUI - BIBLIOTECA DE INTERFACE (single file)
--
-- Funcoes:
--   Nexus.CreateWindow(title)      janela + topbar + sidebar + perfil
--   Nexus.CreateTab(name)          aba da sidebar (com a sua pagina)
--   Nexus.CreateSection(parent, t)  seccao com titulo e linha de 1 px
--   Nexus.CreateToggle(parent, ...)toggle com accordion (☰)
--   Nexus.CreateSlider(parent, ...)barra arrastavel
--   Nexus.CreateDropdown(parent, ..)lista suspensa
--   Nexus.CreateInput(parent, ...)  caixa de texto escura
--   Nexus.CreateKeybind(parent, ...)botao que captura uma tecla
--   Nexus.CreateNotification(text)  toast animado
--
-- Duas licoes vindas do AirFlowLibrary (so a tecnica, nao o codigo):
--   1. o CanvasSize segue o conteudo DIVIDIDO pela escala (o
--      AbsoluteContentSize esta em pixels ja escalados; sem dividir, no
--      mobile o scroll fica curto);
--   2. a escala da interface e "fit to screen": a escala base (0.65 no
--      telemóvel) nunca pode fazer a janela sair do ecra.
--=====================================================================

local Nexus = {}
local NexusWindow = nil
local NexusTabs = {}
local currentTab = nil

-- Overlay de cada pagina: os popups (dropdowns, accordions) vivem aqui
-- para nao serem cortados pelas margens da pagina.
local function makeOverlay(page)
	local overlay = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 30,
	})
	overlay.Parent = page
	return overlay
end

-- ---------------------------------------------------------------------
-- Nexus.CreateWindow(title)
-- ---------------------------------------------------------------------
function Nexus.CreateWindow(title)
	local gui = make("ScreenGui", {
		Name = randomGuiName(),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
	})
	gui.Parent = guiHost

	local frame = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(WINDOW_W, WINDOW_H),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 2,
	})
	corner(frame, Design.WindowCorner)
	border(frame, Theme.Stroke, 1)
	frame.Parent = gui

	local scale = make("UIScale", { Scale = UI_SCALE })
	scale.Parent = frame

	-- Parede hexagonal: dentro da MainFrame, por baixo de tudo.
	local hex = make("ImageLabel", {
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
	corner(hex, Design.WindowCorner)
	hex.Parent = frame

	-- ---------------------------------------------------------------
	-- TOPBAR
	-- ---------------------------------------------------------------
	local topbar = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, TOPBAR_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface,
		Active = true,
		ZIndex = 3,
	})
	corner(topbar, Design.WindowCorner)
	topbar.Parent = frame

	-- Patch: tapa os cantos de baixo da barra.
	local patch = make("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromOffset(0, TOPBAR_H - 14),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface,
		ZIndex = 3,
	})
	patch.Parent = topbar

	-- Linha subtil em baixo da barra.
	local line = make("Frame", {
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.new(0, 12, 1, -1),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Stroke,
		ZIndex = 4,
	})
	line.Parent = topbar

	local logo = make("Frame", {
		Size = UDim2.fromOffset(34, 34),
		Position = UDim2.fromOffset(16, 10),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Text,
		ZIndex = 4,
	})
	corner(logo, Design.Corner)
	logo.Parent = topbar

	label(logo, {
		Size = UDim2.fromScale(1, 1),
		Text = "N",
		TextSize = 18,
		Font = FONT_BOLD,
		TextColor3 = Theme.Background,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 5,
	})

	label(topbar, {
		Position = UDim2.fromOffset(62, 11),
		Size = UDim2.fromOffset(240, 20),
		Text = tostring(title or "NEXUS"),
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

	-- Botao central (perfil activo) - so UI.
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
	corner(profileButton, Design.Corner)
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

	-- Botoes de icones a direita (desenhados com formas).
	local function iconButton(xOffset, kind)
		local button = make("TextButton", {
			Name = randomName(),
			Size = UDim2.fromOffset(28, 28),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(1, xOffset, 0.5, 0),
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Surface2,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 4,
		})
		corner(button, Design.Corner)
		border(button, Theme.Stroke, 1)
		button.Parent = topbar

		if kind == "search" then
			local lens = make("Frame", {
				Size = UDim2.fromOffset(12, 12),
				Position = UDim2.fromOffset(6, 6),
				BorderSizePixel = 0,
				BackgroundColor3 = Theme.Muted,
				ZIndex = 5,
			})
			corner(lens, Design.Corner)
			local hole = make("Frame", {
				Size = UDim2.fromOffset(6, 6),
				Position = UDim2.fromOffset(3, 3),
				BorderSizePixel = 0,
				BackgroundColor3 = Theme.Surface2,
				ZIndex = 6,
			})
			corner(hole, Design.Corner)
			hole.Parent = lens
			lens.Parent = button

			local handle = make("Frame", {
				Size = UDim2.fromOffset(6, 2),
				Position = UDim2.fromOffset(15, 17),
				Rotation = 45,
				BorderSizePixel = 0,
				BackgroundColor3 = Theme.Muted,
				ZIndex = 5,
			})
			corner(handle, Design.Corner)
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
			local gear = make("Frame", {
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.fromOffset(7, 7),
				BorderSizePixel = 0,
				BackgroundColor3 = Theme.Muted,
				ZIndex = 5,
			})
			corner(gear, Design.Corner)
			local hole = make("Frame", {
				Size = UDim2.fromOffset(5, 5),
				Position = UDim2.fromOffset(4.5, 4.5),
				BorderSizePixel = 0,
				BackgroundColor3 = Theme.Surface2,
				ZIndex = 6,
			})
			corner(hole, Design.Corner)
			hole.Parent = gear
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
				corner(tooth, Design.Corner)
				tooth.Parent = button
			end
		end

		button.MouseEnter:Connect(function()
			tween(button, { BackgroundColor3 = Design.Hover }, 0.15)
		end)
		button.MouseLeave:Connect(function()
			tween(button, { BackgroundColor3 = Theme.Surface2 }, 0.15)
		end)
		button.MouseButton1Click:Connect(function()
			log("Botao: " .. kind)
		end)
	end

	-- Os icones estao centrados na altura da barra (AnchorPoint 0,0.5)
	-- para nao ficarem cortados em cima.
	iconButton(-116, "search")
	iconButton(-86, "lua")
	iconButton(-56, "settings")

	-- Botao X: fecha a janela (o botao flutuante traz-la de volta).
	local closeButton = make("TextButton", {
		Name = randomName(),
		Size = UDim2.fromOffset(28, 28),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		Text = "✕",
		TextSize = 13,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		AutoButtonColor = false,
		ZIndex = 4,
	})
	corner(closeButton, Design.Corner)
	border(closeButton, Theme.Stroke, 1)
	closeButton.Parent = topbar

	closeButton.MouseEnter:Connect(function()
		tween(closeButton, { BackgroundColor3 = Design.Hover, TextColor3 = Theme.Text }, 0.15)
	end)
	closeButton.MouseLeave:Connect(function()
		tween(closeButton, { BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Muted }, 0.15)
	end)
	closeButton.MouseButton1Click:Connect(function()
		log("Interface fechada")
		frame.Visible = false
		if NexusWindow and NexusWindow.Floating then
			NexusWindow.Floating.Visible = true
		end
	end)

	makeDraggable(frame, topbar)

	-- ---------------------------------------------------------------
	-- SIDEBAR
	-- ---------------------------------------------------------------
	local sidebar = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(SIDEBAR_W, WINDOW_H - TOPBAR_H),
		Position = UDim2.fromOffset(0, TOPBAR_H),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 3,
	})
	sidebar.Parent = frame

	-- Linha vertical entre a sidebar e o conteudo.
	local divider = make("Frame", {
		Size = UDim2.new(0, 1, 1, -28),
		Position = UDim2.fromOffset(SIDEBAR_W - 1, TOPBAR_H + 14),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Stroke,
		ZIndex = 4,
	})
	divider.Parent = frame

	local sidebarPadding = make("UIPadding", {
		PaddingLeft = UDim.new(0, Design.Padding),
		PaddingRight = UDim.new(0, Design.Padding),
		PaddingTop = UDim.new(0, Design.Padding),
		PaddingBottom = UDim.new(0, Design.Padding),
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

	-- ---------------------------------------------------------------
	-- CONTEUDO
	-- ---------------------------------------------------------------
	local content = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(CONTENT_W, CONTENT_H),
		Position = UDim2.fromOffset(CONTENT_X, CONTENT_Y),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 3,
	})
	corner(content, Design.WindowCorner)
	border(content, Theme.Stroke, 1)
	content.Parent = frame

	-- ---------------------------------------------------------------
	-- CARD DE PERFIL (canto inferior esquerdo da janela)
	-- ---------------------------------------------------------------
	local profile = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(180, 74),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 15, 1, -15),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		Active = true,
		ZIndex = 6,
	})
	corner(profile, Design.WindowCorner)
	border(profile, Theme.Stroke, 1)
	profile.Parent = frame

	local avatar = make("ImageLabel", {
		Name = randomName(),
		Size = UDim2.fromOffset(44, 44),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 7,
	})
	corner(avatar, Design.Corner)
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
		Size = UDim2.fromOffset(110, 18),
		Position = UDim2.new(0, 62, 0, 14),
		Text = LocalPlayer.DisplayName,
		TextSize = 12,
		Font = FONT_BOLD,
		TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
	})

	label(profile, {
		Size = UDim2.fromOffset(110, 14),
		Position = UDim2.new(0, 62, 0, 32),
		Text = "@" .. LocalPlayer.Name,
		TextSize = 10,
		Font = FONT,
		TextColor3 = Theme.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
	})

	-- A unica cor forte do menu.
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
	corner(ownerTag, Design.Corner)
	ownerTag.Parent = profile

	local footer = label(frame, {
		Name = "SidebarFooter",
		Size = UDim2.fromOffset(SIDEBAR_W - 36, 16),
		Position = UDim2.new(0, 18, 1, -32),
		Text = "NEXUS v1.0  •  SINGLE FILE",
		TextSize = 9,
		Font = FONT,
		TextColor3 = Theme.Muted,
		ZIndex = 4,
	})

	-- Centra a janela no ecra (a escala ja esta aplicada).
	local function center()
		local view = viewportSize()
		frame.Position = UDim2.fromOffset(
			math.max(0, (view.X - (WINDOW_W * UI_SCALE)) / 2),
			math.max(0, (view.Y - (WINDOW_H * UI_SCALE)) / 2) - 20
		)
	end
	center()

	NexusWindow = {
		Gui = gui,
		Frame = frame,
		Topbar = topbar,
		Sidebar = sidebar,
		Content = content,
		Profile = profile,
		Footer = footer,
		Divider = divider,
		Scale = scale,
		Tabs = NexusTabs,
		Center = center,
	}

	return NexusWindow
end

-- ---------------------------------------------------------------------
-- Nexus.CreateTab(name)
--
-- Cada aba tem a sua pagina com o seu proprio ScrollingFrame: e o que
-- garante que o scroll funciona em todas as abas.
-- ---------------------------------------------------------------------
function Nexus.CreateTab(name)
	local page = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 4,
	})
	page.Parent = NexusWindow.Content

	local scroll = make("ScrollingFrame", {
		Name = randomName(),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Muted,
		ScrollBarImageTransparency = 0.45,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.fromOffset(CONTENT_W, CONTENT_H),
		ZIndex = 5,
	})
	scroll.Parent = page

	-- Padding do ScrollingFrame (nada de posicoes fixas no conteudo).
	local padding = make("UIPadding", {
		PaddingLeft = UDim.new(0, Design.Padding),
		PaddingRight = UDim.new(0, Design.Padding),
		PaddingTop = UDim.new(0, Design.Padding),
		PaddingBottom = UDim.new(0, Design.Padding),
	})
	padding.Parent = scroll

	local body = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ZIndex = 5,
	})
	body.Parent = scroll

	local bodyLayout = make("UIListLayout", {
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	bodyLayout.Parent = body

	-- O canvas segue o conteudo: o AbsoluteContentSize ja vem escalado
	-- (e o CanvasSize nao), por isso dividimos pela escala.
	local function refreshCanvas()
		local height = (bodyLayout.AbsoluteContentSize.Y / UI_SCALE) + 4
		scroll.CanvasSize = UDim2.fromOffset(CONTENT_W, math.max(height, CONTENT_H))
	end
	bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

	local overlay = makeOverlay(page)

	-- Botao na sidebar.
	local button = make("TextButton", {
		Name = randomName(),
		Size = UDim2.new(1, -10, 0, TAB_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface,
		Text = "",
		AutoButtonColor = false,
		Visible = true,
		LayoutOrder = #NexusTabs + 2,
		ZIndex = 5,
	})
	corner(button, Design.Corner)
	button.Parent = NexusWindow.Sidebar

	local icon = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(15, 15),
		Position = UDim2.new(0, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Stroke,
		ZIndex = 6,
	})
	corner(icon, Design.Corner)
	icon.Parent = button

	local indicator = make("Frame", {
		Size = UDim2.fromOffset(3, 16),
		Position = UDim2.new(0, -6, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Text,
		Visible = false,
		ZIndex = 6,
	})
	corner(indicator, Design.Corner)
	indicator.Parent = button

	local text = label(button, {
		Position = UDim2.fromOffset(25, 0),
		Size = UDim2.new(1, -33, 1, 0),
		Text = tostring(name or ""),
		TextSize = 12,
		Font = FONT_MED,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 6,
	})

	local tab = {
		Name = name,
		Page = page,
		Scroll = scroll,
		Body = body,
		Overlay = overlay,
		Button = button,
		Icon = icon,
		Indicator = indicator,
		Text = text,
		RefreshCanvas = refreshCanvas,
	}

	function tab:Show()
		for _, other in ipairs(NexusTabs) do
			other.Page.Visible = other == self
			other.Button.BackgroundColor3 = other == self and Theme.Surface2 or Theme.Surface
			other.Text.TextColor3 = other == self and Theme.Text or Theme.Muted
			other.Indicator.Visible = other == self
		end
		currentTab = self
		Nexus.RefreshCanvases()
	end

	button.MouseButton1Click:Connect(function()
		tab:Show()
		log("Aba: " .. tostring(name))
	end)

	button.MouseEnter:Connect(function()
		if not indicator.Visible then
			tween(button, { BackgroundColor3 = Design.Hover }, 0.15)
		end
	end)

	button.MouseLeave:Connect(function()
		if not indicator.Visible then
			tween(button, { BackgroundColor3 = Theme.Surface }, 0.15)
		end
	end)

	table.insert(NexusTabs, tab)
	return tab
end

-- Recalcula o canvas de todas as abas (quando o conteudo muda).
function Nexus.RefreshCanvases()
	for _, tab in ipairs(NexusTabs) do
		task.defer(function()
			if tab.Page.Visible then
				tab.RefreshCanvas()
			end
		end)
	end
end

-- Hover suave de um card (25,25,25 -> 35,35,35).
local function hoverCard(card)
	card.MouseEnter:Connect(function()
		tween(card, { BackgroundColor3 = Design.Hover }, 0.15)
	end)
	card.MouseLeave:Connect(function()
		tween(card, { BackgroundColor3 = Theme.Surface2 }, 0.15)
	end)
end

-- ---------------------------------------------------------------------
-- Nexus.CreateSection(parent, title)
--
-- Seccao com o titulo em maiusculas e uma linha de 1 px a direita. Os
-- controlos vao para uma grelha de duas colunas (UIGridLayout).
-- ---------------------------------------------------------------------
function Nexus.CreateSection(parent, title)
	local section = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		LayoutOrder = #parent:GetChildren(),
		ZIndex = 5,
	})
	section.Parent = parent

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

	local titleText = string.upper(tostring(title or ""))
	local titleWidth = math.max(60, (#titleText * 8) + 8)

	label(header, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(titleWidth, 16),
		Text = titleText,
		TextSize = Design.SectionTitleSize,
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

	-- Grelha de duas colunas.
	local grid = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
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

	local api = {
		Frame = section,
		Grid = grid,
		Order = 0,
	}

	-- API: os controlos sao colocados na grelha por ordem de chamada.
	function api:Add(control)
		self.Order += 1
		control.LayoutOrder = self.Order
		control.Parent = grid
		return control
	end

	return api
end

-- ---------------------------------------------------------------------
-- Nexus.CreateSlider(parent, title, min, max, default)
--
-- Barra arrastavel. A matematica e a do AirFlow: o valor e uma fracao
-- entre o minimo e o maximo, e o preenchimento/knob andam para essa
-- fracao.
-- ---------------------------------------------------------------------
function Nexus.CreateSlider(parent, title, min, max, default)
	min = min or 0
	max = max or 100
	default = default or min

	local card = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ZIndex = 5,
	})
	corner(card, Design.Corner)
	border(card, Theme.Stroke, 1)
	hoverCard(card)

	label(card, {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -80, 0, 16),
		Text = tostring(title or ""),
		TextSize = Design.TextSize,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		ZIndex = 6,
	})

	local valueLabel = label(card, {
		Position = UDim2.new(1, -62, 0, 8),
		Size = UDim2.fromOffset(50, 16),
		Text = tostring(default),
		TextSize = Design.TextSize,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 6,
	})

	local track = make("TextButton", {
		Name = randomName(),
		Size = UDim2.new(1, -24, 0, 6),
		Position = UDim2.fromOffset(12, 28),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Stroke,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
	})
	corner(track, Design.Corner)
	track.Parent = card

	local fill = make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Muted,
		ZIndex = 7,
	})
	corner(fill, Design.Corner)
	fill.Parent = track

	local knob = make("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromScale(0, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Text,
		ZIndex = 8,
	})
	corner(knob, Design.Corner)
	border(knob, Theme.Background, 1)
	knob.Parent = track

	local value = math.clamp(default, min, max)
	local dragging = false

	local function fraction()
		if (max - min) == 0 then
			return 0
		end
		return (value - min) / (max - min)
	end

	local function moveTo(frac, duration)
		tween(fill, { Size = UDim2.new(frac, 0, 1, 0) }, duration or 0.12)
		tween(knob, { Position = UDim2.new(frac, 0, 0.5, 0) }, duration or 0.12)
	end

	local function render()
		valueLabel.Text = tostring(math.floor(value + 0.5))
		moveTo(fraction(), 0)
	end

	-- A fracao e calculada sobre o tamanho ABSOLUTO do trilho: as
	-- coordenadas do ecra e o trilho estao na mesma escala, por isso a
	-- razao e correta em qualquer UIScale.
	local function updateFromX(x)
		local width = math.max(track.AbsoluteSize.X, 1)
		local frac = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
		value = min + (frac * (max - min))
		render()
	end

	track.InputBegan:Connect(function(input)
		local mouse = input.UserInputType == Enum.UserInputType.MouseButton1
		local touch = input.UserInputType == Enum.UserInputType.Touch
		if mouse or touch then
			dragging = true
			tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.15, Enum.EasingStyle.Back)
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		local moved = input.UserInputType == Enum.UserInputType.MouseMovement
		local dragged = input.UserInputType == Enum.UserInputType.Touch
		if moved or dragged then
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not dragging then
			return
		end
		dragging = false
		tween(knob, { Size = UDim2.fromOffset(12, 12) }, 0.2)
		log(string.format("%s: %d", tostring(title), math.floor(value + 0.5)))
	end)

	render()

	local api = {
		Frame = card,
		GetValue = function()
			return value
		end,
		SetValue = function(newValue)
			value = math.clamp(newValue, min, max)
			render()
		end,
	}
	return api
end

-- ---------------------------------------------------------------------
-- Nexus.CreateDropdown(parent, title, options)
-- ---------------------------------------------------------------------
function Nexus.CreateDropdown(parent, title, options)
	options = options or {}

	local card = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ZIndex = 5,
	})
	corner(card, Design.Corner)
	border(card, Theme.Stroke, 1)
	hoverCard(card)

	label(card, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -140, 1, 0),
		Text = tostring(title or ""),
		TextSize = Design.TextSize,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	local value = options[1] or ""
	local valueButton = make("TextButton", {
		Name = randomName(),
		Size = UDim2.fromOffset(110, 26),
		Position = UDim2.new(1, -128, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface,
		Text = tostring(value),
		TextSize = Design.TextSize,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		AutoButtonColor = false,
		ZIndex = 7,
	})
	corner(valueButton, Design.Corner)
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

	local function openList()
		local list = make("Frame", {
			Name = randomName(),
			Size = UDim2.fromOffset(120, (#options * 26) + 8),
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Surface,
			ClipsDescendants = true,
			ZIndex = 90,
		})
		corner(list, Design.Corner)
		border(list, Theme.Stroke, 1)
		list.Parent = Nexus.CurrentOverlay()

		local origin = valueButton.AbsolutePosition - Nexus.CurrentPage().AbsolutePosition
		local x = (origin.X + valueButton.AbsoluteSize.X - 120) / UI_SCALE
		local below = (origin.Y + valueButton.AbsoluteSize.Y) / UI_SCALE + 4
		local above = (origin.Y - (#options * 26) - 8) / UI_SCALE
		local room = Nexus.CurrentPage().AbsoluteSize.Y / UI_SCALE
		if below + (#options * 26) > room and above > 8 then
			list.Position = UDim2.fromOffset(x, above)
		else
			list.Position = UDim2.fromOffset(x, below)
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
				Nexus.ClosePopups()
			end)
		end

		Nexus.SetPopup(list)
	end

	valueButton.MouseButton1Click:Connect(function()
		if Nexus.GetPopup() then
			Nexus.ClosePopups()
			return
		end
		openList()
	end)

	return {
		Frame = card,
		GetValue = function()
			return value
		end,
		SetValue = setValue,
	}
end

-- ---------------------------------------------------------------------
-- Nexus.CreateInput(parent, title, placeholder)
-- ---------------------------------------------------------------------
function Nexus.CreateInput(parent, title, placeholder)
	local card = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ZIndex = 5,
	})
	corner(card, Design.Corner)
	border(card, Theme.Stroke, 1)
	hoverCard(card)

	label(card, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.fromOffset(120, 1, 0),
		Text = tostring(title or ""),
		TextSize = Design.TextSize,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	local box = make("TextBox", {
		Name = randomName(),
		Size = UDim2.fromOffset(140, 26),
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
	corner(box, Design.Corner)
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

	return {
		Frame = card,
		GetValue = getValue,
		SetValue = function(text)
			box.Text = tostring(text)
		end,
	}
end

-- ---------------------------------------------------------------------
-- Nexus.CreateKeybind(parent, title, defaultKey)
-- ---------------------------------------------------------------------
function Nexus.CreateKeybind(parent, title, defaultKey)
	local card = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ZIndex = 5,
	})
	corner(card, Design.Corner)
	border(card, Theme.Stroke, 1)
	hoverCard(card)

	label(card, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -140, 1, 0),
		Text = tostring(title or ""),
		TextSize = Design.TextSize,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	local key = defaultKey or "..."
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
	corner(chip, Design.Corner)
	border(chip, Theme.Stroke, 1)
	chip.Parent = card

	local chipLabel = label(chip, {
		Size = UDim2.fromScale(1, 1),
		Text = tostring(key),
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 8,
	})

	local listening = false

	chip.MouseButton1Click:Connect(function()
		if listening then
			listening = false
			chipLabel.Text = tostring(key)
			return
		end
		listening = true
		chipLabel.Text = "..."
		tween(chipLabel, { TextColor3 = Theme.Text }, 0.15)

		local connection
		connection = UserInputService.InputBegan:Connect(function(input, processed)
			if processed or not listening then
				return
			end
			local name = input.KeyCode and input.KeyCode.Name
			if name then
				key = name
				chipLabel.Text = name
				log(string.format("%s -> %s", tostring(title), tostring(name)))
			end
			listening = false
			tween(chipLabel, { TextColor3 = Theme.Muted }, 0.15)
			connection:Disconnect()
		end)
	end)

	return {
		Frame = card,
		GetValue = function()
			return key
		end,
	}
end

-- ---------------------------------------------------------------------
-- Nexus.CreateToggle(parent, title, default, subElements)
--
-- Cartao com o icone "☰" (que abre o accordion), o texto e o switch.
-- subElements = { {Type="Slider", ...}, {Type="Dropdown", ...} }
-- ---------------------------------------------------------------------
function Nexus.CreateToggle(parent, title, default, subElements, onChange)
	subElements = subElements or {}

	local card = make("TextButton", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 5,
	})
	corner(card, Design.Corner)
	border(card, Theme.Stroke, 1)

	local burger = make("TextButton", {
		Name = randomName(),
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(0, 6, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Text = "☰",
		TextSize = 15,
		Font = FONT_BOLD,
		TextColor3 = (#subElements > 0) and Theme.Text or Theme.Muted,
		AutoButtonColor = false,
		ZIndex = 6,
	})
	burger.Parent = card

	label(card, {
		Position = UDim2.fromOffset(36, 0),
		Size = UDim2.new(1, -92, 1, 0),
		Text = tostring(title or ""),
		TextSize = Design.TextSize,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})

	-- Switch (bolinha branca).
	local state = default == true
	local holder = make("Frame", {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -48, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = state and Theme.Text or Theme.Stroke,
		ZIndex = 6,
	})
	corner(holder, Design.Corner)
	holder.Parent = card

	local knob = make("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(state and 1 or 0, state and -7 or 7, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Text,
		ZIndex = 7,
	})
	corner(knob, Design.Corner)
	border(knob, Theme.Background, 1)
	knob.Parent = holder

	local function applySwitch()
		-- A bolinha desliza com TweenService (Quart).
		tween(holder, { BackgroundColor3 = state and Theme.Text or Theme.Stroke }, 0.18, Enum.EasingStyle.Quart)
		tween(knob, { Position = UDim2.new(state and 1 or 0, state and -7 or 7, 0.5, 0) }, 0.18, Enum.EasingStyle.Quart)
	end

	card.MouseButton1Click:Connect(function()
		state = not state
		applySwitch()
		log(string.format("%s -> %s", tostring(title), state and "ON" or "OFF"))
		if type(onChange) == "function" then
			onChange(state)
		end
	end)

	card.MouseEnter:Connect(function()
		tween(card, { BackgroundColor3 = Design.Hover }, 0.15)
	end)
	card.MouseLeave:Connect(function()
		tween(card, { BackgroundColor3 = Theme.Surface2 }, 0.15)
	end)

	-- Accordion: o painel abre por baixo do cartao e anima a altura.
	local panel = nil
	local open = false

	local function closePanel()
		if not panel then
			return
		end
		open = false
		local closing = panel
		panel = nil
		local animation = tween(closing, { Size = UDim2.fromOffset(closing.Size.X.Offset, 0) }, 0.2)
		if animation and animation.Completed then
			animation.Completed:Once(function()
				if closing.Parent then
					closing:Destroy()
				end
			end)
		else
			closing:Destroy()
		end
		tween(burger, { Rotation = 0 }, 0.2)
		Nexus.RefreshCanvases()
	end

	local function openPanel()
		if open then
			closePanel()
			return
		end
		open = true

		panel = make("Frame", {
			Name = randomName(),
			Size = UDim2.fromOffset((card.AbsoluteSize.X / UI_SCALE), 0),
			Position = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			BackgroundColor3 = Theme.Surface2,
			ClipsDescendants = true,
			ZIndex = 40,
		})
		corner(panel, Design.Corner)
		border(panel, Theme.Stroke, 1)
		panel.Parent = Nexus.CurrentOverlay()

		local layout = make("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
		layout.Parent = panel

		local padding = make("UIPadding", {
			PaddingLeft = UDim.new(0, Design.Padding),
			PaddingRight = UDim.new(0, Design.Padding),
			PaddingTop = UDim.new(0, Design.Padding),
			PaddingBottom = UDim.new(0, Design.Padding),
		})
		padding.Parent = panel

		label(panel, {
			Size = UDim2.new(1, 0, 0, 16),
			Text = string.upper(tostring(title or "OPTIONS")),
			TextSize = 10,
			Font = FONT_BOLD,
			TextColor3 = Theme.Muted,
			LayoutOrder = 1,
			ZIndex = 41,
		})

		for index, spec in ipairs(subElements) do
			local holder2 = make("Frame", {
				Name = randomName(),
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = index + 1,
				ZIndex = 41,
			})
			holder2.Parent = panel

			local kind = spec.Type or spec.Kind
			if kind == "Slider" then
				local slider = Nexus.CreateSlider(holder2, spec.Name, spec.Min, spec.Max, spec.Default)
				slider.Frame.Parent = holder2
			elseif kind == "Dropdown" then
				local dropdown = Nexus.CreateDropdown(holder2, spec.Name, spec.Options)
				dropdown.Frame.Parent = holder2
			elseif kind == "Input" then
				local input = Nexus.CreateInput(holder2, spec.Name, spec.Placeholder)
				input.Frame.Parent = holder2
			elseif kind == "Keybind" then
				local keybind = Nexus.CreateKeybind(holder2, spec.Name, spec.Default)
				keybind.Frame.Parent = holder2
			elseif kind == "Toggle" then
				local toggle = Nexus.CreateToggle(holder2, spec.Name, spec.Default, spec.SubElements)
				toggle.Frame.Parent = holder2
			end
		end

		-- Posicao: abaixo do cartao, em unidades da pagina.
		local page = Nexus.CurrentPage()
		local origin = card.AbsolutePosition - page.AbsolutePosition
		panel.Position = UDim2.fromOffset(
			origin.X / UI_SCALE,
			(origin.Y + card.AbsoluteSize.Y) / UI_SCALE + 6
		)

		-- A altura vem do AutomaticSize, mas em pixels JA escalados: e
		-- preciso dividir pela escala (mesma tecnica do CanvasSize).
		task.defer(function()
			if not panel then
				return
			end
			local height = (panel.AbsoluteSize.Y / UI_SCALE)
			if height > 0 then
				tween(panel, { Size = UDim2.fromOffset(panel.Size.X.Offset, height) }, 0.22, Enum.EasingStyle.Quart)
			end
			tween(burger, { Rotation = 90 }, 0.2)
			Nexus.RefreshCanvases()
		end)
	end

	burger.MouseButton1Click:Connect(function()
		if #subElements > 0 then
			openPanel()
		else
			log(tostring(title) .. ": sem opcoes extras")
		end
	end)

	return {
		Frame = card,
		GetState = function()
			return state
		end,
		SetState = function(value)
			state = value == true
			applySwitch()
		end,
	}
end

-- ---------------------------------------------------------------------
-- Nexus.CreateNotification(text)
--
-- Toast que entra a deslizar no canto da tela e desaparece.
-- ---------------------------------------------------------------------
function Nexus.CreateNotification(text, duration)
	local holder = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(280, 0),
		Position = UDim2.fromOffset(320, 0),
		AnchorPoint = Vector2.new(1, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ZIndex = 40,
	})
	holder.Parent = NexusWindow.Gui

	local toast = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(280, 56),
		Position = UDim2.fromOffset(0, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ZIndex = 41,
	})
	corner(toast, Design.Corner)
	border(toast, Theme.Stroke, 1)
	toast.Parent = holder

	label(toast, {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 16),
		Text = "NEXUS HUB",
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

-- ---------------------------------------------------------------------
-- POPUPS (uma lista de opcoes de cada vez)
-- ---------------------------------------------------------------------
local popup = nil

function Nexus.SetPopup(object)
	popup = object
end

function Nexus.GetPopup()
	return popup
end

function Nexus.ClosePopups()
	if popup then
		local object = popup
		popup = nil
		if object.Parent then
			object:Destroy()
		end
	end
end

-- Pagina e overlay da aba activa (para os popups).
function Nexus.CurrentPage()
	if currentTab then
		return currentTab.Page
	end
	return NexusWindow.Content
end

function Nexus.CurrentOverlay()
	if currentTab then
		return currentTab.Overlay
	end
	return NexusWindow.Content
end

--=====================================================================
-- MENU - MONTAGEM DAS ABAS (usando so a biblioteca NexusUI)
--=====================================================================

local window = Nexus.CreateWindow("NEXUS")

-- Duas colunas dentro de uma pagina (usado na HOME).
local function buildColumns(body)
	local columns = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ZIndex = 5,
	})
	columns.Parent = body

	local layout = make("UIListLayout", {
		Padding = UDim.new(0, GRID_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
	})
	layout.Parent = columns

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

		local columnLayout = make("UIListLayout", {
			Padding = UDim.new(0, GRID_ROW_GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
		columnLayout.Parent = frame

		return frame
	end

	return columns, column(1), column(2)
end

-- Cartao de texto (banner, estado, creditos).
local function infoCard(parent)
	local card = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ZIndex = 5,
	})
	corner(card, Design.Corner)
	border(card, Theme.Stroke, 1)
	card.Parent = parent

	-- Os textos do card empilham-se com um UIListLayout (nada de
	-- Positions fixos).
	local layout = make("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	layout.Parent = card

	local padding = make("UIPadding", {
		PaddingLeft = UDim.new(0, Design.Padding),
		PaddingRight = UDim.new(0, Design.Padding),
		PaddingTop = UDim.new(0, Design.Padding),
		PaddingBottom = UDim.new(0, Design.Padding),
	})
	padding.Parent = card

	return card
end

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
	if UserInputService.TouchEnabled then
		return "Mobile"
	end
	return "PC"
end

-- Linha "rotulo: valor".
local function infoRow(parent, title, value, muted)
	local row = make("Frame", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		ZIndex = 6,
	})
	row.Parent = parent

	label(row, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, -140, 1, 0),
		Text = title,
		TextSize = Design.TextSize,
		Font = FONT,
		TextColor3 = Theme.Muted,
		ZIndex = 7,
	})

	label(row, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(130, 20),
		Text = tostring(value or "-"),
		TextSize = Design.TextSize,
		Font = FONT_MED,
		TextColor3 = muted and Theme.Muted or Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
	})

	return row
end

--=====================================================================
-- ABA HOME
--=====================================================================
local homeTab = Nexus.CreateTab("HOME")
do
	local _, left, right = buildColumns(homeTab.Body)

	-- Banner
	local banner = infoCard(left)
	label(banner, {
		Size = UDim2.new(1, 0, 0, 22),
		Text = "NexusHub v1.0",
		TextSize = 18,
		Font = FONT_BOLD,
		TextColor3 = Theme.Text,
		ZIndex = 6,
	})

	label(banner, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "BBC HUB STYLE  •  PROJECT DELTA",
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

	-- Card de status
	local status = infoCard(left)
	label(status, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "STATUS",
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Muted,
		ZIndex = 6,
	})

	infoRow(status, "Jogador", LocalPlayer.DisplayName)
	infoRow(status, "Username", "@" .. LocalPlayer.Name, true)
	infoRow(status, "Executor", detectExecutor())
	infoRow(status, "Plataforma", detectPlatform())

	-- Botao Join Discord
	local discord = make("TextButton", {
		Name = randomName(),
		Size = UDim2.new(1, 0, 0, GRID_CARD_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		Text = "Join Discord",
		TextSize = Design.TextSize,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		AutoButtonColor = false,
		ZIndex = 5,
	})
	corner(discord, Design.Corner)
	border(discord, Theme.Stroke, 1)
	discord.Parent = right

	discord.MouseButton1Click:Connect(function()
		Nexus.CreateNotification("A abrir o Discord do NexusHub...")
		log("Discord: a abrir o convite")
	end)

	discord.MouseEnter:Connect(function()
		tween(discord, { BackgroundColor3 = Design.Hover }, 0.15)
	end)

	discord.MouseLeave:Connect(function()
		tween(discord, { BackgroundColor3 = Theme.Surface2 }, 0.15)
	end)

	-- Creditos
	local credits = infoCard(right)
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
		Text = "NexusHub  •  Project Delta",
		TextSize = 11,
		Font = FONT_MED,
		TextColor3 = Theme.Text,
		ZIndex = 6,
	})

	label(credits, {
		Size = UDim2.new(1, 0, 0, 16),
		Text = "Interface por guivn  •  v1.0",
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
end

--=====================================================================
-- ABA VISUALS
--=====================================================================
local visualsTab = Nexus.CreateTab("VISUALS")
do
	local section = Nexus.CreateSection(visualsTab.Body, "WORLD")

	local fullbright = Nexus.CreateToggle(section.Grid, "Fullbright", false, {
		{ Type = "Slider", Name = "Intensity", Min = 0, Max = 100, Default = 50 },
	})
	section:Add(fullbright.Frame)

	local crosshair = Nexus.CreateToggle(section.Grid, "Crosshair", false, {
		{ Type = "Slider", Name = "Size", Min = 0, Max = 50, Default = 10 },
	})
	section:Add(crosshair.Frame)

	local fov = Nexus.CreateToggle(section.Grid, "FOV Circle", false)
	section:Add(fov.Frame)
end

--=====================================================================
-- ABA PLAYER
--=====================================================================
local playerTab = Nexus.CreateTab("PLAYER")
do
	local section = Nexus.CreateSection(playerTab.Body, "PLAYERS ESP")

	local boxes = Nexus.CreateToggle(section.Grid, "Boxes", false, {
		{ Type = "Dropdown", Name = "Style", Options = { "Outline", "Corner", "Full" }, Default = "Outline" },
	})
	section:Add(boxes.Frame)

	local nametags = Nexus.CreateToggle(section.Grid, "Name Tags", false, {
		{ Type = "Slider", Name = "Max Distance", Min = 0, Max = 2000, Default = 500 },
	})
	section:Add(nametags.Frame)

	local tracers = Nexus.CreateToggle(section.Grid, "Tracers", false)
	section:Add(tracers.Frame)
end

--=====================================================================
-- ABA COMBAT
--=====================================================================
local combatTab = Nexus.CreateTab("COMBAT")
do
	local aim = Nexus.CreateSection(combatTab.Body, "AIM")

	local silentAim = Nexus.CreateToggle(aim.Grid, "Silent Aim", false, {
		{ Type = "Slider", Name = "Hit Chance", Min = 0, Max = 100, Default = 50 },
		{ Type = "Dropdown", Name = "Target Part", Options = { "Head", "Torso", "Nearest" }, Default = "Head" },
	})
	aim:Add(silentAim.Frame)

	local aimbot = Nexus.CreateToggle(aim.Grid, "Aimbot", false, {
		{ Type = "Slider", Name = "Smoothness", Min = 0, Max = 100, Default = 40 },
		{ Type = "Slider", Name = "FOV", Min = 0, Max = 360, Default = 120 },
	})
	aim:Add(aimbot.Frame)

	local autoShoot = Nexus.CreateToggle(aim.Grid, "Auto Shoot", false)
	aim:Add(autoShoot.Frame)

	local sticky = Nexus.CreateToggle(aim.Grid, "Sticky Target", false)
	aim:Add(sticky.Frame)

	local teamCheck = Nexus.CreateToggle(aim.Grid, "Team Check", false, {
		{ Type = "Dropdown", Name = "Team Mode", Options = { "Skip", "Ignore", "Block" }, Default = "Skip" },
	})
	aim:Add(teamCheck.Frame)

	local fovCircle = Nexus.CreateToggle(aim.Grid, "FOV Circle", false, {
		{ Type = "Slider", Name = "Circle Size", Min = 10, Max = 720, Default = 120 },
	})
	aim:Add(fovCircle.Frame)

	local trigger = Nexus.CreateSection(combatTab.Body, "TRIGGERBOT")
	local triggerbot = Nexus.CreateToggle(trigger.Grid, "Triggerbot", false, {
		{ Type = "Slider", Name = "Triggerbot Distance", Min = 0, Max = 1000, Default = 50 },
	})
	trigger:Add(triggerbot.Frame)

	local kill = Nexus.CreateSection(combatTab.Body, "KILL AURA")
	local killAura = Nexus.CreateToggle(kill.Grid, "Kill Aura", false, {
		{ Type = "Slider", Name = "Kill Aura Range", Min = 0, Max = 100, Default = 10 },
		{ Type = "Dropdown", Name = "Attack Type", Options = { "Power Attack", "Normal", "Heavy" }, Default = "Power Attack" },
	})
	kill:Add(killAura.Frame)

	local gun = Nexus.CreateSection(combatTab.Body, "GUN")
	local noRecoil = Nexus.CreateToggle(gun.Grid, "No Recoil", false, {
		{ Type = "Slider", Name = "Recoil Power", Min = 0, Max = 100, Default = 100 },
	})
	gun:Add(noRecoil.Frame)

	local fireRate = Nexus.CreateToggle(gun.Grid, "Fire Rate", false, {
		{ Type = "Slider", Name = "Rate", Min = 0, Max = 100, Default = 50 },
	})
	gun:Add(fireRate.Frame)

	local autoReload = Nexus.CreateToggle(gun.Grid, "Auto Reload", false, {
		{ Type = "Slider", Name = "Reload Delay", Min = 0, Max = 1000, Default = 100 },
	})
	gun:Add(autoReload.Frame)

	local fakeScope = Nexus.CreateToggle(gun.Grid, "Fake Scope", false, {
		{ Type = "Slider", Name = "Zoom", Min = 1, Max = 10, Default = 3 },
	})
	gun:Add(fakeScope.Frame)
end

--=====================================================================
-- ABA MISC
--=====================================================================
local miscTab = Nexus.CreateTab("MISC")
do
	local misc = Nexus.CreateSection(miscTab.Body, "MISC")

	local fastTrade = Nexus.CreateToggle(misc.Grid, "Fast Trade", false, {
		{ Type = "Slider", Name = "Trade Delay", Min = 0, Max = 1000, Default = 100 },
	})
	misc:Add(fastTrade.Frame)

	local panic = Nexus.CreateToggle(misc.Grid, "Panic Mode", false, {
		{ Type = "Dropdown", Name = "Panic Action", Options = { "Close Menu", "Hide HUD", "Reset" }, Default = "Close Menu" },
	})
	misc:Add(panic.Frame)

	local passDoor = Nexus.CreateToggle(misc.Grid, "Pass Door", false, {
		{ Type = "Toggle", Name = "Auto Open", Default = true },
	})
	misc:Add(passDoor.Frame)

	local screenEffects = Nexus.CreateToggle(misc.Grid, "Screen Effects", false, {
		{ Type = "Dropdown", Name = "Effect", Options = { "None", "Blur", "Vignette" }, Default = "None" },
	})
	misc:Add(screenEffects.Frame)

	local reportNotify = Nexus.CreateToggle(misc.Grid, "Report Notify", false)
	misc:Add(reportNotify.Frame)

	local joinNotify = Nexus.CreateToggle(misc.Grid, "Join Notify", false)
	misc:Add(joinNotify.Frame)

	local sounds = Nexus.CreateSection(miscTab.Body, "SOUNDS")
	local soundInput = Nexus.CreateInput(sounds.Grid, "Add Sound ID", "rbxassetid://...")
	sounds:Add(soundInput.Frame)

	local jump = Nexus.CreateToggle(sounds.Grid, "Jump", false, {
		{ Type = "Slider", Name = "Volume", Min = 0, Max = 100, Default = 50 },
	})
	sounds:Add(jump.Frame)

	local footsteps = Nexus.CreateToggle(sounds.Grid, "Footsteps", false, {
		{ Type = "Slider", Name = "Volume", Min = 0, Max = 100, Default = 50 },
	})
	sounds:Add(footsteps.Frame)

	local detect = Nexus.CreateSection(miscTab.Body, "DETECT")
	local contentCreator = Nexus.CreateToggle(detect.Grid, "Content Creator", false)
	detect:Add(contentCreator.Frame)

	local tester = Nexus.CreateToggle(detect.Grid, "Tester", false)
	detect:Add(tester.Frame)

	local moderator = Nexus.CreateToggle(detect.Grid, "Moderator", false)
	detect:Add(moderator.Frame)

	local cheater = Nexus.CreateToggle(detect.Grid, "Cheater", false)
	detect:Add(cheater.Frame)

	local vault = Nexus.CreateSection(miscTab.Body, "VAULT SORT")
	local sortValue = Nexus.CreateToggle(vault.Grid, "Sort By Value", false, {
		{ Type = "Dropdown", Name = "Order", Options = { "High to Low", "Low to High" }, Default = "High to Low" },
	})
	vault:Add(sortValue.Frame)

	local sortType = Nexus.CreateToggle(vault.Grid, "Sort By Type", false, {
		{ Type = "Dropdown", Name = "Order", Options = { "A to Z", "Z to A" }, Default = "A to Z" },
	})
	vault:Add(sortType.Frame)

	local sortName = Nexus.CreateToggle(vault.Grid, "Sort By Name", false, {
		{ Type = "Dropdown", Name = "Order", Options = { "A to Z", "Z to A" }, Default = "A to Z" },
	})
	vault:Add(sortName.Frame)

	local inventory = Nexus.CreateSection(miscTab.Body, "INVENTORY VIEWER")
	local showInventory = Nexus.CreateToggle(inventory.Grid, "Show Inventory", false)
	inventory:Add(showInventory.Frame)
end

--=====================================================================
-- ABA SETTINGS
--
-- Mantem o toggle "Show Keybinds" (o painel dos atalhos so aparece
-- com ele ligado) e mostra os componentes da biblioteca.
--=====================================================================
local setKeybindsVisible = function() end

local settingsTab = Nexus.CreateTab("SETTINGS")
do
	local panel = Nexus.CreateSection(settingsTab.Body, "PAINEL")

	local keybindsToggle = Nexus.CreateToggle(panel.Grid, "Show Keybinds", false, nil, function(state)
		setKeybindsVisible(state)
		log("Keybinds: " .. (state and "visiveis" or "escondidos"))
	end)
	panel:Add(keybindsToggle.Frame)

	local interface = Nexus.CreateSection(settingsTab.Body, "INTERFACE")

	local dropdown = Nexus.CreateDropdown(interface.Grid, "Interface", { "default", "compact", "cozy" })
	interface:Add(dropdown.Frame)

	local keybind = Nexus.CreateKeybind(interface.Grid, "Abrir menu", "RShift")
	interface:Add(keybind.Frame)

	local webhook = Nexus.CreateInput(interface.Grid, "Webhook URL", "https://discord.com/...")
	interface:Add(webhook.Frame)

	local notify = Nexus.CreateToggle(interface.Grid, "Testar notificacao", false)
	interface:Add(notify.Frame)
end

--=====================================================================
-- PAINEL DE KEYBINDS (informativo, so aparece com o toggle ligado)
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
	Visible = false,
	ZIndex = 40,
})
corner(keyPanel, Design.Corner)
border(keyPanel, Theme.Stroke, 1)
keyPanel.Parent = window.Gui

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
	ZIndex = 41,
})
keyHeader.Parent = keyPanel

label(keyHeader, {
	Position = UDim2.fromOffset(14, 11),
	Size = UDim2.fromOffset(KEY_W - 28, 16),
	Text = "KEYBINDS",
	TextSize = 11,
	Font = FONT_BOLD,
	TextColor3 = Theme.Text,
	ZIndex = 42,
})

local keyLine = make("Frame", {
	Size = UDim2.new(1, -28, 0, 1),
	Position = UDim2.fromOffset(14, 32),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Stroke,
	ZIndex = 41,
})
keyLine.Parent = keyHeader

for index, entry in ipairs(KEYBINDS) do
	local row = make("Frame", {
		Name = entry.key,
		Size = UDim2.new(1, -28, 0, KEY_ROW_H - 6),
		Position = UDim2.fromOffset(14, KEY_HEADER_H + ((index - 1) * KEY_ROW_H)),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ZIndex = 41,
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
		ZIndex = 42,
	})
	corner(chip, Design.Corner)
	chip.Parent = row

	label(row, {
		Position = UDim2.fromOffset(62, 0),
		Size = UDim2.fromOffset(KEY_W - 96, 18),
		Text = entry.action,
		TextSize = 10,
		Font = FONT,
		TextColor3 = Theme.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 42,
	})
end

makeDraggable(keyPanel, keyHeader)

--=====================================================================
-- BOTAO FLUTUANTE (REABRIR O MENU)
--=====================================================================
-- Botao flutuante: redondo, com o "N", no canto ESQUERDO do ecra.
-- E arrastavel (rato e toque) e traz a janela de volta.
local floating = make("TextButton", {
	Name = randomName(),
	Size = UDim2.fromOffset(46, 46),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface2,
	Text = "N",
	TextSize = 20,
	Font = FONT_BOLD,
	TextColor3 = Theme.Text,
	AutoButtonColor = false,
	ZIndex = 50,
})
corner(floating, 23)
border(floating, Theme.Stroke, 1)
floating.Parent = window.Gui

local floatingScale = make("UIScale", { Scale = UI_SCALE })
floatingScale.Parent = floating

do
	local view = viewportSize()
	floating.Position = UDim2.fromOffset(
		20,
		math.max(20, view.Y - (46 * UI_SCALE) - 20)
	)
end

-- Arrastar o botao flutuante (com o mesmo fantasma do menu).
makeDraggable(floating, floating)

floating.MouseEnter:Connect(function()
	tween(floating, { BackgroundColor3 = Design.Hover }, 0.15)
end)

floating.MouseLeave:Connect(function()
	tween(floating, { BackgroundColor3 = Theme.Surface2 }, 0.15)
end)

floating.MouseButton1Click:Connect(function()
	local show = not window.Frame.Visible
	window.Frame.Visible = show
	floating.Visible = not show
	log("Menu: " .. (show and "aberto" or "fechado"))
end)

-- O X da topbar esconde a janela: o botao flutuante aparece.
window.Floating = floating
floating.Visible = false

--=====================================================================
-- INICIALIZACAO
--=====================================================================

-- O toggle "Show Keybinds" controla o painel dos atalhos.
setKeybindsVisible = function(visible)
	keyPanel.Visible = visible == true
end

-- Abre a primeira aba.
if NexusTabs[1] then
	NexusTabs[1]:Show()
end

log(string.format(
	"NexusUI pronta • %d abas • host=%s • namecall=%s • humanoid=%s • antidebug=%s • debuginfo=%s",
	#NexusTabs,
	guiHost and guiHost.Name or "?",
	namecallHooked and "on" or "off",
	humanoidSpoofed and "on" or "off",
	antiDebugInstalled and "on" or "off",
	debugInfoHooked and "on" or "off"
))
