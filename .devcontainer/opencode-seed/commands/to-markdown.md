---
description: Convert files/URLs to Markdown via MarkItDown
agent: build
---

# to-markdown

Convert source content into Markdown using MarkItDown CLI (fallback when MCP is unavailable).

## Usage

`/to-markdown <input-path-or-url> [output]`

## Execution

1. Parse `$ARGUMENTS` as:
   - first token: input path or URL
   - optional second token: output path
2. If input is a directory:
   - do not call `Read File` on the directory path
   - require output to be a directory path and convert supported files recursively
2. Run:

```bash
bash /home/vscode/.opencode/skills/markitdown-converter/scripts/convert.sh <input> [output]
```

3. If output path is provided, report the saved path(s).
4. If output path is omitted, return the generated Markdown in the response.
