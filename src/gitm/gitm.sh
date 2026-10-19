# gitm: Minimal, fast Git wrapper (shallow clones, sparse-checkout, & passthrough)
gitm() {
  local cmd="${1:-}"
  if [ -z "$cmd" ]; then
    command git
    return
  fi
  shift

  case "$cmd" in
    clone)
      _gitm_clone "$@"
      ;;
    pull)
      # Shallow fast-forward pull
      git fetch --depth=1 origin HEAD && git reset --hard FETCH_HEAD
      ;;
    add)
      # Add folder/pattern to existing sparse checkout
      [ $# -eq 0 ] && { echo "usage: gitm add <path>..."; return 1; }
      git sparse-checkout add "$@"
      ;;
    list)
      # View current sparse checkout paths
      git sparse-checkout list
      ;;
    *)
      # Transparent passthrough to standard git
      command git "$cmd" "$@"
      ;;
  esac
}

_gitm_clone() {
  local branch=""
  local no_git=false
  local url=""
  local target=""
  local paths=()
  local seen_paths_delimiter=false

  while [ $# -gt 0 ]; do
    if $seen_paths_delimiter; then
      paths+=("$1")
      shift
      continue
    fi

    case "$1" in
      -b|--branch)
        branch="$2"
        shift 2
        ;;
      --no-git)
        no_git=true
        shift
        ;;
      --|--only)
        seen_paths_delimiter=true
        shift
        ;;
      *)
        if [ -z "$url" ]; then
          url="$1"
        elif [ -z "$target" ]; then
          target="$1"
        else
          # Trailing arguments without -- are treated as sparse paths
          paths+=("$1")
        fi
        shift
        ;;
    esac
  done

  if [ -z "$url" ]; then
    cat << 'EOF'
usage: gitm clone [options] <url> [target_dir] [-- <path>...]

Options:
  -b, --branch <branch>   Clone specific branch
  --no-git                Remove .git folder after checkout (export mode)
  -- <path>...            Only checkout specified paths (sparse clone)

Examples:
  gitm clone https://github.com/org/repo                      # Minimal full clone (shallow, 1 branch, no tags)
  gitm clone https://github.com/org/repo my-app               # Minimal full clone into custom dir
  gitm clone https://github.com/org/repo -- docs              # Only download docs/
  gitm clone https://github.com/org/repo my-docs -- docs      # Only download docs/ into my-docs/
  gitm clone --no-git https://github.com/org/repo -- docs     # Download docs/ without .git (replaces snag.sh)
EOF
    return 1
  fi

  [ -z "$target" ] && target="$(basename "$url" .git)"

  local clone_args=(--depth=1 --single-branch --no-tags)
  [ -n "$branch" ] && clone_args+=(-b "$branch")

  if [ ${#paths[@]} -eq 0 ]; then
    # 1. Full minimal clone
    command git clone "${clone_args[@]}" "$url" "$target" || return 1
  else
    # 2. Sparse clone: partial clone downloading ONLY requested directory blobs
    command git clone "${clone_args[@]}" --filter=blob:none --sparse "$url" "$target" || return 1
    command git -C "$target" sparse-checkout set --no-cone "${paths[@]}" || return 1
  fi

  if $no_git; then
    rm -rf "$target/.git"
    echo "  └─ Exported $target (removed .git)"
  fi
}

# Backward compatibility alias
alias git-sparse='gitm'
