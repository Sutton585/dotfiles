# dotfiles/bashrc
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Enable recursive globbing (**) and silent pass on empty matches
shopt -s globstar nullglob

# Source all cross-platform (.sh) and Bash-only (.bash) modules
for f in "$DOTFILES_DIR/src"/**/*.sh "$DOTFILES_DIR/src"/**/*.bash; do
  [ -r "$f" ] && . "$f"
done

unset f