#!/bin/bash

echo "Setting up your Mac"

DOTFILES="$HOME/Developer/Personal/dotfiles"

# Symlinks the .zshrc to the .dotfiles (-f replaces any existing one)
ln -sfw "$DOTFILES/.zshrc" "$HOME/.zshrc"

# Check for Homebrew and install it if we don't have it
if test ! "$(which brew)"; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew bundle --file "$DOTFILES/Brewfile"

# Create a projects directory
mkdir -p "$HOME/Developer/Work"

# Link app configs into ~/.config (an existing real folder is moved aside to <name>.bak)
mkdir -p "$HOME/.config"
for dir in atuin fish gh-copilot ghostty thefuck; do
  target="$HOME/.config/$dir"
  [ -d "$target" ] && [ ! -L "$target" ] && mv "$target" "$target.bak"
  ln -sfn "$DOTFILES/$dir" "$target"
done

# Neovim config lives in its own repo
[ -d "$HOME/.config/nvim" ] || git clone git@github.com:nickscip/nvim.git "$HOME/.config/nvim"

# Not in this repo, copy by hand if wanted: ~/.zsh_secrets (optional) and
# ~/.config/ghostty/sounds/bell.wav (licensed sound, gitignored)

# Run this last to load the new .zshrc in a fresh shell
exec zsh
