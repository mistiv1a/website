import re
from datetime import datetime
from datetime import UTC
import sys

base_url = "https://blog.mistivia.com"
feed_title = "Scriptum Mistiviae"
feed_link = "https://blog.mistivia.com"
feed_description = "Mistivia's Blog"

def generate_rss(markdown_content):
    rss_feed_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>{feed_title}</title>
    <link>{feed_link}</link>
    <description>{feed_description}</description>
    <language>zh</language>
    <generator>Python Plain String RSS Generator</generator>
"""

    pattern = re.compile(r'^-\s*(\d{4}-\d{2}-\d{2})\s*\[([^\]]+)\]\(([^)]+)\)')

    for line in markdown_content.splitlines():
        # The index wraps dates in markup (e.g. <span class="pdate">); drop any
        # tags first so the feed does not depend on the index's presentation.
        line = re.sub(r'<[^>]+>', '', line.strip())
        match = pattern.match(line)
        if match:
            date_str, title, path = match.groups()
            try:
                pub_date = datetime.strptime(date_str, '%Y-%m-%d')
                pub_date_gmt = pub_date.strftime("%a, %d %b %Y %H:%M:%S GMT")
            except ValueError:
                pub_date_gmt = datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S GMT")

            full_link = f"{base_url}{path}"
            escaped_title = title.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;").replace("'", "&apos;")
            escaped_description = f"Link to the post: {full_link}".replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;").replace("'", "&apos;")

            rss_feed_xml += f"""
    <item>
      <title>{escaped_title}</title>
      <link>{full_link}</link>
      <description>{escaped_description}</description>
      <guid>{full_link}</guid>
      <pubDate>{pub_date_gmt}</pubDate>"""

            rss_feed_xml += f"""
    </item>
"""
    rss_feed_xml += f"""
  </channel>
</rss>
"""
    return rss_feed_xml


content = sys.stdin.read()
print(generate_rss(content))
