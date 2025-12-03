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
    # 1. Get the current branch name
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ $? -ne 0 ]]; then
        echo "Error: Not on a branch (detached HEAD state)." >&2
        return 1
    fi

    # Parse arguments for target branch and -p flag
    local target_branch="main"
    local force_push=0
    local branch_arg_found=0

    # Loop through all provided arguments
    for arg in "$@"; do
        if [[ "$arg" == "-p" ]]; then
            force_push=1
        elif [[ "$arg" == -* ]]; then
            # Deny any other flags
            echo "Error: Unsupported flag $arg. Only -p is allowed." >&2
            return 1
        else
            # This is a positional argument (the branch name)
            if (( branch_arg_found == 1 )); then
                echo "Error: Multiple branch names specified." >&2
                return 1
            fi
            target_branch=$arg
            branch_arg_found=1
        fi
    done

    echo "--- Rebasing $current_branch onto $target_branch ---"

    # 2. Checkout to the supplied branch name
    echo "\n[1/5] Checking out $target_branch..."
    if ! git checkout "$target_branch"; then
        echo "Error: Could not check out $target_branch." >&2
        # Attempt to return to the original branch for safety
        git checkout "$current_branch"
        return 1
    fi

    # 3. Pull changes
    echo "\n[2/5] Pulling changes for $target_branch..."
    if ! git pull; then
        echo "Error: Could not pull $target_branch." >&2
        git checkout "$current_branch"
        return 1
    fi

    # 4. Checkout back to the current branch
    echo "\n[3/5] Checking out back to $current_branch..."
    if ! git checkout "$current_branch"; then
        echo "Error: Could not check out $current_branch." >&2
        return 1 # We're in a bad state, abort
    fi

    # 5. Run git rebase supplied branch name
    echo "\n[4/5] Rebasing $current_branch onto $target_branch..."
    if ! git rebase "$target_branch"; then
        echo "Error: Rebase failed. Conflicts likely." >&2
        echo "Please resolve conflicts and run 'git rebase --continue' or 'git rebase --abort'." >&2
        echo "Script halted. Push will NOT occur." >&2
        return 1
    fi

    echo "Rebase successful."

    # 6. If flag -p is added, push with -f
    if (( force_push == 1 )); then
        echo "\n[5/5] Force-pushing $current_branch with -f..."
        
        # ---
        # SAFETY WARNING: 'git push -f' is destructive.
        # 'git push --force-with-lease' is a much safer alternative
        # that checks if anyone else has pushed to the branch.
        # But, honoring the request for '-f'
        # ---
        if ! git push -f; then
            echo "Error: Force push failed." >&2
            return 1
        fi
        echo "Force push successful."
    else
        echo "\n[5/5] Rebase complete."
        echo "Run 'git push --force-with-lease' to update the remote branch."
    fi

    echo "--- Rebase complete ---"
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

export VAULT_ADDR=https://vault.sandbox.k8s.centrio.com:8200
function vault_token() {
    CLIENT_ID=`cat ~/.deployinator_api_key  | jq -r '."Client-Id"'`
    CLIENT_SECRET=`cat ~/.deployinator_api_key  | jq -r '."Client-Secret"'`
    export VAULT_TOKEN=`curl -X POST https://deployinator.sandbox.k8s.centrio.com/api/vault.tokens -H "Client-Id: ${CLIENT_ID}" -H "Client-Secret: ${CLIENT_SECRET}" | jq -r '.token'`
}

# Load local environment variables/secrets if the file exists
if [ -f ~/.zsh_secrets ]; then
    source ~/.zsh_secrets
fi
