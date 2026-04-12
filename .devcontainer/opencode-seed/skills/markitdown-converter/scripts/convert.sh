#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: convert.sh <input-path-or-url> [output.md]" >&2
  exit 1
fi

INPUT="$1"
OUTPUT="${2:-}"

if ! command -v markitdown >/dev/null 2>&1; then
  echo "markitdown is not installed. Install with: uv tool install markitdown" >&2
  exit 2
fi

if [ -n "$OUTPUT" ]; then
  markitdown "$INPUT" > "$OUTPUT"
  echo "Saved Markdown: $OUTPUT"
else
  markitdown "$INPUT"
fi
