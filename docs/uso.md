# Uso da interface

## Barra e central

A central abre com `Super + C` ou pela engrenagem. Os botões de volume, rede, Bluetooth e bateria abrem a seção correspondente; o destaque acompanha o botão selecionado. `Esc`, o botão de fechar ou um clique fora fecham o painel.

Em **Som**, selecione a saída ou entrada de áudio. Aplicativos que reproduzem áudio aparecem com volume próprio e mute. A roda sobre o volume da barra ajusta em passos de 5%; as teclas de volume e brilho exibem um OSD sem capturar o foco.

O brilho controla a tela interna do notebook. Wi-Fi pessoal pode ser conectado pelo painel; redes empresariais, VPN e ajustes de IP ficam no editor avançado do NetworkManager. O Bluetooth pede confirmação de PIN/código quando necessário.

O botão de energia abre um menu compacto com bloquear, suspender, reiniciar, desligar e sair da sessão. As ações de sessão pedem confirmação. A aba Energia mantém as informações da bateria e os perfis disponíveis no sistema.

## Workspaces e programas

O destaque desliza entre o workspace ou programa ativo. Clique em um ícone de aplicativo para ativá-lo; clique do meio fecha a janela.

Clique direito nos números dos workspaces para abrir a visão geral. Ela mostra **representações da disposição das janelas**, com ícones e títulos, sem capturar o conteúdo. Clique na prévia ou use setas e `Enter` para trocar; `Esc` fecha.

O layout de exemplo reserva os workspaces 1–5 para HDMI e 6–10 para o notebook. Os nomes das saídas e essas regras ficam em `.config/hypr/configs/monitors.lua`; adapte-os ao seu equipamento. Com apenas uma tela, a barra pode mostrar os workspaces existentes de 1 a 10.

## Calendário e player

Clique no relógio para abrir o calendário na mesma tela. Setas navegam pelos dias; `Page Up`/`Page Down` mudam o mês e `Home` volta para hoje. A roda do mouse e os botões do calendário também mudam o mês.

O cartão de música usa os players MPRIS disponíveis. Clique em qualquer parte do cartão para abrir o player horizontal; os botões de reprodução continuam independentes. A visão dedicada traz capa, artista, título, controles e barras com o nível real da saída de áudio. Elas não são um espectro de frequências e podem refletir outros sons reproduzidos nessa saída.

A seta volta ao calendário. `Esc` no player também volta; no calendário, fecha o painel. O monitor de áudio só fica ativo enquanto a visão dedicada está aberta e há reprodução.

## Notificações e comandos

O sino dentro da central abre o histórico e o botão Não perturbe. Clicar no corpo de uma notificação executa a ação principal oferecida pelo aplicativo. As ações secundárias e o botão de dispensar permanecem separados. O histórico é da sessão: recarregar o QML o preserva, mas reiniciar o processo o limpa.

Clique esquerdo no ícone da distro para pesquisar os atalhos ativos do Hyprland. Esse menu mostra os comandos e suas teclas; não é um terminal. Clique direito no ícone abre o Rofi para aplicativos.

## Temas e personalização

Escolha o tema em **Geral → Tema da interface** ou em **Personalizar**:

- **Claro:** vidro claro translúcido.
- **Escuro:** vidro em carvão frio, sem contornos claros.
- **Adaptativo:** vidro tingido e destaques extraídos do wallpaper.

A escolha vale para barra, painéis, calendário, notificações, comandos, OSDs e Rofi. No bloqueador, a escolha é lida na próxima abertura. O configurador de monitores usa um fundo mais opaco para manter a leitura.

`Super + T` abre a personalização; `Super + W` vai direto aos wallpapers. As categorias são:

| Categoria | Origem e efeito |
| --- | --- |
| Wallpaper | Imagens em `~/Pictures/Wallpaper`, aplicadas pelo awww |
| Tela de login | Atualiza o fundo do tema Astronaut, com autenticação Polkit |
| Fastfetch | Imagens em `~/.config/fastfetch/icons` ou logo automático da distro |
| Kitty | Temas `.conf` em `~/.config/kitty` e opção Adaptativo |

Um clique seleciona; **duplo clique**, `Enter` ou Aplicar aplica a escolha. Use setas para navegar, `Tab` para alternar áreas, `Ctrl + F` para buscar e `Ctrl + R` para atualizar. `Esc` limpa a busca ou fecha o seletor.

O Adaptativo do Kitty é uma escolha independente do tema da interface. Quando selecionado, gera fundo, texto, cursor, seleções, abas e as 16 cores ANSI a partir do wallpaper, atualizando as janelas abertas do Kitty. Assim, as bolinhas do módulo `colors` do Fastfetch acompanham a paleta do terminal.

## Monitores

Abra em **Geral → Monitores**, com `Super + Shift + D`, pelo aplicativo Monitores no Rofi ou executando `rice-monitors`.

Selecione uma tela no diagrama e arraste para posicionar à esquerda, direita, acima ou abaixo da outra. As telas se encaixam nas bordas e não podem se sobrepor. Use os seletores para resolução, frequência e escala. **Principal** define a preferência salva e a tela inicial do cursor; não muda o foco atual nem transfere os workspaces.

**Testar alterações** aplica uma prévia. Clique em **Manter** para salvar ou **Reverter** para restaurar. Após 20 segundos sem confirmação, um processo independente reverte o layout, mesmo se a interface fechar. O editor não oferece espelhamento nem desligamento de saídas.

## Bloqueio

`Super + L` e o botão Bloquear iniciam `rice-lock`. A tela mostra o wallpaper, data, relógio e bateria. Clique com o mouse ou comece a digitar para revelar o campo; apenas mover o mouse não ativa a senha. O campo vazio volta ao repouso após oito segundos sem autenticação ou erro pendente.

A tela não mostra nome ou avatar. O campo não tem o texto “Senha”; mensagens de erro aparecem numa cápsula com fundo legível. A autenticação é feita pelo PAM do sistema. Ao interagir com outro monitor, o campo anterior é limpo. `Esc` limpa a entrada e volta ao repouso, sem desbloquear.

Para conferir o visual sem bloquear a sessão:

```sh
rice-lock --preview
```

A prévia não autentica. Nela, `Esc` fecha a janela. Para conferir o estado real, use `rice-lock --status`. O comando `rice-lock --suspend`, usado pelo menu de energia, só solicita suspensão após confirmar o bloqueio no compositor.
