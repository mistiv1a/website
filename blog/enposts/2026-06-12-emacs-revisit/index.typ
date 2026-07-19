#import "/template.typ": *

#doc-template(
title: "Emacs Revisited",
date: "June 12, 2026",
parindent: 1.2em,
body: [

VSCode now contains an increasing amount of AI slop, and it has even begun to alter a user's commit messages automatically, inserting Copilot elements. In addition, various extensions frequently impose functions I do not want; the Python extension, for instance, often switches my pyenv version without permission. Examples of this sort abound. These functions appear convenient at first glance, but they often produce problems that are difficult to diagnose. The remote extension in VSCode consumes considerable resources, remains closed source, and frequently contains bugs after an update. In short, it has become quite irritating.

For modern software, such behavior has become the norm, but after considerable reflection, I decided to leave my comfort zone and return to Emacs. Emacs does not function well immediately after installation, so to bring the experience closer to that of VSCode, I added several new functions to what I had #link("/enposts/2024-08-03-emacs/", "configured previously").

= Remote Clipboard

When Emacs runs within a Linux graphical environment, the clipboard presents no difficulty at all, since Emacs uses the system clipboard automatically. Remote Emacs, however, is somewhat more troublesome: Emacs lacks a complete client-server architecture. Its daemon mode requires that both the client and the server reside on the same machine; the purpose is merely to accelerate startup, not to support remote editing. Consequently, anyone who wants remote Emacs must use its terminal version through SSH.

Fortunately, the Xterm standard has included a remote clipboard function for a long time already: the #link("https://www.xfree86.org/current/ctlseqs.html", "OSC 52 control sequence"). The #link("https://ghostty.org/docs/vt/osc/52", "Ghostty documentation") describes it in greater detail. Many terminals support this function:

- Ghostty: macOS, Linux
- iTerm2: macOS
- mintty: Windows
- Alacritty: Windows, Linux, macOS

The following bash script can test whether the OSC 52 function works correctly:

```bash
if [ -t 0 ]; then
    echo "$1: No stdin provided." >&2
    exit 1
fi

payload=$(base64 | tr -d '\r\n')
printf "\033]52;c;%s\a" "$payload"
```

This script reads text from stdin and then outputs it in the format of an OSC 52 control sequence. If the terminal supports this function, the text enters the clipboard of the local operating system; the script can therefore be regarded as a remote counterpart to xclip or wl-copy.

If you use mintty on Windows, you must modify `.minttyrc` and add:

```
AllowSetSelection=yes
```

Then install this Emacs extension: #link("https://github.com/spudlyo/clipetty", "clipetty"). Clipetty cannot recognize certain terminals automatically, so you may need to add the following lines to your Emacs configuration file manually:

```el
(global-clipetty-mode)
(setq clipetty-assume-ansi-terminal t)
```

= Mouse Support

Enable `xterm-mouse-mode`:

```
(xterm-mouse-mode 1)
```

= LSP

Among the many LSP extensions available for Emacs, #link("https://github.com/emacs-lsp/lsp-mode", "lsp-mode") is probably the most common. However, eglot, the LSP solution included with recent versions of Emacs, suffices for most situations. Eglot is simple to use: you need only enable it within the hook of the relevant language, as required:

```el
(require 'eglot)
(add-hook 'c-mode-hook #'eglot-ensure)
(add-hook 'c++-mode-hook #'eglot-ensure)
(add-hook 'haskell-mode-hook #'eglot-ensure)
(add-hook 'rust-mode-hook #'eglot-ensure)
```

The commonly used shortcuts include:

- `C-M-i`: automatic completion
- `M-.`: jump to a definition
- `M-,`: return from a jump
- `M-x flymake-show-buffer-diagnostics`: view the errors in the current file
- `M-x flymake-show-project-diagnostics`: view the errors in the entire project

= Custom Key Bindings

Emacs offers a great number of shortcuts, and conflicts between key bindings can sometimes cause real discomfort. I chose to use `M-o` uniformly as the prefix for my custom shortcuts. Emacs itself does not use this key, and few extensions use it either.

= Git

We now live in an age of artificial intelligence, in which agentic development prevails widely, and the ability to read a git diff has become one of the most important functions of an editor. Within the Emacs ecosystem, magit is probably the most capable tool for this purpose. However, magit possesses considerable complexity, and the barrier to entry is rather high. The vc module included with Emacs is adequate, more or less, so if you do not wish to learn magit for the moment, using vc alone remains a reasonable option.

The `vc` module offers mainly these commands:

- `vc-diff`: view the diff of the current file
- `vc-root-diff`: view the diff of the entire directory
- `vc-print-root-log`: view the commit history of the current directory

The commonly used shortcuts include:

- Within the diff view, `C-c C-c` jumps to the location of a modification.
- When you view the diff of a historical version of a file, `C-u C-c C-c` jumps to the corresponding location in that historical version.

When you view the commit history, press `=` to see the details of a diff.

= Bulk Replacement

The #link("https://github.com/dajva/rg.el", "rg extension") for Emacs can search text within a project, roughly equivalent to `Ctrl+Shift+F` in VSCode. This rg extension, however, does not itself provide a bulk replacement function; that function comes from wgrep instead. To perform a bulk replacement, you need only press `e` within the buffer containing the search results to enter wgrep state, and then use `M-%` to replace text throughout.

For further information about using wgrep, consult its #link("https://github.com/mhayashi1120/Emacs-wgrep", "documentation").

]
)
