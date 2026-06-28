// 像Rust一样使用Haskell
#import "/template.typ": doc-template

#doc-template(
title: "像Rust一样使用Haskell",
date: "2025年5月31日",
body: [

= 引子

在系统编程领域，内存安全一直是C/C++程序员的梦魇。一个简单的`malloc`或`free`，就可能埋下导致程序崩溃、数据损坏甚至安全漏洞的隐患。今天，我们将探索如何用Haskell来驯服这些内存猛兽，甚至达到类似于Rust的内存安全保证。

首先让我们从一些不怎么安全的C代码开始。下面是三个函数，分别是创建矩阵、向矩阵中填充随机浮点数，以及矩阵乘法运算。因为矩阵是用malloc函数创建的，所以如果要销毁矩阵，直接用free即可。

```c
#include <stdlib.h>
#include <time.h>
#include <openblas/cblas.h>

#define N 1000

double* new_matrix() {
    double* mat = (double*)malloc(N * N * sizeof(double));
    return mat;
}

void fill_matrix(double* mat) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            mat[i*N + j] = (double)rand() / RAND_MAX;
        }
    }
}

// 计算 c = a * b
void mat_mul(double* c, double* a, double* b) {
    cblas_dgemm(
        CblasRowMajor,
        CblasNoTrans,
        CblasNoTrans,
        N, N, N, 1.0,
        a, N, b, N, 1.0, c, N);
}
```

然后我们写一个main函数：

```c
int main() {
    double *a, *b, *c;

    srand(time(NULL));

    a = new_matrix();
    b = new_matrix();
    c = new_matrix();

    fill_matrix(a);
    fill_matrix(b);


    mat_mul(c, a, b);

    free(a);
    free(b);
    free(c);

    return 0;
}
```

虽然这是一个很简单的例子，但是因为这里用的是不安全的C语言，所以我们有无数种方法可以让程序崩溃。

比如说，双重free：

```c
free(a);
free(a);
```

或者，在free后使用：

```c
free(a);
fill_matrix(a);
```

又或者因为忘记free导致内存泄露，等等。

= Haskell FFI

通过Haskell的FFI功能，我们可以在Haskell中调用这些函数。

首先打开FFI扩展：

```hs
{-# LANGUAGE ForeignFunctionInterface #-}
```

导入一些必要的功能模块：

```hs
import Foreign.Ptr (Ptr)
import Foreign.C.Types (CDouble)
import Foreign.Marshal.Alloc (free)
```

定义FFI函数：

```hs
foreign import ccall "new_matrix"
    cNewMatrix :: IO (Ptr CDouble)

foreign import ccall "fill_matrix"
    cFillMatrix :: Ptr CDouble -> IO ()

foreign import ccall "mat_mul"
    cMatMul :: Ptr CDouble -> Ptr CDouble -> Ptr CDouble -> IO ()
```

然后就可以调用这些函数了：

```hs
main = do
    a <- cNewMatrix
    b <- cNewMatrix
    c <- cNewMatrix

    cFillMatrix a
    cFillMatrix b

    cMatMul c a b

    free a
    free b
    free c

    return ()
```

这里的main函数几乎是和C语言中的版本逐行对应的，但是，这样一来，C语言中的同样的安全问题也会如影随形，上面提到的几个C语言相关的安全问题这里都会出现。

不过，和C语言不同，这次，我们可以解决这个问题。

= 安全指针

Haskell的`Foreign.ForeignPtr`可以提供类似于RAII的机制，规避绝大多数内存安全问题。

具体到上面的例子，首先，我们导入一些库函数：

```hs
import Foreign.ForeignPtr
```

然后把指针的定义从裸指针改为安全的ForeignPtr：

```hs
a <- cNewMatrix >>= newForeignPtr free
b <- cNewMatrix >>= newForeignPtr free
c <- cNewMatrix >>= newForeignPtr free
```

然后使用的时候，用withForeignPtr创建一个作用域，这样就可以保证在作用域范围内安全的使用这些指针。完整代码如下：

```hs
main = do
    a <- cNewMatrix >>= newForeignPtr finalizerFree
    b <- cNewMatrix >>= newForeignPtr finalizerFree
    c <- cNewMatrix >>= newForeignPtr finalizerFree
    withForeignPtr a $ \a ->
    withForeignPtr b $ \b ->
        withForeignPtr c $ \c -> do
        cFillMatrix a
        cFillMatrix b
        cMatMul c a b
```
  
这样我们就不用担心内存安全的问题了。

= 线性类型

但是上面的方法仍然有局限性，所能实现的生命周期和所有权管理非常粗糙。

例如，我们无法实现类似这样的只有一部分重叠的两个对象的生命周期：

```hs
a <- cNewMatrix
-- ..
b <- cNewMatrix
free a
-- ...
free b
```


也无法实现类似这样的操作：

```hs
a <- cNewMatrix
if foo then
    free a 
else
    sendToAnotherThread a
```

如果想要精细的生命周期控制，就需要最新最酷炫的线性类型扩展：

```hs
{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE QualifiedDo #-}
```

这里还启用了QualifiedDo扩展，这是为了启用Linear.do，使用线性类型的IO单子，后面会提到。

在线性类型中，我们可以定义一个这样的函数：

```hs
func :: a %1 -> b
```

这个函数签名的意思是，在func中，如果函数的返回值b被使用了一次，那么函数的参数a
必须使用且只能只用一次，否则编译器会报错。

这样，上面的几个安全问题都会在编译器就收到报错。

1. 双重释放：对象使用了两次，不符合规则；
2. 释放后使用：同理，对象使用了两次，不符合规则；
3. 内存泄露：忘记释放，对象没有被使用过，不符合规则。

而如果要对对象进行读写操作，只需要在操作完成之后把这个对象原路返回，这样就可以“假装”这个对象从未被使用过。很类似Rust中的借用规则。

例如，上面的填充矩阵，就可以写成

```hs
a <- fillMatrix a
```

而矩阵乘法可以写成这样：

```hs
(c, a, b) <- matMul c a b
```

基于这样的思路，我们可以对我们FFI中的矩阵操作进行封装。这里要用到linear-base这个库，这是目前Haskell社区实际上的线性类型标准库。

对于IO操作，我们要用专门的Linear IO Monad。Linear IO Monad可以和原先的标准Monad互相转换。

```hs
import Prelude (IO, (>>), (>>=), fmap, return)
import Prelude.Linear
import qualified System.IO.Linear as Linear
import qualified Control.Functor.Linear as Linear

data Mat where Mat :: (Ptr CDouble) -> Mat

-- 消耗完资源又返回，实际上并没有消耗
fillMat :: Mat %1-> Linear.IO Mat
fillMat (Mat ptr) = Linear.fromSystemIO $
    cFillMatrix ptr >> 
    return (Mat ptr)

-- 同上，看起来消耗了资源，实际上这些资源又返回了
matMul :: Mat %1-> Mat %1-> Mat %1-> Linear.IO (Mat, Mat, Mat)
matMul (Mat a) (Mat b) (Mat c) = Linear.fromSystemIO $
    cMatMul a b c >>
    return (Mat a, Mat b, Mat c)

deleteMat :: Mat %1 -> Linear.IO ()
deleteMat (Mat ptr) = Linear.fromSystemIO $ free ptr
```

然后改写main函数，这里我们使用了`Linear.do`，可以对Linear.IO进行monad操作:

```hs
main = Linear.withLinearIO $ Linear.do
    a <- newMatrix
    b <- newMatrix
    c <- newMatrix

    a <- fillMat a
    b <- fillMat b

    (c,a,b) <- matMul c a b

    deleteMat a
    deleteMat b
    deleteMat c
    Linear.return $ Ur ()
```

我们可以试试故意在main函数里面写一些内存不安全的代码。我们会发现无论怎么尝试，编译器都会报错。

这里我们用到了`Ur`这个东西，它表示 () 值是“无限制的”（不被线性消耗），这个解释起来有点复杂，如果感兴趣可以去翻看linear-base的文档和教程。

= 借用

不过，用线性类型像这样把资源传来传去，每次调用函数都要把参数写两遍，输入一遍、输出一遍，会看起来很笨拙。Rust对此的解决方法是借用一个reference，对这个reference进行各种操作，在此期间原来的变量会不可用，等reference离开作用域后原来的变量又会回来，也就是“借用”机制。例如：

在Haskell中，我们可以通过一个类似于`withForeignPtr`的函数，实现类似于“借用”的效果。我们把这个函数起名为`borrow`。

为了区分资源的所有权和使用权，我们引入一个新的类型 `MatRef`。`Mat` 类型表示我们拥有对矩阵内存的完全所有权，而 `MatRef` 则表示我们只是临时“借用”了矩阵，可以对其进行读写操作，但不能释放它或转移其所有权。

```hs
data Mat where Mat :: (Ptr CDouble) -> Mat

-- MatRef 允许我们对矩阵进行操作，但不会“消耗”矩阵资源
data MatRef where MatRef :: (Ptr CDouble) -> MatRef

newMatrix :: Linear.IO Mat
newMatrix = Linear.fromSystemIO $ fmap Mat cNewMatrix

-- 释放矩阵资源，因此它消耗一个 Mat 类型的值
deleteMat :: Mat %1 -> Linear.IO ()
deleteMat (Mat ptr) = Linear.fromSystemIO $ free ptr

-- 填充矩阵的操作，不消耗资源，因此接受 MatRef
fillMat :: MatRef -> IO ()
fillMat (MatRef ptr) = cFillMatrix ptr

-- 矩阵乘法操作，不消耗资源，因此接受 MatRef
matMul :: MatRef -> MatRef -> MatRef -> IO ()
matMul (MatRef a) (MatRef b) (MatRef c) = cMatMul a b c
```

然后我们实现borrow函数，这里用到了一点多态小科技：

```hs
class Borrow io b where
    borrow :: Mat %1 -> (MatRef -> io b) %1-> Linear.IO (Mat, b)

instance Borrow Linear.IO a where
    borrow :: Mat %1 -> (MatRef -> Linear.IO b) %1-> Linear.IO (Mat, b)
    borrow (Mat ptr) body =
        body (MatRef ptr) Linear.>>= \x->
        Linear.return (Mat ptr, x)

instance (a ~ ()) => Borrow IO a where
    borrow :: Mat %1 -> (MatRef -> IO b) %1-> Linear.IO (Mat, b)
    borrow (Mat ptr) body =
        Linear.fromSystemIO (body (MatRef ptr)) Linear.>>= \x->
        Linear.return (Mat ptr, x)
```

通过增加一个类型约束，我们可以将限制borrow内部的IO操作只能返回unit，确保没有引用值“逃逸”到borrow的外面，导致不安全的内存操作。

最后效果如下：

```hs
main = Linear.withLinearIO $ Linear.do
    a <- newMatrix
    b <- newMatrix
    c <- newMatrix

    (a, (b, (c, ()))) <-
    borrow a $ \a ->
    borrow b $ \b ->
    borrow c $ \c -> do
        fillMat a
        fillMat b
        matMul c a b

    deleteMat a
    deleteMat b
    deleteMat c
    Linear.return (Ur ())
```

在borrow函数内部，我们可以对MatRef进行任意次数的操作，不用担心资源问题，代码也很简洁直观。而在borrow函数的外面，我们可以用线性类型对资源的生命周期进行精细而安全的管理，实现安全的零成本抽象。

= 总结

通过线性类型，Haskell即使在与不安全的C代码交互时，也可以实现Rust相媲美的内存安全性。

直到这里，我们全部用的是命令式的编程方式，Haskell还有无比强大的函数式编程功能供我们选用，还有比C++模板元编程更好用更强大的类型级别编程。总之，Haskell不愧为一门优秀的命令式编程语言。

])