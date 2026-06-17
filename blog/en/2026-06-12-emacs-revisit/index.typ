// Emacs Revisited
#import "/template.typ": *

#doc-template(
title: "Emacs Revisited",
date: "June 12nd, 2026",
body: [

Now there is more and more AI slop brought to VSCode by Microsoft, and
they are adding Copilot coauthor to your commit message no matter
wheather you have used Copilot at all. Also, various plugins are
forcing unwanted features to me, for example, the official Python
plugin bundle often switch pyenv on their own. These functions are
helpful to users at first sight, but lead to problems hard to debug in
the long run. The VSCode remote plugin also consumes a lot of
resources, and it's actually a closed source software; not to mention
frequent bugs and the unintended updates which are jamming my workflow.

To be honest, all these things are very common for mordern
software. But after much thinking, I decided to jump out of my comfort
zone and go back to Emacs. Emacs is not very handy out of the box; to
have experience close to VSCode, I've added some new features based on
my previous configuration.

= Remote Clipboard

If you are using Emacs on Linux GUI, clipboard is not a problem at
all. But it gets you some trouble if it's a remote Emacs. Emacs
doesn't have a full server-client architecture: the daemon mode
requires that server and clients are on the same host, as a method to
accelerate cold start. Hence, if you want a remote Emacs, the only
reasonable solution is a terminal Emacs through SSH.

Luckily, Xterm standard provided this feature long time ago:
#link("https://www.xfree86.org/current/ctlseqs.html", "OSC 52 Control Sequence").
There are more detailed introduction in
#link("https://ghostty.org/docs/vt/osc/52", "the document of Ghostty").
There are amny terminal emulators that support this:

- Ghostty: macOS, Linux
- iTerm2: macOS
- mintty: Windows
- Alacritty: Windows, Linux, macOS

This bash script can be used to test if OSC 52 is functioning properly.

```bash
if [ -t 0 ]; then
    echo "$1: No stdin provided." >&2
    exit 1
fi

payload=$(base64 | tr -d '\r\n')
printf "\033]52;c;%s\a" "$payload"
```

This script will read text from stdin, and output and the format of OSC 52 control sequence. If the terminal emulator support this, this text will enter the clipboard of your local OS, which can be considered to be a remote version of xclip or wl-copy.

For mintty, `.minttyrc` should be added with:

```
AllowSetSelection=yes
```

Then install this Emacs extension: #link("https://github.com/spudlyo/clipetty", "clipetty"). Some terminal are not auto detected by clipetty, maybe this lisp snippet are needed to be added to Emacs configuration: 

```el
(global-clipetty-mode)
(setq clipetty-assume-ansi-terminal t)
```

= Mouse Opeartion

Enable `xterm-mouse-mode`:

```
(xterm-mouse-mode 1)
```

= LSP



The mainstream solution is to use #link("https://github.com/emacs-lsp/lsp-mode", "lsp-mode"). But newer version of Emacs come with a LSP solution: eglot, which is sufficient in most cases. Just enable it in the mode hook of relevent programming language:

```el
(require 'eglot)
(add-hook 'c-mode-hook #'eglot-ensure)
(add-hook 'c++-mode-hook #'eglot-ensure)
(add-hook 'haskell-mode-hook #'eglot-ensure)
(add-hook 'rust-mode-hook #'eglot-ensure)
```

Most used shortcuts:

- `C-M-i`: Auto complete
- `M-.`: Jump to definition
- `M-,`: Jump back
- `M-x flymake-show-buffer-diagnostics`: See errors of current file
- `M-x flymake-show-project-diagnostics`: See error of the whole project

= Customized Keyboard Shortcuts

Emacs快捷键繁多，键位冲突有时候会非常难受。我选择了统一用`M-o`作为自定义快捷键的前缀。这个键位Emacs自己不用，各类插件也很少用到。

= Git

在人工智能时代的代理式（Agentic）开发中，阅读git diff已经是编辑器最重要的功能了。Emacs生态里面最好用的当属magit。不过magit功能复杂，上手门槛比较高。Emacs自带的vc模块大多数情况下勉强够用，如果暂时不想学magit的话可以凑合用一用。

主要有这些命令：

- `vc-diff`: 查看当前文件的diff
- `vc-root-diff`: 查看整个目录的当前diff
- `vc-print-root-log`: 查看当前目录下的提交记录

常用快捷键有这些：

Diff界面下，使用`C-c C-c`可以跳转到修改的位置；如果是查看历史文件的diff，使用`C-u C-c C-c`可以跳转到文件的历史版本中的对应位置。

在查看提交记录的界面中，按`=`可以查看其diff细节。

= 批量替换

Emacs的#link("https://github.com/dajva/rg.el", "rg插件")可以很容易检索。但是这个插件本身并没有提供批量替换功能。如果需要批量替换的话，只需要在搜索结果的缓冲区中按下`e`键，就可以进入wgrep状态，此时用`M-%`完成批量替换。

更多wgrep的使用方案可以参考#link("https://github.com/mhayashi1120/Emacs-wgrep", "文档")。

]
)