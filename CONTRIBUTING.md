# Contributing to ig-term

Thanks for your interest in contributing to ig-term!

## Ways to contribute

- Report bugs or suggest features via [GitHub Issues](https://github.com/getigris/igris-terminal/issues)
- Submit pull requests for bug fixes, new modules, themes, or prompt presets
- Improve documentation
- Test on different platforms and report compatibility

## Development setup

```bash
git clone https://github.com/getigris/igris-terminal.git
cd igris-terminal

# Test CLI locally
IG_HOME="$(pwd)" ./bin/ig doctor
IG_HOME="$(pwd)" ./bin/ig module list
```

## Project structure

```
ig-term/
  bin/ig            # CLI entry point
  core/             # Engine, platform detection, config, symlinks, logging
  lib/              # Utilities (TOML parser, semver)
  modules/          # Self-contained modules (shell, prompt, terminal, etc.)
  themes/           # Color palettes
  templates/        # Default config files
  hooks/            # Lifecycle hook directories
```

## Creating a module

Each module lives in `modules/<name>/` and contains:

| File | Purpose | Required |
|------|---------|----------|
| `module.toml` | Metadata, dependencies, platform support | Yes |
| `install.sh` | Install system packages (must be idempotent) | No |
| `configure.sh` | Generate or link config files | No |

### module.toml format

```toml
[module]
name = "my-module"
description = "Short description"
version = "1.0.0"
default = false

[dependencies]
requires = ["theme"]     # Other ig-term modules
tools = ["my-tool"]      # System commands needed

[platforms]
supported = ["macos", "linux"]

[packages]
brew = ["my-tool"]
apt = ["my-tool"]
```

### Script conventions

- Use `#!/usr/bin/env bash` with `set -euo pipefail` for standalone scripts
- Source `${IG_HOME}/core/log.sh` and `${IG_HOME}/core/platform.sh` as needed
- Use `ig_info`, `ig_success`, `ig_warn`, `ig_error` for output
- Use `ig_has <cmd>` to check if a tool exists before installing
- Use `ig_install` for cross-platform package installation
- Use `ig_link` for symlinks (handles backup automatically)
- Use `ig_write_config` for generated config files
- Theme colors are available as `IG_COLOR_*` environment variables

## Creating a theme

Themes live in `themes/<name>/` with a `theme.toml`:

```toml
[meta]
name = "My Theme"
author = "Your Name"
variant = "dark"

[colors]
background = "#1a1b26"
foreground = "#a9b1d6"
cursor = "#c0caf5"
selection_bg = "#28344a"
selection_fg = "#7aa2f7"

[colors.normal]
black = "#414868"
red = "#f7768e"
# ... all 8 colors

[colors.bright]
black = "#565f89"
red = "#f7768e"
# ... all 8 colors

[colors.accent]
primary = "#7aa2f7"
secondary = "#bb9af7"
info = "#7dcfff"
success = "#73daca"
warning = "#e0af68"
error = "#f7768e"
```

## Creating a prompt preset

Starship presets live in `modules/prompt/presets/<name>.toml`. Use standard Starship configuration format. Try to use colors from the theme palette for consistency.

## Pull request guidelines

1. Fork the repo and create a branch from `main`
2. Test your changes locally with `IG_HOME="$(pwd)" ./bin/ig doctor`
3. Keep changes focused - one feature/fix per PR
4. Update documentation if needed
5. Use clear commit messages

## Code style

- Shell scripts: bash, `set -euo pipefail` where appropriate
- Functions: prefix with `ig_` for core utilities
- Config: TOML format
- No hardcoded user paths - use `$IG_HOME`, `$IG_CONFIG_DIR`
- Platform-specific code in separate files, not inline conditionals
