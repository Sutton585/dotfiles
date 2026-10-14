# src/plugins.zsh - Sourced automatically in Zsh via dotfiles.sh

for _dir in \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share" \
  "/usr/local/share" \
  "$HOME/.local/share/zsh-plugins"; do

  # 1. Autosuggestions
  [ -z "$_as_loaded" ] && [ -r "$_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && {
    source "$_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
    _as_loaded=1
  }

  # 2. Syntax Highlighting (must be loaded last)
  [ -z "$_sh_loaded" ] && [ -r "$_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && {
    source "$_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    _sh_loaded=1
  }
done

unset _dir _as_loaded _sh_loaded
