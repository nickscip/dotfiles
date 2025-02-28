#!/bin/bash

echo "Setting up your Mac"

# Check for Oh My Zsh and install it if we don't have it
if test ! "$(which omz)"; then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
fi

# Symlinks the .zshrc to the .dotfiles
ln -sw "$HOME/dotfiles/.zshrc" "$HOME/.zshrc"

# Check for Homebrew and install it if we don't have it
if test ! "$(which brew)"; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle --file ./Brewfile

# Create a projects directory
mkdir "$HOME/Developer"

# TODO: Bootstrap the other config files

# Run this last to source ZSH changes and reload the shell
source ./.zshrc
