#!/usr/bin/env python3
"""Auto-generate blog/index.md from post directories."""

from pathlib import Path
import re

BLOG_DIR = Path(__file__).resolve().parent
POSTS_DIR = BLOG_DIR / "posts"
INDEX_MD = BLOG_DIR / "index.md"

HEADER = """Scriptum Mistiviae
========

"""

def extract_title(index_typ: Path) -> str:
    """Extract the title from a post's index.typ file."""
    text = index_typ.read_text(encoding="utf-8")
    m = re.search(r'^\s*title:\s*"((?:[^"\\]|\\.)*)"', text, re.MULTILINE)
    if m:
        # Unescape \n to actual newline, then collapse all whitespace
        raw = m.group(1).replace("\\n", "")
        return raw.strip()
    raise SystemExit(f"Cannot find title in {index_typ}")

def extract_title_md(index_md: Path) -> str:
    """Extract the title from a markdown post: its first line."""
    text = index_md.read_text(encoding="utf-8")
    title = text.splitlines()[0].strip() if text.splitlines() else ""
    if title:
        return title
    raise SystemExit(f"Cannot find title in {index_md}")

def main():
    posts = []
    for d in sorted(POSTS_DIR.iterdir()):
        if not d.is_dir():
            continue
        # Match YYYY-MM-DD-slug pattern
        m = re.match(r'^(\d{4})-(\d{2})-(\d{2})-(.+)$', d.name)
        if not m:
            continue
        date_str = f"{m.group(1)}-{m.group(2)}-{m.group(3)}"
        slug = m.group(4)
        # Posts are being migrated from typst to markdown; accept either.
        index_typ = d / "index.typ"
        index_md = d / "index.md"
        if index_md.exists():
            title = extract_title_md(index_md)
        elif index_typ.exists():
            title = extract_title(index_typ)
        else:
            print(f"Warning: no index.typ or index.md in {d}, skipping")
            continue
        posts.append((date_str, slug, title))

    # Sort by date descending
    posts.sort(key=lambda x: x[0], reverse=True)

    lines = [HEADER]
    for date_str, slug, title in posts:
        lines.append(
            f'- <span class="pdate">{date_str}</span>'
            f'[{title}](/posts/{date_str}-{slug}/)\n'
        )

    INDEX_MD.write_text("".join(lines).rstrip("\n") + "\n\n", encoding="utf-8")
    print(f"Generated {INDEX_MD} with {len(posts)} posts")

if __name__ == "__main__":
    main()
