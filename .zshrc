# --- Shell basics (what oh-my-zsh used to set up) ---

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history hist_expire_dups_first hist_ignore_dups hist_ignore_space hist_verify share_history

# Directories, completion and job behavior
setopt auto_cd auto_pushd pushd_ignore_dups pushd_minus
setopt always_to_end complete_in_word interactive_comments long_list_jobs prompt_subst
unsetopt flow_control

# Colors: $fg/$reset_color for the prompt, ls and grep output
autoload -U colors && colors
export CLICOLOR=1 LSCOLORS="Gxfxcxdxbxegedabagacad"
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'

# Completion (case-insensitive, arrow-key menu)
fpath+=/opt/homebrew/share/zsh/site-functions
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors ''

# Vi mode, with a 10ms Esc delay instead of zsh's default 400ms
bindkey -v
KEYTIMEOUT=1
bindkey '^?' backward-delete-char # backspace past where insert mode started
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^p' up-history
bindkey '^n' down-history
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
autoload -Uz edit-command-line up-line-or-beginning-search down-line-or-beginning-search
zle -N edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^x^e' edit-command-line
# Up/Down search history for lines starting with what's already typed
for keymap in viins vicmd; do
  bindkey -M $keymap '^[[A' up-line-or-beginning-search
  bindkey -M $keymap '^[OA' up-line-or-beginning-search
  bindkey -M $keymap '^[[B' down-line-or-beginning-search
  bindkey -M $keymap '^[OB' down-line-or-beginning-search
done

# Auto-quote URLs when pasting
autoload -Uz bracketed-paste-magic url-quote-magic
zle -N bracketed-paste bracketed-paste-magic
zle -N self-insert url-quote-magic

eval "$(direnv hook zsh)"
alias gb="git branch"

# User configuration

# Setting up python path
export PATH="/opt/homebrew/bin:$PATH"
alias python="python3"

# Setting up poetry
export PATH="$HOME/.local/bin:$PATH"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$("$HOME/opt/miniconda3/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Atuin records history; Ctrl-R stays with fzf and Up with prefix search
eval "$(atuin init zsh --disable-up-arrow --disable-ctrl-r)"

export PATH="/usr/local/opt/openjdk@17/bin:$PATH"
# thefuck starts Python, so only load its alias the first time `fuck` is run
fuck() { eval "$(thefuck --alias fuck)" && fuck "$@"; }

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

# Git branch on the right, with ✚ when tracked files have changes (one git call per prompt)
function git_prompt {
  local line branch dirty
  for line in ${(f)"$(git status --porcelain=v2 --branch -uno 2>/dev/null)"}; do
    case $line in
      '# branch.head '*) branch=${line#\# branch.head } ;;
      '#'*) ;;
      *) dirty='|✚'; break ;;
    esac
  done
  [[ -n $branch ]] && echo "%{$fg_bold[blue]%}git:(%{$fg_bold[magenta]%}${branch}%{$fg_bold[blue]%}${dirty})%{$reset_color%}"
}
RPROMPT='$(git_prompt)'

alias mydir="cd ~/Developer/Personal/"
alias workdir="cd ~/Developer/Work/"

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

# Node versions via fnm: reads .nvmrc and switches on cd
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd --version-file-strategy=recursive --resolve-engines=false --shell zsh)"

# Load local environment variables/secrets if the file exists
if [ -f ~/.zsh_secrets ]; then
    source ~/.zsh_secrets
fi

# Add Docker CLI
export PATH="$PATH:$HOME/usr/local/bin"

# Add Rust
export PATH="$PATH:$HOME/.cargo/bin"

unset LESS

# claude refresh
alias op='npx opal-security'

# Configure Claude Code for Bedrock
export ANTHROPIC_MODEL='claude-opus-4-7'

# Amp CLI
export PATH="$HOME/.amp/bin:$PATH"

# Blend environment (added by blend-agents)
[ -f "$HOME/.blend_profile" ] && source "$HOME/.blend_profile"


export EDITOR=nvim

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

# Must stay last: highlights based on every widget defined above
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
