# ─────────────────────────────────────────────
#  HISTÓRICO
# ─────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS       # ignora duplicatas consecutivas
setopt HIST_IGNORE_ALL_DUPS   # remove duplicatas antigas
setopt HIST_FIND_NO_DUPS      # não mostra duplicatas na busca
setopt HIST_IGNORE_SPACE      # comandos com espaço na frente não são salvos
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY          # compartilha histórico entre terminais abertos
setopt INC_APPEND_HISTORY     # salva imediatamente, não só ao fechar


# ─────────────────────────────────────────────
#  AUTOCOMPLETION
# ─────────────────────────────────────────────
autoload -Uz compinit && compinit

setopt MENU_COMPLETE           # completa direto o primeiro match
setopt AUTO_LIST               # lista opções automaticamente
setopt COMPLETE_IN_WORD        # completa mesmo no meio da palavra
setopt ALWAYS_TO_END           # move cursor pro fim após completar

# Navegação no menu de completion com setas
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{cyan}── %d%f'
zstyle ':completion:*' group-name ''

# Cache de completion (mais rápido)
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache


# ─────────────────────────────────────────────
#  OPÇÕES GERAIS
# ─────────────────────────────────────────────
setopt AUTO_CD           # digita o nome da pasta sem cd
setopt CORRECT           # sugere correção de comandos errados
setopt NO_BEEP           # sem bip
setopt EXTENDED_GLOB     # glob mais poderoso


# ─────────────────────────────────────────────
#  PLUGINS
# ─────────────────────────────────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zsh-history-substring-search (instalar: yay -S zsh-history-substring-search)
# Permite buscar histórico digitando parte do comando + seta pra cima
if [[ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
  bindkey '^[[A' history-substring-search-up    # seta cima
  bindkey '^[[B' history-substring-search-down  # seta baixo
fi

# zsh-you-should-use (instalar: yay -S zsh-you-should-use)
# Lembra você quando existe um alias pro comando que digitou
if [[ -f /usr/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh ]]; then
  source /usr/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
fi

# Sugestões em cinza mais visíveis
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555555'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Aceita sugestão com Ctrl+Space ou →
bindkey '^ ' autosuggest-accept
bindkey '^[[C' autosuggest-accept


# ─────────────────────────────────────────────
#  ALIASES — Navegação
# ─────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# ─────────────────────────────────────────────
#  ALIASES — Listagem (requer eza: yay -S eza)
# ─────────────────────────────────────────────
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --group-directories-first --git'
  alias lt='eza --tree --icons --level=2'
  alias ltt='eza --tree --icons --level=3'
else
  alias ls='ls --color=auto'
  alias ll='ls -lahF --color=auto'
fi

# ─────────────────────────────────────────────
#  ALIASES — Git
# ─────────────────────────────────────────────
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gst='git stash'
alias gstp='git stash pop'

# ─────────────────────────────────────────────
#  ALIASES — Sistema (Arch)
# ─────────────────────────────────────────────
alias pacs='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacu='sudo pacman -Syu'
alias pacq='pacman -Q | grep'
alias yays='yay -S'
alias yayu='yay -Syu'

alias please='sudo'
alias sudo='sudo '          # aliases funcionam com sudo

alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'           # pede confirmação ao deletar vários arquivos

# ─────────────────────────────────────────────
#  ALIASES — Misc
# ─────────────────────────────────────────────
alias cls='clear'
alias reload='source ~/.zshrc && echo "zshrc recarregado ✓"'
alias zshrc='$EDITOR ~/.zshrc'
alias ip='ip -c'            # ip com cores


# ─────────────────────────────────────────────
#  FUNÇÕES ÚTEIS
# ─────────────────────────────────────────────

# Cria pasta e entra nela
mkcd() { mkdir -p "$1" && cd "$1" }

# Extrai qualquer arquivo comprimido
extract() {
  case "$1" in
    *.tar.gz|*.tgz)   tar xzf "$1"   ;;
    *.tar.bz2|*.tbz2) tar xjf "$1"   ;;
    *.tar.xz)         tar xJf "$1"   ;;
    *.tar)            tar xf  "$1"   ;;
    *.zip)            unzip   "$1"   ;;
    *.7z)             7z x    "$1"   ;;
    *.rar)            unrar x "$1"   ;;
    *.gz)             gunzip  "$1"   ;;
    *.bz2)            bunzip2 "$1"   ;;
    *)  echo "Formato não reconhecido: $1" ;;
  esac
}

# Busca rápida de arquivo por nome
ff() { find . -iname "*$1*" 2>/dev/null }

# Mostra as portas em uso
ports() { ss -tulnp }


# ─────────────────────────────────────────────
#  PROMPT
# ─────────────────────────────────────────────
autoload -Uz colors && colors
autoload -Uz vcs_info         # info de git nativa do zsh

setopt PROMPT_SUBST

# Configura vcs_info para mostrar branch do git
zstyle ':vcs_info:git:*' formats '%F{yellow} %b%f'
zstyle ':vcs_info:*' enable git

precmd() { vcs_info }        # atualiza antes de cada prompt

# Seta fica vermelha se o último comando falhou
_prompt_symbol() {
  if [[ $? -eq 0 ]]; then
    echo '%F{green}❯%f'
  else
    echo '%F{red}❯%f'
  fi
}

PROMPT='
%F{cyan}%~%f${vcs_info_msg_0_}
$(_prompt_symbol) '


# ─────────────────────────────────────────────
#  FASTFETCH 
# ─────────────────────────────────────────────
if [[ $- == *i* ]]; then
    #To Install pokemon-colorscripts:
    #yay -S pokemon-colorscripts-git
    #pokemon-colorscripts -r -s --no-title

    fastfetch
fi
