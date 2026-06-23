#!/usr/bin/env python3
import html
import sys
import subprocess
import os
import glob
import shutil
import json
import tempfile
from pathlib import Path
import urllib.parse

CSS_STYLES = """
"""

def get_project_root() -> Path:
    """Get the project root directory (where this script is located/..)"""
    script_path = Path(__file__).resolve()
    return script_path.parent.parent

def extract_title(src_path: Path) -> str:
    """Extract title from the first line of source file"""
    if not src_path.exists():
        return src_path.stem
    text = src_path.read_text(encoding="utf-8")
    first_line = text.splitlines()[0] if text.splitlines() else ""
    line = first_line.strip()
    if line.startswith("//"):
        return line[2:].strip() or src_path.stem
    if line.startswith("%"):
        return line.lstrip("%").strip() or src_path.stem
    return src_path.stem

def compile_typ_to_svgs(typ_path: Path, project_root: Path, output_dir: Path, base_name: str) -> list[str]:
    """Compile typst file to multiple SVG files in the output directory"""
    # Create temp directory for SVG output first
    with tempfile.TemporaryDirectory() as tmpdir:
        # Calculate relative path from project root
        try:
            rel_path = typ_path.relative_to(project_root)
        except ValueError:
            rel_path = typ_path
        
        # Output pattern: page-01.svg, page-02.svg, etc.
        output_pattern = os.path.join(tmpdir, "page-{0p}.svg")
        
        # Run typst compile
        cmd = [
            "typst", "compile",
            "--root", str(project_root),
            str(rel_path),
            output_pattern
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Error compiling typst: {result.stderr}", file=sys.stderr)
            raise SystemExit(1)
        
        # Collect generated SVG files
        svg_files = sorted(glob.glob(os.path.join(tmpdir, "page-*.svg")))
        if not svg_files:
            print("Error: No SVG files generated", file=sys.stderr)
            raise SystemExit(1)
        
        # Move SVG files to output directory with proper naming
        svg_names = []
        for i, svg_file in enumerate(svg_files, 1):
            # Name: base-01.svg, base-02.svg, etc.
            svg_name = f"{base_name}-{i:02d}.svg"
            svg_path = output_dir / svg_name
            # Read SVG content, process xlink:href links, then write
            svg_content = Path(svg_file).read_text(encoding="utf-8")
            svg_content = svg_content.replace('xlink:href="http', 'target="_top" xlink:href="http')
            svg_path.write_text(svg_content, encoding="utf-8")
            svg_names.append(svg_name)
        
        return svg_names

def fnv1a(s: str):
    hash_val = 0x811c9dc5 # FNV offset basis
    for char in s:
        hash_val ^= ord(char)
        hash_val = (hash_val * 0x01000193) & 0xFFFFFFFF
    return str(hash_val)

def hashxor(key, plaintext: str) -> str:
    ciphertext = []
    current_key = str(key)

    for p_char in plaintext:
        k_byte = ord(current_key[0])
        p_byte = ord(p_char)
        xor_char = chr(k_byte ^ p_byte)
        ciphertext.append(xor_char)
        
        current_key = fnv1a(current_key)
    return "".join(ciphertext)

js = '''
function fnv1a(str) {
    let hash = 0x811c9dc5;
    for (let i = 0; i < str.length; i++) {
        hash ^= str.charCodeAt(i);
        hash = Math.imul(hash, 0x01000193);
    }
    return (hash >>> 0).toString();
}

function hashxor(key, plaintext) {
    let ciphertext = "";
    let currentKey = key.toString();

    for (let i = 0; i < plaintext.length; i++) {
        let kByte = currentKey.charCodeAt(0);
        let pByte = plaintext.charCodeAt(i);
        let xorResult = kByte ^ pByte;
        ciphertext += String.fromCharCode(xorResult);
        currentKey = fnv1a(currentKey);
    }
    return ciphertext;
}

function getKey(cur, n, cont) {
    if (n == 5) {
        cont(cur);
        return;
    }
    for (let i = 0; i < 2000000; i++) { 
        cur = fnv1a(cur);
    }
    setTimeout(function() {getKey(cur, n+1, cont);}, 0);
}

function rendersrc(txt) {
    document.getElementById('srctext').innerHTML =
        document.getElementById('srctext').innerHTML + txt;
}

setTimeout(function() {
    getKey('mistivia', 0, function(key) {
        rendersrc(hashxor(key, ciphertext));
    })
}, 0)

'''

def gen_cipherdiv(plaintext):
    return f'''
    <script>
        let ciphertext = {json.dumps(hashxor('1755283311', plaintext))};
        {js}
    </script>
    '''

def create_en_link(srctext):
    base_url = "https://translate.google.com/"
    params = {
        "sl": "auto",
        "tl": "en",
        "text": srctext,
        "op": "translate"
    }
    query_string = urllib.parse.urlencode(params)
    return f"{base_url}?{query_string}"

def build_html(svg_names: list[str], title: str, srctext: str = "") -> str:
    """Build HTML with object tags referencing SVG files"""
    # Wrap each SVG object in a page div
    page_divs = []
    for svg_name in svg_names:
        page_divs.append(f'''<div class="ipadding"><div class="page">
<object data="{svg_name}" type="image/svg+xml" style="width:100%;height:auto;display:block;"></object>
</div></div>''')
    
    pages_html = '\n'.join(page_divs)
    english_link = create_en_link(srctext)
    return f'''<!DOCTYPE html>
<html>
<head>
<title>{title}</title>
<meta charset="utf-8">
<link rel="stylesheet" href="/style5.css">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="description" content="Type: Blog Article, Author: Mistivia, Title: {title}">
</head>
<body>
<div class="ipadding">
<pre class="back" style="display: flex; justify-content: space-between; align-items: center;">
    <a href="../">../</a>
</pre>
<script>
    if (window.location.hostname.endsWith('translate.goog')) {{
        var myRealDomain = "blog.mistivia.com"; 
        var currentPath = window.location.pathname;
        window.location.replace("https://" + myRealDomain + currentPath);
    }}
</script>
</div>
<style>
.visually-hidden {{
    position: absolute;
    left: -999px;
    width: 100px;
    height: 100px;
    overflow: hidden;
}}
</style>
<main>
<p id="srctext" class="visually-hidden">
    {srctext.replace('\n', '<br>').replace(' ', '&#32;')}
</p>
</main>
<div class="content">
{pages_html}
</div>
<div class="ipadding">
<hr>
<p id="email">Email: i (at) mistivia (dot) com</p>
</div>
<script>
var emailElement = document.getElementById('email');
var base64String = "RW1haWw6IGlAbWlzdGl2aWEuY29tCg==";
var decodedString = atob(base64String);
emailElement.innerHTML = decodedString;
</script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){{dataLayer.push(arguments);}}
  gtag('js', new Date());

  gtag('config', 'G-DRZ9ESWCVM');
</script>
</body>
</html>
'''

def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: python scripts/typ2html.py <path/to/file.typ> <path/to/output.html>", file=sys.stderr)
        return 1

    typ_path = Path(sys.argv[1])
    html_path = Path(sys.argv[2])
    
    if typ_path.suffix.lower() != ".typ":
        print(f"error: input is not a typst file: {typ_path}", file=sys.stderr)
        return 1

    if not typ_path.exists():
        print(f"error: file not found: {typ_path}", file=sys.stderr)
        return 1

    project_root = get_project_root()
    
    # Ensure output directory exists
    html_path.parent.mkdir(parents=True, exist_ok=True)
    output_dir = html_path.parent
    
    # Use HTML stem as base name for SVG files
    base_name = html_path.stem
    
    # Extract title and source text
    title = extract_title(typ_path)
    src_text = typ_path.read_text(encoding="utf-8")
    src_text_escaped = html.escape(src_text)
    
    # Compile to SVGs (saved to output directory)
    svg_names = compile_typ_to_svgs(typ_path, project_root, output_dir, base_name)
    
    # Build HTML
    html_output = build_html(svg_names, title, src_text_escaped)
    
    # Write HTML to file
    html_path.write_text(html_output, encoding="utf-8")
    print(f"Generated {html_path}")
    for svg_name in svg_names:
        print(f"  with {svg_name}")
    
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
