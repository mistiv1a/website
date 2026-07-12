#import "/template.typ":*
#doc-template(
title: "没有公网IP也可以当BT赛博菩萨",
date: "2024年1月28日",
body: [

用BitTorrent下载资源，下载结束之后会进入做种状态上传。这个时候的BT连接一般是传入连接，如果没有公网IP，就没有办法上传。我现在用的中国移动的宽带就是没有公网IP的宽带。

不过我手头有几个VPS服务器，都有公网IP，这些服务器可以用作跳板。

首先我用tailscale建立了mesh VPN网络，我的笔记本电脑的tailscale IP是100.64.0.13，VPS服务器的tailscale IP是100.64.0.30。

用tmux + ssh可以在VPS服务器上快速搭建一个socks5代理：

```sh
ssh -D100.64.0.30:1080 127.0.0.1
```

我用的BitTorrent客户端是qBitTorrent，监听的端口我固定成了42318。利用nginx
stream mod可以设置端口反代：

```conf
stream {
	server {
		listen 0.0.0.0:42318;
		proxy_pass 100.64.0.13:42318;
	}
	server {
		listen 0.0.0.0:42318 udp;
		proxy_pass 100.64.0.13:42318;
	}
}
```

然后设置qBitTorrent。

Tools -> Preferences -> Connections: 传入端口设置为42318、代理服务器设置为100.64.0.30、端口号1080、使用代理服务器处理torrent连接、使用代理解析主机名。

Tools -> Preferences -> BitTorrent：加上tracker服务器，可以参考#link("https://github.com/ngosang/trackerslist", "这个列表")。

Tools -> Preferences -> Advanced：因为用nginx反代之后所有的传入连接的IP都是相同的，所以要在这里选上“Allow multiple connections from the same IP address”。

应用设置之后重启qBitTorrent，就可以当BT赛博菩萨开始布施了。

])
