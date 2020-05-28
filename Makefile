clean: 
	rm -rf _site/*

build: clean
	npx @11ty/eleventy eleventy --formats=md,png --input=site --output=_site

run: build
	npx @11ty/eleventy eleventy --serve

publish: build
	rm -rf ../thanospapathanasiou.github.io/*
	cp -a ./_site/. ../thanospapathanasiou.github.io/
