#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-8000}"

cd "$ROOT_DIR"

if python3 --version >/dev/null 2>&1; then
  PYTHON_CMD=(python3)
elif python --version >/dev/null 2>&1; then
  PYTHON_CMD=(python)
elif py -3 --version >/dev/null 2>&1; then
  PYTHON_CMD=(py -3)
else
  echo "Python 3 is required to host this site locally." >&2
  exit 1
fi

echo "Serving $ROOT_DIR at http://localhost:$PORT"
exec "${PYTHON_CMD[@]}" -m http.server "$PORT"