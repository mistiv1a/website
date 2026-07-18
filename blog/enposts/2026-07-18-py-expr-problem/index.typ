#import "/template.typ": *

#doc-template(
title: "The Expression Problem in Python:\nA Static Typing Approach",
date: "July 18, 2026",
parindent: 1.2em,
body: [

DISCLAIMER: I am not a Python expert, and this is just a note of what I found when exploring Python's type checker. There may be better solutions already but I don't know. And I'm not sure if someone has already written a post on similar approach, though I cannot find one.

= What is the Expression Problem

Let's start with the type definition of an expression AST. For simplicity, only addition and multiplication are included here. Python 3.14.6 and mypy 2.1.0 are used here.

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

We can write an `evaluate` operation for `Expr`:

```python
def evaluate(e: Expr) -> int:
    match e:
        case int(): return e
        case Add(l, r): return eval(l) + eval(r)
        case Mul(l, r): return eval(l) * eval(r)
        case _ as never: assert_never(never)
```

Imagine this code snippet being in an 3rd-party library and the user cannot modify it, yet the user want to extend it. What the user want would be:

- Without modifying existing code, add a new data type (e.g., adding a `Minus` besides `Add` and `Mul`);
- Without modifying existing code, add a new operation (e.g., adding a `pretty_print`);
- Keep type safety.

The definition on #link("https://en.wikipedia.org/wiki/Expression_problem")[Wikipedia] is similar:

#myquote[The goal is to define a data abstraction that is extensible both in its representations and its behaviors, where one can add new representations and new behaviors to the data abstraction, without recompiling existing code, and while retaining static type safety (e.g., no casts). ]

= Existed Solutions

Although achieving all three goals above is somewhat difficult, achieving any two of them is quite simple. 

In the example above, we've actually already achieved type safety and operation extensibility: just define a function that pattern-matches on `Expr`.

Using the traditional OOP approach — defining a base class and subtyping it — you can easily achieve type safety and data type extensibility. Other approaches similar to OOP include the visitor pattern and Python's newly introduced `Protocol`. However, none of them are good at achieving operation extensibility.

Python has also introduced `@singledispatch`. It's very similar to typeclasses in Haskell or `defgeneric` in Lisp. With `@singledispatch`, you can get extensibility in both data types and operations simultaneously. However, type safety is lost — the parameter type of a singledispatched function will be `Any`. You might forget to register the singledispatch function for a particular type, and then at runtime it falls back to the default implementation, crashing the program. And in a language like Haskell that has type constraints, recursive calls to an operation become a problem. This is why Haskell resorts to complex solutions like #link("https://webspace.science.uu.nl/~swier004/publications/2008-jfp.pdf")[_Data Types à la Carte_] to fix the Expression Problem.

= The Typed Python Approach

== Adding a Type Parameter

Let's start with the example of `Expr` from above. We first modify the definitions of the two AST nodes, turning them into generic types:

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

Then we define a new generic union type:

```python
type ExprBase[T] = int | Add[T] | Mul[T]
```

And define `Expr` to make it self-referential:

```python
type Expr = ExprBase[Expr]
```

You can see that the newly defined `Expr` here is essentially the same as the previous `Expr`. But the generic provides space for extensibility.

== Being Recursive

If we write `evaluate(expr: Expr) -> int` directly as before, then evaluate will be closed over `Expr`, losing room for extension. Therefore, we make the recursive operation a parameter:

```python
def evaluate_base[T](recur: Callable[[T], int], expr: T) -> int:
    match expr:
        case int():
            return expr
        case Add(lhs, rhs):
            return recur(lhs) + recur(rhs)
        case Mul(lhs, rhs):
            return recur(lhs) * recur(rhs)
        case _ as never:
            assert_never(never)

def evaluate(expr: Expr) -> int:
    return evaluate_base(evaluate, expr)
```

== Extending Data Types

Now we add a `Minus` node:

```python
@dataclass
class Minus[T]:
    lhs: T
    rhs: T
```

And the new `Expr` type will be:

```python
type Expr_v2= Minus[Expr_v2] | ExprBase[Expr_v2]
```

To evaluate `Minus`, we extend the `evaluate` function:

```python
def evaluate_v2(e: Expr_v2) -> int:
    match e:
        case Minus(lhs, rhs):
            return evaluate_v2(lhs) - evaluate_v2(rhs)
        case _:
            return evaluate_base(evaluate_v2, e)
```

Now the data types are extended with perfect type safety.

== Extending Operations

Extending operations on union types is trivial: just pattern matching on it, and you get type safety for free.

```python
def pretty_print(e: Expr2) -> None:
    match e:
        case int(): pass
        case Add(l, r): pass
        case Mul(l, r): pass
        case Minus(l, r): pass
        case _ as never: assert_never(never)
```

= Conclusion

Although I think this is a decent solution to the expression problem achiving all three goals, on the other hand it also adds quite a lot of boilerplate. At the same time, as I mentioned before, there may be better solutions already but I don't know, or this approach may have some flaw that I'm not aware of.

])