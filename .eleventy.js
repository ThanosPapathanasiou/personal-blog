const htmlmin = require("html-minifier");
const pluginRss = require("@11ty/eleventy-plugin-rss");
const { DateTime } = require("luxon");

module.exports = function(eleventyConfig) {

  eleventyConfig.addPlugin(pluginRss);

  eleventyConfig.addTransform("htmlmin", function(content, outputPath) {
    if( outputPath.endsWith(".html") ) {
      let minified = htmlmin.minify(content, {
        useShortDoctype: true,
        removeComments: true,
        collapseWhitespace: true
      });
      return minified;
    }

    return content;
  });

  eleventyConfig.addPassthroughCopy("site/assets");

  eleventyConfig.addFilter('htmlDateString', (dateObj) => {
    return DateTime.fromJSDate(dateObj, {zone: 'utc'}).toFormat('yyyy-LL-dd');
  });  

  eleventyConfig.addCollection("posts", function(collectionApi) {
    return collectionApi.getFilteredByGlob("site/blog/*/*.md");
  });

  eleventyConfig.setTemplateFormats([
    "md",
    "njk",
    "png"
  ]);

};