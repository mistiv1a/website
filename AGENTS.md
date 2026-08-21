# Blog Site

## 创建新文章的步骤

第1步：选定标题、英文缩写（例如，标题：关于XXX的使用；缩写：xxxx-usage）

第2步：运行`date`查看日期（日期格式：20yy-mm-dd）

第3步：创建目录`blog/posts/yyyy-mm-dd-缩写/`

第4步：创建文件`blog/posts/yyyy-mm-dd-缩写/index.typ`。

文件初始内容如下：

```
#import "/template.typ": *

#doc-template(
title: "标题",
date: "20xx年m月y日",
body: [

])
```

注意，目录名的格式是20xx-0x-0x，但是文件里面日期是"20xx年x月x日"，没有“0”。

第5步：修改`blog/index.md`，在合适的位置（按日期降序）插入：

```
- 20xx-mm-dd [标题](/posts/20xx-mm-dd-缩写/)
```

结束。

## English translation

If it's an English translation, the header is :


```
#import "/template.typ": *

#doc-template(
title: "Title",
date: "June 1, 2025",
parindent: 1.2em,
body: [

])
```

Write like a fluent non-native English language speaker writing at CEFR C1 would.

- Vocabulary: stay roughly within the 10,000 most frequent English words.
- Avoid: phrasal verbs (prefer single verbs — "tolerate," not "put up with"), idioms, slang, culture-specific references.
- Do not misspell, break word order, or drop articles at random. You should write like an educated and fluent writer.

## 三方依赖与安装方式

本项目构建依赖以下三方组件。除 `scripts/vendor/` 下的 Python 库可随仓库分发外，其余均为系统级命令/文件，需在构建机上预先安装。

### scripts/vendor/ 中的 Python 库（已随仓库分发）

这些库已安装到 `scripts/vendor/`，如缺失可用 pip 重装到该目录：

```bash
# fonttools 4.63.0（字体子集化，md.py 生成 serif webfont 时使用）
pip install --target=scripts/vendor fonttools==4.63.0

# brotli 1.2.0（fonttools 的 WOFF2 压缩依赖）
pip install --target=scripts/vendor brotli==1.2.0
```

- 代码通过 `sys.path.insert(0, os.path.join(HERE, "vendor"))` 导入（见 `scripts/md.py`）。
- fontTools 是可选的：缺失时 `HAS_FONTTOOLS=False`，构建仍会成功，页面回退到系统衬线字体。
- `scripts/vendor/` 已被 `.gitignore` 忽略，不会进入仓库。

### JavaScript 库

- **KaTeX 0.18.4**（`scripts/vendor/katex.min.js`）
  - 安装方式：`npm install katex@0.18.4`，然后把 `node_modules/katex/dist/katex.min.js` 复制到 `scripts/vendor/katex.min.js`
  - 作用：`scripts/md.py` 通过 `node -e` 调用它把数学公式渲染为 HTML
  - 页面加载的样式与字体已提交到仓库：`blog/katex.min.css` 和 `blog/fonts/KaTeX_*.woff2`（取自 `node_modules/katex/dist/`）

### 系统命令依赖

| 命令 | 版本 | 安装方式 | 作用 |
|---|---|---|---|
| `cmark-gfm` | 0.29.0.gfm.13 | 从 <https://github.com/github/cmark-gfm> 下载源码编译安装，或 `apt install cmark-gfm`（如有） | `scripts/md.py` 的 Markdown→HTML 转换：`cmark-gfm --unsafe --smart -e table -e strikethrough` |
| `typst` | 0.15.1 | 官方脚本 `curl -fsSL https://typst.community/install.sh \| sh`、`cargo install typst` 或下载预编译二进制 | `scripts/typ2html.py` 把 `.typ` 编译成 SVG 页面：`typst compile --root ...` |
| `node` | v22.23.1 | `apt install nodejs` 或 nvm | `scripts/md.py` 中执行 KaTeX 渲染 |
| `python3` | 3.14+ | 系统自带 | 运行所有 `scripts/*.py` 脚本 |

### C 程序（text2html）

- 项目根目录的 `text2html` 是 `text2html.c` 编译得到的可执行文件，用于把 `.pre` 文件转换为 HTML：
  ```bash
  gcc -o text2html text2html.c
  ```
- 当前项目中没有 `.pre` 文件，此工具仅在存在 `.pre` 源文件时被 `Makefile` 调用。

### 系统字体依赖

构建时 `scripts/md.py` 会用 fontTools 对以下字体做字符子集化，生成页面引用的 `serif-*.woff2`：

| 字体 | 路径 | 用途 | 环境变量覆盖 |
|---|---|---|---|
| 方正新书宋 FZXSSJW.TTF | `/usr/share/fonts/FZXSSJW.TTF` | 正文 CJK 衬线字体 | `SERIF_BODY_FONT_SRC` |
| 思源宋体 Source Han Serif CN SemiBold | `/usr/share/fonts/adobe-source-han-serif/SourceHanSerifCN-SemiBold.otf` | 标题衬线字体 | `SERIF_HEADING_FONT_SRC` |

`template.typ`中的代码块使用 **Sarasa Mono SC** 等宽字体（`/usr/share/fonts/sarasa/`），该字体也需在构建机上安装。

### PDF 阅读器（pdfjs）

- `scripts/pdf2html.py` 生成的 PDF 阅读页面引用 `/pdfjs/web/viewer.html`。
- PDF.js 不是仓库内容（`blog/pdfjs/` 已被 `.gitignore` 忽略），需要单独部署到网站根目录。
- 安装方式：从 <https://github.com/mozilla/pdf.js/releases> 下载发布版（如 `pdfjs-4.x-dist.zip`），解压到 `blog/pdfjs/`，使 `viewer.html` 位于 `blog/pdfjs/web/viewer.html`。
