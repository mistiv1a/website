#import "/template.typ": *

#doc-template(
title: "Python中的表达式问题：\n一种静态类型解法",
date: "2026年7月18日",
body: [

声明：我并非Python专家，本文只是我在探索Python类型检查器时的一些记录。或许已经有更好的方案，只是我不知道罢了。我也不确定是否已经有人写过类似思路的文章，尽管我没能找到。

= 什么是表达式问题

先从一个表达式AST的类型定义开始。为了简单起见，这里只包含加法和乘法。本文使用Python 3.14.6和mypy 2.1.0。

```python
from dataclasses import dataclass
from typing import Callable, assert_never

@dataclass
class Add:
    lhs: Expr
    rhs: Expr

@dataclass
class Mul:
    lhs: Expr
    rhs: Expr

type Expr = int | Add | Mul
```

我们可以为`Expr`写一个`evaluate`操作：

```python
def evaluate(e: Expr) -> int:
    match e:
        case int(): return e
        case Add(l, r): return eval(l) + eval(r)
        case Mul(l, r): return eval(l) * eval(r)
        case _ as never: assert_never(never)
```

设想这段代码位于某个库中，用户无法修改它，却又想扩展它。用户想要的是：

- 在不修改现有代码的前提下，添加新的数据类型（例如，在`Add`和`Mul`之外再加一个`Minus`）；
- 在不修改现有代码的前提下，添加新的操作（例如，添加一个`pretty_print`）；
- 保持类型安全。

#link("https://en.wikipedia.org/wiki/Expression_problem")[维基百科]上的定义也与此类似：

#myquote[目标是定义一种数据抽象，使其在表示和行为两方面都可扩展：既能为该数据抽象添加新的表示，也能添加新的行为，同时无需重新编译现有代码，并且保持静态类型安全（例如，不使用类型转换）。]

= 已有的解决方案

虽然同时达成上述三个目标有些困难，但达成其中任意两个都相当简单。

在上面的例子中，我们其实已经实现了类型安全和操作可扩展性：只需定义一个对`Expr`进行模式匹配的函数即可。

使用传统的面向对象方法——定义一个基类并对其派生子类——可以轻松实现类型安全和数据类型的可扩展性。然而，它不擅长实现操作的可扩展性。你必须定义新的visitor来扩展新操作，而visitor没有穷尽性检查。#link("https://eli.thegreenplace.net/2016/the-expression-problem-and-its-solutions/")[这篇博客文章]用非常漂亮的图示说明了它们的缺陷。

Python还引入了`@singledispatch`。它与Haskell中的typeclass或Lisp中的`defgeneric`非常相似。借助`@singledispatch`，你可以同时获得数据类型和操作两方面的可扩展性。然而，类型安全丢失了——被singledispatch修饰的函数，其参数类型会变成`Any`，因此你完全可以用非法的数据类型作为参数去调用它。而在像Haskell这样带有类型约束的语言中，对操作的递归调用会成为一个问题，况且Haskell的数据类型是封闭的。这正是Haskell为解决表达式问题不得不诉诸诸如#link("https://webspace.science.uu.nl/~swier004/publications/2008-jfp.pdf")[_Data Types à la Carte_]这样复杂方案的原因。

= 带类型的Python方案

== 添加类型参数

让我们从上面`Expr`的例子开始。我们首先修改这两个AST节点的定义，把它们变成泛型类型：

```python
@dataclass
class Add[T]:
    lhs: T
    rhs: T

@dataclass
class Mul[T]:
    lhs: T
    rhs: T
```

然后我们定义一个新的泛型联合类型：

```python
type ExprBase[T] = int | Add[T] | Mul[T]
```

再定义`Expr`，使其自引用：

```python
type Expr = ExprBase[Expr]
```

可以看到，这里新定义的`Expr`本质上和之前的`Expr`是一样的。但泛型为可扩展性留出了空间。

== 让操作可递归

如果我们像之前那样直接写“`evaluate(expr: Expr) -> int`”，那么evaluate就会封闭在`Expr`之上，失去扩展的余地。因此，我们把递归调用的操作作为一个参数传入，并像上面的数据类型那样，把这个操作也变成泛型：

```python
def evaluate_base[T](recur: Callable[[T], int], expr: ExprBase[T]) -> int:
    match expr:
        case int():
            return expr
        case Add(lhs, rhs):
            return recur(lhs) + recur(rhs)
        case Mul(lhs, rhs):
            return recur(lhs) * recur(rhs)
        case _ as never:
            assert_never(never)
```

然后我们定义一个包装用的操作：

```python
def evaluate(expr: Expr) -> int:
    return evaluate_base(evaluate, expr)
```

== 扩展数据类型

现在我们添加一个`Minus`节点：

```python
@dataclass
class Minus[T]:
    lhs: T
    rhs: T
```

新的`Expr`类型将是：

```python
type Expr_v2= Minus[Expr_v2] | ExprBase[Expr_v2]
```

为了对`Minus`求值，我们扩展`evaluate`函数：

```python
def evaluate_v2(e: Expr_v2) -> int:
    match e:
        case Minus(lhs, rhs):
            return evaluate_v2(lhs) - evaluate_v2(rhs)
        case _:
            return evaluate_base(evaluate_v2, e)
```

现在数据类型得到了扩展，而且类型安全完好无缺。

== 扩展操作

如前所述，在联合类型上扩展操作是一个已经解决的问题：

```python
def pretty_print(e: Expr2) -> None:
    match e:
        case int(): pass
        case Add(l, r): pass
        case Mul(l, r): pass
        case Minus(l, r): pass
        case _ as never: assert_never(never)
```

= 结语

虽然我认为这是解决表达式问题的一个不错的方案，达成了全部三个目标，但另一方面，它也引入了相当多的样板代码。同时，正如我前面所说，或许已经有更好的方案只是我不知道，又或者这个方法存在某些我尚未意识到的缺陷。

])
