#import "/template.typ": *

#doc-template(
title: "Writing a Virtual Machine Manager",
date: "February 2, 2026",
parindent: 1.2em,
body: [

I set out to learn eBPF recently, and somewhere along the way I ran into #link("https://firecracker-microvm.github.io/")[Firecracker], a virtual machine manager. I never did get to eBPF: I took a wrong turn and fell straight down the virtualization rabbit hole. Until then my mental image of a VMM had been some behemoth like QEMU or VMware, but Firecracker convinced me that a virtual machine manager doesn't have to be complicated at all. So I decided to build one myself.

The end result was a successful Linux kernel boot, running all the way to a BusyBox shell:

#image("1.jpg", width: 75%)

The code is on #link("https://github.com/mistivia/mvvmm")[GitHub], and the rest of this post walks through it.

= Creating the Virtual Machine

This step is just a handful of `ioctl` calls against the KVM interfaces, all in the `vm_guest_init` function. There isn't much to say about it; it's pure boilerplate:

- `KVM_CREATE_VM`: create the virtual machine
- `KVM_CREATE_IRQCHIP`: create the interrupt chip emulator
- `KVM_CREATE_PIT2`: create the timer chip emulator
- `KVM_SET_USER_MEMORY_REGION`: load the memory allocated with `mmap`
- `KVM_CREATE_VCPU`: create the virtual CPU

= CPU Initialization

Here we hit the first fork in the road. Our goal is to load and boot a Linux kernel, and thanks to x86's infamous historical baggage, a 64-bit Linux kernel has three separate entry points — one each for 16-bit, 32-bit, and 64-bit mode. We have to pick one.

Booting from the 16-bit entry point would mean emulating a BIOS, which is tedious just to think about. Starting from the 64-bit entry point would mean putting the CPU into 64-bit mode ourselves, and 64-bit mode on x86 requires paging, so we'd have to work out the memory mapping and build page tables too.

The 32-bit boot is far simpler by comparison: no BIOS, no page tables. Our kernel is 64-bit, but the kernel itself handles paging and the switch into 64-bit mode, so that's not our problem. We're here to write a virtual machine manager, not a bootloader or an operating system, which makes the 32-bit entry point the obvious choice.

Per the kernel's boot protocol, the CPU must be in 32-bit "flat mode" before we jump to the 32-bit entry point. In flat mode the CPU is 32-bit but paging is off, so every address maps straight to physical memory.

On real hardware, reaching this mode takes a famously convoluted initialization sequence — the #link("https://wiki.osdev.org/GDT_Tutorial")[OSDev Wiki] has the details. That too is pure x86 historical detritus and not worth the effort here. With the interfaces KVM gives us, it comes down to setting the internal state of the segment registers and the `cr0` control register, and the virtual CPU lands in 32-bit flat mode:

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

Finally, `rip` needs to point at 0x100000, where the kernel entry point will be loaded and where the CPU will start executing, and `rsi` needs to point at 0x10000, where the kernel boot parameters will be loaded:

```c
struct kvm_regs regs;
ioctl(cpu_fd, KVM_GET_REGS, &regs);
regs.rip = 0x100000;
regs.rsi = 0x10000;
ioctl(cpu_fd, KVM_SET_REGS, &regs);
```

Both of those addresses come from the Linux kernel boot protocol; the next section explains why they are what they are.

The last step is CPUID: we ask the KVM API which CPUID entries it supports and hand them straight to the virtual CPU:

```c
struct kvm_cpuid2 *cpuid;
int max_entries = 100;
cpuid = malloc(sizeof(*cpuid) +
    max_entries * sizeof(struct kvm_cpuid_entry2));
cpuid->nent = max_entries;
ioctl(kvm_fd, KVM_GET_SUPPORTED_CPUID, cpuid)
ioctl(cpu_fd, KVM_SET_CPUID2, cpuid)
```

That's the CPU initialized. All we're missing now is the kernel.

= Loading the Kernel

To load the kernel we first need to know how the kernel file is laid out. The format a modern Linux kernel ships in is called bzImage. Traditionally, each 512-byte chunk of a disk is called a sector, and the first sector of the kernel image is the boot sector, used when booting from 16-bit mode. After it come several sectors of boot parameters (setup), and only then does the real kernel begin:

#image("2.jpg", width: 80%)

The boot sector is only for 16-bit boot, so we can ignore it and care only about the other two parts. The boot protocol spells out what loading the kernel involves:

- Set up the boot parameters (`boot_params`, traditionally called the "zero page")
- Copy the setup header, which starts at offset 0x01f1 in the kernel image, into `boot_params` and check it
- Fill in the remaining `boot_params` fields
- Point the `%esi` register at `boot_params`

We start by mapping the bzImage into memory:

```c
bz_image = map_file(kernel_path, &bz_image_size);
```

In the previous section we pointed `%rsi` at 0x10000, so that's where `struct boot_params` goes. We place it there and zero it out:

```c
zeropage = (struct boot_params *)(vm->memory + 0x10000);
memset(zeropage, 0, sizeof(*zeropage));
```

Then copy in the setup header from offset 0x01f1:

```c
memcpy(&zeropage->hdr, bz_image+0x01f1, sizeof(zeropage->hdr));
```

The command-line arguments need a free spot in memory too; I picked 0x20000. We have no VGA display, only a serial port, so the arguments tell the kernel to print to the serial console and to turn on debug output:

```c
#define KERNEL_ARGS "console=ttyS0 debug"
cmd_line = (char *)(vm->memory + 0x20000);
memcpy(cmd_line, KERNEL_ARGS, strlen(KERNEL_ARGS) + 1);
```

We may also want an initial RAM disk (initrd). The kernel is relaxed about where the initrd lives — anywhere works, as long as we tell it where. I put mine at the 512 MB mark, in the `load_initrd` function:

```c
uint32_t initrd_addr = 0x20000000;
memcpy(vm->memory + initrd_addr, initrd, st.st_size);
```

Then we fill in the kernel's boot parameters. First, the location of the command-line arguments:

```c
zeropage->hdr.cmd_line_ptr = 0x20000;
```

The video mode field gets the default 0xFFFF:

```c
zeropage->hdr.vid_mode = 0xFFFF;
```

There's no bootloader here — we're emulating the loading process ourselves — so the bootloader field can be anything:

```c
zeropage->hdr.type_of_loader = 0xFF;
```

The location of the RAM disk:

```c
zeropage->hdr.ramdisk_image = initrd_addr;
zeropage->hdr.ramdisk_size = st.st_size;
```

And a flag telling the kernel we're loading it at the 1 MB mark:

```c
zeropage->hdr.loadflags |= LOADED_HIGH;
```

The fiddliest step is the memory layout. I marked two regions as usable memory: 0–640 KB and 1 MB–1 GB. Why there has to be a hole between 640 KB and 1 MB, I have no idea; all I found out is that getting it wrong can panic the kernel. More x86 historical baggage, and I've chosen not to dig.

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

Finally we copy the kernel portion of the bzImage to the 1 MB mark. To find where that portion starts, we need the combined size of the boot and setup parts: boot is a fixed 512 bytes, and the setup size sits in the setup header we just copied, measured in 512-byte sectors. That gives us the kernel's offset:

```c
setup_size = (zeropage->hdr.setup_sects + 1) * 512;
memcpy(vm->memory + 0x100000,
       (char *)bz_image + setup_size,
       bz_image_size - setup_size);
```

And with that, the kernel is loaded.

= Serial Port Emulation

Until there's a network device emulator, the serial port is our only way to interact with the virtual machine: it prints the kernel's debug output, and it can host a shell. There isn't much to this section, though. I couldn't be bothered to read the hardware manual, so I had Kimi generate a serial port emulator that's good enough to get by. It can only write, never read — no input at all — but at this stage that's plenty.

The serial code lives in the `serial_init` and `handle_serial` functions. Note that the emulator's initialization has to happen back when we create the virtual machine.

= Running the Virtual CPU

This section is mostly about the `vm_run` function.

Before we can run the virtual CPU, we have to map a small region of memory sitting behind the virtual CPU's file descriptor; `KVM_GET_VCPU_MMAP_SIZE` tells us how big it is. This region is how KVM hands us the details of IO and MMIO exits later on:

```c
mmap_size = ioctl(vm->kvm_fd, KVM_GET_VCPU_MMAP_SIZE, 0);
run = mmap(NULL, mmap_size, PROT_READ | PROT_WRITE,
           MAP_SHARED, vm->cpu_fd, 0);
```

Once the mapping is done, we can run the virtual CPU through the `KVM_RUN` interface:

```c
ioctl(vm->cpu_fd, KVM_RUN, 0)
```

The CPU then runs until it exits back to us, for one of a few reasons:

- The virtual machine shut down
- The virtual machine requested IO
- The virtual machine requested memory-mapped IO (MMIO)

MMIO is indispensable for modern block and network devices, but we don't need any of that yet, so we ignore it entirely. On a shutdown request, we simply quit.

IO requests here mean x86's #link("https://wiki.osdev.org/I/O_Ports")[IO ports]. Most of them we can ignore outright, but the serial port's requests we do have to handle. The details live in the memory we mapped earlier: we check the port number, and if it falls between 0x3f8 and 0x3ff it belongs to the serial port, so we pass it to `handle_serial`:

```c
if (run->io.port >= 0x3f8 && run->io.port <= 0x3ff) {
    handle_serial(vm, run);
}
```

= Creating the BusyBox RAM Disk

First install BusyBox:

```bash
sudo pacman -S busybox
```

Create a rootfs directory:

```bash
mkdir rootfs
```

Then the directories we can't do without:

```bash
cd rootfs
mkdir dev sys proc bin
```

Install BusyBox into it:

```bash
busybox --install bin/
```

Write an init script:

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

Make it executable, then pack the whole directory into a cpio image:

```bash
chmod +x init
find . -print0 | cpio --null -ov --format=newc | gzip > ../initrd
```

And that gives us our initial RAM disk: the initrd file.

= Wrapping Up

At this point we can get the virtual machine running. First, scrounge a kernel off the host machine:

```bash
cp /boot/vmlinuz-linux ./vmlinuz
```

The filename varies from distribution to distribution, but it's always something close to this.

Then compile the virtual machine manager:

```bash
gcc small_vmm.c -o small_vmm
```

And run it:

```bash
sudo ./small_vmm vmlinuz initrd
```

If all goes well, you'll get the BusyBox shell prompt from the screenshot at the top. Typing at it won't do anything, though — the serial emulation is unfinished and has no input path — so all you can do is hit Ctrl+C to quit.

= Summary

That brings our virtual machine manager to a reasonable stopping point. As for what comes next, the obvious first item is finishing the serial emulation so we can actually type at the console, which probably means reading the manual and whatever else I can find on the 8250 chip.

After that comes emulating virtio devices, which means working from #link("https://docs.oasis-open.org/virtio/virtio/v1.0/virtio-v1.0.html")[this specification]. A complete implementation has to emulate the PCI bus, but Linux offers a command-line parameter for handing the kernel a virtio device's MMIO address directly, no PCI bus involved, which cuts the work down dramatically.

And then there's multiprocessor support, another chunk of work on top of all that.

As it stands, this virtual machine manager is of course useless. But it isn't far from being genuinely useful, either. Add block and network device emulation and it would do fine for deploying backend applications that need environment isolation — running something like clawdbot would be entirely feasible.

If app development, frontend work, and CRUD backends are the popular curriculum, then the lower reaches of computing are the hidden one. None of it is genuinely hard; it's just niche, so much of the knowledge gets passed along by word of mouth and by chewing through source code — sometimes even the strongest AI struggles to give you a decent answer. Virtualization is mainstream enough as technologies go, and yet drill down into the details and it goes hidden again. That's what made me want to write this post.

= References

- #link("https://www.kernel.org/doc/html/v6.1/x86/boot.html")[The Linux/x86 Boot Protocol]
- #link("https://docs.kernel.org/virt/kvm/api.html")[The Definitive KVM API Documentation]
- #link("https://wdv4758h.github.io/notes/blog/linux-kernel-boot.html")[Linux Kernel Boot]
- #link("https://www.ihcblog.com/rust-mini-vmm-1/")[用Rust实现极简VMM - Ihcblog!]
- #link("https://docs.kernel.org/admin-guide/kernel-parameters.html")[The kernel's command-line parameters]
- #link("https://gist.github.com/zserge/ae9098a75b2b83a1299d19b79b5fe488")[kvm_host.c - GitHub Gist]
- #link("https://github.com/rust-vmm/vmm-reference/")[vmm-reference - GitHub]

])
