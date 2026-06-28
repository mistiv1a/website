// 如何使用新闻组
#import "/template.typ":*

#doc-template(
title: "如何使用新闻组",
date: "2025年6月4日",
body: [

= TL;DR.

如果你已经知道新闻组是什么的话，请用NNTP客户端直接连接下面的地址：

```
nntps://raye.mistivia.com:563/sharknews
```

= 什么是新闻组

新闻组是一种基于NNTP协议的公共讨论系统，也叫Usenet。它类似于一个巨大的公告板/论坛，用户可以在不同的“组”中发布文章，其他用户则可以阅读和回复这些文章。

1980年代和1990年代早期是新闻组的黄金时代。那时候，它几乎是互联网上唯一的大规模公共讨论平台，见证了很多互联网最早期的风气云涌，例如开源运动的兴起。当时新闻组的存档至今仍然是探寻互联网早期文化的宝库。但是随着Web的崛起，新闻组已经逐渐淡出历史舞台。

= 我的新闻组服务器

纯粹是为了好玩，我搭建了一个新闻组服务器，部署在“raye.mistivia.com”这台服务器上。这个新闻组可以用作知识库、公告板，乃至聊天室。虽然没有万维网那么强大，但是可以提供一些“复古”的独特乐趣。

= 使用指南

虽然是已经近乎淘汰的古老协议，但是新闻组依然有很多客户端支持，其中最知名的当属雷鸟（Thunderbird）。所以这里就以雷鸟为例介绍如何使用新闻组。

- #link("https://releases.mozilla.org/pub/thunderbird/releases/139.0.1/win64/zh-CN/", "Windows下载链接")
- #link("https://releases.mozilla.org/pub/thunderbird/releases/139.0.1/mac/zh-CN/", "macOS下载链接")

== 设置服务器

打开雷鸟后，点击右上角菜单。选择“添加帐号”。

#image("addaccount.jpg", width:70%);

选择“新闻组”。

#image("newsgroup.jpg", width:70%);

填入自己的昵称和电子邮箱地址。

#image("id.jpg", width:70%);

填入服务器地址：“raye.mistivia.com”。

#image("serveraddr.jpg", width:70%);

添加完成之后重启雷鸟。

== （可选）配置TLS安全连接

雷鸟中，默认新增的新闻组服务器会使用不安全的明文连接，因此最好改成用安全的TLS连接。

在左侧栏选中新闻组服务器，点击“账户设置”。

#image("accountsetting.jpg", width:70%);

然后选择“服务器”，把“连接安全”改成“SSL/TLS”。

#image("tls.jpg", width:70%);

== 订阅新闻组

在刚才添加的新闻组服务器上右击，选择“订阅”。

#image("subscribe.jpg", width:70%);

勾选上“sharknews”组，然后确认。

#image("sharknews.jpg", width:70%);

== 发贴

在左侧栏选中“sharknews”组，然后点击“写信”：

#image("write.jpg", width:70%);

即可向新闻组发贴。

#image("compose.jpg", width:70%);

== 回复贴子

如果要回复某一篇贴子，则选中想要回复的贴子，然后再点击“回复组”。即可在新闻组中跟贴。

#image("reply.jpg", width:70%);

])