// EZLive: 无需服务器，轻松搭建私人直播间
#import "/template.typ": doc-template

#doc-template(
title: "EZLive: 无需服务器，轻松搭建私人直播间",
date: "2025年9月27日",
body: [

如果想要开启一场直播，大部分人的选择会是国内的Bilibili、抖音、斗鱼等平台，或者选择Twitch、YouTube之类的国外视频平台。

但是，这些平台各有缺点。国外的平台版权方面非常严格，如果放歌的话稍有不慎就会下架；而国内的平台在版权音乐等方面相对宽松，但是审核比较严厉。

目前已经有了一个开源的个人直播工具，叫做Owncast。Owncast采用Go语言开发，可以轻松搭建自己的直播间，但是仍然需要托管在服务器上面，配置也很繁琐。

针对以上问题，我最近开发了一个新的个人直播工具，名叫EZLive。托管在了GitHub上： #link("https://github.com/mistivia/ezlive", "mistivia/ezlive")。

EZLive在功能上基本以Owncast为蓝本，但是和Owncast不同，不需要专门的公网服务器。EZLive内置了SRT推流服务器，将接收到的推流直接转成HLS，发布到云上的对象存储桶中。支持任意和AWS S3兼容的对象存储平台，包括但不限于：DigitalOcean、七牛云、阿里云OSS、腾讯云COS、B2、CloudFlare R2、Minio等等。

下面介绍一下使用方法。

= 申请S3兼容的对象存储桶

这里各个云厂商操作方式大同小异，不再赘述。操作完成之后，需要有以下信息：


- 存储桶名称
- 接入点（Endpoint）
- 地域（region）
- Access key
- Secret key

然后，要允许公网访问存储桶中的元素。对于AWS S3来说，配置就是，在“Permissions”、“Bucket Policy”中设置：

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadOnly",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::存储桶名字/*"
        }
    ]
}
```

然后，需要设置跨域访问（CORS）。EZLive项目自带了一个HLS播放器，托管在了Github Page上： #link("https://github.com/mistivia/ezlive/tree/gh-pages", "mistivia/ezlive/tree/gh-pages")

访问地址是：#link("https://mistivia.github.io/ezlive", "https://mistivia.github.io/ezlive")

因此需要将：`https://mistivia.github.io`加入跨域访问中，允许GET操作。

对于AWS S3来说，配置就是编辑存储桶的“Permissions”、“Cross-origin resource sharing (CORS)”：

```
[
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "GET"
        ],
        "AllowedOrigins": [
            "https://mistivia.github.io"
        ],
        "ExposeHeaders": []
    }
]
```

= 启动EZLive

首先需要去发布页面下载EZLive：#link("https://github.com/mistivia/ezlive/releases/", "https://github.com/mistivia/ezlive/releases/")

== Windows平台

下载Windows平台的二进制构建结果：ezlive-windows.7z

解压后在ezlive目录下创建配置文件“config”，注意没有任何扩展名。然后按以下格式填入：

```ini
listening_addr=127.0.0.1
listening_port=61935
bucket=YOUR_BUCKET_NAME
endpoint=https://your-oss.com
s3_path=ezlive/
access_key=YOUR_S3_ACCESS_KEY
secret_key=YOUR_S3_SECRET_KEY
region=YOUR_REGION
```

然后运行ezlive.exe。

== Linux平台

Linux平台上推荐使用Docker。下载Docker镜像：ezlive-docker-image.tar.gz

导入：

```sh
cat ezlive-docker-image.tar.gz | gzip -d | sudo docker load
```

创建conf目录：

```sh
mkdir conf
```

conf目录中创建一个config文件，内容和上面基本相同。但是因为在docker中，所以监听地址需要改成0.0.0.0。

```ini
listening_addr=0.0.0.0
listening_port=61935
bucket=YOUR_BUCKET_NAME
endpoint=https://your-oss.com
s3_path=ezlive/
access_key=YOUR_S3_ACCESS_KEY
secret_key=YOUR_S3_SECRET_KEY
region=YOUR_REGION
```

最后运行Docker镜像

```sh
sudo docker run -it --rm \
    -v ./conf:/etc/ezlive/ \
    -p 127.0.0.1:61935:61935/udp \
    localhost/ezlive
```

因为手头没有macOS设备，因此没有提供macOS构建，macOS用户可能需要自行从源码构建。

= 推流

EZLive启动后可以打开OBS推流。EZLive要求视频流必须是H.264，音频流必须是AAC。
EZLive不会对推流进行太多处理，只是会把容器从mpegts转成hls。

推流地址是：

```
srt://127.0.0.1:61935
```

= 播放

推流开始后，应当可以在对象存储桶中的ezlive目录下看到stream.m3u8和若干视频片段文件。

假设stream.m3u8的访问路径是：`https://your-bucket.your-oss.com/ezlive/stream.m3u8`，那么，打开下面的地址即可收看直播：

```
https://mistivia.github.io/ezlive#https://your-bucket.your-oss.com/ezlive/stream.m3u8
```

这个播放器中默认内置了hack chat服务用于弹幕评论，如果不需要这个功能的话，可以使用这个播放地址：

```
https://mistivia.github.io/ezlive/hls.html#https://your-bucket.your-oss.com/ezlive/stream.m3u8
```

如果无法播放的话，检查：

- stream.m3u8的链接是否可以正常访问；
- 是否将播放器的域名(https://mistivia.github.io)加入到了CORS设置中。

= 提醒

对于直播来说，目前各大云厂商的对象存储的存储费用几乎可以忽略不计，但是流量费用往往较高，有的高达0.5元每GB，使用的时候需要注意开销。

推流结束后不要急着关闭EZLive进程，可以等待一段时间，在一分钟没有收到新推流的情况下，EZLive会自动删除直播视频片段，节省云存储空间。

此外，GitHub pages和hack chat在国内的访问均不稳定。如果需要国内用户可以无障碍观看，除了尽量采用国内的对象存储服务以外，可能还需要换一个hls播放器，例如：

```
https://www.livereacting.com/tools/hls-player-embed?url=https://your-bucket.your-oss.com/ezlive/stream.m3u8
```

注意要将对应的播放器域名加入跨域设置中，比如说对于上面的播放器，就是：

```
https://www.livereacting.com
```

只有正确配置了跨域设置，直播才能正常观看。

])
