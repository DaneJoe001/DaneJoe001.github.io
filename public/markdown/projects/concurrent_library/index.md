# DaneJoe Concurrent - 并发容器库

> 轻量级 C++17 并发容器与组件集合

## 项目概述

DaneJoe Concurrent 是一个精心设计的 C++ 并发容器库，提供线程安全的数据结构和组件。目前实现了完整的多生产者多消费者有界阻塞队列（MPMC Bounded Queue），并预留了无锁容器的扩展位。项目展示了对并发编程、线程同步、内存模型的深刻理解。

## GitHub 仓库

🔗 **开源地址**: [https://github.com/DaneJoe001/DaneJoeConcurrent](https://github.com/DaneJoe001/DaneJoeConcurrent)

[![Stars](https://img.shields.io/github/stars/DaneJoe001/DaneJoeConcurrent?style=social)](https://github.com/DaneJoe001/DaneJoeConcurrent)

## 核心组件

### 1. MPMC Bounded Queue ⭐⭐⭐

完整实现的多生产者/多消费者有界阻塞队列：

```cpp
DaneJoe::Concurrent::Blocking::MpmcBoundedQueue<T>
```

#### 核心特性

✅ **多模式出队**
- `pop()`: 阻塞直到有数据或队列关闭
- `pop_for(duration)`: 超时等待，避免无限阻塞
- `pop_until(time_point)`: 绝对时间等待
- `try_pop()`: 非阻塞，立即返回

✅ **批量操作**
- `push(begin, end)`: 批量入队，容量不足时分批阻塞
- `pop(int n)`: 打包出队，一次取出多个元素
- `try_pop(size_t n)`: 非阻塞批量，尽可能多地返回

✅ **动态容量管理**
- 构造时指定初始容量
- `set_max_size()`: 运行时动态扩容
- 容量不足时自动阻塞，不会丢失数据

✅ **优雅关闭**
- `close()`: 唤醒所有等待的 push/pop 线程
- 关闭后拒绝新的 push 操作
- 允许消费者取完队列中剩余数据

✅ **现代 C++ 设计**
- 支持移动构造/移动赋值
- 禁用拷贝，避免意外的深拷贝
- 异常安全保证

### 2. Lock-Free SPSC Queue (预留)

单生产者/单消费者无锁环形队列（接口占位）：

```cpp
DaneJoe::Concurrent::LockFree::SpscRingQueue<T>  // 接口待完善
```

## 技术实现

### 并发安全机制

```cpp
template<class T>
class MpmcBoundedQueue {
private:
    mutable std::mutex m_mutex;              // 互斥锁
    std::condition_variable m_not_empty;     // 非空条件变量
    std::condition_variable m_not_full;      // 非满条件变量
    std::deque<T> m_queue;                   // 底层容器
    std::size_t m_max_size;                  // 最大容量
    std::atomic<bool> m_running{true};       // 运行状态
    
public:
    bool push(T item) {
        std::unique_lock lock(m_mutex);
        m_not_full.wait(lock, [this] {
            return !m_running || m_queue.size() < m_max_size;
        });
        
        if (!m_running) return false;
        
        m_queue.push_back(std::move(item));
        m_not_empty.notify_one();
        return true;
    }
    
    std::optional<T> pop() {
        std::unique_lock lock(m_mutex);
        m_not_empty.wait(lock, [this] {
            return !m_running || !m_queue.empty();
        });
        
        if (m_queue.empty()) return std::nullopt;
        
        T item = std::move(m_queue.front());
        m_queue.pop_front();
        m_not_full.notify_one();
        return item;
    }
};
```

### 设计要点

#### 1. 条件变量的正确使用

- **虚假唤醒**: 使用 lambda 谓词，自动处理虚假唤醒
- **丢失唤醒**: 先修改状态，后通知条件变量
- **通知策略**: `notify_one()` vs `notify_all()`

#### 2. 关闭语义

```cpp
void close() {
    {
        std::unique_lock lock(m_mutex);
        m_running.store(false);
    }
    m_not_empty.notify_all();  // 唤醒所有 pop 等待
    m_not_full.notify_all();   // 唤醒所有 push 等待
}
```

**关键点**:
- 使用 `std::atomic<bool>` 标记运行状态
- 通知所有等待线程，避免死锁
- 允许消费者取完剩余数据

#### 3. 批量操作的效率优化

```cpp
template<typename It>
bool push(It begin, It end) {
    for (auto it = begin; it != end; ++it) {
        if (!push(*it)) return false;  // 关闭时提前退出
    }
    return true;
}

std::optional<std::vector<T>> pop(int n) {
    std::vector<T> result;
    result.reserve(n);
    
    for (int i = 0; i < n; ++i) {
        auto item = pop();
        if (!item) {
            return result.empty() ? std::nullopt : std::make_optional(result);
        }
        result.push_back(std::move(*item));
    }
    return result;
}
```

## 使用示例

### 示例1: 生产者-消费者模型

```cpp
#include "concurrent/blocking/mpmc_bounded_queue.hpp"
#include <thread>
#include <iostream>

using DaneJoe::Concurrent::Blocking::MpmcBoundedQueue;

int main() {
    MpmcBoundedQueue<int> queue(100);  // 容量 100
    
    // 启动 3 个生产者
    std::vector<std::thread> producers;
    for (int i = 0; i < 3; ++i) {
        producers.emplace_back([&queue, i] {
            for (int j = 0; j < 100; ++j) {
                queue.push(i * 100 + j);
                std::cout << "Producer " << i << " pushed: " << (i * 100 + j) << "\n";
            }
        });
    }
    
    // 启动 2 个消费者
    std::vector<std::thread> consumers;
    for (int i = 0; i < 2; ++i) {
        consumers.emplace_back([&queue, i] {
            while (true) {
                auto item = queue.pop_for(std::chrono::milliseconds(100));
                if (!item && !queue.is_running()) break;
                
                if (item) {
                    std::cout << "Consumer " << i << " popped: " << *item << "\n";
                }
            }
        });
    }
    
    // 等待生产者完成
    for (auto& t : producers) t.join();
    
    // 关闭队列
    queue.close();
    
    // 等待消费者完成
    for (auto& t : consumers) t.join();
    
    return 0;
}
```

### 示例2: 批量处理

```cpp
MpmcBoundedQueue<int> queue(50);

// 批量入队
std::vector<int> data{1, 2, 3, 4, 5};
queue.push(data.begin(), data.end());

// 批量出队
auto items = queue.pop(5);  // 一次取出 5 个
if (items) {
    for (int val : *items) {
        std::cout << val << " ";
    }
}
```

### 示例3: 超时等待

```cpp
MpmcBoundedQueue<std::string> queue(10);

// 超时等待（相对时间）
auto item1 = queue.pop_for(std::chrono::seconds(1));
if (!item1) {
    std::cout << "Timeout after 1 second\n";
}

// 超时等待（绝对时间）
auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(5);
auto item2 = queue.pop_until(deadline);
```

## CMake 集成

### 方式1: FetchContent（推荐）

```cmake
include(FetchContent)

FetchContent_Declare(DaneJoeConcurrent
    GIT_REPOSITORY https://github.com/DaneJoe001/DaneJoeConcurrent.git
    GIT_TAG v1.0.0
)
FetchContent_MakeAvailable(DaneJoeConcurrent)

add_executable(MyApp main.cpp)
target_link_libraries(MyApp PRIVATE danejoe::concurrent)
```

## 基于源码的构建配置要点

- **项目与版本**：`project(DaneJoeConcurrent VERSION 1.0.0 LANGUAGES CXX)`。
- **库目标**：实现目标 `danejoe_concurrent`，对外别名 `danejoe::concurrent`。
- **标准声明**：`target_compile_features(danejoe_concurrent PUBLIC cxx_std_17)`（消费者可用更高标准）。
- **公共头路径**：构建树与安装树分别通过 `BUILD_INTERFACE`/`INSTALL_INTERFACE` 暴露。
- **版本头生成**：`include/version/concurrent_version.h.in` → 生成到构建树 `include/version/concurrent_version.h`。
- **可选项**：`DANEJOE_concurrent_BUILD_TESTS=OFF`（默认）、`BUILD_SHARED_LIBS=OFF`（默认静态）。
- **安装与导出**：使用 `GNUInstallDirs` 与自定义 `danejoe_install_export()` 导出 `DaneJoeConcurrent` 包，命名空间 `danejoe::`，方便 `find_package()`。

### 方式2: 子目录

```cmake
add_subdirectory(path/to/library_danejoe_concurrent)

add_executable(MyApp main.cpp)
target_link_libraries(MyApp PRIVATE danejoe::concurrent)
```

### 方式3: find_package

```bash
# 先安装库
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
cmake --install build --prefix /usr/local
```

```cmake
# 然后在项目中使用
find_package(DaneJoeConcurrent CONFIG REQUIRED)
target_link_libraries(MyApp PRIVATE danejoe::concurrent)
```

## API 参考

### 构造函数

```cpp
MpmcBoundedQueue(int max_size = 50);
```

### 入队操作

```cpp
bool push(T item);                              // 阻塞入队
template<typename It>
bool push(It begin, It end);                    // 批量入队
```

### 出队操作

```cpp
std::optional<T> pop();                         // 阻塞出队
std::optional<T> try_pop();                     // 非阻塞出队
template<class Rep, class Period>
std::optional<T> pop_for(                       // 超时等待
    const std::chrono::duration<Rep, Period>& timeout);
template<class Clock, class Duration>
std::optional<T> pop_until(                     // 等到指定时间
    const std::chrono::time_point<Clock, Duration>& time_point);

std::optional<std::vector<T>> pop(int n);       // 批量出队
std::vector<T> try_pop(std::size_t n);          // 非阻塞批量出队
```

### 查询操作

```cpp
bool empty() const;                             // 是否为空
bool full() const;                              // 是否已满
std::size_t size() const;                       // 当前大小
bool is_running() const;                        // 是否运行中
std::optional<T> front() const;                 // 查看队首（需要 T 可拷贝）
```

### 控制操作

```cpp
void close();                                   // 关闭队列
void set_max_size(std::size_t new_size);        // 动态扩容
std::size_t get_max_size() const;               // 获取最大容量
```

## 性能特点

### 优势
- ✅ 简洁的 API，易于使用
- ✅ 线程安全，无需外部同步
- ✅ 支持超时等待，避免死锁
- ✅ 批量操作，减少锁竞争
- ✅ 动态扩容，灵活适应负载

### 适用场景
- 生产者-消费者模型
- 任务队列 / 线程池
- 日志异步输出
- 事件分发系统

### 性能考虑
- 使用 `std::mutex` + `std::condition_variable`，适合中等并发
- 高并发场景（1000+ 线程）建议使用无锁队列（规划中）
- 批量操作可减少锁开销

## 编译要求

- **C++ 标准**: C++17 及以上
- **编译器**: GCC 7+, Clang 6+, MSVC 2019+
- **平台**: Linux, Windows, macOS

## 测试与验证

```bash
# 启用测试
cmake -B build -DDANEJOE_concurrent_BUILD_TESTS=ON
cmake --build build -j

# 运行测试
ctest --test-dir build --output-on-failure
```

## 项目特色

### 1. 现代 CMake 工程化

- 命名空间别名：`danejoe::concurrent`
- 支持 FetchContent / find_package 多种方式集成
- 导出配置文件，方便其他项目引用

### 2. 清晰的接口设计

- 使用 `std::optional` 表示可能失败的操作
- 返回值语义明确（true/false 表示成功/失败）
- 支持移动语义，避免不必要的拷贝

### 3. 完善的错误处理

- 超时返回 `std::nullopt`
- 队列关闭时优雅退出
- 无异常抛出（除非类型 T 的构造/析构抛出）

## 后续规划

- [ ] 实现无锁 SPSC 队列（单生产者/单消费者）
- [ ] 实现无锁 MPMC 队列（使用 CAS 操作）
- [ ] 添加性能基准测试
- [ ] 提供线程池组件
- [ ] 支持优先级队列

## 技术收获

通过这个项目，我深入掌握了：

1. **并发编程**: 互斥锁、条件变量、原子操作
2. **线程同步**: 避免死锁、虚假唤醒、丢失唤醒
3. **API 设计**: 简洁易用、异常安全、接口抽象
4. **模板编程**: 泛型容器、类型萃取
5. **CMake 工程化**: 现代 CMake、包管理、导出配置

## 相关资源

- 📦 **GitHub**: [DaneJoeConcurrent](https://github.com/DaneJoe001/DaneJoeConcurrent)
- 📖 **文档**: [README.md](https://github.com/DaneJoe001/DaneJoeConcurrent/blob/main/README.md)
- 🧪 **示例代码**: `source/test/main.cpp`

---

**技术栈标签**: `C++17` `并发编程` `线程安全` `条件变量` `生产者消费者` `CMake`

**适合岗位**: C++ 开发 / 后端开发 / 系统开发 / 基础库开发

