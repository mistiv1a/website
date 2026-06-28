// udp2raw + Wiregurad组建虚拟专网
#import "/template.typ":*
#doc-template(
title: "udp2raw + Wiregurad组建虚拟专网",
date: "2024年1月27日",
body: [

= 服务端配置

Wireguard配置：

```ini
[Interface]
Address = 10.7.1.1/24
ListenPort = 51820
PrivateKey = *************
MTU=1350

[Peer]
PublicKey = *************
AllowedIPs = 10.7.1.2/32
```


用iptables开启NAT：

```sh
#!/bin/bash

IPT=iptables
SUB_NET=10.7.1.0/24
IN_FACE=eth0
WG_FACE=wg0
WG_PORT=51820

sudo $IPT -t nat -I POSTROUTING 1 -s $SUB_NET -o $IN_FACE -j MASQUERADE
sudo $IPT -I INPUT -i $WG_FACE -j ACCEPT
sudo $IPT -I INPUT -i lo -j ACCEPT
sudo $IPT -I FORWARD -i $IN_FACE -o $WG_FACE -j ACCEPT
sudo $IPT -I FORWARD -i $WG_FACE -o $IN_FACE -j ACCEPT
sudo $IPT -I INPUT -i $IN_FACE -p udp --dport $WG_PORT -j ACCEPT
sudo $IPT -I INPUT -i lo -p udp --dport $WG_PORT -j ACCEPT
```

在/etc/sysctl.conf中启用ip转发：

```
net.ipv4.ip_forward = 1
```

用udp2raw转换成fakeTCP：

```sh
sudo ./udp2raw -s \
    -l 0.0.0.0:53388 \
    -r 127.0.0.1:51820 \
    -k "YourPasswordHere" \
    --fix-gro
```


= 客户端配置

udp2raw客户端配置:

```sh
sudo ./udp2raw -c \
    -l 127.0.0.1:53388 \
    -r [SERVER IP]:53388 \
    -k "YourPasswordHere" \
    --fix-gro
```

Wireguard配置：

```ini
[Interface]
Address = 10.7.1.2/32
PrivateKey = **********
MTU=1350

[Peer]
PublicKey = **********
Endpoint = 127.0.0.1:53388
AllowedIPs = 10.7.1.1/32
```

])