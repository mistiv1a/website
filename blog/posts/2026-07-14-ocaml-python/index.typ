#import "/template.typ": *

#doc-template(
title: "如何把Python写出OCaml风味",
date: "2026年7月14日",
body: [


要想代码有 OCaml 风味，以下要素必不可少：

- ADT (product type 正常编程语言都有，主要是 sum type)
- Pattern Matching
- 基于 Functor 的多态

这是一段从 _Real World Ocaml_ 中摘下来的代码，上面几个要素都有所体现：

```ocaml
module type Comparable = sig
  type t
  val compare : t -> t -> int
end;;

module Make_interval(Endpoint : Comparable) = struct
  type t = | Interval of Endpoint.t * Endpoint.t
           | Empty
  let create low high =
    if Endpoint.compare low high > 0 then Empty
    else Interval (low,high)
  let contains t x =
    match t with
    | Empty -> false
    | Interval (l,h) ->
      Endpoint.compare x l >= 0 && Endpoint.compare x h <= 0
end;;

module Int_comparable = struct
    type t = int
    let compare = Int.compare
end

module Int_interval =
  Make_interval(Int_comparable);;

let i1 = Int_interval.create 3 8;;
let c = Int_interval.contains i1 5;;
```

现代 Python 几经迭代，现在该有的特性也都有了，于是写出 OCaml 感也就成为可能。不过也就能接近九十年代古典 OCaml 的效果，GADTs 和 algebraic effects 什么的还是别想了。

下面是上述 OCaml 代码的 Python 对应：

```python
from typing import Callable
from dataclasses import dataclass

@dataclass
class Comparable[T]:
    compare: Callable[[T, T], int]

@dataclass
class Empty:
    pass

@dataclass
class Interval[T]:
    low: T
    high: T

type IntervalType[T] = Interval[T] | Empty

@dataclass
class IntervalModule[T]:
    create: Callable[[T, T], IntervalType[T]]
    contains: Callable[[IntervalType[T], T], bool]

def Make_interval[T](Endpoint: Comparable[T]) -> IntervalModule[T]:
    def create(low: T, high: T) -> IntervalType[T]:
        if Endpoint.compare(low, high) > 0:
            return Empty()
        return Interval(low, high)
    def contains(t: IntervalType[T], x: T) -> bool:
        match t:
            case Empty():
                return False
            case Interval(l, h):
                return Endpoint.compare(x, l) >= 0 and Endpoint.compare(x, h) <= 0
    return IntervalModule(create=create, contains=contains)

def int_compare(a: int, b: int) -> int:
    return (a > b) - (a < b)

Int_comparable = Comparable(int_compare)

Int_interval = Make_interval(Int_comparable)

i1 = Int_interval.create(3, 8)
c = Int_interval.contains(i1, 5)
```

小结一下：

#box(width:80%)[
#figure(
  align(left)[
    #table(
      columns: 2,
      stroke: 0.5pt + luma(200),
      fill: (col, row) => if row == 0 { luma(240) } else { none },
      
      [*OCaml 要素*], [*Python 中的实现方式*],
      [*ADT*], [`type annotation`（类型注解）],
      [*Pattern Matching*], [内置语法支持（`match-case`） + `dataclass`],
      [*Functor*], [泛型 `dataclass` + 泛型高阶函数 模拟],
    )
  ]
)
]

目前还不知道这种风格大规模写起来是什么效果，有没有什么隐藏的陷阱，不过就目前这个小例子看起来很有趣。

])