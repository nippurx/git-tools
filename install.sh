#!/usr/bin/env sh
set -eu
command -v git >/dev/null 2>&1 || { echo 'ERROR: instala Git primero.' >&2; exit 1; }
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
payload=$(cat "$script_dir/lib/commands.sh")
github_owner=${1:-$(git config --global --get git-tools.github-owner || :)}
if [ -z "$github_owner" ] && [ -t 0 ]; then
  printf 'Usuario de GitHub (Enter para omitir): '
  read -r github_owner
fi
if [ -n "$github_owner" ]; then
  printf '%s\n' "$github_owner" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$' || { echo 'ERROR: usuario de GitHub invalido.' >&2; exit 1; }
  git config --global --replace-all git-tools.github-owner "$github_owner"
fi
for name in start backup release rollback rollback-release; do
  value="!$payload
gt_main $name"
  git config --global --replace-all "alias.$name" "$value"
  [ "$(git config --global --get "alias.$name")" = "$value" ] || exit 1
done
echo 'Git Tools instalado. Usa git start, backup, release y rollback.'