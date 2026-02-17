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
plugins=(git direnv rust git-commit vi-mode git-prompt fzf)

source $ZSH/oh-my-zsh.sh
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# User configuration

# Setting up python path
export PATH="/opt/homebrew/bin:$PATH"
alias python="python3"

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

# Atuin configs
eval "$(atuin init zsh)"
export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"
bindkey '^r' atuin-search

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
function awp() {
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

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
export FZF_BASE=/path/to/fzf/install/dir

# psycopg2 config
export PATH="/usr/local/opt/libpq/bin:$PATH"

# kubectl alias
alias k="kubectl"

# pomodoro alias and pathing
alias po="pomodoro"
export PATH="$PATH:$HOME/go/bin"
export PATH="$HOME/.local/bin:$PATH"

alias ca="cursor-agent"
export AWS_DEFAULT_PROFILE=opal

# -----------------------------------------------------------------
# Custom Git Rebase Function
# -----------------------------------------------------------------
#
# This function automates the process of updating a target branch
# and rebasing the current feature branch onto it.
#
# Usage:
#   rb           (Updates 'main' and rebases current branch onto it)
#   rb develop   (Updates 'develop' and rebases current branch onto it)
#   rb -p        (Rebases onto 'main' AND force-pushes with -f)
#   rb -p develop (Rebases onto 'develop' AND force-pushes with -f)
#   rb develop -p (Same as above)
#
rb() {
    # 1. Get current branch name
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ $? -ne 0 ]]; then
        echo "Error: Not on a branch." >&2
        return 1
    fi

    # Parse arguments
    local target_branch="main"
    local force_push=0
    local branch_arg_found=0

    for arg in "$@"; do
        if [[ "$arg" == "-p" ]]; then
            force_push=1
        elif [[ "$arg" == -* ]]; then
            echo "Error: Unsupported flag $arg." >&2
            return 1
        else
            target_branch=$arg
            branch_arg_found=1
        fi
    done

    echo "--- Updating and Rebasing $current_branch onto origin/$target_branch ---"

    # 2. Fetch latest changes from remote (No checkout needed!)
    echo "\n[1/4] Fetching latest changes from origin..."
    if ! git fetch origin "$target_branch"; then
        echo "Error: Could not fetch $target_branch from origin." >&2
        return 1
    fi

    # 3. Fast-forward local target branch to match remote
    echo "\n[2/4] Updating local $target_branch to match origin/$target_branch..."
    if ! git branch -f "$target_branch" "origin/$target_branch" 2>/dev/null; then
        echo "Warning: Could not update local $target_branch (you may be on it or it may not exist locally). Continuing with rebase." >&2
    fi

    # 4. Rebase current branch onto the remote version of the target
    echo "\n[3/4] Rebasing $current_branch onto origin/$target_branch..."
    if ! git rebase "origin/$target_branch"; then
        echo "Error: Rebase failed. Resolve conflicts and continue manually." >&2
        return 1
    fi

    # 5. Handle Force Push
    if (( force_push == 1 )); then
        echo "\n[4/4] Force-pushing $current_branch..."
        # Using --force-with-lease as it's safer, but stays true to your -p intent
        if ! git push --force-with-lease; then
            echo "Error: Push failed." >&2
            return 1
        fi
        echo "Push successful."
    else
        echo "\n[4/4] Rebase complete."
        echo "Run 'git push --force-with-lease' to update remote."
    fi

    echo "--- Process Complete ---"
    return 0
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# place this after nvm initialization!
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc


# Load local environment variables/secrets if the file exists
if [ -f ~/.zsh_secrets ]; then
    source ~/.zsh_secrets
fi

# Add Docker CLI
export PATH="$PATH:$HOME/usr/local/bin"

# Add Rust
export PATH="$PATH:$HOME/.cargo/bin"

unset LESS

export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-east-1

# Amp CLI
export PATH="/Users/nscipione/.amp/bin:$PATH"
