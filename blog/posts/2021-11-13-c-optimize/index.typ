#import "/template.typ":*

#doc-template(
title: "一些C/C++优化工具",
date: "2021年11月13日",
body: [

= 性能数据收集

== perf

Linux下收集性能数据通常用perf。关于perf的使用可以参考#link("https://www.brendangregg.com/perf.html")[Brendan Gregg的网站]。

其中最常用的命令是perf record和perf report，而常用的指标有cycles、branch miss、cache miss等。

然后用#link("https://github.com/brendangregg/FlameGraph")[FlameGraph工具]可以生成火焰图，直观显示性能消耗在何处。

== perf的原理

收集cycles、branch miss、cache miss这些数据，主要应用到了CPU当中的 Performance Monitoring Unit（简称PMU）。PMU其实就是CPU当中的一个计数器，当发生特定事件的时候加一，并可以向内核报告寄存器状态，尤其是Program Counter寄存器的状态，这样就可以知道branch miss、cache miss发生在何处。

因为会带来性能损耗，所以使用PMU的时候一般采用采样模式。例如，每发生一万次cache miss才会报告一次。

此外，Intel的CPU还有一项功能，叫Least Recent Branch（简称LRB），可以记录控制流，也被perf用于发现程序中的热点。

关于PMU和LRB的原理，参见：

- #link("http://rts.lab.asu.edu/web_438/project_final/Talk%209%20Performance%20Monitoring%20Unit.pdf")[Performance Monitoring Unit]
- #link("https://easyperf.net/blog/2018/06/01/PMU-counters-and-profiling-basics")[PMU counters and profiling basics. | Easyperf - Denis Bakhvalov]
- #link("https://lwn.net/Articles/680985/")[An introduction to last branch records]

= 手工优化

关于怎么优化程序，有一些放之四海而皆准的老生常谈，比如如何优化系统调用、如何用锁等等、使用-O3编译选项等等。不过，也有一些更精妙的东西。

其一是likely/unlikely宏，而这些宏依赖了GCC中的`__builtin_expect`函数。如下：

```cpp
#define likely(x)       __builtin_expect((x),1)
#define unlikely(x)     __builtin_expect((x),0)
```

这个宏可以告诉编译器在分支处更容易跳转到哪里。编译器根据这些提示，可以做出相应优化，防止发生太长的跳转，进而提高分支预测的成功率，并减少程序加载时出现page fault的可能性。

从C++20开始，likely和unlikely以attribute的形式进入了C++标准。使用方法如下：

```cpp
double pow(double x, long long n) {
    if (n > 0) [[likely]]
        return x * pow(x, n - 1);
    else [[unlikely]]
        return 1;
}
```

此外，也有一些builtin功能可以提示编译器对缓存做更精确的控制，例如`__builtin_prefetch`。

参见：

- #link("https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html")[Other Builtins (Using the GNU Compiler Collection (GCC))]
- #link("https://en.cppreference.com/w/cpp/language/attributes/likely")[C++ attribute: likely, unlikely (since C++20)]

= 自动优化

上面的手工优化，实际操作起来往往很繁琐，所以只能在少量热点处使用。如果要对程序进行大量优化，免不了要使用自动化工具。

== LTO

LTO全称是Link-Time Optimization，即“链接期优化”。LTO可以对程序进行全局优化，而不仅仅着眼于局部，故可以执行一些更激进的优化策略。但是缺点是优化方法比较复杂，且内存消耗大；针对这些缺点又有了Thin LTO。LTO使用起来也很简单，利用clang编译，然后在编译和链接时加上-flto和-flto=thin即可。

参见：

- #link("https://llvm.org/docs/LinkTimeOptimization.html")[LLVM Link Time Optimization: Design and Implementation]
- #link("http://blog.llvm.org/2016/06/thinlto-scalable-and-incremental-lto.html")[ThinLTO: Scalable and Incremental LTO]

== PGO

PGO，全名Profile-Guided Optimazation，即通过编译的时候，构建一个运行模型，通过Profile数据来指导编译器优化。目前GCC已经提供了该功能。但是缺点是这个过程通常非常耗时，而且不好收集数据集，构建模型也很复杂。针对此，谷歌做了一些PGO自动化相关的工作，开源了AutoFDO，全名Automatic Feedback-Directed Optimization，通过采集生产机器上的数据来做反馈优化。不过，谷歌的AutoFDO虽然开源了，但是Github上似乎并没有详细的使用说明，只能够找到一些零散的资料。

参见：

- #link("https://rigtorp.se/notes/pgo/")[Profile-guided optimization]
- #link("https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html")[GCC: Options That Control Optimization]
- #link("https://github.com/google/autofdo")[google/autofdo]
- #link("https://research.google/pubs/pub45290/")[AutoFDO: Automatic Feedback-Directed Optimization for Warehouse-Scale Applications]
- #link("https://clang.llvm.org/docs/UsersManual.html#using-sampling-profilers")[LLVM Docs: Using Sampling Profilers]
- #link("https://gcc.gnu.org/wiki/AutoFDO/Tutorial")[GCC Wiki: AutoFDO Tutorial]
- #link("https://stackoverflow.com/questions/4365980/how-to-use-profile-guided-optimizations-in-g")[How to use profile guided optimizations in g++?]

== BOLT

BOLT由Facebook开发（现在改名meta了），也是一种反馈优化，全名是Binary Optimization and Layout Tool。根据Facebook的数据，BOLT给他们的Hack语言（一种php类似物）虚拟机#link("https://hhvm.com/")[HHVM]带来了8%的性能提升。

参见：

- #link("https://github.com/facebookincubator/BOLT")[facebookincubator/BOLT - GitHub]
- #link("https://engineering.fb.com/2018/06/19/data-infrastructure/accelerate-large-scale-applications-with-bolt/")[Accelerate large-scale applications with BOLT]

正如其名，BOLT在优化时不需要源代码，可以直接操作二进制。由重排代码、优化控制流，而提高指令缓存的效率。如果程序依赖了一些没有源代码的二进制库，那么BOLT在这种场景下就有很大优势。

])