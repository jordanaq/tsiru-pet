#!/usr/bin/env python3
"""Assert the shared header geometry is identical on every page.

Renders each page in headless Chromium and compares the `.avatar` rect, so a
page that overrides the hero's styling fails the build instead of quietly
looking different. This is the guard for the class of bug that made the
résumé avatar sit 1.5px off the home page's.

Geometry is read from the DOM (same-origin iframe -> getBoundingClientRect),
not from pixels, so it is exact and independent of fonts or rendering.

Requires a built ./public and chromium on PATH (override with $CHROMIUM).
"""
from __future__ import annotations

import functools
import http.server
import json
import os
import re
import shutil
import socketserver
import subprocess
import sys
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUBLIC = ROOT / "public"
PAGES = ["/", "/resume/"]
WRAPPER = "_layout-check.html"
VIEWPORT = "900,700"

WRAPPER_HTML = """<!doctype html>
<meta charset="utf-8">
<iframe id="f" src="__PAGE__" style="width:900px;height:700px;border:0"></iframe>
<pre id="out">pending</pre>
<script>
document.getElementById('f').addEventListener('load', function () {
  var d = this.contentDocument;
  var a = d.querySelector('.avatar');
  var r = a ? a.getBoundingClientRect() : null;
  document.getElementById('out').textContent = JSON.stringify({
    viewport: d.documentElement.clientWidth,
    avatar: r ? { x: r.x, y: r.y, width: r.width, height: r.height } : null
  });
});
</script>
"""


def chromium() -> str | None:
    return os.environ.get("CHROMIUM") or shutil.which("chromium") or shutil.which("chromium-browser")


class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):  # keep make output clean
        pass


def serve(directory: Path) -> tuple[socketserver.TCPServer, int]:
    handler = functools.partial(Quiet, directory=str(directory))
    httpd = socketserver.TCPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd, httpd.server_address[1]


def measure(binary: str, base: str, page: str) -> dict:
    (PUBLIC / WRAPPER).write_text(WRAPPER_HTML.replace("__PAGE__", page))
    try:
        out = subprocess.run(
            [binary, "--headless=new", "--no-sandbox", "--disable-gpu",
             "--virtual-time-budget=4000", "--window-size=" + VIEWPORT,
             "--dump-dom", f"{base}/{WRAPPER}"],
            capture_output=True, text=True, timeout=90,
        ).stdout
        m = re.search(r'<pre id="out">(.*?)</pre>', out, re.S)
        if not m or m.group(1) == "pending":
            raise SystemExit(f"error: no geometry for {page} (iframe never loaded)")
        return json.loads(m.group(1))
    finally:
        (PUBLIC / WRAPPER).unlink(missing_ok=True)


def main() -> int:
    if not (PUBLIC / "index.html").exists():
        print("error: ./public not built — run `make build` first")
        return 2

    binary = chromium()
    if not binary:
        print("SKIP  layout guard did not run — chromium not found (set $CHROMIUM)")
        return 0

    httpd, port = serve(PUBLIC)
    base = f"http://127.0.0.1:{port}"
    try:
        results = {p: measure(binary, base, p) for p in PAGES}
    finally:
        httpd.shutdown()
        (PUBLIC / WRAPPER).unlink(missing_ok=True)

    for page, data in results.items():
        a = data["avatar"]
        if a is None:
            print(f"FAIL  {page} has no .avatar — does it extend page.html?")
            return 1
        print(f"PASS  {page:10} avatar x={a['x']:.1f} y={a['y']:.1f} "
              f"w={a['width']:.1f} h={a['height']:.1f} (viewport {data['viewport']})")

    reference = results[PAGES[0]]
    drift = {p: d for p, d in results.items() if d != reference}
    if drift:
        print("\nFAIL  header geometry differs between pages:")
        for page, d in drift.items():
            print(f"      {page}: {d['avatar']} vs {reference['avatar']}")
        return 1

    print("\nlayout: identical on all pages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
