
if [[ $- == *i* ]]; then
  fastfetch	

  #To Install pokemon-colorscripts:
  #yay -S pokemon-colorscripts-git
  #pokemon-colorscripts -r -s --no-title
  
fi

# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Prompt minimalista
autoload -Uz colors && colors

setopt PROMPT_SUBST

PROMPT='
%F{cyan}%~%f
%F{green}❯%f '
