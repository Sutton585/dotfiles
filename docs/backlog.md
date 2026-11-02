### TODO
- branching kernal-aware install paths
	- homebrew install support
	- pacman install support
- env variables and config files
	- starship.toml: done in dotfiles.sh
	- fzf: created fzf.sh, didn't set in dotfiles.sh
	- zoxide: creating zoxide.sh, didn't set in dotfiles.sh 
- uvx/npx support
- sanitize_md
- compress_md
- some items not working in arch
- vim settings, neovim? syntax highlighting in markdown files and other file types.
- research other plugins

# Details

## Plugins to research:
- atuin
- autojump
- fasd
- z
- z.lua
- neovim

## Branching installs

instead of binaries in .local or .config or whatever, use native instal methods. That is, "is homebrew exists, use that, if pacman exists, use that, etc. fallback is (current flow) using .local"

### zoxide
homebrew: `brew install zoxide`
pacman:

### fzf
homebrew: `brew install zoxide`
pacman:

###  starship



