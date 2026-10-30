.docker() {
  case "$1" in
    up)   shift; docker compose --profile '*' up "$@" ;;
    down) shift; docker compose --profile '*' down "$@" ;;
    ps)   shift; docker ps --format "table {{.Names}}\t{{.Status}}" "$@" ;;
    compose)
      if [ "$2" = "ps" ]; then
        shift 2
        docker compose ps --format "table {{.Name}}\t{{.Status}}" "$@"
      else
        docker "$@"
      fi ;;
    *)    docker "$@" ;;
  esac
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
