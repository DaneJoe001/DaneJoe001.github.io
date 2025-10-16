# 多媒体播放器项目

> 基于 FFmpeg/SDL/Qt6 的跨平台视频播放器

## 项目概述

这是一个功能完善的多媒体播放器项目，采用现代 C++ 技术栈，实现了视频解码、渲染和播放的完整流程。项目展示了对多媒体处理框架的深入理解，以及对 Qt GUI 开发的熟练掌握。

## 技术亮点

### 核心技术栈
- **C++23**: 使用最新 C++ 标准特性
- **FFmpeg**: 视频解码（H.264/H.265 等）
- **SDL2**: 跨平台音视频渲染
- **Qt6**: 现代化的 GUI 界面
- **CMake**: 工程化构建系统

### 架构设计

项目采用分层架构设计，清晰分离各模块职责：

```
┌─────────────────────────────────────────┐
│          UI Layer (Qt6 Widgets)         │
│  MainWindow / OpenGLWidget / SDLWidget  │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│        Renderer Layer (SDL/OpenGL)      │
│   IFrameRenderer / SDLFrameRenderer     │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Codec Layer (FFmpeg)            │
│  AVFormatContext / AVCodecContext       │
└─────────────────────────────────────────┘
```

### 核心特性

1. **智能指针封装 FFmpeg 资源**
   - `AVFormatContextPtr`: 格式上下文智能管理
   - `AVCodecContextPtr`: 编解码器上下文自动释放
   - `AVFramePtr` / `AVPacketPtr`: 内存安全保障
   - RAII 模式确保资源不泄漏

2. **多种渲染方案**
   - **SDL 渲染**: 跨平台硬件加速
   - **OpenGL 渲染**: 自定义着色器处理
   - 统一的 `IFrameRenderer` 接口抽象

3. **YUV 格式处理**
   - 支持 YUV420/YUV422/YUV444 格式
   - 高效的平面数据解析
   - YUV 到 RGB 转换优化

4. **错误处理机制**
   - `AVError` 封装 FFmpeg 错误码
   - 友好的错误信息提示
   - 异常安全保证

## 项目结构

```
cpp_project_multimedia/
├── include/
│   ├── codec/              # FFmpeg 封装
│   │   ├── av_format_context_ptr.hpp
│   │   ├── av_codec_context_ptr.hpp
│   │   ├── av_frame_ptr.hpp
│   │   └── av_packet_ptr.hpp
│   ├── renderer/           # 渲染器接口与实现
│   │   ├── i_frame_renderer.hpp
│   │   └── sdl_frame_renderer.hpp
│   ├── view/               # Qt GUI 组件
│   │   ├── main_window.hpp
│   │   ├── opengl_video_widget.hpp
│   │   └── sdl_video_widget.hpp
│   └── util/               # 工具类
├── source/                 # 实现文件
├── document/
│   └── YUV格式解析.md      # 技术文档
└── CMakeLists.txt
```

## 关键技术细节

### 1. 视频解码流程

```cpp
// 打开视频文件
AVFormatContextPtr format_ctx = open_input(file_path);

// 查找视频流
AVStreamPtr video_stream = find_best_stream(format_ctx, AVMEDIA_TYPE_VIDEO);

// 创建解码器
AVCodecContextPtr codec_ctx = create_decoder(video_stream);

// 解码循环
while (AVPacketPtr packet = read_packet(format_ctx)) {
    if (AVFramePtr frame = decode_frame(codec_ctx, packet)) {
        renderer->render(frame);
    }
}
```

### 2. 内存管理优化

- **零拷贝策略**: 尽可能使用引用和移动语义
- **智能指针**: 自动管理 FFmpeg 资源生命周期
- **对象池**: 复用 Frame 和 Packet 对象

### 3. 渲染性能优化

- **硬件加速**: 使用 SDL 硬件加速渲染器
- **双缓冲**: 避免画面撕裂
- **异步渲染**: UI 与解码分离

## 技术难点与解决方案

### 难点1: FFmpeg 资源管理

**问题**: FFmpeg 资源需要手动释放，容易造成内存泄漏

**解决方案**: 
- 封装智能指针类，使用 RAII 模式
- 自定义 Deleter 调用 FFmpeg 的释放函数
- 支持移动语义，避免不必要的拷贝

```cpp
class AVFormatContextPtr {
    AVFormatContext* m_ctx = nullptr;
    
public:
    ~AVFormatContextPtr() {
        if (m_ctx) avformat_close_input(&m_ctx);
    }
    
    AVFormatContextPtr(AVFormatContextPtr&& other) noexcept
        : m_ctx(std::exchange(other.m_ctx, nullptr)) {}
};
```

### 难点2: YUV 格式转换

**问题**: 不同 YUV 格式（420/422/444）存储方式不同

**解决方案**:
- 详细分析各格式的内存布局
- 编写文档记录解析过程
- 提供统一的格式转换接口

参考文档: [YUV格式解析](./document/YUV格式解析.md)

### 难点3: Qt 与 SDL 集成

**问题**: SDL 窗口与 Qt Widget 集成困难

**解决方案**:
- 使用 `QWidget::createWindowContainer`
- 自定义 `SDLVideoWidget` 继承 QWidget
- 正确处理事件循环和绘制时机

## 依赖管理

项目使用现代 CMake + FetchContent 方式管理依赖：

```cmake
FetchContent_Declare(DaneJoeStringify
    GIT_REPOSITORY https://github.com/DaneJoe001/DaneJoeStringify.git
    GIT_TAG v1.0.0
)

FetchContent_Declare(DaneJoeLogger
    GIT_REPOSITORY https://github.com/DaneJoe001/DaneJoeLogger.git
    GIT_TAG v1.0.0
)
```

## 构建与运行

### 环境要求
- CMake ≥ 3.20
- C++23 兼容编译器（GCC 11+, Clang 14+, MSVC 2022+）
- Qt6 (Core, Gui, Widgets)
- FFmpeg 4.x/5.x
- SDL2

### 构建步骤

```bash
# 配置项目
cmake -B build -DCMAKE_BUILD_TYPE=Release

# 编译
cmake --build build -j

# 运行
./build/cpp_exercise_qt_sdl
```

## 项目演示

### 功能截图
- ✅ 支持常见视频格式（MP4, AVI, MKV 等）
- ✅ 流畅的播放控制（播放/暂停/快进）
- ✅ 现代化的 Qt6 界面
- ✅ 实时性能监控

### 技术指标
- 1080p 视频流畅播放
- CPU 占用优化（< 30%）
- 内存占用稳定（无泄漏）

## 后续优化方向

- [ ] 支持硬件解码（VAAPI/NVDEC）
- [ ] 添加音频播放支持
- [ ] 实现播放列表功能
- [ ] 支持字幕显示
- [ ] 提供截图和录制功能

## 技术收获

通过这个项目，我深入学习并掌握了：

1. **多媒体处理**: FFmpeg API 的使用，视频编解码原理
2. **跨平台开发**: Qt6 GUI 开发，SDL2 渲染
3. **C++ 现代特性**: 智能指针、移动语义、RAII
4. **工程化实践**: CMake 构建系统，依赖管理
5. **性能优化**: 内存管理，渲染优化

## 相关资源

- 📦 **源代码**: 本地项目目录
- 📖 **技术文档**: [YUV格式解析](./document/)
- 🔧 **依赖库**: [DaneJoeLogger](https://github.com/DaneJoe001/DaneJoeLogger) | [DaneJoeStringify](https://github.com/DaneJoe001/DaneJoeStringify)

---

**技术栈标签**: `C++23` `FFmpeg` `SDL2` `Qt6` `CMake` `多媒体处理` `视频播放器`

