import syntaxHighlight from '@11ty/eleventy-plugin-syntaxhighlight';
import 'prismjs/plugins/custom-class/prism-custom-class.js';

export default function (eleventyConfig) {
  eleventyConfig.addPlugin(syntaxHighlight, {
    init: function ({ Prism }) {
      Prism.plugins.customClass.prefix('prism--')
    }
  })
  eleventyConfig.setUseGitIgnore(false)
  eleventyConfig.addPassthroughCopy('CNAME')
  eleventyConfig.addPassthroughCopy({
    'node_modules/@fortawesome/fontawesome-free/webfonts': 'fonts/fontawesome'
  })
  eleventyConfig.setTemplateFormats([
    'html',
    'md',
    'njk',
    'css',
    'jpg',
    'png',
    'map',
    'svg'
  ])
  eleventyConfig.setFrontMatterParsingOptions({
    excerpt: function (file) {
      if (file.data.layout === 'essay' || file.data.layout === 'rails-page') {
        file.excerpt = file.content.split('\n\n')[0]
      }
    }
  })
};
