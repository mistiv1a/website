// Adding Type Annotations to the Euler–Lagrange Equation
#import "/template.typ": *

#doc-template(
title: "Type Annotating the Euler–Lagrange Equation Using Haskell",
date: "March 30, 2026\nTranslated by LLM from Chinese",
body: [

The word "functional" in functional programming is commonly referred to as an adjective; but it can actually also be used as a noun meaning “higher-order function” - that is, a function that takes another function as input, such as the famous map/reduce. Here is a casual JavaScript example:

```js
var add1 = function (x) { return x + 1; };
[1,2,3].map(add1);
```

The calculus of variations, built upon the concept of functionals, is precisely the foundation of analytical mechanics in physics. _Structure and Interpretation of Classical Mechanics_ is an attempt to combine these two. This book is a companion to _SICP_, teaching analytical mechanics using the Scheme language. I tried reading it two years ago, but after struggling for a long time, I couldn't understand the mathematical formulas, couldn't keep track of all the Lisp parentheses, and found the English painful to read, so I gave up.

Last year I learned Haskell, and recently I picked it up again to flip through. Then I tried rewriting the code in the book into Haskell with type annotations. Something magical happened: I found that with types, the code suddenly became completely clear, and the mathematical formulas instantly made sense too, so I decided to write down my thoughts.

= Real Numbers and Functions

In calculus, we mainly work with real numbers. Although floating-point numbers are not real numbers, we are not striving for rigor here—we are merely borrowing Haskell's type system as scratch paper for our thoughts—so we will use floating-point numbers as a substitute.

```hs
pi :: Float
e :: Float
```

A function, then, takes one or more real numbers as input and returns one or more real numbers. For example, a single-variable scalar function looks like this:

```hs
f :: Float -> Float
```

Functions like $sin$, $cos$, and $ln$ all follow this pattern:

```hs
sin :: Float -> Float
cos :: Float -> Float
ln :: Float -> Float
```

= Derivatives and Integrals

Here we assume the reader has at least a high-school level understanding of calculus.

Mathematical notation for derivatives is notoriously inconsistent. Some choose dots (like Newton):

$ dot(f) (x) $

Some use differential notation:

$ (upright(d) f) / (upright(d) x) (x) $

Some use primes:

$ f'(x) $

Or a standalone capital D:

$  upright(D) f (x) $

But all these symbols essentially express the same concept: we have a function, and through some transformation, it becomes another function, which is the “derivative” of the original function. What this transformation does is take a function as input and return a function:

```hs
derive :: (Float -> Float) -> (Float -> Float)
```

In Haskell, `->` is right-associative, so we can drop the parentheses on the right:

```hs
derive :: (Float -> Float) -> Float -> Float
```

Here, `derive` is clearly a higher-order function. In mathematics, however, this kind of higher-order function that takes a function and returns a function is usually not called a functional, but rather an “operator.”

For example, for a function `f :: Float -> Float`, the type of `derive f` is also a function: `Float -> Float`. Then with the independent variable added, `derive f x0` is the value of the derivative of `f` at the point `x0`, so its type is `Float`. In mathematics this is written as:

$ (upright(d) f)/(upright(d) x) (x_0) $

Here we are not developing a complete symbolic computation system, so we will assume we have such a higher-order function ready to use and will not give its full definition. We will only provide its type, and write the implementation as `undefined`.

```hs
derive f = undefined
```

As for integration, mathematically there is basically only one notation. For an integrand $f$ with upper limit $b$ and lower limit $a$, the definite integral is:

$ integral_a^b f(x) d x $

In code, this corresponds to the following higher-order function:

```hs
integral :: (Float -> Float) -> Float -> Float -> Float
integral f a b = undefined
```

= Action

Let us open the #link("https://en.wikipedia.org/wiki/Euler%E2%80%93Lagrange_equation", "Wikipedia page") for the Euler–Lagrange equation.

Inside, a thing called the “action functional” is defined. Its input is a trajectory function $q(t)$ that evolves over time, and it computes the integral of the Lagrangian over the time interval $[t_"start", t_"end"]$:

$ S[q] = integral_(t_"start")^(t_"end") L(t, q(t), dot(q)(t)) d t $

If you are reading this article and, like me, are bad at advanced mathematics, you might already be scared to tears at this point. But it is actually not that difficult—it is just intimidating because one gets lost in the notation. Let us break it down step by step.

The $L$ in the formula is called the Lagrangian. Let us simplify and assume a one-dimensional case where $q(t)$ is a scalar; then $L$ is a ternary function:

```hs
lagrangian :: Float -> Float -> Float -> Float
lagrangian = undefined
```

By extension, if there are two generalized coordinates, the Lagrangian is a function of five variables; if there are three, it is a function of seven variables. But here we will only look at the simplest case.

Now let us rewrite this formula using the higher-order functions for differentiation and integration defined above:

```hs
s q = integral
  (\t -> lagrangian t (q t) (derive q t)) t_start t_end
```

Pay attention to the lambda expression inside—this is precisely the most confusing part of the mathematical formula. In the formula, it looks like we are integrating the Lagrangian function, but that is not what is actually happening at all. What the formula actually does is use the ternary function $L$, the trajectory function $q$, and the derivative operator $upright(D)$ to define a new unary function, and then integrate this newly defined function. In code, this potentially ambiguous part of the formula is laid bare and will not cause any confusion in understanding.

The `t_start` and `t_end` in the formula are constants; we do not care about their specific values, only that they exist:

```hs
t_start :: Float
t_start = undefined

t_end :: Float
t_end = undefined
```

At this point, if you have the Haskell LSP server installed, it will automatically infer the type of `s` for you:

```hs
s :: (Float -> Float) -> Float
```

You can see that the type of $S$ is actually very simple: it takes a function as input and returns a real number. This is precisely the definition of a “functional” in mathematics, and here $S$ is called the “action functional.”

If you often play around with higher-order functions, mapping, reducing, and filtering all over the place, then compared to the mathematical formula above, the definition of `s` here is much clearer. If you are not familiar with Haskell, expressing it in JavaScript has a similar effect (you can try adding type annotations to the following code with TypeScript):

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

Before continuing to explore the Euler–Lagrange equation, let us recall what a partial derivative is.

For a multivariable function $f(x, y, z)$, the partial derivative with respect to variable $x$ at a point $(x_0, y_0, z_0)$ is obtained by first fixing the other two variables $y_0, z_0$, treating them as constants, turning it into a unary function, then differentiating this unary function, and finally evaluating the derivative of this unary function at $x_0$. Written in Haskell, it looks like this:

```hs
px f x0 y0 z0 = derive (\x -> f x y0 z0) x0
```

Similarly, we can obtain the partial derivatives with respect to $y$ and $z$:

```hs
py f x0 y0 z0 = derive (\y -> f x0 y z0) y0
pz f x0 y0 z0 = derive (\z -> f x0 y0 z) z0
```

Here `px`, `py`, and `pz` correspond to the partial derivative operators $(partial) / (partial x), (partial) / (partial y), (partial) / (partial z)$ of the function $f(x, y, z)$. The type signatures of the three are as follows:

```hs
px, py, pz :: (Float -> Float -> Float -> Float) -> Float -> Float -> Float -> Float
```

That is to say, a partial derivative is actually an “operator” that takes a multivariable function as input and returns a multivariable function.

= The Euler–Lagrange Equation

The mathematical statement of the Euler–Lagrange equation is that if the action functional $S$ is at a stationary point, then this is equivalent to the function $q(t)$ satisfying:

$ (partial L) / (partial q) (t, q(t), dot(q)(t)) = d / (d t) ( (partial L) / (partial dot(q)) (t, q(t), dot(q)(t))) $

A stationary point refers to a maximum, minimum, or saddle point. Among these, minima are more commonly used, so this is also often called the principle of least action (though this phrasing is not strictly rigorous).

Here is another very intimidating formula; at first glance it is difficult to understand even if you know what it means. Let us rewrite it in Haskell code with types, just as we did before.

First, we define the function $q(t)$:

```hs
q :: Float -> Float
q t = undefined
```

Now look at the left-hand side of the equation. First, we take the partial derivative of the Lagrangian with respect to its second argument:

```hs
lhsFirstStep = py lagrangian
```

This gives a ternary function: `Float -> Float -> Float -> Float`. Then the three arguments to this function are `t (q t) (derive q t)`. The only undefined free variable inside is `t`. So this is a function with a single independent variable `t`. From this we write the definition of the left-hand side:

```hs
lhs :: Float -> Float
lhs t = py lagrangian t (q t) (derive q t)
```

The right-hand side first takes the partial derivative of L with respect to its third variable, giving a ternary function whose three arguments are still `t (q t) (derive q t)`. This again gives a unary function whose only undefined free variable is `t`; finally, we differentiate this unary function once more to obtain the definition of the right-hand side:

```hs
rhs = derive (\t -> pz lagrangian t (q t) (derive q t))
```

Here we can let Haskell automatically infer the type for us:

```hs
rhs :: Float -> Float
```

You can see that `lhs` and `rhs` have the same type: both are unary functions. The meaning of the Euler–Lagrange equation is that if the action functional $S$ is at a stationary point, then equivalently, for $t$ in the interval from $t_"start"$ to $t_"end"$:

```hs
lhs t == rhs t
```

= From Lagrangian Back to Newton

Let us continue simplifying and consider only a single particle of mass $m$ in a one-dimensional conservative field. Assume the potential energy of the system $V(q)$ (which we denote as `potential q` in Haskell) depends only on position. The Lagrangian is then defined as:

```hs
lagrangian t q v = 0.5 * m * v * v - potential q
```

For this Lagrangian, we apply calculus rules to take partial derivatives with respect to position (parameter `q`) and velocity (parameter `v`); that is, with respect to the second and third arguments:

```hs
py_lagrangian = \t q v -> - derive potential q
pz_lagrangian = \t q v -> m * v
```

According to the Euler–Lagrange equation, if the action functional $S[q] = integral_(t_"start")^(t_"end") L(t, q(t), dot(q)(t)) d t$ is at a stationary point, then necessarily `lhs t == rhs t`. We substitute the formulas from the previous section:

```hs
lhs t = - derive potential (q t)
rhs t = derive (\t -> m * (derive q t)) t
```

According to calculus rules, we can factor out `m`, so `rhs` can actually be written as:

```hs
rhs t = m * derive (derive q) t
```

This expression can also be written as:

```hs
rhs t = m * (derive . derive) q t
```

And in dynamics, taking the second derivative of an object's position with respect to time is precisely its acceleration:

$ a(t) = (upright(d)^2 q) / (upright(d) t^2) (t) $

And in a one-dimensional conservative field, the gradient of the potential field becomes the derivative of the potential with respect to position, and this derivative is precisely the force on the object in this field:

$ F(t) = - (upright(d) V) / (upright(d) q)(q(t)) $

So we obtain:

```hs
force t = - derive potential (q t)
a t = (derive . derive) q t
```

From the Euler–Lagrange equation requirement `lhs t == rhs t`, substituting the simplified results yields:

```hs
force t == m * (a t)
```

That is to say, at any moment the force on the object equals its acceleration multiplied by its mass. We state this with a mathematical formula:

$ F(t) = m a(t) $

Thus, we return to Newton's second law.

The Euler–Lagrange equation holding is a necessary and sufficient condition for the action to be at a stationary point. Therefore, starting from Newton's second law, we can also work backwards to show that this action is at a stationary point.

Here we started from a Lagrangian and arrived at Newton's second law. The work Euler and Lagrange did back in their day was the reverse: they figured out how to construct a suitable ternary function as the Lagrangian such that the stationary point of the action functional perfectly corresponds to Newton's laws through the Euler–Lagrange equation.

= Conclusion

In this article, to simplify the discussion, we have used one-dimensional scalars and single-variable functions as much as possible. But in fact, formulas from vector and multivariable calculus can also be expressed using a type system in this way. If you are interested, you can try adding type annotations to divergence, gradient, curl, the Laplacian operator, and so on. In addition, the derivation of the Euler–Lagrange formula (I mean the not-very-rigorous 18th-century kind of proof) is also quite interesting; you can try adding type annotations to integration by parts and the expressions obtained during the proof—it can be quite fun.

Although this notation is not entirely rigorous, it serves as excellent commentary for formulas and is a great tool for aiding understanding and thought, allowing someone like me with limited brainpower to more or less grasp the meaning of very complex mathematical formulas. For engineering mathematics, this is already good enough. If you, like me, felt that everything was a blur when you studied calculus back then, you might as well give it a try—it may open the door to a whole new world.

])
