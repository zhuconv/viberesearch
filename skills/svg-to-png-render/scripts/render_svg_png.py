#!/usr/bin/env python3
from __future__ import annotations

import argparse
import http.server
import os
import re
import socket
import socketserver
import subprocess
import sys
import tempfile
import threading
from pathlib import Path
from xml.etree import ElementTree


def parse_length(value: str | None) -> int | None:
    if not value:
        return None
    match = re.match(r"^\s*([0-9]+(?:\.[0-9]+)?)", value)
    if not match:
        return None
    return round(float(match.group(1)))


def svg_dimensions(path: Path) -> tuple[int, int]:
    root = ElementTree.parse(path).getroot()
    width = parse_length(root.attrib.get("width"))
    height = parse_length(root.attrib.get("height"))
    if width and height:
        return width, height

    view_box = root.attrib.get("viewBox")
    if view_box:
        parts = [float(x) for x in re.split(r"[\s,]+", view_box.strip()) if x]
        if len(parts) == 4:
            return round(parts[2]), round(parts[3])

    raise SystemExit(f"Could not infer SVG dimensions from {path}")


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format: str, *args: object) -> None:
        pass


def start_server(root: Path) -> tuple[socketserver.TCPServer, int]:
    port = free_port()

    class Handler(QuietHandler):
        def __init__(self, *args: object, **kwargs: object) -> None:
            super().__init__(*args, directory=str(root), **kwargs)

    server = socketserver.TCPServer(("127.0.0.1", port), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server, port


def render(svg: Path, output: Path, width: int, height: int) -> None:
    with tempfile.TemporaryDirectory(prefix="svg-render-") as tmp:
        tmp_path = Path(tmp)
        served_svg = tmp_path / svg.name
        served_svg.write_bytes(svg.read_bytes())
        server, port = start_server(tmp_path)
        code_path = tmp_path / "render.js"
        session = f"svg-render-{os.getpid()}"
        codex_home = Path(os.environ.get("CODEX_HOME", str(Path.home() / ".codex")))
        wrapper = codex_home / "skills/playwright/scripts/playwright_cli.sh"
        if wrapper.exists():
            pwcli = ["sh", str(wrapper)]
        else:
            pwcli = ["npx", "--yes", "--package", "@playwright/cli", "playwright-cli"]

        code_path.write_text(
            f"""
async (page) => {{
  await page.setViewportSize({{ width: {width}, height: {height} }});
  await page.goto('http://127.0.0.1:{port}/{served_svg.name}', {{
    waitUntil: 'domcontentloaded',
    timeout: 15000
  }});
  await page.screenshot({{
    path: {str(output)!r},
    clip: {{ x: 0, y: 0, width: {width}, height: {height} }},
    scale: 'css',
    type: 'png'
  }});
}}
""".strip()
        )

        try:
            subprocess.run(
                [*pwcli, "--session", session, "open", "about:blank"],
                check=True,
            )
            result = subprocess.run(
                [*pwcli, "--session", session, "run-code", "--filename", str(code_path)],
                check=False,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
            )
            if not output.exists():
                print(result.stdout, file=sys.stderr)
                raise SystemExit(result.returncode or 1)
        finally:
            subprocess.run([*pwcli, "--session", session, "close"], check=False)
            server.shutdown()


def verify_png(path: Path, width: int, height: int) -> None:
    try:
        from PIL import Image
    except Exception:
        print(f"Rendered {path}; expected dimensions {width}x{height}. Install Pillow for automatic dimension verification.")
        return

    with Image.open(path) as image:
        actual = image.size
    if actual != (width, height):
        raise SystemExit(f"PNG dimensions mismatch: expected {width}x{height}, got {actual[0]}x{actual[1]}")
    print(f"Rendered {path} ({width}x{height})")


def main() -> None:
    parser = argparse.ArgumentParser(description="Render an SVG to an exact-dimension PNG using Playwright/Chromium.")
    parser.add_argument("svg", type=Path)
    parser.add_argument("png", type=Path)
    parser.add_argument("--width", type=int)
    parser.add_argument("--height", type=int)
    args = parser.parse_args()

    svg = args.svg.resolve()
    output = args.png.resolve()
    if not svg.exists():
        raise FileNotFoundError(svg)

    inferred_width, inferred_height = svg_dimensions(svg)
    width = args.width or inferred_width
    height = args.height or inferred_height

    output.parent.mkdir(parents=True, exist_ok=True)
    render(svg, output, width, height)
    verify_png(output, width, height)


if __name__ == "__main__":
    main()
