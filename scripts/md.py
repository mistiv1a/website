import json
import os
import re
import sys
import subprocess

FENCE_RE = re.compile(r'^(```|~~~).*?^\1[ \t]*$', re.MULTILINE | re.DOTALL)
INLINE_CODE_RE = re.compile(r'(?<!`)(`+)(?!`).+?(?<!`)\1(?!`)', re.DOTALL)

# --- Math -----------------------------------------------------------------
# Formulas are rendered to HTML at build time with KaTeX, so pages carry no
# math JavaScript and load nothing from a CDN. The stylesheet and fonts are
# served from the site itself (blog/katex.min.css, blog/fonts/).
KATEX_JS = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "vendor", "katex.min.js")
KATEX_CSS_LINK = '<link rel="stylesheet" href="/katex.min.css">'

DISPLAY_MATH_RE = re.compile(r'\$\$(.+?)\$\$', re.DOTALL)
INLINE_MATH_RE = re.compile(r'(?<!\$)\$(?!\s)([^\n$]+?)(?<!\s)\$(?!\$)')

NODE_RENDER = """
const katex = require(process.argv[1]);
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', d => input += d);
process.stdin.on('end', () => {
  const items = JSON.parse(input);
  const out = items.map(it =>
    katex.renderToString(it.tex, {
      displayMode: it.display,
      throwOnError: true,
      strict: 'ignore',
    })
  );
  process.stdout.write(JSON.stringify(out));
});
"""

def render_math(items):
    """Render [(tex, display), ...] to KaTeX HTML in one node process."""
    if not items:
        return []
    payload = json.dumps([{"tex": t, "display": d} for t, d in items])
    result = subprocess.run(
        ["node", "-e", NODE_RENDER, KATEX_JS],
        input=payload, capture_output=True, text=True,
    )
    if result.returncode != 0:
        sys.exit(f"KaTeX failed:\n{result.stderr.strip()}")
    return json.loads(result.stdout)

def protect_math(content):
    """Swap math for inert placeholders before the markdown pass.

    Markdown would otherwise eat backslashes and underscores inside formulas,
    and --smart would turn quotes and -- into typographic forms. Code spans and
    fenced blocks are skipped so a literal $ in a shell snippet stays literal.
    """
    items = []

    def stash(tex, display):
        items.append((tex.strip(), display))
        return f"zzmath{len(items) - 1}zz"

    def scan(text):
        text = DISPLAY_MATH_RE.sub(lambda m: stash(m.group(1), True), text)
        text = INLINE_MATH_RE.sub(lambda m: stash(m.group(1), False), text)
        return text

    # walk the text, leaving fenced blocks and inline code untouched
    out, pos = [], 0
    for m in FENCE_RE.finditer(content):
        out.append(_scan_outside_code(content[pos:m.start()], scan))
        out.append(m.group(0))
        pos = m.end()
    out.append(_scan_outside_code(content[pos:], scan))
    return "".join(out), items

def _scan_outside_code(text, scan):
    out, pos = [], 0
    for m in INLINE_CODE_RE.finditer(text):
        out.append(scan(text[pos:m.start()]))
        out.append(m.group(0))
        pos = m.end()
    out.append(scan(text[pos:]))
    return "".join(out)

def restore_math(html_text, rendered):
    for i, frag in enumerate(rendered):
        token = f"zzmath{i}zz"
        # a display formula sits alone in its own paragraph; unwrap it
        html_text = html_text.replace(f"<p>{token}</p>", frag)
        html_text = html_text.replace(token, frag)
    return html_text

# The site nav is inserted here, after conversion, so there is exactly one
# definition of it rather than a copy pasted into every source file.
# Addresses are absolute because this same nav is served from two hosts
# (mistivia.com and blog.mistivia.com); a site-relative "/links/" would point
# at mistivia.com/links/ when the nav appears on the homepage.
# Note: "关于" is written without a trailing slash so sync.sh's yggdrasil
# rewrite of href="//mistivia.com" keeps matching.
BLOG_NAV = [
    ("博客", "//blog.mistivia.com/"),
    ("关于", "//mistivia.com"),
    ("友链", "//blog.mistivia.com/links/"),
    ("English", "//blog.mistivia.com/enposts/"),
    ("RSS", "//blog.mistivia.com/index.xml"),
]

def render_nav(items):
    links = " · ".join(f'<a href="{href}">{text}</a>' for text, href in items)
    return f'<p><span class="masthead-nav">{links}</span></p>'

def nav_for(input_path):
    """Pick the nav belonging to the site this page is part of."""
    path = os.path.abspath(input_path).replace(os.sep, "/")
    if "/blog/" in path or path.endswith("/homepage/index.md"):
        return render_nav(BLOG_NAV)
    return ""

# A post lives in a directory named YYYY-MM-DD-slug; that name is the single
# source of the publication date, so it is never written by hand in the body.
POST_DIR_RE = re.compile(r'^(\d{4})-(\d{2})-(\d{2})-')

EN_MONTHS = ["January", "February", "March", "April", "May", "June", "July",
             "August", "September", "October", "November", "December"]

def pubdate_for(input_path):
    path = os.path.abspath(input_path).replace(os.sep, "/")
    m = POST_DIR_RE.match(os.path.basename(os.path.dirname(path)))
    if not m:
        return ""
    year, month, day = int(m.group(1)), int(m.group(2)), int(m.group(3))
    if "/enposts/" in path:
        text = f"{EN_MONTHS[month - 1]} {day}, {year}"
    else:
        text = f"{year}年{month}月{day}日"
    return f'<p><span class="pubdate">{text}</span></p>'

def _rewrite_links(content):
    pattern_image_link = re.compile(r'!\[([^\]]+?)\]\((.+?)\)')
    pattern_new_link = re.compile(r'~\[([^\]]+?)\]\((.+?)\)')
    content = pattern_new_link.sub(r'<a href="\2" target="_blank">\1</a>', content)
    content = pattern_image_link.sub(r'<a href="\2" target="_blank"><img src="\2" alt="\1" style="max-width:300px;max-height:300px;"></a>', content)
    return content

def replace_markdown_links_in_file(content):
    """Rewrite links outside fenced code blocks, leaving code verbatim."""
    out = []
    pos = 0
    for m in FENCE_RE.finditer(content):
        out.append(_rewrite_links(content[pos:m.start()]))
        out.append(m.group(0))
        pos = m.end()
    out.append(_rewrite_links(content[pos:]))
    return ''.join(out)

template = """
<!DOCTYPE html>
<html>
<head>
<title>{}</title>
<meta charset="utf-8">
<link rel="stylesheet" href="/style3.css">{}
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
{}

<hr>
<p id="email">Email: i (at) mistivia (dot) com</p>
<script>
var emailElement = document.getElementById('email');
var base64String = "RW1haWw6IGlAbWlzdGl2aWEuY29tCg==";
var decodedString = atob(base64String);
emailElement.innerHTML = decodedString;
</script>
</body>
</html>
"""

def markdown_convert(title, body, chrome=""):
    html_title = f"<h1>{title}</h1>"
    try:
        # cmark-gfm rather than discount: discount mis-parses fenced code
        # blocks, folding the paragraph that follows one into the same <p> as
        # the <pre>. --unsafe keeps the raw HTML spans the pages rely on.
        result = subprocess.run(
            ["cmark-gfm", "--unsafe", "--smart",
             "-e", "table", "-e", "strikethrough"],
            input=body,
            capture_output=True,
            text=True,
            check=True
        )
        html_body = result.stdout.strip()

    except FileNotFoundError:
        return "error: cannot find 'cmark-gfm' command"
    
    except subprocess.CalledProcessError as e:
        return (f"error:：Markdown convert cmd failed (exit code: {e.returncode})."
                f"\nerr msg: {e.stderr}")
    parts = [html_title]
    if chrome:
        parts.append(chrome)
    parts.append(html_body)
    return "\n".join(parts)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage：python your_script_name.py <input_file_path>")
        sys.exit(1)
    input_file = sys.argv[1]
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    title = content.splitlines(1)[0].strip()
    body = ''.join(content.splitlines(1)[2:])
    body, math_items = protect_math(body)
    body = replace_markdown_links_in_file(body)
    chrome = "\n".join(x for x in (nav_for(input_file), pubdate_for(input_file)) if x)
    html_out = markdown_convert(title, body, chrome)
    html_out = restore_math(html_out, render_math(math_items))
    head_extra = "\n" + KATEX_CSS_LINK if math_items else ""
    print(template.format(title, head_extra, html_out))

