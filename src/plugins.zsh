# src/plugins.zsh - Sourced automatically in Zsh via dotfiles.sh
#alias ls='ls -vhFA --color=auto'
alias ls='ls -vhFAG'

for _dir in \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share" \
  "/usr/local/share" \
  "$HOME/.local/share/zsh-plugins"; do

  # 1. Additional completions (must be added to fpath before compinit)
  if [ -z "$_comp_loaded" ]; then
    if [ -d "$_dir/zsh-completions/src" ]; then
      fpath=("$_dir/zsh-completions/src" $fpath)
      _comp_loaded=1
    elif [ -d "$_dir/zsh-completions" ]; then
      fpath=("$_dir/zsh-completions" $fpath)
      _comp_loaded=1
    fi
  fi

  # 2. Autosuggestions
  [ -z "$_as_loaded" ] && [ -r "$_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && {
    source "$_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
    _as_loaded=1
  }

  # 3. Syntax Highlighting (must be loaded last)
  [ -z "$_sh_loaded" ] && [ -r "$_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && {
    source "$_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    _sh_loaded=1
  }
done

# Initialize Zsh completion system (-C for fast cached load, -i fallback to ignore insecure dir warnings)
autoload -Uz compinit
compinit -C 2>/dev/null || compinit -i 2>/dev/null

unset _dir _as_loaded _sh_loaded _comp_loaded
