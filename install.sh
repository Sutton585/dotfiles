#!/bin/sh
# Adds the loader line to each rc file that exists. Safe to re-run.
LINE='. "$HOME/dotfiles/init.sh"'
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$rc" ] || continue
  grep -qF "$LINE" "$rc" || { printf '\n%s\n' "$LINE" >> "$rc"; echo "added to $rc"; }
done
