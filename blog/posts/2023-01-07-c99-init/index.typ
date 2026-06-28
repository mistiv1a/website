// C99的指定初始化 
#import "/template.typ": *

#doc-template(
title: "C99的指定初始化 ",
date: "2023年1月7日",
body: [


C99中提供了一种新的初始化方式：指定初始化（designated initialization）。这种初始化方式是少数几个C和C++不兼容的地方之一，学校里也很少会教。但是这个语法糖实在是很有用，可以少打很多字。

= 结构体

```c
struct S {
    int x;
    int y;
};

void foo() {
    struct S obj1 = {.x = 1, .y = 2};
    // obj1 = {1, 2}

    struct S obj2 = {.y = 2};
    // obj2 = {0, 2}
}
```


= 数组

```c
void bar() {
    int a[5] = {[2] = 2, [4] = 4};
    // a = {0, 0, 2, 0, 4}
}
```

= 混用

```c
struct S {
    int x;
    int y;
};

void uwu() {
    struct S sa[3] = {[1].y = 2};
    // sa = {{0, 0}, {0, 2}, {0, 0}}
}
```

= 用于在堆上初始化

```c
struct S {
    int x;
    int y;
};

void foo() {
    struct S *ptr = malloc(sizeof(struct S));
    *ptr = (struct S){.y = 2};
    // ptr->x == 0 && ptr->y == 2
}
```

= 参见

- #link("https://floooh.github.io/2019/09/27/modern-c-for-cpp-peeps.html", "Modern C for C++ Peeps")
- #link("https://en.cppreference.com/w/c/language/initialization", "Initialization - cppreference.com")

])