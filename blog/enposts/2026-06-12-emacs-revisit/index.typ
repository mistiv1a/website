// Revisiting Emacs
#import "/template.typ": *

#doc-template(
title: "Revisiting Emacs",
date: "June 12, 2026\nTranslated from the original Chinese version by LLM",
body: [

As VSCode adding more and more AI slop and even forces modifications on users' commit messages to include Copilot, it has fully turned into Microsoft's commercial platform. Furthermore, various extensions frequently shove unwanted features to me. For instance, the Python extension automatically switch my pyenv. While these features seem convenient for some users, in practice they often lead to issues that are difficult to locate and debug. VSCode's remote extensions are also resource-heavy, and the software is actually closed-source; not to mention it frequently glitches and constantly do unintended auto updates.

Although enshittification has become the norm for modern software, after thinking it over for a long time, I decided to step out of my comfort zone and return to Emacs. Emacs is not ready to daily drive out-of-the-box, so to achieve an experience close to VSCode, I added some new functionalities on top of my previous configuration.

= Remote Clipboard

If you are using Emacs on a Linux graphical interface, the clipboard is not a problem at all, as Emacs uses the system clipboard by default. However, if it's a remote Emacs, things get a bit tricky. Emacs does not have a full server-client architecture; its daemon mode requires both the client and the server to be on the same machine, serving merely as an optimization to speed up startup. Therefore, if you want a remote Emacs, the only viable option is to use the terminal version of Emacs through SSH.

Fortunately, the Xterm standard provided a solution for this a long time ago: the #link("https://www.xfree86.org/current/ctlseqs.html", "OSC 52 control sequence"). #link("https://ghostty.org/docs/vt/osc/52", "Ghostty's documentation") provides a more detailed description. There are many terminals support this:

- Ghostty: macOS, Linux
- iTerm2: macOS
- mintty: Windows
- Alacritty: Windows, Linux, macOS

This bash script can be used to test whether the OSC 52 sequence is working properly:

```bash
if [ -t 0 ]; then
    echo "$1: No stdin provided." >&2
    exit 1
fi

payload=$(base64 | tr -d '\r\n')
printf "\033]52;c;%s\a" "$payload"

```

This script reads text from `stdin` and then outputs it in the format of OSC 52 control sequence. If the terminal supports it, the text will be in the local operating system's clipboard. It can be thought of as a remote version of `xclip` or `wl-copy`.

For mintty, you need to modify `.minttyrc` and add:

```
AllowSetSelection=yes

```

Then install this Emacs extension: #link("https://github.com/spudlyo/clipetty", "clipetty"). For certain terminals where clipetty cannot automatically detect it, you might need to manually add this Lisp snippet to your Emacs configuration:

```el
(global-clipetty-mode)
(setq clipetty-assume-ansi-terminal t)

```

= Mouse Operations

Enable `xterm-mouse-mode`:

```
(xterm-mouse-mode 1)

```

= LSP

The mainstream solution is to use #link("https://github.com/emacs-lsp/lsp-mode", "lsp-mode"). However, `eglot`, the built-in LSP solution in newer versions of Emacs, is already good enough for most situations. To use it, you only need to enable it on-demand in the mode hook of the corresponding language:

```el
(require 'eglot)
(add-hook 'c-mode-hook #'eglot-ensure)
(add-hook 'c++-mode-hook #'eglot-ensure)
(add-hook 'haskell-mode-hook #'eglot-ensure)
(add-hook 'rust-mode-hook #'eglot-ensure)

```

Commonly used shortcuts are:

* `C-M-i`: Auto-complete
* `M-.`: Jump to definition
* `M-,`: Pop back from definition jump
* `M-x flymake-show-buffer-diagnostics`: View errors in the current file
* `M-x flymake-show-project-diagnostics`: View errors across the entire project

= Custom Shortcuts

Emacs has a vast number of shortcuts, and keybinding conflicts can sometimes be incredibly frustrating. I chose to uniformly use `M-o` as the prefix for custom shortcuts. Emacs itself does not use this keybinding, and it is rarely used by various extensions.

= Git

In the era of AI-driven Agentic development, reviewing git diffs has become the most critical feature of an editor. Without a doubt, the best tool in the Emacs ecosystem is `magit`. However, `magit` has complex features and a steep learning curve. The built-in `vc` module in Emacs is actually enough for most cases, and you can try it if you don't want to learn `magit`.

The most used commands include:

* `vc-diff`: View the diff of the current file
* `vc-root-diff`: View the current diff of the entire directory
* `vc-print-root-log`: View the commit history of the current directory

Commonly used shortcuts:

In the Diff interface, using `C-c C-c` allows you to jump to the location of the modification; if you are viewing the diff of a historical file, using `C-u C-c C-c` allows you to jump to the corresponding position in that historical version of the file.

In the commit history interface, pressing `=` allows you to view the detailed diff.

= Batch Replacement

The #link("https://github.com/dajva/rg.el", "rg plugin") for Emacs makes searching very easy. However, the extension itself does not provide a batch replacement feature. If you need to perform a batch replace, simply press `E` within the search results buffer to enter the `wgrep` state, and then use `M-%` to complete the batch replacement.

For more ways to use `wgrep`, you can refer to the #link("https://github.com/mhayashi1120/Emacs-wgrep", "documentation").

]
)
