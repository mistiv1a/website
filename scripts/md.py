import json
import os
import re
import sys
import subprocess
import glob
import uuid

FENCE_RE = re.compile(r'^(```|~~~).*?^\1[ \t]*$', re.MULTILINE | re.DOTALL)
INLINE_CODE_RE = re.compile(r'(?<!`)(`+)(?!`).+?(?<!`)\1(?!`)', re.DOTALL)

# --- Math -----------------------------------------------------------------
# Formulas are rendered to HTML at build time with KaTeX, so pages carry no
# math JavaScript and load nothing from a CDN. The stylesheet and fonts are
# served from the site itself (blog/katex.min.css, blog/fonts/).
KATEX_JS = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "vendor", "katex.min.js")
KATEX_CSS_LINK = '<link rel="stylesheet" href="/katex.min.css">'

# --- Serif webfont ---------------------------------------------------------
# Each page carries two character-subsetted woff2 faces: Source Han Serif CN
# SemiBold for headings and FZNewShuSong (方正新书宋) for body text, so CJK
# text is reliably serif on platforms without a serif CJK face (iOS).
# fontTools lives in scripts/vendor; if absent the build still succeeds and
# pages simply fall back to the system serif stack.
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "vendor"))
try:
    from fontTools.subset import Options, Subsetter
    from fontTools.ttLib import TTFont
    HAS_FONTTOOLS = True
except Exception:
    HAS_FONTTOOLS = False

SERIF_BODY_FAMILY = "SiteSerifBody"
SERIF_HEADING_FAMILY = "SiteSerifHeading"
SERIF_BODY_FONT = "serif-body-subset.woff2"
SERIF_HEADING_FONT = "serif-heading-subset.woff2"
SERIF_BODY_SOURCE = os.environ.get(
    "SERIF_BODY_FONT_SRC", "/usr/share/fonts/FZXSSJW.TTF")
SERIF_HEADING_SOURCE = os.environ.get(
    "SERIF_HEADING_FONT_SRC",
    "/usr/share/fonts/adobe-source-han-serif/SourceHanSerifCN-SemiBold.otf")

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
    ("订阅", "//blog.mistivia.com/index.xml"),
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

IMAGE_LINK_RE = re.compile(r'!\[([^\]]*?)\]\((.+?)\)')
NEW_LINK_RE = re.compile(r'~\[([^\]]+?)\]\((.+?)\)')

# Elsewhere an image is a thumbnail that opens full size; in an article the
# photographs are the content, so they run the width of the text column.
THUMB_STYLE = ' style="max-width:300px;max-height:300px;"'

def _rewrite_links(content, thumb=True):
    style = THUMB_STYLE if thumb else ""
    content = NEW_LINK_RE.sub(r'<a href="\2" target="_blank">\1</a>', content)
    content = IMAGE_LINK_RE.sub(
        rf'<a href="\2" target="_blank"><img src="\2" alt="\1"{style}></a>',
        content)
    return content

def replace_markdown_links_in_file(content, thumb=True):
    """Rewrite links outside fenced code blocks, leaving code verbatim."""
    out = []
    pos = 0
    for m in FENCE_RE.finditer(content):
        out.append(_rewrite_links(content[pos:m.start()], thumb))
        out.append(m.group(0))
        pos = m.end()
    out.append(_rewrite_links(content[pos:], thumb))
    return ''.join(out)

ARTICLE_PATH_RE = re.compile(r"/blog/(?:posts|enposts)/[^/]+/index\.(?:md|typ)$")

def is_article(input_path):
    path = os.path.abspath(input_path).replace(os.sep, "/")
    return bool(ARTICLE_PATH_RE.search(path))

def find_font_source(path):
    return path if path and os.path.isfile(path) else None

def make_serif_subset(font_path, chars, out_path, keep_ascii=False):
    """Build a woff2 containing exactly the glyphs given.

    By default only non-ASCII glyphs are kept, so the body face never
    shadows the Latin stack (Palatino). Headings pass keep_ascii=True: the
    whole heading, Latin and CJK alike, is set in Source Han Serif.
    """
    if not HAS_FONTTOOLS or not font_path:
        return False
    if keep_ascii:
        chars = set(chars)
    else:
        chars = {ch for ch in chars if ord(ch) > 0x7e}
    chars.update("，。、；：？！“”‘’（）《》〈〉【】—…「」·")
    if not chars:
        return False
    try:
        font = TTFont(font_path)
        options = Options()
        options.flavor = "woff2"
        subsetter = Subsetter(options)
        subsetter.populate(text="".join(chars))
        subsetter.subset(font)
        font.save(out_path)
        font.close()
        return True
    except Exception as e:
        print(f"warning: serif subset failed for {out_path}: {e}",
              file=sys.stderr)
        return False

HEADING_TAG_RE = re.compile(r"<h[1-6][^>]*>(.*?)</h[1-6]>", re.S)

def serif_face_extra(input_path, html_text):
    """Write per-page subsets and return <style> content ("" if skipped).

    Each page owns a namespaced pair of files
    (serif-body-<slug>-<rand>.woff2 etc.), so pages that share an output
    directory (e.g. AGENTS.md and CLAUDE.md in the repo root) never delete
    each other's fonts. A fresh random suffix defeats stale HTTP caches;
    superseded files of the same page are removed after the new ones are
    safely on disk.
    """
    out_dir = os.path.dirname(os.path.abspath(input_path))
    slug = os.path.splitext(os.path.basename(input_path))[0].lower()
    rand = uuid.uuid4().hex[:8]
    body_font_name = f"serif-body-{slug}-{rand}.woff2"
    heading_font_name = f"serif-heading-{slug}-{rand}.woff2"
    body_font = os.path.join(out_dir, body_font_name)
    heading_font = os.path.join(out_dir, heading_font_name)

    heading_text = "".join(HEADING_TAG_RE.findall(html_text))
    body_html = HEADING_TAG_RE.sub("", html_text)
    body_ok = make_serif_subset(find_font_source(SERIF_BODY_SOURCE),
                                body_html, body_font)
    heading_ok = make_serif_subset(find_font_source(SERIF_HEADING_SOURCE),
                                   heading_text, heading_font, keep_ascii=True)

    if body_ok:
        for old in glob.glob(os.path.join(out_dir, f"serif-body-{slug}*.woff2")):
            if old != body_font:
                try:
                    os.remove(old)
                except OSError:
                    pass
    if heading_ok:
        for old in glob.glob(os.path.join(out_dir, f"serif-heading-{slug}*.woff2")):
            if old != heading_font:
                try:
                    os.remove(old)
                except OSError:
                    pass

    # CJK range: Latin stays on Palatino, while CJK ideographs (simplified
    # and traditional), Japanese kana, Korean hangul and CJK extensions B-F
    # all fall on the serif webfont.
    CJK_RANGE = "U+1100-11FF,U+2E80-FFFF,U+10000-10FFFF"

    faces = []
    if body_ok:
        faces.append(
            f'@font-face{{font-family:"{SERIF_BODY_FAMILY}";'
            f'src:url("{body_font_name}") format("woff2");'
            f"unicode-range:{CJK_RANGE};font-style:normal;font-weight:400;"
            f"font-display:swap;}}")
    if heading_ok:
        faces.append(
            f'@font-face{{font-family:"{SERIF_HEADING_FAMILY}";'
            f'src:url("{heading_font_name}") format("woff2");'
            f"unicode-range:U+0000-10FFFF;font-style:normal;font-weight:600;"
            f"font-display:swap;}}")
    return "\n".join(faces)

template = """
<!DOCTYPE html>
<html>
<head>
<title>{}</title>
<meta charset="utf-8">
<link rel="stylesheet" href="/style4.css">{}
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

def markdown_convert(title, body, nav="", pubdate=""):
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
    # The nav sits ahead of the title so it lands in the top corner of the page.
    parts = [x for x in (nav, html_title, pubdate) if x]
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
    body = replace_markdown_links_in_file(body, thumb=not is_article(input_file))
    html_out = markdown_convert(title, body,
                                nav_for(input_file), pubdate_for(input_file))
    html_out = restore_math(html_out, render_math(math_items))
    serif_extra = serif_face_extra(input_file, html_out)
    head_extra = "\n" + KATEX_CSS_LINK if math_items else ""
    if serif_extra:
        head_extra += f"\n<style>\n{serif_extra}\n</style>"
    print(template.format(title, head_extra, html_out))

