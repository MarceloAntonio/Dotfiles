# Instalação e migração

## Ambiente esperado

O instalador é voltado a Arch Linux com `pacman`, systemd e uma sessão Wayland. A configuração usa a API Lua do Hyprland, inclusive `hl.monitor()` e `hyprctl eval`; versões antigas que só aceitam configuração em `.conf` não servem para estes arquivos. O desenvolvimento foi feito com Hyprland 0.57.1 e Quickshell 0.3.2.

As dependências incluem Quickshell e módulos Qt/Wayland, PipeWire e WirePlumber, NetworkManager, BlueZ, awww, Rofi, Kitty e os helpers Python com Pillow, D-Bus e GObject. O lock usa PAM e mantém o Hyprlock como alternativa. O instalador imprime a lista de pacotes que pretende instalar.

## Antes de instalar

Clone e veja o plano sem alterar a máquina:

```sh
git clone https://github.com/MarceloAntonio/Dotfiles.git
cd Dotfiles
./install.sh --dry-run
```

O modo `--dry-run` não executa `sudo`, não instala pacotes nem copia arquivos. Para ver todas as opções:

```sh
./install.sh --help
```

A instalação usa a rede para pacotes e recursos visuais. Execute como usuário normal:

```sh
./install.sh
```

As configurações anteriores que seriam substituídas são preservadas em um diretório com data e hora dentro de `~/.local/state/dotfiles-backups/`. O script copia as configurações, comandos de `~/.local/bin`, entradas de aplicativos e integração de serviços para o usuário de destino; não depende de o usuário se chamar como o autor do repositório.

## Opções

| Opção | Efeito |
| --- | --- |
| `--dry-run` | Exibe o plano sem aplicar |
| `--skip-assets` | Pula o download/instalação dos recursos visuais externos |
| `--skip-wallpapers` | Mantém a coleção de wallpapers existente |
| `--skip-nvim` | Não pré-instala os plugins do Neovim |
| `--sddm` | Instala/configura o tema SDDM Astronaut |
| `--set-shell` | Define Zsh como shell padrão |

Por exemplo, para aplicar a configuração sem baixar novamente os recursos visuais, wallpapers e plugins:

```sh
./install.sh --skip-assets --skip-wallpapers --skip-nvim
```

O instalador deixa de instalar Waybar, SwayNC e Pulsar, mas não remove pacotes que você já tinha instalado. Não é necessário um helper AUR para o fluxo padrão. O tema SDDM e a troca de shell são opções explícitas.

## Atualizando uma instalação antiga

A barra e os painéis agora pertencem ao Quickshell. Os atalhos de personalização continuam em `Super + T` e `Super + W`, mas abrem a interface QML em vez dos seletores antigos do Rofi. O Rofi permanece para aplicativos e clipboard.

O bloqueio passa pelo comando `rice-lock`, que abre uma configuração Quickshell independente e autentica pelo serviço PAM `hyprlock`. O Hyprlock continua instalado e com configuração alternativa disponível. O serviço `rice-lock-bridge` integra pedidos de bloqueio e suspensão à sessão do logind.

Ao terminar a instalação, encerre e abra a sessão do Hyprland para iniciar os componentes com as novas variáveis de ambiente. Numa sessão já aberta, confira se não há Waybar/Pulsar antigos ainda rodando e se o SwayNC não está disputando `org.freedesktop.Notifications` com o Quickshell. Pare apenas os componentes legados que você identificar; não encerre um bloqueador enquanto a sessão estiver bloqueada.

## Primeiro uso

1. Confira `hyprctl configerrors` e abra a central com `Super + C`.
2. Escolha Claro, Escuro ou Adaptativo na aba Geral.
3. Abra Monitores com `Super + Shift + D`, organize as telas e teste a configuração. Ela só é salva ao clicar em **Manter**.
4. Abra a personalização com `Super + T` para escolher seu wallpaper e tema do Kitty. Não são copiadas fotos ou seleções particulares do computador do autor.
5. Confira o bloqueador com `rice-lock --preview`. Essa janela é apenas uma prévia; o bloqueio real usa `Super + L`.

O significado de Principal no editor é preferência do rice e tela inicial do cursor. Regras de workspaces e nomes de conectores são configurados em `.config/hypr/configs/monitors.lua`; ajuste o perfil de exemplo ao seu equipamento quando necessário.

As alterações de monitor têm reversão automática após 20 segundos sem confirmação. O watchdog roda fora da interface; fechar ou recarregar o Quickshell não cancela essa proteção.

## Voltar a uma configuração anterior

Use os arquivos do diretório de backup criado pela instalação para restaurar os componentes desejados. A cópia preserva os caminhos relativos ao diretório do usuário. Compare os arquivos antes de substituir preferências feitas depois da instalação.

Se voltar ao bloqueio antigo, restaure também o atalho, o autostart e os botões que chamam `rice-lock`. Depois desabilite a ponte nova:

```sh
systemctl --user disable --now rice-lock-bridge.service
```

Se voltar a outro servidor de notificações, pare a configuração `control-center`, remova a ativação D-Bus do Quickshell e só então inicie o servidor escolhido. Não mantenha dois servidores de notificações concorrentes.

## O que foi validado

A atualização do instalador é verificada com análise de sintaxe, modo de simulação e verificações dos arquivos que seriam instalados. Isso não substitui uma instalação completa numa máquina de destino. O bloqueador teve seu carregamento e visual validados sem assumir a sessão; autenticação real, suspensão/retomada e hotplug durante o bloqueio continuam exigindo teste interativo.
