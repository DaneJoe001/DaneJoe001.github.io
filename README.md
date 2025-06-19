# Vue个人博客

基于Vue.js和GitHub Pages的个人博客项目，支持Markdown内容渲染、代码高亮和主题切换。

## 功能特点

- **响应式设计**：适配不同屏幕尺寸的设备
- **主题切换**：支持亮色模式和暗色模式
- **Markdown渲染**：使用marked库渲染Markdown内容
- **代码高亮**：使用Prism.js实现代码语法高亮
- **菜单折叠**：支持侧边栏折叠，提供更大的内容显示区域

## 技术栈

- Vue.js 3
- Marked (Markdown渲染)
- Prism.js (代码高亮)
- Font Awesome (图标库)

## 项目结构

```
├── public/                 # 静态资源
├── src/                    # 源代码
│   ├── assets/             # 资源文件
│   │   ├── markdown/       # Markdown内容
│   │   │   ├── notes/      # 笔记内容
│   │   │   └── projects/   # 项目内容
│   │   └── styles/         # 样式文件
│   ├── components/         # Vue组件
│   │   ├── Sidebar.vue     # 侧边栏组件
│   │   └── Content.vue     # 内容区域组件
│   ├── App.vue             # 根组件
│   └── main.js             # 入口文件
├── DEVELOP.md              # 开发文档
├── DEVLOG.md               # 开发日志
└── README.md               # 项目说明
```

## 安装与运行

### 安装依赖

```bash
npm install
```

### 开发模式运行

```bash
npm run serve
```

### 构建生产版本

```bash
npm run build
```

## 部署

项目可以部署到GitHub Pages或其他静态网站托管服务。

### GitHub Pages部署步骤

1. 安装gh-pages包
```bash
npm install gh-pages --save-dev
```

2. 在package.json中添加部署脚本
```json
"scripts": {
  "deploy": "gh-pages -d dist -b main"
}
```

3. 配置vue.config.js中的publicPath
```javascript
publicPath: process.env.NODE_ENV === 'production'
  ? '/' // 个人站点仓库(username.github.io)使用根路径
  : '/',
```

4. 构建并部署
```bash
npm run build
npm run deploy
```

## 框架迁移记录

本博客项目是从旧框架迁移到Vue.js框架的新版本。迁移过程记录如下：

### 开发历史

```
69022a8 - 优化界面布局并修复目录与内容重叠问题
b341c18 - 创建首页Markdown目录并删除HelloWorld组件
f7de7e6 - 优化响应式设计并添加首页功能
b800e44 - 更新README，添加项目说明和使用指南
b610de3 - 添加开发日志，记录项目开发过程和问题解决方案
408a6df - 完成博客基础结构开发，包括侧边栏、内容区域和Markdown渲染
860c760 - 初始化Vue项目
526c04d - init
```

### 迁移注意事项

1. **包名问题**：避免使用中文作为package.json中的name字段，会导致npm错误
2. **路径配置**：针对个人站点仓库(username.github.io)，publicPath应设置为'/'
3. **部署方式**：个人站点需要部署到main分支，而不是gh-pages分支
4. **仓库连接**：如遇到SSH密钥问题，可切换为HTTPS协议连接仓库

## 自定义内容

1. 在`src/assets/markdown/`目录下添加或修改Markdown文件
2. 在`src/components/Sidebar.vue`中更新菜单项
3. 在`src/components/Content.vue`中添加新内容的加载逻辑

## 作者信息

- **昵称**：水漫金山
- **GitHub**：[DaneJoe001](https://github.com/DaneJoe001)
- **邮箱**：2845547447@qq.com

## 许可证

MIT
