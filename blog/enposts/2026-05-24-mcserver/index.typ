// Setup a Minecraft Server
#import "/template.typ": *

#doc-template(
title: "Setup a Minecraft Server",
date: "May 24th, 2026",
body: [

Recently I deployed a Minecraft server. This time, I added many mods and didn't use existed modpack like ATM10, but select mods I want. So I record my experience here. Because of the widespread of LLM, I won't describe details here, but only high-level trade-off.

= Picking a Version

The reason I create a server this time is that I watched many videos about _Create: Aeronautics_, so I want to try it. This mod now supports 1.21.1. And this version (1.21.1) is compatible with many other mods, thus this is a natural choice.

= Choosing a Launcher

The most popular launcher recently is #link("https://prismlauncher.org/", "Prism Launcher"), which only supports legit game. But some of my friends are pirate players. They will need to use another launcher, for example, #link("https://prismlauncher.org/", "PolyMC"). These two are from the same upstream, both forked from link("https://multimc.org/", "MultiMC"). But their modpacks are not compatible. You will need to create two modpacks separately.

As for making modpacks, using Prism Launcher is easier, for its ability to automatically resolve mod dependencies. Therefore, even if you are going to use PolyMC, I still recommend you to use Prism Launcher to make the modpack, and copy all jars to PolyMC instance.

= Choosing a Host

The demand for memory and CPU of a Minecraft will surge after added many mods. Now memory price is very high, and the prices of servers with large memory are increasing sharply. If you use a VPS, the cost will be \$50-\$100 a month, which is hard to accept. So I decided to use an old laptop with 16GB memory as the host; and then rent a VPS server with 2.5 dollars a month as reverse proxy to public Internet (my broadband at home is behind NAT). So that the cost is very low.

= Adding Mods to the Server

It's easy to add mods to clients, the launcher will do the job for you. But things are a bit more complicated on server. To play with _Aeronautics_, I choosed NeoForge as mod API. Firstly, I downloaded the installer on #link("https://neoforged.net/", "NeoForge's website"). After running the installer and installing the server, copy all jar files from `mods/` in client instance to `mods` directory of NeoForge server isntance

Before creating the server, it's recommended to test the modpack in single player mode. Once the server were cerated, it would be a huge hussle to upgrade: every player need to upgrade their client.

= Online and Offline Modes at the Same Time

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
