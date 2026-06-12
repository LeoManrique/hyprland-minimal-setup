#!/usr/bin/env python3
"""Convert the mirrored Hyprland wiki (HTML) to Markdown.

Walks every *.html under SRC, extracts the main article (<main id="content">),
converts it to Markdown, and writes a parallel tree under DST.

Usage:
    pip install markdownify beautifulsoup4
    python3 html2md.py [SRC] [DST]

Defaults: SRC=./v0.55.4  DST=./v0.55.4-md
"""
import sys
from pathlib import Path

from bs4 import BeautifulSoup
from markdownify import markdownify as md

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else "v0.55.4")
DST = Path(sys.argv[2] if len(sys.argv) > 2 else "v0.55.4-md")


def convert(html: str) -> str:
    soup = BeautifulSoup(html, "html.parser")
    main = soup.select_one("main#content") or soup.body or soup
    # Drop obvious non-content (page nav, edit links, breadcrumbs, scripts)
    for sel in ("nav", "script", "style", ".breadcrumb", ".hextra-toc"):
        for tag in main.select(sel):
            tag.decompose()
    return md(str(main), heading_style="ATX", bullets="-", code_language="").strip()


def main() -> None:
    files = sorted(SRC.rglob("*.html"))
    if not files:
        sys.exit(f"No .html files under {SRC}")
    for f in files:
        rel = f.relative_to(SRC).with_suffix(".md")
        out = DST / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(convert(f.read_text(encoding="utf-8", errors="replace")),
                       encoding="utf-8")
        print(rel)
    print(f"\nDone: {len(files)} files -> {DST}")


if __name__ == "__main__":
    main()
