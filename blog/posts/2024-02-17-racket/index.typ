// 成功上手Racket
#import "/template.typ":*
#doc-template(
title: "成功上手Racket",
date: "2024年2月17日",
body: [

过年回家没事干用Racket做了几道#link("https://adventofcode.com/2023", "Advent of Code 2023")上面的题目。之前几次学Scheme系的语言都不太顺利，屡次受挫，不过这次倒是很顺利，写起代码突然感觉得心应手起来，卫生宏也会写了，可能是突然开窍了。

一开始是想用C语言来做这些题目的。但是果不其然，当题目逐渐复杂起来，用C来写这些东西开始有点掉san了；尤其是字符串处理，这是C语言最不擅长的部分。

和C相比，Racket就要轻松多了，至少不至于一个字符串转数字的函数都要翻阅半天的文档。但是同时，Racket，或者说Scheme，简洁程度也是可以媲美C的。就从标准文档的页数来说。ISO C大概是200页，而R5RS只有50多页，广受诟病“太复杂”的R6RS也只有100多页。Racket是一个“包括电池”的Scheme变体，功能也非常庞大，但是语言最核心的部分还是维持了Scheme的传统，非常精炼。我手边有一个只有半页纸的R5RS速查表，足够应付日常绝大多数功能需求。

“Python之禅”里面提到：

#myquote([
  Explicit is better than implicit. \
  Simple is better than complex.
])


然而很显然，如今的Python并没有做到这一点，反而是背道而驰。我从来没有搞懂过Python的Metaclass，OOP里面也有种种微妙的坑让我胆战心惊，再加上gradual typing、await/async等等新功能，如今我已经不太敢说我会写Python了。JavaScript也有类似的问题。至于C++就更不必提了。Racket诞生于学术界，也非常追求新功能新特性，但是语言的核心部分是稳定的。使用Racket的时候，可以说丰俭由人，既可以只使用近似于R5RS的最核心的那部分内容，也可以用庞大的标准库还有contract、Typed Racket等复杂的功能运筹帷幄。

我并非适应不了复杂的语法，甚至曾经对当C++的语言律师兴趣满满。奈何这些东西长时间不用就会逐渐遗忘，重新捡起来又要消耗很大的力气，好似西西弗斯。人生苦短，如今我更不愿意把本就宝贵的时间浪费再这些费解而无用的细节上面。

Racket的性能也是了得的，虽说自然是比不上C/C++、Rust之流，只大致和Java、NodeJS在一个梯队（而且很多时候稍慢），但是远强于Python、Ruby等一众脚本语言。这大概跟这几年的Racket on ChezScheme工作有关系。

最后一个优点大概是Racket很适合开发“冷血软件”。这个概念是#link("https://dubroy.com/blog/cold-blooded-software/", "这篇博客")里面提出的。这里的“冷血”并不是“冷血杀手”的冷血，而且“冷血动物”的冷血，大致是说可以冬眠，丢掉很多年后还是可以捡起来，不至于过了几年之后API和SDK翻天覆地，连开发环境都配不好了（这在Python、JavaScript这类语言中非常常见；C++乱七八糟的依赖和构建系统也会导致类似问题）。但是我有理由相信Racket不太可能出现类似现象（因为语言核心非常精炼）。记得我曾经下载过一个八十年代的Scheme解释器的代码，那个时候甚至还没有ISO C标准，但是这个代码稍作修改就可以在现代的Linux系统上顺利编译执行，给我留下了很深的印象。

最近成功上手Racket的感想大概就是这些了。最近有一些side project的想法，准备用Racket试试。

])
