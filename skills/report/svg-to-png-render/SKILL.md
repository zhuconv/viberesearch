---
name: svg-to-png-render
description: Render SVG files to exact-dimension PNG screenshots using a real Chromium browser. Use when Codex needs to convert an SVG diagram or vector artifact into a PNG for GitHub README display, documentation, visual verification, or non-cropped export, especially when sips, qlmanage, ImageMagick, or direct file:// Playwright loading fail.
---

# SVG To PNG Render

## Workflow

Use the bundled script first:

```bash
SCRIPT="$(find "${CODEX_HOME:-$HOME/.codex}" "$HOME/.claude" \
  -path "*/skills/svg-to-png-render/scripts/render_svg_png.py" \
  -print -quit 2>/dev/null)"
python3 "$SCRIPT" input.svg output.png
```

If working from the viberesearch repository itself, use
`skills/svg-to-png-render/scripts/render_svg_png.py` directly.

The script:

- Reads the SVG `width`/`height` or `viewBox`.
- Starts a localhost-only HTTP server.
- Opens `about:blank` with the Playwright CLI, then runs `page.goto(...)` and `page.screenshot(...)` through `run-code --filename`.
- Verifies the output dimensions.

Use this instead of `sips` or `qlmanage` for diagrams. On macOS, `sips` often cannot rasterize SVG, and `qlmanage` can create cropped or thumbnail-style output.

## Requirements

- `node` and `npx` must be on PATH.
- Playwright can be downloaded through `npx --package playwright`.
- If browser binaries are missing, use the existing Playwright setup or set `PLAYWRIGHT_BROWSERS_PATH` to a writable cache and install browsers.

## Notes

- Do not load local SVGs with Playwright CLI `file://`; this environment can block `file:` protocol.
- The CLI may print `TimeoutError` after writing the screenshot because it tries to snapshot the page afterward. Treat the file existence and dimension check as the source of truth.
- For repo diagrams, inspect the generated PNG dimensions and use `view_image` for visual confirmation before committing.
