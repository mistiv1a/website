#import "/template.typ":*

#doc-template(
title: "一些FFMpeg小窍门",
date: "2022年1月18日",
body: [

= 烧录字幕

如果要给视频加载字幕的话，其实还是单独加载文字格式的字幕轨或者字幕文件最方便。但是，如果视频要传到一些网站上，或者要用移动设备观看，可能就需要把字幕烧到视频里面了。FFMpeg提供了一个命令：

```sh
ffmpeg -i input.mp4 -vf "ass=subtitle.ass" output.mp4
```

有的字幕是`*.srt`格式的，这时候要先转码成`*.ass`格式:

```sh
ffmpeg -i input.srt output.ass
```

要是字幕是MKV文件中的字幕轨，那就需要先提取出来：

```sh
ffmpeg -i Movie.mkv -map 0:s:0 subs.srt
```

这里`0:s:0`代表第一条字幕轨。因为有时候一个视频文件里面有多条不同语言的字幕轨，比如说很多从Netflix上扒下来的视频。如果要选择其他的视频轨，比如第二条，就把`-map`参数改成`0:s:1`。

= 合并音频文件

要合并音频文件的话，先要把文件列出来，放到一个文本文件里面，像这样：

```
file track-01.mp3
file track-02.mp3
file track-03.mp3
...
file track-XX.mp3
```

假设把上面的文件存成了`list.txt`，那么就运行这个命令：

```sh
ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp3
```

= 把视频转成GIF

用FFMpeg其实可以直接把视频转成GIF：

```sh
ffmpeg -i input.mp4 output.gif
```

但是，如果直接转换的话，GIF图像上会出现横纵条纹。其实，数字信号处理领域有个专门术语描述这个技术：[抖动（dither）](https://en.wikipedia.org/wiki/Dither)。

因为GIF只有128种颜色可供选择，所以把视频转换过来的时候难免会有损失，这个时候用抖动可减小量化误差。

然而，虽然理论上说，量化误差减小了，但是实际上人眼看起来却是不舒服的，所以最好还是把抖动关掉。不过这样的话步骤要复杂一点，首先要生成GIF调色板：

```sh
ffmpeg -i input.mp4 -vf palettegen palette.png
```

然后结合调色板文件，在禁用抖动的情况下启动转码：

```sh
ffmpeg -i input.mp4 -i palette.png \
    -filter_complex "paletteuse=dither=none" output.gif
```

这样即可得到满意的GIF图片。

])

