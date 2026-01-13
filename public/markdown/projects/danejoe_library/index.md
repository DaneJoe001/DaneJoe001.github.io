# DaneJoeLibrary - C++ 组件库集合

> 高质量、模块化的 C++20 组件库集合：`logger`、`common`、`database`、`concurrent`、`stringify`、`condition`、`network`

## 项目概述

`DaneJoeLibrary` 是我在日常开发中持续沉淀的一套 C++ 基础设施组件库。我在这里主要强调：

- **模块化（Modular）**：每个组件可独立编译、安装与使用，也可通过聚合包统一接入。
- **工程化（Engineering）**：提供 `Config/Version/Targets`，便于外部项目 `find_package()` 消费。
- **跨平台（Cross-platform）**：统一 C++20，Windows（MSVC）与 Linux（GCC/Clang）均可作为目标平台。

我做这个项目的初衷之一，是把日常开发中反复遇到的“基础能力”沉淀成可复用的组件，并且做到可持续交付：包括 **可复用基础设施（Reusable Infrastructure）**、**稳定交付（Deliverability）**、**CMake 包管理（Package Export）**，以及并发/网络/诊断等底层能力的系统化建设。

## GitHub 链接

🔗 **仓库地址**: https://github.com/DaneJoe001/DaneJoeLibrary

## 组件列表（以源码为准）

- `library/logger/`：日志库（目标 `DaneJoe::Logger`）
- `library/common/`：通用工具（目标 `DaneJoe::Common`）
- `library/database/`：数据库抽象（目标 `DaneJoe::Database`）
- `library/concurrent/`：并发容器/线程池（目标 `DaneJoe::Concurrent`）
- `library/stringify/`：字符串化工具（目标 `DaneJoe::Stringify`）
- `library/condition/`：条件/事件等同步原语封装（目标 `DaneJoe::Condition`）
- `library/network/`：网络组件（目标 `DaneJoe::Network`）

## 组件详解（每个组件做什么）

下面按组件分别说明它们的定位与典型使用方式，便于快速了解整体分层与职责边界。

### 1) DaneJoe::Common

**用途**：通用工具库，承载跨组件复用的基础能力（例如时间、进程、数据类型与辅助工具）。

**典型场景**：

- 为其他组件提供公共类型与工具函数
- 为业务工程提供“轻量但统一”的工具层

**接入方式**：

```cmake
find_package(DaneJoeCommon CONFIG REQUIRED)
target_link_libraries(app PRIVATE DaneJoe::Common)
```

**相关资源**：

- 📌 README（仓库内搜索）: https://github.com/DaneJoe001/DaneJoeLibrary/search?q=library%2Fcommon%2FREADME.md

### 2) DaneJoe::Logger

**用途**：基础日志库，提供同步/异步接口、日志管理器与宏封装。

**典型场景**：

- 服务端/工具程序的日志输出
- 与并发队列结合做异步落盘或异步控制台输出

**接入方式**：

```cmake
find_package(DaneJoeLogger CONFIG REQUIRED)
target_link_libraries(app PRIVATE DaneJoe::Logger)
```

**相关资源**：

- 📌 README（仓库内搜索）: https://github.com/DaneJoe001/DaneJoeLibrary/search?q=library%2Flogger%2FREADME.md

### 3) DaneJoe::Database

**用途**：数据库抽象层（目前内置 SQLite3 驱动），依赖 `DaneJoe::Common`。

**典型场景**：

- 工具类/客户端/服务端的轻量持久化（例如任务记录、传输历史、状态快照等）

**接入方式**：

```cmake
find_package(DaneJoeDatabase CONFIG REQUIRED)
target_link_libraries(app PRIVATE DaneJoe::Database)
```

**相关资源**：

- 📌 README（仓库内搜索）: https://github.com/DaneJoe001/DaneJoeLibrary/search?q=library%2Fdatabase%2FREADME.md

### 4) DaneJoe::Concurrent

**用途**：并发组件（阻塞/无锁队列、线程池等）。当前以头文件库（INTERFACE）的形式提供。

**典型场景**：

- 日志异步队列
- 网络 IO/业务线程之间的 mailbox
- 任务调度、生产者-消费者模型

**接入方式**：

```cmake
find_package(DaneJoeConcurrent CONFIG REQUIRED)
target_link_libraries(app PRIVATE DaneJoe::Concurrent)
```

**相关资源**：

- 📌 README（仓库内搜索）: https://github.com/DaneJoe001/DaneJoeLibrary/search?q=library%2Fconcurrent%2FREADME.md

### 5) DaneJoe::Stringify

**用途**：通用 `to_string` 库，支持 STL 容器等常见类型的字符串化。

**典型场景**：

- 日志/调试输出复杂容器
- 将协议字段、配置结构转为可读文本便于排障

**接入方式**：

```cmake
find_package(DaneJoeStringify CONFIG REQUIRED)
target_link_libraries(app PRIVATE DaneJoe::Stringify)
```

**相关资源**：

- 📌 README（仓库内搜索）: https://github.com/DaneJoe001/DaneJoeLibrary/search?q=library%2Fstringify%2FREADME.md

### 6) DaneJoe::Condition

**用途**：条件/事件等同步原语封装，依赖 `DaneJoe::Common`。

**典型场景**：

- 线程间协调：等待/通知
- 将平台相关同步细节收敛到统一接口，降低业务代码复杂度

**接入方式**：

```cmake
find_package(DaneJoeCondition CONFIG REQUIRED)
target_link_libraries(app PRIVATE DaneJoe::Condition)
```

**相关资源**：

- 📌 README（仓库内搜索）: https://github.com/DaneJoe001/DaneJoeLibrary/search?q=library%2Fcondition%2FREADME.md

### 7) DaneJoe::Network

**用途**：网络组件（序列化/编解码、Socket 抽象、事件循环等），依赖 `DaneJoe::Common`、`DaneJoe::Concurrent`、`DaneJoe::Stringify`。

**典型场景**：

- 自研协议/序列化与组帧
- Reactor/事件循环模型（Linux 侧包含 `posix_*`、`epoll_*` 相关实现）

**接入方式**：

```cmake
find_package(DaneJoeNetwork CONFIG REQUIRED)
target_link_libraries(app PRIVATE DaneJoe::Network)
```

**相关资源**：

- 📌 README（仓库内搜索）: https://github.com/DaneJoe001/DaneJoeLibrary/search?q=library%2Fnetwork%2FREADME.md

## 我在这个项目里做了什么（能力点）

- **可交付的库工程（Deliverable Library）**
  - 提供聚合包 `DaneJoeConfig.cmake` + 版本文件，使外部工程可按组件粒度使用。
  - 对外暴露统一命名空间目标（`DaneJoe::Logger/Common/...`），符合现代 CMake 的消费习惯。

- **模块边界与依赖控制（Modularity & Dependencies）**
  - 组件按职责分目录，避免“巨无霸公共库”。
  - 网络组件明确依赖 `Common/Concurrent/Stringify`（见 `library/network/README.md`）。

- **测试与质量（Testing & Quality）**
  - 各组件提供 GoogleTest + CTest 的单元测试，并以 label（`unit`）组织，便于 CI 过滤运行。

- **跨平台与开发体验（Cross-platform & Developer Experience）**
  - 支持 `CMakePresets.json` 统一管理配置；在支持的生成器下可输出/更新 `compile_commands.json`，便于 IDE/静态分析工具工作。

## 目录结构与分层（从代码角度理解）

```
DaneJoeLibrary/
├── library/                 # 组件源码（in-tree sources）
│   ├── common/
│   ├── concurrent/
│   ├── logger/
│   ├── stringify/
│   ├── condition/
│   ├── database/
│   └── network/
├── cmake/                   # 聚合包与导出配置模板
├── document/                # 组件规范、测试模板等
├── example/                 # 示例工程（可选构建）
└── CMakeLists.txt           # 顶层：选择组件 + 生成聚合包
```

## 工程化交付（Packaging）

### 1) 聚合包的目的

聚合包的核心目标是：

- 外部工程只需要 `find_package(DaneJoe CONFIG REQUIRED COMPONENTS ...)`
- 就能拿到各组件的目标（targets），并且版本可控

这类设计在多项目协作（例如多个业务仓库共享同一套基础设施）时，可以显著降低依赖接入成本。

### 2) 多配置生成器兼容性说明

在 Windows（Visual Studio / Ninja Multi-Config）这类多配置生成器下，如果安装前缀只包含 Debug，而外部工程要链接 Release/RelWithDebInfo，会出现导入目标缺少对应配置的问题。仓库 README 已说明了两条解决思路：

- 安装全部配置（Debug/Release/RelWithDebInfo/MinSizeRel）
- 或在聚合包里做 `MAP_IMPORTED_CONFIG_*` 映射回退

这部分属于非常典型的“工程化坑”，我把它明确记录进文档，便于复用与避免踩坑。

## 构建选项（CMake）

顶层 `CMakeLists.txt` 通过 option 控制是否编译对应组件：

```cmake
option(DANEJOE_BUILD_Logger     "Build Logger component"     ON)
option(DANEJOE_BUILD_Common     "Build Common component"     ON)
option(DANEJOE_BUILD_Database   "Build Database component"   ON)
option(DANEJOE_BUILD_Concurrent "Build Concurrent component" ON)
option(DANEJOE_BUILD_Stringify  "Build Stringify component"  ON)
option(DANEJOE_BUILD_Condition  "Build Condition component"  ON)
option(DANEJOE_BUILD_Network    "Build Network component"    ON)
```

## 关键实现示例：MPMC 有界阻塞队列（Concurrent 组件的一部分）

并发组件里提供了多生产者/多消费者（MPMC）的有界阻塞队列实现（节选自 `library/concurrent/include/danejoe/concurrent/container/mpmc_bounded_queue.hpp`）：

```cpp
template<class T>
class MpmcBoundedQueue
{
public:
    MpmcBoundedQueue(int max_size = 50) : m_max_size(max_size) {}

    std::optional<T> pop()
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        m_empty_cv.wait(lock, [this]()
            {
                return !m_queue.empty() || !m_is_running;
            });
        if (m_queue.empty())
        {
            return std::nullopt;
        }
        T item = std::move(m_queue.front());
        m_queue.pop();
        lock.unlock();
        m_full_cv.notify_one();
        return item;
    }

    std::optional<T> try_pop()
    {
        std::unique_lock<std::mutex> lock(m_mutex);
        if (m_queue.empty())
        {
            return std::nullopt;
        }
        T item = std::move(m_queue.front());
        m_queue.pop();
        lock.unlock();
        m_full_cv.notify_one();
        return item;
    }
};
```

我在这个实现里主要关注：

- `condition_variable` + 谓词（predicate）保证在 **虚假唤醒（spurious wakeup）** 场景下依旧正确。
- `close()` 语义（源码中提供）会唤醒等待线程，确保 shutdown 流程可控。

进一步说，我在这里的设计取舍是：

- **正确性优先**：选择互斥锁 + 条件变量的经典模型，保证语义清晰。
- **可控资源**：通过 max_size 约束队列容量，避免生产者失控导致内存无限增长。
- **可停止（Stoppable）**：`close()` 作为“系统退出”的基础能力，在日志异步写入、网络 IO、线程池任务队列等场景都非常关键。

## 外部项目使用方式

- **安装后聚合接入**：
  - `find_package(DaneJoe CONFIG REQUIRED COMPONENTS Common Logger Database Concurrent Stringify Condition Network)`
  - 然后 `target_link_libraries(app PRIVATE DaneJoe::Logger DaneJoe::Common ...)`
- **精确接入某个组件**：`find_package(DaneJoeLogger CONFIG REQUIRED)` / `find_package(DaneJoeCommon CONFIG REQUIRED)` 等
- **源码联编**：`add_subdirectory(<path-to-repo>)`

## 结构导航（关注点索引）

- **工程化交付**：聚合包、导出 targets、presets、多配置生成器兼容性说明。
- **底层实现**：并发队列、网络协议/组帧、诊断系统等基础设施设计。
- **可维护性**：模块边界、依赖关系、测试结构与规范化文档。

## 相关资源

- 📌 **README**: https://github.com/DaneJoe001/DaneJoeLibrary/blob/main/README.md
- 📌 **组件规范**: https://github.com/DaneJoe001/DaneJoeLibrary/blob/main/document/COMPONENT_RULE.md

---

**技术栈标签**: `C++20` `CMake` `基础库` `并发编程` `模块化` `跨平台`
