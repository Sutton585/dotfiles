# Resolve physical repo directory through symlinks
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DOTFILES_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"


# Enable recursive globbing (**) and silent pass on empty matches
shopt -s globstar nullglob

# Source all cross-platform (.sh) and Bash-only (.bash) modules
for f in "$DOTFILES_DIR/src"/**/*.sh "$DOTFILES_DIR/src"/**/*.bash; do
  [ -r "$f" ] && . "$f"
done

# Local version of .bashrc that isn't connected to the dotfiles repository
[ -r "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"

unset f