# OpenAI SDK for MoonBit

[![Build Status](https://img.shields.io/github/actions/workflow/status/0Ayachi0/openai_sdk/ci.yml)](https://github.com/0Ayachi0/openai_sdk/actions) 

[English](README.md) | 简体中文

一个用 MoonBit 语言实现的综合 OpenAI SDK，提供完整的 API 功能和与 Go SDK 兼容的接口设计，支持所有主流 AI 模型功能和使用场景。

## 🚀 核心特性

• 🎯 **核心聊天完成** – 完整的 OpenAI 聊天完成 API 实现  
• 🔧 **多种响应模式** – 支持标准、流式、工具调用和结构化输出  
• 🚀 **高级功能** – 多轮对话和上下文管理  
• 📊 **性能优化** – 高效的 HTTP 请求处理和重试机制  
• 🔄 **错误处理** – 全面的错误检测和恢复机制  
• 🎨 **灵活API** – 与 Go SDK 设计模式兼容的多种接口  
• 📈 **生产就绪** – 完整的配置管理和环境支持  
• 🔍 **类型安全** – 具有健壮类型系统的完整错误类型  
• 📦 **网络集成** – 准备好真实网络库集成  
• 🧪 **测试覆盖** – 全面的测试套件，25个测试全部通过  
• 📚 **文档完善** – 详细的使用示例和 API 参考  

## 📥 安装

```bash
moon add 0Ayachi0/openai_sdk@0.1.0
```

## 🚀 使用指南

### 🔨 基本聊天完成
执行基本的 OpenAI 聊天完成操作。

```moonbit
// 基本对话
let client = new_client("your-api-key")
let response = simple_chat(client, "Say this is a test")
match response {
    Ok(message) => {
        // 处理响应消息
        println("响应: " + message)
    }
    Err(error) => {
        // 处理 API 错误
        let (error_type, message, status_code) = error
        println("错误: " + error_type + " - " + message)
    }
}

// 多轮对话
let messages = [
    system_message("You are a helpful assistant."),
    user_message("Hello"),
    assistant_message("Hi! How can I help you today?"),
    user_message("What's 2+2?")
]
let result = chat_completion(client, messages, GPT_4O)
match result {
    Ok(response) => {
        // 处理聊天完成响应
        let (id, object, created, model, choices, usage) = response
        // 从第一个选择中提取消息
    }
    Err(error) => {
        // 处理完成错误
    }
}
```

### 🎯 高级响应模式
使用不同的响应模式适应各种使用场景。

```moonbit
// 流式响应
let stream_result = stream_chat(client, "Tell me a story about a brave knight")
match stream_result {
    Ok(response) => {
        // 处理流式响应
        println("流式输出: " + response)
    }
    Err(error) => {
        // 处理流式错误
    }
}

// 工具调用
let tools = ["get_weather", "get_time", "calculate"]
let tool_result = tool_chat(client, "What's the weather like in New York?", tools)
match tool_result {
    Ok((message, tool_call)) => {
        // 处理工具响应
        println("消息: " + message)
        match tool_call {
            Some((id, type, function_name, arguments)) => {
                println("调用工具: " + function_name)
                println("参数: " + arguments)
            }
            None => {
                println("未调用工具")
            }
        }
    }
    Err(error) => {
        // 处理工具调用错误
    }
}

// 结构化输出（json_schema，严格校验，禁止额外字段）
let schema = "{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"},\"age\":{\"type\":\"integer\"}},\"required\":[\"name\",\"age\"],\"additionalProperties\":false}"
let format = ("json_schema", schema, "Person")
let struct_result = structured_chat(client, "Extract the name and age from: John is 25 years old.", format)
match struct_result {
    Ok(response) => {
        // 处理结构化响应
        println("结构化数据: " + response)
    }
    Err(error) => {
        // 处理结构化输出错误
    }
}
```

### 🔧 高级客户端配置
使用自定义设置和选项配置客户端。

```moonbit
// 创建具有自定义配置的客户端
let client = new_client_with_config(
    "your-api-key",           // API 密钥
    "https://api.openai.com/v1", // 基础 URL
    30,                       // 超时秒数
    3,                        // 最大重试次数
    "MoonBit-SDK/1.0",       // 用户代理
    false                     // 调试模式
)

// 创建 HTTP 客户端进行自定义请求
let http_client = new_http_client("https://api.openai.com/v1")
let request = new_http_request(
    "POST",
    "https://api.openai.com/v1/chat/completions",
    ["Content-Type: application/json", "Authorization: Bearer your-api-key"],
    "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello\"}]}"
)

// 执行自定义 HTTP 请求
let http_result = http_post(http_client, request)
match http_result {
    Ok((status_code, headers, body)) => {
        // 处理 HTTP 响应
        println("状态: " + status_code.to_string())
        println("响应: " + body)
    }
    Err(error) => {
        // 处理 HTTP 错误
    }
}
```

#### 更多运行时配置辅助函数

```moonbit
// 开启调试日志（打印关键请求/响应片段）
let client = enable_debug(client)

// 运行时更新超时与重试次数
let client = set_timeout(client, 60)
let client = set_retries(client, 5)

// 可选：设置组织与项目（请求头 OpenAI-Organization / OpenAI-Project）
let client = set_organization(client, "org_123")
let client = set_project(client, "proj_123")
```

### 🔄 错误处理
优雅地处理各种 API 和网络错误。

```moonbit
// 处理特定错误类型
let result = simple_chat(client, "Test message")
match result {
    Ok(response) => {
        // 成功情况
    }
    Err((error_type, message, status_code)) => {
        match error_type {
            "invalid_api_key" => {
                // 处理无效 API 密钥
            }
            "rate_limit_exceeded" => {
                // 处理速率限制
            }
            "max_retries_exceeded" => {
                // 处理网络超时
            }
            "invalid_request" => {
                // 处理格式错误的请求
            }
            _ => {
                // 处理其他错误
            }
        }
    }
}

// 处理网络错误
let network_result = check_network_status()
// 带重试逻辑的网络状态检查
```

### 📈 消息和模型管理
创建和管理不同类型的消息和模型。

```moonbit
// 创建不同类型的消息
let system_msg = system_message("You are a helpful assistant specialized in coding.")
let user_msg = user_message("Explain how to implement a binary search tree")
let assistant_msg = assistant_message("I'll help you implement a binary search tree...")

// 使用不同模型
let gpt4_result = chat_completion(client, messages, GPT_4O)
let gpt35_result = chat_completion(client, messages, GPT_3_5_TURBO)
let gpt4_mini_result = chat_completion(client, messages, GPT_4O_MINI)

// 自定义模型配置
let custom_model = "gpt-4-turbo-preview"
let custom_result = chat_completion(client, messages, custom_model)
```

### 🎨 响应处理
处理和解析不同类型的 API 响应。

```moonbit
// 处理聊天完成响应
let result = chat_completion(client, messages, GPT_4O)
match result {
    Ok((id, object, created, model, choices, usage)) => {
        // 提取响应详情
        println("响应 ID: " + id)
        println("使用模型: " + model)
        println("创建时间: " + created.to_string())
        
        // 处理选择
        if choices.length() > 0 {
            let choice = choices.get(0)
            match choice {
                Some(c) => {
                    let message = c.1
                    let finish_reason = c.2
                    let (role, content) = message
                    println("助手: " + content)
                    println("结束原因: " + finish_reason)
                }
                None => {
                    println("未收到响应")
                }
            }
        }
        
        // 处理使用统计
        let (prompt_tokens, completion_tokens, total_tokens) = usage
        println("使用令牌: " + total_tokens.to_string())
    }
    Err(error) => {
        // 处理错误
    }
}
```

### 🏗️ 复杂对话管理
处理复杂的多轮对话和上下文。

```moonbit
// 构建对话上下文
let mut conversation = []
conversation = conversation + [system_message("You are a coding tutor.")]
conversation = conversation + [user_message("I want to learn about algorithms.")]

// 获取响应并继续对话
let result = chat_completion(client, conversation, GPT_4O)
match result {
    Ok(response) => {
        let choices = response.4
        if choices.length() > 0 {
            let choice = choices.get(0)
            match choice {
                Some(c) => {
                    let message = c.1
                    // 将助手响应添加到对话中
                    conversation = conversation + [assistant_message(message.1)]
                    
                    // 继续后续问题
                    conversation = conversation + [user_message("Can you explain binary search?")]
                    
                    // 获取下一个响应
                    let next_result = chat_completion(client, conversation, GPT_4O)
                    // 处理下一个响应...
                }
                None => {}
            }
        }
    }
    Err(error) => {
        // 处理对话错误
    }
}
```

## 📋 数据结构

### 错误类型
```moonbit
// OpenAI API 错误类型
pub typealias (String, String, Int) as OpenAIError  // (error_type, message, status_code)

// HTTP 错误类型
pub typealias (String, Int, String) as HttpError  // (error_type, status_code, message)
```

### 核心类型
```moonbit
// 消息类型
pub typealias (String, String) as Message  // (role, content)

// 选择类型（带可选 tool_calls）
pub typealias (Int, Message, String, Option[ToolCall]) as Choice  // (index, message, finish_reason, tool_calls)

// 使用统计
pub typealias (Int, Int, Int) as Usage  // (prompt_tokens, completion_tokens, total_tokens)

// 聊天完成响应
pub typealias (String, String, Int, String, Array[Choice], Usage) as ChatCompletionResponse

// 工具调用类型
pub typealias (String, String, String, String) as ToolCall  // (id, type, function_name, arguments)

// HTTP 客户端和请求类型
pub typealias (String, Int, Int, String) as HttpClient  // (base_url, timeout, retries, user_agent)
pub typealias (String, String, Array[String], String) as HttpRequest  // (method, url, headers, body)
```

## 📊 完整 API 参考

### 核心聊天函数
- `simple_chat(client, message)` - 简单聊天完成
- `stream_chat(client, message)` - 流式聊天完成
- `tool_chat(client, message, tools)` - 带工具调用的聊天
- `structured_chat(client, message, format)` - 带结构化输出的聊天
- `chat_completion(client, messages, model)` - 完整聊天完成 API

### 客户端管理
- `new_client(api_key)` - 使用 API 密钥创建客户端
- `new_client_with_config(api_key, base_url, timeout, retries, user_agent, debug)` - 创建配置客户端

### 消息创建
- `system_message(content)` - 创建系统消息
- `user_message(content)` - 创建用户消息
- `assistant_message(content)` - 创建助手消息

### HTTP 操作
- `new_http_client(base_url)` - 创建 HTTP 客户端
- `new_http_request(method, url, headers, body)` - 创建 HTTP 请求
- `http_post(client, request)` - 执行 HTTP POST 请求

### 工具函数
- `check_network_status()` - 检查网络连接状态
- `json_serialize(value)` - 字符串 JSON 安全序列化
- `json_deserialize(json)` - JSON 合法性校验与规范化
- `extract_json_field(json, field)` - 提取顶层字段

## 📈 性能特征

| 操作 | 时间复杂度 | 空间复杂度 |
|------|------------|------------|
| `simple_chat()` | O(n) | O(n) |
| `stream_chat()` | O(n) | O(n) |
| `tool_chat()` | O(n) | O(n) |
| `structured_chat()` | O(n) | O(n) |
| `chat_completion()` | O(n) | O(n) |
| `new_client()` | O(1) | O(1) |
| `new_client_with_config()` | O(1) | O(1) |
| `system_message()` | O(1) | O(1) |
| `user_message()` | O(1) | O(1) |
| `assistant_message()` | O(1) | O(1) |
| `http_post()` | O(n) | O(n) |
| `check_network_status()` | O(1) | O(1) |

## 🏗️ 算法详情

### 聊天完成算法
1. **请求准备**: 格式化消息和模型参数
2. **HTTP 请求**: 向 OpenAI API 端点发送 POST 请求
3. **响应处理**: 解析 JSON 响应并提取选择
4. **错误处理**: 处理 API 错误和网络故障

### 流式响应算法
1. **流设置**: 配置流式参数
2. **块处理**: 增量处理服务器发送的事件
3. **数据组装**: 将块组合成完整响应
4. **流管理**: 处理连接和缓冲

### 工具调用算法
1. **工具定义**: 定义可用工具及其模式
2. **意图检测**: 让模型确定何时调用工具
3. **函数执行**: 使用提供的参数执行调用的工具
4. **响应集成**: 将工具结果与模型响应结合

### 错误处理策略
- **网络故障**: 实现指数退避重试机制
- **API 错误**: 解析和分类 OpenAI API 错误响应
- **速率限制**: 使用适当延迟处理速率限制错误
- **超时管理**: 配置和处理请求超时

## 🧪 测试覆盖

项目包含全面的测试用例，**25个测试全部通过**：
- ✅ 基本聊天完成功能测试
- ✅ 流式响应处理测试
- ✅ 工具调用和函数执行测试
- ✅ 结构化输出解析测试
- ✅ 多轮对话测试
- ✅ 错误处理和边界情况测试
- ✅ 网络模拟和重试测试
- ✅ 配置和客户端管理测试

### 测试统计
- **总测试数**: 25 个测试
- **通过率**: 100% (25/25 通过)
- **测试代码行数**: 605 行
- **错误路径覆盖**: 全面的错误处理测试
- **网络实现**: 覆盖真实网络与模拟逻辑

## 🚀 构建和运行

```bash
# Linux/macOS
moon build
moon test
moon run src/main.mbt
moon coverage report -f cobertura -o coverage.xml

# Windows（命令需要加 --target native）
moon build --target native
moon test --target native
moon run --target native src/main.mbt
```

### 运行 5 个演示用例（src/main.mbt）

- **传入 API Key**：使用 `--api-key VALUE`、`--key VALUE` 或 `-k VALUE`（也支持 `--api-key=VALUE`、`--key=VALUE`、`-k=VALUE`）。
- **可选运行参数**：`--base-url VALUE`、`--timeout VALUE`（秒）、`--retries VALUE`。
- **参数分隔符**：通过 `moon run` 传入程序参数时，请在参数前添加 `--`。

运行全部 5 个 Case：

```bash
# Linux/macOS
moon run src/main.mbt -- --api-key sk-your-api-key

# Windows
moon run --target native src/main.mbt -- --api-key sk-your-api-key
```

仅运行 Case 1（基础对话）：

```bash
# Linux/macOS
moon run src/main.mbt -- --api-key sk-your-api-key --case=1

# Windows
moon run --target native src/main.mbt -- --api-key sk-your-api-key --case=1
```

- **Case 1**：基础对话（`demo_basic_conversation`）
- **Case 2**：流式响应（`demo_streaming_response`）
- **Case 3**：工具调用与结果回传（`demo_tool_calling`）
- **Case 4**：结构化输出（`demo_structured_output`）
- **Case 5**：多轮对话（`demo_multi_turn_conversation`）

## 📦 依赖

- `moonbitlang/async: 0.9.0`: 异步 HTTP 与超时支持
- `moonbitlang/core`: 提供基础数据结构支持

## 🌐 网络集成

### 当前状态
- **网络库**: `moonbitlang/async: 0.9.0` 正在使用
- **实现方式**: 基于 async/http 的真实 HTTP，请求支持超时与重试
- **生产就绪**: 可用于生产的真实网络集成

### 生产部署
```moonbit
// 使用 async/http 进行真实 HTTP 请求
fn perform_real_http_request(
    http_method: String,
    url: String,
    headers: Array[String],
    body: String,
    timeout: Int
) -> Result[HttpResponse, HttpError] {
    // 基于 moonbitlang/async 实现真实 HTTP 与超时
}
```

### Go 风格适配器（可选）

为偏好 Go SDK 习惯的用户提供 Go 风格包装。

```moonbit
// 创建客户端并使用 Go 风格的配置帮助函数
let client = go_new_client("your-api-key")
let client = go_with_base_url(client, "https://api.openai.com/v1")
let client = go_with_timeout(client, 60)
let client = go_with_retries(client, 5)
let client = go_with_organization(client, "org_123")
let client = go_with_project(client, "proj_123")

// 构造消息
let messages = [
  go_system_message("You are helpful."),
  go_user_message("Hello")
]

// 非流式聊天
let res = go_chat_completions_create(client, GPT_4O, messages)

// 流式聊天
let stream_res = go_chat_completions_create_stream(client, GPT_4O, messages)

// 带工具
let tools = ["get_weather"]
let tool_res = go_chat_completions_create_with_tools(client, GPT_4O, messages, tools)

// 结构化输出
let schema = "{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"}},\"required\":[\"name\"]}"
let fmt = go_response_format_json_schema(schema, "Person")
let structured_res = go_chat_completions_create_structured(client, GPT_4O, messages, fmt)
```

## 🔧 配置

### 环境变量
```bash
# 设置环境变量
export OPENAI_API_KEY="your-api-key"
export OPENAI_BASE_URL="https://api.openai.com/v1"
export OPENAI_TIMEOUT="30"
export OPENAI_MAX_RETRIES="3"
```

### 客户端配置
```moonbit
// 使用自定义设置配置客户端
let client = new_client_with_config(
    api_key,      // API 密钥
    base_url,     // API 基础 URL
    timeout,      // 请求超时
    retries,      // 最大重试次数
    user_agent,   // 自定义用户代理
    debug         // 调试模式
)
```

## 🎯 用例实现

### 用例 1: 基础对话
```moonbit
let client = new_client("sk-your-api-key")
let response = simple_chat(client, "Say this is a test")
// 简单问答交互
```

### 用例 2: 流式响应
```moonbit
let response = stream_chat(client, "Tell me a story about a brave knight")
// 实时流式输出
```

### 用例 3: 工具调用
```moonbit
let tools = ["get_weather"]
let (response, tool_call) = tool_chat(client, "What's the weather like?", tools)
// 函数调用能力
```

### 用例 4: 结构化输出
```moonbit
let schema = "{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"},\"age\":{\"type\":\"integer\"}},\"required\":[\"name\",\"age\"],\"additionalProperties\":false}"
let format = ("json_schema", schema, "Person")
let response = structured_chat(client, "Extract name and age", format)
// 严格 JSON Schema 输出
```

### 用例 5: 多轮对话
```moonbit
let messages = [
    system_message("You are a helpful assistant."),
    user_message("Hello"),
    assistant_message("Hi! How can I help you?"),
    user_message("What's 2+2?")
]
let result = chat_completion(client, messages, GPT_4O)
// 上下文感知对话
```

## 🏗️ 项目结构

```
openai_sdk/
├── src/
│   ├── openai.mbt                    # OpenAI API 核心实现
│   ├── main.mbt                      # 主程序入口点
│   ├── utils.mbt                     # 工具函数
│   ├── examples.mbt                  # 使用示例
│   ├── openai_test.mbt              # 完整测试套件 (605 行)
│   ├── real_network.mbt             # 真实网络集成层
│   └── moon.pkg.json                # 包配置
├── moon.mod.json                    # 项目配置
├── README.md                        # 项目文档
├── README_zh_CN.md                  # 中文文档
└── LICENSE                          # 开源许可证
```

## 📜 许可证

本项目采用 Apache-2.0 许可证。详情请参阅 LICENSE 文件。

## 📢 联系与支持

• MoonBit 社区: moonbit-community  
• GitHub Issues: 报告问题  

## 🔍 OpenAI API 信息

此 SDK 为 OpenAI API 功能提供完整支持：
- **聊天完成**: GPT-3.5-turbo、GPT-4、GPT-4-turbo 模型
- **流式传输**: 用于实时响应的服务器发送事件
- **工具调用**: 带 JSON 模式定义的函数调用
- **结构化输出**: 用于结构化数据提取的 JSON 模式
- **上下文管理**: 带消息历史的多轮对话

本库提供完整的 OpenAI API 兼容性，具有高效的请求处理和全面的错误管理。

👋 如果您喜欢这个项目，请给它一个 ⭐！祝编码愉快！🚀 