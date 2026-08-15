友情链接
========

<ul id="lnks">
<li><a href="https://unstablebeagle.bearblog.dev/">比格犬劳动饮酒叹息</a></li>
<li><a href="https://blog.gyara.moe/">岛风造船所</a></li>
<li><a href="https://blog.dctewi.com/">冻葱Tewi</a></li>
<li><a href="https://blog.lycheeee.top/">Lychee’s Blog</a></li>
<li><a href="https://nachtzug.xyz/">Nachtzug</a></li>
<li><a href="https://asaba.sakuragawa.moe/">樱川家::浅羽</a></li>
<li><a href="https://blog.bgme.me/">影子屋</a></li>
<li><a href="https://metanoise.in/">有希书简</a></li>
<li><a href="https://blog.pullopen.xyz/">于光年外遥望</a></li>
<li><a href="https://blog.clickfling.top/">抗性面包</a></li>
<li><a href="https://stella.observer/">Minty</a></li>
<li><a href="https://suzu.dev/">後藤研究所</a></li>
<li><a href="https://qwonsuzune.wordpress.com/">小さな砂の部屋</a></li>
<li><a href="https://noxylva.org/">noxylva</a></li>
<li><a href="https://blog.owo.li/">Fragmenta Iridis</a></li>
<li><a href="https://xiayun.click/">Snake and Snail and Saury</a></li>
<li><a href="https://ioover.net/">读写终子</a></li>
</ul>

<p>失效链接：</p>

<ul>
<li><del><a href="https://coccimore.cyou/">苹果核聚变</a></del></li>
</ul>


<script>
function shuffleArray(array) {
  let currentIndex = array.length,
    randomIndex;

  while (currentIndex !== 0) {
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex--;

    [array[currentIndex], array[randomIndex]] = [
      array[randomIndex],
      array[currentIndex],
    ];
  }

  return array;
}

function shuffleListItems() {
  const ul = document.getElementById('lnks');

  if (!ul) {
    return;
  }

  const listItems = Array.from(ul.children);
  const shuffledItems = shuffleArray(listItems);

  shuffledItems.forEach(item => {
    ul.appendChild(item);
  });
}

shuffleListItems();
</script>
