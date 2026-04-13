#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: convert.sh <input-path-or-url> [output.md]" >&2
  exit 1
fi

INPUT="$1"
OUTPUT="${2:-}"

if ! command -v markitdown >/dev/null 2>&1; then
  echo "markitdown is not installed. Install with: uv tool install 'markitdown[all]'" >&2
  exit 2
fi

is_supported_file() {
  local path="$1"
  case "${path,,}" in
    *.pdf|*.doc|*.docx|*.ppt|*.pptx|*.xls|*.xlsx|*.html|*.htm|*.txt|*.csv|*.json|*.xml)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

if [ -d "$INPUT" ]; then
  if [ -z "$OUTPUT" ]; then
    echo "Input is a directory. Provide an output directory as the second argument." >&2
    exit 3
  fi

  mkdir -p "$OUTPUT"
  converted=0

  while IFS= read -r -d '' source_file; do
    if ! is_supported_file "$source_file"; then
      continue
    fi

    rel_path="${source_file#$INPUT/}"
    target_path="$OUTPUT/${rel_path%.*}.md"
    mkdir -p "$(dirname "$target_path")"
    markitdown "$source_file" > "$target_path"
    converted=$((converted + 1))
    echo "Saved Markdown: $target_path"
  done < <(find "$INPUT" -type f -print0 | sort -z)

  if [ "$converted" -eq 0 ]; then
    echo "No supported files found in: $INPUT" >&2
    exit 4
  fi
elif [ -n "$OUTPUT" ]; then
  markitdown "$INPUT" > "$OUTPUT"
  echo "Saved Markdown: $OUTPUT"
else
  markitdown "$INPUT"
fi
