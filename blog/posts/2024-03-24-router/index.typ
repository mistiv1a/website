#import "/template.typ":*
#doc-template(
title: "基于Debian 12的IPv4/IPv6双栈软路由",
date: "2024年3月24日",
body: [

= 缘起

最近买了一个Intel Celeron处理器的便宜的工控小主机。这个主机上有两个网卡，很适合用作路由器。刚好我的路由器因为年代久远，不支持IPv6，所以我就决定用这个机器换掉原来的路由器。原本的无线路由器只用作接入点。原本按常理路由器应该选用OpenWRT之类的专用路由器操作系统，但是这个机器我还想同时承担很多服务器功能，还是Debian用起来更加得心应手，而代价就是没有一个好用的一站式web配置界面，只能手工操作。

所以这里就记录一下怎么用Debian来配置出一个可用的服务器。

= 基础设定

这台主机有两个网卡，在操作系统里面的名字是enp2s0和enp4s0。理论上，借由VLAN，一个网口即可成为路由器。但是以我的经验来说，基于VLAN的单臂路由器配置起来很麻烦，本着“不折腾”的原则，这边还是建议使用两个网卡。如果机器主板上只有一个网卡，则可以购入一块USB 3.0接口的网卡，即可起到同样的作用。

在这里，我把`enp2s0`作为广域网网口，网段由ISP分配。而`enp4s0`则是局域网网口，
IPv4网段是`192.168.31.0/24`，路由器的IP地址是`192.168.31.63`；IPv6网段是`fc61:
5887:1acd:4260::/64`，路由器自身的IPv6地址是`fc61:5887:1acd:4260::1`。

IPv4的网段可以从`192.168.*.*`中任选，只要不会冲突即可。IPv6的私有网段是`fc`开头的，所以只要以fc开头即可，后面可以任意填写。我这里用了随机生成的64位网段，如果你要用`fc11:4514:1919:8100::/64`，也是可以的。


= 广域网设置

Debian现在用networking服务来配置网络。编辑`/etc/network/interfaces`，加入：

```
allow-hotplug enp2s0
iface enp2s0 inet dhcp
iface enp2s0 inet6 dhcp
```

然后运行：

```sh
sudo systemctl restart networking
```


= 局域网设置

同样编辑`/etc/network/interfaces`，加入：

```
allow-hotplug enp4s0
iface enp4s0 inet static
    address 192.168.31.63/24
iface enp4s0 inet6 static
    address fc61:5887:1acd:4260::1/64
```

然后运行：

```sh
sudo systemctl restart networking
```


= IP转发

编辑`/etc/sysctl.conf`，加入：

```
net.ipv4.ip_forward = 1
net.ipv6.conf.enp2s0.accept_ra = 2
net.ipv6.conf.all.forwarding=1
```

然后使配置即刻生效：

```sh
sudo sysctl -p
```

然而这里生效之后不知道为什么默认路由规则会消失，这里我也不知道是什么问题，所以我选择直接手动添加路由规则：

```sh
sudo ip -6 route add \
    default via fe80::1 \
        dev enp2s0 \
        proto ra \
        metric 1024 \
        hoplimit 255 \
        pref medium
```

不同的网络环境下的路由规则可能不一样，可以在开启IPv6的转发前用下面的命令看一下当前的路由规则是什么。

```sh
sudo ip -6 route | grep default
```

另外，这段代码也要加入到开机启动自运行脚本中。

= NAT

现在Linux的防火墙配置已经进入了nftables的时代，不过我还没怎么学过nftables，所以还是选择了用iptables兼容层。

IPv4的NAT配置：

```sh
IPT=/usr/sbin/iptables
SUB_NET=192.168.31.0/24
WAN_FACE=enp2s0
LAN_FACE=enp4s0

$IPT -t nat -I POSTROUTING 1 -s $SUB_NET -o $WAN_FACE -j MASQUERADE
$IPT -I INPUT -i $LAN_FACE -j ACCEPT
$IPT -I FORWARD -i $WAN_FACE -o $LAN_FACE -j ACCEPT
$IPT -I FORWARD -i $LAN_FACE -o $WAN_FACE -j ACCEPT
```

IPv6的NAT配置：

```sh
IPT=/usr/sbin/ip6tables
SUB_NET=fc61:5887:1acd:4260::/64
WAN_FACE=enp2s0

$IPT -t nat -A POSTROUTING -o $WAN_FACE -j MASQUERADE
```

这两个是bash脚本，也要加入到开机启动的脚本中。

理论上IPv6是完全不需要NAT的，但是因为我不太能搞清楚我的ISP的IPv6的地址分配规则，所以选择退而求其次，选择了稳妥的NAT。


= DHCP服务器

Debian 12提供了一个DHCP服务器isc-dhcp-server：

```sh
sudo apt install isc-dhcp-server
```

首先修改`/etc/default/isc-dhcp-server`，这里我们只需要IPv4：

```
INTERFACESv4="enp4s0"
INTERFACESv6=""
```

然后编辑`/etc/dhcp/dhcpd.conf`：
    
```
option domain-name-servers 223.5.5.5;

subnet 192.168.31.0 netmask 255.255.255.0 {
    range 192.168.31.100 192.168.31.200;
    option routers 192.168.31.63;
}
```

这里选的DNS服务器是阿里云的服务器，主要在国内用，如果在国外的话，直接选用
8.8.8.8或者1.1.1.1即可。

对于IPv6，则不需要DHCP，可以直接用#link("https://en.wikipedia.org/wiki/IPv6", "IPv6的无状态自配置功能")。

首先安装radvd：

```sh
sudo apt install radvd
```

然后创建配置/etc/radvd.conf：

```
interface enp4s0 {
    AdvSendAdvert on;
    MinRtrAdvInterval 30;
    MaxRtrAdvInterval 100;
    prefix fc61:5887:1acd:4260::/64 {
        AdvOnLink on;
        AdvAutonomous on;
        AdvRouterAddr off;
    };
};
```


最后重启DHCP服务器和radvd：

```sh
sudo systemctl restart isc-dhcp-server
sudo systemctl restart radvd
```

如果这两个服务器能正常运作的话，软路由就可以宣布完工了。

])