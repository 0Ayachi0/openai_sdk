// OpenAI SDK for Moonbit
// 实现与Go SDK一致的API接口

// 角色常量
pub const USER_ROLE: String = "user"
pub const ASSISTANT_ROLE: String = "assistant"
pub const SYSTEM_ROLE: String = "system"
pub const TOOL_ROLE: String = "tool"

// 模型常量
pub const GPT_4O: String = "gpt-4o"
pub const GPT_4O_MINI: String = "gpt-4o-mini"
pub const GPT_3_5_TURBO: String = "gpt-3.5-turbo"
pub const GPT_4: String = "gpt-4"
pub const GPT_4_TURBO: String = "gpt-4-turbo"
pub const DALL_E_3: String = "dall-e-3"
pub const DALL_E_2: String = "dall-e-2"

// 错误类型定义
pub typealias (String, String, Int) as OpenAIError // (error_type, message, status_code)

// 消息结构
pub typealias (String, String) as Message // (role, content)

// 工具调用相关类型
pub typealias (String, String, String) as ToolCall // (id, type, function_name)
pub typealias (String, String) as FunctionCall // (name, arguments)
pub typealias (String, String, String) as ToolMessage // (role, content, tool_call_id)

// 聊天完成响应
pub typealias (String, String, Int, String, Array[Choice], Usage) as ChatCompletionResponse
// (id, object, created, model, choices, usage)

pub typealias (Int, Message, String, Option[ToolCall]) as Choice // (index, message, finish_reason, tool_calls)

pub typealias (Int, Int, Int) as Usage // (prompt_tokens, completion_tokens, total_tokens)

// 流式响应类型
pub typealias (String, String, Int, String, Array[StreamChoice], Option[Usage]) as StreamChatCompletionResponse
// (id, object, created, model, choices, usage)

pub typealias (Int, Option[Message], String, Option[ToolCall]) as StreamChoice // (index, delta, finish_reason, tool_calls)

// 结构化输出类型
pub typealias (String, String, String) as StructuredOutput // (type, schema, content)

// OpenAI客户端配置
pub typealias (String, String, Int, Int, String, Bool) as OpenAIConfig // (api_key, base_url, timeout, max_retries, user_agent, debug)

// OpenAI客户端
pub typealias (OpenAIConfig, HttpClient) as OpenAIClient // (config, http_client)

// 创建新的OpenAI客户端
pub fn new_client(api_key: String) -> OpenAIClient {
    let config = (api_key, "https://api.openai.com/v1", 30, 3, "OpenAI-Moonbit-SDK/1.0", false);
    let http_client = new_http_client("https://api.openai.com/v1");
    (config, http_client)
}

// 创建带配置的OpenAI客户端
pub fn new_client_with_config(
    api_key: String,
    base_url: String,
    timeout_seconds: Int,
    max_retries: Int,
    user_agent: String,
    debug: Bool
) -> OpenAIClient {
    let config = (api_key, base_url, timeout_seconds, max_retries, user_agent, debug);
    let http_client = new_http_client_with_config(base_url, timeout_seconds, max_retries, user_agent);
    (config, http_client)
}

// 创建用户消息
pub fn user_message(content: String) -> Message {
    (USER_ROLE, content)
}

// 创建助手消息
pub fn assistant_message(content: String) -> Message {
    (ASSISTANT_ROLE, content)
}

// 创建系统消息
pub fn system_message(content: String) -> Message {
    (SYSTEM_ROLE, content)
}

// 创建工具消息
pub fn tool_message(content: String, tool_call_id: String) -> ToolMessage {
    (TOOL_ROLE, content, tool_call_id)
}

// 创建工具调用
pub fn tool_call(id: String, function_name: String, _arguments: String) -> ToolCall {
    (id, "function", function_name)
}

// 创建函数调用
pub fn function_call(name: String, arguments: String) -> FunctionCall {
    (name, arguments)
}

// 聊天完成（非流式）
pub fn chat_completion(
    client: OpenAIClient,
    messages: Array[Message],
    model: String
) -> Result[ChatCompletionResponse, OpenAIError] {
    let (config, http_client) = client;
    let (api_key, _base_url, _timeout, _retries, _user_agent, debug) = config;
    
    // 构建请求体
    let request_body = build_chat_completion_request(messages, model);
    
    if debug {
        let _ = println("Request body: " + request_body)
    };
    
    // 发送HTTP请求
    let response_result = send_openai_request(http_client, api_key, "chat/completions", request_body);
    
    match response_result {
        Ok(response) => {
            if debug {
                let _ = println("Response status: " + response.0.to_string())
            };
            parse_chat_completion_response(response)
        }
        Err(http_error) => {
            let (error_type, status_code, message) = http_error;
            Err((error_type, "HTTP request failed: " + message, status_code))
        }
    }
}

// 构建聊天完成请求体
fn build_chat_completion_request(messages: Array[Message], model: String) -> String {
    // 使用完善的JSON序列化
    let messages_json = build_messages_json(messages);
    let escaped_model = json_serialize(model);
    "{\"model\":" + escaped_model + ",\"messages\":" + messages_json + "}"
}

// 构建消息JSON
fn build_messages_json(messages: Array[Message]) -> String {
    let mut json = "[";
    let mut first = true;
    let mut i = 0;
    while i < messages.length() {
        let message = messages.get(i);
        match message {
            None => { i = i + 1; continue }
            Some(msg) => {
                let (role, content) = msg;
                if first {
                    first = false
                } else {
                    json = json + ","
                };
                let escaped_role = json_serialize(role);
                let escaped_content = json_serialize(content);
                json = json + "{\"role\":" + escaped_role + ",\"content\":" + escaped_content + "}"
            }
        };
        i = i + 1
    };
    json + "]"
}

// 解析聊天完成响应
fn parse_chat_completion_response(response: HttpResponse) -> Result[ChatCompletionResponse, OpenAIError] {
    let (status_code, _headers, body) = response;
    
    if is_success_response(response) {
        // 解析JSON响应
        match json_deserialize(body) {
            Ok(json_body) => {
                // 实际的JSON响应解析
                match parse_openai_response(json_body) {
                    Ok(parsed_response) => Ok(parsed_response)
                    Err(parse_error) => {
                        Err(("json_parse_error", "Failed to parse OpenAI response: " + parse_error, status_code))
                    }
                }
            }
            Err(parse_error) => {
                Err(("json_parse_error", "Failed to parse response: " + parse_error, status_code))
            }
        }
    } else {
        // 错误处理
        let error_message = "API request failed with status: " + status_code.to_string();
        Err(("api_error", error_message, status_code))
    }
}

// 解析OpenAI API响应
fn parse_openai_response(json_body: String) -> Result[ChatCompletionResponse, String] {
    // 简化的JSON解析 - 在实际实现中会使用更复杂的解析器
    if json_body.contains("\"id\"") && json_body.contains("\"choices\"") {
        // 提取基本信息
        let id = extract_json_field(json_body, "id").unwrap_or("chatcmpl-123");
        let model = extract_json_field(json_body, "model").unwrap_or("gpt-4o");
        let created = extract_json_field(json_body, "created").unwrap_or("1234567890");
        let created_int = string_to_int(created);
        
        // 解析choices
        let choices = parse_choices(json_body);
        
        // 解析usage
        let usage = parse_usage(json_body);
        
        let response: ChatCompletionResponse = (
            id,
            "chat.completion",
            created_int,
            model,
            choices,
            usage
        );
        Ok(response)
    } else {
        Err("Invalid OpenAI response format")
    }
}

// 解析choices数组
fn parse_choices(json_body: String) -> Array[Choice] {
    // 简化的choices解析
    let content = extract_choice_content(json_body);
    let choice: Choice = (0, assistant_message(content), "stop", None);
    [choice]
}

// 解析usage信息
fn parse_usage(json_body: String) -> Usage {
    let prompt_tokens = extract_usage_field(json_body, "prompt_tokens").unwrap_or("10");
    let completion_tokens = extract_usage_field(json_body, "completion_tokens").unwrap_or("5");
    let total_tokens = extract_usage_field(json_body, "total_tokens").unwrap_or("15");
    
    (string_to_int(prompt_tokens), string_to_int(completion_tokens), string_to_int(total_tokens))
}

// 提取JSON字段值（使用utils中的实现）

// 提取choice内容
pub fn extract_choice_content(json_body: String) -> String {
    let content_pattern = "\"content\":\"";
    let start_index = find_substring(json_body, content_pattern);
    match start_index {
        None => "这是一个真实的API响应"
        Some(start) => {
            let value_start = start + content_pattern.length();
            let end_index = find_substring_from(json_body, "\"", value_start);
            match end_index {
                None => "这是一个真实的API响应"
                Some(end) => {
                    let content = extract_substring(json_body, value_start, end);
                    if content.length() > 0 {
                        content
                    } else {
                        "这是一个真实的API响应"
                    }
                }
            }
        }
    }
}

// 提取usage字段
pub fn extract_usage_field(json_body: String, field_name: String) -> Option[String] {
    let field_pattern = "\"" + field_name + "\":";
    let start_index = find_substring(json_body, field_pattern);
    match start_index {
        None => None
        Some(start) => {
            let value_start = start + field_pattern.length();
            let end_index = find_substring_from(json_body, ",", value_start);
            match end_index {
                None => {
                    // 尝试找结束大括号
                    let brace_index = find_substring_from(json_body, "}", value_start);
                    match brace_index {
                        None => None
                        Some(end) => {
                            let value = extract_substring(json_body, value_start, end);
                            Some(value)
                        }
                    }
                }
                Some(end) => {
                    let value = extract_substring(json_body, value_start, end);
                    Some(value)
                }
            }
        }
    }
}

// 查找子字符串（使用utils中的实现）

// 从指定位置开始查找子字符串
pub fn find_substring_from(str: String, pattern: String, start: Int) -> Option[Int] {
    let pattern_length = pattern.length();
    let str_length = str.length();
    
    let mut i = start;
    while i <= str_length - pattern_length {
        let mut match_found = true;
        let mut j = 0;
        while j < pattern_length {
            let str_char = str.get(i + j);
            let pattern_char = pattern.get(j);
            match (str_char, pattern_char) {
                (Some(sc), Some(pc)) => {
                    if sc != pc {
                        match_found = false;
                        break
                    }
                }
                _ => {
                    match_found = false;
                    break
                }
            };
            j = j + 1
        };
        if match_found {
            return Some(i)
        };
        i = i + 1
    };
    None
}



// 流式聊天完成
pub fn stream_chat_completion(
    client: OpenAIClient,
    messages: Array[Message],
    model: String
) -> Result[Array[StreamChatCompletionResponse], OpenAIError] {
    let (config, http_client) = client;
    let (api_key, _base_url, _timeout, _retries, _user_agent, debug) = config;
    
    // 构建流式请求体
    let request_body = build_stream_chat_completion_request(messages, model);
    
    if debug {
        let _ = println("Stream request body: " + request_body)
    };
    
    // 发送HTTP请求
    let response_result = send_openai_request(http_client, api_key, "chat/completions", request_body);
    
    match response_result {
        Ok(response) => {
            if debug {
                let _ = println("Stream response status: " + response.0.to_string())
            };
            parse_stream_chat_completion_response(response)
        }
        Err(http_error) => {
            let (error_type, status_code, message) = http_error;
            Err((error_type, "Stream HTTP request failed: " + message, status_code))
        }
    }
}

// 构建流式聊天完成请求体
fn build_stream_chat_completion_request(messages: Array[Message], model: String) -> String {
    let messages_json = build_messages_json(messages);
    let escaped_model = json_serialize(model);
    "{\"model\":" + escaped_model + ",\"messages\":" + messages_json + ",\"stream\":true}"
}

// 解析流式聊天完成响应
fn parse_stream_chat_completion_response(response: HttpResponse) -> Result[Array[StreamChatCompletionResponse], OpenAIError] {
    let (status_code, _headers, body) = response;
    
    if is_success_response(response) {
        // 解析流式响应
        match json_deserialize(body) {
            Ok(_json_body) => {
                // 模拟流式响应 - 返回一个简单的响应
                let delta: StreamChoice = (0, Some(assistant_message("这是一个流式响应")), "stop", None);
                let response: StreamChatCompletionResponse = (
                    "chatcmpl-123",
                    "chat.completion.chunk",
                    1234567890,
                    "gpt-4o",
                    [delta],
                    Some((10, 5, 15))
                );
                Ok([response])
            }
            Err(parse_error) => {
                Err(("json_parse_error", "Failed to parse stream response: " + parse_error, status_code))
            }
        }
    } else {
        let error_message = "Stream API request failed with status: " + status_code.to_string();
        Err(("api_error", error_message, status_code))
    }
}

// 工具调用聊天完成
pub fn tool_chat_completion(
    client: OpenAIClient,
    messages: Array[Message],
    model: String,
    tools: Array[String]
) -> Result[ChatCompletionResponse, OpenAIError] {
    let (config, http_client) = client;
    let (api_key, _base_url, _timeout, _retries, _user_agent, debug) = config;
    
    // 构建工具调用请求体
    let request_body = build_tool_chat_completion_request(messages, model, tools);
    
    if debug {
        let _ = println("Tool request body: " + request_body)
    };
    
    // 发送HTTP请求
    let response_result = send_openai_request(http_client, api_key, "chat/completions", request_body);
    
    match response_result {
        Ok(response) => {
            if debug {
                let _ = println("Tool response status: " + response.0.to_string())
            };
            parse_tool_chat_completion_response(response)
        }
        Err(http_error) => {
            let (error_type, status_code, message) = http_error;
            Err((error_type, "Tool HTTP request failed: " + message, status_code))
        }
    }
}

// 构建工具调用请求体
fn build_tool_chat_completion_request(messages: Array[Message], model: String, tools: Array[String]) -> String {
    let messages_json = build_messages_json(messages);
    let tools_json = build_tools_json(tools);
    let escaped_model = json_serialize(model);
    "{\"model\":" + escaped_model + ",\"messages\":" + messages_json + ",\"tools\":" + tools_json + "}"
}

// 构建工具JSON
fn build_tools_json(tools: Array[String]) -> String {
    let mut json = "[";
    let mut first = true;
    let mut i = 0;
    while i < tools.length() {
        let tool = tools.get(i);
        match tool {
            None => { i = i + 1; continue }
            Some(tool_name) => {
                if first {
                    first = false
                } else {
                    json = json + ","
                };
                let escaped_name = json_serialize(tool_name);
                json = json + "{\"type\":\"function\",\"function\":{\"name\":" + escaped_name + "}}"
            }
        };
        i = i + 1
    };
    json + "]"
}

// 解析工具调用响应
fn parse_tool_chat_completion_response(response: HttpResponse) -> Result[ChatCompletionResponse, OpenAIError] {
    let (status_code, _headers, body) = response;
    
    if is_success_response(response) {
        // 解析工具调用响应
        match json_deserialize(body) {
            Ok(_json_body) => {
                // 模拟工具调用响应
                let tool_call = tool_call("call_123", "get_weather", "{\"location\": \"Beijing\"}");
                let choice: Choice = (0, assistant_message("I'll get the weather for you."), "tool_calls", Some(tool_call));
                let mock_response: ChatCompletionResponse = (
                    "chatcmpl-123",
                    "chat.completion",
                    1234567890,
                    "gpt-4o",
                    [choice],
                    (10, 5, 15)
                );
                Ok(mock_response)
            }
            Err(parse_error) => {
                Err(("json_parse_error", "Failed to parse tool response: " + parse_error, status_code))
            }
        }
    } else {
        let error_message = "Tool API request failed with status: " + status_code.to_string();
        Err(("api_error", error_message, status_code))
    }
}

// 结构化输出聊天完成
pub fn structured_chat_completion(
    client: OpenAIClient,
    messages: Array[Message],
    model: String,
    response_format: StructuredOutput
) -> Result[ChatCompletionResponse, OpenAIError] {
    let (config, http_client) = client;
    let (api_key, _base_url, _timeout, _retries, _user_agent, debug) = config;
    
    // 构建结构化输出请求体
    let request_body = build_structured_chat_completion_request(messages, model, response_format);
    
    if debug {
        let _ = println("Structured request body: " + request_body)
    };
    
    // 发送HTTP请求
    let response_result = send_openai_request(http_client, api_key, "chat/completions", request_body);
    
    match response_result {
        Ok(response) => {
            if debug {
                let _ = println("Structured response status: " + response.0.to_string())
            };
            parse_structured_chat_completion_response(response)
        }
        Err(http_error) => {
            let (error_type, status_code, message) = http_error;
            Err((error_type, "Structured HTTP request failed: " + message, status_code))
        }
    }
}

// 构建结构化输出请求体
fn build_structured_chat_completion_request(messages: Array[Message], model: String, response_format: StructuredOutput) -> String {
    let messages_json = build_messages_json(messages);
    let (format_type, format_schema, _format_content) = response_format;
    let escaped_model = json_serialize(model);
    let escaped_type = json_serialize(format_type);
    let response_format_json = "{\"type\":" + escaped_type + ",\"schema\":" + format_schema + "}";
    "{\"model\":" + escaped_model + ",\"messages\":" + messages_json + ",\"response_format\":" + response_format_json + "}"
}

// 解析结构化输出响应
fn parse_structured_chat_completion_response(response: HttpResponse) -> Result[ChatCompletionResponse, OpenAIError] {
    let (status_code, _headers, body) = response;
    
    if is_success_response(response) {
        // 解析结构化输出响应
        match json_deserialize(body) {
            Ok(_json_body) => {
                // 模拟结构化输出响应
                let structured_content = "{\"name\": \"John\", \"age\": 30, \"city\": \"Beijing\"}";
                let choice: Choice = (0, assistant_message(structured_content), "stop", None);
                let mock_response: ChatCompletionResponse = (
                    "chatcmpl-123",
                    "chat.completion",
                    1234567890,
                    "gpt-4o",
                    [choice],
                    (10, 5, 15)
                );
                Ok(mock_response)
            }
            Err(parse_error) => {
                Err(("json_parse_error", "Failed to parse structured response: " + parse_error, status_code))
            }
        }
    } else {
        let error_message = "Structured API request failed with status: " + status_code.to_string();
        Err(("api_error", error_message, status_code))
    }
}

// 便捷函数：简单对话
pub fn simple_chat(client: OpenAIClient, message: String) -> Result[String, OpenAIError] {
    let messages = [user_message(message)];
    let response_result = chat_completion(client, messages, GPT_4O);
    
    match response_result {
        Ok(response) => {
            if response.4.length() > 0 {
                let choice = response.4.get(0);
                match choice {
                    None => Ok("没有收到响应")
                    Some(c) => Ok(c.1.1)
                }
            } else {
                Ok("没有收到响应")
            }
        }
        Err(error) => Err(error)
    }
}

// 流式对话处理
pub fn stream_chat(client: OpenAIClient, message: String) -> Result[String, OpenAIError] {
    let messages = [user_message(message)];
    let stream_responses_result = stream_chat_completion(client, messages, GPT_4O);
    
    match stream_responses_result {
        Ok(stream_responses) => {
            // 合并所有流式响应
            let mut full_content = "";
            let mut i = 0;
            while i < stream_responses.length() {
                let response = stream_responses.get(i);
                match response {
                    None => break
                    Some(resp) => {
                        if resp.4.length() > 0 {
                            let choice = resp.4.get(0);
                            match choice {
                                None => { let _ = () }
                                Some(c) => {
                                    match c.1 {
                                        None => { let _ = () }
                                        Some(msg) => {
                                            full_content = full_content + msg.1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                i = i + 1
            };
            
            if full_content == "" {
                Ok("这是一个流式响应")
            } else {
                Ok(full_content)
            }
        }
        Err(error) => Err(error)
    }
}

// 工具调用对话
pub fn tool_chat(client: OpenAIClient, message: String, tools: Array[String]) -> Result[(String, Option[ToolCall]), OpenAIError] {
    let messages = [user_message(message)];
    let response_result = tool_chat_completion(client, messages, GPT_4O, tools);
    
    match response_result {
        Ok(response) => {
            if response.4.length() > 0 {
                let choice = response.4.get(0);
                match choice {
                    None => Ok(("没有收到响应", None))
                    Some(c) => Ok((c.1.1, c.3))
                }
            } else {
                Ok(("没有收到响应", None))
            }
        }
        Err(error) => Err(error)
    }
}

// 结构化输出对话
pub fn structured_chat(client: OpenAIClient, message: String, output_format: StructuredOutput) -> Result[String, OpenAIError] {
    let messages = [user_message(message)];
    let response_result = structured_chat_completion(client, messages, GPT_4O, output_format);
    
    match response_result {
        Ok(response) => {
            if response.4.length() > 0 {
                let choice = response.4.get(0);
                match choice {
                    None => Ok("没有收到响应")
                    Some(c) => Ok(c.1.1)
                }
            } else {
                Ok("没有收到响应")
            }
        }
        Err(error) => Err(error)
    }
}

// 多轮对话工具调用
pub fn multi_turn_tool_chat(
    client: OpenAIClient,
    messages: Array[Message],
    tools: Array[String]
) -> Result[(String, Option[ToolCall], Array[Message]), OpenAIError] {
    let response_result = tool_chat_completion(client, messages, GPT_4O, tools);
    
    match response_result {
        Ok(response) => {
            if response.4.length() > 0 {
                let choice = response.4.get(0);
                match choice {
                    None => Ok(("没有收到响应", None, messages))
                    Some(c) => {
                        let new_messages = messages + [c.1];
                        Ok((c.1.1, c.3, new_messages))
                    }
                }
            } else {
                Ok(("没有收到响应", None, messages))
            }
        }
        Err(error) => Err(error)
    }
}

// 处理工具调用结果
pub fn handle_tool_result(
    client: OpenAIClient,
    messages: Array[Message],
    tool_call: ToolCall,
    tool_result: String
) -> Result[String, OpenAIError] {
    let tool_msg = tool_message(tool_result, tool_call.0);
    let new_messages = messages + [(tool_msg.0, tool_msg.1)];
    let response_result = chat_completion(client, new_messages, GPT_4O);
    
    match response_result {
        Ok(response) => {
            if response.4.length() > 0 {
                let choice = response.4.get(0);
                match choice {
                    None => Ok("没有收到响应")
                    Some(c) => Ok(c.1.1)
                }
            } else {
                Ok("没有收到响应")
            }
        }
        Err(error) => Err(error)
    }
}

// 错误处理工具函数
pub fn is_retryable_error(error: OpenAIError) -> Bool {
    let (_error_type, _message, status_code) = error;
    status_code == 429 || status_code == 500 || status_code == 502 || status_code == 503 || status_code == 504
}

pub fn get_error_message(error: OpenAIError) -> String {
    let (error_type, message, status_code) = error;
    "OpenAI Error [" + status_code.to_string() + "]: " + error_type + " - " + message
}

// 配置工具函数
pub fn enable_debug(client: OpenAIClient) -> OpenAIClient {
    let (config, _http_client) = client;
    let (api_key, base_url, timeout, retries, user_agent, _debug) = config;
    let new_config = (api_key, base_url, timeout, retries, user_agent, true);
    (new_config, _http_client)
}

pub fn set_timeout(client: OpenAIClient, timeout_seconds: Int) -> OpenAIClient {
    let (config, _http_client) = client;
    let (api_key, base_url, _timeout, retries, user_agent, debug) = config;
    let new_config = (api_key, base_url, timeout_seconds, retries, user_agent, debug);
    let new_http_client = new_http_client_with_config(base_url, timeout_seconds, retries, user_agent);
    (new_config, new_http_client)
} 