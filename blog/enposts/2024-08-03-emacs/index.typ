#import "/template.typ": *

#doc-template(
title: "Emacs Notes",
date: "August 3, 2024",
parindent: 1.2em,
body: [

I recently switched my primary editor from VSCode to Emacs; this post records the configuration process.

= Basic Configuration

To prevent Emacs from placing temporary files within the current directory, direct all of them to `/tmp`:

```lisp
(setq backup-directory-alist
        `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
        `((".*" ,temporary-file-directory t)))
```

Set the font:

```lisp
(set-frame-font "monospace 13" nil t)
(set-fontset-font t 'han "Source Han Sans CN")
```

Enable line numbers:

```lisp
(global-display-line-numbers-mode 1)
```

The title bar and the tool bar serve little purpose in most situations and merely occupy screen space, so I hide them here; you can summon them again with `F10` whenever necessary.

```lisp
(menu-bar-mode -1)
(toggle-scroll-bar -1)
(tool-bar-mode -1)
```

= Package Management

Add Melpa to Emacs:

```lisp
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
```

Enable the package manager:

```lisp
(require 'package)
(package-initialize)
```

Then restart Emacs and refresh the package directory: `M-x package-refresh-contents`.

Use `M-x package-install` to install each of the following packages in turn:

- magit
- lsp-mode
- rust-mode
- dired-sidebar
- treesit-auto
- use-package
- yasnippet
- rg
- counsel
- ivy
- lsp-ivy
- projectile
- company

To update all installed packages: `M-x list-package RET S-u x`

= Treesit

Enable the built-in treesit and use `treesit-auto` for automatic configuration:

```lisp
(require 'treesit)

(use-package treesit-auto
    :config
    (global-treesit-auto-mode))
```

Then install the grammar libraries: `M-x treesit-auto-install-all`

= Typst

The typst mode package does not appear in Melpa, so you must install it from git: `M-x package-vc-install`. The address is:

```
https://git.sr.ht/~meow_king/typst-ts-mode
```

Then compile and install the treesit library for typst: first enter

```
    M-: (treesit-install-language-grammar 'typst) RET
```

then enter

```
https://github.com/uben0/tree-sitter-typst`
```

Configuration:

```lisp
(use-package typst-ts-mode
    :custom
    (typst-ts-mode-grammar-location
    (expand-file-name "tree-sitter/libtree-sitter-typst.so"
                        user-emacs-directory)))
```

= Ivy

Ivy is a completion tool for the minibuffer. Some people use helm instead, but I find ivy somewhat lighter and simpler.

```lisp
(require 'ivy)
(require 'counsel)
(ivy-mode)
(setq ivy-use-virtual-buffers t)
(setq enable-recursive-minibuffers t)
(global-set-key "\C-s" 'swiper)
(global-set-key (kbd "C-c C-r") 'ivy-resume)
(global-set-key (kbd "<f6>") 'ivy-resume)
(global-set-key (kbd "M-x") 'counsel-M-x)
(global-set-key (kbd "C-x C-f") 'counsel-find-file)
(global-set-key (kbd "<f1> f") 'counsel-describe-function)
(global-set-key (kbd "<f1> v") 'counsel-describe-variable)
(global-set-key (kbd "<f1> o") 'counsel-describe-symbol)
(global-set-key (kbd "<f1> l") 'counsel-find-library)
(global-set-key (kbd "<f2> i") 'counsel-info-lookup-symbol)
(global-set-key (kbd "<f2> u") 'counsel-unicode-char)
(global-set-key (kbd "C-c g") 'counsel-git)
(global-set-key (kbd "C-c j") 'counsel-git-grep)
(global-set-key (kbd "C-c k") 'counsel-ag)
(global-set-key (kbd "C-x l") 'counsel-locate)
(global-set-key (kbd "C-S-o") 'counsel-rhythmbox)
(define-key minibuffer-local-map (kbd "C-r") 'counsel-minibuffer-history)
```

= LSP

Here I install LSP support for Rust only, for the moment:

```lisp
(use-package company)
(use-package rust-mode)
(use-package lsp-mode
    :init
    ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
    (setq lsp-keymap-prefix "C-c l")
    :hook (
            (rust-mode . lsp)
            ;; if you want which-key integration
            (lsp-mode . lsp-enable-which-key-integration))
    :commands lsp)
(use-package lsp-ivy :commands lsp-ivy-workspace-symbol)
```

= File Browser Sidebar

Use `dired-sidebar`:

```lisp
(use-package dired-sidebar
    :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
    :ensure t
    :commands (dired-sidebar-toggle-sidebar)
    :init
    (add-hook 'dired-sidebar-mode-hook
            (lambda ()
                (unless (file-remote-p default-directory)
                (auto-revert-mode))))
    :config
    (push 'toggle-window-split dired-sidebar-toggle-hidden-commands)
    (push 'rotate-windows dired-sidebar-toggle-hidden-commands)

    (setq dired-sidebar-subtree-line-prefix "__")
    (setq dired-sidebar-theme 'vscode)
    (setq dired-sidebar-use-term-integration t)
    (setq dired-sidebar-use-custom-font t))
```

Then you can summon the sidebar with `C-x C-n`.

= Projectile

Use `C-c p` to jump quickly to a file within a project, similar to CtrlP in Vim:

```lisp
(projectile-mode +1)
;; Recommended keymap prefix on Windows/Linux
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
```

= Snippet

Use the `yasnippet` extension:

```lisp
(use-package yasnippet
    :bind
    (("C-c n i" . yas-insert-snippet))
    :config
    (add-to-list 'yas-snippet-dirs "~/.emacs.d/snippets")
    (yas-global-mode 1))
```

Snippets are stored in the `~/.emacs.d/snippets/{mode-name}/` directory.

= Ripgrep

Use the rg extension to search text quickly within a project directory:

```lisp
(require 'rg)
(rg-enable-default-bindings)
```

The most commonly used shortcut is `C-c p f`, which searches within a Projectile project.

= Magit

The magit extension offers a considerable range of functions; I will not describe them in detail here. You can consult the tutorial on the magit website instead.

Enable it:

```lisp
(require 'magit)
```

= Markdown

Simply load Markdown mode:

```lisp
(use-package markdown-mode)
```

]
)
