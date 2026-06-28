// 写一个虚拟机管理器
#import "/template.typ": *

#doc-template(
title: "写一个虚拟机管理器",
date: "2026年2月2日",
body: [

最近因为想学 eBPF 的关系，接触到了 #link("https://firecracker-microvm.github.io/")[Firecracker] 这个虚拟机管理器，结果正事没干一头拐进了虚拟化的坑里。本来我对虚拟机管理器的印象都是 QEMU、VMWare 之类的庞然大物，不过 Firecracker 突然让我发现虚拟机管理器其实也不见得非得这么复杂，于是就萌生了自己做一个虚拟机管理器的想法。

最后的成果是成功启动了Linux内核，并成功运行了 BusyBox 的 Shell，如下图：

#image("1.jpg", width: 75%)

相关的代码放在了 #link("https://github.com/mistivia/mvvmm")[GitHub] 上面。本文的后面也会主要就着这个源代码讲解。

过程中也参考了不少之前已有的资料，会一并放在末尾。

= 创建虚拟机

这一步主要用 `ioctl` 调用一些 KVM 的接口，代码在 `vm_guest_init` 函数当中。这一步没什么好介绍的，就是一些套路化的东西：

- `KVM_CREATE_VM`：创建虚拟机
- `KVM_CREATE_IRQCHIP`：创建中断芯片模拟程序
- `KVM_CREATE_PIT2`：创建时钟芯片模拟程序
- `KVM_SET_USER_MEMORY_REGION`：加载用 `mmap` 分配出来的内存
- `KVM_CREATE_VCPU`：创建虚拟 CPU

= CPU 初始化

这里就来到了本文的第一个分歧点。我们的目标是加载并启动 Linux 内核，而因为 x86 架构臭名昭著的历史包袱，64 位的 Linux 内核中实际上有 3 个启动点，分别对应了 16 位、32 位，以及 64 位。如何选择就成了一个问题。

如果我们选择从 16 位启动点启动内核，就意味着我们要实现 BIOS 模拟，想想就十分繁琐。而如果从 64 位启动点开始启动，我们就必须首先进入 CPU 的 64 位模式。而 x86 CPU 的 64 位模式要求必须分页，所以我们还要先处理内存映射并创建页表。

相比之下，32 位启动就简单多了，不需要BIOS。也不要求创建页表。虽然我们的 Linux 内核是 64 位的，但是 Linux 内核会帮我们处理好分页并进入64位模式，并不需要担心。我们是来做虚拟机管理器的，不是来做 bootloader 和操作系统的，所以自然，从 32 位启动点启动是最好的选择。

根据 Linux 内核的启动协议，CPU 在跳转到 32 位内核启动点之前，需要进入32位的"平坦模式"，在这个模式下，CPU 在 32 位模式中运行，但是却没有分页，所有内存地址均直接映射到物理内存。

为了进入这个模式，在实际的机器中，有一个特别复杂的初始化流程。具体可以查看 #link("https://wiki.osdev.org/GDT_Tutorial")[OSDev Wiki]。但是这个也完全是 x86 架构的历史糟粕，并不值得耗费心力。总之，利用 KVM 提供的接口，设置若干个段寄存器和一个特殊的 cr0 寄存器的内部状态，我们就可以让虚拟CPU进入 32 位平坦模式了：

```c
void set_flat_mode(struct kvm_segment *seg) {
    seg->base = 0;
    seg->limit = 0xffffffff;
    seg->g = 1;
    seg->db = 1;
}

struct kvm_sregs sregs;
ioctl(cpu_fd, KVM_GET_SREGS, &sregs);
set_flat_mode(&sregs.cs);
set_flat_mode(&sregs.ds);
set_flat_mode(&sregs.es);
set_flat_mode(&sregs.fs);
set_flat_mode(&sregs.gs);
set_flat_mode(&sregs.ss);
sregs.cr0 |= 0x1;
ioctl(cpu_fd, KVM_SET_SREGS, &sregs);
```

最后，需要 rip 寄存器设置为 0x100000，稍后内核启动点将会加载到这个地方，而 CPU 也会从这里启航。而 rsp 寄存器需要设置为 0x10000，内核的启动参数将会加载到这个位置：

```c
struct kvm_regs regs;
ioctl(cpu_fd, KVM_GET_REGS, &regs);
regs.rip = 0x100000;
regs.rsi = 0x10000;
ioctl(cpu_fd, KVM_SET_REGS, &regs);
```

至于为什么是这两个数字，下一节将会介绍，这是 Linux 内核启动协议的一部分。

最后一步是设置 CPUID，我们从 KVM API 中获取 KVM 支持的 CPUID，然后设置给虚拟 CPU 即可：

```c
struct kvm_cpuid2 *cpuid;
int max_entries = 100;
cpuid = malloc(sizeof(*cpuid) + 
    max_entries * sizeof(struct kvm_cpuid_entry2));
cpuid->nent = max_entries;
ioctl(kvm_fd, KVM_GET_SUPPORTED_CPUID, cpuid)
ioctl(cpu_fd, KVM_SET_CPUID2, cpuid)
```

这样，CPU 初始化完毕，只欠内核。

= 加载内核

要加载内核，首先我们要知道内核文件的布局。现代Linux内核的文件模式叫做"bzImage"。传统上，磁盘上的每 512 字节被称为一个"扇区"。Linux内核上最开始的 512 字节就是用于从 16 位模式启动的启动扇区（boot）。然后是若干个扇区的启动参数（setup）。再然后才是真正的内核（kernel）。如下图：

#image("2.jpg", width: 80%)

其中，boot 部分是用于 16 位启动的，我们不需要理会。我们只需要看后两部分。根据Linux内核的启动协议，内核加载时需要完成这些步骤：

- 加载 Linux 内核的第一步应该是设置启动参数（`boot_params`，传统上称为"Zero Page"）
- 将内核映像偏移量 0x01f1 开始的 setup 头部加载到 `boot_params` 中并进行检查
- 设置 `boot_params` 中的其他字段
- `%esi`寄存器保存 `boot_params` 的地址

那么我们首先把内核文件（bzImage）映射到内存中：

```c
bz_image = map_file(kernel_path, &bz_image_size);
```

在上一节中，我们把 `%rsi` 寄存器设置为了 0x10000，因此，我们也会把 `struct boot_params` 设置到内存中的 0x10000 处并清零。

```c
zeropage = (struct boot_params *)(vm->memory + 0x10000);
memset(zeropage, 0, sizeof(*zeropage));
```

加载偏移量 0x01f1 开始的 setup 头部：

```c
memcpy(&zeropage->hdr, bz_image+0x01f1, sizeof(zeropage->hdr));
```

我们还需要在内存中随便找一块空闲的位置存放命令行参数，这里我选了 0x20000。我们没有VGA显示，只能用串口，所以设置一下用串口打印，并且开启debug显示："console=ttyS0 debug"。

```c
#define KERNEL_ARGS "console=ttyS0 debug"
cmd_line = (char *)(vm->memory + 0x20000);
memcpy(cmd_line, KERNEL_ARGS, strlen(KERNEL_ARGS) + 1);
```

此外，我们可能还需要加载一个用于初始化的内存虚拟盘（initrd）。这个 initrd 的位置就比较宽松了，随便放什么地方都可以，只要内核能知道就行。这里我选择放在内存的 512 MB 处。参见 `load_initrd` 函数：

```c
uint32_t initrd_addr = 0x20000000;
memcpy(vm->memory + initrd_addr, initrd, st.st_size);
```

然后我们设置一下内核的启动参数。首先是命令行参数的位置：

```c
zeropage->hdr.cmd_line_ptr = 0x20000;
```

图形模式设置位默认的 0xFFFF：

```c
zeropage->hdr.vid_mode = 0xFFFF;
```

我们没用到 bootloader，而是直接模拟了内核加载过程，所以 bootloader 字段随便设一个：

```c
zeropage->hdr.type_of_loader = 0xFF;
```

设置内存虚拟盘的位置：

```c
zeropage->hdr.ramdisk_image = initrd_addr;
zeropage->hdr.ramdisk_size = st.st_size;
```

告诉内核，我们加载内核的位置是 1MB 处：

```c
zeropage->hdr.loadflags |= LOADED_HIGH;
```

最麻烦的一步是设置内存布局，这里我选择的是把 0-640KB 和 1MB-1GB 这两个区域标记为可用内存。至于为什么 640KB 到 1MB 之间要留个空洞，我也不知道，我只发现如果设置错误可能会 kernel panic。不过这又是 x86 架构的历史包袱造成的，我选择不去深究。

```c
zeropage->e820_entries = 2;
// first 640KB
zeropage->e820_table[0].addr = 0;
zeropage->e820_table[0].size = 0xA0000;
zeropage->e820_table[0].type = 1;
// > 1MB
zeropage->e820_table[1].addr = 0x100000;
zeropage->e820_table[1].size = MEM_SIZE - 0x100000;
zeropage->e820_table[1].type = 1;
```

最后，我们把 bzImage 中的 kernel 部分加载到内存中的 1MB 处。为此，我们需要知道boot和setup部分的大小，boot 固定是 512 字节，setup 的大小，在内核映像偏移量 0x01f1 处，单位是扇区，而 1 扇区是 512 字节。因此，我们得到 kernel 的位置：

```c
setup_size = (zeropage->hdr.setup_sects + 1) * 512;
memcpy(vm->memory + 0x100000,
       (char *)bz_image + setup_size,
       bz_image_size - setup_size);
```

这样，内核加载完毕。

= 串口模拟

在网络设备模拟器调通以前，串口是我们和虚拟机交互的唯一方式，串口可以打印内核的调试信息，也可以用来启动 shell。不过这一节没有什么内容，因为懒得读硬件手册，所以我让 Kimi 模型给我生成了一个凑合能用的串口模拟程序。这个串口模拟器只能输出内容，无法接收输入。不过在现在这个阶段已经够了。

串口模拟相关的代码在 `serial_init` 和 `handle_serial` 这两个函数中。串口模拟器的初始化需要在前面创建虚拟机的时候一并完成。

= 运行虚拟 CPU

这一节主要涉及代码中的 `vm_run` 函数。

在运行虚拟 CPU 之前，首先需要把虚拟 CPU 的文件描述符后面的一小段内存映射出来。而这段内存的大小是通过 `KVM_GET_VCPU_MMAP_SIZE` 接口获得的。这段内存在后面处理 IO 和 MMIO 的时候会有用处：

```c
mmap_size = ioctl(vm->kvm_fd, KVM_GET_VCPU_MMAP_SIZE, 0);
run = mmap(NULL, mmap_size, PROT_READ | PROT_WRITE,
           MAP_SHARED, vm->cpu_fd, 0);
```

完成内存映射之后，就可以通过 `KVM_RUN` 接口运行虚拟 CPU：

```c
ioctl(vm->cpu_fd, KVM_RUN, 0)
```

但是 CPU 运行一段时间之后可能会退出。原因有以下几种：

- 虚拟机关闭
- 虚拟机请求 IO
- 虚拟机请求内存映射 IO（MMIO）

MMIO 对于现代的块设备和网络设备必不可少，但是现阶段我们用不到，所以全部忽略。而碰到退出请求直接退出就好。

至于 IO 请求，这里指的是 x86 架构中的 #link("https://wiki.osdev.org/I/O_Ports")[IO port]，大部分也是可以直接忽略的，但是串口的请求我们需要处理一下。之前映射的内存里面会存放 IO 相关的信息。我们查看其端口，如果是 0x3f8 到 0x3ff 之间的端口，说明是串口 IO，我们调用 `handle_serial` 处理：

```c
if (run->io.port >= 0x3f8 && run->io.port <= 0x3ff) {
    handle_serial(vm, run);
}
```

= 创建 BusyBox 内存虚拟盘

首先安装 BusyBox:

```bash
sudo pacman -S BusyBox
```

然后创建一个 rootfs 目录：

```bash
mkdir rootfs
```

然后创建一些必备的目录：

```bash
cd rootfs
mkdir dev sys proc bin
```

然后把 BusyBox 安装到这个目录里面：

```bash
BusyBox --install bin/
```

然后创建一个 init 脚本：

```bash
#!/bin/sh

mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc
mount -t sysfs sys /sys
mdev -s

echo "BusyBox!"
/bin/sh -l

while : ; do
    sleep 1
done
```

把这个 init 脚本设置为可运行，然后把整个目录打包成一个 cpio 镜像：

```bash
chmod +x init
find . -print0 | cpio --null -ov --format=newc | gzip > ../initrd
```

这样我们就得到了我们的初始化虚拟盘：initrd 文件。

= 收官

这个时候我们就可以把虚拟机跑起来了。首先从本机薅一个内核出来：

```bash
cp /boot/vmlinuz-linux ./vmlinuz
```

不同发行版下面内核文件的名字可能不同，但是应该都大体差不多。

然后编译虚拟机管理器的代码：

```bash
gcc small_vmm.c -o small_vmm
```

最后运行：

```bash
sudo ./small_vmm vmlinuz initrd
```

如果顺利的话，就能像开头那张图一样，看到 BusyBox 的shell提示符。不过输入命令和按回车都是没有反应的，因为前面没有完整实现串口模拟，没有做串口输入的功能。只能按 Ctrl+C 退出。

= 小结

到这里我们的虚拟机管理器就告一段落了。至于下一步，首先自然是要把串口模拟完整做出来，这样就可以在控制台上输入，为此可能需要阅读 8250 芯片的手册和资料。

然后就是实现 Virtual IO 设备的模拟了，需要参考#link("https://docs.oasis-open.org/virtio/virtio/v1.0/virtio-v1.0.html")[这份文档]。完整的实现需要模拟 PCI 总线，但是 Linux 提供了一个命令行参数，我们可以直接把 Virtual IO 映射的 MMIO 内存地址通过内核命令行参数直接告诉内核，而无需通过 PCI 总线，这样就大大降低了开发工作量。

最后，为了让这个虚拟机管理器能够支持多处理器，也还有一段额外的工作量。

现阶段这个虚拟机管理器自然是没法使用的。但是另一方面，这个虚拟机管理器距离有实际用途却也并不遥远。只要再加上块设备和网络设备模拟程序，就完全可以用来部署一些需要环境隔离的后端应用了，用于部署 clawdbot 之类的东西也都可行。

如果说 App 开发、前端、CRUD 后端这些是"显宗"的话，一些比较底层的计算机领域，就全是"密宗"了：虽然实际上并不是很难的东西，但是因为比较小众，很多知识只能依赖口耳相传和啃源代码获得，甚至有时候连最强的 AI 也难以给出良好的解答。虚拟化虽然也算是个很大众的技术了，但是具体到一些细节，就又变成了一个比较接近"密宗"的东西。这也是我写这篇文章的动机。

= 参考资料

- #link("https://www.kernel.org/doc/html/v6.1/x86/boot.html")[The Linux/x86 Boot Protocol]
- #link("https://docs.kernel.org/virt/kvm/api.html")[The Definitive KVM API Documentation]
- #link("https://wdv4758h.github.io/notes/blog/linux-kernel-boot.html")[Linux Kernel Boot]
- #link("https://www.ihcblog.com/rust-mini-vmm-1/")[用Rust实现极简VMM - Ihcblog!]
- #link("https://docs.kernel.org/admin-guide/kernel-parameters.html")[The kernel's command-line parameters]
- #link("https://gist.github.com/zserge/ae9098a75b2b83a1299d19b79b5fe488")[kvm_host.c - GitHub Gist]
- #link("https://github.com/rust-vmm/vmm-reference/")[vmm-reference - GitHub]

])
