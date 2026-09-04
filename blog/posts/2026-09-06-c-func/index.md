C语言中的一等函数
===============

## 什么是一等函数

下面这段话来自[MDN](https://developer.mozilla.org/en-US/docs/Glossary/First-class_Function)：

> 当函数在一种编程语言中被当作与其他任何变量一样来对待时，我们就说这种语言拥有一等函数（First-class functions）。例如，在这种语言中，函数可以作为参数传递给其他函数，可以由另一个函数返回，也可以作为值赋给变量。

## 闭包：以JavaScript为例

一等函数，在应用中最经典的例子就是“闭包”。这是一个在函数式编程中非常常用的概念。而对于普通开发者，接触到这个概念最早可能是因为前端开发中JavaScript会用到：

```
function counter() {
  let count = 0; // 外部的局部变量

  return function () {
    count++;     // 函数“记住”了count
    return count;
  };
}

const c1 = counter();
console.log(c1()); // 1
console.log(c1()); // 2
console.log(c1()); // 3
```

利用闭包，我们可以构造出一个“函数工厂”，也就是部分应用，或者说“柯里化”：

```
function multiply(a) {
  return function (b) {
    return a * b;
  };
}

const double = multiply(2);
const triple = multiply(3);

console.log(double(10)); // 20
console.log(triple(10)); // 30
```

## 函数指针并非一等函数

C语言中，函数指针看起来也可以当作变量参数，但是这并不是一等函数。因为我们不能够像上面的例子那样，动态创建函数。所有的函数的行为，在编译期就已经固定下来了。

不过，如果我们把一个函数指针和一个数据指针组合起来，并约定这个数据指针作为该函数的参数传入，就能近似实现"动态创建函数"的效果。

因此，在C语言中，对于一些需要回调函数的接口，API往往会设计成函数指针加上一个用户自定义数据的指针，例如创建线程的`pthread_create`接口：

```
int pthread_create(pthread_t * thread,
                   const pthread_attr_t * restrict attr,
                   void (*start_routine)(void *),
                   void *arg);
```

## 如何构造出一等函数

这里我们使用x86-64架构。但是其他架构思路也类似。

首先我们要设计一段机器码，这段机器码需要把上下文数据指针塞进一个寄存器，然后跳转到目标函数。写成汇编的话就是这样：

```
mov r11, func
mov r10, data
jmp r11
```

之所以用r10、r11两个寄存器，是因为，根据C的ABI，这两个寄存器不用来传递参数，同时由调用方负责保存，被调用方可以自由使用。

这段汇编转成机器码后就是：

```
0x49 0xbb [func]
0x49 0xba [data]
0x41 0xff 0xe3
```

然后，我们在一个单独的内存页面上分配内存：

```
void *jitPage = NULL;
int jitPageOffset = 0;

#define PAGE_SIZE 4096

void* alloc_closure() {
	if (jitPage == NULL || jitPageOffset >= 4096) {
        jitPage = mmap(NULL, PAGE_SIZE, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0 );
        if (jitPage == MAP_FAILED) {
            jitPage = NULL;
            return NULL;
        }
        jitPageOffset = 0;
	}
    jitPageOffset += 32;
    return jitPage + jitPageOffset - 32;
}
```

之所以要在单独的页面上分配，是因为很多平台存在W^X的限制，也就是，一个内存页面不能同时既可写又可执行，所以要和普通的堆内存隔离开，不能直接malloc。

然后我们写一个函数，把前面的机器码写入分配的内存中，就可以创建闭包：

```
typedef void(*FuncPtr)(void);

FuncPtr make_closure(FuncPtr func, void *context) {
    void *buf = alloc_closure();
    
    if (buf == NULL) {
        return NULL;
    }
    if (mprotect(jitPage, PAGE_SIZE, PROT_READ | PROT_WRITE) != 0) {
        return NULL;
    }
    *(uint8_t*)buf = 0x49;
    *(uint8_t*)(buf + 1) = 0xbb;
    *(uint64_t*)(buf + 2) = (uint64_t)func;
    *(uint8_t*)(buf + 10) = 0x49;
    *(uint8_t*)(buf + 11) = 0xba;
    *(uint64_t*)(buf + 12) = (uint64_t)context;
    *(uint8_t*)(buf + 20) = 0x41;
    *(uint8_t*)(buf + 21) = 0xff;
    *(uint8_t*)(buf + 22) = 0xe3;
    if (mprotect(jitPage, PAGE_SIZE, PROT_READ | PROT_EXEC) != 0) {
        return NULL;
    }
    return (void (*)(void))buf;
}
```

随后，在函数中，只要读取r1寄存器就可以获得上下文数据指针。我们写一个工具函数来辅助：

```
__attribute__((naked))
void* get_context(void) {
    __asm__ volatile(
        "mov %r10, %rax\n\t"
        "ret\n\t"
    );
}
```

## 使用方法

下面写一个类似上面的Counter的例子说明怎么使用：

```
int counter() {
    int *i = get_context();
    (*i)++;
    return *i;
}

int main() {
    int *a = malloc(sizeof(int));
    int *b = malloc(sizeof(int));
    *a = 0;
    *b = 5;

    CounterFunc ca = (CounterFunc)make_closure((FuncPtr)counter, a);
    CounterFunc cb = (CounterFunc)make_closure((FuncPtr)counter, b);
    
    printf("a = %d, b = %d\n", *a, *b);
    ca();
    cb();
    cb();
    printf("a = %d, b = %d\n", *a, *b);

    return 0;
}
```

## 这种方法的缺陷

首先，不像函数式语言，它不能自动捕获变量。如果要使用某个变量，只能手动创建一个context对象，然后把这个变量的值或者指针拷贝到context对象中，还要考虑复杂的对象生命周期，最坏情况下可能不得不需要GC。

同时，捕获变量的的类型安全也丢失了，所有一切都变成了一个`void*`。

另外，这种方法其实也不能方便的构造类似lambda的东西，写起来还是很繁琐，大部分情况下还是使用由两个指针构成的结构体更方便。只有在处理一些只能接受函数指针作为回调的库的API的时候，又需要让回调函数能够有运行时动态行为，这种hack才会派上用场。

## 附录：完整代码

```
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>
#include <unistd.h>

typedef void(*FuncPtr)(void);
typedef int (*CounterFunc)();

FuncPtr make_closure(FuncPtr func, void *context);
void* get_context(void);

int counter() {
    int *i = get_context();
    (*i)++;
    return *i;
}

int main() {
    int *a = malloc(sizeof(int));
    int *b = malloc(sizeof(int));
    *a = 0;
    *b = 5;

    CounterFunc ca = (CounterFunc)make_closure((FuncPtr)counter, a);
    CounterFunc cb = (CounterFunc)make_closure((FuncPtr)counter, b);
    
    printf("a = %d, b = %d\n", *a, *b);
    ca();
    cb();
    cb();
    printf("a = %d, b = %d\n", *a, *b);

    return 0;
}

void *jitPage = NULL;
int jitPageOffset = 0;

__attribute__((naked))
void* get_context(void) {
    __asm__ volatile(
        "mov %r10, %rax\n\t"
        "ret\n\t"
    );
}

#define PAGE_SIZE 4096

void* alloc_closure() {
	if (jitPage == NULL || jitPageOffset >= 4096) {
        jitPage = mmap(NULL, PAGE_SIZE, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0 );
        if (jitPage == MAP_FAILED) {
            jitPage = NULL;
            return NULL;
        }
        jitPageOffset = 0;
	}
    jitPageOffset += 32;
    return jitPage + jitPageOffset - 32;
}

FuncPtr make_closure(FuncPtr func, void *context) {
    void *buf = alloc_closure();
    
    if (buf == NULL) {
        return NULL;
    }
    if (mprotect(jitPage, PAGE_SIZE, PROT_READ | PROT_WRITE) != 0) {
        return NULL;
    }
    *(uint8_t*)buf = 0x49;
    *(uint8_t*)(buf + 1) = 0xbb;
    *(uint64_t*)(buf + 2) = (uint64_t)func;
    *(uint8_t*)(buf + 10) = 0x49;
    *(uint8_t*)(buf + 11) = 0xba;
    *(uint64_t*)(buf + 12) = (uint64_t)context;
    *(uint8_t*)(buf + 20) = 0x41;
    *(uint8_t*)(buf + 21) = 0xff;
    *(uint8_t*)(buf + 22) = 0xe3;
    if (mprotect(jitPage, PAGE_SIZE, PROT_READ | PROT_EXEC) != 0) {
        return NULL;
    }
    return (void (*)(void))buf;
}
```
