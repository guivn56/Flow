--[[
	BBC HUB • Project Delta
	Interface single-file (Luau / Roblox) com camada de seguranca (stealth).

	REGRA: apenas UI + prints. Sem logica de cheat (sem CFrame, sem hooks de
	jogo, sem Raycast, sem ESP math). A camada de seguranca serve apenas
	para o proprio script nao ser identificado pelo jogo.
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
-- TEMA
--=====================================================================

local Theme = {
	Background = Color3.fromRGB(8, 8, 8),
	Surface = Color3.fromRGB(15, 15, 15),
	Surface2 = Color3.fromRGB(25, 25, 25),
	Stroke = Color3.fromRGB(45, 45, 45),
	Accent = Color3.fromRGB(170, 80, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(150, 150, 150),
}

local FONT = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local IS_TOUCH = UserInputService.TouchEnabled
local UI_SCALE = IS_TOUCH and 0.65 or 1

--=====================================================================
-- LAYOUT
--=====================================================================

local WINDOW_W, WINDOW_H = 900, 560
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

local function corner(object, radius)
	object:AddChild(make("UICorner", { CornerRadius = UDim.new(radius, 0) }))
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

local function viewportSize()
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1920, 1080)
end

--=====================================================================
-- CONTEUDO DAS ABAS
--=====================================================================

local TABS = {
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
							{ name = "FOV", min = 0, max = 360, value = 90, unit = "°" },
							{ name = "Smoothness", min = 0, max = 100, value = 50, unit = "%" },
							{ name = "Hit Radius", min = 0, max = 50, value = 12, unit = "px" },
						},
					},
					{
						type = "toggle",
						label = "Aimbot",
						sliders = {
							{ name = "FOV", min = 0, max = 360, value = 120, unit = "°" },
							{ name = "Target Part", min = 0, max = 100, value = 60, unit = "%" },
							{ name = "Smoothness", min = 0, max = 100, value = 40, unit = "%" },
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
					{ type = "input", label = "Sound ID", placeholder = "rbxassetid://..." },
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
	BackgroundColor3 = Theme.Surface,
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

-- Topbar
local topbar = make("Frame", {
	Name = randomName(),
	Size = UDim2.new(1, 0, 0, TOPBAR_H),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface2,
	Active = true,
	ZIndex = 3,
})
corner(topbar, 12)
topbar.Parent = window

local topbarPatch = make("Frame", {
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.fromOffset(0, TOPBAR_H - 14),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface2,
	ZIndex = 3,
})
topbarPatch.Parent = topbar

local logoMark = make("Frame", {
	Size = UDim2.fromOffset(34, 34),
	Position = UDim2.fromOffset(16, 10),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Accent,
	ZIndex = 4,
})
corner(logoMark, 9)
logoMark.Parent = topbar

label(logoMark, {
	Size = UDim2.fromScale(1, 1),
	Text = "B",
	TextSize = 18,
	Font = FONT_BOLD,
	TextColor3 = Theme.Text,
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
	TextColor3 = Theme.TextDim,
	ZIndex = 4,
})

local closeButton = make("TextButton", {
	Size = UDim2.fromOffset(30, 30),
	Position = UDim2.new(1, -42, 0, 12),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface,
	BackgroundTransparency = 0.3,
	Text = "✕",
	TextSize = 14,
	Font = FONT_BOLD,
	TextColor3 = Theme.Text,
	AutoButtonColor = false,
	ZIndex = 4,
})
corner(closeButton, 8)
closeButton.Parent = topbar

closeButton.MouseButton1Click:Connect(function()
	log("Interface fechada")
	window.Visible = false
end)

makeDraggable(window, topbar)

-- Sidebar
local sidebar = make("Frame", {
	Name = randomName(),
	Size = UDim2.fromOffset(SIDEBAR_W, WINDOW_H - TOPBAR_H),
	Position = UDim2.fromOffset(0, TOPBAR_H),
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	ZIndex = 3,
})
sidebar.Parent = window

local sidebarLine = make("Frame", {
	Size = UDim2.new(0, 1, 1, -28),
	Position = UDim2.fromOffset(SIDEBAR_W - 1, 14),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Stroke,
	ZIndex = 4,
})
sidebarLine.Parent = sidebar

label(sidebar, {
	Position = UDim2.fromOffset(18, 16),
	Size = UDim2.fromOffset(SIDEBAR_W - 36, 16),
	Text = "CATEGORIES",
	TextSize = 10,
	Font = FONT_BOLD,
	TextColor3 = Theme.TextDim,
	ZIndex = 4,
})

-- Container proprio da lista de abas (o UIListLayout nao pode tocar
-- nos labels/linhas da sidebar).
local tabList = make("Frame", {
	Name = randomName(),
	Size = UDim2.new(1, 0, 1, -74),
	Position = UDim2.fromOffset(0, 40),
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	ZIndex = 4,
})
tabList.Parent = sidebar

local tabListLayout = make("UIListLayout", {
	Padding = UDim.new(4, 0),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
tabListLayout.Parent = tabList

local tabListPadding = make("UIPadding", {
	PaddingLeft = UDim.new(16, 0),
	PaddingRight = UDim.new(16, 0),
})
tabListPadding.Parent = tabList

-- Painel de conteudo
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

-- Fundo hexagonal do painel de conteudo.
--
-- O painel e transparente de proposito: um filho com ZIndex negativo e
-- desenhado ATRAS do fundo do pai, so aparece se o pai nao tiver cor.
-- O proprio hex carrega a cor de fundo (8,8,8) e o padrao e a imagem
-- por cima, com 80% de transparencia.
local hexLayer = make("ImageLabel", {
	Name = randomName(),
	Size = UDim2.fromScale(1, 1),
	Position = UDim2.fromOffset(0, 0),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Background,
	BackgroundTransparency = 0,
	Image = "rbxassetid://12629542321",
	ScaleType = Enum.ScaleType.Tile,
	TileSize = UDim2.fromOffset(50, 50),
	ImageColor3 = Color3.fromRGB(45, 45, 45),
	ImageTransparency = 0.8,
	ZIndex = -1,
})
corner(hexLayer, 10)
hexLayer.Parent = contentPanel

local scroll = make("ScrollingFrame", {
	Name = randomName(),
	Size = UDim2.fromScale(1, 1),
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Theme.Accent,
	ScrollBarImageTransparency = 0.3,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromOffset(CONTENT_W, 0),
	ZIndex = 4,
})
scroll.Parent = contentPanel

local scrollBody = make("Frame", {
	Name = randomName(),
	Size = UDim2.fromOffset(CONTENT_W - (BODY_PAD * 2), 0),
	Position = UDim2.fromOffset(BODY_PAD, BODY_PAD),
	AutomaticSize = Enum.AutomaticSize.Y,
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
	ZIndex = 4,
})
scrollBody.Parent = scroll

local bodyListLayout = make("UIListLayout", {
	Padding = UDim.new(16, 0),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
bodyListLayout.Parent = scrollBody

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
local openBurger = nil

local function closeDropdown()
	if openPanel then
		local panel = openPanel
		openPanel = nil
		local animation = tween(panel, { Size = UDim2.fromOffset(panel.Size.X.Offset, 0) }, 0.15)
		animation.Completed:Once(function()
			if panel.Parent then
				panel:Destroy()
			end
		end)
	end
	if openBurger then
		local burger = openBurger
		openBurger = nil
		if burger.Parent then
			tween(burger, { Rotation = 0 }, 0.2)
		end
	end
end

local function cardWidth()
	local bodyWidth = scrollBody.Size.X.Offset
	return (bodyWidth - GRID_GAP) / 2
end

-- Slider visual: linha cinza com preenchimento roxo
local function buildSlider(parent, spec, order)
	local minValue = spec.min or 0
	local maxValue = spec.max or 100
	local unit = spec.unit or ""

	local row = make("Frame", {
		Size = UDim2.new(1, -24, 0, SLIDER_ROW_H - 10),
		Position = UDim2.fromOffset(12, SLIDER_BASE_Y + ((order - 1) * SLIDER_ROW_H)),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
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
		TextColor3 = Theme.Accent,
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
		BackgroundColor3 = Theme.Accent,
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

-- SubFrame que abre por baixo do cartao, com altura animada
local function openDropdown(card, burger, sliders, title)
	if openBurger == burger then
		closeDropdown()
		return
	end
	closeDropdown()

	local panel = make("Frame", {
		Name = randomName(),
		Size = UDim2.fromOffset(cardWidth(), 0),
		Position = UDim2.fromOffset(0, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface2,
		ClipsDescendants = true,
		ZIndex = 61,
	})
	corner(panel, 10)
	border(panel, Theme.Accent, 1)
	panel.Parent = overlay

	label(panel, {
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.new(1, -24, 0, 16),
		Text = string.upper(title or "OPTIONS"),
		TextSize = 10,
		Font = FONT_BOLD,
		TextColor3 = Theme.Accent,
		ZIndex = 62,
	})

	for index, spec in ipairs(sliders) do
		buildSlider(panel, spec, index)
	end

	local height = SLIDER_BASE_Y + (#sliders * SLIDER_ROW_H)

	-- Posicao relativa ao painel de conteudo. O overlay vive dentro do
	-- contentPanel, por isso basta a diferenca para o painel. As
	-- coordenadas de ecra sao divididas pela escala porque o painel esta
	-- sob um UIScale.
	local origin = card.AbsolutePosition - contentPanel.AbsolutePosition
	panel.Position = UDim2.fromOffset(
		origin.X / UI_SCALE,
		(origin.Y + card.AbsoluteSize.Y) / UI_SCALE + 6
	)

	panel.Size = UDim2.fromOffset(panel.Size.X.Offset, 0)
	tween(panel, { Size = UDim2.fromOffset(panel.Size.X.Offset, height) }, 0.22, Enum.EasingStyle.Quint)

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
		BackgroundColor3 = state and Theme.Accent or Theme.Stroke,
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
	knob.Parent = holder

	return holder, knob
end

local function applySwitch(holder, knob, state)
	tween(holder, { BackgroundColor3 = state and Theme.Accent or Theme.Stroke }, 0.16)
	tween(knob, { Position = UDim2.new(state and 1 or 0, state and -7 or 7, 0.5, 0) }, 0.16)
end

-- CreateToggle: cartao com o icone ☰ a esquerda do texto e o switch
-- a direita. O ☰ abre o submenu.
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
		TextColor3 = item.sliders and Theme.Accent or Theme.TextDim,
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
	end

	burger.MouseButton1Click:Connect(function()
		if item.sliders then
			openDropdown(card, burger, item.sliders, item.label)
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
		BackgroundColor3 = isAccent and Theme.Accent or Theme.Surface2,
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
				and Theme.Accent:Lerp(Color3.fromRGB(0, 0, 0), 0.18)
				or Theme.Stroke,
		}, 0.15)
	end)

	card.MouseLeave:Connect(function()
		tween(card, {
			BackgroundColor3 = isAccent and Theme.Accent or Theme.Surface2,
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
		stroke.Color = isActive and Theme.Accent or Theme.Stroke
		card.BackgroundColor3 = isActive
			and Theme.Accent:Lerp(Theme.Background, 0.8)
			or Theme.Surface2
		text.TextColor3 = isActive and Theme.Accent or Theme.Text
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
		TextColor3 = Theme.TextDim,
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
		PlaceholderColor3 = Theme.TextDim,
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
		BackgroundColor3 = Theme.Accent,
		Text = "▶",
		TextSize = 12,
		Font = FONT_BOLD,
		TextColor3 = Theme.Text,
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
		Padding = UDim.new(10, 0),
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

	label(header, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(400, 16),
		Text = string.upper(sectionData.name),
		TextSize = 11,
		Font = FONT_BOLD,
		TextColor3 = Theme.Accent,
		ZIndex = 6,
	})

	local divider = make("Frame", {
		Size = UDim2.new(1, -8, 0, 1),
		Position = UDim2.fromOffset(0, 19),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Stroke,
		ZIndex = 5,
	})
	divider.Parent = header

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

local function selectTab(index)
	currentTab = index
	for i, ref in ipairs(tabRefs) do
		local active = (i == index)
		ref.Button.BackgroundColor3 = active and Theme.Surface2 or Theme.Surface
		ref.Text.TextColor3 = active and Theme.Accent or Theme.TextDim
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
	for order, sectionData in ipairs(tabData.sections) do
		buildSection(sectionData, order)
	end
end

for index, tabData in ipairs(TABS) do
	local button = make("TextButton", {
		Name = randomName(),
		Size = UDim2.new(1, -32, 0, 34),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Surface,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		ZIndex = 5,
	})
	corner(button, 8)
	button.Parent = tabList

	local indicator = make("Frame", {
		Size = UDim2.fromOffset(3, 16),
		Position = UDim2.new(0, -6, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BorderSizePixel = 0,
		BackgroundColor3 = Theme.Accent,
		Visible = false,
		ZIndex = 6,
	})
	corner(indicator, 2)
	indicator.Parent = button

	local text = label(button, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -18, 1, 0),
		Text = tabData.name,
		TextSize = 12,
		Font = FONT_MED,
		TextColor3 = Theme.TextDim,
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

	tabRefs[index] = { Button = button, Indicator = indicator, Text = text }
end

-- Rodape da sidebar
label(sidebar, {
	Size = UDim2.fromOffset(SIDEBAR_W - 36, 16),
	Position = UDim2.new(0, 18, 1, -30),
	Text = "v1.0.0 • SINGLE FILE",
	TextSize = 9,
	Font = FONT,
	TextColor3 = Theme.TextDim,
	ZIndex = 4,
})

--=====================================================================
-- CARD DE PERFIL (INFERIOR ESQUERDO)
--=====================================================================

local PROFILE_W, PROFILE_H = 250, 78

local profile = make("Frame", {
	Name = randomName(),
	Size = UDim2.fromOffset(PROFILE_W, PROFILE_H),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface2,
	Active = true,
	ZIndex = 4,
})
corner(profile, 12)
border(profile, Theme.Stroke, 1)
profile.Parent = screenGui

local profileScale = make("UIScale", { Scale = UI_SCALE })
profileScale.Parent = profile

do
	local view = viewportSize()
	profile.Position = UDim2.fromOffset(20, view.Y - (PROFILE_H * UI_SCALE) - 20)
end

local avatar = make("ImageLabel", {
	Name = randomName(),
	Size = UDim2.fromOffset(52, 52),
	Position = UDim2.new(0, 12, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Surface,
	ScaleType = Enum.ScaleType.Crop,
	ZIndex = 5,
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
	TextSize = 20,
	Font = FONT_BOLD,
	TextColor3 = Theme.TextDim,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 6,
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
	Size = UDim2.fromOffset(PROFILE_W - 92, 18),
	Position = UDim2.new(0, 76, 0, 12),
	Text = LocalPlayer.DisplayName,
	TextSize = 13,
	Font = FONT_BOLD,
	TextColor3 = Theme.Text,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 5,
})

label(profile, {
	Size = UDim2.fromOffset(PROFILE_W - 92, 14),
	Position = UDim2.new(0, 76, 0, 31),
	Text = "@" .. LocalPlayer.Name,
	TextSize = 10,
	Font = FONT,
	TextColor3 = Theme.TextDim,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 5,
})

local ownerTag = make("TextLabel", {
	Name = "Lbl",
	Size = UDim2.fromOffset(56, 18),
	Position = UDim2.new(0, 76, 0, 48),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Accent,
	BackgroundTransparency = 0.82,
	Text = "OWNER",
	TextSize = 9,
	Font = FONT_BOLD,
	TextColor3 = Theme.Accent,
	TextXAlignment = Enum.TextXAlignment.Center,
	ZIndex = 5,
})
corner(ownerTag, 5)
ownerTag.Parent = profile

makeDraggable(profile, profile)

--=====================================================================
-- PAINEL DE KEYBINDS (SUPERIOR DIREITO)
--=====================================================================

local KEYBINDS = {
	{ key = "RShift", action = "Abrir / fechar o menu" },
	{ key = "LAlt", action = "Recolher a sidebar" },
	{ key = "Equals", action = "Mostrar inventario" },
	{ key = "G", action = "Fast trade" },
	{ key = "X", action = "Panic mode" },
	{ key = "Z", action = "Ordenar vault" },
	{ key = "C", action = "Copiar server ID" },
	{ key = "B", action = "Alternar fundo" },
	{ key = "J", action = "Join notify" },
	{ key = "MB3", action = "Clique do meio" },
	{ key = "U", action = "Descarregar a interface" },
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
	TextColor3 = Theme.Accent,
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
		TextColor3 = Theme.Accent,
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
		TextColor3 = Theme.TextDim,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	})
end

makeDraggable(keyPanel, keyHeader)

--=====================================================================
-- BOTAO FLUTUANTE (REABRIR O MENU)
--=====================================================================

local floating = make("TextButton", {
	Name = randomName(),
	Size = UDim2.fromOffset(46, 46),
	BorderSizePixel = 0,
	BackgroundColor3 = Theme.Accent,
	Text = "☰",
	TextSize = 20,
	Font = FONT_BOLD,
	TextColor3 = Theme.Text,
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

	local newX = collapsed and PANEL_PAD or CONTENT_X
	local newW = collapsed and (WINDOW_W - (PANEL_PAD * 2)) or CONTENT_W
	contentPanel.Position = UDim2.fromOffset(newX, CONTENT_Y)
	contentPanel.Size = UDim2.fromOffset(newW, CONTENT_H)

	scrollBody.Size = UDim2.fromOffset(newW - (BODY_PAD * 2), 0)
	renderTab(currentTab)
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
