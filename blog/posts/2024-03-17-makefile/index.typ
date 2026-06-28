// 一些编写Makefile的常用套路
#import "/template.typ":*
#doc-template(
title: "一些编写Makefile的常用套路",
date: "2024年3月17日",
body: [

列出`src`目录中的所有的`*.c`文件：

```make
SRC = $(shell find src/ -name '*.c')
```

列出`src`目录中的所有`*.c`文件，但是不包括`main.c`:

```make
SRC = $(shell find src/ -name '*.c' -not -name 'main.c')
```

列出所有`*.c`文件对应的`*.o`文件：

```make
OBJ = $(SRC:.c=.o)
```

把所有`*.c`文件编译成`*.o`文件并生成头文件的依赖关系（`*.d`文件）：

```make
$(OBJ):%.o:%.c
    $(CC) -c $(CFLAGS) $< -MD -MF $@.d -o $@
```

把依赖关系加入到`Makefile`中，以便于头文件有修改时自动重新编译：

```make
DEPS := $(shell find . -name *.d)

ifneq ($(DEPS),)
include $(DEPS)
endif
```

])
