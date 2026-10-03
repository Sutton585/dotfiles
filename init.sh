#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------
# 1. macOS / Zsh Provisioning
# ---------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]] || [ -n "$ZSH_VERSION" ]; then
  echo "==> Setting up macOS / Zsh environment..."

  # Install Oh My Zsh if missing
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  # Clone external plugins if missing
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

  # Overwrite ~/.zshrc with a symlink to dotfiles/zshrc
  ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
  echo "Linked ~/.zshrc -> $DOTFILES_DIR/zshrc"
fi

# ---------------------------------------------------------
# 2. Linux / Bash Provisioning
# ---------------------------------------------------------
if [[ "$OSTYPE" == "linux"* ]] || [ -f "$HOME/.bashrc" ]; then
  echo "==> Setting up Linux / Bash environment..."

  # Overwrite ~/.bashrc with a symlink to dotfiles/bashrc
  ln -sf "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"
  echo "Linked ~/.bashrc -> $DOTFILES_DIR/bashrc"
fi

echo "==> Setup complete! Reload your shell to apply."