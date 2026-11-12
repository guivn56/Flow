# Flow

**AirflowUI** - menu de executor para Roblox em Luau, construido com a
**AirFlowLibrary** (neste repo), com o layout do **BBC Hub**: cada aba
tem DUAS COLUNAS lado a lado, cada secao tem o seu cabecalho e a logica
pesada fica em marcadores.

Corre em executores de **PC** (Synapse X, Fluxus, Script-Ware, AWP, Codex)
e de **mobile** (Delta, Arceus, Hydrogen, Solara).

---

## Link RAW (o artefacto)

```
https://raw.githubusercontent.com/guivn56/Flow/main/dist/airflowui.lua
```

Um ficheiro, sem `require`, sem a pasta `tabs/` no telemóvel: as 6 abas
vao embutidas. A biblioteca continua a ser lida de
`/sdcard/Download/AirFlowLibrary.luau`.

| | |
|---|---|
| tamanho | 36 125 bytes |
| sha256 | `f1162f15fa93794f3fff81c62499f0a16c1d7ed7f49a0dc7b97dc48b71af1e0d` |

---

## O que esta no repo

```
AirFlowLibrary.luau   a biblioteca do Airflow (o menu em si)
airflowui/
  main.lua            entrada: biblioteca, tema roxo, janela, Settings
                      partilhado, carrega as 6 abas
  teste_misc.lua      teste da aba MISC sozinha
  build.py            junta as abas num unico ficheiro
  tabs/               uma aba por ficheiro
dist/
  airflowui.lua       o bundle (o que se cola no executor)
  airflowui.lua.map.json   sha256 por modulo e do bundle
```

## Abas

| Aba | Coluna esquerda | Coluna direita |
|---|---|---|
| **COMBAT** | AIM | GUN · TRIGGERBOT · KILL AURA |
| **PLAYERS** | PLAYERS ESP | ITEMS ESP · RADAR |
| **VISUALS** | WORLD | PLAYER · CROSSHAIR |
| **MISC** | MISC · SOUNDS | DETECT · VAULT SORT · INVENTORY VIEWER |
| **UTILITY** | LOOT · LOOT RANGE | MOVEMENT · FREECAM · BOSS CHECKER |
| **SETTINGS** | UI | KEYBINDS · CONFIG |

## Como uma aba e feita

Cada ficheiro em `airflowui/tabs/` devolve `function(ctx)` e recebe:

| Campo | Para que serve |
|---|---|
| `Library` | a biblioteca AirFlow (tema, cores) |
| `window` | a janela onde criar o tab |
| `Settings` | a tabela de estado partilhada por todas as abas |
| `plainColumn` | esconde a barra do groupbox (as colunas do BBC Hub nao a usam) |

Regras:

1. **Duas colunas** por aba: `Groupbox({ Side = "Left" })` e
   `Groupbox({ Side = "Right" })`, com `ctx.plainColumn` nas duas.
2. **Secoes** com o nome em maiusculas (`AIM`, `SOUNDS`, `DETECT`, ...).
3. **Logica em marcadores**: cada callback escreve na `Settings` e
   commenta com `-- [LOGICA ... AQUI]`.
4. **Flags** em todos os widgets (e o que permite guardar a config).
5. **Uma aba que falhe nao leva o menu abaixo**: o `main.lua` carrega
   cada aba num `pcall` e avisa no console.

Exemplo:

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

## Build

```
python3 airflowui/build.py
```

Escreve `dist/airflowui.lua` (o bundle), `dist/airflowui.lua.map.json` e
`dist/airflowui.lua.source.lua` (a fonte em claro, para os testes
correrem os mesmos bytes). O build e determinista: os mesmos ficheiros
dao sempre o mesmo bundle.

O `main.lua` tem a tabela `EMBEDDED`: o build troca a linha
`local EMBEDDED = {}` pela tabela com as abas embutidas. Por isso o
mesmo ficheiro serve para as duas formas - com bundle (as abas vem de
dentro) e sem bundle (as abas vem do disco).

## Correr

- **Menu completo**: cola o `dist/airflowui.lua` no executor.
- **So a aba MISC**: cola o `airflowui/teste_misc.lua`.

---

Uso interno. Nao redistribuir sem autorizacao.
