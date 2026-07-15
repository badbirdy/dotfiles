# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). The repository has two independent roles:

- `desktop/`: Arch Linux desktop running the niri Wayland compositor.
- `server/`: CLI configuration for remote servers.

Each immediate child of a role directory is one Stow package. Desktop and Server configs are intentionally duplicated when necessary; do not add a common inheritance layer or separate long-lived Git branches.

See **AGENTS.md** for coding style, commit conventions, validation commands, and repo-specific rules. That file is the primary guidance; this one covers what AGENTS.md doesn't.

## Deploying dotfiles

```bash
# Preview all packages for one role
./deploy.sh desktop --dry-run
./deploy.sh server --dry-run

# Deploy all packages for one role
./deploy.sh desktop
./deploy.sh server
```

`deploy.sh` resolves the repository directory itself, enumerates every package under the selected role, and runs GNU Stow with `--restow --no-folding`. It never runs Git commands, installs dependencies, overwrites conflicting regular files, or uses `--adopt`.

Package paths mirror `$HOME`. For example, `desktop/niri/.config/niri/config.kdl` maps to `~/.config/niri/config.kdl`.

## Desktop architecture

The graphics stack: **niri** (Wayland compositor) → **nirinit** (session init daemon that launches apps on startup) → **systemd user services** manage background processes (waybar, mako, xremap, swayidle, waypaper-random.timer, zju-connect, kdeconnect-refresh.timer).

Key config relationships:
- `desktop/niri/.config/niri/config.kdl` includes `binds.kdl`, `output.kdl`, `rule.kdl` — each scoped to one concern.
- `desktop/niri/.config/niri/config.kdl` declares named workspaces (`browser`, `ghostty`, `code`, `write`, `chat`) that are referenced in `rule.kdl` to pin windows.
- `desktop/nirinit/.config/nirinit/config.toml` defines which apps auto-start after niri launches.
- `desktop/systemd/.config/systemd/user/` contains service units and `*.wants/` symlinks that wire them to session targets (`niri.service.wants/`, `graphical-session.target.wants/`).
- `desktop/waybar/.config/waybar/scripts/` contains helper scripts used by modules defined in `modules.jsonc`.
- `desktop/rofi/.config/rofi/` includes a `mypowermenu/` subdirectory for the custom power menu.

## Validation commands (from AGENTS.md)

| Component | Command |
|-----------|---------|
| Deploy script | `bash -n deploy.sh` |
| Desktop Stow preview | `./deploy.sh desktop --dry-run` |
| Server Stow preview | `./deploy.sh server --dry-run` |
| Fish config | `fish -n desktop/fish/.config/fish/config.fish` |
| Neovim format | `stylua desktop/nvim/.config/nvim` |
| Neovim startup | `nvim --headless "+qa"` |
| Systemd user units | `systemd-analyze --user verify desktop/systemd/.config/systemd/user/*.service` |
| Apply service changes | `systemctl --user daemon-reload && systemctl --user restart <service>` |
| Yazi plugins | `ya pkg add <plugin-or-flavor>` |

## Git conventions

Commit subjects are short, imperative, and scoped to the changed app: `update niri configs`, `add zju-connect service`, `update waybar configs`. No PRs or release branches — work happens directly on `main`.

## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five default triage labels. See `docs/agents/triage-labels.md`.

### Domain docs

This repository uses a single-context layout. See `docs/agents/domain.md`.
