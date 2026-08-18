#!/usr/bin/env bash
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_SCRIPT="${ROOT_DIR}/flutter_app/tool/package_release.sh"

if [[ ! -f "${PACKAGE_SCRIPT}" ]]; then
  printf 'Error: package script not found: %s\n' "${PACKAGE_SCRIPT}" >&2
  exit 1
fi

exec bash "${PACKAGE_SCRIPT}" "$@"
