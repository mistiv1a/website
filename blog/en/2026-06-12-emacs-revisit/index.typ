// Emacs Revisited
#import "/template.typ": *

#doc-template(
title: "Emacs Revisited",
date: "June 12th, 2026",
body: [

Now there is more and more AI slop brought to VSCode by Microsoft, and
they are adding Copilot coauthor to your commit message no matter
whether you have used Copilot at all. Additionally, various plugins are
forcing unwanted features on users, for example, the official Python
plugin bundle often switches pyenv on its own. These functions are
helpful to users at first sight, but lead to problems hard to debug in
the long run. The VSCode remote plugin also consumes a lot of
resources, and it's actually closed source software; not to mention
frequent bugs and the unintended updates which are jamming my workflow.

To be honest, all these things are very common for modern
software. But after much thinking, I decided to jump out of my comfort
zone and go back to Emacs. Emacs is not very handy out of the box; to
have experience close to VSCode, I've added some new features based on
my previous configuration.

= Remote Clipboard

If you are using Emacs on Linux GUI, clipboard is not a problem at
all. But it gets you into trouble if it's a remote Emacs. Emacs
doesn't have a full server-client architecture: the daemon mode
requires that server and clients be on the same host, as a method to
accelerate cold start. Hence, if you want a remote Emacs, the only
reasonable solution is a terminal Emacs through SSH.

Luckily, Xterm standard provided this feature long time ago:
#link("https://www.xfree86.org/current/ctlseqs.html", "OSC 52 Control Sequence").
There is a more detailed introduction in
#link("https://ghostty.org/docs/vt/osc/52", "the document of
Ghostty").  There are many terminal emulators that support this:

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

This script will read text from stdin, and output it in the format of
OSC 52 control sequence. If the terminal emulator supports this, this
text will enter the clipboard of your local OS, which can be
considered a remote version of xclip or wl-copy.

For mintty, `.minttyrc` should be added with:

```
AllowSetSelection=yes
```

Then install this Emacs extension:
#link("https://github.com/spudlyo/clipetty", "clipetty"). Some
terminals are not auto-detected by clipetty, maybe this Lisp snippet
is needed to be added to Emacs configuration:

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

The mainstream solution is to use
#link("https://github.com/emacs-lsp/lsp-mode", "lsp-mode"). But newer
versions of Emacs come with an LSP solution: Eglot, which is sufficient
in most cases. Just enable it in the mode hook of relevant programming
language:

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
- `M-x flymake-show-buffer-diagnostics`: View errors of current file
- `M-x flymake-show-project-diagnostics`: View errors of the whole project

= Customized Keyboard Shortcuts

There are a lot of keybindings in Emacs, and resolving key conflicts is
a pain. So I choose to use `M-o` as a universal prefix, which is not
used by Emacs itself and rarely used by all kinds of plugins.

= Git

Now we are in the AI-era, agentic development are everywhere, which
means reading `git diff` has been the most important function of an
editor. In Emacs ecosystem, the best tool is magit. However, magit is
very complex and difficult to learn. Emacs' built-in `vc` module is
enough in most cases. If you don't want to learn magit for now, it
will be an acceptable alternative.

Here are the primary commands:

- `vc-diff`: View diff of current file
- `vc-root-diff`: View diff of the whole directory
- `vc-print-root-log`: View commit log of current directory

And the most used keyboard shortcuts are these:

In the diff interface, use `C-c C-c` to jump to modified position; If you
are viewing the diff of a historical file, use `C-u C-c C-c` to jump
to relevant position in the historical version.

In the interface of viewing commit log, you can press `=` to view diff
details.

= Batch Replacement

#link("https://github.com/dajva/rg.el", "The rg plugin") of Emacs
 provides an easy way to search the project. But this plugin doesn't
 provide a way for batch replacement directly. If you need to do batch
 replacement, you need to press `e` to enter `wgrep` mode, and then
 use `M-%` to do batch replacement.

For more usage of `wgrep`, you can refer to
#link("https://github.com/mhayashi1120/Emacs-wgrep", "its document").

]
)