#import "/template.typ": *

#doc-template(
title: "Writing Python with an OCaml Flavor",
date: "July 14, 2026",
parindent: 1.2em,
body: [


A few elements are essential if you want your code to resemble OCaml:

- Algebraic data types (most languages already have product types; the interesting aspect is sum types)
- Pattern matching
- Functor-based polymorphism

Here is a fragment taken from _Real World OCaml_ that demonstrates all three:

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

After several rounds of improvements, modern Python finally has everything it needs to imitate all three — to a certain degree. You can approximate the feeling of classical, 1990s-era OCaml, but do not expect advanced features such as GADTs or algebraic effects.

Here is the Python equivalent of the OCaml code above:

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

To summarize:

#box(width:80%)[
#figure(
  align(left)[
    #table(
      columns: 2,
      stroke: 0.5pt + luma(200),
      fill: (col, row) => if row == 0 { luma(240) } else { none },

      [*OCaml Ingredient*], [*Python Implementation*],
      [*ADT*], [Type annotations],
      [*Pattern Matching*], [Built-in `match-case` syntax],
      [*Functor*], [Generic `dataclass` + generic higher-order functions],
    )
  ]
)
]

I do not yet know how well this style performs at a larger scale, or what pitfalls are concealed within it. But on a small example such as this one, it is an enjoyable experiment.

])
