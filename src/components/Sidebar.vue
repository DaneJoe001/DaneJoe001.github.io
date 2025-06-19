<template>
  <div class="sidebar" :class="{ collapsed: isCollapsed, open: isOpen }">
    <div class="sidebar-header">
      <h3 class="sidebar-title" v-if="!isCollapsed">水漫金山的博客</h3>
      <button class="sidebar-toggle" @click="toggleSidebar">
        <i :class="isCollapsed ? 'fa fa-bars' : 'fa fa-times'"></i>
      </button>
      <button class="theme-toggle" @click="toggleTheme" v-if="!isCollapsed">
        <i :class="isDarkTheme ? 'fa fa-sun-o' : 'fa fa-moon-o'"></i>
      </button>
    </div>
    
    <div class="sidebar-content">
      <div class="menu-item" @click="selectContent('home', 'home')" :class="{ active: activeContent === 'home' }">
        <i class="fa fa-home"></i>
        <span v-if="!isCollapsed">首页</span>
      </div>
      
      <div class="menu-item" @click="toggleSubmenu('notes')" :class="{ active: activeMenu === 'notes' }">
        <i class="fa fa-book"></i>
        <span v-if="!isCollapsed">笔记</span>
        <i v-if="!isCollapsed" class="fa fa-angle-down" style="margin-left: auto" :class="{ 'fa-angle-up': openSubmenus.includes('notes') }"></i>
      </div>
      
      <div class="submenu" :class="{ open: openSubmenus.includes('notes') && !isCollapsed }">
        <div class="menu-item" @click="selectContent('notes', 'cpp')" :class="{ active: activeContent === 'cpp' }">
          <i class="fa fa-code"></i>
          <span v-if="!isCollapsed">C++开发笔记</span>
        </div>
        <div class="menu-item" @click="selectContent('notes', 'stm32')" :class="{ active: activeContent === 'stm32' }">
          <i class="fa fa-microchip"></i>
          <span v-if="!isCollapsed">STM32开发笔记</span>
        </div>
        <div class="menu-item" @click="selectContent('notes', 'qt')" :class="{ active: activeContent === 'qt' }">
          <i class="fa fa-window-restore"></i>
          <span v-if="!isCollapsed">Qt开发笔记</span>
        </div>
      </div>
      
      <div class="menu-item" @click="toggleSubmenu('projects')" :class="{ active: activeMenu === 'projects' }">
        <i class="fa fa-folder-open"></i>
        <span v-if="!isCollapsed">项目</span>
        <i v-if="!isCollapsed" class="fa fa-angle-down" style="margin-left: auto" :class="{ 'fa-angle-up': openSubmenus.includes('projects') }"></i>
      </div>
      
      <div class="submenu" :class="{ open: openSubmenus.includes('projects') && !isCollapsed }">
        <div class="menu-item" @click="selectContent('projects', 'wordbox')" :class="{ active: activeContent === 'wordbox' }">
          <i class="fa fa-language"></i>
          <span v-if="!isCollapsed">单词魔盒项目</span>
        </div>
        <div class="menu-item" @click="selectContent('projects', 'doctools')" :class="{ active: activeContent === 'doctools' }">
          <i class="fa fa-file-text"></i>
          <span v-if="!isCollapsed">文档工具项目</span>
        </div>
        <div class="menu-item" @click="selectContent('projects', 'serialtool')" :class="{ active: activeContent === 'serialtool' }">
          <i class="fa fa-terminal"></i>
          <span v-if="!isCollapsed">串口调试工具</span>
        </div>
      </div>
      
      <div class="menu-item" @click="selectContent('about', 'about')" :class="{ active: activeContent === 'about' }">
        <i class="fa fa-user"></i>
        <span v-if="!isCollapsed">关于我</span>
      </div>
    </div>
    
    <div class="sidebar-footer" v-if="!isCollapsed">
      <div class="contact-info">
        <div><i class="fa fa-qq"></i> 2845547447</div>
        <div><i class="fa fa-envelope"></i> 2845547447@qq.com</div>
        <div><i class="fa fa-github"></i> DaneJoe001</div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SidebarMenu',
  props: {
    isOpen: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      isCollapsed: false,
      isDarkTheme: false,
      activeMenu: '',
      activeContent: '',
      openSubmenus: [],
      isMobileView: false
    }
  },
  watch: {
    // 监听外部传入的isOpen属性变化
    isOpen(newVal) {
      if (this.isMobileView) {
        // 在移动端视图下，根据isOpen状态控制侧边栏的显示/隐藏
        document.body.style.overflow = newVal ? 'hidden' : '';
      }
    }
  },
  created() {
    // 检查本地存储中的主题设置
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
      this.isDarkTheme = savedTheme === 'dark';
      this.applyTheme();
    } else {
      // 默认使用亮色主题
      this.isDarkTheme = false;
      this.applyTheme();
    }
    
    // 检测是否为移动设备
    this.checkMobileView();
    window.addEventListener('resize', this.handleResize);
  },
  beforeUnmount() {
    window.removeEventListener('resize', this.handleResize);
  },
  methods: {
    toggleSidebar() {
      // 判断是否为移动端视图
      if (this.isMobileView) {
        // 在移动端视图下，通知父组件切换侧边栏状态
        this.$emit('sidebar-toggle', false);
      } else {
        // 非移动端视图下，切换侧边栏折叠状态
        this.isCollapsed = !this.isCollapsed;
        this.$emit('sidebar-toggle', this.isCollapsed);
      }
    },
    toggleTheme() {
      this.isDarkTheme = !this.isDarkTheme;
      this.applyTheme();
      // 保存主题设置到本地存储
      localStorage.setItem('theme', this.isDarkTheme ? 'dark' : 'light');
    },
    applyTheme() {
      document.body.classList.remove('light-theme', 'dark-theme');
      document.body.classList.add(this.isDarkTheme ? 'dark-theme' : 'light-theme');
    },
    toggleSubmenu(menu) {
      this.activeMenu = menu;
      if (this.openSubmenus.includes(menu)) {
        this.openSubmenus = this.openSubmenus.filter(item => item !== menu);
      } else {
        this.openSubmenus.push(menu);
      }
    },
    selectContent(category, content) {
      this.activeContent = content;
      // 发出事件通知父组件更新内容
      this.$emit('content-selected', { category, content });
    },
    handleResize() {
      this.checkMobileView();
    },
    checkMobileView() {
      const oldMobileView = this.isMobileView;
      this.isMobileView = window.innerWidth <= 768;
      
      // 如果从移动端切换到桌面端，重置侧边栏状态
      if (oldMobileView && !this.isMobileView) {
        this.isCollapsed = false;
        this.$emit('sidebar-toggle', false);
        document.body.style.overflow = '';
      }
    }
  }
}
</script>

<style scoped>
.sidebar {
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow-x: hidden;
}

.sidebar-content {
  flex: 1;
  overflow-y: auto;
  padding: 10px 0;  /* 减少顶部内边距 */
}

.sidebar-footer {
  padding: 15px; /* 减小内边距 */
  border-top: 1px solid var(--border);
  margin-top: auto;
  font-size: 0.9rem; /* 减小字体大小 */
  background-color: rgba(0, 0, 0, 0.02);
}

.contact-info {
  color: var(--text-secondary);
}

.contact-info div {
  margin-bottom: 8px; /* 减小间距 */
  display: flex;
  align-items: center;
}

.contact-info i {
  margin-right: 10px; /* 减小图标间距 */
  width: 15px; /* 减小图标宽度 */
  font-size: 0.95rem; /* 减小图标大小 */
  color: var(--accent-blue);
}

.sidebar-header {
  padding: 15px; /* 减小头部内边距 */
}

.sidebar-title {
  font-size: 1.2rem; /* 减小标题字体 */
}

.menu-item {
  padding: 10px 15px; /* 减小菜单项内边距 */
  font-size: 0.95rem; /* 减小菜单字体大小 */
}

.menu-item i {
  margin-right: 10px; /* 减小图标和文字间距 */
  width: 16px; /* 减小图标宽度 */
  font-size: 1rem; /* 减小图标大小 */
}

.submenu {
  margin-left: 15px; /* 减小子菜单缩进 */
}

/* 为折叠状态下的侧边栏优化图标显示 */
.sidebar.collapsed .menu-item {
  padding: 10px 0;
  justify-content: center;
}

.sidebar.collapsed .menu-item i {
  margin-right: 0;
  font-size: 1.1rem; /* 折叠时减小图标尺寸 */
}

/* 移动端样式 */
@media screen and (max-width: 768px) {
  .sidebar {
    transition: transform 0.3s ease;
  }

  .sidebar.open {
    transform: translateX(0);
    box-shadow: 0 0 15px rgba(0, 0, 0, 0.2);
  }
  
  /* 侧边栏打开时添加背景遮罩 */
  .sidebar.open::after {
    content: '';
    position: fixed;
    top: 0;
    left: 260px; /* 侧边栏宽度 */
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    z-index: -1;
  }
  
  /* 侧边栏打开时禁止滚动主内容区域 */
  .sidebar.open ~ .content {
    overflow: hidden;
  }
}
</style> 