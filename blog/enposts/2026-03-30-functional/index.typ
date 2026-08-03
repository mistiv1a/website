#import "/template.typ": *

#doc-template(
title: "Adding Type Annotations to the\nEuler-Lagrange Equation",
date: "March 30, 2026",
parindent: 1.2em,
body: [

In English, the word _functional_ is generally regarded as an adjective, as in _functional programming_. It can, however, also serve as a noun, denoting a higher-order function — a function that accepts another function as its input, such as the famous `map` and `reduce`. Here is a simple JavaScript example:

```js
var add1 = function (x) { return x + 1; };
[1,2,3].map(add1);
```

In mathematics, however, the term _functional_ denotes something different: a mapping from functions to numbers. The calculus of variations, which rests on this concept, is the foundation of analytical mechanics in physics. _Structure and Interpretation of Classical Mechanics_ is an attempt to bring the two together: it is the companion volume to _SICP_ and teaches analytical mechanics in Scheme. I first attempted to read this book two years ago, but after considerable effort the mathematical formulas still defeated me, I kept losing my place among the Lisp parentheses, and the English prose was laborious to read; in the end I abandoned it.

Last year I learned Haskell, and recently I returned to the book. This time I did not force myself through the original English; instead I made extensive use of LLM-based translation, and I attempted to rewrite the book's code in Haskell, adding type annotations. Then something remarkable happened: with types in place, the code suddenly became entirely transparent, and the mathematical formulas became intelligible at once. Hence this post records what I learned.

= Real Numbers and Functions

Calculus deals mainly with real numbers. Although floating-point numbers are not real numbers, we do not pursue rigor here; we merely borrow Haskell's type system as a scratchpad for thought, so floating-point numbers are used as a stand-in.

```hs
pi :: Float
e :: Float
```

A function takes one or more real numbers as input and returns one or more real numbers. For example, a single-variable scalar function looks like this:

```hs
f :: Float -> Float
```

Functions such as $sin$, $cos$, and $ln$ all have this form:

```hs
sin :: Float -> Float
cos :: Float -> Float
ln :: Float -> Float
```

= Derivatives and Integrals

We assume the reader has at least a high-school level of calculus.

The notation for derivatives in mathematics is notoriously messy. Some prefer a dot above, as in Newton's notation:

$ dot(f) (x) $

Some use differential notation:

$ (upright(d) f) / (upright(d) x) (x) $

Some use a prime:

$ f'(x) $

or a single uppercase letter $D$:

$ upright(D) f (x) $

Yet all these notations express essentially the same concept: we have a function, and under some transformation this function becomes another function, namely the derivative of the original one. The transformation itself takes a function as input and returns a function as output:

```hs
derive :: (Float -> Float) -> (Float -> Float)
```

In Haskell the arrow `->` is right-associative, so we can drop the trailing parentheses:

```hs
derive :: (Float -> Float) -> Float -> Float
```

Here `derive` is evidently a higher-order function. In mathematics, however, such higher-order functions that take a function and return a function are usually called operators, not functionals.

For example, given a function `f :: Float -> Float`, the type of `derive f` is also a function: `Float -> Float`. If we then supply the independent variable, `derive f x0` is the value of the derivative of `f` at the point `x0`, so its type is `Float`. In mathematics this is written as:

$ (upright(d) f)/(upright(d) x) (x_0) $

We are not building a complete computer algebra system here, so let us merely assume that such a higher-order function is available, without giving its full definition. We provide only its type and leave the implementation as `undefined`.

```hs
derive f = undefined
```

Integration, by contrast, fares much better: in mathematics there is essentially only one notation. For an integrand $f$ with upper limit $b$ and lower limit $a$, the definite integral is:

$ integral_a^b f(x) d x $

In code, this corresponds to the following higher-order function:

```hs
integral :: (Float -> Float) -> Float -> Float -> Float
integral f a b = undefined
```

= The Action

Let us open the #link("https://en.wikipedia.org/wiki/Euler%E2%80%93Lagrange_equation", "Wikipedia page") for the Euler–Lagrange equation.

It defines something called the action functional. Its input is a trajectory function $q(t)$ that evolves over time, and it computes the integral of the Lagrangian over the time interval $[t_"start", t_"end"]$:

$ S[q] = integral_(t_"start")^(t_"end") L(t, q(t), dot(q)(t)) d t $

If you, like me, are not at ease with advanced mathematics, you may have been frightened now. But in fact there is nothing very difficult here; it only seems hard when one is lost among the symbols. Let us try to explain it step by step.

The $L$ in the formula is called the Lagrangian. To simplify, let us consider the one-dimensional case, where $q(t)$ is a scalar; then $L$ is a function of three variables:

```hs
lagrangian :: Float -> Float -> Float -> Float
lagrangian = undefined
```

Similarly, if there were two generalized coordinates, the Lagrangian would be a function of five variables; with three, a function of seven. Here, however, we consider only the simplest case.

Now we rewrite the formula using the higher-order differentiation and integration functions defined above:

```hs
s q = integral
  (\t -> lagrangian t (q t) (derive q t)) t_start t_end
```

Look closely at the lambda expression inside: this is precisely the most confusing part of the mathematical formula. It appears that we are integrating the Lagrangian function itself, but that is not what is happening at all. In reality, the formula uses the three-variable function $L$, the trajectory function $q$, and the derivative operator $upright(D)$ to define a new one-variable function, and then integrates this newly defined function. In code, this ambiguous spot in the formula has nowhere to hide, so it no longer causes confusion.

The `t_start` and `t_end` in the formula are constants. We do not care about their values; it is enough to know that they exist:

```hs
t_start :: Float
t_start = undefined

t_end :: Float
t_end = undefined
```

At this point, if you have installed a Haskell LSP server, it will infer the type of `s` for you automatically:

```hs
s :: (Float -> Float) -> Float
```

As you can see, the type of $S$ is in fact very simple: it takes a function and returns a real number. This is precisely the mathematical definition of a functional, and here $S$ is called the action functional.

If you are accustomed to higher-order programming — passing `map`, `reduce`, and `filter` around — then this definition of `s` is far clearer than the mathematical formula above. If Haskell is unfamiliar to you, JavaScript expresses the same idea just as well (you may try adding type annotations to the code below with TypeScript):

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

= Partial Derivatives

Before continuing our exploration of the Euler–Lagrange equation, let us recall what a partial derivative is.

For a multi-variable function $f(x, y, z)$, its partial derivative with respect to $x$ at a point $(x_0, y_0, z_0)$ is obtained as follows: first hold the other two variables fixed at $y_0, z_0$, treating them as constants, so that the expression becomes a one-variable function; then differentiate this one-variable function; finally, evaluate the resulting derivative at $x_0$. In Haskell:

```hs
px f x0 y0 z0 = derive (\x -> f x y0 z0) x0
```

Similarly, we obtain the partial derivatives with respect to $y$ and $z$:

```hs
py f x0 y0 z0 = derive (\y -> f x0 y z0) y0
pz f x0 y0 z0 = derive (\z -> f x0 y0 z) z0
```

Here `px`, `py`, and `pz` correspond respectively to the partial derivative operators $(partial) / (partial x), (partial) / (partial y), (partial) / (partial z)$ acting on the function $f(x, y, z)$. Their type signature is:

```hs
px, py, pz :: (Float -> Float -> Float -> Float) -> Float -> Float -> Float -> Float
```

In other words, a partial derivative is precisely an operator that takes a multi-variable function as input and returns a multi-variable function as output.

= The Euler–Lagrange Equation

The mathematical statement of the Euler–Lagrange equation is as follows: if the action functional $S$ is at a stationary point, then this is equivalent to the function $q(t)$ satisfying

$ (partial L) / (partial q) (t, q(t), dot(q)(t)) = d / (d t) ( (partial L) / (partial dot(q)) (t, q(t), dot(q)(t))) $

A stationary point is a maximum, a minimum, or a saddle point. The minimum is the most common case, so the principle is often called the principle of least action (although this phrasing is not strictly accurate).

Here is yet another intimidating formula, one that is hard to grasp even at first glance. Let us do as before: rewrite it in Haskell, with types added.

First we define the function $q(t)$:

```hs
q :: Float -> Float
q t = undefined
```

Then we look at the left-hand side of the formula, which begins with the partial derivative of the Lagrangian with respect to its second argument:

```hs
lhsFirstStep = py lagrangian
```

This yields a function of three variables: `Float -> Float -> Float -> Float`. The three arguments of this function are `t (q t) (derive q t)`. The only free variable left undefined is `t`, so this is a function of the single variable `t`. From this we write the definition of the left-hand side:

```hs
lhs :: Float -> Float
lhs t = py lagrangian t (q t) (derive q t)
```

For the right-hand side, we first take the partial derivative of $L$ with respect to its third variable, obtaining a function of three variables whose three arguments are likewise `t (q t) (derive q t)`. This again yields a one-variable function, in which the only free variable left undefined is `t`; finally, we differentiate this one-variable function once, giving the definition of the right-hand side:

```hs
rhs = derive (\t -> pz lagrangian t (q t) (derive q t))
```

Here we can let Haskell infer the type automatically:

```hs
rhs :: Float -> Float
```

Observe that `lhs` and `rhs` have the same type: both are functions of one variable. The meaning of the Euler–Lagrange equation is that, if the action functional $S$ is at a stationary point, then for every $t$ in the interval from $t_"start"$ to $t_"end"$ we have:

```hs
lhs t == rhs t
```

= From the Lagrangian Back to Newton

Here again we simplify: we discuss only a single point mass of mass $m$ in a one-dimensional conservative field, and we assume that the potential energy $V(q)$ (written `potential q` in Haskell) depends only on position. The Lagrangian is then defined as:

```hs
lagrangian t q v = 0.5 * m * v * v - potential q
```

For this Lagrangian, we take partial derivatives with respect to position (argument `q`) and velocity (argument `v`) by the rules of calculus; that is, we differentiate the second and third arguments:

```hs
py_lagrangian = \t q v -> - derive potential q
pz_lagrangian = \t q v -> m * v
```

According to the Euler–Lagrange equation, if the action functional $S[q] = integral_(t_"start")^(t_"end") L(t, q(t), dot(q)(t)) d t$ is at a stationary point, then necessarily `lhs t == rhs t`. Substituting into the formulas of the previous section:

```hs
lhs t = - derive potential (q t)
rhs t = derive (\t -> m * (derive q t)) t
```

By the rules of calculus, we can factor out `m`, so `rhs` can in fact be written as:

```hs
rhs t = m * derive (derive q) t
```

This expression may also be written as:

```hs
rhs t = m * (derive . derive) q t
```

In dynamics, differentiating the position of an object twice with respect to time gives precisely its acceleration:

$ a(t) = (upright(d)^2 q) / (upright(d) t^2) (t) $

In a one-dimensional conservative field, the gradient of the potential-energy field reduces to the derivative of the potential energy with respect to position, and this derivative is exactly the force acting on the object in the field:

$ F(t) = - (upright(d) V) / (upright(d) q)(q(t)) $

We thus obtain:

```hs
force t = - derive potential (q t)
a t = (derive . derive) q t
```

From the requirement `lhs t == rhs t` of the Euler–Lagrange equation, substituting the simplified results yields:

```hs
force t == m * (a t)
```

In words: the force on the object at any moment equals its acceleration multiplied by its mass. In mathematical notation:

$ F(t) = m a(t) $

And so we return to Newton's second law.

The Euler–Lagrange equation is a necessary and sufficient condition for the action to be at a stationary point. Therefore, starting from Newton's second law, we can also reverse the reasoning and conclude that the action is at a stationary point.

Here we began from a Lagrangian and arrived at Newton's second law. The work of Euler and Lagrange went in the opposite direction: they contrived a suitable function of three variables as the Lagrangian so that the stationary point of the action functional, through the Euler–Lagrange equation, would correspond perfectly to Newton's laws.

= Conclusion

Throughout this post I have tried to keep the discussion simple by using one-dimensional scalars and single-variable functions wherever possible. In reality, however, formulas in vector and multi-variable calculus can be expressed in a type system in similar manner. If you are interested, you may try adding type annotations to the divergence, gradient, curl, and Laplacian operators as well. Moreover, the proof of the Euler–Lagrange equation (I mean the rather unrigorous eighteenth-century proof) is itself quite interesting: you might try annotating integration by parts and the intermediate expressions that arise during the proof — you will find it amusing.

This notation is not perfectly rigorous, but it annotates formulas admirably and serves as a useful aid to understanding. It has enabled a person like me, who have difficulties in math, to grasp the meaning of complex mathematical formulas, which is adequate for engineering mathematics. If, like me, you once studied calculus but cannot fully grasp it, you might give this approach a try; it may open the door to a new world.

])
