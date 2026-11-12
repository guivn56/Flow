# AirflowUI

Menu do **Airflow** (biblioteca `AirFlowLibrary.luau`) com o layout do
**BBC Hub**: cada aba tem duas colunas lado a lado, cada secao tem o seu
cabecalho e a logica pesada fica em marcadores.

## Ficheiros

```
AirflowUI/
  main.lua          entrada: biblioteca, tema, janela, tabela Settings
  teste_misc.lua    teste da aba MISC sozinha
  tabs/
    misc.lua        aba MISC
    combat.lua      aba COMBAT
    players.lua     aba PLAYERS
    visuals.lua     aba VISUALS
    utility.lua     aba UTILITY
    settings.lua    aba SETTINGS
```

A biblioteca é buscada na internet com `game:HttpGet`, a partir da RAW do
GitHub (`https://raw.githubusercontent.com/guivn56/Flow/main/AirFlowLibrary.luau`).
Se a rede falhar, há fallback para `/sdcard/Download/AirFlowLibrary.luau`.

## Como uma aba e feita

Cada ficheiro em `tabs/` devolve uma funcao que recebe o contexto e
constroi a aba:

```lua
return function(ctx)
	local window = ctx.window
	local Settings = ctx.Settings

	local tab = window:CreateTab({ Name = "COMBAT" }, "crosshair")
	local left = tab:Groupbox({ Name = "", Side = "Left", PopOut = false })
	local right = tab:Groupbox({ Name = "", Side = "Right", PopOut = false })
	ctx.plainColumn(left)
	ctx.plainColumn(right)

	left:Section("AIM")
	left:Toggle({
		Name = "Silent Aim",
		Flag = "CombatSilentAim",
		Callback = function(value)
			Settings.combat_silent_aim = value
		end,
	})
	return tab
end
```

O `ctx` leva quatro coisas:

| Campo | Para que serve |
|---|---|
| `Library` | a biblioteca AirFlow (tema, cores) |
| `window` | a janela onde criar o tab |
| `Settings` | a tabela de estado partilhada por todas as abas |
| `plainColumn` | esconde a barra do groupbox (as colunas do BBC Hub nao a usam) |

## Regras

1. **Duas colunas** por aba: `Groupbox({ Side = "Left" })` e
   `Groupbox({ Side = "Right" })`, e `ctx.plainColumn` nas duas.
2. **Secoes** com o nome em maiusculas (`AIM`, `SOUNDS`, `DETECT`, ...).
3. **Logica em marcadores**: cada callback escreve na `Settings` e
   commenta com `-- [LOGICA ... AQUI]` onde a feature vai ser
   implementada.
4. **Flags** em todos os widgets: e o que permite guardar a config.
5. **Uma aba que falhe nao leva o menu abaixo**: o `main.lua` carrega
   cada aba num `pcall` e avisa no console.

## Correr

- Menu completo: cola o `main.lua` no executor (ele busca a biblioteca no
  GitHub com `game:HttpGet` e as abas de
  `/sdcard/Delta/Workspace/AirflowUI/tabs`).
- So a aba MISC: cola o `teste_misc.lua`.

## Validar sem o jogo

O harness corre a biblioteca e o menu num mock do Roblox (headless) e
confere que as abas e os widgets aparecem:

```
/tmp/opencode/airflow_check/check.sh
```

`build_suite.py` embute os ficheiros do dispositivo no harness (o luau
CLI nao tem `io`) e o `mock_tmp/roblox.lua` e o mock do RoboX com os
patches necessarios (`mock_patches.patch` mostra o diff para o mock do
repo).
