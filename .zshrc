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

# Listagem (eza com fallback)
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
else
  alias ls='ls --color=auto'
fi

# Atalhos
alias reload='source ~/.zshrc && echo "zshrc recarregado ✓"'



# ── Fastfetch ────────────────────────────────
[[ $- == *i* ]] && fastfetch

# Added by Antigravity CLI installer
export PATH="/home/celo/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH=$PATH:/home/celo/.spicetify

eval "$(starship init zsh)"
