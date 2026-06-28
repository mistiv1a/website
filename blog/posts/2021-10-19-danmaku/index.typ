// 开发弹幕朗读器
#import "/template.typ":*

#doc-template(
title: "开发弹幕朗读器",
date: "2021年10月19日",
body: [

最近有成为透明无声系vTuber的打算，为了增加娱乐效果，搞了一个弹幕朗读器。因为不想花太多时间，所以就选了Python，准备快速解决。

= 如何朗读

我直接用了Windows操作系统内置的语音合成功能：#link("https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ms723602(v=vs.85)", "SpVoice")。

用#link("https://pypi.org/project/pywin32/", "PyWin32")可以调用该接口。

首先需要安装PyWin32：

```bash
pip3 install pywin32
```

示例代码：

```py
import win32com.client

speaker = win32com.client.Dispatch("SAPI.SpVoice")
speaker.Speak("你好，世界！")
```

= 如何获取弹幕

Twitch的聊天系统比较有意思，他们在提供聊天机器人接口的竟然用的是#link("https://dev.twitch.tv/docs/irc/guide#connecting-to-twitch-irc", "IRC接口")。

所以，你甚至可以用nc命令上去直接手工操作：

```
[mistivia@arch ~]$ nc irc.chat.twitch.tv 6667
< PASS oauth:<Twitch OAuth token>
< NICK <user>
> :tmi.twitch.tv 001 <user> :Welcome, GLHF!
> :tmi.twitch.tv 002 <user> :Your host is tmi.twitch.tv
> :tmi.twitch.tv 003 <user> :This server is rather new
> :tmi.twitch.tv 004 <user> :-
> :tmi.twitch.tv 375 <user> :-
> :tmi.twitch.tv 372 <user> :You are in a maze of twisty passages, all alike.
> :tmi.twitch.tv 376 <user> :>
JOIN #channel
```

注意登录之后的提示语：

```
You are in a maze of twitsy passages，all alike.
```

这其实是一个彩蛋，来自70年代PDP-10计算机上的冒险游戏：#link("https://en.wikipedia.org/wiki/Colossal_Cave_Adventure#Maze_of_twisty_little_passages", "Colossal Cave Adventure")，简称Adventure。这是世界上第一部交互式小说，也是第一部冒险游戏和文字冒险游戏。

这款游戏后来在Atari游戏机上还有一个改编的图形版：Adventure，被认为是历史上第一个带彩蛋的游戏（就是《头号玩家》里面的那个）。

因为IRC是一个非常古老而成熟的文本协议，所以开发的时候只需要用Python上的一些IRC开源库即可。Twitch官方就提供了一个#link("https://github.com/twitchdev/chatbot-python-sample", "Python2实现的机器人的例子")。稍微改一改即可使用在Python3上。

里面用到了一个#link("https://pypi.org/project/irc/", "Python的IRC库")，需要提前安装上：

```sh
pip3 install irc
```

最后的代码：

```py
# Windows Only
# Dependencies: pip install pywin32 irc

import win32com.client
import irc.bot

# your username
username = "mistivia"
botname = "mybot"
# channel name, prepending '#' is a must
channel = "#mistivia"
# To get a token, visit: http://twitchapps.com/tmi/
token = "oauth:YOUR TOKEN HERE"

server = "irc.chat.twitch.tv"
port = 6667

speaker = win32com.client.Dispatch("SAPI.SpVoice")

class TwitchBot(irc.bot.SingleServerIRCBot):
    def __init__(self, username, client_id, token, channel):
        self.client_id = client_id
        self.token = token
        self.channel = channel

        print('Connecting to ' + server + ' on port ' + str(port) + '...')
        irc.bot.SingleServerIRCBot.__init__(
            self, [(server, port, token)], username, username)


    def on_welcome(self, c, e):
        print('Joining ' + self.channel)

        # You must request specific capabilities before you can use them
        c.join(self.channel)

    def on_pubmsg(self, c, e):
        self.on_msg(e.source.nick, e.arguments[0])

    def on_msg(self, nick, msg):
        print(nick + ": " + msg)
        speaker.Speak(nick + "说：" + msg)

if __name__ == "__main__":
    bot = TwitchBot(username,botname, token, channel)
    bot.start()
```

])