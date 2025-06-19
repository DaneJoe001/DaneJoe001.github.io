<template>
  <div class="content" :class="{ 'sidebar-collapsed': isSidebarCollapsed, 'toc-collapsed': isTocCollapsed }" :data-category="category">
    <!-- 可折叠的左侧目录 -->
    <div v-if="tableOfContents.length > 0" class="toc-container" :class="{ 'collapsed': isTocCollapsed }">
      <div class="toc-header">
        <span>目录</span>
        <div class="toc-actions">
          <button class="toc-refresh" title="刷新内容" @click="refreshContent">
            <i class="fa fa-refresh"></i>
          </button>
          <button class="toc-toggle" title="折叠/展开目录" @click="toggleToc">
            <i :class="isTocCollapsed ? 'fa fa-indent' : 'fa fa-outdent'"></i>
          </button>
        </div>
      </div>
      <ul class="toc-list" v-if="!isTocCollapsed">
        <li v-for="(item, index) in tableOfContents" :key="index" :class="'toc-level-' + item.level">
          <a :href="'#' + item.id" @click.prevent="scrollToHeading(item.id)">{{ item.text }}</a>
        </li>
      </ul>
    </div>
    
    <!-- 主内容区域 -->
    <div class="content-body markdown-content" v-html="renderedContent" ref="contentBody"></div>
  </div>
</template>

<script>
import { marked } from 'marked';
import Prism from 'prismjs';
import 'prismjs/themes/prism-tomorrow.css';
// 导入额外的语法高亮支持
import 'prismjs/components/prism-c';
import 'prismjs/components/prism-cpp';
import 'prismjs/components/prism-javascript';
import 'prismjs/components/prism-css';
import 'prismjs/components/prism-markup';
// 导入Markdown样式
import '@/assets/styles/markdown.css';

export default {
  name: 'ContentView',
  props: {
    category: {
      type: String,
      required: true
    },
    content: {
      type: String,
      required: true
    },
    isSidebarCollapsed: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      markdownContent: '',
      title: '',
      tableOfContents: [],
      isTocCollapsed: false
    }
  },
  computed: {
    renderedContent() {
      if (!this.markdownContent) return '';
      
      try {
        // 在渲染前提取标题并生成目录
        this.generateTableOfContents();
        
        // 使用marked渲染Markdown内容
        return marked.parse(this.markdownContent);
      } catch (error) {
        console.error('渲染Markdown内容失败:', error);
        return '<p>内容渲染失败: ' + error.message + '</p>';
      }
    }
  },
  watch: {
    category: 'loadContent',
    content: 'loadContent',
    isSidebarCollapsed(newVal) {
      // 侧边栏状态变更时，调整目录位置
      console.log('侧边栏状态变更:', newVal);
      // 当目录存在时，调整其位置
      this.$nextTick(() => {
        if (this.tableOfContents.length > 0) {
          // 调用窗口大小调整方法
          this.handleWindowResize();
        }
      });
    }
  },
  mounted() {
    this.loadContent();
    // 添加滚动事件监听，实现在滚动到指定位置时突出显示对应的目录项
    window.addEventListener('scroll', this.highlightCurrentSection);
    
    // 添加窗口大小变化事件监听
    window.addEventListener('window-resized', this.handleWindowResize);
    
    // 从本地存储中获取目录折叠状态
    const savedTocState = localStorage.getItem('tocCollapsed');
    if (savedTocState) {
      this.isTocCollapsed = savedTocState === 'true';
    }
    
    // 初始化时调整布局
    this.handleWindowResize();
  },
  beforeUnmount() {
    // 组件销毁时移除事件监听
    window.removeEventListener('scroll', this.highlightCurrentSection);
    window.removeEventListener('window-resized', this.handleWindowResize);
  },
  updated() {
    // 在内容更新后应用代码高亮
    this.$nextTick(() => {
      Prism.highlightAll();
      // 为所有标题添加ID
      this.addIdsToHeadings();
      // 检查URL中是否有锚点，如果有则滚动到对应位置
      this.scrollToHashLocation();
      // 强制应用Markdown样式
      this.applyMarkdownStyles();
      // 调整布局，确保目录与内容不重叠
      this.handleWindowResize();
    });
  },
  methods: {
    // 刷新内容
    refreshContent() {
      console.log('刷新内容');
      // 重新加载内容
      this.loadContent();
      // 显示刷新动画
      const refreshBtn = document.querySelector('.toc-refresh i');
      if (refreshBtn) {
        refreshBtn.classList.add('fa-spin');
        setTimeout(() => {
          refreshBtn.classList.remove('fa-spin');
        }, 1000);
      }
    },
    
    // 处理窗口大小变化，调整目录和内容布局
    handleWindowResize() {
      // 获取当前窗口宽度
      const windowWidth = window.innerWidth;
      const tocContainer = document.querySelector('.toc-container');
      const contentBody = document.querySelector('.content-body');
      const contentElement = document.querySelector('.content');
      
      // 定义全局变量，确保在整个方法中可访问
      let contentMaxWidth = 0;
      
      if (!tocContainer || !contentBody || !contentElement) return;
      
      // 根据窗口大小调整目录位置
      if (windowWidth <= 768) {
        // 移动端布局，目录显示在底部，不需要特殊处理
        tocContainer.style.removeProperty('left');
        contentBody.style.removeProperty('width');
        contentBody.style.removeProperty('max-width');
      } else {
        // 桌面布局，需要确保目录不与侧边栏重叠
        const sidebarWidth = this.isSidebarCollapsed ? 60 : 240; // 根据侧边栏状态设置宽度
        
        // 计算目录的位置
        tocContainer.style.left = ''; // 移除左边界设置，使用right属性定位
        tocContainer.style.right = '0'; // 确保目录始终靠右
        
        // 防止目录与内容重叠的关键步骤：调整内容区域的宽度
        const tocWidth = this.isTocCollapsed ? 35 : 180;
        
        // 计算内容区域宽度，考虑侧边栏和目录宽度，确保内容与目录之间有足够空间
        const availableWidth = windowWidth - sidebarWidth; // 可用宽度（不包括侧边栏）
        contentMaxWidth = availableWidth - tocWidth; // 更新全局变量的值
        
        // 设置内容区域样式
        contentBody.style.maxWidth = `${contentMaxWidth}px`;
        contentBody.style.width = `${contentMaxWidth}px`;
        contentBody.style.marginRight = `${tocWidth + 5}px`; // 添加5px额外间距
        
        // 调整内容容器宽度
        contentElement.style.width = '100%';
        contentElement.style.maxWidth = '100%';
      }
      
      // 确保在笔记内容页面目录正常显示
      if (this.category === 'notes') {
        // 笔记页面可能需要额外处理
        console.log('处理笔记页面布局调整');
        
        // 强制目录使用绝对定位，不受页面布局影响
        tocContainer.style.position = 'fixed';
        tocContainer.style.zIndex = '15';  // 确保目录在上层显示
        
        // 仅针对笔记页面的额外处理
        const extraPadding = 20; // 额外右侧内边距
        
        // 使用已有的contentMaxWidth变量，根据屏幕大小调整
        if (windowWidth > 1200) {
          // 大屏幕
          const adjustedWidth = contentMaxWidth - extraPadding;
          contentBody.style.maxWidth = `${adjustedWidth}px`;
          contentBody.style.width = `${adjustedWidth}px`;
        } else {
          // 中小屏幕，减少内容宽度，确保不重叠
          const adjustedWidth = contentMaxWidth - extraPadding * 2;
          contentBody.style.maxWidth = `${adjustedWidth}px`;
          contentBody.style.width = `${adjustedWidth}px`;
        }
      }
    },
    
    // 切换目录折叠状态
    toggleToc() {
      this.isTocCollapsed = !this.isTocCollapsed;
      // 保存目录折叠状态到本地存储
      localStorage.setItem('tocCollapsed', this.isTocCollapsed);
      // 调整布局
      this.$nextTick(() => {
        this.handleWindowResize();
      });
    },
    
    // 为渲染后的HTML标题添加ID
    addIdsToHeadings() {
      if (!this.$refs.contentBody) return;
      
      // 获取所有标题元素
      const headings = this.$refs.contentBody.querySelectorAll('h1, h2, h3, h4, h5, h6');
      
      // 为每个标题添加ID
      headings.forEach(heading => {
        const text = heading.textContent;
        const id = text.toLowerCase()
                      .replace(/[^\u4e00-\u9fa5a-z0-9 -]/g, '')
                      .replace(/\s+/g, '-')
                      .replace(/-+/g, '-');
        
        heading.id = id;
        console.log(`为标题添加ID: "${text}" -> "${id}"`);
      });
      
      // 强制应用样式
      this.applyMarkdownStyles();
    },
    
    // 应用Markdown样式
    applyMarkdownStyles() {
      // 确保代码块样式正确应用
      const codeBlocks = this.$refs.contentBody.querySelectorAll('pre code');
      codeBlocks.forEach(block => {
        block.parentElement.classList.add('code-block');
      });
      
      // 确保表格样式正确应用
      const tables = this.$refs.contentBody.querySelectorAll('table');
      tables.forEach(table => {
        const wrapper = document.createElement('div');
        wrapper.className = 'table-responsive';
        table.parentNode.insertBefore(wrapper, table);
        wrapper.appendChild(table);
      });
      
      // 确保图片样式正确应用
      const images = this.$refs.contentBody.querySelectorAll('img');
      images.forEach(img => {
        img.classList.add('markdown-image');
        img.onerror = () => {
          img.classList.add('image-error');
          img.alt = '图片加载失败';
        };
      });
    },
    
    // 检查URL中的锚点并滚动到对应位置
    scrollToHashLocation() {
      const hash = window.location.hash;
      if (hash && hash.length > 1) {
        const id = hash.substring(1);
        console.log('URL中检测到锚点:', id);
        this.scrollToHeading(id);
      }
    },
    
    // 高亮当前可见的部分对应的目录项
    highlightCurrentSection() {
      // 如果没有目录，则不执行操作
      if (this.tableOfContents.length === 0) return;
      
      // 获取所有标题元素
      const headings = Array.from(document.querySelectorAll('.markdown-content h1, .markdown-content h2, .markdown-content h3, .markdown-content h4, .markdown-content h5, .markdown-content h6'));
      
      // 如果没有标题元素，则不执行操作
      if (headings.length === 0) return;
      
      // 找到当前可见的标题
      const scrollPosition = window.scrollY;
      let currentHeadingId = null;
      
      // 计算视口顶部位置，考虑一个偏移量以提前激活标题
      const scrollOffset = 100;
      
      for (let i = 0; i < headings.length; i++) {
        const heading = headings[i];
        const nextHeading = headings[i + 1];
        
        // 获取当前标题的位置
        const headingTop = heading.offsetTop - scrollOffset;
        
        // 如果下一个标题存在，则检查当前滚动位置是否在当前标题和下一个标题之间
        if (nextHeading) {
          const nextHeadingTop = nextHeading.offsetTop - scrollOffset;
          if (scrollPosition >= headingTop && scrollPosition < nextHeadingTop) {
            currentHeadingId = heading.id;
            break;
          }
        } 
        // 如果已经是最后一个标题，则检查当前滚动位置是否在最后一个标题之后
        else if (scrollPosition >= headingTop) {
          currentHeadingId = heading.id;
        }
      }
      
      // 移除所有目录项的活动状态
      const tocLinks = document.querySelectorAll('.toc-list a');
      tocLinks.forEach(link => {
        link.classList.remove('active');
      });
      
      // 如果找到当前标题，则激活对应的目录项
      if (currentHeadingId) {
        const activeLink = document.querySelector(`.toc-list a[href="#${currentHeadingId}"]`);
        if (activeLink) {
          activeLink.classList.add('active');
        }
      }
    },
    
    // 预处理Markdown内容
    preprocessMarkdown(content) {
      try {
        // 保存代码块，避免其中的内容被错误解析
        const codeBlocks = [];
        let processedContent = content.replace(/```([\s\S]*?)```/g, (match) => {
          const placeholder = `CODE_BLOCK_${codeBlocks.length}`;
          codeBlocks.push(match);
          return placeholder;
        });
        
        // 恢复代码块
        processedContent = processedContent.replace(/CODE_BLOCK_(\d+)/g, (match, index) => {
          return codeBlocks[parseInt(index)];
        });
        
        return processedContent;
      } catch (error) {
        console.error('预处理Markdown失败:', error);
        return content;
      }
    },
    
    // 后处理HTML，为标题添加ID
    postprocessHTML(html) {
      try {
        // 为标题添加ID
        return html.replace(/<h([1-6])>(.*?)<\/h\1>/g, (match, level, text) => {
          const id = this.slugify(text.replace(/<[^>]*>/g, '')); // 移除HTML标签后生成ID
          return `<h${level} id="${id}">${text}</h${level}>`;
        });
      } catch (error) {
        console.error('后处理HTML失败:', error);
        return html;
      }
    },
    
    // HTML转义函数
    escapeHtml(unsafe) {
      return unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
    },
    
    // 生成标题ID的函数
    slugify(text) {
      try {
        // 确保输入是字符串
        const str = String(text);
        
        // 调试输出
        console.log(`生成ID前的文本: "${str}"`);
        
        // 规范化字符串：转小写，移除特殊字符，将空格替换为连字符
        const result = str
          .toLowerCase()
          .replace(/[^\u4e00-\u9fa5a-z0-9 -]/g, '') // 保留中文、字母、数字和连字符
          .replace(/\s+/g, '-') // 空格替换为连字符
          .replace(/-+/g, '-') // 避免多个连续连字符
          .replace(/^-+|-+$/g, ''); // 移除开头和结尾的连字符
        
        console.log(`生成的ID: "${result}"`);
        return result || 'section-' + Math.random().toString(36).substr(2, 9); // 确保返回非空ID
      } catch (error) {
        console.error('生成ID时出错:', error);
        return 'section-' + Math.random().toString(36).substr(2, 9); // 生成随机ID作为后备
      }
    },
    
    // 生成目录
    generateTableOfContents() {
      try {
        const toc = [];
        // 使用简单的正则表达式匹配标题
        const headingRegex = /^(#{1,6})\s+(.+)$/gm;
        
        console.log('开始生成目录');
        // 从Markdown内容中提取所有标题
        const content = this.markdownContent;
        const matches = content.matchAll(headingRegex);
        
        // 将匹配结果转换为数组并迭代
        for (const match of Array.from(matches)) {
          const level = match[1].length; // #的数量表示级别
          const text = match[2].trim();  // 标题文本
          const id = text.toLowerCase()
                        .replace(/[^\u4e00-\u9fa5a-z0-9 -]/g, '')
                        .replace(/\s+/g, '-')
                        .replace(/-+/g, '-');
          
          console.log(`目录项: "${text}", 级别: ${level}, ID: "${id}"`);
          toc.push({ level, text, id });
        }
        
        this.tableOfContents = toc;
        console.log(`生成目录完成，共${toc.length}项`);
      } catch (error) {
        console.error('生成目录失败:', error);
        this.tableOfContents = [];
      }
    },
    
    // 滚动到指定标题
    scrollToHeading(id) {
      console.log('尝试滚动到标题ID:', id);
      // 等待DOM更新完成
      this.$nextTick(() => {
        const el = document.getElementById(id);
        if (el) {
          console.log('找到元素，滚动到位置');
          // 使用scrollIntoView滚动
          el.scrollIntoView({ behavior: 'smooth', block: 'start' });
          
          // 添加高亮效果
          el.classList.add('highlight-heading');
          setTimeout(() => {
            el.classList.remove('highlight-heading');
          }, 2000);
        } else {
          console.warn('未找到ID为', id, '的元素');
        }
      });
    },
    
    // 从外部文件加载Markdown内容
    async loadMarkdownFile(filePath) {
      try {
        console.log('尝试加载文件:', filePath);
        // 使用相对路径
        const response = await fetch(filePath);
        if (!response.ok) {
          throw new Error(`无法加载文件: ${filePath}, 状态码: ${response.status}`);
        }
        const content = await response.text();
        console.log('文件加载成功:', filePath);
        return content;
      } catch (error) {
        console.error('加载Markdown文件失败:', error);
        return null;
      }
    },
    
    async loadContent() {
      try {
        // 尝试从文件系统加载内容
        let mdFilePath = null;
        
        if (this.category === 'home' && this.content === 'home') {
          this.title = '首页';
          mdFilePath = '/markdown/home/index.md';
        } else if (this.category === 'about' && this.content === 'about') {
          this.title = '关于我';
          mdFilePath = '/markdown/about/index.md';
        } else if (this.category === 'notes') {
          if (this.content === 'cpp') {
            this.title = 'C++开发笔记';
            mdFilePath = '/markdown/notes/cpp/index.md'; // 恢复使用完整文件
          } else if (this.content === 'stm32') {
            this.title = 'STM32开发笔记';
            mdFilePath = '/markdown/notes/stm32/index.md';
          } else if (this.content === 'qt') {
            this.title = 'Qt开发笔记';
            mdFilePath = '/markdown/notes/qt/index.md';
          }
        } else if (this.category === 'projects') {
          if (this.content === 'wordbox') {
            this.title = '单词魔盒项目';
            mdFilePath = '/markdown/projects/wordbox/index.md';
          } else if (this.content === 'doctools') {
            this.title = '文档工具项目';
            mdFilePath = '/markdown/projects/doctools/index.md';
          } else if (this.content === 'serialtool') {
            this.title = '串口调试工具';
            mdFilePath = '/markdown/projects/serialtool/index.md';
          }
        }
        
        if (mdFilePath) {
          console.log('开始加载文件:', mdFilePath);
          const content = await this.loadMarkdownFile(mdFilePath);
          if (content) {
            console.log('内容已加载, 长度:', content.length);
            this.markdownContent = content;
            // 内容加载后立即调整布局
            this.$nextTick(() => {
              this.handleWindowResize();
            });
            return;
          } else {
            console.warn('加载文件失败:', mdFilePath);
          }
        }
        
        // 如果无法从文件加载，则使用默认内容
        console.log('回退到默认内容');
        this.loadDefaultContent();
      } catch (error) {
        console.error('加载内容失败:', error);
        this.loadDefaultContent();
      }
    },
    
    // 加载默认的硬编码内容（作为备份）
    loadDefaultContent() {
      // 首页内容已经在loadContent方法中通过文件加载，这里只处理文件加载失败的备用内容
      if (this.category === 'home' && this.content === 'home') {
        this.title = '首页';
        this.markdownContent = '# 首页内容加载失败\n\n请稍后重试或联系管理员。';
        return;
      }

      if (this.category === 'about' && this.content === 'about') {
          this.title = '关于我';
          this.markdownContent = `# 关于我

## 个人信息

- **昵称**：水漫金山
- **QQ**：2845547447
- **邮箱**：2845547447@qq.com
- **GitHub**：[DaneJoe001](https://github.com/DaneJoe001)

## 技术栈

- **编程语言**：C/C++
- **嵌入式平台**：STM32, ESP32, Arduino
- **开发工具**：
  - Visual Studio、Qt Creator
  - Keil MDK、STM32CubeIDE
  - Eclipse、CLion
- **技术领域**：
  - 嵌入式系统设计
  - 实时操作系统(FreeRTOS)
  - 设备驱动开发
  - 嵌入式GUI开发(LVGL)
  - 底层通信协议

## 擅长领域

- 嵌入式软件架构设计
- 性能优化与调试
- 低功耗设计
- 硬件接口与通信协议

欢迎访问我的博客，了解更多关于我的项目和技术笔记！
`;
          return;
        }

        // 设置标题和内容
        if (this.category === 'notes') {
          if (this.content === 'cpp') {
            this.title = 'C++开发笔记';
            this.markdownContent = `# C++开发笔记

## 基础知识

### 变量和数据类型

C++提供了多种数据类型，包括：

- **基本数据类型**：
  - 整型：\`int\`, \`short\`, \`long\`, \`long long\`
  - 浮点型：\`float\`, \`double\`, \`long double\`
  - 字符型：\`char\`
  - 布尔型：\`bool\`

- **复合数据类型**：
  - 数组
  - 字符串（\`std::string\`）
  - 结构体（\`struct\`）
  - 类（\`class\`）

### 指针和引用

指针是存储内存地址的变量，而引用是变量的别名。

\`\`\`cpp
int num = 10;
int* ptr = &num;  // 指针
int& ref = num;   // 引用

*ptr = 20;        // 通过指针修改值
ref = 30;         // 通过引用修改值
\`\`\`

## 面向对象编程

### 类和对象

类是C++中实现面向对象编程的基础。

\`\`\`cpp
class Person {
private:
    std::string name;
    int age;
    
public:
    // 构造函数
    Person(const std::string& n, int a) : name(n), age(a) {}
    
    // 成员函数
    void display() const {
        std::cout << "Name: " << name << ", Age: " << age << std::endl;
    }
};

int main() {
    Person person("张三", 25);
    person.display();
    return 0;
}
\`\`\`

### 继承和多态

继承允许一个类继承另一个类的属性和方法，多态允许使用基类指针调用派生类的方法。

\`\`\`cpp
class Animal {
public:
    virtual void makeSound() const {
        std::cout << "Some generic sound" << std::endl;
    }
};

class Dog : public Animal {
public:
    void makeSound() const override {
        std::cout << "Woof!" << std::endl;
    }
};

int main() {
    Animal* animal = new Dog();
    animal->makeSound();  // 输出：Woof!
    delete animal;
    return 0;
}
\`\`\`

## 待续...

更多C++开发笔记将持续更新，敬请期待！`;
          } else if (this.content === 'stm32') {
            this.title = 'STM32开发笔记';
            this.markdownContent = `# STM32开发笔记

## STM32简介

STM32是ST公司推出的基于ARM Cortex-M内核的32位微控制器系列。它具有高性能、低功耗、丰富的外设等特点，广泛应用于工业控制、消费电子、医疗设备等领域。

## 开发环境搭建

### 硬件准备

- STM32开发板（如STM32F103系列）
- ST-Link调试器
- USB线
- 面包板和杜邦线（可选）

### 软件准备

- **IDE选择**：
  - Keil MDK
  - STM32CubeIDE
  - IAR Embedded Workbench

- **工具链**：
  - STM32CubeMX（图形化配置工具）
  - STM32CubeProgrammer（烧录工具）

## 基础外设使用

### GPIO操作

\`\`\`c
// 配置LED引脚为输出模式
GPIO_InitTypeDef GPIO_InitStruct = {0};
GPIO_InitStruct.Pin = GPIO_PIN_5;
GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
GPIO_InitStruct.Pull = GPIO_NOPULL;
GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

// 控制LED
HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);   // 点亮LED
HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET); // 熄灭LED
HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_5);                // 翻转LED状态
\`\`\`

## 待续...

更多STM32开发笔记将持续更新，敬请期待！`;
          } else if (this.content === 'qt') {
            this.title = 'Qt开发笔记';
            this.markdownContent = `# Qt开发笔记

## Qt简介

Qt是一个跨平台的C++应用程序开发框架，由挪威Trolltech公司（现已被Nokia收购，后又被Digia收购）开发。Qt提供了丰富的UI组件、网络、数据库、多媒体等功能模块，使得开发人员能够高效地构建跨平台的GUI应用程序。

## 开发环境搭建

### 安装Qt

1. 访问[Qt官网](https://www.qt.io/download)下载Qt安装包
2. 运行安装程序，选择所需的组件：
   - Qt库和模块
   - Qt Creator IDE
   - 编译器（如MinGW或MSVC）
   - 调试工具

### 创建第一个Qt项目

1. 打开Qt Creator
2. 选择"File" > "New File or Project"
3. 选择"Qt Widgets Application"
4. 填写项目名称和路径
5. 选择构建套件（如Desktop Qt 5.15.2 MinGW 64-bit）
6. 完成项目创建

## 待续...

更多Qt开发笔记将持续更新，敬请期待！`;
          }
        } else if (this.category === 'projects') {
          if (this.content === 'wordbox') {
            this.title = '单词魔盒项目';
            this.markdownContent = `# 单词魔盒项目

## 项目概述

单词魔盒是一个帮助用户高效记忆单词的学习工具，通过科学的记忆曲线算法和多样化的学习模式，使单词记忆更加高效和有趣。

## 核心功能

### 1. 智能记忆系统

基于艾宾浩斯遗忘曲线，系统会根据用户的记忆情况，自动安排复习计划：

- 首次学习后的复习时间点：1天、2天、4天、7天、15天、30天
- 根据用户对单词的掌握程度动态调整复习间隔
- 提供记忆效果分析和学习建议

### 2. 多样化学习模式

提供多种学习模式，满足不同场景的需求：

- **闪卡模式**：快速翻阅单词卡片
- **测试模式**：通过选择题、填空题等形式测试记忆
- **听写模式**：通过语音播放单词，用户输入拼写
- **情境记忆**：将单词放入实际语境中加深理解

## 待续...

更多项目详情将持续更新，敬请期待！`;
          } else if (this.content === 'doctools') {
            this.title = '文档工具项目';
            this.markdownContent = `# 文档工具项目

## 项目概述

文档工具是一个专为开发人员和技术文档编写者设计的多功能文档管理工具。它集成了Markdown编辑、代码高亮、版本控制、团队协作等功能，旨在提高技术文档的编写效率和质量。

## 核心功能

### 1. 多格式文档编辑

- **Markdown编辑器**：支持实时预览和语法高亮
- **代码块高亮**：支持多种编程语言的代码高亮显示
- **数学公式支持**：集成LaTeX公式编辑功能
- **图表绘制**：支持流程图、时序图、甘特图等

### 2. 文档管理系统

- **项目组织**：以项目为单位组织文档，支持多级目录结构
- **标签系统**：通过标签对文档进行分类和快速查找
- **全文搜索**：支持文档内容的全文检索
- **版本历史**：记录文档的修改历史，支持版本比较和回滚

## 待续...

更多项目详情将持续更新，敬请期待！`;
        } else if (this.content === 'serialtool') {
          this.title = '串口调试工具';
          this.markdownContent = `# USART串口通信交互工具

![版本](https://img.shields.io/badge/版本-1.0.0-blue)
![Qt版本](https://img.shields.io/badge/Qt-6.9.1-green)
![C++标准](https://img.shields.io/badge/C++-17-orange)
![平台](https://img.shields.io/badge/平台-Windows-lightgrey)

## 项目简介

这是一个基于Qt框架开发的串口(USART)通信工具，提供友好的图形界面，支持多种串口参数配置，方便进行串口设备的调试和数据交互。本工具适合嵌入式开发人员、硬件工程师和需要与串口设备通信的开发者使用。

项目开发背景源于嵌入式设备开发过程中对简单高效的串口通信工具的需求。虽然市面上已有许多串口调试助手，但往往功能过于复杂或者界面不够友好，因此决定基于Qt框架开发一款轻量级的、功能专注的串口通信工具。

## 功能特点

- **直观的图形界面**：清晰的布局设计，使用户可以轻松操作
- **串口参数配置**：支持配置波特率、数据位、停止位、校验位和流控制
- **实时数据显示**：接收和发送的数据实时显示在文本浏览器中
- **数据发送功能**：支持文本数据编辑和发送
- **端口管理**：自动检测可用串口，支持刷新端口列表
- **数据清除功能**：一键清空输入输出窗口

## 待续...

更多项目详情将持续更新，敬请期待！`;
        }
      }
    }
  }
}
</script>

<style>
/* 确保markdown.css中的样式能够正确应用，移除scoped属性 */
/* 整体内容区布局 */
.content {
  padding-top: 0;
  padding-bottom: 0;
  min-height: 100vh;
  display: flex;
  position: relative;
  box-sizing: border-box;
  width: 100%;
}

/* 右侧目录样式，类似左侧菜单栏 */
.toc-container {
  position: fixed;
  top: 0;
  right: 0;
  width: 180px; /* 减小目录宽度 */
  height: 100vh;
  background-color: var(--bg-secondary);
  box-shadow: var(--shadow);
  border-left: 1px solid var(--border);
  overflow-y: auto;
  z-index: 10;
  padding-top: 15px; /* 减小顶部内边距 */
  transition: all 0.3s ease;
  /* 保证目录不会与左侧菜单重叠 - 去除left:auto */
}

/* 折叠时的目录样式 */
.toc-container.collapsed {
  width: 35px; /* 减小折叠时的宽度 */
  overflow: hidden;
}

/* 主内容区域样式 */
.content-body {
  flex: 1;
  padding: 15px 20px 15px 25px; /* 减小内边距 */
  margin-right: 180px; /* 与目录宽度一致 */
  transition: all 0.3s ease;
  max-width: calc(100% - 180px); /* 确保内容不会超出可见区域 */
  box-sizing: border-box; /* 确保padding包含在宽度内 */
  overflow-wrap: break-word; /* 确保长文本会换行 */
  word-wrap: break-word;
  position: relative; /* 添加相对定位 */
}

/* 当目录折叠时调整内容区域 */
.toc-collapsed .content-body {
  margin-right: 35px; /* 与折叠后目录宽度一致 */
  max-width: calc(100% - 35px);
  width: calc(100% - 35px);
}

/* 当侧边栏折叠时调整内容区域 */
.sidebar-collapsed .content-body {
  max-width: calc(100% - 240px); /* 60px侧边栏 + 180px目录 */
  width: calc(100% - 240px);
}

/* 当侧边栏和目录都折叠时 */
.sidebar-collapsed.toc-collapsed .content-body {
  max-width: calc(100% - 95px); /* 60px侧边栏 + 35px目录 */
  width: calc(100% - 95px);
}

/* 目录标题样式 */
.toc-header {
  font-size: 1rem;
  font-weight: 600;
  margin-bottom: 8px;
  padding: 0 8px 8px 8px; /* 减小内边距 */
  border-bottom: 1px solid var(--border);
  color: var(--text-primary);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* 目录操作按钮容器 */
.toc-actions {
  display: flex;
  align-items: center;
}

/* 折叠按钮样式 */
.toc-toggle, .toc-refresh {
  background: none;
  border: none;
  color: var(--text-primary);
  cursor: pointer;
  font-size: 0.9rem; /* 减小字体大小 */
  padding: 3px;
  border-radius: 3px;
  margin-left: 3px;
}

.toc-toggle:hover, .toc-refresh:hover {
  background-color: rgba(0, 0, 0, 0.05);
  color: var(--accent-blue);
}

.toc-container.collapsed .toc-header {
  padding: 8px 0;
  justify-content: center;
}

.toc-container.collapsed .toc-toggle {
  transform: rotate(180deg);
}

/* 目录列表样式 */
.toc-list {
  list-style: none;
  padding: 0 8px; /* 减小内边距 */
  margin: 0;
  max-height: calc(100vh - 50px); /* 确保在高度范围内 */
  overflow-y: auto;
}

/* 目录项样式 */
.toc-list a {
  color: var(--text-secondary);
  text-decoration: none;
  transition: color 0.2s, background-color 0.2s;
  display: block;
  padding: 3px 5px; /* 减小内边距 */
  font-size: 0.8rem; /* 减小字体大小 */
  border-radius: 3px;
  position: relative;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.toc-list a:hover {
  color: var(--accent-blue);
  background-color: rgba(33, 150, 243, 0.05);
}

.toc-list a.active {
  color: var(--accent-blue);
  font-weight: 500;
  background-color: rgba(33, 150, 243, 0.1);
  border-left: 2px solid var(--accent-blue); /* 减小边框宽度 */
  padding-left: 7px;
}

/* 响应式布局调整 */
@media (max-width: 1400px) {
  .toc-container {
    width: 170px;
  }
  
  .content-body {
    margin-right: 170px;
    max-width: calc(100% - 170px);
    width: calc(100% - 170px);
  }
  
  .sidebar-collapsed .content-body {
    max-width: calc(100% - 230px); /* 60px侧边栏 + 170px目录 */
    width: calc(100% - 230px);
  }
  
  .toc-collapsed .content-body {
    margin-right: 35px;
    max-width: calc(100% - 35px);
    width: calc(100% - 35px);
  }
  
  .sidebar-collapsed.toc-collapsed .content-body {
    max-width: calc(100% - 95px); /* 60px侧边栏 + 35px目录 */
    width: calc(100% - 95px);
  }
}

@media (max-width: 1200px) {
  .toc-container {
    width: 160px;
  }
  
  .content-body {
    margin-right: 160px;
    max-width: calc(100% - 160px);
    padding: 15px 15px 15px 20px;
  }
  
  .sidebar-collapsed .content-body {
    max-width: calc(100% - 215px); /* 55px侧边栏 + 160px目录 */
  }
  
  .toc-collapsed .content-body {
    margin-right: 35px;
    max-width: calc(100% - 35px);
  }
  
  .sidebar-collapsed.toc-collapsed .content-body {
    max-width: calc(100% - 90px); /* 55px侧边栏 + 35px目录 */
  }
}

@media (max-width: 992px) {
  .toc-container {
    width: 140px;
  }
  
  .content-body {
    margin-right: 140px;
    max-width: calc(100% - 140px);
    padding: 12px 12px 12px 15px;
  }
  
  .sidebar-collapsed .content-body {
    max-width: calc(100% - 190px); /* 50px侧边栏 + 140px目录 */
  }
  
  .toc-collapsed .content-body {
    margin-right: 35px;
    max-width: calc(100% - 35px);
  }
  
  .sidebar-collapsed.toc-collapsed .content-body {
    max-width: calc(100% - 85px); /* 50px侧边栏 + 35px目录 */
  }
}

@media (max-width: 768px) {
  .content {
    flex-direction: column;
  }
  
  .toc-container {
    position: fixed;
    bottom: 0;
    top: auto;
    left: 0 !important; /* 强制覆盖可能的内联样式 */
    right: 0;
    width: 100%;
    height: auto;
    max-height: 30vh; /* 减小目录高度 */
    border-top: 1px solid var(--border);
    border-left: none;
    z-index: 100;
    padding-top: 0;
  }
  
  .toc-container.collapsed {
    max-height: 30px;
    width: 100%;
  }
  
  .content-body {
    margin-right: 0;
    margin-bottom: 30vh; /* 与目录高度一致 */
    padding: 12px;
    max-width: 100%;
  }
  
  .toc-collapsed .content-body {
    margin-right: 0;
    margin-bottom: 30px;
    max-width: 100%;
  }
  
  .sidebar-collapsed .content-body,
  .sidebar-collapsed.toc-collapsed .content-body {
    max-width: 100%;
  }
  
  .toc-list {
    max-height: calc(30vh - 40px);
    padding: 0 12px;
  }
}

@media (max-width: 480px) {
  .toc-container {
    max-height: 25vh;
  }
  
  .toc-container.collapsed {
    max-height: 25px;
  }
  
  .toc-list {
    max-height: calc(25vh - 35px);
  }
  
  .content-body {
    margin-bottom: 25vh;
    padding: 8px;
  }
  
  .toc-collapsed .content-body {
    margin-bottom: 25px;
  }
}

/* 目录层次样式 */
.toc-level-1 {
  margin-left: 0;
  font-weight: 600;
}

.toc-level-2 {
  margin-left: 5px; /* 减小缩进 */
}

.toc-level-3 {
  margin-left: 10px; /* 减小缩进 */
  font-size: 0.75rem;
}

.toc-level-4 {
  margin-left: 15px; /* 减小缩进 */
  font-size: 0.7rem;
}

.toc-level-5, .toc-level-6 {
  margin-left: 20px; /* 减小缩进 */
  font-size: 0.65rem;
}

.toc-list li {
  margin-bottom: 1px; /* 减小间距 */
  line-height: 1.1;
}

/* 确保markdown内容在目录折叠时正常显示 */
.markdown-content {
  width: 100%;
  overflow-x: auto; /* 防止代码块等内容溢出 */
}

/* 强制处理代码块溢出 */
.markdown-content pre {
  max-width: 100%;
  overflow-x: auto;
}

/* 强制处理表格溢出 */
.markdown-content table {
  max-width: 100%;
  overflow-x: auto;
  display: block;
}

/* 笔记页面特定样式处理 */
.content[data-category="notes"] .markdown-content {
  padding-right: 20px; /* 确保内容与目录有更多间距 */
}

.content[data-category="notes"] .content-body {
  overflow-x: visible; /* 防止内容被隐藏 */
}

/* 使内容区域自适应不同宽度 */
@media (min-width: 1400px) {
  .content[data-category="notes"] .content-body {
    max-width: calc(100% - 250px); /* 桌面大屏幕 */
  }
}

@media (max-width: 1399px) and (min-width: 992px) {
  .content[data-category="notes"] .content-body {
    max-width: calc(100% - 220px); /* 桌面中等屏幕 */
  }
}

@media (max-width: 991px) and (min-width: 769px) {
  .content[data-category="notes"] .content-body {
    max-width: calc(100% - 200px); /* 小屏幕 */
  }
}
</style>