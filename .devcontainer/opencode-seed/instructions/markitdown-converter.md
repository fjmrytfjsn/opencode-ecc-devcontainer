When users ask to read, summarize, or analyze non-Markdown sources (PDF, DOCX, PPTX, HTML, image-derived text, or URLs), first convert the source with `/to-markdown`.

Guidelines:
- Prefer `/to-markdown <input> <output.md>` for large inputs.
- For small inputs, `/to-markdown <input>` and return inline Markdown is acceptable.
- After conversion, continue analysis using the Markdown output only.
