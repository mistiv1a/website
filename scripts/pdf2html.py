import html
import sys
from pathlib import Path


def extract_title(src_path: Path) -> str:
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


def build_pdf_url(pdf_path: Path) -> str:
    parts = pdf_path.as_posix().split("/")
    if len(parts) <= 1:
        return "/" + pdf_path.name
    return "/" + "/".join(parts[1:])


def html_template(title: str, pdf_url: str, srctext: str = "") -> str:
    return f"""<!DOCTYPE html>
<html>
<head>
<title>{title}</title>
<meta charset="utf-8">
<link rel="stylesheet" href="/style6.css">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
    .pdf-wrapper {{
        width: 100%;
        height: 80vh;
        margin-bottom: 20px;
    }}
    .pdf-wrapper iframe {{
        width: 100%;
        height: 100%;
        border: none;
        display: block;
    }}
</style>
</head>
<body>
<div style="padding:0px 5px;">
<pre class="back"><a href="../">../</a></pre>
</div>
<pre style="position:absolute;left:-10000px;top:-10000px;opacity:0;width:1px;height:1px;overflow:hidden;">{srctext}</pre>
<div class="pdf-wrapper">
    <iframe src="/pdfjs/web/viewer.html?file={pdf_url}">
        <p><a href="{pdf_url}">{pdf_url}</a></p>
    </iframe>
</div>
<div style="padding:0px 5px;">
<hr>
<p id="email">Email: i (at) mistivia (dot) com</p>
</div>
<script>
var emailElement = document.getElementById('email');
var base64String = "RW1haWw6IGlAbWlzdGl2aWEuY29tCg==";
var decodedString = atob(base64String);
emailElement.innerHTML = decodedString;
</script>
</body>
<script>
var max = function(x, y) {{return x < y ? y : x}};
var seth;
seth = function() {{try{{document.getElementsByClassName('pdf-wrapper')[0].style.height = max(500, document.getElementsByTagName('iframe')[0].contentDocument.getElementById('viewer').scrollHeight) + 80 + 'px';}} catch (err) {{}} setTimeout(seth, 1000);}}
setTimeout(seth, 1000);
</script>
</html>
"""


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python scripts/pdf2html.py <path/to/file.pdf>", file=sys.stderr)
        return 1

    pdf_path = Path(sys.argv[1])
    if pdf_path.suffix.lower() != ".pdf":
        print(f"error: input is not a pdf file: {pdf_path}", file=sys.stderr)
        return 1

    base = pdf_path.with_suffix("")
    typ_path = base.with_suffix(".typ")
    tex_path = base.with_suffix(".tex")

    if typ_path.exists():
        src_path = typ_path
    elif tex_path.exists():
        src_path = tex_path
    else:
        print(f"error: cannot find sibling .typ or .tex for {pdf_path}", file=sys.stderr)
        return 1

    title = extract_title(src_path)
    pdf_url = build_pdf_url(pdf_path)
    src_text = src_path.read_text(encoding="utf-8")
    src_text_escaped = html.escape(src_text)
    print(html_template(title=title, pdf_url=pdf_url, srctext=src_text_escaped))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
