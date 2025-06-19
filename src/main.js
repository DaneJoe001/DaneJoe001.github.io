import { createApp } from 'vue'
import App from './App.vue'

// 导入样式
import './assets/styles/theme.css'
import './assets/styles/main.css'
import './assets/styles/markdown.css' // 确保正确加载Markdown样式
import 'font-awesome/css/font-awesome.min.css'

// 添加resize事件监听器，用于处理窗口大小变化
window.addEventListener('resize', () => {
  // 触发自定义事件，通知组件窗口大小已改变
  window.dispatchEvent(new CustomEvent('window-resized'));
});

// 创建Vue应用实例
const app = createApp(App)

// 挂载应用
app.mount('#app')
