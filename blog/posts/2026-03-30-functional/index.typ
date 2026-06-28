// 给欧拉-拉格朗日方程加上类型注释
#import "/template.typ": *

#doc-template(
title: "给欧拉-拉格朗日方程\n加上类型注释",
date: "2026年3月30日",
body: [

Functional programming通常被称为“函数式编程”。“functional”这个词，因为“_-al_”后缀的关系，一般被视为形容词；但是它实际上也可以作为名词使用，意思是“高阶函数”，也就是把另一个函数作为输入参数的函数，例如著名的“map/reduce”。这里随便举个JavaScript的例子：

```js
var add1 = function (x) { return x + 1; };
[1,2,3].map(add1);
```

但是在数学中，“functional”这个词通常翻译成“泛函”。基于“泛函”而产生的变分法，正是物理学中分析力学的基础。_Structure and Interpretation of Classical Mechanics_这个书正是一个把这两者结合起来的一个尝试。这本书是_SICP_的姊妹篇，用Scheme语言讲授分析力学。我前年就在尝试读这本书，但是看了半天，数学公式搞不明白，Lisp数括号数来数去也数不明白，英语读起来也很头痛，然后就弃坑了。

去年学会了Haskell，最近就又拿起来翻翻。这次不折磨自己硬啃英文了，开始大规模使用LLM翻译器，然后把书里面的代码尝试改写成Haskell，加上类型注解。然后很神奇的事情发生了，我发现有了类型之后里面的代码读起来一下子就全通畅了，数学公式也一下子都能看懂了，所以就来写写自己的心得。

= 实数和函数

微积分里面主要是和实数打交道。虽然浮点数并不是实数，但是这里我们并不追求严谨，只是借用一下Haskell的类型系统作为思考的草稿纸，所以这里就用浮点数代替了。

```hs
pi :: Float
e :: Float
```

而函数，就是输入一个或多个实数，返回一个或多个实数。例如一个单变量标量函数就像这样：

```hs
f :: Float -> Float
```

像什么 $sin$、$cos$、$ln$ 都是这样：

```hs
sin :: Float -> Float
cos :: Float -> Float
ln :: Float -> Float
```

= 导数和积分

这里我们假设读者至少具有高中程度的微积分知识。

在数学上，导数的符号是非常混乱的。有的人选择加点（比如牛顿）：

$ dot(f) (x) $

有的人选择用微分符号：

$ (upright(d) f) / (upright(d) x) (x) $

有的人用单引号：

$ f'(x) $

或者一个单独的大写字母D：

$  upright(D) f (x) $

但是这些符号本质上都是表达这么一个概念：我们有一个函数，经过某种变换之后，这个函数变成了另一个函数，而这个函数就是原来的函数的“导数”。而这个变换所做的工作，就是输入一个函数，返回一个函数：

```hs
derive :: (Float -> Float) -> (Float -> Float)
```

Haskell中的`->`是右结合的，所以我们可以去掉后面的括号，变成这样：

```hs
derive :: (Float -> Float) -> Float -> Float
```

这里的`derive`显然就是一个高阶函数。不过在数学上，这种输入一个函数、返回一个函数的高阶函数，通常不被称为泛函，而是称为“算子（Operator）”。

比如说对于函数`f :: Float -> Float`，`derive f`的类型也是一个函数：`Float -> Float`。然后我们加上自变量，`derive f x0`也就是这个函数`f`在`x0`这个点上的导数的值，所以其类型也就是`Float`。数学上记作：

$ (upright(d) f)/(upright(d) x) (x_0) $

这里我们并没有在开发一个完整的符号计算系统，所以我们先假设我们有这么一个高阶函数可以直接用，并不会给出其完整定义。所以我们只给出其类型，实现直接写成`undefined`就好。

```hs
derive f = undefined
```

积分就多了，在数学中基本就只有一种表示法。对于被积函数 $f$ 以及积分上限 $b$ 和下限 $a$,定积分就是：

$ integral_a^b f(x) d x $

在代码中，对应为如下高阶函数：

```hs
integral :: (Float -> Float) -> Float -> Float -> Float
integral f a b = undefined
```

= 作用量

我们打开欧拉-拉格朗日方程的#link("https://en.wikipedia.org/wiki/Euler%E2%80%93Lagrange_equation", "维基百科页面")。

里面定义了一个叫做“作用量泛函”的东西，它的输入是一条随时间演化的轨迹函数 $q(t)$，并对其拉格朗日量在时间区间 $[t_"start", t_"end"]$ 上计算积分：

$ S[q] = integral_(t_"start")^(t_"end") L(t, q(t), dot(q)(t)) d t $

如果正在读这篇文章的你像我一样高等数学苦手的话，这个时候可能已经被吓哭了。但是这实际上并没有多难，只是迷失在了符号里，所以很吓人罢了。让我们来逐步拆解一下。

公式中的 $L$，被称为拉格朗日量。这里我们简化一下，假设是一维的情况，$q(t)$ 是一个标量，那么 $L$ 就是一个三元函数：

```hs
lagrangian :: Float -> Float -> Float -> Float
lagrangian = undefined
```

以此类推，假如广义坐标有两个，那么拉格朗日量就是一个五元函数；假如广义坐标有三个，那么拉格朗日量就是一个七元函数。不过这里我们只看最简单的情况。

然后我们用上面定义的微分高阶函数、积分高阶函数来重写一下这个公式：

```hs
s q = integral
  (\t -> lagrangian t (q t) (derive q t)) t_start t_end
```

注意看里面的这个lambda表达式，这里正是数学公式里面最让人迷惑的地方。公式里面看起来我们是在对拉格朗日量这个函数在做积分，但是实际上根本不是这么一回事，公式里面实际上是利用了拉格朗日量这个三元函数 $L$、轨迹函数 $q$，以及导数算子 $upright(D)$，定义了一个新的一元函数，然后再对这个新定义的一元函数求积分。而在代码里面，公式中的这个容易引起歧义的地方已经无处遁形了，不会引起理解上的困扰。

而公式中的`t_start`和`t_end`都是一个常数，我们并不关心其具体的值，只要知道它存在就好：

```hs
t_start :: Float
t_start = undefined

t_end :: Float
t_end = undefined
```

这个时候，如果你安装了Haskell的LSP server的话，LSP server会自动帮你推导出`s`的类型:

```hs
s :: (Float -> Float) -> Float
```

可以看到 $S$ 的类型实际上非常简单：输入一个函数，返回一个实数。这正是数学上“泛函”的定义，这里的 $S$ 被称为“作用量泛函”。

如果你经常玩一些高阶函数编程，map、reduce、filter绕来绕去的话，相比于前面那个数学公式来说，这里的`s`的定义要清晰太多了。如果你不熟悉Haskell的话，用JavaScript表达也是类似的效果（你可以尝试用TypeScript给下面的代码加上类型注解）：

```js
function s(q) {
  return integral(
    function(t) {
      return lagrangian(t, q(t), derive(q)(t));
    },
    start,
    end
  );
}
```

= 偏导数

在继续探索欧拉-拉格朗日方程之前，我们先回忆一下什么是偏导数。

对于多元函数 $f(x, y, z)$ 来说，它在某一个点 $(x_0, y_0, z_0)$ 上的对于变量 $x$ 的偏导，就是先把其它两个变量 $y_0, z_0$ 固定住，假设它们是常量，这样变成一个一元函数，随后对这个一元函数求导，最后得到这个一元函数的导数在 $x_0$ 处的取值。用Haskell写出来就是这样：

```hs
px f x0 y0 z0 = derive (\x -> f x y0 z0) x0
```

类似的，我们可以得到对 $y$ 和 $z$ 的偏导：

```hs
py f x0 y0 z0 = derive (\y -> f x0 y z0) y0
pz f x0 y0 z0 = derive (\z -> f x0 y0 z) z0
```

此处 `px`、`py`、`pz` 分别对应函数 $f(x, y, z)$ 的偏导算子 $(partial) / (partial x), (partial) / (partial y), (partial) / (partial z)$。三者的类型签名如下：

```hs
px, py, pz :: (Float -> Float -> Float -> Float) -> Float -> Float -> Float -> Float
```

也就是说，偏导数实际上就是一个输入一个多元函数、返回一个多元函数的“算子”。

= 欧拉-拉格朗日方程

欧拉-拉格朗日方程的数学表述是这样的，如果作用量泛函 $S$ 在驻点上，那么等价于函数 $q(t)$ 满足：

$ (partial L) / (partial q) (t, q(t), dot(q)(t)) = d / (d t) ( (partial L) / (partial dot(q)) (t, q(t), dot(q)(t))) $

而所谓驻点，也就是极大点、极小点、或者鞍点。其中极小比较常用，所这也常被称为最小作用量原理（但是这种说法并不严谨）。

这里又是一个非常吓人的公式，乍看上去即使理解也很困难。我们接着像刚才一下改写成Haskell代码，加上类型。

首先我们定义 $q(t)$ 这个函数：

```hs
q :: Float -> Float
q t = undefined
```

然后我们看公式的左边，首先是对拉格朗日量的第二项求偏导：

```hs
lhsFirstStep = py lagrangian
```

得到一个三元函数：`Float -> Float -> Float -> Float`。然后这个函数的三个参数是：`t (q t) (derive q t)`。里面唯一的没有定义的自由变量就是`t`。所以这是一个只有一个自变量`t`的函数。由此我们写出公式的左手边的定义：

```hs
lhs :: Float -> Float
lhs t = py lagrangian t (q t) (derive q t)
```

右边则是先对L的第三个变量求偏导，得到一个三元函数，其三个参数也还是`t (q t) (derive q t)`。同样得到一个一元函数，里面唯一的没有定义的自由变量就是`t`；最后再对这个一元函数求一次导数，就得到了公式的右手边的定义：

```hs
rhs = derive (\t -> pz lagrangian t (q t) (derive q t))
```

这里可以让Haskell帮我们自动推导一下类型：

```hs
rhs :: Float -> Float
```

可以看到`lhs`和`rhs`的类型是一样的，都是一个一元函数。而欧拉-拉格朗日方程的含义就是，如果作用量泛函 $S$ 在驻点上，那么等价于，$t$ 在从 $t_"start"$ 到 $t_"end"$ 的区间内，有：

```hs
lhs t == rhs t
```

= 从拉格朗日回到牛顿

这里我们依然简化一下，只讨论一维保守场中质量为 $m$ 的单个质点，假设系统势能 $V(q)$ （Haskell中我们将其记作 `potential q`）仅依赖位置。那么拉格朗日量定义如下：

```hs
lagrangian t q v = 0.5 * m * v * v - potential q
```

对于这个拉格朗日量，我们用微积分法则针对位置（参数 `q`）与速度（参数 `v`）求偏导；也就是对第二个自变量和第三个自变量求偏导：

```hs
py_lagrangian = \t q v -> - derive potential q
pz_lagrangian = \t q v -> m * v
```

根据欧拉-拉格朗日方程，如果作用量泛函 $S[q] = integral_(t_"start")^(t_"end") L(t, q(t), dot(q)(t)) d t$ 在驻点上，那么必然有：`lhs t == rhs t`。我们代入上一节的公式：

```hs
lhs t = - derive potential (q t)
rhs t = derive (\t -> m * (derive q t)) t
```

根据微积分法则， 我们可以把`-m`提出来，所以`rhs`实际上可以写成：

```hs
rhs t = m * derive (derive q) t
```

这个表达式也可以写成：

```hs
rhs t = m * (derive . derive) q t
```

而在动力学中，将物体的位置对时间求两次导数正是其加速度：

$ a(t) = (upright(d)^2 q) / (upright(d) t^2) (t) $

而在一维保守场中，势能场的梯度变成了势能对位置的导数，而这个导数正是物体在这个场中的受力：

$ F(t) = - (upright(d) V) / (upright(d) q)(q(t)) $

所以我们得到：

```hs
force t = - derive potential (q t)
a t = (derive . derive) q t
```

由欧拉-拉格朗日方程的要求 `lhs t == rhs t`，代入化简结果后得到：

```hs
force t == m * (a t)
```

也就是说，物体任意时刻受到的力等于其加速度乘以质量。我们用数学公式来表述：

$ F(t) = m a(t) $

于是，我们回到了牛顿第二定律。

欧拉-拉格朗日方程成立，是作用量在驻点上的充分必要条件。所以，从牛顿第二定律出发，我们也可以反推得到这个作用量在驻点上。

这里我们从一个拉格朗日量出发，得到了牛顿第二定律。而欧拉和拉格朗日当年所做的工作则是反过来的，他们想办法构造出了一个合适的三元函数作为拉格朗日量，使得作用量泛函的驻点可以通过欧拉-拉格朗日方程完美对应牛顿定律。

= 小结

本文中为了简化讨论，都尽量采用一维标量、单变量函数。但是实际上，矢量、多变量微积分中的公式也可以像这样用类型系统来表达。如果有兴趣的话，可以尝试给散度、梯度、旋度、拉普拉斯算子等等，也都加上类型注解。另外，欧拉-拉格朗日公式的证明推导过程（我指的是18世纪的那种不怎么严谨的证明）也很有意思，可以试试给分部积分，还有证明过程中得到的式子加上类型注解看看，会很有趣。

虽然这种表示方法并不十分严谨，但是却可以给公式起到很好的注释作用，是一个很好的辅助理解、辅助思考的工具，让我这种脑子不太够用的人也能大致理解很复杂的数学公式的含义，对于工科数学来说已经够用了。如果你当年学习微积分的时候也跟我一样雾里看花的话，不妨一试，或许可以打开新世界的大门。

])