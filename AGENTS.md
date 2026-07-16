# Blog Site

## 创建新文章的步骤

第1步：选定标题、英文缩写（例如，标题：关于XXX的使用；缩写：xxxx-usage）

第2步：运行`date`查看日期（日期格式：20yy-mm-dd）

第3步：创建目录`blog/posts/yyyy-mm-dd-缩写/`

第4步：创建文件`blog/posts/yyyy-mm-dd-缩写/index.typ`。

文件初始内容如下：

```
#import "/template.typ": *

#doc-template(
title: "标题",
date: "20xx年m月y日",
body: [

])
```

注意，目录名的格式是20xx-0x-0x，但是文件里面日期是"20xx年x月x日"，没有“0”。

第5步：修改`blog/index.md`，在合适的位置（按日期降序）插入：

```
- 20xx-mm-dd [标题](/posts/20xx-mm-dd-缩写/)
```

结束。

## English translation

If it's an English translation, the header is :


```
#import "/template.typ": *

#doc-template(
title: "Title",
date: "June 1, 2025",
parindent: 1.2em,
body: [

])
```

Write like a fluent native Roman language speaker writing English at CEFR C1 would.

- Vocabulary: stay roughly within the 10,000 most frequent English words.
- Avoid: phrasal verbs (prefer single Latinate verbs — "tolerate," not "put up with"), idioms, slang, culture-specific references.
- Do not  misspell, break word order, or drop articles at random. You should write like a educated and fluent writer.