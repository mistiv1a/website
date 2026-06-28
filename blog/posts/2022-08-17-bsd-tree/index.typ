// 生活在BSD的树上
#import "/template.typ":doc-template

#doc-template(
title: "生活在BSD的树上",
date: "2022年8月17日",
body: [

FreeBSD、OpenBSD系统都自带了#link("https://github.com/openbsd/src/blob/master/sys/sys/tree.h")[一个很好用的红黑树和splay树实现]。

这个实现只有头文件，无需外部依赖，而且是泛型的。所以想在Linux下面用起来也很简单。

= 获取头文件

运行：

```sh
curl https://raw.githubusercontent.com/openbsd/src/master/sys/sys/tree.h -o tree.h
```

这个头文件里面包含了`sys/_null.h`，这个文件在Linux里面是没有的。不过，`tree.h`用这个文件只是为了定义`NULL`，所以改成`stdlib.h`就行了。

```c
// #include <sys/_null.h>
#include <stdlib.h>
```

= 声明

头文件tree.h中的树实际上全是宏，所以用之前需要先展开。举个例子，如果希望树中的值类型是`double`，那么新建一个头文件`double_tree.h`，在文件中这样声明：

```c
#ifndef DOUBLE_TREE_H_
#define DOUBLE_TREE_H_

#include "tree.h"

struct double_treenode {
    RB_ENTRY(double_treenode) entry;
    double val;
};

int double_cmp(struct double_treenode *e1, struct double_treenode *e2);

RB_HEAD(double_tree, double_treenode);
RB_PROTOTYPE(double_tree, double_treenode, entry, double_cmp)

#endif
```

= 定义

然后创建源文件`double_tree.h`，补充需要的函数定义：

```c
#include "double_tree.h"

int double_cmp(struct double_treenode *e1, struct double_treenode *e2); {
    if (e1->val < e2->val) {
        return -1;
    } else if (e1->val > e2->val) {
        return 1;
    }
    return 0;
}

RB_GENERATE(double_tree, double_treenode, entry, double_cmp)
```

= 使用

接下来介绍如何使用这个`double_tree`。

== 初始化

创建树并初始化：

```c
RB_HEAD(double_tree, double_treenode) head;
RB_INIT(&head);
```

初始化也可以一行完成：

```c
RB_HEAD(double_tree, double_treenode) head = RB_INITIALIZER(&head);
```

== 插入

```c
struct double_treenode *n;
double data[5] = {1.0, 2.0, 3.0, 4.0, 5.0};
for (int i = 0; i < 5; i++) {
    n = malloc(sizeof(struct double_treenode));
    n->val = data[i];
    RB_INSERT(double_tree, &head, n);
}
```

== 查找和删除

```c
struct double_treenode find;
find.val = 3.0

struct double_treenode *iter;
iter = RB_FIND(double_tree, &head, &find);

if (iter != NULL) {
    printf("Found\n");
    RB_REMOVE(double_tree, &head, iter);
    free(iter);
}
```

== 遍历

```c
RB_FOREACH(iter, double_tree, &head) {
    // Do something on iter->val
    ...
}
```

其实，`RB_FOREACH(iter, double_tree, &head)`本质上是：

```c
for (iter = RB_MIN(double_tree, &head);
        iter != NULL;
        iter = RB_NEXT(double_tree, &head, iter))
```

用`RB_MIN`可以取得树中的最小节点；用`RB_NEXT`可以获取`iter`的下一个元素；`RB_MAX`则是最大节点。

如果想用其他的顺序遍历树的话，可以用`RB_LEFT`和`RB_RIGHT`。比如说，用前序遍历打印树：

```c
void
print_tree(struct double_treenode *n)
{
    struct double_treenode *left, *right;

    if (n == NULL) {
        printf("nil");
        return;
    }
    left = RB_LEFT(n, entry);
    right = RB_RIGHT(n, entry);
    if (left == NULL && right == NULL)
        printf("%d", n->val);
    else {
        printf("%d(", n->val);
        print_tree(left);
        printf(",");
        print_tree(right);
        printf(")");
    }
}
```

= 其他

有个很怪的事情，Arch Linux里面有`tree.h`的man文档，执行`man 3 tree`就能看到，但是这个头文件本体却找不到。

这篇文章里面只写了红黑树，但是splay树其实也大同小异，就不再赘述了，可以直接去翻#link("https://www.freebsd.org/cgi/man.cgi?query=tree&amp;sektion=3&amp;format=html", "文档")。

= 勘误

感谢#link("https://c7.io/@w3cing", "@w3cing")的#link("https://mstdn.party/@w3cing@c7.io/111659300344465706", "提醒")。FreeBSD所提供的`tree.h`中的`RB_TREE`实际上并非红黑树，RB指的是rank-balanced tree，而具体的实现是weak AVL。FreeBSD在2020年8月对tree.h进行过一次#link("https://github.com/freebsd/freebsd-src/commit/e605dcc939848312a201b4aa53bd7bb67d862b18", "修改")。

]
)
