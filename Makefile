clean: 
	rm -rf _site

# we need npx installed for this to run
# npm install -g npx
publish: clean
	npx @11ty/eleventy eleventy --formats=md,png --input=site --output=_site

run:
	npx @11ty/eleventy --formats=md,png --serve --input=site --output=_site

