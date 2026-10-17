#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_LINE="[ -f \"$DOTFILES_DIR/dotfiles.sh\" ] && . \"$DOTFILES_DIR/dotfiles.sh\""

# Universal prefix resolver (defaults to empty string for standalone runs)
PREFIX="${LOG_PREFIX:-}"

log() {
  local extra=""
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    extra=$(printf '%*s' "$(( $1 * 2 ))" '')
    shift
  fi
  printf "%s%s%s\n" "$PREFIX" "$extra" "$*"
}

log "dotfiles initialization:"

# --- 1. Install CLI tools if missing ---
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v starship >/dev/null 2>&1; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null 2>&1
  log 1 "└─ starship: installed to ~/.local/bin"
else
  log 1 "└─ starship: already present (cached)"
fi

if ! command -v zoxide >/dev/null 2>&1; then
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh >/dev/null 2>&1
  log 1 "└─ zoxide: installed to ~/.local/bin"
else
  log 1 "└─ zoxide: already present (cached)"
fi

if ! command -v fzf >/dev/null 2>&1; then
  if [ ! -d "$HOME/.fzf" ]; then
    git clone --quiet --depth 1 --single-branch --no-tags https://github.com/junegunn/fzf.git "$HOME/.fzf" >/dev/null 2>&1
  fi
  "$HOME/.fzf/install" --bin --no-bash --no-zsh --no-fish >/dev/null 2>&1
  ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
  log 1 "└─ fzf: installed to ~/.local/bin"
else
  log 1 "└─ fzf: already present (cached)"
fi

if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
  BAT_VER="0.24.0"
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  case "$OS-$ARCH" in
    darwin-arm64)              TARGET="aarch64-apple-darwin" ;;
    darwin-x86_64)             TARGET="x86_64-apple-darwin" ;;
    linux-x86_64)              TARGET="x86_64-unknown-linux-musl" ;;
    linux-aarch64|linux-arm64) TARGET="aarch64-unknown-linux-musl" ;;
    *)                         TARGET="" ;;
  esac
  if [ -n "$TARGET" ]; then
    TMP="$(mktemp -d)"
    curl -sSL "https://github.com/sharkdp/bat/releases/download/v${BAT_VER}/bat-v${BAT_VER}-${TARGET}.tar.gz" | tar -xz -C "$TMP" 2>/dev/null || true
    find "$TMP" -name bat -type f -exec cp {} "$HOME/.local/bin/bat" \; 2>/dev/null || true
    chmod +x "$HOME/.local/bin/bat" 2>/dev/null || true
    rm -rf "$TMP"
  fi
  if command -v bat >/dev/null 2>&1; then
    log 1 "└─ bat: installed to ~/.local/bin"
  else
    log 1 "└─ bat: missing (install manually or put in ~/.local/bin)"
  fi
else
  log 1 "└─ bat: already present (cached)"
fi

# Clean up legacy Starship symlink (now loaded via STARSHIP_CONFIG in dotfiles.sh)
if [ -L "$HOME/.config/starship.toml" ]; then
  rm -f "$HOME/.config/starship.toml"
  log 1 "└─ legacy cleanup: removed obsolete ~/.config/starship.toml symlink"
fi

# --- 2. Set up isolated virtualenv for sanitize_md ---
VENV_DIR="$DOTFILES_DIR/src/sanitize_md/.venv"
if [ ! -d "$VENV_DIR" ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 -m venv "$VENV_DIR" >/dev/null 2>&1 || true
    if [ -x "$VENV_DIR/bin/pip" ]; then
      "$VENV_DIR/bin/pip" install --quiet mdformat mdformat-gfm >/dev/null 2>&1 || true
      log 1 "└─ sanitize_md: venv configured with mdformat"
    fi
  else
    log 1 "└─ sanitize_md: python3 not found (skipping venv)"
  fi
else
  log 1 "└─ sanitize_md: venv already present (cached)"
fi

# --- 3. Install Zsh plugins (if zsh is available) ---
if command -v zsh >/dev/null 2>&1; then
  ZSH_PLUGIN_DIR="$HOME/.local/share/zsh-plugins"
  mkdir -p "$ZSH_PLUGIN_DIR"
  plugins_installed=()

  if [ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]; then
    git clone --quiet --depth 1 --single-branch --no-tags https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_PLUGIN_DIR/zsh-autosuggestions" >/dev/null 2>&1
    plugins_installed+=("autosuggestions")
  fi

  if [ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    git clone --quiet --depth 1 --single-branch --no-tags https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" >/dev/null 2>&1
    plugins_installed+=("syntax-highlighting")
  fi

  if [ ! -d "$ZSH_PLUGIN_DIR/zsh-completions" ]; then
    git clone --quiet --depth 1 --single-branch --no-tags https://github.com/zsh-users/zsh-completions.git "$ZSH_PLUGIN_DIR/zsh-completions" >/dev/null 2>&1
    plugins_installed+=("completions")
  fi

  if [ ${#plugins_installed[@]} -gt 0 ]; then
    log 1 "└─ zsh plugins: installed ${plugins_installed[*]} [ready]"
  else
    log 1 "└─ zsh plugins: autosuggestions, syntax-highlighting, completions [cached]"
  fi
else
  log 1 "└─ zsh plugins: skipped (zsh not installed)"
fi

# --- 4. Idempotently inject source line into RC files ---
inject_source() {
  local rc_file="$1"
  local name
  name="$(basename "$rc_file")"
  touch "$rc_file"
  if ! grep -Fq "$DOTFILES_DIR/dotfiles.sh" "$rc_file"; then
    echo -e "\n# Load dotfiles\n$SOURCE_LINE" >> "$rc_file"
    log 1 "└─ shell rc: injected dotfiles source into ~/$name"
  else
    log 1 "└─ shell rc: source line already present in ~/$name"
  fi
}

# Inject into active user shells
if [ -f "$HOME/.zshrc" ] || [[ "$SHELL" == *"zsh"* ]]; then
  inject_source "$HOME/.zshrc"
fi

if [ -f "$HOME/.bashrc" ] || [[ "$SHELL" == *"bash"* ]]; then
  inject_source "$HOME/.bashrc"
fi

# Reload recommendation
reload_cmd="exec zsh"
if [[ "$SHELL" == *"bash"* ]] && [ ! -f "$HOME/.zshrc" ]; then
  reload_cmd="source ~/.bashrc"
fi

log ""
log "Setup complete: reload shell with '$reload_cmd'"