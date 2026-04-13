When users ask to read, summarize, or analyze non-Markdown sources (PDF, DOCX, PPTX, HTML, image-derived text, or URLs), first convert the source with the `markitdown` MCP tool (`convert_to_markdown`).

Guidelines:
- Prefer MCP conversion first; use `/to-markdown` only as a fallback when MCP is unavailable.
- Prefer `/to-markdown <input> <output.md>` for large inputs.
- If `<input>` is a directory, never use `Read File` on that directory path; run `/to-markdown <input-dir> <output-dir>` instead.
- For small inputs, `/to-markdown <input>` and return inline Markdown is acceptable.
- After conversion, continue analysis using the Markdown output only.
