sanitize_md() {
  # 1. Check if python3 is installed
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is not installed or not in PATH." >&2
    return 1
  fi

  # 2. Get the directory where THIS script/init.sh lives
  # In Zsh: ${(%):-%x} gives the path of the sourced file; in Bash: ${BASH_SOURCE[0]}
  local script_dir
  if [ -n "$ZSH_VERSION" ]; then
    script_dir="${${(%):-%x}:A:h}"
  elif [ -n "$BASH_SOURCE" ]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  else
    script_dir="$HOME/dev/mac/dotfiles/src/sanitize_md"
  fi

  local python_script="$script_dir/script.py"
  local py_bin="python3"
  if [ -x "$script_dir/.venv/bin/python3" ]; then
    py_bin="$script_dir/.venv/bin/python3"
  fi

  # 3. Handle inputs
  # If you gave it a file: sanitize_md job.md
  if [ -f "$1" ]; then
    "$py_bin" "$python_script" < "$1"
  # If you ran it bare with no args and no piped input: sanitize the clipboard
  elif [ -t 0 ] && [ $# -eq 0 ]; then
    pbpaste | "$py_bin" "$python_script" | pbcopy
    echo "✨ Clipboard sanitized!"
  # Otherwise handle piped input or direct text arguments
  else
    "$py_bin" "$python_script" "$@"
  fi
}
