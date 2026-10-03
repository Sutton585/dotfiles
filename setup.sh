#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper function to convert an existing RC file into .local and symlink repo file
link_rc_file() {
  local src="$1"       # e.g., "$DOTFILES_DIR/zshrc"
  local target="$2"    # e.g., "$HOME/.zshrc"
  local local_rc="$3"  # e.g., "$HOME/.zshrc.local"

  # If target is already a symlink, check if it points to our dotfiles
  if [ -L "$target" ]; then
    echo "Symlink already exists for $target"
    ln -sf "$src" "$target"
    return 0
  fi

  # If target is a real file, migrate it to .local
  if [ -f "$target" ]; then
    if [ ! -f "$local_rc" ]; then
      echo "Migrating existing $target -> $local_rc"
      mv "$target" "$local_rc"
    else
      echo "Warning: $local_rc already exists. Backing up $target to ${target}.bak"
      mv "$target" "${target}.bak"
    fi
  fi

  # Create the canonical symlink
  ln -sf "$src" "$target"
  echo "Linked $target -> $src"
}

# ---------------------------------------------------------
# 1. macOS / Zsh Provisioning
# ---------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]] || [ -n "$ZSH_VERSION" ]; then
  echo "==> Setting up macOS / Zsh environment..."

  # Install Oh My Zsh if missing
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # OMZ backs up existing .zshrc to ~/.zshrc.pre-oh-my-zsh during unattended install.
    # If present, migrate THAT original user config to ~/.zshrc.local
    if [ -f "$HOME/.zshrc.pre-oh-my-zsh" ] && [ ! -f "$HOME/.zshrc.local" ]; then
      echo "Recovering pre-OMZ config -> $HOME/.zshrc.local"
      mv "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc.local"
    fi

    # Remove the generic template OMZ just placed at ~/.zshrc so our symlink takes over
    rm -f "$HOME/.zshrc"
  fi

  # Clone external plugins if missing
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

  # Link repo zshrc -> ~/.zshrc (and preserve existing config into ~/.zshrc.local)
  link_rc_file "$DOTFILES_DIR/zshrc" "$HOME/.zshrc" "$HOME/.zshrc.local"
fi

# ---------------------------------------------------------
# 2. Linux / Bash Provisioning
# ---------------------------------------------------------
if [[ "$OSTYPE" == "linux"* ]] || [ -n "$BASH_VERSION" ]; then
  echo "==> Setting up Linux / Bash environment..."

  # Link repo bashrc -> ~/.bashrc (and preserve existing config into ~/.bashrc.local)
  link_rc_file "$DOTFILES_DIR/bashrc" "$HOME/.bashrc" "$HOME/.bashrc.local"
fi

echo "==> Setup complete! Reload your shell to apply."