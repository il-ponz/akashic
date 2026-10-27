#!/usr/bin/env bash
# Refresh every registered source's listing and product pages, then export the current library.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRAPER="$ROOT/scraper"
LOG_DIR="$ROOT/data/cache/refresh-pages/$(date +%F)"
mkdir -p "$LOG_DIR"

cd "$SCRAPER"
PCBLIB_BIN="${PCBLIB_BIN:-.venv/bin/pcblib}"
PYTHON_BIN="${PYTHON_BIN:-.venv/bin/python}"
if [ ! -x "$PCBLIB_BIN" ] || [ ! -x "$PYTHON_BIN" ]; then
  echo "Missing scraper CLI or Python environment; install the scraper first (see README.md)." >&2
  exit 1
fi

FAILED="$LOG_DIR/failed.txt"
: >"$FAILED"
export LOG_DIR FAILED PCBLIB_BIN PYTHON_BIN

echo "Refreshing all registered sources (up to 4 at a time). Logs: $LOG_DIR"
"$PYTHON_BIN" -c "from pcblib.vendors import REGISTRY, load_all; load_all(); print('\n'.join(sorted(REGISTRY)))" |
  xargs -P 4 -n 1 sh -c '
    source="$1"
    for attempt in 1 2 3; do
      if "$PCBLIB_BIN" scrape "$source" --refresh-pages >"$LOG_DIR/$source.log" 2>&1; then
        exit 0
      fi
      if [ "$attempt" -lt 3 ]; then sleep 20; fi
    done
    echo "$source" >>"$FAILED"
  ' sh

echo
if [ -s "$FAILED" ]; then
  echo "Sources still failing after 3 attempts:"
  cat "$FAILED"
  echo "See per-source logs in $LOG_DIR."
else
  echo "All sources refreshed successfully."
fi

echo
"$PCBLIB_BIN" stats
"$PCBLIB_BIN" audit
"$PCBLIB_BIN" export

if [ -s "$FAILED" ]; then
  exit 1
fi
