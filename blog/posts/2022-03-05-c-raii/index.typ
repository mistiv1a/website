// 在C语言中模拟RAII
#import "/template.typ":*

#doc-template(
title: "在C语言中模拟RAII",
date: "2022年3月5日",
body: [

#set heading(numbering: none)

资源安全在C中要比C++中困难不少。C++中有了RAII机制，资源安全可谓得心应手。无怪乎，Stroustrup的《C++程序设计语言》的前半本都在写内存安全和资源安全，而这些也全是用RAII保证的。局部变量一旦出了作用域，其析构函数就被调用了，非常方便。

然而，C语言中就没有这种好用的工具，比如说：

```c
int foo() {
    FILE* fp = fopen("bar", "w");
    if (f == 0) {
        error("failed to open file");
        return -1;
    }
    int ret = do_something(fp);
    if (ret < 0) {
        error("failed to process file");
        fclose(fp);
        return -1;
    }
    fprintf(fp, "this end it");
    fclose(fp);
    return 0;
}
```

这里仅仅是一个简单的例子，`fclose`在这里程序出现了两次；然而，当程序的控制流繁杂起来的时候，资源回收就变得骇人起来。不似C++中，只需要打开一个`ofstream`，然后把剩下的交给析构函数就好。

除了C++以外，别的语言中也有类似的机制，比如说Javas和Go里面都有垃圾回收，用来处理内存。至于别的资源，比如文件柄、网络连接、互斥锁等等，在Java里面会用`try...catch...finally...`处理，而Go语言里面会用`defer`来处理。

所以C里面应该怎么办呢？所幸，gcc提供了一个#link("https://gcc.gnu.org/onlinedocs/gcc/Common-Variable-Attributes.html#Common-Variable-Attributes", "cleanup扩展")，可以用来注册析构函数。

上面那个关闭文件的例子就可以用这个扩展重写成下面这样：

```c
void close_file(FILE** fp_ptr) {
    if (*fp_ptr == NULL) return;
    fprintf(*fp_ptr, "file is closed\n");
    fclose(*fp_ptr);
}

int foo() {
    __attribute__((cleanup(close_file))) FILE* fp = fopen("bar", "w");
    if (fp == NULL) {
        error("failed to open file");
        return -1;
    }
    int ret = do_something(fp);
    if (ret < 0) {
        error("failed to process file");
        return -1;
    }
    fprintf(fp, "this end it\n");
    return 0;
}
```

有了这个cleanup attribute, `close_file`就可以自动执行了，省去了手动管理的困扰。

为了让代码更紧凑，还可以加一个词法宏。

```c
#define CLEANUP(func) __attribute__((cleanup(func)))
```

互斥锁也类似：

```c
pthread_mutex_t mutex;
int count;

void unlock_mutex(pthread_mutex_t **mutex_ptr) {
    pthread_mutex_unlock(*mutex_ptr);
}

void *thread_run(void *arg){
    int i;
    int ret = pthread_mutex_lock(&mutex);
    if (ret != 0) {
        error("failed to acqure lock");
        return 0;
    }
    CLEANUP(unlock_mutex) pthread_mutex_t *defer_mutex = &mutex;
    for (i = 0; i < 3; i++) {
        printf("[%ld]count: %d\n", pthread_self(), ++count);
    }
    return 0;
}

int main() {
    pthread_t threads[10];
    for (int i = 0; i < 10; i++) {
        int res = pthread_create(&threads[i], NULL, thread_run, NULL);
        if (res) error("create thread error");
    }
    for (int i = 0; i < 10; i++) {
        void *ret;
        pthread_join(threads[i], &ret);
    }
    return 0;
}
```

虽说这是个gcc扩展，不过Clang/LLVM工具链也是支持的。

如果想要更通用的写法，还可以用goto语句实现。虽然goto语句一般被认为一种不好的实践，但是在资源回收这个场景中，其实反而被认为是一种好的做法：

```c
int foo() {
    FILE* fp = fopen("bar", "w");
    if (f == 0) {
        error("failed to open file");
        goto clean_0;
    }
    int ret = do_something(fp);
    if (ret < 0) {
        error("failed to process file");
        goto clean_1;
    }
    fprintf(fp, "this end it");
    fclose(fp);
    return 0;

clean_1:
    fclose(fp);
clean_0:
    return -1;
}
```

或者，也可以尝试用宏：

```c
int foo() {
    FILE* fp = NULL;
    #define DEFER \
        if (fp != NULL) fclose(fp);

    fp = fopen("bar", "w");
    if (f == 0) {
        error("failed to open file");
        DEFER return -1;
    }
    int ret = do_something(fp);
    if (ret < 0) {
        error("failed to process file");
        DEFER return -1;
    }
    fprintf(fp, "this end it");
    DEFER return 0;
    #undef DEFER
}
```

= 总结

综合起来，感觉还是用goto语句最佳。

另一边，还有一个#link("http://www.open-std.org/jtc1/sc22/wg14/www/docs/n2895.htm", "给C语言加defer的提案")，不过能不能进标准谁也不知道，就拭目以待吧。

])
