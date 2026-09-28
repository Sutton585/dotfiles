# docker ps -m / docker compose ps -m => minimal output; all else passes through
docker() {
  if [ "$1" = ps ] && [ "$2" = -m ]; then
    shift 2
    command docker ps --format "table {{.Names}}\t{{.Status}}" "$@"
  elif [ "$1" = compose ] && [ "$2" = ps ] && [ "$3" = -m ]; then
    shift 3
    command docker compose ps --format "table {{.Name}}\t{{.Status}}" "$@"
  else
    command docker "$@"
  fi
}

# deploy [-f] [profile...]  (no profile = all; -f = foreground)
deploy() {
  local fg=false p
  local args=()
  for p in "$@"; do
    if [ "$p" = -f ]; then fg=true; else args+=(--profile "$p"); fi
  done
  [ ${#args[@]} -eq 0 ] && args=(--profile '*')
  git pull --ff-only || return 1
  if $fg; then command docker compose "${args[@]}" up --build
  else command docker compose "${args[@]}" up -d --build; fi
}
