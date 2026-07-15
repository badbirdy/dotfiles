# Repository Guidelines

## Project Structure & Module Organization
This repository keeps two independent GNU Stow roles: `desktop/` and `server/`. Each immediate child is one Stow package and mirrors its target path under `$HOME`, for example `desktop/niri/.config/niri/` and `server/nvim/.config/nvim/`.

Do not introduce a shared config layer between the roles. If an application's configuration differs, keep complete copies in both roles. Keep related assets beside the config that uses them, for example Waybar helper scripts in `desktop/waybar/.config/waybar/scripts` and Ghostty shaders in `desktop/ghostty/.config/ghostty/shaders`.

## Build, Test, and Development Commands
There is no single build step; validate the component you changed.

- `bash -n deploy.sh`: syntax-check the deployment script.
- `./deploy.sh desktop --dry-run`: preview Desktop link changes.
- `./deploy.sh server --dry-run`: preview Server link changes.
- `fish -n desktop/fish/.config/fish/config.fish`: syntax-check Desktop Fish config.
- `stylua desktop/nvim/.config/nvim`: format Desktop Neovim Lua config.
- `nvim --headless "+qa"`: catch Neovim startup errors.
- `systemd-analyze --user verify desktop/systemd/.config/systemd/user/*.service`: validate user units.
- `systemctl --user daemon-reload`: reload user systemd after unit changes.
- `systemctl --user restart waybar.service`: apply Waybar changes.
- `ya pkg add <plugin-or-flavor>`: install Yazi plugins and flavors listed in [desktop/yazi/.config/yazi/README.md](/home/bdbd/dotfiles/desktop/yazi/.config/yazi/README.md).

## Coding Style & Naming Conventions
Match the style already used by each config format instead of normalizing everything:

- JSONC, YAML, and most Lua files use compact formatting with 2-space indentation.
- KDL files in `desktop/niri/.config/niri` use 4-space indentation.
- Preserve existing comments; add new comments only when they explain non-obvious behavior.
- Name files and modules by app or feature, for example `rule.kdl`, `modules.jsonc`, `proxy_on.fish`.

## Testing Guidelines
There is no centralized test suite or coverage target. Prefer native validation plus a role-specific Stow dry-run. For Desktop UI changes, verify the exact behavior in the live session, especially for Waybar, Rofi, Niri, and Mako.

## Commit & Pull Request Guidelines
Recent history uses short imperative subjects such as `update my nvim config` and `add wf-recorder to my waybar widgets`. Follow that pattern: keep subjects brief, action-first, and scoped to the changed app.

Pull requests should include:

- A short summary of affected apps or folders.
- Manual verification steps you ran.
- Screenshots for visible desktop changes.
- Notes about machine-specific paths, services, or dependencies.

## Repository-Specific Notes
Do not commit generated or local-only files such as `fish_variables*`, swap files, `*.bak`, or package-managed plugin directories unless the change intentionally updates tracked state. Keep such runtime files in the real `$HOME` directories created by `stow --no-folding`, not inside a package. Avoid hardcoding secrets or host-specific values without documenting why they are required.
