# Loaded from ~/.bashrc / ~/.zshrc
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
for f in "$DOTFILES"/shared/*.sh; do [ -r "$f" ] && . "$f"; done
if [ -n "$BASH_VERSION" ]; then
  for f in "$DOTFILES"/bash/*.sh; do [ -r "$f" ] && . "$f"; done
elif [ -n "$ZSH_VERSION" ]; then
  for f in "$DOTFILES"/zsh/*.sh; do [ -r "$f" ] && . "$f"; done
fi
unset f
