手写汇编小窍门（x86-64）
====================

这里假设使用的是GAS（也就是as命令）。虽然纯汇编编程的汇编器以nasm更常见，但是下面两个原因让我决定还是选择GAS：

1. GAS跟gcc是一家，交互比较容易；
2. nasm只支持x86-64架构，而GAS有RISC-V、ARM等其它架构的版本，在GAS上学到的技巧更加泛用。

## 使用Intel格式

GAS默认使用AT&T格式，这个格式很垃圾，不要学。我们直接用intel格式。在文件开头加上这么一行：

```asm
.intel_syntax noprefix
```

## 使用RISC-V风格的寄存器别名

8086早期的寄存器的名字都是有含义的，比如`bx`代表“基址 (base)”，`cx`代表“计数器 (counter)”。然后这些寄存器又扩展成32位的ebx、ecx，以及64位的rbx、rcx。但是对于现代CPU来说，现如今这些寄存器含义早就消解了，大家都是通用寄存器。

在Linux上，调用函数的时候，参数和寄存器关系如下：

- 参数1：rdi
- 参数2：rsi
- 参数3：rdx
- 参数4：rcx
- 参数5：r8
- 参数6：r9

这个顺序实在太难记了，所以不妨效仿RISC-V汇编，给它们一个能表示ABI语义的别名:

```asm
/* arguments */
#define a0 rdi
#define a1 rsi
#define a2 rdx
#define a3 rcx
#define a4 r8
#define a5 r9
```

rax用来存放返回值，起名r0:

```asm
#define r0 rax
```

此外还有两个寄存器，由调用方（caller）负责保存，但是不用来传参，很适合用来存储临时值：

```asm
/* other caller-saved registers */
#define t0  r10
#define t1  r11
```

最后是一些由被调用方（callee）负责保存的寄存器。函数中如果要使用的话，要在函数开头push到栈上，然后在函数结尾pop恢复。这些寄存器都很适合用来保存本地变量。这里以“s”开头，意为“save”：

```asm
/* callee-saved registers */
#define s0 rbx
#define s1 r12
#define s2 r13
#define s3 r14
#define s4 r15
```

注意，因为这里用了C语言风格的宏，所以源代码文件的扩展名必须是大写的字母S，也就是`filename.S`。然后统一用`gcc`编译即可。

## 栈管理

大多数函数都要在最开始处创建栈帧，并在结束时恢复栈帧。这是固定操作，所以用宏：

```asm
.macro begin
    push rbp
    mov rbp, rsp
.endm

.macro return
    mov rsp, rbp
    pop rbp
    ret
.endm
```

## 例子：FNV-1 64位哈希

这个哈希函数的C代码是这样的：

```c
#define FNV_PRIME 0x100000001b3

uint64_t fnv64(const unsigned char *bytes, size_t length, uint64_t input)
{
    uint64_t hash = input;
    for (size_t i = 0; i < length; ++i) {
        hash *= FNV_PRIME;
        hash ^= (uint64_t)bytes[i];
    }
    return hash;
}
```

因为足够简单所以很适合用来作为例子。手写出来的汇编大概是这样：

```s
#define FNV_PRIME 0x100000001b3

.section .text
.globl fnv64

/* fnv64(data, dataSize, input) -> output */
fnv64:
    /* 参数 */
    #define data     a0
    #define dataSize a1
    #define input    a2
    
    begin
    
    /* 本地变量 */
    #define hash  a3
    #define i     a4
    #define prime a5
    
    /* 变量初始化 */
    mov prime, FNV_PRIME
    mov hash, input
    mov i, 0
.Lloop:
    /* while i < dataSize */
    cmp i, dataSize
    jae .Lendloop
        /* hash *= prime */
        imul hash, prime
        /* hash ^= data[i] */
        movzx t0, byte ptr [data + i] /* t0 = data[i] */
        xor hash, t0
        inc i
        jmp .Lloop
.Lendloop:
    mov r0, hash
    return
    #undef data
    #undef dataSize
    #undef input
    #undef hash
    #undef i
    #undef prime
```

几个值得注意的地方：

### 叶子函数

这个函数本身没有调用其他函数，所以所有的`aX`寄存器和`tX`寄存器都可以当成变量用。

与之对应，如果是普通函数，本地变量最好分配成`sX`寄存器，或者溢出到栈上。此时`aX`寄存器和`tX`寄存器只适合存储一些生命周期极短的临时变量。否则每次调用其他函数都需要push这些寄存器，然后恢复，很麻烦。

### 寄存器分配

我们这里可以用宏给他们分配变量名。编译器后端在进行寄存器分配的时候也会做类似的事情。人自然比不上机器，没法进行图着色分配，但是简单模拟一个线性扫描的话基本问题不大：

```c
/* 参数 */
#define data     a0
#define dataSize a1
#define input    a2

/* 本地变量 */
#define hash  a3
#define i     a4
#define prime a5
```

如果变量在栈上的话也一样：

```c
#define varName [rbp - varOffset]
```

### 标签

在GAS中，.L开头的标签不会进入`.o`文件，适合用作函数内部的跳转标签。

例如上面程序中的：

```asm
.Lloop:
```

和

```asm
.Lendloop:
```

但是要注意，标签在每一个文件中必须是唯一的，如果有好几个loop，那可能就要写成 `.Lloop1:`、`.Lloop2:`...，这样。

另一种方法是数字：

```asm
1:
    ...
    ...
2:
    ...
    ...
```

然后，这些数字是可以重复的，例如，编号为1的label可能有多个，为了避免歧义，跳转的时候要注明是往前跳还是往后跳：

```asm
/* 往前跳（向下） */
    jmp 1f

/* 往后跳（向上） */
    jmp 1b
```

### 结构化编程

虽然汇编里面只有跳转和条件跳转，也就是说，只有GOTO。但是作为写汇编体验生活的现代人，我们可以“手中无剑，心中有剑”，依然用结构化编程的形式来组织程序，加上注释，然后在合适的地方缩进：

```asm
.Lloop:
    /* while i < dataSize */
    cmp i, dataSize
    jae .Lendloop
        /* hash *= prime */
        imul hash, prime
        /* hash ^= data[i] */
        movzx t0, byte ptr [data + i] /* t0 = data[i] */
        xor hash, t0
        inc i
        jmp .Lloop
.Lendloop:
```

## 结构体

假设有2个这样的结构体：

```c
struct Point {
    int32_t x;
    int32_t y;
    int32_t z;
};

struct Line {
    struct Point p1;
    struct point p2;
};
```

那么GAS中可以这么定义：

```asm
.set Point_x,      0
.set Point_y,      4 + Point_x
.set Point_z,      4 + Point_y
.set sizeof_Point, 4 + Point_z

.set Line_p1,     0
.set Line_p2,     sizeof_Point + Line_p1
.set sizeof_Line, sizeof_Point + Line_p2
```

这样就可以得到一个可维护的结构体偏移量和结构体尺寸。

在使用时，假如`t0`寄存器中存储了一个`struct Line`的指针，如果我们要获得 t0->p2.x，只需要：

```asm
movsx t0, dword ptr [t0 + Line_p2 + Point_x]
```

## 栈帧

栈帧上的变量也可以用类似方式，通过`.set`分配其偏移量。

假如一个函数中有这些本地变量需要保存在栈上：

```c
int32_t x;
int32_t y;
int64_t z;
struct Line line;
```

那么就可以这么写：

```asm
.set x,    4
.set y,    4 + x
.set z,    8 + y
.set line, sizeof_Line + z
```

要注意到：本地变量的栈帧是向下增长的，所以，最后一个变量line的偏移量也就是栈帧的尺寸。但是C ABI要求栈帧必须16字节对齐，也就是说，栈帧尺寸的字节数必须是16的倍数，所以我们用一个宏辅助向上取到16的倍数：

```asm
#define align16(_var) (((_var) + 15) & (-16))

.set stackFrameSize, align16(line)
```

然后创建栈帧：

```asm
sub rsp, stackFrameSize
```

随后，相对`rbp`进行寻址就可以访问这些本地变量。注意到本地变量的栈帧是从高到低增长的，所以对本地变量寻址应该做减法。而成员变量的偏移是从低到高，所以对成员变量做寻址应该做加法：

```asm
/* t0 = line.p1.y; */
movsx t0, dword ptr [rbp - line + Line_p1 + Point_y]
```
