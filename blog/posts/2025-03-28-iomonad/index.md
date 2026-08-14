从Hello World到IO Monad
========

这是一段平平无奇的Python代码：

```py
def main():
    x = input()
    y = input()
    print(x + y)

main()
```

这段代码的主要作用是输出“Hello World”。

第一步：输入“Hello”：

```
hello
```

第二步：输入“ World”：

```
hello
    world
```

最后按下回车，第三步就会得到：

```
hello world
```

如果接触过一些异步编程的话，我们会注意到，input是一个I/O操作，如果想要高效执行I/O，往往需要做异步的I/O。

在async/await尚未诞生的远古时代，如果我们想要把一个程序异步化，就必须要写成回调函数的形式。

当然，这里的`input`并不是一个异步的I/O函数，不过这不妨碍我们把这段程序改成回调函数的形式，只是为了好玩。

我们把`main`拆成三个函数，每一个函数会在结尾调用下一步：

```py
def main():
    step1()

def step1():
    x = input()
    step2(x)

def step2(x):
    y = input()
    step3(x, y)

def step3(x, y):
    print(x + y)
```

这段代码和最初的版本功能是一样的。

接着把代码改紧凑一点：
    
```py
def main():
    step1()

def step1():
    step2(input())

def step2(x):
    step3(x, input())

def step3(x, y):
    print(x + y)
```

Python是允许在函数里面定义函数的，就像这样：

```py
def f1():
    def f2():
        do_something()
    f2()
```

我们就用这样的方式，把函数全部堆在一起，每一步函数都在上一步里面定义，这样还是只有一个`main`函数：

```py
def main():
    def step1():
        def step2(x):
            def step3(x, y):
                print(x + y)
            step3(x, input())
        step2(input());
    step1()
```

Python里面有个叫做“闭包”的功能。因为`step3`是在`step2`里面定义的，所以`step3`中可以直接访问`step2`的参数`x`，不需要再专门传递进去。所以我们可以稍微简化一下：

```py
def main():
    def step1():
        def step2(x):
            def step3(y):
                print(x + y)
            step3(x, input())
        step2(input());
    step1()
```

上面的代码中，`step1`和`step2`的结构很相似，都是这样：

```py
def step(...):
    def next_step(...) 
        ...
    next_step(input())
```

注意最后一行的`next_step(input())`，其作用是调用`input`，获取输入结果之后，作为参数传递给下一步。既然`input()`这个步骤是固定的，变化的只有下一步的函数，那么我们干脆把下一步的函数当成参数，定义一个新函数：

```py
def input_and_do(next_step):
    next_step(input())
```

这个函数的作用和`next_step(input())`相同。

然后，用这个新定义的`input_and_do`改写`main`函数：

```py
def main():
    def step2(x):
        def step3(y):
            print(x + y)
        input_and_do(step3)
    input_and_do(step2)
```

Python中有个功能叫lambda表达式。原本要两行才能定义的函数：

```py
def fn(x):
    return meow(x)
```

用上了lambda之后只需要一行:
    
```py
lambda x: meow(x)
```

所以，`step3`可以写成这样:

```py
lambda y: print(x + y)
```

`step2`可以写成这样：

```py
lambda x: input_and_do(step3)
```

把`step3`代进去，`step2`就变成了：

```py
lambda x: input_and_do(lambda y: print(x+y))
```

这样`main`就可以改写成一行：

```py
def main():
    input_and_do(lambda x: input_and_do(lambda y: print(x+y)))
```

不过这样看起来有点乱，所以稍微做一些排版。得到了最终的Python程序，看上去非常抽象（整活意味上的）：

```py
def input_and_do(next_step):
    next_step(input())

def main():
    input_and_do(lambda x: ( \
        input_and_do(lambda y: \
            print(x + y))))
```

既然标题里面写了IO monad了，接下来要开始Haskell了。我们尝试把上面这段Python代码改写成Haskell。既然已经写成了全是lambda的样子，那么自然也可以像素级复刻这段代码了。

不过Haskell标准库里面的函数名字稍微有点区别，`input`对应`getLine`，`print`对应putStrLn：

```hs
inputAndDo nextStep = nextStep getLine    

main :: IO ()
main = inputAndDo(\x ->
            inputAndDo(\y ->
                putStrLn (x ++ y)))
```

不出意外的话，这段代码是可以运行的。

但是出意外了：

```
• Couldn't match expected type: [Char]
                with actual type: IO String
• In the first argument of ‘(++)’, namely ‘x’
    In the first argument of ‘putStrLn’, namely ‘(x ++ y)’
    In the expression: putStrLn (x ++ y)
```

我们原来期望`x`和`y`的类型是`String`，但是实际上它们变成了`IO String`。问题出在`getLine`这里，`getLine`返回的并不是一个简单的`String`，而是一个`IO String`：

```
ghci> :t getLine
getLine :: IO String
```

`getLine`的返回值（`IO String`类型）变成了`x`和`y`传给了`putStrLn`，但是`putStrLn`期望的参数类型是`String`，所以报错了。

我们想要的`String`被IO monad包起来了，我们需要“解包”，把`IO String`“变成”
`String`。

要解决这个问题，先看看`IO String`是什么。`IO`是一个monad，monad的定义是：

```hs
class Monad m where
    (>>=)  :: m a -> (a -> m b) -> m b
    -- ...
    -- ...
```

具体到`IO`和`IO String`的话，也就是说，`(>>=)`这个操作符的类型变成了：

```hs
IO String -> (String -> IO b) -> IO b
```

一个只接受`String`作为参数的函数，只要使用`(>>=)`就可以把`IO String`塞进去，“解包”，得到其中的`String`。

但是力量往往伴随着代价，如果一个函数想要用`(>>=)`解开IO monad的封印，那么这个函数的返回值也必须是一个IO monad。

我们选择接受这个代价，修改一下`inputAndDo`：

```hs
inputAndDo nextStep = (>>=) getLine nextStep
```

再改成中缀形式：

```hs
inputAndDo nextStep = getLine >>= nextStep
```

最终的Haskell代码如下：

```hs
inputAndDo nextStep = (getLine >>= nextStep)

main :: IO ()
main = inputAndDo(\x ->
            inputAndDo(\y ->
                putStrLn (x ++ y)))
```

这段代码可以工作，撒花~

既然`inputAndDo nextStep`等价于`getLine >>= nextStep`，那么其实可以直接把`inputAndDo`改成`getLine >>=`：

```hs
main :: IO ()
main = getLine >>= (\x->
            getLine >>= (\y ->
                putStrLn (x ++ y)))
```

效果是一样的。不过这段代码和上面的抽象版本Python代码一样，仍然看起来很糟心。

好在Haskell里面有个语法糖，叫做do notation，可以把这样的表达式：

```hs
uwu >>= (\x -> ...)
```

变成这样：
    
```hs
do
    x <- uwu
    ...
```

这样看起来舒服一点。

所以我们就这样改一下，先改第一步：

```hs
main :: IO ()
main = do
    x <- getLine
    getLine >>= (\y ->
                    putStrLn (x ++ y))
```

第二步也是同样的形式，所以可以接着爆改：

```hs
main :: IO ()
main = do
    x <- getLine
    y <- getLine
    putStrLn (x ++ y)
```

改造完毕，跟一开始的Python代码对比一下：

```hs
def main():
    x = input()
    y = input()
    print(x + y)
```

完 全 一 致

就这样，我们回到了最初的原点。这段旅程就此结束。

## 免责声明

本文并没有介绍什么是Monad。只是介绍了Haskell中的do记号实际上在做什么。至于monad本身，还是需要额外的学习。
