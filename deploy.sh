#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
用法：
  ./deploy.sh <desktop|server> [--dry-run]
EOF
}

if (( $# < 1 || $# > 2 )); then
  usage >&2
  exit 2
fi

role=$1
dry_run=false

case "$role" in
  desktop | server) ;;
  *)
    printf '错误：未知角色 %q\n' "$role" >&2
    usage >&2
    exit 2
    ;;
esac

if (( $# == 2 )); then
  if [[ $2 != --dry-run ]]; then
    printf '错误：未知参数 %q\n' "$2" >&2
    usage >&2
    exit 2
  fi
  dry_run=true
fi

if ! command -v stow >/dev/null 2>&1; then
  printf '错误：未找到 GNU Stow，请先安装 stow。\n' >&2
  exit 1
fi

repo_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
role_dir=$repo_dir/$role

if [[ ! -d $role_dir ]]; then
  printf '错误：角色目录不存在：%s\n' "$role_dir" >&2
  exit 1
fi

shopt -s nullglob
package_dirs=("$role_dir"/*/)
shopt -u nullglob

if (( ${#package_dirs[@]} == 0 )); then
  printf '错误：角色目录中没有可部署的软件包：%s\n' "$role_dir" >&2
  exit 1
fi

packages=()
for package_dir in "${package_dirs[@]}"; do
  package=${package_dir%/}
  packages+=("${package##*/}")
done

stow_args=(
  --restow
  --no-folding
  --dir="$role_dir"
  --target="$HOME"
)

if [[ $dry_run == true ]]; then
  stow_args+=(--simulate --verbose=1)
fi

stow "${stow_args[@]}" "${packages[@]}"
