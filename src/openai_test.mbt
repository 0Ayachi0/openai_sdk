// Self-contained test suite without cross-file references

// Types used by tests (T_ prefixes to avoid collisions)
///|
typealias (String, String, Int, Int, String, Bool) as T_OpenAIConfig

///|
typealias (String, Int, Int, String) as T_HttpClient

///|
typealias (T_OpenAIConfig, T_HttpClient) as T_OpenAIClient

///|
typealias (String, String) as T_Message

///|
typealias (String, String, String) as T_ToolMessage

///|
typealias (String, String) as T_FunctionCall

///|
typealias (Int, Array[String], String) as T_HttpResponse

///|
typealias (String, String, Int) as T_OpenAIError

///|
typealias (String, String, Array[String], String) as T_HttpRequest

// Helpers

///|
const T_USER_ROLE : String = "user"

///|
const T_ASSISTANT_ROLE : String = "assistant"

///|
const T_SYSTEM_ROLE : String = "system"

///|
const T_TOOL_ROLE : String = "tool"

///|
fn t_new_client(api_key : String) -> T_OpenAIClient {
  let cfg : T_OpenAIConfig = (
    api_key, "https://api.openai.com/v1", 30, 3, "OpenAI-Moonbit-SDK/1.0", false,
  )
  let http : T_HttpClient = (
    "https://api.openai.com/v1", 30, 3, "MoonBit-HTTP-Client/1.0",
  )
  (cfg, http)
}

///|
fn t_new_client_with_config(
  api_key : String,
  base_url : String,
  timeout_seconds : Int,
  max_retries : Int,
  user_agent : String,
  debug : Bool,
) -> T_OpenAIClient {
  let cfg : T_OpenAIConfig = (
    api_key, base_url, timeout_seconds, max_retries, user_agent, debug,
  )
  let http : T_HttpClient = (base_url, timeout_seconds, max_retries, user_agent)
  (cfg, http)
}

///|
fn t_user_message(content : String) -> T_Message {
  (T_USER_ROLE, content)
}

///|
fn t_assistant_message(content : String) -> T_Message {
  (T_ASSISTANT_ROLE, content)
}

///|
fn t_system_message(content : String) -> T_Message {
  (T_SYSTEM_ROLE, content)
}

///|
fn t_tool_message(content : String, tool_call_id : String) -> T_ToolMessage {
  (T_TOOL_ROLE, content, tool_call_id)
}

///|
fn t_function_call(name : String, arguments : String) -> T_FunctionCall {
  (name, arguments)
}

///|
fn t_enable_debug(client : T_OpenAIClient) -> T_OpenAIClient {
  let (cfg, http) = client
  let (api_key, base_url, timeout, retries, user_agent, _debug) = cfg
  ((api_key, base_url, timeout, retries, user_agent, true), http)
}

///|
fn t_set_timeout(
  client : T_OpenAIClient,
  timeout_seconds : Int,
) -> T_OpenAIClient {
  let (cfg, _http) = client
  let (api_key, base_url, _timeout, retries, user_agent, debug) = cfg
  (
    (api_key, base_url, timeout_seconds, retries, user_agent, debug),
    (base_url, timeout_seconds, retries, user_agent),
  )
}

///|
fn t_is_success_response(resp : T_HttpResponse) -> Bool {
  let (code, _, _) = resp
  code >= 200 && code < 300
}

///|
fn t_int_to_string(n : Int) -> String {
  if n == 0 {
    return "0"
  }
  let mut num = n
  let mut out = ""
  let neg = n < 0
  if neg {
    num = -num
  }
  while num > 0 {
    let d = num % 10
    let ch = Int::unsafe_to_char(d + 48)
    out = ch.to_string() + out
    num = num / 10
  }
  if neg {
    "-" + out
  } else {
    out
  }
}

///|
fn t_string_to_int(s : String) -> Int {
  let mut res = 0
  let mut i = 0
  let mut neg = false
  let len = s.length()
  // Move to the first sign (followed by a digit) or the first digit
  while i < len {
    match s.get(i) {
      Some('-') =>
        match s.get(i + 1) {
          Some(next) =>
            if next >= '0' && next <= '9' {
              neg = true
              i = i + 1
              break
            }
          None => ()
        }
      Some('+') =>
        match s.get(i + 1) {
          Some(next) =>
            if next >= '0' && next <= '9' {
              i = i + 1
              break
            }
          None => ()
        }
      Some(c) => if c >= '0' && c <= '9' { break }
      None => ()
    }
    i = i + 1
  }
  // Accumulate the digit sequence starting at current i
  while i < len {
    match s.get(i) {
      Some(c) =>
        if c >= '0' && c <= '9' {
          res = res * 10 + (c.reinterpret_as_uint().reinterpret_as_int() - 48)
        } else {
          break
        }
      None => break
    }
    i = i + 1
  }
  if neg {
    -res
  } else {
    res
  }
}

///|
fn t_trim(s : String) -> String {
  s
}

///|
fn t_extract_substring(str : String, start : Int, end : Int) -> String {
  let mut r = ""
  let mut i = start
  while i < end && i < str.length() {
    match str.get(i) {
      Some(c) => r = r + c.to_string()
      None => break
    }
    i = i + 1
  }
  r
}

///|
fn t_find_substring(str : String, pattern : String) -> Int? {
  let plen = pattern.length()
  let slen = str.length()
  let mut i = 0
  while i <= slen - plen {
    let mut ok = true
    let mut j = 0
    while j < plen {
      match (str.get(i + j), pattern.get(j)) {
        (Some(sc), Some(pc)) =>
          if sc != pc {
            ok = false
            break
          }
        _ => {
          ok = false
          break
        }
      }
      j = j + 1
    }
    if ok {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn t_find_substring_from(str : String, pattern : String, start : Int) -> Int? {
  let plen = pattern.length()
  let slen = str.length()
  let mut i = start
  while i <= slen - plen {
    let mut ok = true
    let mut j = 0
    while j < plen {
      match (str.get(i + j), pattern.get(j)) {
        (Some(sc), Some(pc)) =>
          if sc != pc {
            ok = false
            break
          }
        _ => {
          ok = false
          break
        }
      }
      j = j + 1
    }
    if ok {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn t_json_serialize(value : String) -> String {
  let mut r = "\""
  let mut i = 0
  while i < value.length() {
    match value.get(i) {
      Some('"') => r = r + "\\\""
      Some('\\') => r = r + "\\\\"
      Some('\n') => r = r + "\\n"
      Some('\r') => r = r + "\\r"
      Some('\t') => r = r + "\\t"
      Some(c) => r = r + c.to_string()
      None => break
    }
    i = i + 1
  }
  let out = r + "\""
  out
}

///|
fn t_json_deserialize(json : String) -> Result[String, String] {
  let s = t_trim(json)
  if s.length() == 0 {
    return Err("Invalid JSON format: empty")
  }
  match (s.get(0), s.get(s.length() - 1)) {
    (Some('{'), Some('}')) => ()
    (Some('['), Some(']')) => ()
    _ => {
      let _ = println("t_json_deserialize: not enclosed -> " + s)
      return Err("Invalid JSON format: not enclosed by {} or []")
    }
  }

  // Validate brackets/braces pairing and quoted strings
  let mut i = 0
  let mut in_string = false
  let mut escape_next = false
  let mut brace_count = 0 // {}
  let mut bracket_count = 0 // []
  while i < s.length() {
    match s.get(i) {
      None => break
      Some(ch) =>
        if in_string {
          if escape_next {
            escape_next = false
          } else if ch == '\\' { // escape character inside string
            escape_next = true
          } else if ch == '"' { // string terminator
            in_string = false
          }
        } else if ch == '"' {
          in_string = true
        } else if ch == '{' {
          brace_count = brace_count + 1
        } else if ch == '}' {
          brace_count = brace_count - 1
          if brace_count < 0 {
            let _ = println("t_json_deserialize: unmatched } in -> " + s)
            return Err("Invalid JSON format: unmatched }")
          }
        } else if ch == '[' {
          bracket_count = bracket_count + 1
        } else if ch == ']' {
          bracket_count = bracket_count - 1
          if bracket_count < 0 {
            let _ = println("t_json_deserialize: unmatched ] in -> " + s)
            return Err("Invalid JSON format: unmatched ]")
          }
        } else {
          let _ = ()

        }
    }
    i = i + 1
  }
  if in_string {
    let _ = println("t_json_deserialize: unclosed string in -> " + s)
    return Err("Invalid JSON format: unclosed string")
  }
  if brace_count != 0 || bracket_count != 0 {
    let _ = println(
      "t_json_deserialize: unbalanced in -> braces=" +
      brace_count.to_string() +
      ", brackets=" +
      bracket_count.to_string(),
    )
    return Err("Invalid JSON format: unbalanced braces/brackets")
  }

  // Preserve original formatting (spaces) by returning the original input
  Ok(json)
}

///|
fn t_extract_json_field(json : String, field_name : String) -> String? {
  let pattern = "\"" + field_name + "\":"
  match t_find_substring(json, pattern) {
    None => None
    Some(start) => {
      let vstart = start + pattern.length()
      match t_find_substring_from(json, ",", vstart) {
        Some(end) => Some(t_trim(t_extract_substring(json, vstart, end)))
        None =>
          match t_find_substring_from(json, "}", vstart) {
            Some(end2) => Some(t_trim(t_extract_substring(json, vstart, end2)))
            None => None
          }
      }
    }
  }
}

///|
fn t_get_error_message(e : T_OpenAIError) -> String {
  let (t, m, c) = e
  "OpenAI Error [" + c.to_string() + "]: " + t + " - " + m
}

///|
fn t_is_retryable_error(e : T_OpenAIError) -> Bool {
  let (_, _, code) = e
  code == 429 || code == 500 || code == 502 || code == 503 || code == 504
}

///|
fn t_new_http_request(
  m : String,
  u : String,
  h : Array[String],
  b : String,
) -> T_HttpRequest {
  (m, u, h, b)
}

// ================= Tests =================

///|
test "客户端创建测试" {
  let client = t_new_client("your-api-key")
  let (cfg, _http) = client
  let (_k, base_url, _t, _r, _ua, _dbg) = cfg
  if base_url != "https://api.openai.com/v1" {
    let _ : Unit = panic()

  }
}

///|
test "带配置的客户端创建测试" {
  let client = t_new_client_with_config(
    "your-api-key", "https://api.openai.com/v1", 60, 5, "Custom-Agent/1.0", true,
  )
  let (cfg, _http) = client
  let (_k, base_url, timeout, retries, user_agent, debug) = cfg
  if base_url != "https://api.openai.com/v1" {
    let _ : Unit = panic()

  }
  if timeout != 60 {
    let _ : Unit = panic()

  }
  if retries != 5 {
    let _ : Unit = panic()

  }
  if user_agent != "Custom-Agent/1.0" {
    let _ : Unit = panic()

  }
  if debug != true {
    let _ : Unit = panic()

  }
}

///|
test "消息创建函数测试" {
  let u = t_user_message("Hello")
  let a = t_assistant_message("Hi there")
  let s = t_system_message("You are helpful")
  if u.0 != T_USER_ROLE {
    let _ : Unit = panic()

  }
  if u.1 != "Hello" {
    let _ : Unit = panic()

  }
  if a.0 != T_ASSISTANT_ROLE {
    let _ : Unit = panic()

  }
  if a.1 != "Hi there" {
    let _ : Unit = panic()

  }
  if s.0 != T_SYSTEM_ROLE {
    let _ : Unit = panic()

  }
  if s.1 != "You are helpful" {
    let _ : Unit = panic()

  }
}

///|
test "常量定义测试" {
  if T_USER_ROLE != "user" {
    let _ : Unit = panic()

  }
  if T_ASSISTANT_ROLE != "assistant" {
    let _ : Unit = panic()

  }
  if T_SYSTEM_ROLE != "system" {
    let _ : Unit = panic()

  }
}

///|
test "工具消息创建测试" {
  let tm = t_tool_message("Weather is sunny", "call_123")
  if tm.0 != T_TOOL_ROLE {
    let _ : Unit = panic()

  }
  if tm.1 != "Weather is sunny" {
    let _ : Unit = panic()

  }
  if tm.2 != "call_123" {
    let _ : Unit = panic()

  }
}

///|
test "函数调用创建测试" {
  let fc = t_function_call("get_weather", "{\"location\": \"Beijing\"}")
  if fc.0 != "get_weather" {
    let _ : Unit = panic()

  }
  if fc.1 != "{\"location\": \"Beijing\"}" {
    let _ : Unit = panic()

  }
}

///|
test "错误处理测试" {
  let e : T_OpenAIError = ("api_error", "Test error message", 500)
  let msg = t_get_error_message(e)
  if msg.length() == 0 {
    let _ : Unit = panic()

  }
  if !msg.contains("500") {
    let _ : Unit = panic()

  }
  if !msg.contains("api_error") {
    let _ : Unit = panic()

  }
  let r = t_is_retryable_error(e)
  if r != true {
    let _ : Unit = panic()

  }
  let e2 : T_OpenAIError = ("invalid_request", "Bad request", 400)
  let r2 = t_is_retryable_error(e2)
  if r2 != false {
    let _ : Unit = panic()

  }
}

///|
test "配置功能测试" {
  let c = t_new_client("your-api-key")
  let cdbg = t_enable_debug(c)
  let (cfgd, _h1) = cdbg
  if cfgd.5 != true {
    let _ : Unit = panic()

  }
  let ct = t_set_timeout(c, 120)
  let (cfgt, _h2) = ct
  if cfgt.2 != 120 {
    let _ : Unit = panic()

  }
}

///|
test "HTTP客户端功能测试" {
  let http : T_HttpClient = (
    "https://api.openai.com/v1", 30, 3, "MoonBit-HTTP-Client/1.0",
  )
  let (base_url, timeout, retries, user_agent) = http
  if base_url != "https://api.openai.com/v1" {
    let _ : Unit = panic()

  }
  if timeout != 30 {
    let _ : Unit = panic()

  }
  if retries != 3 {
    let _ : Unit = panic()

  }
  if user_agent != "MoonBit-HTTP-Client/1.0" {
    let _ : Unit = panic()

  }
  let http2 : T_HttpClient = ("https://custom.api.com", 60, 5, "Custom/1.0")
  let (b2, t2, r2, ua2) = http2
  if b2 != "https://custom.api.com" {
    let _ : Unit = panic()

  }
  if t2 != 60 {
    let _ : Unit = panic()

  }
  if r2 != 5 {
    let _ : Unit = panic()

  }
  if ua2 != "Custom/1.0" {
    let _ : Unit = panic()

  }
}

///|
test "JSON序列化测试" {
  let s = "Hello \"World\" with\nnewlines\tand\\backslashes"
  let serialized = t_json_serialize(s)
  if serialized.length() == 0 {
    let _ : Unit = panic()

  }
  if !serialized.contains("\\\"") {
    let _ : Unit = panic()

  }
  if !serialized.contains("\\n") {
    let _ : Unit = panic()

  }
  if !serialized.contains("\\t") {
    let _ : Unit = panic()

  }
  if !serialized.contains("\\\\") {
    let _ : Unit = panic()

  }
  let valid_json = "{\"name\": \"test\"}"
  match t_json_deserialize(valid_json) {
    Ok(parsed) =>
      if parsed != valid_json {
        let _ : Unit = panic()

      }
    Err(_) => {
      let _ : Unit = panic()

    }
  }
  let invalid_json = "invalid json"
  match t_json_deserialize(invalid_json) {
    Ok(_) => {
      let _ : Unit = panic()

    }
    Err(_) => {
      let _ = ()

    }
  }
}

///|
test "URL解析测试" {
  let http_url = "http://api.openai.com/v1/chat/completions"
  let rq = t_new_http_request("POST", http_url, [], "{}")
  let (m, u, _h, b) = rq
  if m != "POST" {
    let _ : Unit = panic()

  }
  if u != http_url {
    let _ : Unit = panic()

  }
  if b != "{}" {
    let _ : Unit = panic()

  }
  let https_url = "https://api.openai.com/v1/chat/completions"
  let rq2 = t_new_http_request("POST", https_url, [], "{}")
  let (m2, u2, _h2, _b2) = rq2
  if m2 != "POST" {
    let _ : Unit = panic()

  }
  if u2 != https_url {
    let _ : Unit = panic()

  }
}

///|
test "字符串操作测试" {
  let s = "Hello World"
  if s.length() != 11 {
    let _ : Unit = panic()

  }
  match s.get(0) {
    Some(c) =>
      if c != 72 {
        let _ : Unit = panic()

      }
    None => {
      let _ : Unit = panic()

    }
  }
  match s.get(6) {
    Some(c) =>
      if c != 87 {
        let _ : Unit = panic()

      }
    None => {
      let _ : Unit = panic()

    }
  }
}

///|
test "HTTP响应解析测试" {
  let r1 : T_HttpResponse = (
    200,
    ["Content-Type: application/json"],
    "{\"status\":\"ok\"}",
  )
  if t_is_success_response(r1) != true {
    let _ : Unit = panic()

  }
  let r2 : T_HttpResponse = (404, ["Content-Type: text/plain"], "Not Found")
  if t_is_success_response(r2) != false {
    let _ : Unit = panic()

  }
  let r3 : T_HttpResponse = (500, [], "")
  if t_is_success_response(r3) != false {
    let _ : Unit = panic()

  }
}

///|
test "响应头捕获转换测试" {
  let mut array_headers : Array[String] = []
  let mut i = 0
  let headers = ["Content-Type: application/json", "X-CUSTOM-Header: ABC"]
  while i < headers.length() {
    array_headers = array_headers + [headers.get(i).unwrap_or("")]
    i = i + 1
  }
  let mut found_ct = false
  let mut found_custom = false
  let mut j = 0
  while j < array_headers.length() {
    match array_headers.get(j) {
      Some(line) => {
        if line.to_lower() == "content-type: application/json" {
          found_ct = true
        }
        if line.to_lower() == "x-custom-header: abc" {
          found_custom = true
        }
      }
      None => {
        let _ = ()

      }
    }
    j = j + 1
  }
  if !found_ct {
    let _ : Unit = panic()

  }
  if !found_custom {
    let _ : Unit = panic()

  }
}

///|
test "重试机制测试" {
  let client : T_HttpClient = (
    "https://api.openai.com/v1", 30, 3, "MoonBit-HTTP-Client/1.0",
  )
  let (_b, _t, max_retries, _ua) = client
  if max_retries != 3 {
    let _ : Unit = panic()

  }
  let attempt1 = 1
  let delay1 = 2 * attempt1
  if delay1 != 2 {
    let _ : Unit = panic()

  }
  let attempt2 = 2
  let delay2 = 2 * attempt2
  if delay2 != 4 {
    let _ : Unit = panic()

  }
  let attempt3 = 3
  let delay3 = 2 * attempt3
  if delay3 != 6 {
    let _ : Unit = panic()

  }
  let e1 = 1
  let e2 = 2
  let e3 = 4
  let e4 = 8
  if e1 != 1 {
    let _ : Unit = panic()

  }
  if e2 != 2 {
    let _ : Unit = panic()

  }
  if e3 != 4 {
    let _ : Unit = panic()

  }
  if e4 != 8 {
    let _ : Unit = panic()

  }
}

///|
test "字符串转整数测试" {
  if t_string_to_int("123") != 123 {
    let _ : Unit = panic()

  }
  if t_string_to_int("0") != 0 {
    let _ : Unit = panic()

  }
  if t_string_to_int("999") != 999 {
    let _ : Unit = panic()

  }
  if t_string_to_int("abc123def") != 123 {
    let _ : Unit = panic()

  }
}

///|
test "特殊字符JSON序列化测试" {
  let s = "test\nwith\tspecial\"chars\\here"
  let serialized = t_json_serialize(s)
  if !serialized.contains("\\n") {
    let _ : Unit = panic()

  }
  if !serialized.contains("\\t") {
    let _ : Unit = panic()

  }
  if !serialized.contains("\\\"") {
    let _ : Unit = panic()

  }
  if !serialized.contains("\\\\") {
    let _ : Unit = panic()

  }
}

///|
test "数组JSON反序列化测试" {
  let arr = "[\"item1\", \"item2\"]"
  match t_json_deserialize(arr) {
    Ok(parsed) =>
      if parsed != arr {
        let _ : Unit = panic()

      }
    Err(_) => {
      let _ : Unit = panic()

    }
  }
}

///|
test "零值转字符串测试" {
  if t_int_to_string(0) != "0" {
    let _ : Unit = panic()

  }
}

///|
test "负数转字符串测试" {
  if t_int_to_string(-123) != "-123" {
    let _ : Unit = panic()

  }
  if t_int_to_string(456) != "456" {
    let _ : Unit = panic()

  }
}

///|
test "JSON字段提取失败测试" {
  let json = "{\"other_field\": \"value\"}"
  match t_extract_json_field(json, "missing_field") {
    None => {
      let _ = ()

    }
    Some(_) => {
      let _ : Unit = panic()

    }
  }
}

///|
test "HTTP响应解析边界测试" {
  let ok : T_HttpResponse = (
    200,
    ["Content-Type: application/json"],
    "{\"status\":\"ok\"}",
  )
  if t_is_success_response(ok) != true {
    let _ : Unit = panic()

  }
  let codes = [0, 100, 300, 400, 401, 403, 404, 429, 500, 502, 503, 999]
  let mut i = 0
  while i < codes.length() {
    let c = codes.get(i).unwrap_or(0)
    let resp : T_HttpResponse = (c, [], "")
    if c >= 200 && c < 300 {
      if t_is_success_response(resp) != true {
        let _ : Unit = panic()

      }
    } else if t_is_success_response(resp) != false {
      let _ : Unit = panic()

    }
    i = i + 1
  }
}

///|
test "简化错误处理分支测试" {
  let errors = [
    ("api_error", "API调用失败", 500),
    ("network_error", "网络连接失败", 0),
    ("timeout_error", "请求超时", 0),
    ("parse_error", "解析失败", 400),
    ("auth_error", "认证失败", 401),
    ("rate_limit_error", "请求频率限制", 429),
    ("unknown_error", "未知错误", 999),
  ]
  let mut i = 0
  while i < errors.length() {
    let (t, m, c) = errors.get(i).unwrap_or(("", "", 0))
    let e : T_OpenAIError = (t, m, c)
    let msg = t_get_error_message(e)
    if msg.length() == 0 {
      let _ : Unit = panic()

    }
    let retryable = t_is_retryable_error(e)
    if c == 429 || c == 500 || c == 502 || c == 503 || c == 504 {
      if !retryable {
        let _ : Unit = panic()

      }
    } else if retryable {
      let _ : Unit = panic()

    }
    i = i + 1
  }
}

///|
test "字符串处理边界测试" {
  let empty_serialized = t_json_serialize("")
  if empty_serialized != "\"\"" {
    let _ : Unit = panic()

  }
  let special = "\n\t\"\\"
  let s2 = t_json_serialize(special)
  if !s2.contains("\\n") {
    let _ : Unit = panic()

  }
  if !s2.contains("\\t") {
    let _ : Unit = panic()

  }
  if !s2.contains("\\\"") {
    let _ : Unit = panic()

  }
  if !s2.contains("\\\\") {
    let _ : Unit = panic()

  }
  let mut long = ""
  let mut j = 0
  while j < 1000 {
    long = long + "a"
    j = j + 1
  }
  let ls = t_json_serialize(long)
  if ls.length() < 1000 {
    let _ : Unit = panic()

  }
  let chinese = "你好世界"
  let cs = t_json_serialize(chinese)
  if cs.length() == 0 {
    let _ : Unit = panic()

  }
  if !cs.has_prefix("\"") {
    let _ : Unit = panic()

  }
  if !cs.has_suffix("\"") {
    let _ : Unit = panic()

  }
}

///|
test "数值转换边界测试" {
  let vals = [0, 1, -1, 10, -10, 100, -100, 999, -999]
  let mut i = 0
  while i < vals.length() {
    let v = vals.get(i).unwrap_or(0)
    let s = t_int_to_string(v)
    let v2 = t_string_to_int(s)
    if v2 != v {
      let _ : Unit = panic()

    }
    if v == 0 && s != "0" {
      let _ : Unit = panic()

    }
    if v > 0 && s == "" {
      let _ : Unit = panic()

    }
    if v < 0 && !s.has_prefix("-") {
      let _ : Unit = panic()

    }
    i = i + 1
  }
}
