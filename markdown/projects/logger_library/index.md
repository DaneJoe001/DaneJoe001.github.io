# DaneJoe Logger - 异步日志库

> 轻量级 C++20 异步日志库，基于 std::format

## 项目概述

DaneJoe Logger 是一个现代化的 C++ 异步日志库，提供简洁的 API 和强大的功能。使用 C++20 的 `std::format` 实现零开销的格式化输出，支持异步控制台/文件输出，配合宏定义提供便捷的日志记录方式。

## GitHub 仓库

🔗 **开源地址**: [https://github.com/DaneJoe001/DaneJoeLogger](https://github.com/DaneJoe001/DaneJoeLogger)

[![Stars](https://img.shields.io/github/stars/DaneJoe001/DaneJoeLogger?style=social)](https://github.com/DaneJoe001/DaneJoeLogger)

## 核心特性

### 1. 现代 C++20 设计 ⭐⭐⭐

#### std::format 格式化

```cpp
// 类型安全的格式化，编译期检查
logger->info("main", __FILE__, __FUNCTION__, __LINE__, 
             "User {} logged in, age: {}, score: {:.2f}", 
             "alice", 30, 95.678);

// 输出: [2024-01-15 10:30:45] [INFO] [main] User alice logged in, age: 30, score: 95.68
```

**优势**:
- 编译期格式字符串检查
- 类型安全，不会出现 printf 的类型错误
- 性能优异，零开销抽象
- 支持自定义类型格式化

### 2. 异步输出机制 ⭐⭐⭐

```
┌──────────────┐
│  应用线程     │
│  调用 log()  │
└──────┬───────┘
       │ (非阻塞)
       ▼
┌──────────────┐
│  消息队列     │
│ (无锁队列)   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  后台线程     │
│  写入文件     │
└──────────────┘
```

**特点**:
- 日志调用不阻塞业务线程
- 使用 DaneJoeConcurrent 队列，线程安全
- 控制台和文件分别使用独立队列
- 程序退出时自动等待队列清空

### 3. 灵活的配置系统 ⭐⭐

```cpp
DaneJoe::ILogger::LoggerConfig cfg;
cfg.log_name = "app";
cfg.log_path = "./logs/app.log";
cfg.console_level = LogLevel::DEBUG;   // 控制台显示 DEBUG 及以上
cfg.file_level = LogLevel::INFO;       // 文件记录 INFO 及以上
cfg.enable_console = true;
cfg.enable_file = true;
cfg.enable_async = true;               // 开启异步模式
```

**配置项**:
- 分别控制控制台和文件的日志级别
- 可选的异步/同步模式
- 自定义日志文件路径
- 预留滚动日志、按日切分等扩展点

### 4. 可定制的输出格式 ⭐

```cpp
ILogger::LogOutputSetting out;
out.enable_time = true;           // [2024-01-15 10:30:45]
out.enable_level = true;          // [INFO]
out.enable_module = true;         // [network]
out.enable_file_name = true;      // [main.cpp]
out.enable_function_name = true;  // [process_request]
out.enable_line_num = true;       // [Line:42]
out.enable_thread_id = true;      // [Thread:12345]
out.enable_process_id = true;     // [PID:6789]

logger->set_output_settings(out);
```

**输出示例**:
```
[2024-01-15 10:30:45] [INFO] [network] [main.cpp] [process_request] [Line:42] [Thread:12345] [PID:6789] Request processed successfully
```

### 5. 单例管理器 ⭐

```cpp
// 注册日志器
auto& mgr = ManageLogger::get_instance();
mgr.add_logger("default", config);
mgr.add_logger("network", network_config);

// 获取日志器
auto logger = mgr.get_logger("default");
logger->info("module", __FILE__, __FUNCTION__, __LINE__, "Hello {}", "World");
```

**特点**:
- 全局单例，避免重复创建
- 按名称管理多个日志器
- 支持注册自定义日志器创建器

### 6. 便捷的日志宏 ⭐⭐

```cpp
// 自动填充文件名、函数名、行号
DANEJOE_LOG_TRACE("default", "network", "Connection established");
DANEJOE_LOG_DEBUG("default", "database", "Query executed: {}", sql);
DANEJOE_LOG_INFO("default", "server", "Server started on port {}", 8080);
DANEJOE_LOG_WARN("default", "cache", "Cache miss for key: {}", key);
DANEJOE_LOG_ERROR("default", "file", "Failed to open file: {}", path);
DANEJOE_LOG_FATAL("default", "system", "Out of memory!");
```

## 项目结构

```
library_danejoe_logger/
├── include/
│   ├── logger/
│   │   ├── i_logger.hpp           # 日志接口定义
│   │   ├── async_logger.hpp       # 异步日志实现
│   │   └── logger_manager.hpp     # 日志管理器 + 宏定义
│   ├── util/
│   │   ├── time_util.hpp          # 时间格式化工具
│   │   └── process_util.hpp       # 进程信息工具
│   └── version/
│       └── logger_version.h.in    # 版本信息
├── source/
│   ├── logger/                    # 实现文件
│   ├── util/                      # 工具实现
│   └── test/main.cpp              # 测试示例
├── cmake/
│   ├── danejoe_install_export.cmake
│   └── DaneJoeLoggerConfig.cmake.in
├── CMakeLists.txt
└── README.md
```

## 核心实现

### 1. 日志接口（ILogger）

```cpp
class ILogger {
public:
    enum class LogLevel {
        TRACE, DEBUG, INFO, WARN, ERROR, FATAL
    };
    
    // 模板成员函数，使用 std::format
    template<typename... Args>
    void info(const std::string& module,
              const std::string& file,
              const std::string& function,
              int line,
              std::format_string<Args...> fmt,
              Args&&... args) {
        std::string message = std::format(fmt, std::forward<Args>(args)...);
        log_msg(LogLevel::INFO, module, file, function, line, message);
    }
    
    // 其他级别类似: trace, debug, warn, error, fatal
    
protected:
    virtual void log_msg(LogLevel level, 
                         const std::string& module,
                         const std::string& file,
                         const std::string& function,
                         int line,
                         const std::string& message) = 0;
};
```

### 2. 异步日志实现（AsyncLogger）

```cpp
class AsyncLogger : public ILogger {
private:
    std::unique_ptr<MpmcBoundedQueue<LogMessage>> m_console_queue;
    std::unique_ptr<MpmcBoundedQueue<LogMessage>> m_file_queue;
    std::thread m_console_thread;
    std::thread m_file_thread;
    std::ofstream m_file_stream;
    
    void console_worker() {
        while (true) {
            auto msg = m_console_queue->pop();
            if (!msg) break;  // 队列关闭
            
            std::cout << format_message(*msg) << std::endl;
        }
    }
    
    void file_worker() {
        while (true) {
            auto msg = m_file_queue->pop();
            if (!msg) break;
            
            m_file_stream << format_message(*msg) << std::endl;
        }
    }
    
protected:
    void log_msg(...) override {
        LogMessage msg{level, module, file, function, line, message, get_timestamp()};
        
        if (level >= m_config.console_level && m_config.enable_console) {
            m_console_queue->push(msg);
        }
        
        if (level >= m_config.file_level && m_config.enable_file) {
            m_file_queue->push(msg);
        }
    }
};
```

### 3. 日志宏定义

```cpp
#define DANEJOE_LOG_INFO(log_name, module, fmt, ...) \
    do { \
        auto logger = ManageLogger::get_instance().get_logger(log_name); \
        if (logger) { \
            logger->info(module, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__); \
        } \
    } while(0)

// 其他级别类似: TRACE, DEBUG, WARN, ERROR, FATAL
```

## 使用示例

### 示例1: 基础使用

```cpp
#include "logger/async_logger.hpp"
#include "logger/logger_manager.hpp"

int main() {
    // 1. 配置日志器
    DaneJoe::ILogger::LoggerConfig cfg;
    cfg.log_name = "default";
    cfg.log_path = "./logs/app.log";
    cfg.console_level = DaneJoe::ILogger::LogLevel::TRACE;
    cfg.file_level = DaneJoe::ILogger::LogLevel::INFO;
    cfg.enable_async = true;
    
    // 2. 注册到管理器
    auto& mgr = DaneJoe::ManageLogger::get_instance();
    mgr.add_logger("default", cfg);
    
    // 3. 使用宏记录日志
    DANEJOE_LOG_INFO("default", "main", "Application started");
    DANEJOE_LOG_DEBUG("default", "config", "Config loaded: {}", "app.ini");
    DANEJOE_LOG_ERROR("default", "network", "Connection failed to {}:{}", "192.168.1.1", 8080);
    
    return 0;
}
```

### 示例2: 多日志器

```cpp
// 为不同模块创建独立的日志器
ILogger::LoggerConfig network_cfg;
network_cfg.log_name = "network";
network_cfg.log_path = "./logs/network.log";
network_cfg.file_level = LogLevel::DEBUG;

ILogger::LoggerConfig database_cfg;
database_cfg.log_name = "database";
database_cfg.log_path = "./logs/database.log";
database_cfg.file_level = LogLevel::INFO;

auto& mgr = ManageLogger::get_instance();
mgr.add_logger("network", network_cfg);
mgr.add_logger("database", database_cfg);

// 使用不同的日志器
DANEJOE_LOG_INFO("network", "tcp", "Client connected");
DANEJOE_LOG_INFO("database", "query", "SELECT executed");
```

### 示例3: 自定义输出格式

```cpp
auto logger = mgr.get_logger("default");

ILogger::LogOutputSetting setting;
setting.enable_time = true;
setting.enable_level = true;
setting.enable_module = true;
setting.enable_file_name = false;      // 不显示文件名
setting.enable_function_name = true;
setting.enable_line_num = true;
setting.enable_thread_id = false;      // 不显示线程 ID
setting.enable_process_id = false;

logger->set_output_settings(setting);

// 输出: [2024-01-15 10:30:45] [INFO] [network] [process_request] [Line:42] Message
```

## CMake 集成

### 方式1: FetchContent（推荐）

```cmake
include(FetchContent)

FetchContent_Declare(DaneJoeLogger
    GIT_REPOSITORY https://github.com/DaneJoe001/DaneJoeLogger.git
    GIT_TAG v1.0.0
)
FetchContent_MakeAvailable(DaneJoeLogger)

add_executable(MyApp main.cpp)
target_link_libraries(MyApp PRIVATE danejoe::logger)
```

### 方式2: 子目录

```cmake
add_subdirectory(path/to/library_danejoe_logger)
target_link_libraries(MyApp PRIVATE danejoe::logger)
```

### 方式3: find_package

```bash
# 安装库
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
cmake --install build --prefix /usr/local
```

```cmake
# 使用库
find_package(DaneJoeLogger CONFIG REQUIRED)
target_link_libraries(MyApp PRIVATE danejoe::logger)
```

## API 参考

### 日志级别

```cpp
enum class LogLevel {
    TRACE,   // 最详细的调试信息
    DEBUG,   // 调试信息
    INFO,    // 一般信息
    WARN,    // 警告信息
    ERROR,   // 错误信息
    FATAL    // 致命错误
};
```

### 日志方法

```cpp
template<typename... Args>
void trace(const std::string& module, const std::string& file, 
           const std::string& function, int line,
           std::format_string<Args...> fmt, Args&&... args);

// debug, info, warn, error, fatal 同理
```

### 配置选项

```cpp
struct LoggerConfig {
    std::string log_name;                // 日志器名称
    std::string log_path;                // 日志文件路径
    LogLevel console_level = INFO;       // 控制台级别
    LogLevel file_level = INFO;          // 文件级别
    bool enable_console = true;          // 启用控制台
    bool enable_file = true;             // 启用文件
    bool enable_async = true;            // 启用异步
    
    // 预留选项（暂未实现）
    size_t max_file_size = 10 * 1024 * 1024;   // 单文件最大大小
    size_t max_file_num = 10;                   // 最多保留文件数
    bool use_daily_log = false;                 // 按日切分
    bool enable_backtrace = false;              // 回溯缓冲
    size_t backtrace_size = 100;                // 回溯大小
};
```

## 性能优化

### 1. 异步输出
- 日志调用立即返回，不阻塞业务
- 后台线程批量写入磁盘

### 2. 零拷贝消息传递
- 使用 `std::move` 避免字符串拷贝
- 队列传递轻量级消息结构

### 3. 编译期格式检查
- `std::format` 在编译期检查格式字符串
- 避免运行时格式错误

## 编译要求

- **C++ 标准**: C++20 及以上（需要 std::format）
- **编译器**: 
  - GCC 13+ (GCC 12 需要链接 libfmt)
  - Clang 17+
  - MSVC 2022 (17.4+)
- **平台**: Linux, Windows, macOS

## 测试与验证

```bash
# 启用测试
cmake -B build -DDANEJOE_LOGGER_BUILD_TESTS=ON
cmake --build build -j

# 运行测试
ctest --test-dir build --output-on-failure
```

## 项目特色

### 1. 类型安全
- 使用 `std::format_string<Args...>` 确保编译期检查
- 避免 printf 风格的类型错误

### 2. 现代设计
- 使用 C++20 最新特性
- 智能指针管理资源
- RAII 保证异常安全

### 3. 易于集成
- 现代 CMake，支持多种集成方式
- 命名空间别名 `danejoe::logger`
- 最小依赖（仅依赖 DaneJoeConcurrent）

## 后续规划

- [ ] 实现日志文件滚动（按大小/数量）
- [ ] 支持按日期切分日志文件
- [ ] 添加日志过滤器
- [ ] 支持日志回溯（backtrace）
- [ ] 提供彩色控制台输出
- [ ] 支持 syslog / Windows Event Log

## 技术收获

通过这个项目，我深入掌握了：

1. **C++20 新特性**: std::format, concepts
2. **异步编程**: 消息队列、后台线程
3. **模板元编程**: 可变参数模板、完美转发
4. **宏编程**: 预处理器、宏定义技巧
5. **跨平台开发**: Windows/Linux 平台差异处理

## 相关资源

- 📦 **GitHub**: [DaneJoeLogger](https://github.com/DaneJoe001/DaneJoeLogger)
- 📖 **文档**: [README.md](https://github.com/DaneJoe001/DaneJoeLogger/blob/main/README.md)
- 🧪 **示例代码**: `source/test/main.cpp`
- 🔧 **依赖库**: [DaneJoeConcurrent](https://github.com/DaneJoe001/DaneJoeConcurrent)

---

**技术栈标签**: `C++20` `异步编程` `日志系统` `std::format` `线程安全` `CMake`

**适合岗位**: C++ 开发 / 后端开发 / 系统开发 / 基础库开发

