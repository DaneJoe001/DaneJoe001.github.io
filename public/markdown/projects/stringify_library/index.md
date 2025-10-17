# DaneJoe Stringify - 字符串化工具库

> 轻量级 C++17 字符串化工具，统一 to_string 接口

## 项目概述

DaneJoe Stringify 是一个精巧的 C++ 字符串化工具库，提供统一的 `to_string` 接口，将常见类型、容器、数组与 `std::pair` 转换为可读字符串。通过模板元编程和类型萃取，自动分派到最合适的转换方法，大大简化了调试和日志输出。

## GitHub 仓库

🔗 **开源地址**: [https://github.com/DaneJoe001/DaneJoeStringify](https://github.com/DaneJoe001/DaneJoeStringify)

*(注: 如果仓库为私有，可以在简历中注明"源码可应要求提供")*

## 核心特性

### 1. 统一的字符串化接口 ⭐⭐⭐

#### 一个函数，处理所有类型

```cpp
#include "stringify/stringify.hpp"

// 基础类型
DaneJoe::to_string(42);              // "42"
DaneJoe::to_string(3.14);            // "3.14"
DaneJoe::to_string(true);            // "true"

// 字符串
DaneJoe::to_string("hello");         // "hello"
DaneJoe::to_string(std::string("world"));  // "world"

// 容器
std::vector<int> v{1, 2, 3};
DaneJoe::to_string(v);               // "[1, 2, 3]"

DaneJoe::to_string(m);               // "[{1:one}, {2:two}]"

// Pair
std::pair<int, std::string> p{7, "seven"};
DaneJoe::to_string(p);               // "{7:seven}"

// 自定义类型（实现 to_string() 成员函数）
struct User {
    std::string name;
    int age;
    std::string to_string() const {
        return "User{" + name + ":" + std::to_string(age) + "}";
    }
};

User u{"alice", 30};
DaneJoe::to_string(u);               // "User{alice:30}"
```

### 2. 智能类型分派 ⭐⭐⭐

库使用模板元编程和类型萃取，自动选择最合适的转换方法：

```
┌─────────────────────────────────────────┐
│         DaneJoe::to_string(obj)         │
└───────────────┬─────────────────────────┘
                │
        ┌───────┴───────┐
        │  类型检测      │
        └───────┬───────┘
                │
    ┌───────────┼───────────┐
    │           │           │
    ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐
│ 成员    │ │ std::  │ │ 可迭代  │
│to_string│ │to_string│ │ 类型   │
└────────┘ └────────┘ └────────┘
    │           │           │
    └───────────┴───────────┘
                │
                ▼
          ┌─────────┐
          │ 字符串   │
          └─────────┘
```

#### 类型检测顺序

1. **字符串类型**: 直接返回
2. **可迭代类型** (有 begin/end): 遍历元素，格式化为 `[a, b, c]`
3. **std::pair**: 格式化为 `{first:second}`
4. **枚举类型**: 显示类型名和底层值
5. **成员 to_string()**: 优先调用成员函数
6. **std::to_string()**: 其次使用标准库函数
7. **类型名占位**: 无法转换时显示 `<No to_string>`

### 3. 容器友好设计 ⭐⭐

#### 自动遍历容器

```cpp
// 标准容器
std::vector<int> vec{1, 2, 3, 4, 5};
DaneJoe::to_string(vec);  // "[1, 2, 3, 4, 5]"

std::set<std::string> set{"apple", "banana", "cherry"};
DaneJoe::to_string(set);  // "[apple, banana, cherry]"

```

#### 指针数组支持

```cpp
int arr[] = {10, 20, 30};
DaneJoe::to_string(arr, 3);  // "[10, 20, 30]"

std::string names[] = {"Alice", "Bob", "Charlie"};
DaneJoe::to_string(names, 3);  // "[Alice, Bob, Charlie]"
```

### 4. 调试友好的宏 ⭐

#### 变量名转字符串

```cpp
#define VARIABLE_NAME_TO_STRING(x) #x

int count = 42;
std::cout << VARIABLE_NAME_TO_STRING(count) << " = " 
          << DaneJoe::to_string(count) << "\n";
// 输出: count = 42

// 快速调试
#define DEBUG_VAR(x) \
    std::cout << #x << " = " << DaneJoe::to_string(x) << "\n"

std::vector<int> data{1, 2, 3};
DEBUG_VAR(data);  // 输出: data = [1, 2, 3]
```

### 5. 枚举类型支持 ⭐

```cpp
enum class Color : int { Red = 1, Green = 2, Blue = 3 };

Color c = Color::Green;
DaneJoe::to_string(c);  // "Color<2>" (显示类型名和底层值)
```

## 项目结构

```
library_danejoe_stringify/
├── include/
│   ├── stringify/
│   │   └── stringify.hpp          # 公开头文件（核心实现）
│   └── version/
│       └── stringify_version.h.in # 版本信息
├── source/
│   ├── stringify/
│   │   └── stringify.cpp          # 静态库占位实现
│   └── test/
│       └── main.cpp               # 示例与测试
├── cmake/
│   ├── danejoe_install_export.cmake
│   └── DaneJoeStringifyConfig.cmake.in
├── CMakeLists.txt
└── README.md
```

## 核心实现

### 1. 类型萃取

```cpp
namespace DaneJoe {

// 检测是否有成员 to_string()
template<typename T>
struct has_member_to_string {
private:
    template<typename U>
    static auto test(int) -> decltype(std::declval<U>().to_string(), std::true_type{});
    
    template<typename>
    static std::false_type test(...);
    
public:
    static constexpr bool value = decltype(test<T>(0))::value;
};

// 检测是否可用 std::to_string
template<typename T>
struct has_std_to_string {
private:
    template<typename U>
    static auto test(int) -> decltype(std::to_string(std::declval<U>()), std::true_type{});
    
    template<typename>
    static std::false_type test(...);
    
public:
    static constexpr bool value = decltype(test<T>(0))::value;
};

// 检测是否可迭代
template<typename T>
struct has_iterator {
private:
    template<typename U>
    static auto test(int) -> decltype(std::begin(std::declval<U>()), std::true_type{});
    
    template<typename>
    static std::false_type test(...);
    
public:
    static constexpr bool value = decltype(test<T>(0))::value;
};

}  // namespace DaneJoe
```

### 2. 统一转换接口

```cpp
template<typename T>
std::string to_string(const T& value) {
    // 1. 如果是字符串，直接返回
    if constexpr (std::is_same_v<T, std::string>) {
        return value;
    }
    // 2. 如果可迭代（容器），遍历元素
    else if constexpr (has_iterator<T>::value && !std::is_same_v<T, std::string>) {
        std::string result = "[";
        auto it = std::begin(value);
        auto end = std::end(value);
        if (it != end) {
            result += to_string(*it);
            ++it;
            for (; it != end; ++it) {
                result += ", " + to_string(*it);
            }
        }
        result += "]";
        return result;
    }
    // 3. std::pair 特化
    else if constexpr (is_pair<T>::value) {
        return "{" + to_string(value.first) + ":" + to_string(value.second) + "}";
    }
    // 4. 其他类型使用 try_to_string
    else {
        return try_to_string(value);
    }
}

template<typename T>
std::string try_to_string(const T& obj) {
    // 1. 枚举类型
    if constexpr (std::is_enum_v<T>) {
        return std::string(typeid(T).name()) + "<" + 
               std::to_string(static_cast<std::underlying_type_t<T>>(obj)) + ">";
    }
    // 2. 成员 to_string()
    else if constexpr (has_member_to_string<T>::value) {
        return obj.to_string();
    }
    // 3. std::to_string
    else if constexpr (has_std_to_string<T>::value) {
        return std::to_string(obj);
    }
    // 4. 字符类型
    else if constexpr (std::is_same_v<T, char> || std::is_same_v<T, unsigned char>) {
        return std::string(1, obj);
    }
    // 5. 布尔类型
    else if constexpr (std::is_same_v<T, bool>) {
        return obj ? "true" : "false";
    }
    // 6. 无法转换
    else {
        return std::string(typeid(T).name()) + "<No to_string>";
    }
}
```

## 使用示例

### 示例1: 调试复杂数据结构

```cpp
#include "stringify/stringify.hpp"
#include <iostream>
#include <vector>
#include <map>

struct Person {
    std::string name;
    int age;
    std::vector<std::string> hobbies;
    
    std::string to_string() const {
        return "Person{" + name + ", " + std::to_string(age) + 
               ", hobbies: " + DaneJoe::to_string(hobbies) + "}";
    }
};

int main() {
    std::vector<Person> team{
        {"Alice", 30, {"reading", "coding"}},
        {"Bob", 25, {"gaming", "sports"}},
        {"Charlie", 28, {"music", "travel"}}
    };
    
    std::cout << "Team: " << DaneJoe::to_string(team) << "\n";
    // 输出: Team: [Person{Alice, 30, hobbies: [reading, coding]}, ...]
}
```

### 示例2: 日志输出

```cpp
#define LOG_DEBUG(msg, ...) \
    std::cout << "[DEBUG] " << msg << " " << DaneJoe::to_string(__VA_ARGS__) << "\n"

```

### 示例3: 单元测试辅助

```cpp
template<typename T>
void assert_equal(const T& expected, const T& actual) {
    if (expected != actual) {
        std::cerr << "Assertion failed!\n"
                  << "  Expected: " << DaneJoe::to_string(expected) << "\n"
                  << "  Actual:   " << DaneJoe::to_string(actual) << "\n";
        std::abort();
    }
}

std::vector<int> result = compute();
std::vector<int> expected{1, 2, 3, 4, 5};
assert_equal(expected, result);
```

### 示例4: 网络协议调试

```cpp
struct Packet {
    int id;
    std::string type;
    std::vector<uint8_t> payload;
    
    std::string to_string() const {
        return "Packet{id=" + std::to_string(id) + 
               ", type=" + type + 
               ", payload=" + DaneJoe::to_string(payload) + "}";
    }
};

Packet pkt{123, "DATA", {0x01, 0x02, 0x03}};
LOG_INFO("Received packet: {}", DaneJoe::to_string(pkt));
// 输出: Received packet: Packet{id=123, type=DATA, payload=[1, 2, 3]}
```

## CMake 集成

### 方式1: 仅头文件（最简单）

```cmake
target_include_directories(MyApp PRIVATE path/to/library_danejoe_stringify/include)
```

### 方式2: FetchContent

```cmake
include(FetchContent)

FetchContent_Declare(DaneJoeStringify
    GIT_REPOSITORY https://github.com/DaneJoe001/DaneJoeStringify.git
    GIT_TAG v1.0.0
)
FetchContent_MakeAvailable(DaneJoeStringify)

add_executable(MyApp main.cpp)
target_link_libraries(MyApp PRIVATE danejoe::stringify)
```

### 方式3: 子目录

```cmake
add_subdirectory(path/to/library_danejoe_stringify)
target_link_libraries(MyApp PRIVATE danejoe::stringify)
```

### 方式4: find_package

```bash
# 安装库
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
cmake --install build --prefix /usr/local
```

```cmake
# 使用库
find_package(DaneJoeStringify CONFIG REQUIRED)
target_link_libraries(MyApp PRIVATE danejoe::stringify)
```

## API 参考

### 核心函数

```cpp
// 主转换函数
template<typename T>
std::string to_string(const T& value);

// 指针数组
template<typename T>
std::string to_string(const T* array, std::size_t count = 1);

// 尝试转换
template<typename T>
std::string try_to_string(const T& obj);
```

### 宏

```cpp
// 变量名转字符串
VARIABLE_NAME_TO_STRING(x)  // 展开为 "x"
```

## 支持的类型

### 基础类型
- ✅ 整数类型（int, long, short, char 等）
- ✅ 浮点类型（float, double）
- ✅ 布尔类型（bool）
- ✅ 字符类型（char, unsigned char）
- ✅ 字符串（std::string, const char*）

### 复合类型
- ✅ std::pair<K, V>
- ✅ 枚举类型（显示类型名 + 底层值）

### 容器类型
- ✅ std::vector
- ✅ std::list, std::deque
- ✅ std::set, std::multiset
- ✅ std::unordered_set, std::unordered_multiset
- ✅ std::map, std::multimap
- ✅ std::unordered_map, std::unordered_multimap
- ✅ 任意支持 begin/end 的自定义容器

### 自定义类型
- ✅ 实现了 `to_string()` 成员函数的类
- ✅ 支持 `std::to_string()` 的类型

## 编译要求

- **C++ 标准**: C++17 及以上
- **编译器**: GCC 7+, Clang 6+, MSVC 2019+
- **平台**: Linux, Windows, macOS

## 测试与验证

```bash
# 启用测试
cmake -B build -DDANEJOE_STRINGIFY_BUILD_TESTS=ON
cmake --build build -j

# 运行测试
ctest --test-dir build --output-on-failure
```

## 项目特色

### 1. 零依赖
- 纯头文件实现（可选静态库）
- 仅依赖标准库
- 轻量级，易于集成

### 2. 类型安全
- 编译期类型检查
- SFINAE 技术避免模板错误
- 自动类型推导

### 3. 高扩展性
- 用户类型只需实现 `to_string()` 成员
- 或提供 `std::to_string()` 特化
- 统一接口，一致体验

### 4. 性能优化
- 尽可能使用 `std::move` 避免拷贝
- 预留字符串容量，减少重新分配
- 编译期类型分派，无运行时开销

## 局限性

### 1. 枚举类型显示
- 枚举名称使用 `typeid(T).name()`
- 可能是编译器 mangled 名称
- 建议用户自定义枚举的 `to_string()` 函数

### 2. 字符类型
- `char/unsigned char` 显示为字符
- 若需整数形式，请先转换为 `int`

### 3. 指针类型
- 不支持裸指针转换（除数组）
- 建议使用智能指针并自定义转换

## 使用技巧

### 1. 自定义类型转换

```cpp
struct Complex {
    double real, imag;
    
    std::string to_string() const {
        return std::to_string(real) + (imag >= 0 ? "+" : "") + 
               std::to_string(imag) + "i";
    }
};

Complex c{3.5, -2.1};
DaneJoe::to_string(c);  // "3.5-2.1i"
```

### 2. ADL 友好

```cpp
namespace MyNamespace {
    struct MyType { /*...*/ };
    
    // 在同一命名空间提供 to_string
    std::string to_string(const MyType& obj) {
        // ...
    }
}

MyNamespace::MyType obj;
DaneJoe::to_string(obj);  // 会找到 MyNamespace::to_string
```

### 3. 调试宏封装

```cpp
#define DUMP(x) \
    std::cout << __FILE__ << ":" << __LINE__ << " " \
              << #x << " = " << DaneJoe::to_string(x) << "\n"

int main() {
    std::vector<int> data{1, 2, 3};
    DUMP(data);  // main.cpp:10 data = [1, 2, 3]
}
```

## 后续规划

- [ ] 支持宽字符串（std::wstring）
- [ ] 提供自定义分隔符
- [ ] 支持缩进格式化（多层嵌套）
- [ ] 提供 JSON 风格输出选项
- [ ] 优化大容器的性能

## 技术收获

通过这个项目，我深入掌握了：

1. **模板元编程**: SFINAE, 类型萃取, constexpr if
2. **类型系统**: 类型推导, 完美转发, 类型特性
3. **编译期计算**: 编译期类型检查和分派
4. **API 设计**: 简洁统一的接口，易用性优化
5. **现代 C++**: C++17 特性应用，零开销抽象

## 相关资源

- 📖 **文档**: [README.md](./README.md)
- 🧪 **示例代码**: `source/test/main.cpp`
- 🔗 **GitHub**: [DaneJoeStringify](https://github.com/DaneJoe001/DaneJoeStringify)

## 许可证

本项目以 **MIT** 许可证授权。

---

**技术栈标签**: `C++17` `模板元编程` `类型萃取` `SFINAE` `调试工具` `纯头文件库`

**适合岗位**: C++ 开发 / 基础库开发 / 工具开发

---

## 总结

DaneJoe Stringify 是一个小而美的工具库，解决了 C++ 中字符串化不统一的痛点。通过精巧的模板设计，为各种类型提供了统一的 `to_string` 接口，大大简化了调试和日志输出。项目代码量不大，但充分展示了对 C++ 模板元编程和类型系统的深入理解，是简历中的加分项。

