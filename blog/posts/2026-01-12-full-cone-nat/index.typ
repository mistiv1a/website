#import "/template.typ": doc-template

#doc-template(
title: "专治各种游戏联机\n疑难杂症",
date: "2026年1月12日",
body: [

a.k.a. 怎么基于VPS把游戏电脑的网络的NAT类型变成NAT1

= 背景

联机游戏，本应是件乐事，但当连接不稳、延迟很高之时，却又变为痛苦。究其原因，Steam上的大部分联机游戏，为节省成本，并不会像传统的网络游戏那样，设有中心服务器，而是采用点对点连接。而家用宽带，往往具有复杂的防火墙和NAT，互通有诸多阻碍。二则玩家之间相互发送的数据包，都是家用宽带之间的点对点数据包。这些数据包在网络运营商看来，并不优先，网络稍有拥堵即丢弃。

#image("1.jpg", width: 75%)

这时，如果自己在VPS上自己运行服务端就会好很多，比如Factorio、比如Minecraft，都是这样。

但此举并不能推广至所有游戏，很多游戏并不支持自己运行Linux服务端。这时，静态NAT就可派上用场了。和家用宽带路由器上常见的动态NAT不同，静态NAT是一对一的，没有任何IP、端口的限制。在VPS服务器和作为联机主机的游戏电脑之间配置好静态NAT之后，作为网关的VPS服务器就变成了游戏电脑在网络上的“化身”。VPS所接收的数据，无论端口，都会被原封不动地转发至作为主机的游戏电脑上。而游戏电脑发出地数据包反之亦然。如此一来，虽然作为联机游戏的主机运行在自己面前的家用电脑上，在网络上的效果却和直接在VPS上托管联机服务器近似。

#image("2.jpg", width: 75%)

= 密钥生成

首先，在VPS上安装`wireguard-tools`。

```sh
apt install wireguard-tools
```

然后用`wg genkey`和`wg pubkey`命令创建一对Wireguard密钥对：

```sh
sk1=$(wg genkey)
pk1=$(echo $sk1 | wg pubkey)
echo $sk1
echo $pk1
```

其中，sk1是私钥，pk1是公钥，需要记录下来，作为服务器的密钥。

然后再重复一次，再生成一组sk2、pk2，作为游戏电脑的密钥。

= VPS配置

首先说一下如何选择VPS，这里一般优先选离游戏电脑较近的机房。根据游戏服务器的特点，最好选择流量计费、不限制带宽的网络计费模式。然后要把VPS服务商提供的防火墙关闭，我们自己来配置防火墙策略。

我们先配置Wireguard：用管理员权限，创建一个Wireguard配置文件：

```sh
sudo vim /etc/wireguard/wg0.conf
```

文件内容如下：

```ini
[Interface]
PrivateKey = 填入sk1
Address = 10.1.1.1/32
MTU=1420
ListenPort = 51820

[Peer]
PublicKey = 填入pk2
AllowedIPs = 10.1.1.2/32
```

然后用`ip addr`看一下VPS上以太网接口，一般都是`eth0`，假设其IP地址是`111.111.111.111`。

将这些命令加入到开机自动运行中，`111.111.111.111`需要替换成对应的以太网口上的网址。VPS可能也有静态NAT，所以VPS的公网地址和VPS的以太网口地址不见得一样，这里使用的是VPS的以太网口地址。

```sh
sysctl -w net.ipv4.ip_forward=1

wg-quick up wg0
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -j ACCEPT

iptables -t nat -A POSTROUTING \
    -o eth0 -s 10.1.1.2 \
    -j SNAT --to-source 111.111.111.111

iptables -t nat -A PREROUTING \
    -i eth0 -p udp --dport 1025:65535 \
    -j DNAT --to-destination 10.1.1.2
iptables -t nat -A PREROUTING \
    -i eth0 -p tcp --dport 1025:65535 \
    -j DNAT --to-destination 10.1.1.2

iptables -t nat -I PREROUTING \
    -i eth0 -p udp --dport 51820 -j RETURN
```

利用systemd创建开机自动运行脚本的方法请自行查询AI。

然后重启VPS。

= 游戏电脑配置

这里以Windows为例，Linux上的配置基本没有什么区别。

这里假设VPS的公网地址是`123.123.123.123`。下面的实例中的`123.123.123.123`都要替换成VPS服务器的真实的IP地址。VPS可能也有静态NAT，所以VPS的公网地址和VPS的以太网口地址不见得一样，这里使用的是VPS的公网地址。

首先下载安装Windows上的Wireguard客户端：#link("https://download.wireguard.com/windows-client/", "下载链接")。

然后计算一下Wiregurad的AllowedIP，可以使用#link("https://www.procustodibus.com/blog/2021/03/wireguard-allowedips-calculator/", "这个网站")来计算。在Allowed IPs中填入`0.0.0.0/0`。在Disallowed IPs中填入：`192.168.0.0/16, 123.123.123.123/32`，然后点击“Calculate”，把`AllowedIPs = ...`一大串复制下来。

创建一个conf扩展名的文件，比如`wg0.conf`，用记事本打开，填入：

```ini
[Interface]
PrivateKey = 填入sk2
Address = 10.1.1.2/32
DNS = 8.8.8.8

[Peer]
PublicKey = 填入pk1
AllowedIPs = 填入刚才计算的一大串
Endpoint = 123.123.123.123:51820
PersistentKeepalive = 25
```

用Wireguard客户端载入这个配置文件，然后点击“连接”。这个时候理论上就配置完成了。

如果有什么clash之类的透明代理工具什么的，这里最好都退出一下，可能会有干扰。

这个时候可以在搜索引擎上搜索“NAT检测”，找个基于WebRTC的NAT检测网站看一下此时的NAT类型，如果顺利的话应该会显示为“NAT1”或者“Full Cone NAT”，这样就算成功了。这个时候再启动联机游戏，大部分情况下各种疑难杂症应该都会消失。

])