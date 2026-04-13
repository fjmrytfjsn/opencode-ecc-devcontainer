---
name: markitdown-converter
description: Convert files and URLs into Markdown so AI agents can reliably read and reason over mixed-format content.
origin: opencode-ecc-devcontainer
---

# MarkItDown Converter

Use this skill when you need to transform non-Markdown sources (PDF, Office docs, HTML, images with OCR-capable inputs, etc.) into Markdown before analysis.

## When to Activate

- User asks to summarize or extract data from files that are not already Markdown
- User provides URLs or documents that should be converted for downstream AI workflows
- You need a consistent Markdown representation before chunking, indexing, or prompt injection checks

## OpenChamber Usage

1. Explicit command:
   - `/to-markdown <input> [output.md]`
2. Natural language:
   - Ask normally (e.g. "このPDFをMarkdown化して"), then route through `/to-markdown`

## Notes

- If output is large, prefer writing to a file and then summarizing key sections.
- Preserve the generated Markdown as an artifact when reproducibility is needed.
- When the input is a directory, pass an output directory and convert files in bulk instead of reading the directory as a file.
