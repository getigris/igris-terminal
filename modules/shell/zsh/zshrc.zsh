# ig-term :: .zshrc - Interactive shell configuration

# ── ZSH Options ───────────────────────────────────────────
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FCNTL_LOCK
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt +o nomatch

# ── Zim Framework ─────────────────────────────────────────
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_HIGHLIGHT_MAXLENGTH=300

if [[ -f "${ZIM_HOME}/init.zsh" ]]; then
  source "${ZIM_HOME}/init.zsh"
fi

# ── Load ig-term aliases ──────────────────────────────────
for _ig_alias_file in "${IG_HOME}"/modules/shell/aliases/*.sh; do
  [[ -f "$_ig_alias_file" ]] && source "$_ig_alias_file"
done
unset _ig_alias_file

# ── Load ig-term functions ────────────────────────────────
for _ig_func_file in "${IG_HOME}"/modules/shell/functions/*.sh; do
  [[ -f "$_ig_func_file" ]] && source "$_ig_func_file"
done
unset _ig_func_file

# ── Generated configs (theme colors, etc.) ────────────────
for _ig_gen_file in "${IG_CONFIG_DIR}"/generated/*.sh; do
  [[ -f "$_ig_gen_file" ]] && source "$_ig_gen_file"
done
unset _ig_gen_file

# ── User custom configs ──────────────────────────────────
# Source user's custom shell scripts (not managed by ig-term)
if [[ -d "${IG_CONFIG_DIR}/custom" ]]; then
  for _ig_custom_file in "${IG_CONFIG_DIR}"/custom/*.sh; do
    [[ -f "$_ig_custom_file" ]] && source "$_ig_custom_file"
  done
  unset _ig_custom_file
fi

# ── Tool initialization ──────────────────────────────────
# Starship prompt
command -v starship &>/dev/null && eval "$(starship init zsh)"

# zoxide (smarter cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# fzf keybindings
if command -v fzf &>/dev/null; then
  source <(fzf --zsh 2>/dev/null) || true
fi

# direnv (if installed)
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# ── Welcome screen (optional) ────────────────────────────
# Disable with: [shell] welcome = false in ig.toml
if [[ "${IG_WELCOME:-true}" == "true" ]]; then
  [[ -f "${IG_HOME}/modules/shell/welcome.sh" ]] && source "${IG_HOME}/modules/shell/welcome.sh"
fi
