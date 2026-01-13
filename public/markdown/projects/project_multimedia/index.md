# ProjectMultimedia - Qt6 + FFmpeg + SDL2 多媒体播放器
 
 > 基于 Qt6 + FFmpeg + SDL2 的本地媒体播放器练手项目（视频渲染 + 音频播放 + A/V 同步与背压）
 
 ![](/markdown/assets/projects/project_multimedia/default_open.png)
 
 ## 项目概述
 
 `ProjectMultimedia` 是一个本地多媒体播放器项目，当前支持 GUI 打开本地媒体文件并播放（视频渲染 + 音频播放）。
 
 我在这个项目里的重点不是“能播”，而是围绕工程化与运行时问题做针对性的实践：
 
 - **A/V 同步**：维护 audio clock（微秒）作为视频调度基准
 - **背压（Backpressure）**：通过队列水位控制解码暂停/恢复，避免内存与延迟失控
 - **可观测性（Observability）**：周期性输出 `METRIC` 日志辅助定位帧率、丢帧、队列长度与同步误差
 
 ![](/markdown/assets/projects/project_multimedia/open_file_dialog.png)
 
 ## GitHub 链接
 
 🔗 **仓库地址**: https://github.com/DaneJoe001/ProjectMultimediaPlayer

## 技术栈（以源码为准）

- **C++20 / CMake Presets**
- **Qt6**（Widgets）
- **SDL2**（视频渲染 + 音频 callback）
- **FFmpeg**（解封装/解码 + swresample）

## 我在这个项目里做了什么（能力点）

- **多媒体播放链路的完整闭环**：从文件选择、解封装、解码、缓存、渲染/音频输出到退出清理。
 - **A/V 同步与调度**：以音频时钟作为 master clock，对视频进行“等待/丢帧”阈值控制。
 - **背压（Backpressure）**：通过队列水位控制暂停/恢复解码，避免内存与延迟失控。
 - **可观测性（Observability）**：周期性输出指标（fps/drop/队列长度/同步误差），方便定位卡顿与不同步。
 - **资源生命周期治理（RAII）与退出稳定性**：SDL 资源智能指针封装 + 跨线程 stop 保护，降低崩溃与泄漏概率。
 
 ![](/markdown/assets/projects/project_multimedia/playing.gif)
 
 ## 播放链路与线程模型（从代码视角）
 
 结合项目 README 与源码目录，我把职责拆成 4 条主线：
 
```
UI(QMainWindow)
  -> Decode Service (解封装/解码)
  -> Controller (帧队列缓存 + 定时器调度)
  -> Renderer / Audio (SDL video + SDL audio callback)
```

我不仅跑通了播放链路，还围绕运行时问题（同步、背压、退出路径）补齐了可观测与可调参的工程化治理能力。

## 项目结构（按职责）

（节选自项目 `README.md` 的职责拆分）

- `source/main/widget_main.cpp`：Qt GUI 入口
- `source/service/media_decode_service.cpp`：解码服务与线程管理
- `source/controller/media_controller.cpp`：帧队列缓存 + 定时器调度（A/V 同步）
- `source/audio/sdl_audio_renderer.cpp`：SDL audio callback + PCM 队列
- `source/renderer/sdl_frame_renderer.cpp`：SDL texture/renderer/window 管理与绘制
- `source/view/main_window.cpp`、`source/view/sdl_frame_widget.cpp`：Qt 主窗口与 SDL 渲染承载控件

## 关键实现 1：调度控制器（缓存 + 指标）

控制器维护音视频缓冲，并记录关键指标（节选自 `include/controller/media_controller.hpp`）：

```cpp
class MediaController : public QObject
{
public:
    Q_OBJECT

    MediaController(std::shared_ptr<TimeService> time_service, QObject* parent = nullptr);
    ~MediaController() override;

    void init();
    void stop_audio();
    void stop_video();

signals:
    void renderer_video_frame(SessionFrame frame);
    void renderer_audio_frame(SessionFrame frame);
    void paused_decode(bool is_paused);

private:
    QQueue<SessionFrame> m_video_frames;
    QQueue<SessionFrame> m_audio_frames;

    std::optional<int64_t> m_audio_pts_base_us;

    std::atomic<int64_t> m_metrics_video_rendered = 0;
    std::atomic<int64_t> m_metrics_video_dropped = 0;
    std::atomic<int64_t> m_metrics_diff_max_abs_us = 0;
};
```

这部分对应了我在 README 里强调的两条核心目标：

- 以音频为基准做简单同步（audio clock）。
- 通过指标可视化同步误差与队列状态，方便迭代。

### 真实实现：指标日志（METRIC）

控制器初始化时会注册一个 1s 周期任务，输出 fps/drop/队列长度/同步误差（节选自 `source/controller/media_controller.cpp`）：

```cpp
m_metrics_task_id = DaneJoe::TimerManager::get_instance().add_periodic_task(
    1s,
    [this]()
    {
        int64_t rendered = m_metrics_video_rendered.exchange(0);
        int64_t dropped = m_metrics_video_dropped.exchange(0);
        int64_t diff_sum_us = m_metrics_diff_sum_us.exchange(0);
        int64_t diff_count = m_metrics_diff_count.exchange(0);
        int64_t diff_max_abs_us = m_metrics_diff_max_abs_us.exchange(0);
        int64_t vq_len = m_metrics_video_queue_size.load();
        int64_t aq_len = m_metrics_audio_queue_size.load();

        double avg_ms = 0.0;
        if (diff_count > 0)
        {
            avg_ms = static_cast<double>(diff_sum_us) / static_cast<double>(diff_count) / 1000.0;
        }
        double max_ms = static_cast<double>(diff_max_abs_us) / 1000.0;

        DANEJOE_LOG_INFO(
            "default",
            "METRIC",
            "fps={} drop={} vq={} aq={} av_diff_avg={:.2f}ms av_diff_max={:.2f}ms",
            rendered,
            dropped,
            vq_len,
            aq_len,
            avg_ms,
            max_ms);
    },
    -1);
```

这段设计里我主要强调两点“工程化思维”：

- **可量化**：把“感觉卡顿/不同步”变成可度量的指标。
- **可定位**：通过 `vq/aq` 识别是解码跟不上还是渲染/输出跟不上；通过 `av_diff` 判断同步策略是否过激。

### 真实实现：背压水位（High/Low Watermark）

视频帧队列达到高水位时暂停解码，降到低水位时恢复（同样来自 `media_controller.cpp`）：

```cpp
void MediaController::on_video_frame_ready(SessionFrame frame)
{
    m_video_frames.enqueue(frame);
    if (m_video_frames.size() >= 64)
    {
        emit paused_decode(true);
    }
}

void MediaController::on_video_frame_timer_tick()
{
    // ...
    emit renderer_video_frame(m_video_frames.dequeue());
    if (m_video_frames.size() < 32)
    {
        emit paused_decode(false);
    }
}
```

我需要背压来解决两个播放侧常见问题：

- 避免缓存无限增长导致内存上涨。
- 降低“缓存越来越大导致延迟越来越大”的体验问题。

## 关键实现 2：SDL 渲染器（RAII + 纹理更新）

渲染侧封装了 SDL 资源的智能指针（节选自 `include/renderer/sdl_frame_renderer.hpp`）：

```cpp
struct SDL_window_deleter
{
    void operator()(SDL_Window* window)const;
};

struct SDL_renderer_deleter
{
    void operator()(SDL_Renderer* renderer)const;
};

struct SDL_texture_deleter
{
    void operator()(SDL_Texture* texture)const;
};

using SDL_window_ptr = std::unique_ptr<SDL_Window, SDL_window_deleter>;
using SDL_renderer_ptr = std::unique_ptr<SDL_Renderer, SDL_renderer_deleter>;
using SDL_texture_ptr = std::unique_ptr<SDL_Texture, SDL_texture_deleter>;

class SDLFrameRenderer : public IFrameRenderer
{
public:
    bool init() override;
    bool draw(AVFramePtr frame)override;

private:
    SDL_window_ptr m_window = nullptr;
    SDL_renderer_ptr m_renderer = nullptr;
    SDL_texture_ptr m_texture = nullptr;
};
```

在多媒体项目里，资源生命周期与线程退出路径往往是 bug 的主要来源之一，我在这里通过 RAII 让清理行为更稳定。

## A/V 同步策略（基于真实代码的取舍说明）

播放器的同步本质是：**让视频的展示时间跟随音频播放进度**。在 `MediaController::on_video_frame_timer_tick()` 中，我采用了阈值策略：

- 用 `m_audio_pts_base_us` 做首帧 PTS 基准对齐，避免“音视频首帧基准不一致”导致固定偏移。
- 引入 `AUDIO_OUTPUT_LATENCY_US`（设备输出延迟）与 `VIDEO_LEAD_US`（视频提前量）做经验补偿。
- 当视频明显“超前”时等待；当视频明显“落后”时丢帧追赶。

我选择这种策略主要是因为：

- 实现成本低、可控、便于调参。
- 对常见媒体足够稳定，适合练手项目做成可演示闭环。

## 结构导航（关注点索引）

- **多媒体链路**：解码/渲染/音频 callback 的链路，以及同步策略的落地方式。
- **工程化与稳定性**：背压水位、指标体系（METRIC）、SDL 资源 RAII 与退出路径处理。

## 构建与运行（Windows / MSVC）

项目使用 CMake Presets（示例见 README）：

```powershell
cmake --preset win-msvc-debug
cmake --build --preset win-msvc-debug
```

## 相关资源

- 📌 **README**: https://github.com/DaneJoe001/ProjectMultimediaPlayer
- 📌 **MediaController（仓库内搜索）**: https://github.com/DaneJoe001/ProjectMultimediaPlayer/search?q=media_controller.hpp
- 📌 **SDLFrameRenderer（仓库内搜索）**: https://github.com/DaneJoe001/ProjectMultimediaPlayer/search?q=sdl_frame_renderer.hpp

---

**技术栈标签**: `C++20` `Qt6` `FFmpeg` `SDL2` `多媒体` `A/V同步` `背压` `CMake`
