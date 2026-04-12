---
description: Convert files/URLs to Markdown via MarkItDown
agent: build
---

# to-markdown

Convert source content into Markdown using MarkItDown.

## Usage

`/to-markdown <input-path-or-url> [output.md]`

## Execution

1. Parse `$ARGUMENTS` as:
   - first token: input path or URL
   - optional second token: output file path
2. Run:

```bash
bash /home/vscode/.opencode/skills/markitdown-converter/scripts/convert.sh <input> [output]
```

3. If output path is provided, report the saved path.
4. If output path is omitted, return the generated Markdown in the response.
