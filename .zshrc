# ── Histórico ────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

# ── Autocompletion ───────────────────────────
autoload -Uz compinit && compinit

setopt MENU_COMPLETE
setopt AUTO_LIST
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{cyan}── %d%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# ── Opções gerais ────────────────────────────
setopt AUTO_CD
setopt CORRECT
setopt NO_BEEP
setopt EXTENDED_GLOB

# Keybindings — teclas que o zsh não mapeia por padrão
bindkey '^[[3~' delete-char       # Delete
bindkey '^[[H'  beginning-of-line # Home
bindkey '^[[F'  end-of-line       # End

# ── Plugins ──────────────────────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if [[ -f /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

if [[ -f /usr/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh ]]; then
  source /usr/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
fi

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555555'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^ ' autosuggest-accept
bindkey '^[^M' autosuggest-accept

# ── Aliases ──────────────────────────────────

# Navegação
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Listagem (eza com fallback)
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --group-directories-first --git'
  alias lt='eza --tree --icons --level=2'
  alias ltt='eza --tree --icons --level=3'
else
  alias ls='ls --color=auto'
  alias ll='ls -lahF --color=auto'
fi

# Git
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# Pacman / Yay
alias pacs='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacu='sudo pacman -Syu'
alias pacq='pacman -Q | grep'
alias yays='yay -S'
alias yayu='yay -Syu'

# Sistema
alias sudo='sudo '
alias df='df -h'
alias free='free -h'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias ip='ip -c'

# Atalhos
alias cls='clear'
alias reload='source ~/.zshrc && echo "zshrc recarregado ✓"'
alias zshrc='${EDITOR:-vim} ~/.zshrc'

# ── Funções ──────────────────────────────────

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

# Busca arquivo por nome
ff() { find . -iname "*$1*" 2>/dev/null }

# Portas em uso
ports() { ss -tulnp }

# ── Prompt ───────────────────────────────────
autoload -Uz colors && colors
autoload -Uz vcs_info

setopt PROMPT_SUBST

zstyle ':vcs_info:git:*' formats '%F{yellow} %b%f'
zstyle ':vcs_info:*' enable git

precmd() {
  _last_status=$?
  vcs_info
}

PROMPT='
%F{cyan}%~%f${vcs_info_msg_0_}
%(?.%F{green}❯%f.%F{red}❯%f) '

# ── Fastfetch ────────────────────────────────
[[ $- == *i* ]] && fastfetch

# Added by Antigravity CLI installer
export PATH="/home/celo/.local/bin:$PATH"
