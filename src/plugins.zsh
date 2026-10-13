# src/plugins.zsh - Sourced automatically only in Zsh via dotfiles.sh

# 1. zsh-autosuggestions
[ -r "$HOME/.local/share/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$HOME/.local/share/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# 2. zsh-syntax-highlighting (must always be loaded last)
[ -r "$HOME/.local/share/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "$HOME/.local/share/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
