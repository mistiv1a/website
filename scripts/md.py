import os
import re
import sys
import subprocess

FENCE_RE = re.compile(r'^(```|~~~).*?^\1[ \t]*$', re.MULTILINE | re.DOTALL)

# The site nav is inserted here, after conversion, so there is exactly one
# definition of it rather than a copy pasted into every source file.
BLOG_NAV = [
    ("首页", "/"),
    ("关于", "//mistivia.com"),
    ("友链", "/links/"),
    ("English", "/enposts/"),
    ("RSS", "/index.xml"),
]

PROJECT_NAV = [
    ("Projects", "../"),
    ("Home", "/"),
]

def render_nav(items):
    links = " · ".join(f'<a href="{href}">{text}</a>' for text, href in items)
    return f'<p><span class="masthead-nav">{links}</span></p>'

def nav_for(input_path):
    """Pick the nav belonging to the site this page is part of."""
    path = os.path.abspath(input_path).replace(os.sep, "/")
    if "/blog/" in path:
        return render_nav(BLOG_NAV)
    if "/homepage/projects/" in path:
        return render_nav(PROJECT_NAV)
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
<link rel="stylesheet" href="/style3.css">
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
    body = replace_markdown_links_in_file(body)
    chrome = "\n".join(x for x in (nav_for(input_file), pubdate_for(input_file)) if x)
    html_out = markdown_convert(title, body, chrome)
    print(template.format(title, html_out))

