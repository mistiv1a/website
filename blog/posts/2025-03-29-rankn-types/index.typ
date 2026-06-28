// Rank-N类型的简单例子
#import "/template.typ": *

#doc-template(
title: "Rank-N类型的简单例子",
date: "2025年3月29日",
body: [

考虑一段简单的代码：

```hs
highOrderFunc :: (Num b) => ([a] -> b) -> b
highOrderFunc f = f [1,2,3] + f ["a", "b", "c"]

main = do print $ highOrderFunc length
```

这里是无法通过编译的。

`highOrderFunc`的类型完整写出来实际上是：

```hs
highOrderFunc :: forall a b. (Num b) => ([a] -> b) -> b
```

对于一个`highOrderFunc`函数的实例，`a`只能是一个确定的类型，比如`String`，或者`Int`。

```hs
highOrderFunc f = f [1,2,3] + f ["a", "b", "c"]
```

但是这里要求a又可以是Int又可以是String。

所以使用Rank-2类型：

```hs
highOrderFunc :: forall b. (Num b) => (forall a. [a] -> b) -> b
```

此时对于一个`highOrderFunc`实例，`f`是一个泛型函数，`a`不再有只能确定为一个类型的限制。


])