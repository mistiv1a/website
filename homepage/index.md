Mistivia
========

<div id="zh" class="lang-zh">
<p>关于我自己，我并不想作太多介绍，你可以点击“博客”阅读我的文章。另外，除了博客之外，这里还有一些其他内容：</p>
<ul>
<li><a href="//raye.mistivia.com/gallery/">摄影集</a></li>
<li><a href="//mistivia.com/chat">IRC 聊天室</a></li>
<li><a href="https://github.com/mistivia?tab=repositories">GitHub</a></li>
</ul>
</div>

<div id="en" class="lang-en" hidden>
<p>I do not wish to say much about myself; you can read my articles here. There are also a few other things here:</p>
<ul>
<li><a href="//raye.mistivia.com/gallery/">Photographs</a></li>
<li><a href="//mistivia.com/chat">IRC chat</a></li>
<li><a href="https://github.com/mistivia?tab=repositories">GitHub</a></li>
</ul>
</div>

<style>
[hidden] { display: none !important; }
</style>
<script>
(function () {
    var lang = (navigator.language || navigator.userLanguage || '').toLowerCase();
    var zh = document.getElementById('zh');
    var en = document.getElementById('en');
    if (zh && en && lang.indexOf('zh') !== 0) {
        zh.hidden = true;
        en.hidden = false;
    }
})();
</script>
