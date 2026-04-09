# ig-term - Claude Code Context

## Project Overview

**ig-term** is an open-source terminal configuration framework. One command to set up a productive, beautiful, and functional terminal without researching 20 tools.

- **Repo:** `getigris/igris-terminal`
- **License:** Elastic License 2.0
- **Target:** macOS first, designed to extend to Linux

## Stack (Defaults)

| Component | Tool |
|-----------|------|
| Shell | ZSH + Zim framework |
| Prompt | Starship |
| Terminal | Ghostty |
| Theme | Tokyo Night |
| Font | Hack Nerd Font |
| CLI tools | bat, lsd, fzf, zoxide |
| Plugins | zsh-syntax-highlighting, zsh-autosuggestions |

## Architecture

### Module System
Each module is self-contained in `modules/<name>/`:
- `module.toml` - metadata, dependencies, platform support, package mapping
- `install.sh` - installs system packages (idempotent)
- `configure.sh` - generates/links config files

### Configuration (3-layer TOML merge)
1. `templates/ig.toml` - shipped defaults (never modified by user)
2. `~/.config/ig-term/ig.toml` - user config
3. `~/.config/ig-term/local.toml` - machine-local overrides (.gitignored)

### Theming
Single source of truth in `themes/<name>/theme.toml`. Colors exported as env vars (`IG_COLOR_*`) and projected into each tool's native format by `configure.sh`.

### Cross-Platform
- `core/platform.sh` exposes `ig_os()`, `ig_arch()`, `ig_pkg()`, `ig_install()`
- Platform-specific files live inside each module: `exports/macos.sh`, `platform/linux.conf`
- Package mapping in `module.toml`: `brew = ["bat"]`, `apt = ["bat"]`

### CLI (`bin/ig`)
```
ig init, ig apply, ig update, ig module list/enable/disable,
ig theme list/set, ig list, ig logs, ig doctor, ig backup, ig uninstall
```

## Project Structure

```
ig-term/
├── bin/ig                      # CLI entry point
├── core/                       # Engine, platform, config, symlink, log
├── modules/                    # shell, prompt, terminal, theme, fonts, tools, git
├── themes/                     # Color palettes (tokyo-night)
├── hooks/                      # pre/post install/update drop-in scripts
├── lib/                        # toml-parser.sh, semver.sh
├── templates/                  # Default ig.toml, local.toml
├── tests/
├── docs/
├── install.sh                  # One-line installer (curl | sh)
└── README.md
```

## Conventions

- All shell scripts use `#!/usr/bin/env bash` with `set -euo pipefail`
- Functions prefixed with `ig_` for core utils (e.g., `ig_log`, `ig_install`, `ig_os`)
- Module scripts receive theme colors as `IG_COLOR_*` env vars
- No hardcoded user paths - use `$IG_HOME`, `$IG_CONFIG_DIR`
- Platform-specific code goes in separate files, never inline conditionals
- TOML for all config files
- Keep scripts POSIX-compatible where possible, bash where necessary

## Key Variables

- `IG_HOME` - ig-term installation (`~/.local/share/ig-term/`)
- `IG_CONFIG_DIR` - user config (`~/.config/ig-term/`)
- `IG_BACKUP_DIR` - config backups (`~/.config/ig-term/backups/`)
- `IG_STATE_FILE` - state tracking (`~/.config/ig-term/state.toml`)
- `IG_LOG_DIR` - operation logs (`~/.config/ig-term/logs/`)

## Memory

This project uses **igris-memory MCP** for cross-session context. Key topic_keys:
- `plan/ig-term` - current project plan and status
- `user/adiaz` - user preferences

## Development Guidelines

- Start small, expand based on traction
- Only include what's actually used in the default stack
- Every module must be independently disable-able
- Updates must NEVER overwrite user config
- Backup existing configs before touching anything
- All install scripts must be idempotent
