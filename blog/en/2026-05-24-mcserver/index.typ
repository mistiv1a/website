// Setup a Minecraft Server
#import "/template.typ": *

#doc-template(
title: "Setup a Minecraft Server",
date: "May 24th, 2026",
body: [

Recently I deployed a Minecraft server. This time, I added many mods and didn't use existed modpack like ATM10, but select mods I want. So I record my experience here. Because of the widespread of LLM, I won't describe details here, but only high-level trade-off.

= Picking a Version

The reason I create a server this time is that I watched many videos about _Create: Aeronautics_, so I want to try it. This mod now only mainly support 1.21.1, and this version is compatible with many other mods, thus this is a natural choice.

= Choosing a Launcher

The most popular launcher recently is #link("https://prismlauncher.org/", "Prism Launcher"), which only supports legit game. But some of my friends are pirate players. They will need to change a launcher, for example, #link("https://prismlauncher.org/", "PolyMC"). These two are from the same upstream, both forked from link("https://multimc.org/", "MultiMC"). But their modpacks are not compatible. You will need to create two modpack separately.

至于制作整合包时，则Prism Launcher更为轻松，因其能自动解决模组依赖。因此即使决定使用PolyMC启动器，也推荐用Prism Launcher来安装模组，然后把模组的jar包统一复制到PolyMC的实例中。

不过要注意，这两个启动器都会从Mojang的网站上下载游戏，在国内网络环境下可能遇到下载缓慢乃至无法下载的问题。如果服务器玩家的上网技术不够高超的话，可能一些国内开发的MC启动器会更好，例如#link("https://hmcl.huangyuhui.net/", "HMCL")。

= 服务器选择

加了很多模组之后，服务器对内存和CPU的需求将会飙升。而今内存价格高企，大内存服务器涨价尤甚。此时如果采用VPS，花销将是每月约500到1000元，有点难以承受。所以我选用一台老旧的16GB内存的二手笔记本作为服务器；然后租用了一个每月仅15元的VPS服务器用作公网出口。这样服务器就很便宜了，一个月也就一两顿饭钱。

= 如何创建服务端整合包

客户端加入模组非常简单，只需要在启动器上操作即可。而服务端则稍微麻烦一些。今次选用的模组API是NeoForge，所以首先在#link("https://neoforged.net/", "NeoForge的网站")上下载安装包，然后运行，并选择安装服务端。然后，打开客户端的实例目录，找到其中的`mods/`目录，然后复制其中的所有jar文件到NeoForge的mods目录中即可。

建议在创建服务器前先开单人模式试玩一下各个功能是否正常，因为服务器一旦开起来如果发现不兼容之类的问题想要更新会非常麻烦，所有用户都要一起升级。

= 同时支持正版和盗版用户

为了支持盗版用户加入服务器，服务器设置为离线模式。但默认情况下，离线模式服务器中的用户，其皮肤与披风无法显示，因此需要加入模组#link("https://modrinth.com/mod/trueuuid", "TrueUUID")。另外，为防止假冒身份，需要加入登录功能，这里推荐使用#link("https://modrinth.com/mod/nedologin", "NedoLogin")。另外要注意，为了服务器的安全，最好启用白名单。

由于一些复杂的UUID问题，新用户加入服务器需要遵从这样的流程：

1. 在控制台关闭服务器白名单；
2. 等待玩家加入后，在控制台中把玩家加入白名单；
3. 在控制台重新打开服务器白名单。

= 模组选择

== 必备的工具模组

这里是我认为无论什么样的整合包都必须安装的模组。

- #link("https://modrinth.com/mod/xaeros-minimap", "Xaero's Minimap")和#link("https://modrinth.com/mod/xaeros-world-map/versions", "Xaero's World Map")：提供地图功能；
- #link("https://modrinth.com/mod/iris", "Iris Shaders")：提供光影；
- #link("https://modrinth.com/mod/jei", "JEI")：提供好用的合成表，模组多的时候是非常重要的指引；
- #link("https://modrinth.com/mod/jade", "Jade")：鼠标悬停在方块上时提供其信息。

== 改善体验的小模组

这里是一些可以改善体验的模组，不一定必装，但是绝对推荐。

- #link("https://modrinth.com/mod/waystones", "Waystones")：传送石；
- #link("https://modrinth.com/mod/natures-compass", "自然罗盘")：用于搜寻群系，找资源的时候很好用；
- #link("https://modrinth.com/mod/trashslot", "垃圾槽")；
- #link("https://modrinth.com/mod/jump-over-fences", "跳过栅栏")：人可以跳过栅栏，但是怪物和动物不可以；
- #link("https://modrinth.com/mod/travelers-titles", "Traveler's Titles")：来到新群系或者新位面的时候显示字幕，就像《艾尔登法环》里面的大字“宁 姆 格 福”；
- #link("https://modrinth.com/mod/sophisticated-backpacks", "精妙背包")；
- #link("https://modrinth.com/mod/distanthorizons", "遥远的地平线")：提供非常大的视野范围，加上光影之后，能够提供类似《塞尔达传说：旷野之息》的质感；
- #link("https://modrinth.com/mod/clientsort", "ClientSort")：整理背包和箱子；
- #link("https://modrinth.com/mod/yes-steve-model", "YSM")：提供更精细的玩家模型和动作,不过仅支持Windows和Linux，macOS玩家无法看到和使用。

== 大型模组

这里的模组是我此次建立服务器主要想玩的模组，列举出来以供参考。

- #link("https://modrinth.com/mod/create", "机械动力")
- #link("https://modrinth.com/mod/create-aeronautics", "机械动力：航空学")
- #link("https://modrinth.com/mod/ars-nouveau", "新生魔艺")
- #link("https://modrinth.com/mod/bosses-of-mass-destruction", "祸乱鬼魅")
- #link("https://modrinth.com/mod/l_enders-cataclysm", "灾变")
- #link("https://modrinth.com/mod/when-dungeons-arise", "当地牢浮现之时")
- #link("https://modrinth.com/mod/farmers-delight", "农夫乐事")
- #link("https://modrinth.com/mod/touhou-little-maid", "东方女仆")
- #link("https://www.curseforge.com/minecraft/mc-mods/minecolonies", "MineColonies")
- #link("https://www.curseforge.com/minecraft/mc-mods/the-twilight-forest", "暮色森林")

= 服务端安装YSM模型

YSM模型可以去哔哩哔哩上看看，很多人提供整合包或者下载。然后放到服务器中的`config/yes_steve_model/custom`目录即可供服务器上所有玩家使用。

= 广告

最后打个广告，如果想要加入服务器一起玩的话，欢迎联系我。

])
