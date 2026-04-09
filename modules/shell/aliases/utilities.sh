# ig-term :: aliases/utilities.sh - Modern CLI replacements

# bat -> cat replacement (only if installed)
command -v bat &>/dev/null && alias cat="bat"

# lsd -> ls replacement (only if installed)
if command -v lsd &>/dev/null; then
  alias ls="lsd"
  alias ll="lsd -l"
  alias la="lsd -la"
  alias lt="lsd --tree"
else
  alias ll="ls -l"
  alias la="ls -la"
fi

# vim -> nvim (only if installed)
command -v nvim &>/dev/null && alias vim="nvim"

# Quick open
alias o.='open .'
alias k='kill -9'
alias public-ip="curl -s ifconfig.me"
