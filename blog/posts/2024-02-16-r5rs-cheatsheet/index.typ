#import "/template.typ":doc-template

#doc-template(
title: "R5RS速查表",
date: "2024年2月16日",
body: [

= 相等

```rkt
(eqv? obj1 obj2)
(eq? obj1 obj2)
(equal? obj1 obj2)
```

= 数字

```rkt
(number? obj)
(complex? obj)
(real? obj)
(rational? obj)
(integer? obj)

(exact? z)
(inexact? z)

(zero? z)
(positive? x)
(negative? x)
(add? n)
(even? n)

(max x1 x2 ...)
(min x1 x2 ...)

(+ z1 ...)
(* z1 ...)
(- z1 z2)
(- z)
(- z1 z2 ...)
(/ z1 z2)
(/ z)
(/ z1 z2 ...)

(abs x)

(quotient n1 n2)
(remainder n1 n2)
(modulo n1 n2)

(gcd n1 ...)
(lcm n1 ...)

(numerator q)
(denominator q)

(floor x)
(ceiling x)
(truncate x)
(round x)

(rationalize x y)

(exp z)
(log z)
(sin z)
(cos z)
(tan z)
(asin z)
(acos z)
(atan z)
(atan y x)

(sqrt z)
(expt z1 z2)

(make-rectangular x1 x2)
(make-polar x3 x4)
(real-part z)
(imag-part z)
(magnitude z)
(angle z)

(exact->inexcat z)
(inexact->exact z)

(number->string z)
(number->string z radix)

(string->number str)
(string->number str radix)
```

= 布尔

```rkt
(not obj)
(boolean? obj)
```

= 有序对和列表

```rkt
(pair? obj)
(cons obj1 obj2)
(car pair)
(cdr pair)
(set-car! pair obj)
(set-cdr! pair obj)

(caar pair)
(cadr pair)
...
(cdddar pair)
(cddddr pair)

(null? obj)
(list? obj)

(list obj ...)
(length list)
(append list ...)
(reverse list)
(list-tail list k)
(list-ref list k)

(memq obj list)
(memv obj list)
(member obj list)

(assq obj alist)
(assv obj alist)
(assoc obj alist)
```

= 符号

```rkt
(symbol? obj)
(symbol->string symbol)
(string->symbol string)
```

= 字符

```rkt
(char? obj)

(char=? c1 c2)
(char<? c1 c2)
(char>? c1 c2)
(char<=? c1 c2)
(char>=? c1 c2)

(char-ci=? c1 c2)
(char-ci<? c1 c2)
(char-ci>? c1 c2)
(char-ci<=? c1 c2)
(char-ci>=? c1 c2)

(char-alphabetic? c)
(char-numeric? c)
(char-whitespace? c)
(char-upper-case? c)
(char-lower-case? c)

(char->integer c)
(integer->char c)

(char-upcase c)
(char-downcase c)
```

= 字符串

```rkt
(string? obj)

(make-string k)
(make-string k char)

(string char ...)

(string-length str)
(string-ref str k)
(string-set! str k char)

(string=? str1 str2)
(string>? str1 str2)
(string<? str1 str2)
(string>=? str1 str2)
(string<=? str1 str2)

(string-ci=? str1 str2)
(string-ci>? str1 str2)
(string-ci<? str1 str2)
(string-ci>=? str1 str2)
(string-ci<=? str1 str2)

(substring str start end)
(string-append str ...)

(string->list string)
(list->string list)

(string-copy string)
(string-fill! string char)
```

= 向量

```rkt
(vector? obj)

(make-vector k)
(make-vector k fill)

(vector obj ...)

(vector-length vec)

(vector-ref vec k)
(vector-set! vec k obj)

(vector->list vector)
(list->vector list)

(vector-fill! vector fill)
```

= 控制流

```rkt
(procedure? obj)

(apply proc arg1 arg2 ...)

(map proc list1 list2 ...)

(for-each proc list1 list2)

(deplay expr)
(force promise)

(call/cc proc)

(values obj ...)
(call-with-values producer cosumer)

(dynamic-wind before thunk after)

(eval expr env)
```


= 输入输出

```rkt
(call-with-input-file string proc)
(call-with-output-file string proc)

(input-port? obj)
(output-port? obj)

(current-input-port)
(current-output-port)

(with-input-from-file string thunk)
(with-output-to-file string thunk)

(open-input-file filename)
(open-output-file filename)

(close-input-port port)
(close-output-port port)

(read)
(read port)

(read-char)
(read-char port)

(peek-char)
(peek-char port)

(eof-object? obj)

(char-ready?)
(char-ready? port)

(write obj)
(write obj port)

(display obj)
(display obj port)

(newline)
(newline port)

(write-char char)
(write-char char port)
```

= 系统

```rkt
(load filename)

(transcript-on filename)
(transcript-off)
```

])