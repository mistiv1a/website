用Vim制作文本处理工具
========

首先创建vim脚本，例如，用vim给文本在70列的时候自动断行的脚本如下:

```v
:set tw=70
gggqG
:wq
```

保存为`~/.vim/scripts/wrap`，然后可以处理文件：

```bash
vim -s ~/.vim/scripts/wrap input.txt
```

如果要以stdin为输入，stdout为输出，以便放进管道，给其他程序调用，可以用bash脚本包装一下：

```bash
#!/bin/bash

BUF=/tmp/$(head -c 15 /dev/urandom | base32)
cat > $BUF
/usr/bin/vim -s ~/.vim/scripts/wrap $BUF 1>/dev/null 2>/dev/null
cat $BUF
rm $BUF
```

这样一个小工具就完成了。
