#!/bin/bash

echo "Setting up your Mac"

# Check for Oh My Zsh and install it if we don't have it
if test ! "$(which omz)"; then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
fi

# Check fo rHomebrew and install it if we don't have it
# if test ! "$(which brew)"; then
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
#   echo "eval '$(/opt/homebrew/bin/brew shellenv)'" >> "$HOME/.zprofile"
#   eval "$(/opt/homebrew/bin/brew shellenv)"
# fi

# Symlinks the .zshrc to the .dotfiles
ln -sw "$HOME/.zshrc" "$HOME/dotfiles/.zshrc"
