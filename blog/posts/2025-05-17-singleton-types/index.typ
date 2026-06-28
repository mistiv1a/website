// 类型级编程：一个最平凡的例子
#import "/template.typ": doc-template

#doc-template(
title: "类型级编程：一个最平凡的例子",
date: "2025年5月17日",
body: [

本文将使用Haskell。

起手先开一些扩展：

```hs
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DataKinds#-}
{-# LANGUAGE TypeOperators #-}
{-# OPTIONS_GHC -Werror=incomplete-patterns #-}

import Data.Type.Equality
```

= 零一

计算机中的一切都是「零」和「一」：

```hs
data Bit = Zero | One
```

为Bit类型中的两个值：「零」和「一」，各自创建类型，是为单例类型（Singleton
Type）：

```hs
-- 前缀S，是Singleton的缩写
data SBit :: Bit -> * where
    SZero :: SBit 'Zero
    SOne  :: SBit 'One
```

= 与非门

一切布尔电路都可以用「与非门」完成，但是我们首先要定义「与非门」：

```hs
type family Nand (a :: Bit) (b :: Bit) :: Bit where
    Nand 'One 'One = 'Zero
    Nand _ _ = 'One
```

`type family`给出的是“定义”，也可以称为“标准”（Specification/Spec）。证明也好，检查也好，都是要让程序必须符合这里的标准。

然后我们可以实现它：

```hs
nandGate :: SBit a -> SBit b -> SBit (Nand a b)
nandGate SOne SOne = SZero
nandGate SZero _ = SOne
nandGate _ SZero = SOne
```


= 非门

零变成一，一变成零，这就是非门。因此给出定义：

```hs
type family Not (a :: Bit) :: Bit where
    Not 'One = 'Zero
    Not 'Zero = 'One
```

「非门」可以利用「与非门」实现：

```hs
notGateImpl x = nandGate x x
```
    
把实现提交给编译器：

```hs
notGate :: SBit a -> SBit (Not a)
notGate = notGateImpl
```

被编译器驳回：

```
Couldn't match type: Nand a a
            with: Not a
Expected: SBit a -> SBit (Not a)
Actual: SBit a -> SBit (Nand a a)
```


notGateImpl返回的是`SBit (Nand a a)`，而notGate的返回值所期望的是`SBit (Not a)`。我们需要证明`SBit (Not a)`和`SBit (Nand a a)`是同一个东西。这样，就可以实现转化。

这里有两种思路，第一种是用纯粹的力量碾压过去，用暴力枚举证明这个东西就是绝对成立的：

```hs
notGateProof :: SBit a -> SBit (Nand a a) :~: SBit (Not a)
notGateProof SOne = Refl
notGateProof SZero = Refl
```

然后利用这个证明实现安全的类型转换：
    
```hs
notGate :: SBit a -> SBit (Not a)
notGate x = castWith (notGateProof x) (notGateImpl x)
```

这样「非门」就完成了。

第二种则是退而求其次，只增加一个类型约束：

```hs
notGate :: (SBit (Nand a a) ~ SBit (Not a)) => SBit a -> SBit (Not a)
notGate x = nandGate x x
```

这样的也能通过编译，而且代码比较简单。

不过这样更像是一种“静态检查”。例如，我们故意写一个错误的实现：

```hs
notGate :: (SBit 'Zero ~ SBit (Not a)) => SBit a -> SBit (Not a)
notGate x = SZero
```

显然，`SBit 'Zero`和`SBit (Not a)`在`a`是`'Zero`的时候是不等价的，但是这里还是可以通过编译。

如果程序中出现了`x`是SOne的`notGate`调用： 

```hs
zero = notGate SOne
```

因为恰好满足条件，还是可以通过编译。

只有在程序中出现`x`是`SZero`的`notGate`调用时：

```hs
one = notGate SZero
```

才会在类型检查中发现问题，此时编译器会报错：

```
• Couldn't match type ‘'Zero’ with ‘'One’
    arising from a use of ‘notGate’
• In the expression: notGate SZero
    In an equation for ‘one’: one = notGate SZero 
```

因为第二种比较简单，所以后面不再赘述，只介绍第一种。从实用的角度来看，第一种的证明经常难以给出，大多数时候只需要第二种这样的“静态检查”就够了。
    
= 与门

何为「与门」？一一得一，余下皆零：

```hs
type family And (a :: Bit) (b :: Bit) :: Bit where
    And 'One 'One = 'One
    And _ _ = 'Zero
```

与非门加上非门，就是与门：

```hs
andGateImpl a b = notGate $ nandGate a b
```
    
用枚举法暴力求证： 
    
```hs
andGateProof :: SBit a -> SBit b -> SBit (Not (Nand a b)) :~: SBit (And a b)
andGateProof SZero SOne = Refl
andGateProof SZero SZero = Refl
andGateProof SOne SOne = Refl
andGateProof SOne SZero = Refl
```

提交给编译器：

```hs
andGate :: SBit a -> SBit b -> SBit (And a b)
andGate a b = castWith (andGateProof a b) (andGateImpl a b)
```

「与门」完成了。

= 或门

照例先给出定义，零零得零，余下皆一：

```hs
type family Or (a :: Bit) (b :: Bit) :: Bit where
    Or 'Zero 'Zero = 'Zero
    Or _ _ = 'One
```

尝试一下花哨的实现方法，利用De Morgan定律，利用「与门」和「非门」组合出「或门」：

```hs
orGateImpl a b = notGate (andGate (notGate a) (notGate b))
```

继续暴力枚举证明自己是对的：
    
```hs
orGateProof :: SBit a -> SBit b
    -> SBit(Not (And (Not a) (Not b))) :~: SBit (Or a b)
orGateProof SZero SZero = Refl
orGateProof SZero SOne = Refl
orGateProof SOne SZero = Refl
orGateProof SOne SOne = Refl
```
    
编译器欣然接受：

```hs
orGate :: SBit a -> SBit b -> SBit (Or a b)
orGate a b = castWith (orGateProof a b) (orGateImpl a b)
```

= 结尾

这里给出的是一个平凡到不能再平凡的例子，不过用到的语言特性还挺多的，算是对最近学习的一个小结。但是如果要实现一些不平凡的例子的话，往往要用一些很复杂很丑的Template Haskell库，不太想碰，所以准备后面去看看Lean 4去。


])
