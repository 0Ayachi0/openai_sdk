// Go 风格适配器：提供接近 openai-go 的链式/命名风格包装

// Client 构造与配置（Go: openai.NewClient / WithXxx）
///|
pub fn go_new_client(api_key : String) -> OpenAIClient {
  new_client(api_key)
}

///|
pub fn go_new_client_with_config(
  api_key : String,
  base_url : String,
  timeout_seconds : Int,
  max_retries : Int,
  user_agent : String,
  debug : Bool,
) -> OpenAIClient {
  new_client_with_config(
    api_key, base_url, timeout_seconds, max_retries, user_agent, debug,
  )
}

///|
pub fn go_with_organization(
  client : OpenAIClient,
  organization : String,
) -> OpenAIClient {
  set_organization(client, organization)
}

///|
pub fn go_with_project(
  client : OpenAIClient,
  project_id : String,
) -> OpenAIClient {
  set_project(client, project_id)
}

///|
pub fn go_with_timeout(
  client : OpenAIClient,
  timeout_seconds : Int,
) -> OpenAIClient {
  set_timeout(client, timeout_seconds)
}

///|
pub fn go_with_retries(client : OpenAIClient, retries : Int) -> OpenAIClient {
  set_retries(client, retries)
}

// 可选：变更 BaseURL（保持 HTTP 客户端同步）

///|
pub fn go_with_base_url(
  client : OpenAIClient,
  base_url : String,
) -> OpenAIClient {
  let (cfg, _hc) = client
  let (api_key, _base, timeout, retries, user_agent, debug, org, proj) = cfg
  let mut nc = new_client_with_config(
    api_key, base_url, timeout, retries, user_agent, debug,
  )
  // 恢复 org/project（仅在 Some 时设置）
  match org {
    None => {
      let _ = ()

    }
    Some(o) => nc = set_organization(nc, o)
  }
  match proj {
    None => {
      let _ = ()

    }
    Some(p) => nc = set_project(nc, p)
  }
  nc
}

// Chat/Completions（Go: client.Chat.Completions.Create/New）

///|
pub async fn go_chat_completions_create(
  client : OpenAIClient,
  model : String,
  messages : Array[Message],
) -> Result[ChatCompletionResponse, OpenAIError] {
  chat_completion(client, messages, model)
}

///|
pub async fn go_chat_completions_new(
  client : OpenAIClient,
  model : String,
  messages : Array[Message],
) -> Result[ChatCompletionResponse, OpenAIError] {
  chat_completion(client, messages, model)
}

///|
pub async fn go_chat_completions_create_stream(
  client : OpenAIClient,
  model : String,
  messages : Array[Message],
) -> Result[Array[StreamChatCompletionResponse], OpenAIError] {
  stream_chat_completion(client, messages, model)
}

// 带工具调用

///|
pub async fn go_chat_completions_create_with_tools(
  client : OpenAIClient,
  model : String,
  messages : Array[Message],
  tools : Array[String],
) -> Result[ChatCompletionResponse, OpenAIError] {
  tool_chat_completion(client, messages, model, tools)
}

// 结构化输出（json_object/json_schema）

///|
pub async fn go_chat_completions_create_structured(
  client : OpenAIClient,
  model : String,
  messages : Array[Message],
  response_format : StructuredOutput,
) -> Result[ChatCompletionResponse, OpenAIError] {
  structured_chat_completion(client, messages, model, response_format)
}

// 消息构造辅助（接近 Go 请求体）

///|
pub fn go_user_message(content : String) -> Message {
  user_message(content)
}

///|
pub fn go_system_message(content : String) -> Message {
  system_message(content)
}

///|
pub fn go_assistant_message(content : String) -> Message {
  assistant_message(content)
}

// StructuredOutput 构造便捷

///|
pub fn go_response_format_json() -> StructuredOutput {
  ("json_object", "{}", "")
}

///|
pub fn go_response_format_json_schema(
  schema_json : String,
  name : String,
) -> StructuredOutput {
  ("json_schema", schema_json, name)
}
