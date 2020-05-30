clean: 
	rm -rf _site/*

build: clean
	npx @11ty/eleventy eleventy --formats=md,png --input=site --output=_site

run: build
	npx @11ty/eleventy eleventy --serve

publish: build
	find ../thanospapathanasiou.github.io/ -mindepth 1 ! '(' -path '../thanospapathanasiou.github.io/.git/*' -or -name '.git' -or -name 'CNAME' ')' -delete
	cp -a ./_site/. ../thanospapathanasiou.github.io/
