# ProjectTrans - 网络传输 / 协议 / 运行时端到端演示
 
> 自研网络与序列化基础设施之上的 Client/Server 端到端 demo（含 Qt GUI + SQLite 持久化）

![](/markdown/assets/projects/project_trans/client_new_download_dialog.png)

## 项目概述

`ProjectTrans` 是一个以“网络传输/协议/运行时”为核心的个人项目：在自研 C++ 网络与序列化基础设施之上，提供可运行的 Client/Server 演示系统（`client/`、`server/`），用于验证传输、存储与交互能力。

我希望把以下三部分组合成一个可运行的闭环：

- **事件驱动网络（Reactor + epoll）**
- **跨线程解耦（mailbox/eventfd 唤醒）**
- **自定义二进制协议（字段级编码 + 流式组帧）**

![](/markdown/assets/projects/project_trans/echo_test.png)

![](/markdown/assets/projects/project_trans/server_resource_manager_panel.png)

与“只写一个 demo”不同，我在这个项目里刻意把重心放在 **运行时（Runtime）** 与 **边界清晰的基础设施（Infrastructure）** 上：

- IO 线程只做 IO 与事件分发，不做业务。
- 业务线程聚焦协议解码后的业务逻辑与持久化。
- 通过 mailbox 将线程间交互变成“可观测、可控、可限流”的数据通道。

## GitHub 链接

🔗 **仓库地址**: https://github.com/DaneJoe001/ProjectTrans

## 技术栈（以源码为准）

- **C++20 / CMake ≥ 3.20**
- **Qt6**（Core/Gui/Widgets/Sql/Network）
- **POSIX Socket / epoll**（服务端）
- **OpenSSL / SQLite3**

## 我在这个项目里做了什么（能力点）

围绕“可运行闭环 + 可扩展运行时”的目标，我主要做了：

- **系统级网络编程（Linux）**：非阻塞 socket + epoll 事件循环 + ET/按需 EPOLLOUT 的设计意识。
- **并发与线程解耦**：IO/业务线程拆分，通过 mailbox 做跨线程通道，具备可扩展的线程模型。
- **协议设计与实现**：字段级二进制编码 + 组帧器（Frame Assembler），能从字节流稳定恢复消息边界。
- **工程化与可运行闭环**：Client/Server 可运行、可演示；并且包含日志/数据库等“真实系统”必要部件。

![](/markdown/assets/projects/project_trans/finished_download_message_box.png)

## 目录结构

```
ProjectTrans/
├── common/     # 通用基础设施（网络/并发/诊断/日志/数据库/序列化）
├── server/     # 服务端（NetworkRuntime/BusinessRuntime + Qt 面板）
├── client/     # 客户端（Qt Widgets + TransService + 调度控制器）
└── simple_server/  # 早期极简服务端示例（历史参考）
```

## 关键实现 1：epoll 事件循环骨架

服务端 IO 线程由 `PosixEpollEventLoop` 驱动（节选自 `common/include/danejoe/network/event_loop/posix_epoll_event_loop.hpp`）：

```cpp
class PosixEpollEventLoop
{
public:
    PosixEpollEventLoop();

    void init(
        std::shared_ptr<ReactorMailBox> reactor_mail_box,
        std::shared_ptr<PosixEventHandle> event_handle,
        PosixSocketHandle&& server_handle,
        PosixEpollHandle&& epoll_handle);

    void run();
    void stop();
    void notify();

    void readable_event(int fd);
    void writable_event(int fd);
    void acceptable_event();
    void notify_event();

private:
    std::atomic<bool> m_is_running = false;
    std::shared_ptr<ReactorMailBox> m_reactor_mail_box = nullptr;
    std::unordered_map<int, ConnectContext> m_connect_contexts;
};
```

这个类体现了我在这个项目里对“运行时”的拆分思路：

- IO 线程只负责 **accept/读写事件分发**。
- 业务线程通过 mailbox 与 IO 线程解耦，必要时通过 `notify()` 唤醒阻塞的 `epoll_wait`。

### 为什么需要 notify()

当业务线程投递了“待发送帧”到 mailbox，如果 IO 线程正阻塞在 `epoll_wait`，需要一种方式让它立刻醒来去 flush。
因此引入 `PosixEventHandle`（通常基于 eventfd/pipe），并由 mailbox/事件循环配合触发唤醒。

## 关键实现 2：字段级序列化结构

协议侧以字段（Field）为基本单元（节选自 `common/include/danejoe/network/codec/serialize_field.hpp`）：

```cpp
enum class SerializeFieldFlag :uint8_t
{
    None = 0,
    HasValueLength = 1 << 0,
};

template<>
struct enable_bitmask_operator<SerializeFieldFlag> :std::true_type {};

struct SerializeField
{
    uint16_t name_length;
    std::vector<uint8_t> name;
    DataType type;
    SerializeFieldFlag flag;
    uint32_t value_length;
    std::vector<uint8_t> value;

    uint32_t serialized_size()const;
    std::vector<uint8_t> to_serialized_byte_array()const;
    static std::optional<SerializeField> from_serialized_byte_array(const std::vector<uint8_t>& data);
};
```

我选择这种设计主要是因为：

- **可扩展性**：字段类型由 `DataType` 描述，后续扩展复合结构时不需要推翻协议。
- **流式友好**：配合 `FrameAssembler` 可以从 socket 字节流中做组帧。

## 关键实现 3：ReactorMailBox（跨线程通道 + 容量控制）

`ReactorMailBox` 把线程间交互收敛成“投递/弹出帧”的接口（节选自 `common/include/danejoe/network/runtime/reactor_mail_box.hpp`）：

```cpp
class ReactorMailBox
{
public:
    void add_to_client_queue(uint64_t connect_id);
    void remove_to_client_queue(uint64_t connect_id);

    void push_to_client_frame(const PosixFrame& frame);
    void push_to_server_frame(const PosixFrame& frame);
    void push_to_server_frame(const std::vector<PosixFrame>& frame);

    std::optional<PosixFrame> pop_from_to_server_frame();
    std::optional<PosixFrame> try_pop_from_to_server_queue();
    std::optional<PosixFrame> pop_from_to_client_queue(uint64_t connect_id);

    void stop();

private:
    MpmcBoundedQueue<PosixFrame> m_to_server_frame_queue;
    std::unordered_map<uint64_t, std::queue<PosixFrame>> m_to_client_queues;
};
```

这里我主要处理了两个更“工程化”的点：

- **to_server 使用 MPMC 有界队列**：避免 IO 线程持续生产导致内存无限增长。
- **to_client 按连接拆队列**：便于按连接组织发送数据，也为后续实现公平发送/限速预留了空间。

## 关键实现 4：FrameAssembler（从字节流恢复消息边界）

网络读取拿到的是“无边界”的字节流，`FrameAssembler` 负责按协议头累计数据直到得到完整帧（节选自 `common/include/danejoe/network/codec/frame_assembler.hpp`）：

```cpp
class FrameAssembler
{
public:
    void push_data(const std::vector<uint8_t>& data);
    std::vector<uint8_t> pop_data(uint32_t size);
    std::optional<std::vector<uint8_t>> pop_frame();
    void clear_current_frame();

private:
    std::deque<uint8_t> m_buffer;
    std::vector<uint8_t> m_current_frame;
    uint32_t m_current_frame_index = 0;
    DaneJoe::SerializeHeader m_current_header;
    bool m_is_got_header = false;
};
```

这一层是“协议正确性”的关键：

- 把 TCP 的字节流恢复为“完整帧”，业务层才有可靠输入。
- 后续如果引入 checksum/version 校验，也集中在这一层或 `SerializeHeader` 层演进。

## 构建与运行（参考）

依赖：CMake ≥ 3.20、C++20 编译器、Qt6（Core/Gui/Widgets/Sql/Network）、OpenSSL、SQLite3。

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

可执行文件名与路径以 preset/目标为准（见项目 `README.md`）。

## 相关资源

- 📌 **README**: https://github.com/DaneJoe001/ProjectTrans
- 📌 **PosixEpollEventLoop（仓库内搜索）**: https://github.com/DaneJoe001/ProjectTrans/search?q=posix_epoll_event_loop.hpp
- 📌 **SerializeField（仓库内搜索）**: https://github.com/DaneJoe001/ProjectTrans/search?q=serialize_field.hpp

---

## 结构导航（关注点索引）

- **系统/网络底层实现**：reactor/epoll 事件循环、mailbox 解耦、组帧与协议边界处理（`FrameAssembler` + `Serialize*`）。
- **工程化与可运行闭环**：分层（common/server/client）、跨线程通道的容量控制思路、日志/DB 等“真实系统”组件落地。

---

**技术栈标签**: `C++20` `epoll` `网络编程` `序列化协议` `事件驱动` `Qt6` `SQLite` `系统编程`
