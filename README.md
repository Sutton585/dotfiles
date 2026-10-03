# Universal Dotfiles

## Objective

Build a lightweight, cross-platform dotfiles framework that runs seamlessly across **macOS (Zsh / Oh My Zsh / iTerm2)** and **Linux (Bash)** from a single Git repository without configuration bloat, nested shell recursion, or duplicated logic.

## Core Architecture

```text
dotfiles/
├── setup.sh         # Idempotent installer: provisions dependencies & symlinks
├── bashrc           # Entrypoint: symlinks to ~/.bashrc
├── zshrc            # Entrypoint: symlinks to ~/.zshrc
└── src/             # Feature-grouped modules (git/, docker/, prompt/, etc.)
    ├── *.sh         # Universal: sourced by BOTH Bash and Zsh
    ├── *.bash       # Bash-only: sourced exclusively by Bash
    └── *.zsh        # Zsh-only: sourced exclusively by Zsh

```

1. **Feature-First, Extension-Gated Loading:**
- Instead of siloed environment folders (`shared/`, `bash/`, `zsh/`), scripts are organized by concern inside `src/`.
- Loading compatibility is determined strictly by file extension. Examples:
    - `filename.bash` works in bash, but not in zsh (linux env)
    - `filename.zsh` works in zsh, but not in bash (mac env)
    - `filename.sh` works in both zsh AND bash (univeral)

2. **Symlinks over Injection:**
* `setup.sh` runs once per machine to symlink `dotfiles/bashrc -> ~/.bashrc` and `dotfiles/zshrc -> ~/.zshrc`.
* Edits and `git pull` updates take effect immediately in new tabs with zero file-sync scripts or runtime overhead.

3. **Oh My Zsh Management on macOS:**
* Installed automatically via `setup.sh` in unattended mode (`RUNZSH=no CHSH=no ... --unattended`) before symlinking `zshrc`.
* Third-party plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) are cloned automatically into `~/.oh-my-zsh/custom/plugins`.
* `dotfiles/zshrc` configures OMZ (`ZSH_THEME`, `plugins=(...)`), boots OMZ (`source $ZSH/oh-my-zsh.sh`), and then sources `src/` modules.

---

## Critical Edge Cases & Implementation Rules

**Recursive Loop Prevention:**
- Entrypoints (`bashrc`, `zshrc`) live at the repository root without extensions so that recursive globs (`src/**/*.sh`) never re-source the entrypoints themselves.

**OMZ Install Ordering:**
- OMZ unattended installation generates a default `~/.zshrc`. `setup.sh` must remove/overwrite that generated file with the symlink *after* OMZ finishes installing, not before.

**Globstar Settings:**
- Bash requires `shopt -s globstar nullglob` to resolve nested `**/*.sh` without erroring on empty folders.
- Zsh requires `setopt globstar nullglob`.

**BSD vs. GNU Tool Divergence:**
- Shared scripts (`*.sh`) must avoid GNU-only flags (e.g., `ls -v`, GNU `sed -i` without backup suffix). Use command guards (`command -v tool &>/dev/null`) or OS branching (`[[ "$OSTYPE" == "darwin"* ]]`).

**Zsh Syntax Highlighting Ordering:**
- In the `plugins=(...)` array inside `zshrc`, `zsh-syntax-highlighting` **must** be the very last plugin loaded.

**Terminal Prompt Isolation:**
- Bash prompt hooks (`trap 'timer_start' DEBUG`, `PS1='$(promptify)'`) break in Zsh and must reside strictly in a `*.bash` file.

**Dependencies**
- For zsh environments, we install oh-my-zsh and a few third-party plugins for it
