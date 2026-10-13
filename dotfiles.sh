# dotfiles.sh - Unified entrypoint for Zsh and Bash

# 1. Determine dotfiles directory and current shell
if [ -n "$ZSH_VERSION" ]; then
  CURRENT_SHELL="zsh"
  DOTFILES_DIR="${${(%):-%N}:A:h}"
  setopt null_glob
elif [ -n "$BASH_SOURCE" ]; then
  CURRENT_SHELL="bash"
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  shopt -s globstar nullglob
fi

# Ensure ~/.local/bin is in PATH for starship, zoxide, fzf
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"

# 2. Initialize CLI tools (Starship, Zoxide, FZF)
command -v starship >/dev/null && eval "$(starship init "$CURRENT_SHELL")"
command -v zoxide   >/dev/null && eval "$(zoxide init "$CURRENT_SHELL")"

if command -v fzf >/dev/null; then
  eval "$(fzf --"$CURRENT_SHELL" 2>/dev/null)" || true
fi

# 3. Source all cross-platform (.sh) modules
for f in "$DOTFILES_DIR/src"/**/*.sh; do
  [ -r "$f" ] && . "$f"
done

# 4. Source shell-specific modules (.zsh for Zsh, .bash for Bash)
for f in "$DOTFILES_DIR/src"/**/*."$CURRENT_SHELL"; do
  [ -r "$f" ] && . "$f"
done

unset f
