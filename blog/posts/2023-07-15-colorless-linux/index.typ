// 让Linux失去色彩
#import "/template.typ":*
#doc-template(
title: "让Linux失去色彩",
date: "2023年7月15日",
body: [

这件事情的起因是我看了这么一篇文章：《#link("https://cn.wsj.com/articles/%E6%88%92%E6%8E%89-%E6%89%8B%E6%A9%9F%E7%99%AE-%E4%BD%A0%E9%9C%80%E8%A6%81%E9%80%99%E5%80%8B%E5%B0%8F%E6%8A%80%E5%B7%A7-4f91c59d", "戒掉“手机瘾”，你需要这个小技巧")》

有个新研究显示，相较于用应用程序来限制使用时间，把手机改成黑白屏幕的效果更好。

其中iOS和Android都自带了把屏幕显示变成黑白灰度的功能，主要是提供给色盲群体。而Windows 10上也有类似的功能。我现在手头没有macOS设备，不过既然iOS上有，macOS自然也没有不行的道理。

问题来到了Linux这里。Linux上是没有原生提供这种工具的，唯一一个比较接近的是#link("https://github.com/jonls/redshift", "RedShift")。但是这个工具的原理是调节Gamma值，因此只能调整红绿蓝三种颜色的比例，而不能把屏幕变成灰度。

最后我找到的解决方案是用#link("https://github.com/yshui/picom", "picom")。

Picom是一个X compositor，支持OpenGL渲染，所以可以自己写一个OpenGL着色器控制显示效果：

```glsl
#version 330

in vec2 texcoord;
uniform sampler2D tex;

vec4 window_shader() {
	vec4 c = texelFetch(tex, ivec2(texcoord), 0);

	float grayscale = c.x * 0.299 + c.y * 0.587 + c.z * 0.114;
	c.x = grayscale;
	c.y = grayscale;
	c.z = grayscale;
	return c;
}
```

因为人眼对于红绿蓝三种颜色的敏感程度不同，所以这里用了NTSC制式下的彩色转黑白公式，将红绿蓝以0.299:0.587:0.114的比例配比，计算出灰度值，然后把红绿蓝都设置为这个灰度值，就可以把彩色图像转成黑白。其实用红绿蓝三个颜色的强度的平均值也可以，效果也差不多。

把着色器保存在`~/.picom.glsl`，然后运行picom：

```sh
picom --backend glx --window-shader-fg '/home/mistivia/.picom.glsl' &
```

就可以看到屏幕变成了黑白。如果要开机自动执行的话，可以把这行命令放到`.xinitrc`里面。如果要恢复成彩色的话，只要把picom进程杀掉就可以了。

])