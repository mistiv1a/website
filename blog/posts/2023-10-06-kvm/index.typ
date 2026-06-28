// qemu-kvm使用笔记
#import "/template.typ":*
#doc-template(
title: "qemu-kvm使用笔记",
date: "2023年10月6日",
body: [

= 准备工作

忽略MSRS，参见: 

- #link("https://wiki.archlinux.org/title/QEMU#Certain_Windows_games/applications_crashing/causing_a_bluescreen", "Certain Windows games/applications crashing/causing a bluescreen - ArchLinux Wiki")

运行：

```sh
sudo modprobe kvm; echo 1 | sudo tee /sys/module/kvm/parameters/ignore_msrs
```

同时在/etc/modprobe.d/kvm.conf中加入：

```
options kvm ignore_msrs=1
```

权限配置：

```sh
sudo usermod -aG kvm $(whoami)
sudo usermod -aG libvirt $(whoami)
sudo usermod -aG input $(whoami)
```

= 创建虚拟机

首先创建磁盘镜像：

```sh
qemu-img create -f qcow2 os.qcow2 256G
```

然后准备好安装盘镜像，例如Windows 10或者Ubuntu。这里假设安装盘是install.iso。然后创建启动脚本start.sh：

```sh
#!/bin/bash

chipset="type=q35,kernel_irqchip=on,mem-merge=on"
vcpu="host"
hyper="kvm,thread=multi"
CPU_SOCKETS="1"
CPU_CORES="2"
CPU_THREADS="2"
MEM=4096

qemu-system-x86_64 \
    -enable-kvm \
    -m "${MEM}" \
    -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check \
    -machine ${chipset} \
    -cpu ${vcpu} \
    -device ich9-ahci,id=sata \
    -smp "$CPU_THREADS",cores="$CPU_CORES",sockets="$CPU_SOCKETS" \
    -drive id=HDD,if=none,file="./os.qcow2",format=qcow2 \
    -device ide-hd,bus=sata.3,drive=HDD \
    -netdev user,id=net0,hostfwd=tcp::8022-:22 \
    -device e1000-82545em,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \
    -usb  \
    -device usb-tablet \
    -device qemu-xhci,id=xhci \
    -vga virtio \
    -vnc :0 \
    -cdrom ./install.iso
    #-usb -device usb-host,hostbus=1,hostaddr=4
```

完成安装之后就可以把cdrom那一行注释掉。

= 连接USB外接设备

用lsusb查询端口的总线号和设备号，然后用最后一行连进虚拟机，此时需要用sudo权限运行。

音频的配置我没有成功，不过用USB外接声卡然后连通USB是可以的。

])