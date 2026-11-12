-- =====================================================================
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
