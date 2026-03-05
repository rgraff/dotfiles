#!/usr/bin/env zsh
#
# Install Oh My Zsh. Keeps existing .zshrc (managed by dotfiles).
# Run via: script/bootstrap or bin/dot
#

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "Oh My Zsh already installed at ~/.oh-my-zsh"
  exit 0
fi

echo "Installing Oh My Zsh..."
# Keep existing .zshrc so our dotfiles symlink is not replaced
KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "Oh My Zsh installed. Restart your shell or run: exec zsh"
else
  echo "Oh My Zsh install failed (e.g. no curl or network)."
  exit 1
fi
