## Repo Structure

dotfiles/
├── init.sh     # Runs once on a new machine to provision & symlink
├── bashrc      # Symlinks to ~/.bashrc: allows \*.sh and \*.bash utilization
├── zshrc       # Symlinks to ~/.zshrc allows \*.sh and \*.zsh utilization
└── src/        # The actual scripts, grouped logically.

---

## Compatibility Concerns

To ensure we only load compatible scripts, we use a strict naming structure for the scripts:

- filename.bash = this file works in bash, but not in zsh (linux env)
- filename.zsh = this file works in zsh, but not in bash (mac env)
- filename.sh = this works in both zsh AND bash (univeral)


## Dependencies

For zsh, we install oh-my-zsh and a few third-party plugins