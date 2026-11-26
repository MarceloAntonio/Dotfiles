# Backend do configurador de monitores

**Português** · [English](README.en.md)

Este backend usa `hyprctl eval` com `hl.monitor()` do Hyprland Lua instalado.
O QML deve executar processos com uma lista de argumentos, sem shell.

## Contrato JSON

- `python backend.py catalog`: `{ok:true, monitors:[...], primary, pending}`.
  Cada monitor mantém os campos do `hyprctl -j monitors all` e acrescenta:
  `label`, `mode` (`1920x1080@144.00`), `availableModes` (strings sem `Hz`),
  `modes` (`[{id,width,height,refreshRate,label}]`) e `primary` booleano.
  `pending` é `null` ou `{token,deadline,expiresAt,secondsLeft}`.
- `python backend.py validate JSON`: valida e normaliza sem aplicar.
- `python backend.py apply JSON`: recebe `{monitors:[{name,mode,x,y,scale,
  transform?,disabled?}],primary}`. Inclua todos os monitores conectados.
  Retorna `{ok:true,token,deadline,expiresAt,seconds:20,message}`.
- `python backend.py confirm TOKEN`: persiste e confirma a prévia.
- `python backend.py revert TOKEN`: restaura a configuração anterior.
- Erros retornam `{ok:false,message}` e exit code 1.

`deadline` e `expiresAt` são segundos Unix. O relógio da UI é apenas visual;
a reversão é executada por um processo independente, mesmo se o QML fechar.
Um token só vale para sua própria transação. Não desarme o watchdog no QML.
Ao reabrir a UI, restaure a confirmação pendente a partir do catálogo.

## Persistência e integração

Adicionar ao FIM de `~/.config/hypr/configs/monitors.lua`, após regras atuais:

```lua
local monitor_config = os.getenv("HOME") .. "/.config/hypr/configs/monitors-managed.lua"
local monitor_file = io.open(monitor_config, "r")
if monitor_file then
    monitor_file:close()
    dofile(monitor_config)
end
```

O backend só cria esse arquivo após confirmação. Ele guarda as chamadas
`hl.monitor()` e a opção `cursor.default_monitor`. A preferência principal
é também salva em `~/.local/state/quickshell-monitors/layout.json`. Isso
representa a tela inicial do cursor/preferência do rice, não um atributo
"primary" global do protocolo Wayland. Não muda o foco atual nem atribui
workspaces a outros monitores.

Uma prévia nunca escreve a configuração permanente. Se a aplicação falhar,
o backend tenta restaurar imediatamente e mantém o watchdog caso necessário.
As operações são serializadas por flock. Modos devem pertencer ao monitor,
coordenadas/escalas são finitas, conectores não podem conter código e telas
sobrepostas ou um layout sem nenhuma saída ativa são rejeitados.

## Validação executada

- Catálogo das telas reais e os modos disponíveis lidos sem alterá-las.
- Sintaxe Lua gerada validada em função não invocada no Hyprland.
- Seis testes isolados cobrem validação, watchdog antes de apply, reversão,
  token errado, confirmação expirada e falha na persistência.

`python test_backend.py` não chama Hyprland nem altera telas reais.
Troca real de modo/posição e rollback com compositor exigem teste interativo;
não foram executados durante a implementação para não interromper o usuário.
