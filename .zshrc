# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git direnv rust git-commit vi-mode thefuck zsh-syntax-highlighting git-prompt fzf)

source $ZSH/oh-my-zsh.sh

# User configuration

# Setting up python path
export PATH="/usr/local/bin:$PATH"

# Setting up poetry
export PATH="$HOME/.local/bin:$PATH"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('~/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "~/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "~/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="~/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
export PATH="/usr/local/opt/openjdk@17/bin:$PATH"
eval $(thefuck --alias fuck)

alias reload="source ~/.zshrc"
alias acc="source .venv/bin/activate"
alias deac="deactivate"
alias gs="git status --short"

alias snowsql=/Applications/SnowSQL.app/Contents/MacOS/snowsql

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform

# AWS profile switcher with SSO login by default
function awsp() {
    # Pick a profile. If you cancel, this won't force a login
    local choice
    choice=$(aws configure list-profiles | fzf --prompt "Choose active AWS profile:") || return
    export AWS_PROFILE="${choice:-default}"

    echo "Switching to profile: $AWS_PROFILE"
    if ! aws sts get-caller-identity --profile $AWS_PROFILE > /dev/null 2>&1; then
      echo "Not logged in. Running 'aws sso login --profile $AWS_PROFILE'..."
      aws sso login --profile $AWS_PROFILE
    fi
}

function aws_prof {
  local profile="${AWS_PROFILE:=default}"

  echo "%{$fg_bold[blue]%}aws:(%{$fg[yellow]%}${profile}%{$fg_bold[blue]%})%{$reset_color%} "
}
PROMPT='%F{green}%~%f $(aws_prof)'

alias mydir="cd ~/Developer/Personal/"
alias workdir="cd ~/Developer/Work/"
fpath+=/opt/homebrew/share/zsh/site-functions
autoload -Uz compinit && compinit

# Alias terramate
tm() {
  if [[ "$1" == "gen" ]]; then
    shift
    terramate generate "$@"
  else
    terramate "$@"
  fi
}

source "$HOME/.rye/env"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
export FZF_BASE=/path/to/fzf/install/dir
