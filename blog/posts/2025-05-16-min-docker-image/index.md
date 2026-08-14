如何制作出极小的超轻量Docker镜像
========

使用Ubuntu作为基础镜像构建出来的Docker镜像动辄几百MB，甚至上GB。但是实际上，运行一个二进制程序依赖的文件并不多，如果只保留运行程序必备的文件，势必能大量缩减镜像尺寸。

这里以一个Rust应用为例，尝试打包一个可以运行ripgrep的镜像，C/C++、Go等编译型语言也可以依葫芦画瓢。

## 准备文件

用`ldd`命令查看ripgrep的动态链接库依赖：

```sh
ldd /usr/bin/rg
```

得到：

```
linux-vdso.so.1 (0x00007bd80ef30000)
libpcre2-8.so.0 => /usr/lib/libpcre2-8.so.0 (0x00007bd80e912000)
libgcc_s.so.1 => /usr/lib/libgcc_s.so.1 (0x00007bd80eefd000)
libc.so.6 => /usr/lib/libc.so.6 (0x00007bd80e722000)
/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2
(0x00007bd80ef32000)
```

其中第一条是内核插入内存的，不需要理会。因此，`rg`最少只需要四个so文件即可运行。

创建一个新目录：

```sh
mkdir rootfs
```

编写一个脚本把这些so文件都复制rootfs中的对应位置：

```sh
#!/bin/bash

copy_file () {
    local dir=$(dirname $1)
    mkdir -p rootfs/$dir
    cp $1 rootfs/$dir
}

for f in $(ldd /usr/bin/rg | grep '=>' | awk '{print $3}'); do
    copy_file $f
done
```

运行脚本。然后注意到

```
/lib64/ld-linux-x86-64.so.2 => /usr/lib64/ld-linux-x86-64.so.2
(0x00007bd80ef32000)
```

把`ld-linux-x86-64.so.2`复制到`rootfs/lib64`中。

```sh
mkdir -p rootfs/lib64
cp rootfs/usr/lib64/ld-linux-x86-64.so.2 rootfs/lib64/
```

然后把`rg`本体复制到rootfs：

```sh
cp /usr/bin/rg rootfs/
```

至此，Docker镜像的文件系统准备完毕。

## 创建镜像

创建`Dockerfile`：

```Dockerfile
FROM scratch
COPY rootfs /
ENTRYPOINT ["/rg"]
```

创建Docker镜像：

```sh
sudo docker build -t myrg .
```

尝试运行：

```sh
sudo docker run --rm myrg --version
```

得到：

```
$ sudo docker run --rm myrg --version
ripgrep 14.1.1

features:+pcre2
simd(compile):+SSE2,-SSSE3,-AVX2
simd(runtime):+SSE2,+SSSE3,+AVX2

PCRE2 10.43 is available (JIT is available)
```

至此Docker镜像构建完成。

查看尺寸：

```sh
sudo docker images
```

得到：

```
REPOSITORY         TAG         IMAGE ID      CREATED      SIZE
localhost/myrg     latest      89ce8f41feaa  4 minutes ago  9.23 MB
```

可以看到只有9.23MB。

## Chroot Jail

其实这种方式跟创建chroot jail的原理是一样的，用chroot也可以运行：

```sh
sudo chroot rootfs /rg --version
```

现实中，如果真的要这么部署此类应用，考虑到安全问题，最好用普通用户权限运行。

```sh
sudo chroot --userspec 1000:1000 rootfs /rg --version
```

## 局限性

有的应用，尤其是Python之类的动态语言，非常依赖用`dlopen`动态加载so文件，这些文件无法用ldd查询到，无法用这种方式打包。虽然也可以用`strace`分析系统调用，查看程序具体打开过哪些文件，但是这样仍然很难保证复制到加载所有的动态链接库。

因此，该方法通常只适合编译型语言，如C/C++、Go、Rust、Haskell等等。
