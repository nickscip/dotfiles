#!/bin/bash

echo "Setting up your Mac"

DOTFILES="$HOME/Developer/Personal/dotfiles"

# Check for Oh My Zsh and install it if we don't have it
# (omz is a zsh function, so `which` can't see it from bash; RUNZSH=no stops the installer from exec'ing zsh mid-script)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
fi

# Symlinks the .zshrc to the .dotfiles (-f replaces the default one Oh My Zsh writes)
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

# TODO: Bootstrap the other config files

# ~/.zsh_secrets is not in this repo: copy it over from the old machine by hand

# Run this last to load the new .zshrc in a fresh shell
exec zsh
