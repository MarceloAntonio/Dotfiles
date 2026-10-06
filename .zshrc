export CHROME_EXECUTABLE=/usr/bin/chromium
export ANDROID_HOME="$HOME/Android/Sdk"
typeset -U path
path=(
  $HOME/.local/bin
  $HOME/.cargo/bin
  $HOME/flutter/bin
  $ANDROID_HOME/cmdline-tools/latest/bin
  $ANDROID_HOME/platform-tools
  $ANDROID_HOME/emulator
  $path
  $HOME/.spicetify
)

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
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
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
setopt AUTO_CD
setopt NO_BEEP
setopt EXTENDED_GLOB
bindkey '^[[3~' delete-char
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
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
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
else
  alias ls='ls --color=auto'
fi

if command -v bat &>/dev/null; then
  alias cat='bat'
fi
alias reload='source ~/.zshrc && echo "zshrc recarregado ✓"'
command -v codium &>/dev/null && alias code='codium'
alias vim='nvim'
[[ $- == *i* ]] && fastfetch

eval "$(starship init zsh)"
