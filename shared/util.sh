# cleanup [dir]  Remove macOS junk (.DS_Store, ._*, .AppleDouble) under dir (default .)
cleanup() {
  local target="${1:-.}"
  [ -d "$target" ] || { echo "cleanup: not a directory: $target"; return 1; }
  local abs
  abs="$(cd "$target" && pwd)"
  echo "Cleaning $abs"
  find "$target" \( -name .DS_Store -o -name '._*' -o -name .AppleDouble \) \
    -not -path '*/.git/*' -print -delete
}

# reload  Start a fresh shell so rc changes take effect
alias reload='exec "$SHELL"'
