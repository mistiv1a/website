// 赛博海盗航行指南
#import "/template.typ":doc-template

#doc-template(
title: "赛博海盗航行指南",
date: "2022年3月7日",
body: [

成为海盗，获取盗版资源，并不是不光彩的事情。当今我们身处的世界，文艺被垄断巨头掌握并充满DRM和审查，此时适当地获取盗版，把钱用在刀刃上，支持自己喜欢的独立作者，不失为一种反抗。而获取盗版资源，点对点下载是最重要的方式之一。

不过，在很多发达国家，尤其是欧盟、北美、日本，成为海盗也会有法律风险，有的地区甚至可能入罪。

= 选择协议

当今流行的点对点下载协议有两类：

- BitTorrent/Magnet
- eMule

前者是大名鼎鼎的“BT下载”和衍生出来的“磁力链”。后者则是“电骡”，在中文互联网上，“电驴”这个名字可能流传更广。至于“电驴”、“电骡”、VeryCD等等，背后又是一段冗长的历史，这里不再赘述。鉴于eMule相比前者已经式微，所以我们在这里选择BitTorrent/Magnet。

= 软件推荐

可以进行BitTorrent/Magnet下载（以下均简称BT下载）的软件有很多，随手就可以列出一些：

- #link("https://www.utorrent.com/")[µTorrent]
- #link("https://transmissionbt.com/")[Transmission]
- #link("https://deluge-torrent.org/")[Deluge]
- #link("https://www.qbittorrent.org/")[qBitTorrent]
- #link("https://www.bitcomet.com/en")[BitComet]
- #link("https://www.xunlei.com/")[XunLei]

其中最后一个：迅雷，是我们最大的敌人，因为他会从别处“#link("https://en.wikipedia.org/wiki/Glossary_of_BitTorrent_terms#Leech")[吸血]”。

BT的工作原理是“人人为我，我为人人”，也即，从别处下载之后，会上传给还没下载完成的其他用户。而“吸血”者会只下载，不上传，为大家所唾弃。

而qBitTorrent既是开源的，还有一个#link("https://github.com/c0re100/qBittorrent-Enhanced-Edition")[修改后的fork]。可以有效识别迅雷、QQ旋风等吸血客户端，还可以一键屏蔽未知的BT客户端（吸血者一般都会故意不填写自己的客户端名称和版本号）。

因此，这里就选择qBitTorrent的这个加强版来介绍。（#link("https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases")[Github上的最新下载地址]）

4.4.0.10版本的下载地址（可能不是最新）：

- #link("https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases/download/release-4.4.0.10/qbittorrent_enhanced_4.4.0.10_x64_setup.exe")[Windows(x64)]
- #link("https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases/download/release-4.4.0.10/qBittorrent-Enhanced-Edition.AppImage")[Linux(AppImage)]
- #link("https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases/download/release-4.4.0.10/qBittorrent_enhanced-4.4.0.10.dmg")[macOS]

而安装的话，没什么好说的，因为只需要点击下一步就可以了。

= 软件配置

配置菜单在这里打开：

#image("./images/0005.jpg", width: 80%)

首先开启屏蔽吸血客户端的高级功能：

#image("./images/0006.jpg", width: 80%)

然后是一些跟BT协议相关的配置，为了能够查找到更多用户，我们需要把能用的查找用户的功能打开：

#image("./images/0007.jpg", width: 80%)

最后需要添加一些tracker服务器。

我先稍微解释一下什么是tracker服务器。前面已经说了，BT下载的本质是“人人为我，我为人人”。而bt文件和磁力链其实是所要下载的文件的“指纹”，我们需要在“广场”上吼出这句指纹，好知道谁拥有这份文件，以互通有无。而tracker 服务器就是这样的“广场”。很多bt文件和磁力链接都会自带一个tracker服务器列表，但是这种东西终究是多多益善；而且，有些磁力链接没有没有附带 tracker服务器列表，这个时候我们只能通过DHT这样的点对点协议寻找拥有同款资源的道友，而这个过程如同在黑暗中一样慢慢摸索。

Github上#link("https://github.com/ngosang/trackerslist")[一个很好用的公共tracker服务器列表]。我们只需要把#link("https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt")[这个文件]里面的内容复制到我们的qBitTorrent配置里面就可以了：

#image("./images/0008.jpg", width: 80%)

= 如何下载

最知名的盗版资源站莫过于#link("https://thepiratebay.org/index.html")[海盗湾]。

以上个月的大烂片The Matrix Resurrections为例，检索之后很快就能得到结果，然后，右击磁铁标志复制，即可获得磁力链接。

#image("./images/0009.jpg", width: 80%)

接着，打开qBitTorrent，添加磁力链接：

#image("./images/0010.jpg", width: 80%)

#image("./images/0011.jpg", width: 80%)

最后选择要把文件保存在哪里，再点击OK，下载应该就会开始了。

#image("./images/0012.jpg", width: 80%)

当然，如果是冷门资源，有可能出现下载迟迟无法开始，或者速度很慢的情况，这时只能祈求上苍了。

另外还有一种邪道方式，很多国内网盘都提供磁力链离线下载功能，如果有人在国内网盘上传过这个文件而且还没有被审查的话，就可以直接用网盘下载了：

#image("./images/0013.jpg", width: 80%)

#image("./images/0014.jpg", width: 80%)

= 怎么寻找资源

除了前面说的海盗湾以外，#link("https://www.proxyrarbg.org/index80.php")[RARBG]也是不错的去处（2023年注：因为俄乌战争已经关站）。如果是动画或者ACG相关的资源，欧美字幕组会发在#link("https://nyaa.si")[nyaa.si]。而国内字幕组也出没在#link("https://share.dmhy.org/")[动漫花园]。

另外，谷歌其实也很有用。用中文电影名+“磁力链”作为关键字检索，就可以获得海量结果。一般，如果是英语网站，提供磁力链就会被版权方发DMCA，导致资源被谷歌移除。但是，中文资源就是法外之地了：

#image("./images/0015.jpg", width: 80%)

不过网络资源良莠不齐，还是注意鉴别为妙。

]
)