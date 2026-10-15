----------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

source $ZSH/oh-my-zsh.sh
----------------------------------------
export VAULTS='/Users/sutton585/Library/Mobile Documents/iCloud~md~obsidian/Documents'

export MAC=/Users/sutton585/services/mac

export BULLY=/Users/sutton585/services/bully

export GIT=/Users/sutton585/Documents/Git

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/sutton585/.lmstudio/bin"
# End of LM Studio CLI section


# Added by Antigravity IDE
export PATH="/Users/sutton585/.antigravity-ide/antigravity-ide/bin:$PATH"

# Hermes Agent — ensure ~/.local/bin is on PATH
export PATH="$HOME/.local/bin:$PATH"

plugins=(
  git
  docker
  kubectl
  macos
  brew
  web-search
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source $ZSH/oh-my-zsh.sh


# docker-ps(){
# 	command docker ps --format "table {{.Names}}\t{{.Status}}"
# }

# docker-compose-ps(){
# 	command docker compose ps --format "table {{.Name}}\t{{.Status}}"
# }

dk(){
	if [[ "$1" == "ps" ]]; then
		command docker ps --format "table {{.Names}}\t{{.Status}}"
	elif [[ "$1" == "compose" && "$2" == "ps" ]]; then
		command docker compose ps --format "table {{.Name}}\t{{.Status}}"
	else
		command docker "$@"
	fi
}

deploy(){
	local foreground=false
	local profile="*"

	for arg in "$@"; do
		if [[ "$arg" == "-f" ]]; then
			foreground=true
		else
			profile="$arg"
		fi
	done

	# git pull

	if [[ "$foreground" == true ]]; then
		docker compose --profile "$profile" up --build
	else
		docker compose --profile "$profile" up -d --build
	fi
}


zsh-reset(){
	source ~/.zshrc
}

# Added by Antigravity IDE
export PATH="/Users/sutton585/.antigravity-ide/antigravity-ide/bin:$PATH"


. "/Users/sutton585/services/mac/dotfiles/init.sh"
