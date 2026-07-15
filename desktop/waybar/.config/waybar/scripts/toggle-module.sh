#!/usr/bin/env bash
set -euo pipefail

CONFIG=${WAYBAR_CONFIG:-"$HOME/.config/waybar/config.jsonc"}

python3 - "$CONFIG" "$@" <<'PY'
import re
import sys
from pathlib import Path

ARRAYS = {"modules-left", "modules-center", "modules-right"}
ITEM_RE = re.compile(r'^(\s*)(//\s*)?("[^"]+"\s*,?)(\s*)$')


def iter_modules(lines):
    current = None
    for idx, line in enumerate(lines):
        stripped = line.strip()
        if current is None:
            m = re.match(r'^"([^"]+)":\s*\[\s*$', stripped)
            if m and m.group(1) in ARRAYS:
                current = m.group(1)
            continue

        if stripped.startswith("]"):
            current = None
            continue

        m = ITEM_RE.match(line.rstrip("\n"))
        if not m:
            continue

        name = re.search(r'"([^"]+)"', m.group(3)).group(1)
        yield idx, current, name, bool(m.group(2))


def list_modules(path):
    lines = path.read_text().splitlines(keepends=True)
    for _, _, name, disabled in iter_modules(lines):
        state = "inactive" if disabled else "active"
        print(f"{state}\t{name}")


def toggle_module(path, target):
    lines = path.read_text().splitlines(keepends=True)
    for idx, _, name, disabled in iter_modules(lines):
        if name != target:
            continue

        line = lines[idx]
        body = line.rstrip("\n")
        newline = "\n" if line.endswith("\n") else ""
        m = ITEM_RE.match(body)
        indent, comment, item, tail = m.groups()

        if disabled:
            lines[idx] = f"{indent}{item}{tail}{newline}"
            state = "active"
        else:
            lines[idx] = f"{indent}//{item}{tail}{newline}"
            state = "inactive"

        path.write_text("".join(lines))
        print(f"{state}\t{target}")
        return

    raise SystemExit(f"module not found: {target}")


def main():
    if len(sys.argv) < 3:
        raise SystemExit("usage: toggle-module.sh list | toggle <module>")

    path = Path(sys.argv[1]).expanduser()
    command = sys.argv[2]

    if command == "list":
        list_modules(path)
    elif command == "toggle" and len(sys.argv) == 4:
        toggle_module(path, sys.argv[3])
    else:
        raise SystemExit("usage: toggle-module.sh list | toggle <module>")


if __name__ == "__main__":
    main()
PY
