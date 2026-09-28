# git-sparse clone <url> <path>... | pull | add <path>...
git-sparse() {
  local cmd="$1"; shift
  case "$cmd" in
    clone)
      local url="$1"; shift
      [ -z "$url" ] || [ $# -eq 0 ] && { echo "usage: git-sparse clone <url> <path>..."; return 1; }
      local dir
      dir="$(basename "$url" .git)"
      git clone --depth=1 --filter=blob:none --sparse "$url" "$dir" || return 1
      git -C "$dir" sparse-checkout set --no-cone "$@"
      ;;
    pull) git fetch --depth=1 origin HEAD && git reset --hard FETCH_HEAD ;;
    add)
      [ $# -eq 0 ] && { echo "usage: git-sparse add <path>..."; return 1; }
      git sparse-checkout add "$@"
      ;;
    *) echo "usage: git-sparse clone|pull|add ..."; return 1 ;;
  esac
}
