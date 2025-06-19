const { defineConfig } = require('@vue/cli-service')
module.exports = defineConfig({
  transpileDependencies: true,
  // 添加publicPath配置，适配GitHub Pages部署环境
  publicPath: process.env.NODE_ENV === 'production'
    ? '/vue_blog_demo02/' // 仓库名称，部署到GitHub Pages时需要
    : '/',
  chainWebpack: config => {
    config.module
      .rule('md')
      .test(/\.md$/)
      .use('vue-loader')
      .loader('vue-loader')
      .end()
      .use('vue-markdown-loader')
      .loader('vue-markdown-loader/lib/markdown-compiler')
      .options({
        raw: true
      })
  }
})
