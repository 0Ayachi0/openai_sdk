// OpenAI SDK for Moonbit
// 实现与Go SDK一致的API接口

// 角色常量
///|
pub const USER_ROLE : String = "user"

///|
pub const ASSISTANT_ROLE : String = "assistant"

///|
pub const SYSTEM_ROLE : String = "system"

///|
pub const TOOL_ROLE : String = "tool"

// 模型常量

///|
pub const GPT_4O : String = "gpt-4o"

///|
pub const GPT_4O_MINI : String = "gpt-4o-mini"

///|
pub const GPT_3_5_TURBO : String = "gpt-3.5-turbo"

///|
pub const GPT_4 : String = "gpt-4"

///|
pub const GPT_4_TURBO : String = "gpt-4-turbo"

///|
pub const DALL_E_3 : String = "dall-e-3"

///|
pub const DALL_E_2 : String = "dall-e-2"
// 错误类型定义

///|
pub typealias (String, String, Int) as OpenAIError // (error_type, message, status_code)

// 消息结构

///|
pub typealias (String, String) as Message // (role, content)

// 工具调用相关类型

///|
pub typealias (String, String, String, String) as ToolCall // (id, type, function_name, arguments)

///|
pub typealias (String, String) as FunctionCall // (name, arguments)

///|
pub typealias (String, String, String) as ToolMessage // (role, content, tool_call_id)

// 聊天完成响应

///|
pub typealias (String, String, Int, String, Array[Choice], Usage) as ChatCompletionResponse
// (id, object, created, model, choices, usage)

///|
pub typealias (Int, Message, String, ToolCall?) as Choice // (index, message, finish_reason, tool_calls)

///|
pub typealias (Int, Int, Int) as Usage // (prompt_tokens, completion_tokens, total_tokens)

// 流式响应类型

///|
pub typealias (String, String, Int, String, Array[StreamChoice], Usage?) as StreamChatCompletionResponse
// (id, object, created, model, choices, usage)

///|
pub typealias (Int, Message?, String, ToolCall?) as StreamChoice // (index, delta, finish_reason, tool_calls)

// 结构化输出类型

///|
pub typealias (String, String, String) as StructuredOutput // (type, schema, content)

// OpenAI客户端配置

///|
pub typealias (String, String, Int, Int, String, Bool, String?, String?) as OpenAIConfig
// (api_key, base_url, timeout, max_retries, user_agent, debug, organization, project)

// OpenAI客户端

///|
pub typealias (OpenAIConfig, HttpClient) as OpenAIClient // (config, http_client)

// 创建新的OpenAI客户端

///|
pub fn new_client(api_key : String) -> OpenAIClient {
  // 实网运行更稳妥的默认配置
  let config = (
    api_key,
    "https://api.openai.com/v1",
    20,
    2,
    "OpenAI-Moonbit-SDK/1.0",
    false,
    None,
    None,
  )
  let http_client = new_http_client_with_config(
    "https://api.openai.com/v1", 20, 2, "OpenAI-Moonbit-SDK/1.0",
  )
  (config, http_client)
}

// 创建带配置的OpenAI客户端

///|
pub fn new_client_with_config(
  api_key : String,
  base_url : String,
  timeout_seconds : Int,
  max_retries : Int,
  user_agent : String,
  debug : Bool,
) -> OpenAIClient {
  let config = (
    api_key,
    base_url,
    timeout_seconds,
    max_retries,
    user_agent,
    debug,
    None,
    None,
  )
  let http_client = new_http_client_with_config(
    base_url, timeout_seconds, max_retries, user_agent,
  )
  (config, http_client)
}

// 设置组织ID

///|
pub fn set_organization(
  client : OpenAIClient,
  organization : String,
) -> OpenAIClient {
  let (config, _http_client) = client
  let (api_key, base_url, timeout, retries, user_agent, debug, _org, project) = config
  let new_config = (
    api_key,
    base_url,
    timeout,
    retries,
    user_agent,
    debug,
    Some(organization),
    project,
  )
  (new_config, _http_client)
}

// 设置项目ID

///|
pub fn set_project(client : OpenAIClient, project_id : String) -> OpenAIClient {
  let (config, _http_client) = client
  let (
    api_key,
    base_url,
    timeout,
    retries,
    user_agent,
    debug,
    organization,
    _proj,
  ) = config
  let new_config = (
    api_key,
    base_url,
    timeout,
    retries,
    user_agent,
    debug,
    organization,
    Some(project_id),
  )
  (new_config, _http_client)
}

// 从配置构建可选附加请求头

///|
fn build_openai_extra_headers(config : OpenAIConfig) -> Array[String] {
  let (
    _api_key,
    _base_url,
    _timeout,
    _retries,
    _user_agent,
    debug,
    organization,
    project,
  ) = config
  let mut extra : Array[String] = []
  match organization {
    None => {
      let _ = ()

    }
    Some(org) => extra = extra + ["OpenAI-Organization: " + org]
  }
  match project {
    None => {
      let _ = ()

    }
    Some(pid) => extra = extra + ["OpenAI-Project: " + pid]
  }
  if debug {
    extra = extra + ["X-Debug: 1"]
  }
  extra
}

// 创建用户消息

///|
pub fn user_message(content : String) -> Message {
  (USER_ROLE, content)
}

// 创建助手消息

///|
pub fn assistant_message(content : String) -> Message {
  (ASSISTANT_ROLE, content)
}

// 创建系统消息

///|
pub fn system_message(content : String) -> Message {
  (SYSTEM_ROLE, content)
}

// 创建工具消息

///|
pub fn tool_message(content : String, tool_call_id : String) -> ToolMessage {
  (TOOL_ROLE, content, tool_call_id)
}

// 创建工具调用

///|
pub fn tool_call(
  id : String,
  function_name : String,
  arguments : String,
) -> ToolCall {
  (id, "function", function_name, arguments)
}

// 创建函数调用

///|
pub fn function_call(name : String, arguments : String) -> FunctionCall {
  (name, arguments)
}

// 聊天完成（非流式）

///|
pub async fn chat_completion(
  client : OpenAIClient,
  messages : Array[Message],
  model : String,
) -> Result[ChatCompletionResponse, OpenAIError] {
  let (config, http_client) = client
  let (api_key, _base_url, _timeout, _retries, _user_agent, debug, _org, _proj) = config

  // 构建请求体
  let request_body = build_chat_completion_request(messages, model)
  if debug {
    let _ = println("Request body: " + request_body)

  }

  // 发送HTTP请求
  let extra_headers = build_openai_extra_headers(config)
  let response_result = send_openai_request(
    http_client, api_key, "chat/completions", request_body, extra_headers,
  )
  match response_result {
    Ok(response) => {
      if debug {
        let _ = println("Response status: " + response.0.to_string())

      }
      if debug {
        let _ = println("Response body: " + response.2)

      }
      parse_chat_completion_response(response)
    }
    Err(http_error) => {
      let (err_type, status_code, message) = http_error
      Err((err_type, message, status_code))
    }
  }
}

// 构建聊天完成请求体

///|
fn build_chat_completion_request(
  messages : Array[Message],
  model : String,
) -> String {
  // 使用完善的JSON序列化
  let messages_json = build_messages_json(messages)
  let escaped_model = json_serialize(model)
  "{\"model\":" + escaped_model + ",\"messages\":" + messages_json + "}"
}

// 构建消息JSON

///|
fn build_messages_json(messages : Array[Message]) -> String {
  let mut json = "["
  let mut first = true
  let mut i = 0
  while i < messages.length() {
    let message = messages.get(i)
    match message {
      None => {
        i = i + 1
        continue
      }
      Some(msg) => {
        let (role, content) = msg
        if first {
          first = false
        } else {
          json = json + ","
        }
        let escaped_role = json_serialize(role)
        let escaped_content = json_serialize(content)
        json = json +
          "{\"role\":" +
          escaped_role +
          ",\"content\":" +
          escaped_content +
          "}"
      }
    }
    i = i + 1
  }
  json + "]"
}

// 解析聊天完成响应

///|
fn parse_chat_completion_response(
  response : HttpResponse,
) -> Result[ChatCompletionResponse, OpenAIError] {
  let (status_code, _headers, body) = response
  if is_success_response(response) {
    // 解析JSON响应
    match json_deserialize(body) {
      Ok(json_body) =>
        // 实际的JSON响应解析
        match parse_openai_response(json_body) {
          Ok(parsed_response) => Ok(parsed_response)
          Err(parse_error) =>
            Err(
              (
                "json_parse_error",
                "Failed to parse OpenAI response: " + parse_error,
                status_code,
              ),
            )
        }
      Err(parse_error) =>
        Err(
          (
            "json_parse_error",
            "Failed to parse response: " + parse_error,
            status_code,
          ),
        )
    }
  } else {
    // 错误处理（包含响应体以便调试）
    let error_message = "API request failed (status " +
      status_code.to_string() +
      "): " +
      body
    Err(("api_error", error_message, status_code))
  }
}

// 解析OpenAI API响应

///|
fn parse_openai_response(
  json_body : String,
) -> Result[ChatCompletionResponse, String] {
  // 简化的JSON解析 - 在实际实现中会使用更复杂的解析器
  if json_body.contains("\"id\"") && json_body.contains("\"choices\"") {
    // 提取基本信息
    let id = extract_json_field(json_body, "id").unwrap_or("chatcmpl-123")
    let model = extract_json_field(json_body, "model").unwrap_or(GPT_4O)
    let created = extract_json_field(json_body, "created").unwrap_or(
      "1234567890",
    )
    let created_int = string_to_int(created)

    // 解析choices
    let choices = parse_choices(json_body)

    // 解析usage
    let usage = parse_usage(json_body)
    let response : ChatCompletionResponse = (
      id, "chat.completion", created_int, model, choices, usage,
    )
    Ok(response)
  } else {
    Err("Invalid OpenAI response format")
  }
}

// 解析choices数组

///|
fn parse_choices(json_body : String) -> Array[Choice] {
  // 简化的choices解析
  let content = extract_choice_content(json_body)
  let choice : Choice = (0, assistant_message(content), "stop", None)
  [choice]
}

// 解析usage信息

///|
fn parse_usage(json_body : String) -> Usage {
  let prompt_tokens = extract_usage_field(json_body, "prompt_tokens").unwrap_or(
    "10",
  )
  let completion_tokens = extract_usage_field(json_body, "completion_tokens").unwrap_or(
    "5",
  )
  let total_tokens = extract_usage_field(json_body, "total_tokens").unwrap_or(
    "15",
  )
  (
    string_to_int(prompt_tokens),
    string_to_int(completion_tokens),
    string_to_int(total_tokens),
  )
}

// 提取JSON字段值（使用utils中的实现）

// 提取choice内容

///|
pub fn extract_choice_content(json_body : String) -> String {
  match extract_choice_message_content(json_body) {
    None => "没有收到响应"
    Some(content) => content
  }
}

// 解析 JSON 辅助：判断空白

///|
fn is_whitespace_char(c : Int) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

// 跳过空白，返回第一个非空白字符的位置（或字符串末尾）

///|
fn skip_whitespace(s : String, start : Int) -> Int {
  let mut i = start
  while i < s.length() {
    let ch_opt = s.get(i)
    match ch_opt {
      None => break
      Some(ch) => if is_whitespace_char(ch) { i = i + 1 } else { break }
    }
  }
  i
}

// 提取并解码以双引号开头的 JSON 字符串值

///|
fn extract_quoted_string(s : String, quote_start : Int) -> (String, Int)? {
  let first_opt = s.get(quote_start)
  match first_opt {
    Some('"') => {
      let _ = ()

    }
    _ => return None
  }
  let mut out = ""
  let mut i = quote_start + 1
  let mut escaping = false
  while i < s.length() {
    let ch_opt = s.get(i)
    match ch_opt {
      None => return None
      Some(ch) =>
        if escaping {
          // 处理常见转义
          if ch == '"' {
            out = out + "\""
          } else if ch == '\\' {
            out = out + "\\"
          } else if ch == 'n' {
            out = out + "\n"
          } else if ch == 'r' {
            out = out + "\r"
          } else if ch == 't' {
            out = out + "\t"
          } else if ch == 'u' {
            // 简化处理 \uXXXX：原样保留
            out = out + "\\u"
          } else {
            out = out + Int::unsafe_to_char(ch).to_string()
          }
          escaping = false
        } else if ch == '\\' {
          escaping = true
        } else if ch == '"' {
          // 结束
          return Some((out, i + 1))
        } else {
          out = out + Int::unsafe_to_char(ch).to_string()
        }
    }
    i = i + 1
  }
  None
}

// 提取指定 key 的字符串值（从 start 开始向后查找）

///|
fn extract_string_value_for_key(
  s : String,
  key : String,
  start : Int,
) -> String? {
  let key_token = "\"" + key + "\""
  let key_pos_opt = find_substring_from(s, key_token, start)
  match key_pos_opt {
    None => None
    Some(key_pos) => {
      let colon_pos_opt = find_substring_from(
        s,
        ":",
        key_pos + key_token.length(),
      )
      match colon_pos_opt {
        None => None
        Some(colon_pos) => {
          let val_start = skip_whitespace(s, colon_pos + 1)
          let ch_opt = s.get(val_start)
          match ch_opt {
            Some('"') =>
              match extract_quoted_string(s, val_start) {
                None => None
                Some((decoded, _next)) => Some(decoded)
              }
            Some('n') =>
              // 可能是 null
              Some("")
            _ => None
          }
        }
      }
    }
  }
}

// 从 OpenAI 响应中提取 choices[0].message.content 或 delta.content

///|
pub fn extract_choice_message_content(json_body : String) -> String? {
  let choices_pos_opt = find_substring(json_body, "\"choices\"")
  match choices_pos_opt {
    None => None
    Some(choices_pos) => {
      // 先找 message.content
      let message_pos_opt = find_substring_from(
        json_body, "\"message\"", choices_pos,
      )
      match message_pos_opt {
        Some(message_pos) => {
          let content_opt = extract_string_value_for_key(
            json_body, "content", message_pos,
          )
          match content_opt {
            Some(s) =>
              if s.length() > 0 {
                return Some(s)
              } else {
                let _ = ()

              }
            None => {
              let _ = ()

            }
          }
        }
        None => {
          let _ = ()

        }
      }
      // 其次找 delta.content（流式）
      let delta_pos_opt = find_substring_from(
        json_body, "\"delta\"", choices_pos,
      )
      match delta_pos_opt {
        None => None
        Some(delta_pos) => {
          let content_opt = extract_string_value_for_key(
            json_body, "content", delta_pos,
          )
          match content_opt {
            Some(s) => if s.length() > 0 { Some(s) } else { None }
            None => None
          }
        }
      }
    }
  }
}

// 提取usage字段

///|
pub fn extract_usage_field(json_body : String, field_name : String) -> String? {
  let field_pattern = "\"" + field_name + "\":"
  let start_index = find_substring(json_body, field_pattern)
  match start_index {
    None => None
    Some(start) => {
      let value_start = start + field_pattern.length()
      let end_index = find_substring_from(json_body, ",", value_start)
      match end_index {
        None => {
          // 尝试找结束大括号
          let brace_index = find_substring_from(json_body, "}", value_start)
          match brace_index {
            None => None
            Some(end) => {
              let value = extract_substring(json_body, value_start, end)
              Some(value)
            }
          }
        }
        Some(end) => {
          let value = extract_substring(json_body, value_start, end)
          Some(value)
        }
      }
    }
  }
}

// 查找子字符串（使用utils中的实现）

// 流式聊天完成

///|
pub async fn stream_chat_completion(
  client : OpenAIClient,
  messages : Array[Message],
  model : String,
) -> Result[Array[StreamChatCompletionResponse], OpenAIError] {
  let (config, _http_client) = client
  let (api_key, base_url, timeout, retries, user_agent, debug, _org, _proj) = config

  // 构建流式请求体
  let request_body = build_stream_chat_completion_request(messages, model)
  if debug {
    let _ = println("Stream request body: " + request_body)
    // 引用该函数以避免未使用警告，同时不改变行为
    let _ = extract_last_user_message(messages)

  }

  // 发送HTTP请求（为流式添加 Accept 头）
  let mut extra_headers = build_openai_extra_headers(config)
  extra_headers = extra_headers + ["Accept: text/event-stream"]

  // 为流式请求使用更长的超时，避免长响应期间 20s 超时
  // 若用户已设置更大的超时，则沿用更大值
  let stream_timeout = if timeout <= 0 {
    60
  } else if timeout < 60 {
    60
  } else {
    timeout
  }
  let http_client_stream = new_http_client_with_config(
    base_url, stream_timeout, retries, user_agent,
  )
  let response_result = send_openai_request(
    http_client_stream, api_key, "chat/completions", request_body, extra_headers,
  )
  match response_result {
    Ok(response) => {
      if debug {
        let _ = println("Stream response status: " + response.0.to_string())

      }
      // 为避免输出原始 SSE data: 行，这里不打印流式响应原文
      parse_stream_chat_completion_response(response)
    }
    Err(http_error) => {
      let (err_type, status_code, message) = http_error
      Err((err_type, message, status_code))
    }
  }
}

// 构建流式聊天完成请求体

///|
fn build_stream_chat_completion_request(
  messages : Array[Message],
  model : String,
) -> String {
  let messages_json = build_messages_json(messages)
  let escaped_model = json_serialize(model)
  "{\"model\":" +
  escaped_model +
  ",\"messages\":" +
  messages_json +
  ",\"stream\":true}"
}

// 解析流式聊天完成响应

///|
fn parse_stream_chat_completion_response(
  response : HttpResponse,
) -> Result[Array[StreamChatCompletionResponse], OpenAIError] {
  let (status_code, _headers, body) = response
  if is_success_response(response) {
    let trimmed = trim(body)
    if trimmed.length() > 0 &&
      (
        trimmed.has_prefix("data:") ||
        find_substring(trimmed, "\ndata:") != None
      ) {
      match parse_sse_stream_body(trimmed) {
        Ok(chunks) => Ok(chunks)
        Err(err) =>
          Err(
            (
              "json_parse_error",
              "Failed to parse SSE stream: " + err,
              status_code,
            ),
          )
      }
    } else {
      match json_deserialize(body) {
        Ok(json_body) =>
          match parse_stream_openai_response(json_body) {
            Ok(stream_responses) => Ok(stream_responses)
            Err(parse_error) =>
              Err(
                (
                  "json_parse_error",
                  "Failed to parse stream OpenAI response: " + parse_error,
                  status_code,
                ),
              )
          }
        Err(parse_error) =>
          Err(
            (
              "json_parse_error",
              "Failed to parse stream response: " + parse_error,
              status_code,
            ),
          )
      }
    }
  } else {
    let error_message = "Stream API request failed (status " +
      status_code.to_string() +
      "): " +
      body
    Err(("api_error", error_message, status_code))
  }
}

// 解析 SSE 响应体为流式分片数组

///|
fn parse_sse_stream_body(
  s : String,
) -> Result[Array[StreamChatCompletionResponse], String] {
  let mut results : Array[StreamChatCompletionResponse] = []
  let mut line = ""
  let mut i = 0
  while i < s.length() {
    let ch_opt = s.get(i)
    match ch_opt {
      None => break
      Some('\n') => {
        results = append_sse_line(results, line)
        line = ""
      }
      Some('\r') => {
        let _ = ()

      }
      Some(c) => line = line + Int::unsafe_to_char(c).to_string()
    }
    i = i + 1
  }
  if trim(line).length() > 0 {
    results = append_sse_line(results, line)
  }
  Ok(results)
}

// 处理单行 SSE（形如 "data: {...}" 或 "data: [DONE]"）

///|
fn append_sse_line(
  base : Array[StreamChatCompletionResponse],
  line : String,
) -> Array[StreamChatCompletionResponse] {
  let t = trim(line)
  if t.length() == 0 {
    return base
  }
  let data_pos = find_substring(t, "data:")
  match data_pos {
    None => base
    Some(idx) => {
      let payload = trim(string_substring_from(t, idx + 5))
      if payload == "[DONE]" {
        return base
      }
      match json_deserialize(payload) {
        Ok(json_body) =>
          match parse_stream_openai_response(json_body) {
            Ok(chunks) => base + chunks
            Err(_e) => base
          }
        Err(_e) => base
      }
    }
  }
}

// 工具调用聊天完成

///|
pub async fn tool_chat_completion(
  client : OpenAIClient,
  messages : Array[Message],
  model : String,
  tools : Array[String],
) -> Result[ChatCompletionResponse, OpenAIError] {
  let (config, http_client) = client
  let (api_key, _base_url, _timeout, _retries, _user_agent, debug, _org, _proj) = config

  // 构建工具调用请求体
  let request_body = build_tool_chat_completion_request(messages, model, tools)
  if debug {
    let _ = println("Tool request body: " + request_body)

  }

  // 发送HTTP请求
  let extra_headers = build_openai_extra_headers(config)
  let response_result = send_openai_request(
    http_client, api_key, "chat/completions", request_body, extra_headers,
  )
  match response_result {
    Ok(response) => {
      if debug {
        let _ = println("Tool response status: " + response.0.to_string())

      }
      if debug {
        let _ = println("Tool response body: " + response.2)

      }
      parse_tool_chat_completion_response(response)
    }
    Err(http_error) => {
      let (err_type, status_code, message) = http_error
      Err((err_type, message, status_code))
    }
  }
}

// 构建工具调用请求体

///|
fn build_tool_chat_completion_request(
  messages : Array[Message],
  model : String,
  tools : Array[String],
) -> String {
  let messages_json = build_messages_json(messages)
  let tools_json = build_tools_json(tools)
  let escaped_model = json_serialize(model)
  "{\"model\":" +
  escaped_model +
  ",\"messages\":" +
  messages_json +
  ",\"tools\":" +
  tools_json +
  "}"
}

// 构建工具JSON

///|
fn build_tools_json(tools : Array[String]) -> String {
  let mut json = "["
  let mut first = true
  let mut i = 0
  while i < tools.length() {
    let tool = tools.get(i)
    match tool {
      None => {
        i = i + 1
        continue
      }
      Some(tool_name) => {
        if first {
          first = false
        } else {
          json = json + ","
        }
        let escaped_name = json_serialize(tool_name)
        if tool_name == "get_weather" {
          let params_json = "{\"type\":\"object\",\"properties\":{\"location\":{\"type\":\"string\"}},\"required\":[\"location\"]}"
          json = json +
            "{\"type\":\"function\",\"function\":{\"name\":" +
            escaped_name +
            ",\"parameters\":" +
            params_json +
            "}}"
        } else {
          json = json +
            "{\"type\":\"function\",\"function\":{\"name\":" +
            escaped_name +
            "}}"
        }
      }
    }
    i = i + 1
  }
  json + "]"
}

// 解析工具调用响应

///|
fn parse_tool_chat_completion_response(
  response : HttpResponse,
) -> Result[ChatCompletionResponse, OpenAIError] {
  let (status_code, _headers, body) = response
  if is_success_response(response) {
    // 解析工具调用响应
    match json_deserialize(body) {
      Ok(json_body) =>
        // 解析真实的工具调用响应
        match parse_tool_openai_response(json_body) {
          Ok(tool_response) => Ok(tool_response)
          Err(parse_error) =>
            Err(
              (
                "json_parse_error",
                "Failed to parse tool OpenAI response: " + parse_error,
                status_code,
              ),
            )
        }
      Err(parse_error) =>
        Err(
          (
            "json_parse_error",
            "Failed to parse tool response: " + parse_error,
            status_code,
          ),
        )
    }
  } else {
    let error_message = "Tool API request failed (status " +
      status_code.to_string() +
      "): " +
      body
    Err(("api_error", error_message, status_code))
  }
}

// 结构化输出聊天完成

///|
pub async fn structured_chat_completion(
  client : OpenAIClient,
  messages : Array[Message],
  model : String,
  response_format : StructuredOutput,
) -> Result[ChatCompletionResponse, OpenAIError] {
  let (config, http_client) = client
  let (api_key, _base_url, _timeout, _retries, _user_agent, debug, _org, _proj) = config

  // 构建结构化输出请求体
  let request_body = build_structured_chat_completion_request(
    messages, model, response_format,
  )
  if debug {
    let _ = println("Structured request body: " + request_body)

  }

  // 发送HTTP请求
  let extra_headers = build_openai_extra_headers(config)
  let response_result = send_openai_request(
    http_client, api_key, "chat/completions", request_body, extra_headers,
  )
  match response_result {
    Ok(response) => {
      if debug {
        let _ = println("Structured response status: " + response.0.to_string())

      }
      if debug {
        let _ = println("Structured response body: " + response.2)

      }
      parse_structured_chat_completion_response(response)
    }
    Err(http_error) => {
      let (err_type, status_code, message) = http_error
      Err((err_type, message, status_code))
    }
  }
}

// 构建结构化输出请求体

///|
fn build_structured_chat_completion_request(
  messages : Array[Message],
  model : String,
  response_format : StructuredOutput,
) -> String {
  let messages_json = build_messages_json(messages)
  let (format_type, format_schema, format_content) = response_format
  let escaped_model = json_serialize(model)
  // 兼容旧值："json"/"object" 映射为 "json_object"
  let normalized_type = if format_type == "object" || format_type == "json" {
    "json_object"
  } else {
    format_type
  }
  let escaped_type = json_serialize(normalized_type)
  let response_format_json = if normalized_type == "json_object" {
    // 简单 JSON 对象要求：无需提供 schema
    "{\"type\":" + escaped_type + "}"
  } else if normalized_type == "json_schema" {
    // 新版 API：使用 json_schema 容器，并要求 name 与 schema
    let schema_name = if format_content.length() > 0 {
      format_content
    } else {
      "output"
    }
    let escaped_name = json_serialize(schema_name)
    "{\"type\":" +
    escaped_type +
    ",\"json_schema\":{\"name\":" +
    escaped_name +
    ",\"schema\":" +
    format_schema +
    ",\"strict\":true}}"
  } else {
    // 未知类型：降级为 json_object 以保证不失败
    "{\"type\":\"json_object\"}"
  }
  "{\"model\":" +
  escaped_model +
  ",\"messages\":" +
  messages_json +
  ",\"response_format\":" +
  response_format_json +
  "}"
}

// 解析结构化输出响应

///|
fn parse_structured_chat_completion_response(
  response : HttpResponse,
) -> Result[ChatCompletionResponse, OpenAIError] {
  let (status_code, _headers, body) = response
  if is_success_response(response) {
    // 解析结构化输出响应
    match json_deserialize(body) {
      Ok(json_body) =>
        // 解析真实的结构化输出响应
        match parse_structured_openai_response(json_body) {
          Ok(structured_response) => Ok(structured_response)
          Err(parse_error) =>
            Err(
              (
                "json_parse_error",
                "Failed to parse structured OpenAI response: " + parse_error,
                status_code,
              ),
            )
        }
      Err(parse_error) =>
        Err(
          (
            "json_parse_error",
            "Failed to parse structured response: " + parse_error,
            status_code,
          ),
        )
    }
  } else {
    let error_message = "Structured API request failed (status " +
      status_code.to_string() +
      "): " +
      body
    Err(("api_error", error_message, status_code))
  }
}

// 便捷函数：简单对话

///|
pub async fn simple_chat(
  client : OpenAIClient,
  message : String,
) -> Result[String, OpenAIError] {
  let messages = [user_message(message)]
  let response_result = chat_completion(client, messages, GPT_4O)
  match response_result {
    Ok(response) =>
      if response.4.length() > 0 {
        let choice = response.4.get(0)
        match choice {
          None => Ok("没有收到响应")
          Some(c) => Ok(c.1.1)
        }
      } else {
        Ok("没有收到响应")
      }
    Err(error) => Err(error)
  }
}

// 流式对话处理

///|
pub async fn stream_chat(
  client : OpenAIClient,
  message : String,
) -> Result[String, OpenAIError] {
  let messages = [user_message(message)]
  let stream_responses_result = stream_chat_completion(client, messages, GPT_4O)
  match stream_responses_result {
    Ok(stream_responses) => {
      // 合并所有流式响应
      let mut full_content = ""
      let mut i = 0
      while i < stream_responses.length() {
        let response = stream_responses.get(i)
        match response {
          None => break
          Some(resp) =>
            if resp.4.length() > 0 {
              let choice = resp.4.get(0)
              match choice {
                None => {
                  let _ = ()

                }
                Some(c) =>
                  match c.1 {
                    None => {
                      let _ = ()

                    }
                    Some(msg) => full_content = full_content + msg.1
                  }
              }
            }
        }
        i = i + 1
      }
      if full_content == "" {
        Ok("")
      } else {
        Ok(full_content)
      }
    }
    Err(_error) => {
      // 回退到非流式请求，确保真实连通性
      let fallback_result = chat_completion(client, messages, GPT_4O)
      match fallback_result {
        Ok(response) =>
          if response.4.length() > 0 {
            let choice = response.4.get(0)
            match choice {
              None => Ok("没有收到响应")
              Some(c) => Ok(c.1.1)
            }
          } else {
            Ok("没有收到响应")
          }
        Err(e) => Err(e)
      }
    }
  }
}

// 工具调用对话

///|
pub async fn tool_chat(
  client : OpenAIClient,
  message : String,
  tools : Array[String],
) -> Result[(String, ToolCall?), OpenAIError] {
  let messages = [user_message(message)]
  let response_result = tool_chat_completion(client, messages, GPT_4O, tools)
  match response_result {
    Ok(response) =>
      if response.4.length() > 0 {
        let choice = response.4.get(0)
        match choice {
          None => Ok(("没有收到响应", None))
          Some(c) => Ok((c.1.1, c.3))
        }
      } else {
        Ok(("没有收到响应", None))
      }
    Err(error) => Err(error)
  }
}

// 结构化输出对话

///|
pub async fn structured_chat(
  client : OpenAIClient,
  message : String,
  output_format : StructuredOutput,
) -> Result[String, OpenAIError] {
  let messages = [user_message(message)]
  let response_result = structured_chat_completion(
    client,
    messages,
    GPT_4O,
    output_format,
  )
  match response_result {
    Ok(response) =>
      if response.4.length() > 0 {
        let choice = response.4.get(0)
        match choice {
          None => Ok("没有收到响应")
          Some(c) => Ok(c.1.1)
        }
      } else {
        Ok("没有收到响应")
      }
    Err(error) => Err(error)
  }
}

// 多轮对话工具调用

///|
pub async fn multi_turn_tool_chat(
  client : OpenAIClient,
  messages : Array[Message],
  tools : Array[String],
) -> Result[(String, ToolCall?, Array[Message]), OpenAIError] {
  let response_result = tool_chat_completion(client, messages, GPT_4O, tools)
  match response_result {
    Ok(response) =>
      if response.4.length() > 0 {
        let choice = response.4.get(0)
        match choice {
          None => Ok(("没有收到响应", None, messages))
          Some(c) => {
            // 当存在工具调用时，不把占位助手文本追加到对话，避免对后续语义干扰
            let new_messages = match c.3 {
              None => messages + [c.1]
              Some(_tc) => messages
            }
            Ok((c.1.1, c.3, new_messages))
          }
        }
      } else {
        Ok(("没有收到响应", None, messages))
      }
    Err(error) => Err(error)
  }
}

// 处理工具调用结果

///|
pub async fn handle_tool_result(
  client : OpenAIClient,
  messages : Array[Message],
  tool_call : ToolCall,
  tool_result : String,
) -> Result[String, OpenAIError] {
  // 直接构造包含 tool_calls 的消息数组 JSON 并请求 chat/completions
  // 不对 arguments 进行硬编码，若模型未提供，我们仅传空对象字符串
  let messages_json = build_followup_messages_json(
    messages, tool_call, "{}", tool_result,
  )
  let escaped_model = json_serialize(GPT_4O)
  let request_body = "{\"model\":" +
    escaped_model +
    ",\"messages\":" +
    messages_json +
    "}"
  let (config, http_client) = client
  let (api_key, _base_url, _timeout, _retries, _user_agent, debug, _org, _proj) = config
  if debug {
    let _ = println("Request body: " + request_body)

  }
  let extra_headers = build_openai_extra_headers(config)
  let response_result = send_openai_request(
    http_client, api_key, "chat/completions", request_body, extra_headers,
  )
  match response_result {
    Ok(response) => {
      if debug {
        let _ = println("Response status: " + response.0.to_string())

      }
      if debug {
        let _ = println("Response body: " + response.2)

      }
      parse_chat_completion_response(response).map(fn(r) {
        if r.4.length() > 0 {
          let choice = r.4.get(0)
          match choice {
            Some(c) => c.1.1
            None => "没有收到响应"
          }
        } else {
          "没有收到响应"
        }
      })
    }
    Err(http_error) => {
      let (err_type, status_code, message) = http_error
      Err((err_type, message, status_code))
    }
  }
}

// 错误处理工具函数

///|
pub fn is_retryable_error(error : OpenAIError) -> Bool {
  let (_error_type, _message, status_code) = error
  status_code == 429 ||
  status_code == 500 ||
  status_code == 502 ||
  status_code == 503 ||
  status_code == 504
}

///|
pub fn get_error_message(error : OpenAIError) -> String {
  let (error_type, message, status_code) = error
  "OpenAI Error [" +
  status_code.to_string() +
  "]: " +
  error_type +
  " - " +
  message
}

// 配置工具函数

///|
pub fn enable_debug(client : OpenAIClient) -> OpenAIClient {
  let (config, _http_client) = client
  let (
    api_key,
    base_url,
    timeout,
    retries,
    user_agent,
    _debug,
    organization,
    project,
  ) = config
  let new_config = (
    api_key, base_url, timeout, retries, user_agent, true, organization, project,
  )
  (new_config, _http_client)
}

///|
pub fn set_timeout(
  client : OpenAIClient,
  timeout_seconds : Int,
) -> OpenAIClient {
  let (config, _http_client) = client
  let (
    api_key,
    base_url,
    _timeout,
    retries,
    user_agent,
    debug,
    organization,
    project,
  ) = config
  let new_config = (
    api_key, base_url, timeout_seconds, retries, user_agent, debug, organization,
    project,
  )
  let new_http_client = new_http_client_with_config(
    base_url, timeout_seconds, retries, user_agent,
  )
  (new_config, new_http_client)
}

// 设置最大重试次数

///|
pub fn set_retries(client : OpenAIClient, max_retries : Int) -> OpenAIClient {
  let (config, _http_client) = client
  let (
    api_key,
    base_url,
    timeout,
    _retries,
    user_agent,
    debug,
    organization,
    project,
  ) = config
  let new_config = (
    api_key, base_url, timeout, max_retries, user_agent, debug, organization, project,
  )
  let new_http_client = new_http_client_with_config(
    base_url, timeout, max_retries, user_agent,
  )
  (new_config, new_http_client)
}

// 解析流式OpenAI响应

///|
fn parse_stream_openai_response(
  json_body : String,
) -> Result[Array[StreamChatCompletionResponse], String] {
  // 实际的流式响应解析 - 使用真实的API响应格式
  if json_body.contains("\"id\"") && json_body.contains("\"choices\"") {
    // 提取基本信息
    let id = extract_json_field(json_body, "id").unwrap_or("chatcmpl-unknown")
    let model = extract_json_field(json_body, "model").unwrap_or(GPT_4O)
    let created = extract_json_field(json_body, "created").unwrap_or("0")
    let created_int = string_to_int(created)

    // 解析流式choices
    let stream_choices = parse_stream_choices(json_body)

    // 解析usage（可能为空）
    let usage = if json_body.contains("\"usage\"") {
      Some(parse_usage(json_body))
    } else {
      None
    }
    let response : StreamChatCompletionResponse = (
      id, "chat.completion.chunk", created_int, model, stream_choices, usage,
    )
    Ok([response])
  } else {
    Err("Invalid stream OpenAI response format")
  }
}

// 解析工具调用OpenAI响应

///|
fn parse_tool_openai_response(
  json_body : String,
) -> Result[ChatCompletionResponse, String] {
  // 实际的工具调用响应解析
  if json_body.contains("\"id\"") && json_body.contains("\"choices\"") {
    // 提取基本信息
    let id = extract_json_field(json_body, "id").unwrap_or("chatcmpl-unknown")
    let model = extract_json_field(json_body, "model").unwrap_or(GPT_4O)
    let created = extract_json_field(json_body, "created").unwrap_or("0")
    let created_int = string_to_int(created)

    // 解析工具调用choices
    let tool_choices = parse_tool_choices(json_body)

    // 解析usage
    let usage = parse_usage(json_body)
    let response : ChatCompletionResponse = (
      id, "chat.completion", created_int, model, tool_choices, usage,
    )
    Ok(response)
  } else {
    Err("Invalid tool OpenAI response format")
  }
}

// 解析结构化输出OpenAI响应

///|
fn parse_structured_openai_response(
  json_body : String,
) -> Result[ChatCompletionResponse, String] {
  // 实际的结构化输出响应解析
  if json_body.contains("\"id\"") && json_body.contains("\"choices\"") {
    // 提取基本信息
    let id = extract_json_field(json_body, "id").unwrap_or("chatcmpl-unknown")
    let model = extract_json_field(json_body, "model").unwrap_or(GPT_4O)
    let created = extract_json_field(json_body, "created").unwrap_or("0")
    let created_int = string_to_int(created)

    // 解析结构化输出choices
    let structured_choices = parse_choices(json_body)

    // 解析usage
    let usage = parse_usage(json_body)
    let response : ChatCompletionResponse = (
      id, "chat.completion", created_int, model, structured_choices, usage,
    )
    Ok(response)
  } else {
    Err("Invalid structured OpenAI response format")
  }
}

// 解析流式choices

///|
fn parse_stream_choices(json_body : String) -> Array[StreamChoice] {
  // 避免将占位符当作内容；仅在存在 message/delta 的 content 时返回
  let content_opt = extract_choice_message_content(json_body)
  let delta_message = match content_opt {
    Some(s) => if s.length() > 0 { Some(assistant_message(s)) } else { None }
    None => None
  }
  let finish_reason = extract_json_field(json_body, "finish_reason").unwrap_or(
    "null",
  )
  let actual_finish_reason = if finish_reason == "null" {
    "null"
  } else {
    finish_reason
  }
  let stream_choice : StreamChoice = (
    0,
    delta_message,
    actual_finish_reason,
    None,
  )
  [stream_choice]
}

// 解析工具调用choices

///|
fn parse_tool_choices(json_body : String) -> Array[Choice] {
  // 解析包含 tool_calls 的助手消息
  let content = extract_choice_content(json_body)
  let finish_reason = extract_json_field(json_body, "finish_reason").unwrap_or(
    "stop",
  )
  let tool_call_option = if json_body.contains("\"tool_calls\"") {
    let tc_pos_opt = find_substring(json_body, "\"tool_calls\"")
    match tc_pos_opt {
      None => None
      Some(tc_pos) => {
        let tail = extract_substring(json_body, tc_pos, json_body.length())
        let id_opt = extract_string_value_for_key(tail, "id", 0)
        let name_opt = extract_string_value_for_key(tail, "name", 0)
        // arguments 可能是嵌套对象或字符串，这里只取字符串形式，拿不到则给空对象
        let args_opt = extract_string_value_for_key(tail, "arguments", 0)
        match (id_opt, name_opt) {
          (Some(tid), Some(fname)) =>
            Some(tool_call(tid, fname, args_opt.unwrap_or("{}")))
          _ => None
        }
      }
    }
  } else {
    None
  }
  let choice : Choice = (
    0,
    assistant_message(content),
    finish_reason,
    tool_call_option,
  )
  [choice]
}

// =============== 工具调用辅助函数与真实天气查询 ===============

// 简易 URL 编码（处理常见字符与空格）

///|
fn url_encode_simple(s : String) -> String {
  let mut out = ""
  let mut i = 0
  while i < s.length() {
    let ch_opt = s.get(i)
    match ch_opt {
      None => {
        let _ = ()

      }
      Some(ch) =>
        if ch == ' ' {
          out = out + "%20"
        } else {
          out = out + Int::unsafe_to_char(ch).to_string()
        }
    }
    i = i + 1
  }
  out
}

// 从消息数组中提取最后一条用户问题

///|
fn extract_last_user_message(messages : Array[Message]) -> String? {
  let mut idx = messages.length()
  while idx > 0 {
    idx = idx - 1
    let msg_opt = messages.get(idx)
    match msg_opt {
      Some(m) => if m.0 == USER_ROLE { return Some(m.1) }
      None => {
        let _ = ()

      }
    }
  }
  None
}

// 朴素地从问题中抽取地名（英文 " in <City>" 或中文 "在<城市>天气"）

///|
pub fn extract_location_from_question(q : String) -> String? {
  let in_pos_opt = find_substring(q, " in ")
  match in_pos_opt {
    Some(in_pos) => {
      let start = in_pos + 4
      let mut end = q.length()
      let q_mark = find_substring_from(q, "?", start)
      match q_mark {
        Some(pos) => if pos < end { end = pos }
        None => ()
      }
      let dot_mark = find_substring_from(q, ".", start)
      match dot_mark {
        Some(pos) => if pos < end { end = pos }
        None => ()
      }
      let excl_mark = find_substring_from(q, "!", start)
      match excl_mark {
        Some(pos) => if pos < end { end = pos }
        None => ()
      }
      let raw = trim(extract_substring(q, start, end))
      let mut cleaned = raw
      let last_idx = cleaned.length() - 1
      if cleaned.length() > 0 && cleaned.get(last_idx) == Some(',') {
        cleaned = extract_substring(cleaned, 0, last_idx)
      }
      if cleaned.length() > 0 {
        Some(cleaned)
      } else {
        None
      }
    }
    None => {
      let zai_pos = find_substring(q, "在")
      let tq_pos = find_substring(q, "天气")
      match (zai_pos, tq_pos) {
        (Some(zp), Some(tp)) =>
          if tp > zp {
            let name = trim(extract_substring(q, zp + 1, tp))
            if name.length() > 0 {
              Some(name)
            } else {
              None
            }
          } else {
            None
          }
        _ => None
      }
    }
  }
}

// 地理编码：返回 (latitude, longitude)

///|
async fn geocode_location(
  location : String,
  timeout : Int,
) -> Result[(String, String), String] {
  let url = "https://geocoding-api.open-meteo.com/v1/search?name=" +
    url_encode_simple(location) +
    "&count=1&language=en&format=json"
  match perform_http_request("GET", url, [], "", timeout) {
    Ok(resp) =>
      if resp.0 >= 200 && resp.0 < 300 {
        let body = resp.2
        match find_substring(body, "\"results\"") {
          None => Err("no_results")
          Some(pos) => {
            let tail = extract_substring(body, pos, body.length())
            let lat_opt = extract_json_field(tail, "latitude")
            let lon_opt = extract_json_field(tail, "longitude")
            match (lat_opt, lon_opt) {
              (Some(lat), Some(lon)) => Ok((trim(lat), trim(lon)))
              _ => Err("latlon_not_found")
            }
          }
        }
      } else {
        Err("geocode_http_" + resp.0.to_string())
      }
    Err(e) => Err("geocode_error_" + e.0 + "_" + e.2)
  }
}

// 查询实时天气（Open-Meteo）

///|
pub async fn fetch_weather_for_location(
  client : OpenAIClient,
  location : String,
) -> Result[String, String] {
  let (config, _hc) = client
  let (_api_key, _base_url, timeout, _retries, _ua, _debug, _org, _proj) = config
  let to = if timeout > 0 { timeout } else { 20 }
  match geocode_location(location, to) {
    Ok((lat, lon)) => {
      let url = "https://api.open-meteo.com/v1/forecast?current_weather=true&latitude=" +
        lat +
        "&longitude=" +
        lon
      match perform_http_request("GET", url, [], "", to) {
        Ok(resp) =>
          if resp.0 >= 200 && resp.0 < 300 {
            let b = resp.2
            // Narrow to the current_weather object to avoid matching unit fields
            let cw_key = "\"current_weather\""
            let cw_pos_opt = find_substring(b, cw_key)
            let mut temp = ""
            let mut wind = ""
            match cw_pos_opt {
              None => ()
              Some(cw_pos) => {
                let brace_start_opt = find_substring_from(b, "{", cw_pos)
                match brace_start_opt {
                  None => ()
                  Some(bs) => {
                    // Find matching closing brace for the current_weather object
                    let mut i = bs
                    let mut brace_count = 0
                    let mut in_string = false
                    let mut escape_next = false
                    let mut end_idx : Int = -1
                    while i < b.length() {
                      let ch_opt = b.get(i)
                      match ch_opt {
                        None => break
                        Some(ch) =>
                          if in_string {
                            if escape_next {
                              escape_next = false
                            } else if ch == '\\' {
                              escape_next = true
                            } else if ch == '"' {
                              in_string = false
                            }
                          } else if ch == '"' {
                            in_string = true
                          } else if ch == '{' {
                            brace_count = brace_count + 1
                          } else if ch == '}' {
                            brace_count = brace_count - 1
                            if brace_count == 0 {
                              end_idx = i
                              break
                            }
                          } else {
                            ()
                          }
                      }
                      i = i + 1
                    }
                    if end_idx > bs {
                      let cw_json = extract_substring(b, bs, end_idx + 1)
                      let t_raw = trim(
                        extract_json_field(cw_json, "temperature").unwrap_or(""),
                      )
                      let w_raw = trim(
                        extract_json_field(cw_json, "windspeed").unwrap_or(""),
                      )
                      // Strip quotes if present (defensive)
                      let t_clean = if t_raw.length() >= 2 &&
                        t_raw.get(0) == Some('"') &&
                        t_raw.get(t_raw.length() - 1) == Some('"') {
                        extract_substring(t_raw, 1, t_raw.length() - 1)
                      } else {
                        t_raw
                      }
                      let w_clean = if w_raw.length() >= 2 &&
                        w_raw.get(0) == Some('"') &&
                        w_raw.get(w_raw.length() - 1) == Some('"') {
                        extract_substring(w_raw, 1, w_raw.length() - 1)
                      } else {
                        w_raw
                      }
                      temp = t_clean
                      wind = w_clean
                    }
                  }
                }
              }
            }
            let mut out = ""
            if temp.length() > 0 && wind.length() > 0 {
              out = "Weather in " +
                location +
                ": " +
                temp +
                "°C, Wind: " +
                wind +
                " km/h"
            } else if temp.length() > 0 {
              out = "Weather in " + location + ": " + temp + "°C"
            } else {
              out = "Weather data unavailable for " + location
            }
            Ok(out)
          } else {
            Err("weather_http_" + resp.0.to_string())
          }
        Err(e) => Err("weather_error_" + e.0 + "_" + e.2)
      }
    }
    Err(err) => Err(err)
  }
}

// 构造包含 assistant.tool_calls 与 tool 消息的 messages JSON

///|
fn build_followup_messages_json(
  base_messages : Array[Message],
  tool_call : ToolCall,
  arguments_obj_json : String,
  tool_result : String,
) -> String {
  let mut json = "["
  let mut first = true
  let mut i = 0
  while i < base_messages.length() {
    let mo = base_messages.get(i)
    match mo {
      None => {
        i = i + 1
        continue
      }
      Some(m) => {
        if first {
          first = false
        } else {
          json = json + ","
        }
        let er = json_serialize(m.0)
        let ec = json_serialize(m.1)
        json = json + "{\"role\":" + er + ",\"content\":" + ec + "}"
      }
    }
    i = i + 1
  }
  // assistant 带 tool_calls 的消息
  if first {
    first = false
  } else {
    json = json + ","
  }
  let id_json = json_serialize(tool_call.0)
  let name_json = json_serialize(tool_call.2)
  // 优先使用模型返回的 arguments，若调用方传了覆盖值则使用覆盖值
  let args_value = if arguments_obj_json.length() > 0 &&
    arguments_obj_json != "{}" {
    arguments_obj_json
  } else {
    tool_call.3
  }
  let args_string_json = json_serialize(args_value)
  json = json +
    "{\"role\":\"assistant\",\"content\":null,\"tool_calls\":[{\"id\":" +
    id_json +
    ",\"type\":\"function\",\"function\":{\"name\":" +
    name_json +
    ",\"arguments\":" +
    args_string_json +
    "}}]}"
  // tool 消息
  let tool_content = json_serialize(tool_result)
  json = json +
    ",{\"role\":\"tool\",\"tool_call_id\":" +
    id_json +
    ",\"content\":" +
    tool_content +
    "}]"
  json
}
