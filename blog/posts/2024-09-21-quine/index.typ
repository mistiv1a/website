// 笨方法写Quine
#import "/template.typ":*

#doc-template(
title: "笨方法写Quine",
date: "2024年9月21日",
body: [

#let wrap-anywhere(content) = {
  content.replace(regex("([^\n])"), (m) => m.text + "\u{200b}")
}
#show raw.where(block: true): it => {
  par(leading:0pt,spacing:0pt)[#text(size:0pt)[]]
  block(
    inset: (left: 24pt, top: 0em, bottom: 0em),
    width: 100%,
    text(wrap-anywhere(it.text))
  )
  par(leading:0pt,spacing:0pt)[#text(size:0pt)[]]
}


= 什么是Quine

Quine是一类很有意思的程序，它运行之后所输出的结果是它自身。这种程序又被称为“自我复制程序”，具有某种类似生物一样的奇妙的自指特征，很有意思。

下面两个quine的例子是我从#link("https://en.wikipedia.org/wiki/Quine_%28computing%29")[维基百科]上抄下来的。

示例1: Python

```py
c = 'c = %r; print(c %% c)'; print(c % c)
```

示例2: Java

```java
public class Quine
{
  public static void main(String[] args)
  {
    char q = 34;      // Quotation mark character
    String[] l = {    // Array of source code
    "public class Quine",
    "{",
    "  public static void main(String[] args)",
    "  {",
    "    char q = 34;      // Quotation mark character",
    "    String[] l = {    // Array of source code",
    "    ",
    "    };",
    "    for (int i = 0; i < 6; i++)           // Print opening code",
    "        System.out.println(l[i]);",
    "    for (int i = 0; i < l.length; i++)    // Print string array",
    "        System.out.println(l[6] + q + l[i] + q + ',');",
    "    for (int i = 7; i < l.length; i++)    // Print this code",
    "        System.out.println(l[i]);",
    "  }",
    "}",
    };
    for (int i = 0; i < 6; i++)           // Print opening code
        System.out.println(l[i]);
    for (int i = 0; i < l.length; i++)    // Print string array
        System.out.println(l[6] + q + l[i] + q + ',');
    for (int i = 7; i < l.length; i++)    // Print this code
        System.out.println(l[i]);
  }
}
```

但是这两个例子里面，代码都不是很好理解。假如我想要用第三种语言，比如C++或者JavaScript，写一个quine，还需要重新构思。

因此，我希望找到一种通用的方式，可以以最直观最容易的方式写出quine。虽然这种quine不一定是最短、最高效的，但是最直观、最容易举一反三。

= Quine规律

观察上一节的两个quine，虽然看起来区别很大，但是其实总结起来大概分这么几步：

1. 开头，可能有一些import或者类定义之类的东西；
2. 一个字符串，因为其作用有点像是遗传物质，所以这里我就记作“DNA”，其内容应当包含这个字符串前面的程序，加上这个字符串后面的程序；
3. 结尾：
   1. 从字符串“DNA”中取出开头，并打印；
   2. 打印这个字符串本身；
   3. 从字符串“DNA”中取出结尾，并打印。

虽然看上去很简单，但是常用的编程语言中，在表达字符串的时候，换行符、引号都需要额外的转义。例如，字符串中换行符要写作“\n”，引号前面要加上反斜杠。这些内容带来了不必要的麻烦，这也是上面的代码难以看懂的原因。

但是，这些转义符号，其本质都是一种编码。所以，我的思路是，干脆直接把字符串
DNA编码成最简单的16进制形式，然后需要打印的时候再解码。

这样，就不需要奇怪的hack了。

而且，也不一定非得是16进制编码，用base64、base32，或者跟真正的DNA一样，用碱基字母编码，都是可以的。

= 妙妙小工具

为了把字符串编码成16进制，我用Python写了一个小工具，可以读入字符串，输出其16进制形式：

```py
import sys

s = sys.stdin.read()
if s[-1] == '\n':
  s = s[:-1]
print(s.encode('utf-8').hex())
```

把上述代码保存为hexencode.py，然后在Shell中可以这样使用：

```bash
cat input.txt | python3 hexencode.py
```

= 开始写代码

Python写起来比较简单，就先用Python吧。

首先定义字符串“DNA”。这里我们不知道“DNA”的内容，所以先用emoji符号代替。因为这个字符串里面包含了两部分内容：头和尾，我们假设头是老虎，尾巴是蛇：

```py
dna = '🐱,🐍'
```

然后把头和尾巴取出来：

```py
head, tail = dna.split(',')
```

因为我们打算用16进制编码，所以这里要把头和尾都用16进制解码恢复成原来的样子：

```py
head = bytes.fromhex(head).decode('utf-8')
tail = bytes.fromhex(tail).decode('utf-8')
```

最后，我们把头、DNA、尾巴，这三部分拼接起来，一起输出：

```py
print(head + dna + tail)
```

现在的程序是这样的：

```py
dna = '🐱,🐍'
head, tail = dna.split(',')
head = bytes.fromhex(head).decode('utf-8')
tail = bytes.fromhex(tail).decode('utf-8')
print(head + dna + tail)
```

老虎🐱头前面的部分是：

```py
dna = '\n```

使用妙妙小工具编码，得到：

`646e61203d2027`

把🐱替换成这个字符串。

接着，蛇🐍尾巴后面的部分是：

```py
'\nhead, tail = dna.split(',')
head = bytes.fromhex(head).decode('utf-8')
tail = bytes.fromhex(tail).decode('utf-8')
print(head + dna + tail)
```

使用妙妙小工具编码，得到：

```
270a686561642c207461696c203d20646e612e73706c697428272c27290a68656164203d2062797465732e66726f6d6865782868656164292e6465636f646528277574662d3827290a7461696c203d2062797465732e66726f6d686578287461696c292e6465636f646528277574662d3827290a7072696e742868656164202b20646e61202b207461696c29
```

把🐍替换成这个字符串。

最后得到了这样的代码：

```py
dna = '646e61203d2027,270a686561642c207461696c203d20646e612e73706c697428272c27290a68656164203d2062797465732e66726f6d6865782868656164292e6465636f646528277574662d3827290a7461696c203d2062797465732e66726f6d686578287461696c292e6465636f646528277574662d3827290a7072696e742868656164202b20646e61202b207461696c29'
head, tail = dna.split(',')
head = bytes.fromhex(head).decode('utf-8')
tail = bytes.fromhex(tail).decode('utf-8')
print(head + dna + tail)
```

到这里，一个quine就已经完成了。运行一下试试吧。

= 推广到其他语言

这里就用C++举例好了：

先写出差不多的模板：

```cpp
#include <iostream>
#include <string>

void split(std::string input, std::string &first, std::string &second);
std::string hex_decode(std::string hex);

int main() {
  std::string dna = "🐱,🐍";
  
  std::string head, tail;
  split(dna, head, tail);
  head = hex_decode(head);
  tail = hex_decode(tail);
  
  std::cout << head << dna << tail << std::endl;
}

// 麻烦的地方是C++标准库里面不提供分割和16进制解码函数
// 我也懒得写了，直接AI生成一下:

void split(std::string input, std::string &first, std::string &second) {
    size_t commaPos = input.find(',');
    if (commaPos != std::string::npos) {
        first = input.substr(0, commaPos);
        second = input.substr(commaPos + 1);
    } else {
        first = input;
        second = "";
    }
}

std::string hex_decode(std::string input) {
    std::string output;
    output.reserve(input.size() / 2);
    for (size_t i = 0; i < input.size(); i += 2) {
        std::string byteString = input.substr(i, 2);
        char byte = static_cast<char>(std::strtol(byteString.c_str(), nullptr, 16));
        output.push_back(byte);
    }
    return output;
}
```

然后把🐱前面的程序文本和🐍后面的程序文本用妙妙小工具编码成16进制并替换，得到：

```cpp
#include <iostream>
#include <string>

void split(std::string input, std::string &first, std::string &second);
std::string hex_decode(std::string hex);

int main() {
  std::string dna = "23696e636c756465203c696f73747265616d3e0a23696e636c756465203c737472696e673e0a0a766f69642073706c6974287374643a3a737472696e6720696e7075742c207374643a3a737472696e67202666697273742c207374643a3a737472696e6720267365636f6e64293b0a7374643a3a737472696e67206865785f6465636f6465287374643a3a737472696e6720686578293b0a0a696e74206d61696e2829207b0a20207374643a3a737472696e6720646e61203d2022,223b0a20200a20207374643a3a737472696e6720686561642c207461696c3b0a202073706c697428646e612c20686561642c207461696c293b0a202068656164203d206865785f6465636f64652868656164293b0a20207461696c203d206865785f6465636f6465287461696c293b0a20200a20207374643a3a636f7574203c3c2068656164203c3c20646e61203c3c207461696c203c3c207374643a3a656e646c3b0a7d0a0a2f2f20e9babbe783a6e79a84e59cb0e696b9e698af432b2be6a087e58786e5ba93e9878ce99da2e4b88de68f90e4be9be58886e589b2e5928c3136e8bf9be588b6e8a7a3e7a081e587bde695b00a2f2f20e68891e4b99fe68792e5be97e58699e4ba86efbc8ce79bb4e68ea54149e7949fe68890e4b880e4b88b3a0a0a766f69642073706c6974287374643a3a737472696e6720696e7075742c207374643a3a737472696e67202666697273742c207374643a3a737472696e6720267365636f6e6429207b0a2020202073697a655f7420636f6d6d61506f73203d20696e7075742e66696e6428272c27293b0a2020202069662028636f6d6d61506f7320213d207374643a3a737472696e673a3a6e706f7329207b0a20202020202020206669727374203d20696e7075742e73756273747228302c20636f6d6d61506f73293b0a20202020202020207365636f6e64203d20696e7075742e73756273747228636f6d6d61506f73202b2031293b0a202020207d20656c7365207b0a20202020202020206669727374203d20696e7075743b0a20202020202020207365636f6e64203d2022223b0a202020207d0a7d0a0a7374643a3a737472696e67206865785f6465636f6465287374643a3a737472696e6720696e70757429207b0a202020207374643a3a737472696e67206f75747075743b0a202020206f75747075742e7265736572766528696e7075742e73697a652829202f2032293b0a20202020666f72202873697a655f742069203d20303b2069203c20696e7075742e73697a6528293b2069202b3d203229207b0a20202020202020207374643a3a737472696e672062797465537472696e67203d20696e7075742e73756273747228692c2032293b0a2020202020202020636861722062797465203d207374617469635f636173743c636861723e287374643a3a737472746f6c2862797465537472696e672e635f73747228292c206e756c6c7074722c20313629293b0a20202020202020206f75747075742e707573685f6261636b2862797465293b0a202020207d0a2020202072657475726e206f75747075743b0a7d"
  
  std::string head, tail;
  split(dna, head, tail);
  head = hex_decode(head);
  tail = hex_decode(tail);
  
  std::cout << head << dna << tail << std::endl;
}

// 麻烦的地方是C++标准库里面不提供分割和16进制解码函数
// 我也懒得写了，直接AI生成一下:

void split(std::string input, std::string &first, std::string &second) {
    size_t commaPos = input.find(',');
    if (commaPos != std::string::npos) {
        first = input.substr(0, commaPos);
        second = input.substr(commaPos + 1);
    } else {
        first = input;
        second = "";
    }
}

std::string hex_decode(std::string input) {
    std::string output;
    output.reserve(input.size() / 2);
    for (size_t i = 0; i < input.size(); i += 2) {
        std::string byteString = input.substr(i, 2);
        char byte = static_cast<char>(std::strtol(byteString.c_str(), nullptr, 16));
        output.push_back(byte);
    }
    return output;
}
```

把这个C++源代码文件保存为quine.cpp，然后可以用以下命令验证其输出结果是否和原来的源代码一致：

```bash
g++ quine.cpp && ./a.out | diff quine.cpp -
```

= 多语言的Quine

还有一种quine是这样的：A语言写出来的程序输出B语言的源代码，这段B语言的源代码又输出一开始的A语言的代码，形成了一个A到B回到A的循环。这个过程甚至可以包括更多语言，例如A到B到C到D到E再回到A。

GitHub上#link("https://github.com/mame/quine-relay")[有个项目就构造了一个100多种语言的循环]。

我们用了这种16进制编码的“笨方法”之后，因为不需要再考虑转义字符的问题了，无论多少种语言都可以轻松构造。

接下来我们就把上面的Python和C++结合起来，构造一个C++程序输出Python程序，Python
程序运行又输出原来的C++程序的例子。

先写出Python版本的模板，还是和上面一样：

```py
dna = '🐱,🐍'
head, tail = dna.split(',')
head = bytes.fromhex(head).decode('utf-8')
tail = bytes.fromhex(tail).decode('utf-8')
print(head + dna + tail)
```

然后，写一个C++程序，输出上面的模板：

```cpp
#include <iostream>
#include <string>

std::string py =
    "dna = '🐱,🐍'\n"
    "head, tail = dna.split(',')\n"
    "head = bytes.fromhex(head).decode('utf-8')\n"
    "tail = bytes.fromhex(tail).decode('utf-8')\n"
    "print(head + dna + tail)\n";

int main() {
    std::cout << py;
    return 0;
}
```

然后把这段C++代码中，🐱前面的程序文本和🐍后面的程序文本用妙妙小工具编码成16进制并替换，得到：

```cpp
#include <iostream>
#include <string>

std::string py =
    "dna = '23696e636c756465203c696f73747265616d3e0a23696e636c756465203c737472696e673e0a0a7374643a3a737472696e67207079203d0a2020202022646e61203d2027,275c6e220a2020202022686561642c207461696c203d20646e612e73706c697428272c27295c6e220a202020202268656164203d2062797465732e66726f6d6865782868656164292e6465636f646528277574662d3827295c6e220a20202020227461696c203d2062797465732e66726f6d686578287461696c292e6465636f646528277574662d3827295c6e220a20202020227072696e742868656164202b20646e61202b207461696c295c6e223b0a0a696e74206d61696e2829207b0a202020207374643a3a636f7574203c3c2070793b0a2020202072657475726e20303b0a7d"

int main() {
    std::cout << py;
    return 0;
}
```

把这段代码保存为quine.cpp，并验证结果：

```bash
g++ quine.cpp
./a.out > quine.py
python3 quine.py > quine2.cpp
diff quine.cpp quine2.cpp
```

完工。

]
)
