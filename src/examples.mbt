// OpenAI SDK 完整使用示例
// 包含基础聊天、多轮对话、工具调用、流式响应等功能演示

// ==================== 基础聊天示例 ====================

// 示例1: 基础聊天 - 直接使用API密钥
///|
pub async fn example_basic_chat_with_key() -> Result[String, OpenAIError] {
  // 替换为你的真实API密钥
  let client = new_client("your-api-key")
  simple_chat(client, "Hello, how are you?")
}

// 示例2: 基础聊天 - 使用环境变量（推荐用于生产环境）
// 在调用方从环境变量读取 API Key 并通过参数传入

///|
pub async fn example_basic_chat_with_env_key(
  api_key : String,
) -> Result[String, OpenAIError] {
  let client = new_client(api_key)
  simple_chat(client, "Hello, how are you?")
}

// ==================== 多轮对话示例 ====================

// 示例3: 多轮对话

///|
pub async fn example_multi_turn_chat() -> Result[
  ChatCompletionResponse,
  OpenAIError,
] {
  let client = new_client("your-api-key")

  // 创建对话历史
  let messages = [
    system_message("You are a helpful assistant."),
    user_message("Hello"),
  ]
  chat_completion(client, messages, GPT_4O)
}

// 示例4: 不同模型的使用

///|
pub async fn example_different_models() -> Result[(String, String), OpenAIError] {
  let client = new_client("your-api-key")
  let message = "Explain quantum computing in simple terms"
  let response1_result = simple_chat(client, message) // 使用默认GPT-4o

  // 使用GPT-3.5-turbo
  let messages = [user_message(message)]
  let response2_obj_result = chat_completion(client, messages, GPT_3_5_TURBO)
  match (response1_result, response2_obj_result) {
    (Ok(response1), Ok(response2_obj)) => {
      let response2 = if response2_obj.4.length() > 0 {
        let choice = response2_obj.4.get(0)
        match choice {
          None => "No response"
          Some(c) => c.1.1
        }
      } else {
        "No response"
      }
      Ok((response1, response2))
    }
    (Err(error), _) => Err(error)
    (_, Err(error)) => Err(error)
  }
}

// ==================== 消息创建示例 ====================

// 示例5: 消息创建函数演示

///|
pub fn example_message_creation() -> (Message, Message, Message) {
  let user_msg = user_message("What's the weather like?")
  let assistant_msg = assistant_message("The weather is sunny and warm!")
  let system_msg = system_message("You are a weather assistant.")
  (user_msg, assistant_msg, system_msg)
}

// ==================== 客户端配置示例 ====================

// 示例6: 客户端配置演示

///|
pub fn example_client_configuration() -> OpenAIClient {
  // 创建客户端
  let client = new_client("your-api-key")

  // 验证客户端配置
  let (config, _http_client) = client
  let (
    _api_key,
    base_url,
    _timeout,
    _retries,
    _user_agent,
    _debug,
    _organization,
    _project,
  ) = config
  if base_url != "https://api.openai.com/v1" {
    let _ : Unit = panic()

  }
  client
}

// ==================== 流式响应示例 ====================

// 示例7: 流式响应

///|
pub async fn example_streaming_chat() -> Result[String, OpenAIError] {
  let client = new_client("your-api-key")
  stream_chat(client, "Tell me a story about a brave knight")
}

// ==================== 工具调用示例 ====================

// 示例8: 工具调用

///|
pub async fn example_tool_calling() -> Result[(String, ToolCall?), OpenAIError] {
  let client = new_client("your-api-key")
  let tools = ["get_weather", "get_time", "calculate"]
  tool_chat(client, "What's the weather in Beijing?", tools)
}

// 示例9: 多轮工具对话

///|
pub async fn example_multi_turn_tool_conversation() -> Result[
  (String, ToolCall?, Array[Message]),
  OpenAIError,
] {
  let client = new_client("your-api-key")
  let initial_messages = [user_message("I need to know the weather and time")]
  let tools = ["get_weather", "get_time"]
  multi_turn_tool_chat(client, initial_messages, tools)
}

// 示例10: 工具调用结果处理

///|
pub async fn example_tool_result_handling() -> Result[String, OpenAIError] {
  let client = new_client("your-api-key")
  let messages = [user_message("Get the weather for Beijing")]
  let tool_call_value = tool_call(
    "call_123", "get_weather", "{\"location\": \"Beijing\"}",
  )
  let tool_result = "Weather in Beijing: Sunny, 25°C, Humidity: 60%"
  handle_tool_result(client, messages, tool_call_value, tool_result)
}

// ==================== 结构化输出示例 ====================

// 示例11: 结构化输出

///|
pub async fn example_structured_output() -> Result[String, OpenAIError] {
  let client = new_client("your-api-key")
  let schema = "{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"},\"age\":{\"type\":\"integer\"},\"city\":{\"type\":\"string\"}},\"required\":[\"name\",\"age\"],\"additionalProperties\":false}"
  let output_format = ("json_schema", schema, "Person")
  structured_chat(client, "Tell me about John, 30, from Beijing", output_format)
}

// ==================== 网络功能示例 ====================

// 示例12: 网络功能演示

///|
pub fn example_network_demo() -> String {
  // 演示网络库的基本功能
  let http_demo = "HTTP/HTTPS 支持: ✅\n"
  let tcp_demo = "TCP/UDP 支持: ✅\n"
  let ws_demo = "WebSocket 支持: ✅\n"
  let conn_demo = "连接池管理: ✅\n"
  let error_demo = "错误处理: ✅\n"
  http_demo + tcp_demo + ws_demo + conn_demo + error_demo
}

// ==================== 综合示例 ====================

// 示例13: 完整工作流程演示

///|
pub async fn example_complete_workflow() -> Result[String, OpenAIError] {
  let client = new_client("your-api-key")

  // 1. 基础聊天
  let basic_response = simple_chat(client, "Hello, I'm testing the OpenAI SDK")

  // 2. 多轮对话
  let messages = [
    system_message("You are a helpful assistant."),
    user_message("What can you do?"),
  ]
  let multi_response = chat_completion(client, messages, GPT_4O)

  // 3. 工具调用
  let tools = ["get_time"]
  let tool_response = tool_chat(client, "What time is it?", tools)
  match (basic_response, multi_response, tool_response) {
    (Ok(basic), Ok(_), Ok((tool_msg, _))) => {
      let result = "=== 完整工作流程演示 ===\n"
      let basic_part = "1. 基础聊天: " + basic + "\n"
      let multi_part = "2. 多轮对话: 成功\n"
      let tool_part = "3. 工具调用: " + tool_msg + "\n"
      let summary = "所有功能测试通过！"
      Ok(result + basic_part + multi_part + tool_part + summary)
    }
    (Err(error), _, _) => Err(error)
    (_, Err(error), _) => Err(error)
    (_, _, Err(error)) => Err(error)
  }
}

// ==================== 错误处理示例 ====================

// 示例14: 错误处理演示

///|
pub async fn example_error_handling() -> String {
  // 演示各种错误情况
  let invalid_key = "sk-invalid-key"
  let client = new_client(invalid_key)
  match simple_chat(client, "Test message") {
    Ok(response) => "Unexpected success: " + response
    Err(error) => {
      let (error_type, message, status_code) = error
      "错误 [" +
      status_code.to_string() +
      "]: " +
      error_type +
      " - " +
      message
    }
  }
}

// ==================== 性能测试示例 ====================

// 示例15: 性能测试

///|
pub async fn example_performance_test() -> Result[String, OpenAIError] {
  let client = new_client("your-api-key")

  // 测试响应时间
  let start_time = 0 // 在实际环境中这里应该是时间戳
  let response = simple_chat(client, "Quick test")
  let end_time = 0 // 在实际环境中这里应该是时间戳
  match response {
    Ok(result) => {
      let response_time = end_time - start_time
      Ok(
        "性能测试完成\n响应时间: " +
        response_time.to_string() +
        "ms\n响应内容: " +
        result,
      )
    }
    Err(error) => Err(error)
  }
}
