#import "/template.typ":*
#doc-template(
title: "Emacs手札",
date: "2024年8月3日",
body: [


最近把主力编辑器从VSCode切换到了Emacs，这里给配置过程做一下记录。

= 基本设置

让Emacs把临时文件都放到`/tmp`中，以免污染当前目录：

```lisp
(setq backup-directory-alist
        `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
        `((".*" ,temporary-file-directory t)))
```

设置字体：

```lisp
(set-frame-font "monospace 13" nil t)
(set-fontset-font t 'han "Source Han Sans CN")
```

开启行号显示：

```lisp
(global-display-line-numbers-mode 1)
```

标题栏和工具栏大多数情况下没有用，反而会占屏幕空间，因此这里把它们隐藏，如果需要用到的话可以用`F10`呼出。

```lisp
(menu-bar-mode -1) 
(toggle-scroll-bar -1) 
(tool-bar-mode -1)
```

= 包管理

把Melpa加入Emacs：

```lisp
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
```

启用包管理器：

```lisp
(require 'package)
(package-initialize)
```

随后重启Emacs，更新包目录：`M-x package-refresh-contents`。

使用`M-x package-install`依次安装下列功能包：

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

如果要更新所有安装的包：`M-x list-package RET S-u x`

= Treesit

启用内置的treesit然后利用`treesit-auto`自动配置：

```lisp
(require 'treesit)

(use-package treesit-auto
    :config
    (global-treesit-auto-mode))
```

然后安装语法库：`M-x treesit-auto-install-all`

= Typst

typst模式这个包不在Melpa中，需要从git安装：`M-x package-vc-install`。地址为：

```
https://git.sr.ht/~meow_king/typst-ts-mode
```

然后编译安装typst的treesit库：先输入

```
    M-: (treesit-install-language-grammar 'typst) RET
```

然后输入

```
https://github.com/uben0/tree-sitter-typst`
```

配置：

```lisp
(use-package typst-ts-mode
    :custom
    (typst-ts-mode-grammar-location
    (expand-file-name "tree-sitter/libtree-sitter-typst.so"
                        user-emacs-directory)))
```

= Ivy

Ivy是一个minibuffer的补全工具，也有人用helm，不过我觉得ivy更轻更简洁一点。

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

这里先只安装Rust的lsp功能：

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

= 文件浏览器侧栏

使用`dired-sidebar`：

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

然后使用`C-x C-n`可以呼出侧栏。

= Projectile

使用`C-c p`快速在项目中跳转到文件，类似于Vim的CtrlP：

```lisp
(projectile-mode +1)
;; Recommended keymap prefix on Windows/Linux
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
```

= Snippet

使用`yasnippet`插件：

```lisp
(use-package yasnippet
    :bind
    (("C-c n i" . yas-insert-snippet))  
    :config
    (add-to-list 'yas-snippet-dirs "~/.emacs.d/snippets")
    (yas-global-mode 1))
```

Snippet保存在`~/.emacs.d/snippets/{模式名}/`目录下。

= Ripgrep

使用rg插件可以快速在项目目录中搜索文本内容：

```lisp
(require 'rg)
(rg-enable-default-bindings)
```

最常用的快捷键是`C-c p f`，可以在Projectile项目中搜索。

= Magit

Magit插件功能比较繁杂，这里不再赘述了，可以去看magit网站上的教程。

启用：

```lisp
(require 'magit)
```

= Markdown

直接加载Markdown模式即可：

```lisp
(use-package markdown-mode)
```


])

