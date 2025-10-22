// 真实网络实现 - 使用官方 moonbitlang/async 库
// 将真实HTTP请求代理到统一实现

// 将 Array[String] 形式的 header（"Key: Value"）转换为 Map[String, String]
///|
fn headers_array_to_map(headers : Array[String]) -> Map[String, String] {
  let map = {}
  let mut i = 0
  while i < headers.length() {
    let item = headers.get(i)
    match item {
      None => break
      Some(line) => {
        let maybe_colon = find_substring(line, ":")
        match maybe_colon {
          None => ()
          Some(colon_idx) => {
            let key_raw = extract_substring(line, 0, colon_idx)
            let value_raw = string_substring_from(line, colon_idx + 1)
            // Preserve original header key casing when passing to HTTP client
            let key = trim(key_raw)
            let value = trim(value_raw)
            map[key] = value
          }
        }
      }
    }
    i = i + 1
  }
  map
}

// headers_map_to_array 在 utils.mbt 中提供

// 真实的HTTP请求执行函数（基于 moonbitlang/async/http）

///|
pub async fn perform_real_http_request(
  http_method : String,
  url : String,
  headers : Array[String],
  body : String,
  timeout : Int,
) -> Result[HttpResponse, HttpError] {
  // 将传入的 header 数组转换为 Map，供 async/http 使用
  let header_map = headers_array_to_map(headers)

  // 使用 async 超时保护（单位毫秒）
  let timeout_ms = if timeout <= 0 { 30000 } else { timeout * 1000 }
  let maybe_result = @async.with_timeout_opt(timeout_ms, fn() {
    if http_method == "POST" {
      let (resp, resp_body) = @http.post(url, body, headers=header_map)
      let text = resp_body.text()
      let out_headers = headers_map_to_array(resp.headers)
      Ok((resp.code, out_headers, text))
    } else if http_method == "GET" {
      let (resp, resp_body) = @http.get(url, headers=header_map)
      let text = resp_body.text()
      let out_headers = headers_map_to_array(resp.headers)
      Ok((resp.code, out_headers, text))
    } else if http_method == "PUT" {
      let (resp, resp_body) = @http.put(url, body, headers=header_map)
      let text = resp_body.text()
      let out_headers = headers_map_to_array(resp.headers)
      Ok((resp.code, out_headers, text))
    } else {
      Err(("unsupported_method", 0, "Unsupported HTTP method: " + http_method))
    }
  })
  match maybe_result {
    None =>
      Err(
        (
          "timeout",
          0,
          "HTTP request timed out in " + timeout_ms.to_string() + " ms",
        ),
      )
    Some(r) => r
  }
}

// 真实的HTTP客户端

///|
pub fn new_real_http_client(base_url : String) -> HttpClient {
  (base_url, 30, 3, "Real-Network-Client/1.0")
}
