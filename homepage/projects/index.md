业余项目
=======

现在这个时代其实开源已经没有什么意义了，这里只是记录一下自己做过的东西：

## Haskell

[accessor-hs](https://raye.mistivia.com/releases/accessor-hs.zip): 一个类似lens的库，但是没有那么复杂，用了一些技巧把getter、setter串起来。可能它们的本质就是某种functor，但是我不擅长范畴论，无法看破其中的奥妙。

[flex-record](https://raye.mistivia.com/releases/flex-record.zip): 用了很多类型级编程技巧创建的在类型层可以获得字段名字和类型的record类型和sum type。有点类似[Vinyl](https://github.com/VinylRecords/Vinyl)。

[typed-rpc](https://raye.mistivia.com/releases/typed-rpc.zip): 基于上述两个库创建的强类型JSON API服务端框架，可以看成是穷人的servant。


## C/C++

[hive-mind-ygo](https://raye.mistivia.com/releases/hive-mind-ygo.zip): 游戏王轮抽工具。不过目前还没有找到足够的人一起玩游戏王轮抽，有兴趣的话欢迎联系我。

[ezlive](https://raye.mistivia.com/releases/ezlive.zip): 直播工具，可以接受OBS推流然后转成HLS流，上传到S3兼容的存储捅上。主要目的是利用免费的Cloudflare R1搭建地下直播间。

[lmp](https://raye.mistivia.com/releases/lmp.zip): 一个整活项目。用C++模板元编程实现了类似Lisp的功能（cons, car, cdr, reverse, 等等）。曾[一度登上Hacker News首页](https://news.ycombinator.com/item?id=47292029)。

[mvvmm](https://raye.mistivia.com/releases/mvvmm.zip): 我的得意作品，用1000多行C代码实现了完整的基于KVM的虚拟机管理器，实现了块设备和网络设备的VirtIO模拟，可以运行主流Linux发行版，并且性能不低。

## JavaScript

[ygo-deck-builder](https://raye.mistivia.com/releases/ygo-deck-builder.zip): 一个游戏王卡组编辑器，支持中文、英文、日文，OCG、简中文、TCG、Genesys等多种环境。[【传送门】](https://raye.mistivia.com/ygodeck/)。

## Python

[jitasm](https://raye.mistivia.com/releases/jitasm-py.zip): Python中的x86-64 JIT汇编器。

## 汇编

[asmrt](https://raye.mistivia.com/releases/asmrt.zip): 一个目前未完成的x86-64 Linux汇编运行时，主要用来练习汇编编程。愿景是封装libc常用功能，实现常用数据结构。
