#!/bin/sh

make
python3 scripts/sitemap.py

sed -i 's#href="\.\./"#href="//mistivia.com"#g' blog/index.html

git add *
git commit -am "update"
proxychains -q git push

cp homepage/style*.css blog/
cp homepage/style*.css /var/ygg/web/

rsync -avz --delete blog/ root@raye:/volume/webroot/blog/
rsync -avz --delete homepage/ root@raye:/volume/webroot/homepage/
rsync -avz --delete blog/ /var/ygg/web/blog/
sed -i 's#href="//mistivia.com"#href="http://\[200:2829:50f2:e2f1:96e1:3d6d:e107:b39f\]/"#g' /var/ygg/web/blog/index.html
