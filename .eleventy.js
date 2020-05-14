const pluginSass = require("eleventy-plugin-sass");

module.exports = function(eleventyConfig) {
  eleventyConfig.addPassthroughCopy("CNAME");
  eleventyConfig.addPlugin(pluginSass);
  eleventyConfig.setTemplateFormats([
    "html",
    "md",
    "njk",
    "css",
    "ico",
    "jpg"
  ]);
};
