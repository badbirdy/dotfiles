# Packages

Plugins and flavors are declared in `package.toml`. After deploying this
Stow package, install them into the local Yazi config directory:

```bash
ya pkg install
```

Use `ya pkg add <package>` and `ya pkg upgrade` to update
`package.toml`. The generated `plugins/` and `flavors/` directories are
local runtime state and are not tracked in this repository.
