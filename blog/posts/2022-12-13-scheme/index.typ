// 邪道Scheme
#import "/template.typ":doc-template

#doc-template(
title: "邪道Scheme",
date: "2022年12月13日",
body: [

因为Scheme和Lisp系的其他语言一样，过于灵活，因此可以往语言里面加入很多奇怪的东西。甚至，如果想用命令式的方式，像Python一样编写Scheme代码，也是可以的。

这篇文章中的代码都是为GNU Guile和TinyScheme而写的，这两个解释器都支持老式的Lisp宏。这种宏在Common Lisp当中更多见，并不卫生，也不属于任何Scheme标准。但是大多数解释器和编译器都支持。

例如，假如想在Racket中运行，只需要在代码前面加入下面这段语法就可以了：

```rkt
#lang racket

(define-syntax define-macro
  (lambda (x)
    (syntax-case x ()
      ((_ (macro . args) body ...)
       #'(define-macro macro (lambda args body ...)))
      ((_ macro transformer)
       #'(define-syntax macro
           (lambda (y)
             (syntax-case y ()
               ((_ . args)
                (let ((v (syntax->datum #'args)))
                  (datum->syntax y (apply transformer v)))))))))))
```

= hello, world

Python代码：

```py
print("hello, world")
```

函数定义：

```rkt
(define println
    (lambda x
      (apply display x)
      (newline)))
```

最终效果：

```rkt
(println "hello world")
```

= Def

Python代码：

```py
def is_even(x):
    if x % 2 == 0:
        return True
    return False
```

宏定义：

```rkt
(define-macro (def form . body)
    `(define ,form
         (call/cc (lambda (return)
            ,@body))))
```

最终效果：

```rkt
(def (is-even x)
    (cond ((= 0 (modulo x 2))
        (return #t)))
    (return #f))
```


= While

Python代码：

```py
i = 0
while True:
    i = i + 1
    if x % 2 == 0:
        continue
    print(i)
    if i > 10:
        break
```


宏定义：

```rkt
(define-macro (while condition . body)
    (let ((loop (gensym)))
        `(call/cc (lambda (break)
            (letrec ((,loop (lambda ()
                (cond (,condition
                    (call/cc (lambda (continue)
                            ,@body))
                    (,loop))))))
                (,loop))))))
```


最终效果：

```rkt
(let ((i 0))
(while #t
    (set! i (+ i 1))
    (cond ((= (modulo i 2) 0)
         (continue)))
    (cond ((> i 10)
        (break)))
    (println i)))
```


= For

Python代码：

```py
for i in range(0, 10):
    print(i)
```


宏和工具函数定义：

```rkt
(define (iter-get iter)
    (cond ((list? iter)
        (car iter))
    (else
        (iter 'get))))

(define (iter-next iter)
    (cond ((list? iter)
        (cdr iter))
    (else
        (iter 'next))))

(define (range start end)
    (lambda (method)
        (cond ((eq? 'get method)
            (if (>= start end)
                '()
                start))
        ((eq? 'next method)
            (range (+ 1 start) end)))))

(define-macro (for i range . body)
    (let ((loop (gensym))
          (iter (gensym)))
    `(call/cc (lambda (break)
        (letrec
            ((,loop (lambda (,iter)
                (if (eq? (iter-get ,iter) '())
                    '()
                    (let ((,i (iter-get ,iter)))
                          (call/cc (lambda (continue)
                             ,@body))
                          (,loop (iter-next ,iter)))))))
            (,loop ,range))))))
```


最终效果：

```rkt
(for i (range 0 10)
    (println i))
```


= Goto

这个还是算了吧！

= Fizz Buzz!

Python写出来是这样：

```py
for i in range(35):
    if i % 15 == 0:
        print("FizzBuzz")
        continue
    if i % 3 == 0:
        print("Fizz")
        continue
    if i % 5 == 0:
        print("Buzz")
        continue
    print(i)
```

用Scheme的话，加上上面的宏，几乎可以一一对应：

```rkt
(for i (range 1 35)
    (cond ((= 0 (modulo i 15))
        (println "FizzBuzz")
        (continue)))
    (cond ((= 0 (modulo i 3))
        (println "Fizz")
        (continue)))
    (cond ((= 0 (modulo i 5))
        (println "Buzz")
        (continue)))
    (println i))
```

]
)