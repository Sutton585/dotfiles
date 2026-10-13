#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_LINE="[ -f \"$DOTFILES_DIR/dotfiles.sh\" ] && . \"$DOTFILES_DIR/dotfiles.sh\""

# --- 1. Install CLI tools if missing ---
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v starship >/dev/null 2>&1; then
  echo "==> Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

if ! command -v zoxide >/dev/null 2>&1; then
  echo "==> Installing Zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

if ! command -v fzf >/dev/null 2>&1; then
  echo "==> Installing FZF..."
  if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 --single-branch --no-tags https://github.com/junegunn/fzf.git "$HOME/.fzf"
  fi
  "$HOME/.fzf/install" --bin --no-bash --no-zsh --no-fish
  ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
fi

# --- 2. Install Zsh plugins (if zsh is available) ---
if command -v zsh >/dev/null 2>&1; then
  ZSH_PLUGIN_DIR="$HOME/.local/share/zsh-plugins"
  mkdir -p "$ZSH_PLUGIN_DIR"

  if [ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]; then
    echo "==> Installing zsh-autosuggestions..."
    git clone --depth 1 --single-branch --no-tags https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
  fi

  if [ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    echo "==> Installing zsh-syntax-highlighting..."
    git clone --depth 1 --single-branch --no-tags https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
  fi
fi

# --- 3. Link Starship configuration ---
if [ -f "$DOTFILES_DIR/src/starship.toml" ]; then
  mkdir -p "$HOME/.config"
  ln -sf "$DOTFILES_DIR/src/starship.toml" "$HOME/.config/starship.toml"
  echo "==> Linked starship.toml -> $HOME/.config/starship.toml"
fi

# --- 4. Idempotently inject source line into RC files ---
inject_source() {
  local rc_file="$1"
  touch "$rc_file"
  if ! grep -Fq "$DOTFILES_DIR/dotfiles.sh" "$rc_file"; then
    echo -e "\n# Load dotfiles\n$SOURCE_LINE" >> "$rc_file"
    echo "==> Injected dotfiles source line into $rc_file"
  else
    echo "==> Dotfiles source line already present in $rc_file"
  fi
}

# Inject into active user shells
if [ -f "$HOME/.zshrc" ] || [[ "$SHELL" == *"zsh"* ]]; then
  inject_source "$HOME/.zshrc"
fi

if [ -f "$HOME/.bashrc" ] || [[ "$SHELL" == *"bash"* ]]; then
  inject_source "$HOME/.bashrc"
fi

echo "==> Setup complete! Reload your shell to apply."