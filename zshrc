# dotfiles/zshrc
DOTFILES_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"

# 1. Oh My Zsh prerequisites
export ZSH="$HOME/.oh-my-zsh"
zstyle ':omz:update' mode auto
ZSH_THEME="dst"
export EDITOR='vim'
export VISUAL='vim'
plugins=(
  git
  docker
  kubectl
  macos
  brew
  web-search
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# 2. Boot Oh My Zsh
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# 3. Source all cross-platform (.sh) and Zsh-only (.zsh) modules
setopt globstar nullglob
for f in "$DOTFILES_DIR/src"/**/*.sh "$DOTFILES_DIR/src"/**/*.zsh; do
  [ -r "$f" ] && . "$f"
done

# Local version of .zshrc, unconnected to dotfiles repository
[ -r "$HOME/.zshrc.local" ] && . "$HOME/.zshrc.local"

unset f