#import "/template.typ": *

#doc-template(
title: "Emacs再访",
date: "2026年6月12日",
body: [

现在VSCode中AI泔水越来越多，甚至开始强制修改用户的提交信息，加上copilot元素。另外，各式插件也常塞给我不想要的功能，如Python插件就常自作主张为我切换pyenv。诸如此类，不胜枚举。这些功能看似方便用户，实际上却经常招致难以调试定位的问题。VSCode的远程插件不仅资源消耗多，还是闭源软件，更新的时候也经常出bug，总之就是很烦。

于现代软件而言，这些都是常态，但是想了半天我还是决定跳出舒适圈，回到Emacs。Emacs并非开箱即用，为了使用体验能接近VSCode，我在#link("../2024-08-03-emacs/", "之前的基础")上加了些新功能。

= 远程剪贴板

如果在Linux图形界面上用Emacs，剪贴板完全无妨，Emacs会自动使用系统的剪贴板。但是如果是远程的Emacs就有点麻烦了：Emacs并没有完整的服务端-客户端架构，其daemon模式要求客户端和服务端都在相同机器上，只求加快启动速度，并未考虑远程编辑。因此如果想要远程的Emacs，就只好在SSH中使用其终端版本。

所幸Xterm标准很早就有了远程剪贴板功能：#link("https://www.xfree86.org/current/ctlseqs.html", "OSC 52控制序列")。#link("https://ghostty.org/docs/vt/osc/52", "Ghostty的文档")中介绍更为详尽。很多终端都支持此功能：

- Ghostty: macOS, Linux
- iTerm2: macOS
- mintty: Windows
- Alacritty: Windows, Linux, macOS

这个bash脚本可以用来测试OSC 52功能是否正常工作：

```bash
if [ -t 0 ]; then
    echo "$1: No stdin provided." >&2
    exit 1
fi

payload=$(base64 | tr -d '\r\n')
printf "\033]52;c;%s\a" "$payload"
```

这个脚本会从stdin中读入文本，然后以OSC 52控制序列的格式输出。如果终端支持，那么这段文本就会进入本地操作系统的剪贴板中，故可以看作远程版本的xclip或wl-copy。

若在Windows中使用mintty，则须修改`.minttyrc`，加入：

```
AllowSetSelection=yes
```

然后安装这个Emacs扩展：#link("https://github.com/spudlyo/clipetty", "clipetty")。某些终端clipetty无法自动识别，可能要在Emacs配置文件中手动加入：

```el
(global-clipetty-mode)
(setq clipetty-assume-ansi-terminal t)
```

= 鼠标操作

启用`xterm-mouse-mode`：

```
(xterm-mouse-mode 1)
```

= LSP

Emacs的诸多LSP插件中，最常见者当属#link("https://github.com/emacs-lsp/lsp-mode", "lsp-mode")。但是Emacs新版本自带的LSP方案eglot多数情况下已经够用。Eglot用起来很简单，只要按需在对应语言的hook中启用：

```el
(require 'eglot)
(add-hook 'c-mode-hook #'eglot-ensure)
(add-hook 'c++-mode-hook #'eglot-ensure)
(add-hook 'haskell-mode-hook #'eglot-ensure)
(add-hook 'rust-mode-hook #'eglot-ensure)
```

常用的快捷键有：

- `C-M-i`: 自动补全
- `M-.`: 跳转到定义
- `M-,`: 从跳转返回
- `M-x flymake-show-buffer-diagnostics`: 查看当前文件的错误
- `M-x flymake-show-project-diagnostics`: 查看整个项目的错误

= 自定义快捷键

Emacs快捷键繁多，键位冲突有时候会很难受。我选择了统一用`M-o`作为自定义快捷键的前缀。这个键位Emacs自己不用，各类插件也很少用到。

= Git

如今是人工智能时代，代理式（Agentic）开发大行其道，阅读git diff已是编辑器中最重要的功能。Emacs生态里面最好用的当属magit。不过magit功能复杂，上手门槛较高。而Emacs自带的vc模块大抵勉强够用，如果暂时不想学magit的话，只用它也未尝不可。

`vc`主要有这些命令：

- `vc-diff`: 查看当前文件的diff
- `vc-root-diff`: 查看整个目录的diff
- `vc-print-root-log`: 查看当前目录下的提交记录

常用快捷键有这些：

- Diff界面下，使用`C-c C-c`可以跳转到修改的位置；
- 如果查看历史文件的diff，使用`C-u C-c C-c`可以跳转到文件的历史版本中的对应位置。

查看提交记录时，按`=`键可查看其diff细节。

= 批量替换

Emacs的#link("https://github.com/dajva/rg.el", "rg插件")可在项目中检索文本，大致相当于VSCode的`Ctrl+Shift+F`。但是这个rg插件本身却没有提供批量替换功能，而是藉由wgrep实现。如果需要批量替换的话，只需要在搜索结果的缓冲区中按下`e`键，就可以进入wgrep状态，然后用`M-%`批量替换。

更多wgrep的使用方法可参考其#link("https://github.com/mhayashi1120/Emacs-wgrep", "文档")。

]
)