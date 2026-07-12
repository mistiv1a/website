MD_SRC  = $(shell find . -name "*.md" -not -path './task.md')
MD_TARGET  = $(MD_SRC:.md=.html)

PRE_SRC  = $(shell find . -name "*.pre")
PRE_TARGET  = $(PRE_SRC:.pre=.html)

TYP_SRC  = $(shell find . -name '*.typ' -not -path './template.typ' -not -path './template-en.typ')
TYP_HTML_TARGET  = $(TYP_SRC:.typ=.html)

all: rss $(PRE_TARGET) $(MD_TARGET) $(TYP_HTML_TARGET)

clean:
	-rm $(TYP_HTML_TARGET) $(MD_TARGET)

rss: blog/index.xml

blog/index.xml: blog/index.md scripts/genrss.py
	sed -n '6,11p' $< | python scripts/genrss.py > $@

$(MD_TARGET): %.html: %.md scripts/md.py
	python scripts/md.py $< > $@

$(PRE_TARGET): %.html: %.pre
	./text2html $< $@

$(TYP_HTML_TARGET): %.html: %.typ template.typ scripts/typ2html.py
	python scripts/typ2html.py $< $@

.PHONY: rss clean

BLOG_POST_SRC = $(shell find blog/posts -name 'index.typ')
blog/index.md: $(BLOG_POST_SRC) blog/generate-index.py
	python3 blog/generate-index.py
