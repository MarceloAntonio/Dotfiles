# Arquitetura e diagnóstico

## Processos

A configuração `control-center` do Quickshell mantém barra, central, calendário, player, notificações, personalização e monitores. Ela é iniciada pelo autostart do Hyprland e admite recarga de QML.

A configuração `session-lock` roda em **outro processo**, iniciado por `rice-lock` apenas quando necessário. Ela desativa a recarga automática para que alterações no rice não interfiram no bloqueio.

`rice-lock-bridge.service` acompanha os sinais de bloqueio e preparação para suspensão do logind. Os helpers Python cuidam da geração de paletas, aplicação de personalização, pareamento Bluetooth e transações do configurador de monitores.

## Integrações

| Função | Serviço ou protocolo |
| --- | --- |
| Janelas e workspaces | IPC do Hyprland |
| Áudio e volume por aplicativo | PipeWire |
| Player | MPRIS |
| Bateria e perfis de energia | UPower / power-profiles-daemon |
| Wi-Fi e conexões | NetworkManager |
| Bluetooth | BlueZ, com agente de confirmação |
| Notificações | Servidor `org.freedesktop.Notifications` do Quickshell |
| Bloqueio | `ext-session-lock-v1` e PAM |
| Wallpaper | awww |

O Rofi continua como seletor de aplicativos e clipboard. Waybar, SwayNC e Pulsar não são mais iniciados pelo rice. A ativação D-Bus das notificações aponta para o Quickshell; não deve haver dois servidores disputando o mesmo nome.

## Organização dos arquivos

| Caminho | Conteúdo |
| --- | --- |
| `.config/quickshell/control-center/` | Shell, serviços e componentes comuns |
| `control-center/bar/` | Barra, calendário, comandos e visão de workspaces |
| `control-center/bar/motion/` | Itens persistentes e destaque deslizante |
| `control-center/personalize/` | Galeria e backend de personalização |
| `control-center/monitors/` | Editor de layout e watchdog de reversão |
| `control-center/widgets/` | Tooltips e barras de rolagem |
| `.config/quickshell/session-lock/` | Bloqueador, prévia e integração logind |
| `.config/hypr/configs/` | Configuração Lua, atalhos, regras e autostart |
| `.local/bin/` | `rice-lock` e `rice-monitors` |
| `.config/systemd/user/` | Serviço de integração do bloqueador |

## Estado local

Preferências, imagens e estado de execução são específicos da instalação e não devem ser copiados do computador do autor:

| Caminho no usuário | Uso |
| --- | --- |
| `~/.config/hypr/.current_wallpaper` | Wallpaper selecionado |
| `~/.local/state/quickshell-theme.json` | Tema e cor extraída |
| `~/.config/kitty/Adaptativo.conf` | Paleta gerada do terminal |
| `~/.config/rofi/themes/shell-palette.rasi` | Paleta compartilhada do Rofi |
| `~/.config/hypr/configs/monitors-managed.lua` | Layout confirmado dos monitores |
| `~/.local/state/quickshell-monitors/layout.json` | Preferência de monitores |
| `$XDG_RUNTIME_DIR/quickshell-monitors/` | Transação temporária de prévia |
| `~/.cache/quickshell-lock/` | Wallpapers pré-desfocados do bloqueador |
| `~/.local/state/quickshell-lock/last.log` | Log da última abertura do bloqueador |

O instalador prepara o estado necessário para o usuário de destino. Não versione caches, transações pendentes, senhas ou caminhos para imagens particulares.

## Diagnóstico

```sh
qs -c control-center log -t 50
qs -c control-center ipc call control status
qs -c control-center ipc call bar status
qs -c control-center ipc call calendar status
qs -c control-center ipc call personalize status
qs -c control-center ipc call monitors status
qs -c control-center ipc call theme status
hyprctl configerrors
systemctl --user status rice-lock-bridge.service
rice-lock --status
```

Se a barra não estiver em execução, inicie com:

```sh
qs -c control-center --no-duplicate --daemonize
```

Reiniciar esse processo limpa o histórico de notificações. Recarregar arquivos QML não reinicia o processo separado do bloqueador.

## Bloqueio e suspensão

O controlador libera o bloqueio somente após `PamResult.Success`. A senha não é passada por linha de comando, arquivo ou log. A política usada é `/etc/pam.d/hyprlock`; as regras de senha e os limites de tentativas continuam pertencendo ao PAM do sistema. O IPC expõe o estado, sem oferecer comando de desbloqueio.

O compositor cobre todos os monitores pelo protocolo de bloqueio. Se o cliente morrer, a sessão permanece bloqueada. Não mate o processo enquanto estiver bloqueado; uma falha nessa situação exige recuperação pela sessão/compositor ou por TTY. O launcher tenta o Hyprlock quando o processo termina com erro, mas isso não é garantia de recuperação de um lock já adquirido.

A ponte do logind mantém um inibidor de atraso enquanto espera o bloqueio. Pedidos externos de suspensão ainda estão sujeitos ao limite de espera do logind. Pelo menu, `rice-lock --suspend` cancela a suspensão caso não confirme `secure=true`.

## Validação

As verificações feitas durante o desenvolvimento incluíram recarga do QML, prévia visual, configuração de lock com `locked=false`, navegação dos painéis e testes isolados do backend de monitores. Os testes de monitores não alteram as saídas reais:

```sh
python .config/quickshell/control-center/monitors/test_backend.py
```

Autenticação real, bloqueio durante hotplug, suspensão/retomada e troca de modo de vídeo devem ser verificados interativamente no equipamento de destino. O instalador não deve ser executado para testar apenas sintaxe ou geração de arquivos.
