#!/usr/bin/env zsh
#
# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.

# Use brew from PATH, or standard locations (Apple Silicon vs Intel)
if command -v brew >/dev/null 2>&1; then
  BREW_COMMAND=$(command -v brew)
elif [ -x /opt/homebrew/bin/brew ]; then
  BREW_COMMAND=/opt/homebrew/bin/brew
else
  BREW_COMMAND=/usr/local/bin/brew
fi

# Check for Homebrew
if test ! $(which brew)
then
  sudo xcodebuild -license
  xcode-select -p
  if [[ "$?" -eq "2" ]]; then
    sudo xcode-select --install
    echo
    echo "Please install 'Command Line Tools for Xcode' (follow instructions on window prompt)"
    echo
    echo "Press any key to continue…"
    read
  fi
  echo "  Installing Homebrew for you."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

if ! ${BREW_COMMAND} bundle --file=${HOME}/.dotfiles/homebrew/Brewfile install; then
  echo "Warning: brew bundle had failures (e.g. missing formula). Fix Brewfile and run: brew bundle --file=~/.dotfiles/homebrew/Brewfile"
fi

# git_version=$(git --version | grep git | cut -d ' ' -f3)
# curl https://raw.githubusercontent.com/git/git/v${git_version}/contrib/completion/git-completion.zsh -o ${HOME}/.dotfiles/functions/_git > /dev/null 2>&1
# if [[ "$?" -eq "0" ]]; then
#   echo
#   echo "git zsh autocompletion installed from source"
#   echo
# fi

touch "${HOME}/.tmux.conf.local"

exit 0
