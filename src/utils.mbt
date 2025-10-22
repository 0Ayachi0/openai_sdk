// OpenAI SDK for Moonbit - 使用官方async库的真实网络实现
// 使用真实的HTTP客户端

// 错误类型定义
///|
pub typealias (String, Int, String) as HttpError // (error_type, status_code, message)

// HTTP请求类型

///|
pub typealias (String, String, Array[String], String) as HttpRequest // (http_method, url, headers, body)

// HTTP响应类型

///|
pub typealias (Int, Array[String], String) as HttpResponse // (status_code, headers, body)

// HTTP客户端类型

///|
pub typealias (String, Int, Int, String) as HttpClient // (base_url, timeout_seconds, max_retries, user_agent)

// 创建HTTP客户端

///|
pub fn new_http_client(base_url : String) -> HttpClient {
  (base_url, 30, 3, "MoonBit-HTTP-Client/1.0")
}

// 创建带配置的HTTP客户端

///|
pub fn new_http_client_with_config(
  base_url : String,
  timeout_seconds : Int,
  max_retries : Int,
  user_agent : String,
) -> HttpClient {
  (base_url, timeout_seconds, max_retries, user_agent)
}

// 创建HTTP请求

///|
pub fn new_http_request(
  http_method : String,
  url : String,
  headers : Array[String],
  body : String,
) -> HttpRequest {
  (http_method, url, headers, body)
}

// 检查HTTP响应是否成功

///|
pub fn is_success_response(response : HttpResponse) -> Bool {
  let (status_code, _, _) = response
  status_code >= 200 && status_code < 300
}

// 将 Map[String, String] 形式的 header 转换为 Array[String]（"key: value"），键一律小写

///|
pub fn headers_map_to_array(headers : Map[String, String]) -> Array[String] {
  let mut result : Array[String] = []
  for pair in headers.to_array() {
    let (k, v) = pair
    let key_lc = k.to_lower()
    result = result + [key_lc + ": " + v]
  }
  result
}

// 掩码API Key，避免在日志中泄露完整密钥

///|
fn mask_api_key_for_log(api_key : String) -> String {
  let len = api_key.length()
  if len <= 8 {
    return "***"
  }
  let prefix = extract_substring(api_key, 0, 4)
  let suffix = extract_substring(api_key, len - 4, len)
  prefix + "****" + suffix
}

// 判断是否打印调试请求头：通过环境变量 OPENAI_DEBUG 控制

///|
fn should_log_headers(extra_headers : Array[String]) -> Bool {
  let mut i = 0
  while i < extra_headers.length() {
    let h_opt = extra_headers.get(i)
    match h_opt {
      None => {
        i = i + 1
        continue
      }
      Some(h) => {
        let hl = h.to_lower()
        if hl.has_prefix("x-debug:") {
          // 允许任意非空值开启
          let idx_opt = find_substring(h, ":")
          match idx_opt {
            None => return true
            Some(idx) => {
              let val = trim(string_substring_from(h, idx + 1))
              if val.length() > 0 {
                return true
              }
            }
          }
        }
      }
    }
    i = i + 1
  }
  false
}

// 构建用于日志的掩码后的请求头字符串

///|
fn build_masked_headers_string(
  headers : Array[String],
  api_key : String,
) -> String {
  let masked = mask_api_key_for_log(api_key)
  let mut out = "["
  let mut first = true
  let mut i = 0
  while i < headers.length() {
    let line_opt = headers.get(i)
    match line_opt {
      None => {
        i = i + 1
        continue
      }
      Some(line) => {
        let lower = line.to_lower()
        let printable = if lower.has_prefix("authorization:") {
          "authorization: Bearer " + masked
        } else {
          line
        }
        if first {
          first = false
        } else {
          out = out + ", "
        }
        out = out + printable
      }
    }
    i = i + 1
  }
  out + "]"
}

// 发送OpenAI请求 - 使用真实async库

///|
pub async fn send_openai_request(
  http_client : HttpClient,
  api_key : String,
  endpoint : String,
  request_body : String,
  extra_headers : Array[String],
) -> Result[HttpResponse, HttpError] {
  // 构建完整URL（优先使用传入 http_client 的 base_url）
  let (base_url, _timeout, _max_retries, user_agent) = http_client
  let mut sep = "/"
  if base_url.has_suffix("/") || endpoint.has_prefix("/") {
    sep = ""
  }
  let url = base_url + sep + endpoint

  // 创建请求头（注入 User-Agent）并合并可选附加头
  let headers = [
      "Content-Type: application/json",
      "Authorization: Bearer " + api_key,
      "User-Agent: " + user_agent,
    ] +
    extra_headers

  // 可选：打印掩码后的请求头，便于调试
  if should_log_headers(extra_headers) {
    let _ = println("→ POST " + url)
    let dbg = build_masked_headers_string(headers, api_key)
    let _ = println("→ Headers: " + dbg)

  }
  let request = new_http_request("POST", url, headers, request_body)

  // 发送请求
  http_post(http_client, request)
}

// HTTP POST请求 - 使用真实async库实现

///|
pub async fn http_post(
  client : HttpClient,
  request : HttpRequest,
) -> Result[HttpResponse, HttpError] {
  let (base_url, timeout, max_retries, _) = client
  let (http_method, url, headers, body) = request

  // 构建完整URL
  let full_url = if url.has_prefix("http") { url } else { base_url + url }

  // 使用统一实现执行真实HTTP请求
  match perform_http_request(http_method, full_url, headers, body, timeout) {
    Ok(response) => Ok(response)
    Err(error) => {
      // 重试逻辑
      let mut attempt = 0
      while attempt < max_retries {
        match
          perform_http_request(http_method, full_url, headers, body, timeout) {
          Ok(response) => return Ok(response)
          Err(_) => {
            attempt = attempt + 1
            if attempt < max_retries {
              let _ = wait_before_retry(attempt)

            }
          }
        }
      }
      Err(error)
    }
  }
}

// 统一的HTTP请求实现（支持不同方法）

///|
pub async fn perform_http_request(
  http_method : String,
  url : String,
  headers : Array[String],
  body : String,
  timeout : Int,
) -> Result[HttpResponse, HttpError] {
  let _ = parse_url(url)
  perform_real_http_request(http_method, url, headers, body, timeout)
}

// （已合并）移除单独的异步POST实现，统一由 perform_http_request 处理

// URL解析函数

///|
fn parse_url(url : String) -> Result[(String, String, Int, String), HttpError] {
  // 解析协议
  let protocol_end = find_substring(url, "://")
  match protocol_end {
    None => Err(("invalid_url", 0, "Invalid URL format: missing protocol"))
    Some(proto_end) => {
      let protocol = extract_substring(url, 0, proto_end)
      let remaining = string_substring_from(url, proto_end + 3)

      // 解析主机和路径
      let path_start = find_substring(remaining, "/")
      let (host_port, path) = match path_start {
        None => (remaining, "/")
        Some(path_idx) =>
          (
            extract_substring(remaining, 0, path_idx),
            string_substring_from(remaining, path_idx),
          )
      }

      // 解析主机和端口
      let port_start = find_substring(host_port, ":")
      let (host, port) = match port_start {
        None => {
          let default_port = if protocol == "https" { 443 } else { 80 }
          (host_port, default_port)
        }
        Some(port_idx) => {
          let host = extract_substring(host_port, 0, port_idx)
          let port_str = string_substring_from(host_port, port_idx + 1)
          let port = string_to_int(port_str)
          (host, port)
        }
      }
      Ok((protocol, host, port, path))
    }
  }
}

// 简化的辅助函数

// 等待重试

///|
pub async fn wait_before_retry(attempt : Int) -> Int {
  // 指数退避（毫秒）：500ms, 1s, 2s, 4s, 8s，封顶 10s
  let base_ms = 500
  let mut delay_ms = base_ms
  let mut i = 0
  while i < attempt {
    delay_ms = delay_ms * 2
    i = i + 1
  }
  if delay_ms > 10000 {
    delay_ms = 10000
  }
  // 使用真实异步休眠，避免忙等阻塞
  let _ = @async.sleep(delay_ms)
  // 返回秒值（取整）用于日志或调试
  delay_ms / 1000
}

// ==================== JSON处理函数 ====================

// JSON序列化

///|
pub fn json_serialize(value : String) -> String {
  // 转义特殊字符
  let mut result = "\""
  let mut i = 0
  while i < value.length() {
    let char = value.get(i)
    match char {
      None => break
      Some(c) =>
        match c {
          '"' => result = result + "\\\""
          '\\' => result = result + "\\\\"
          '\n' => result = result + "\\n"
          '\r' => result = result + "\\r"
          '\t' => result = result + "\\t"
          _ => result = result + Int::unsafe_to_char(c).to_string()
        }
    }
    i = i + 1
  }
  result + "\""
}

// JSON反序列化

///|
pub fn json_deserialize(json : String) -> Result[String, String] {
  // 更严格的 JSON 合法性校验：
  // 1) 去除首尾空白；2) 必须以 {..} 或 [..] 包裹；
  // 3) 校验括号/方括号配对与字符串引号闭合（处理转义）。
  let s = trim(json)
  if s.length() == 0 {
    return Err("Invalid JSON format: empty")
  }
  let first = s.get(0)
  let last = s.get(s.length() - 1)
  match (first, last) {
    (Some('{'), Some('}')) => ()
    (Some('['), Some(']')) => ()
    _ => return Err("Invalid JSON format: not enclosed by {} or []")
  }
  let mut i = 0
  let mut in_string = false
  let mut escape_next = false
  let mut brace_count = 0 // {}
  let mut bracket_count = 0 // []
  while i < s.length() {
    let ch_opt = s.get(i)
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
          if brace_count < 0 {
            return Err("Invalid JSON format: unmatched }")
          }
        } else if ch == '[' {
          bracket_count = bracket_count + 1
        } else if ch == ']' {
          bracket_count = bracket_count - 1
          if bracket_count < 0 {
            return Err("Invalid JSON format: unmatched ]")
          }
        } else {
          ()
        }
    }
    i = i + 1
  }
  if in_string {
    return Err("Invalid JSON format: unclosed string")
  }
  if brace_count != 0 || bracket_count != 0 {
    return Err("Invalid JSON format: unbalanced braces/brackets")
  }
  Ok(s)
}

// 提取JSON字段

///|
pub fn extract_json_field(json : String, field_name : String) -> String? {
  let key_token = "\"" + field_name + "\""
  let key_pos = find_substring(json, key_token)
  match key_pos {
    None => None
    Some(kpos) => {
      let colon_pos = find_substring_from(json, ":", kpos + key_token.length())
      match colon_pos {
        None => None
        Some(cpos) => {
          let vstart = util_skip_ws(json, cpos + 1)
          match util_extract_json_value(json, vstart) {
            None => None
            Some(tuple) => {
              let (val, _end) = tuple
              Some(trim(val))
            }
          }
        }
      }
    }
  }
}

// ========== JSON 值解析辅助（避免破坏现有行为，返回原始子串） ==========

///|
fn util_skip_ws(s : String, start : Int) -> Int {
  let mut i = start
  while i < s.length() {
    match s.get(i) {
      Some(' ') => i = i + 1
      Some('\t') => i = i + 1
      Some('\n') => i = i + 1
      Some('\r') => i = i + 1
      _ => break
    }
  }
  i
}

///|
fn util_find_string_end(s : String, quote_start : Int) -> Int? {
  match s.get(quote_start) {
    Some('"') => {
      let _ = ()

    }
    _ => return None
  }
  let mut i = quote_start + 1
  let mut escape_next = false
  while i < s.length() {
    match s.get(i) {
      None => return None
      Some(ch) =>
        if escape_next {
          escape_next = false
        } else if ch == '\\' {
          escape_next = true
        } else if ch == '"' {
          return Some(i)
        } else {
          let _ = ()

        }
    }
    i = i + 1
  }
  None
}

///|
fn util_extract_json_value(s : String, value_start : Int) -> (String, Int)? {
  if value_start >= s.length() {
    return None
  }
  match s.get(value_start) {
    Some('{') => {
      let mut i = value_start
      let mut brace = 0
      let mut bracket = 0
      let mut in_str = false
      let mut esc = false
      while i < s.length() {
        match s.get(i) {
          None => break
          Some(ch) =>
            if in_str {
              if esc {
                esc = false
              } else if ch == '\\' {
                esc = true
              } else if ch == '"' {
                in_str = false
              }
            } else if ch == '"' {
              in_str = true
            } else if ch == '{' {
              brace = brace + 1
            } else if ch == '}' {
              brace = brace - 1
              if brace == 0 && bracket == 0 {
                let end = i
                return Some(
                  (extract_substring(s, value_start, end + 1), end + 1),
                )
              }
            } else if ch == '[' {
              bracket = bracket + 1
            } else if ch == ']' {
              bracket = bracket - 1
            } else {
              let _ = ()

            }
        }
        i = i + 1
      }
      None
    }
    Some('[') => {
      let mut i = value_start
      let mut brace = 0
      let mut bracket = 0
      let mut in_str = false
      let mut esc = false
      while i < s.length() {
        match s.get(i) {
          None => break
          Some(ch) =>
            if in_str {
              if esc {
                esc = false
              } else if ch == '\\' {
                esc = true
              } else if ch == '"' {
                in_str = false
              }
            } else if ch == '"' {
              in_str = true
            } else if ch == '{' {
              brace = brace + 1
            } else if ch == '}' {
              brace = brace - 1
            } else if ch == '[' {
              bracket = bracket + 1
            } else if ch == ']' {
              bracket = bracket - 1
              if brace == 0 && bracket == 0 {
                let end = i
                return Some(
                  (extract_substring(s, value_start, end + 1), end + 1),
                )
              }
            } else {
              let _ = ()

            }
        }
        i = i + 1
      }
      None
    }
    Some('"') =>
      match util_find_string_end(s, value_start) {
        None => None
        Some(endq) =>
          Some((extract_substring(s, value_start, endq + 1), endq + 1))
      }
    Some(_c) => {
      let mut i = value_start
      while i < s.length() {
        match s.get(i) {
          None => break
          Some(ch) => if ch == ',' || ch == '}' || ch == ']' { break }
        }
        i = i + 1
      }
      Some((trim(extract_substring(s, value_start, i)), i))
    }
    None => None
  }
}

// ==================== 字符串处理函数 ====================

// 查找子字符串

///|
pub fn find_substring(str : String, pattern : String) -> Int? {
  let pattern_length = pattern.length()
  let str_length = str.length()
  let mut i = 0
  while i <= str_length - pattern_length {
    let mut match_found = true
    let mut j = 0
    while j < pattern_length {
      let str_char = str.get(i + j)
      let pattern_char = pattern.get(j)
      match (str_char, pattern_char) {
        (Some(sc), Some(pc)) =>
          if sc != pc {
            match_found = false
            break
          }
        _ => {
          match_found = false
          break
        }
      }
      j = j + 1
    }
    if match_found {
      return Some(i)
    }
    i = i + 1
  }
  None
}

// 从指定位置开始查找子字符串

///|
pub fn find_substring_from(str : String, pattern : String, start : Int) -> Int? {
  let pattern_length = pattern.length()
  let str_length = str.length()
  let mut i = start
  while i <= str_length - pattern_length {
    let mut match_found = true
    let mut j = 0
    while j < pattern_length {
      let str_char = str.get(i + j)
      let pattern_char = pattern.get(j)
      match (str_char, pattern_char) {
        (Some(sc), Some(pc)) =>
          if sc != pc {
            match_found = false
            break
          }
        _ => {
          match_found = false
          break
        }
      }
      j = j + 1
    }
    if match_found {
      return Some(i)
    }
    i = i + 1
  }
  None
}

// 提取子字符串

///|
pub fn extract_substring(str : String, start : Int, end : Int) -> String {
  let mut result = ""
  let mut i = start
  while i < end && i < str.length() {
    let char = str.get(i)
    match char {
      None => break
      Some(c) => result = result + Int::unsafe_to_char(c).to_string()
    }
    i = i + 1
  }
  result
}

// 字符串截取

///|
pub fn string_substring_from(str : String, start : Int) -> String {
  let mut result = ""
  let mut i = start
  while i < str.length() {
    let char = str.get(i)
    match char {
      None => break
      Some(c) => result = result + Int::unsafe_to_char(c).to_string()
    }
    i = i + 1
  }
  result
}

// 整数转字符串

///|
pub fn int_to_string(n : Int) -> String {
  if n == 0 {
    return "0"
  }
  let mut num = n
  let mut result = ""
  let is_negative = n < 0
  if is_negative {
    num = -num
  }
  while num > 0 {
    let digit = num % 10
    let digit_char = Int::unsafe_to_char(digit + 48) // 48 is '0'
    result = digit_char.to_string() + result
    num = num / 10
  }
  if is_negative {
    result = "-" + result
  }
  result
}

// 字符串转整数

///|
pub fn string_to_int(s : String) -> Int {
  let mut result = 0
  let mut i = 0
  let mut is_negative = false

  // 检查是否为负数
  if s.length() > 0 {
    let first_char = s.get(0)
    match first_char {
      Some('-') => {
        is_negative = true
        i = 1
      } // 跳过负号
      Some('+') => i = 1 // 跳过正号
      _ => ()
    }
  }
  while i < s.length() {
    let char = s.get(i)
    match char {
      None => break
      Some(c) =>
        if c >= '0' && c <= '9' {
          result = result * 10 +
            (c.reinterpret_as_uint().reinterpret_as_int() - 48)
        } else {
          break
        }
    }
    i = i + 1
  }
  if is_negative {
    -result
  } else {
    result
  }
}

// 字符串trim

///|
pub fn trim(s : String) -> String {
  let mut start = 0
  let mut end = s.length()

  // 找到第一个非空白字符
  while start < end {
    let char = s.get(start)
    match char {
      None => break
      Some(c) =>
        if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
          start = start + 1
        } else {
          break
        }
    }
  }

  // 找到最后一个非空白字符
  while end > start {
    let char = s.get(end - 1)
    match char {
      None => break
      Some(c) =>
        if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
          end = end - 1
        } else {
          break
        }
    }
  }
  extract_substring(s, start, end)
}

// ==================== 网络辅助函数 ====================

// 解析HTTP错误

///|
pub fn parse_http_error(error : HttpError) -> String {
  let (error_type, status_code, message) = error
  "HTTP Error [" +
  status_code.to_string() +
  "]: " +
  error_type +
  " - " +
  message
}
