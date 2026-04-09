# ig-term

A terminal configuration framework that sets up a productive, beautiful, and functional terminal with one command. No need to research 20 tools.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/getigris/igris-terminal/main/install.sh | bash
```

## What you get

| Component | Tool | Why |
|-----------|------|-----|
| Shell | ZSH + Zim | Fast, modular plugin framework |
| Prompt | Starship | Cross-shell, Rust-based, customizable |
| Terminal | Ghostty | Modern, GPU-accelerated, simple config |
| Theme | Tokyo Night | Popular dark theme with great contrast |
| Font | Hack Nerd Font | Complete glyph set, readable |
| CLI tools | bat, lsd, fzf, zoxide | Modern replacements for cat, ls, find, cd |

## Commands

```
ig init              # First-time setup
ig apply             # Re-generate configs (no package installs)
ig update            # Pull latest + re-apply
ig update --check    # Check for updates without applying
ig module list       # Show available modules
ig module enable X   # Enable, install, and configure a module
ig module disable X  # Disable a module
ig theme list        # Show available themes
ig theme set X       # Switch theme and re-apply configs
ig list              # Show installed modules and tools with versions
ig logs              # Show operation history
ig logs install      # Filter logs by action (install, update, remove, etc.)
ig doctor            # Health check
ig backup            # Backup current configs
ig uninstall         # Remove ig-term, restore backups
```

## Modules

ig-term is built around independent modules. Each can be enabled or disabled:

- **fonts** - Nerd Font installation
- **theme** - Unified color palette across all tools
- **shell** - ZSH + Zim framework + aliases + functions
- **prompt** - Starship with multiple presets
- **terminal** - Ghostty configuration
- **tools** - bat, lsd, fzf, zoxide
- **git** - Sensible defaults (does not touch your identity)

## Configuration

ig-term uses a 3-layer TOML config system:

1. **Defaults** - shipped with ig-term (never edit)
2. **User config** - `~/.config/ig-term/ig.toml` (your customizations)
3. **Local overrides** - `~/.config/ig-term/local.toml` (machine-specific, gitignored)

### Example config

```toml
# ~/.config/ig-term/ig.toml

[modules]
shell = true
prompt = true
terminal = true
git = false          # opt out of git config

[prompt]
preset = "minimal"   # "default" | "minimal" | "powerline"

[terminal]
font_family = "JetBrains Mono Nerd Font"
font_size = 14

[theme]
name = "tokyo-night"
```

## Prompt presets

Three built-in presets for Starship:

- **default** - Full-featured with segments for directory, git, languages, time
- **minimal** - Just directory, git branch, and status
- **powerline** - Powerline-style with OS icon and colored segments

## Shell functions

ig-term includes useful shell functions out of the box:

- `smart-install` (aliased as `i`) - Auto-detects your project type and runs the right install command (npm, pnpm, yarn, bun, maven, gradle, cargo, pip, bundle, dotnet)
- `cdd` - FZF-powered directory picker
- `killport <port>` - Kill whatever is running on a given port

## Shell aliases

### Git
`gaa`, `gs`, `gco`, `gd`, `gl`, `gps`, `gpl`, `gb`, `gf`, `git-tree`

### Navigation
`..`, `...`, `....`, `~`, `-`

### Utilities
`cat` (bat), `ls` (lsd), `ll`, `la`, `lt` (tree), `vim` (nvim), `public-ip`

## Extending ig-term

### Custom aliases and scripts

Drop `.sh` files in `~/.config/ig-term/custom/` and they will be sourced automatically:

```bash
# ~/.config/ig-term/custom/my-aliases.sh
alias repos="cd ~/Repositories"
alias myproject="cd ~/work/myproject"
```

### Custom modules

Create a module in `~/.config/ig-term/modules/my-module/` with:

```
my-module/
  module.toml     # metadata
  install.sh      # package installation (optional)
  configure.sh    # config generation (optional)
```

### Hooks

Drop scripts in `~/.config/ig-term/hooks/` to run at lifecycle events:

```
hooks/
  pre-install.d/   # Before installing modules
  post-install.d/  # After installing modules
  pre-update.d/    # Before updating ig-term
  post-update.d/   # After updating ig-term
```

## Cross-platform

ig-term is macOS-first with Linux support designed in:

- Platform-specific configs live inside each module (`exports/macos.sh`, `exports/linux.sh`)
- Package mapping per manager (`brew`, `apt`, `dnf`, `pacman`)
- No hardcoded paths

## Uninstall

```bash
ig uninstall
```

This restores your original configs from backup and removes ig-term symlinks. To fully remove:

```bash
rm -rf ~/.local/share/ig-term ~/.config/ig-term
```

## License

Elastic License 2.0 - see [LICENSE](LICENSE)
