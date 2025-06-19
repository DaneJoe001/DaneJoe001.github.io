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

```bash
# 构建项目
npm run build

# 部署到GitHub Pages
# (需要配置GitHub Pages部署脚本)
```

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
