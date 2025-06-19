<template>
  <div id="app" class="app-container">
    <Sidebar @content-selected="updateContent" @sidebar-toggle="updateSidebarState" :ref="'sidebar'" :is-open="isSidebarOpen" />
    <button v-if="isMobileView" class="mobile-menu-button" @click="toggleMobileSidebar">
      <i :class="isSidebarOpen ? 'fa fa-times' : 'fa fa-bars'"></i>
    </button>
    <Content :category="selectedCategory" :content="selectedContent" :isSidebarCollapsed="isSidebarCollapsed" />
  </div>
</template>

<script>
import Sidebar from './components/Sidebar.vue'
import Content from './components/Content.vue'

export default {
  name: 'App',
  components: {
    Sidebar,
    Content
  },
  data() {
    return {
      selectedCategory: 'home',
      selectedContent: 'home',
      isSidebarCollapsed: false,
      isSidebarOpen: false,
      isMobileView: false,
      windowWidth: window.innerWidth
    }
  },
  methods: {
    updateContent(data) {
      this.selectedCategory = data.category;
      this.selectedContent = data.content;
      // 移动端视图下，选择内容后自动关闭侧边栏
      if (this.isMobileView) {
        this.isSidebarOpen = false;
      }
    },
    updateSidebarState(isCollapsed) {
      this.isSidebarCollapsed = isCollapsed;
    },
    toggleMobileSidebar() {
      this.isSidebarOpen = !this.isSidebarOpen;
    },
    handleResize() {
      this.windowWidth = window.innerWidth;
      this.checkMobileView();
    },
    checkMobileView() {
      this.isMobileView = this.windowWidth <= 768;
      // 如果不是移动端视图，确保侧边栏状态正常
      if (!this.isMobileView) {
        this.isSidebarOpen = false;
      }
    }
  },
  mounted() {
    // 默认添加亮色主题
    document.body.classList.add('light-theme');
    
    // 检测设备视图大小
    this.checkMobileView();
    
    // 添加窗口大小变化监听
    window.addEventListener('resize', this.handleResize);
  },
  beforeUnmount() {
    // 移除窗口大小变化监听
    window.removeEventListener('resize', this.handleResize);
  }
}
</script>

<style>
@import './assets/styles/theme.css';
@import './assets/styles/main.css';
@import './assets/styles/markdown.css';
@import 'font-awesome/css/font-awesome.min.css';

#app {
  font-family: 'Roboto', 'Open Sans', 'PingFang SC', 'Microsoft YaHei', sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  font-size: 14px; /* 减小基本字体大小 */
}

/* 全局链接样式 */
a {
  color: var(--accent-blue);
  text-decoration: none;
  transition: color 0.2s;
}

a:hover {
  color: var(--accent-hover);
}

/* 滚动条美化 */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: var(--bg-secondary);
}

::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: #666;
}
</style>
