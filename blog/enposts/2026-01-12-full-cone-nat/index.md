Curing All Sorts of Online Gaming Connectivity Issues
========

a.k.a. how to change the NAT type of a gaming computer's network into NAT1 with a VPS

## Background

Multiplayer gaming should be a pleasure, but when the connection is unstable and latency is high, it becomes a torment. The reason is that, in order to save costs, most multiplayer games on Steam do not have central servers the way traditional online games do. Instead, they use peer-to-peer connections. Home broadband connections often have complex firewalls and NAT, which place many obstacles in the way of establishing connectivity. Furthermore, the data packets that players send to each other are peer-to-peer packets traveling between home broadband connections. In the eyes of network operators, these packets receive no priority, and they are discarded as soon as the network becomes even slightly congested.

At this point, hosting your own server on a VPS helps a great deal. Factorio and Minecraft, for example, both work this way.

However, this approach does not extend to all games, because many games do not support running your own Linux server. This is where static NAT becomes useful. Unlike the dynamic NAT commonly seen on home broadband routers, static NAT is one-to-one and imposes no restrictions on IP addresses or ports. Once static NAT is configured between the VPS server and the gaming computer that acts as the game host, the VPS server, acting as the gateway, becomes the gaming computer's "avatar" on the network. All data received by the VPS, regardless of port, is forwarded unchanged to the gaming computer that acts as the host. Data packets sent out by the gaming computer follow the same path in reverse. As a result, although the game host runs on a home computer in front of you, the effect on the network is close to hosting the multiplayer server directly on the VPS.


## Generating Keys

First, install `wireguard-tools` on the VPS.

```sh
apt install wireguard-tools
```

Then use the `wg genkey` and `wg pubkey` commands to generate a pair of WireGuard keys:

```sh
sk1=$(wg genkey)
pk1=$(echo $sk1 | wg pubkey)
echo $sk1
echo $pk1
```

Here, sk1 is the private key and pk1 is the public key. Save them; they will be used as the server's keys.

Then repeat the process once more to generate another set, sk2 and pk2, which will be used as the gaming computer's keys.

## Configuring the VPS

First, a few words on choosing a VPS. In general, prefer a datacenter located close to the gaming computer. Given the characteristics of game servers, it is best to choose a billing plan based on traffic volume without bandwidth limits. Also, disable the firewall provided by the VPS provider, because we will manage the firewall policy ourselves.

Let us configure WireGuard first. Create a WireGuard configuration file with administrator privileges:

```sh
sudo vim /etc/wireguard/wg0.conf
```

The file should contain the following:

```ini
[Interface]
PrivateKey = use sk1
Address = 10.1.1.1/32
MTU=1420
ListenPort = 51820

[Peer]
PublicKey = use pk2
AllowedIPs = 10.1.1.2/32
```

Then use `ip addr` to check the Ethernet interface on the VPS. It is usually `eth0`. Suppose its IP address is `111.111.111.111`.

Add these commands to the boot-time startup sequence, replacing `111.111.111.111` with the address of the corresponding Ethernet interface. The VPS may also have static NAT, so its public address and its Ethernet interface address are not necessarily identical. Here, use the Ethernet interface address.

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

For instructions on creating a boot-time startup script with systemd, please consult an AI.

Then reboot the VPS.

## Configuring the Gaming Computer

Here I take Windows as an example. The configuration on Linux is essentially the same.

Assume the VPS's public address is `123.123.123.123`. Throughout the examples below, replace `123.123.123.123` with the real IP address of the VPS server. The VPS may also have static NAT, so its public address and its Ethernet interface address are not necessarily identical. Here, use the public address of the VPS.

First, download and install the WireGuard client for Windows: [download link](https://download.wireguard.com/windows-client/).

Then calculate the AllowedIPs for WireGuard. The calculation can be done with [this website](https://www.procustodibus.com/blog/2021/03/wireguard-allowedips-calculator/). Enter `0.0.0.0/0` in the Allowed IPs field. In the Disallowed IPs field, enter `192.168.0.0/16, 123.123.123.123/32`, then click "Calculate" and copy the long `AllowedIPs = ...` string it produces.

Create a file with a `.conf` extension, for example `wg0.conf`, open it with Notepad, and enter the following:

```ini
[Interface]
PrivateKey = use sk2
Address = 10.1.1.2/32
DNS = 8.8.8.8

[Peer]
PublicKey = use pk1
AllowedIPs = use the long string calculated above
Endpoint = 123.123.123.123:51820
PersistentKeepalive = 25
```

Load this configuration file in the WireGuard client and click "Connect". At this point the configuration should be complete in theory.

If you have transparent proxy tools such as Clash running, it is best to quit them, as they may cause interference.

Now search the web for "NAT test" and find a WebRTC-based NAT detection website to check your current NAT type. If all goes well, it should show "NAT1" or "Full Cone NAT", which means you have succeeded. Then start the multiplayer game again. In most cases, those various connectivity problems should disappear.
