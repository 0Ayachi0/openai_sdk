# OpenAI SDK for MoonBit

[![Build Status](https://img.shields.io/github/actions/workflow/status/0Ayachi0/openai_sdk/ci.yml)](https://github.com/0Ayachi0/openai_sdk/actions) 

[简体中文](README_zh_CN.md) | English

A comprehensive OpenAI SDK implementation in MoonBit language, providing complete API functionality with Go SDK-compatible interface design, supporting all mainstream AI model features and use cases.

## 🚀 Key Features

• 🎯 **Core Chat Completion** – Complete OpenAI chat completion API implementation  
• 🔧 **Multiple Response Modes** – Support for standard, streaming, tool calling, and structured outputs  
• 🚀 **Advanced Features** – Multi-turn conversations and context management  
• 📊 **Performance Optimization** – Efficient HTTP request handling and retry mechanisms  
• 🔄 **Error Handling** – Comprehensive error detection and recovery mechanisms  
• 🎨 **Flexible API** – Multiple interfaces compatible with Go SDK design patterns  
• 📈 **Production Ready** – Complete configuration management and environment support  
• 🔍 **Type Safety** – Complete error types with robust type system  
• 📦 **Network Integration** – Ready for real network library integration  
• 🧪 **Test Coverage** – Comprehensive test suite with 25 passing tests  
• 📚 **Complete Documentation** – Detailed usage examples and API reference  

## 📥 Installation

```bash
moon add 0Ayachi0/openai_sdk@0.1.0
```

## 🚀 Usage Guide

### 🔨 Basic Chat Completion
Perform basic OpenAI chat completion operations.

```moonbit
// Basic conversation
let client = new_client("your-api-key")
let response = simple_chat(client, "Say this is a test")
match response {
    Ok(message) => {
        // Process response message
        println("Response: " + message)
    }
    Err(error) => {
        // Handle API error
        let (error_type, message, status_code) = error
        println("Error: " + error_type + " - " + message)
    }
}

// Multi-turn conversation
let messages = [
    system_message("You are a helpful assistant."),
    user_message("Hello"),
    assistant_message("Hi! How can I help you today?"),
    user_message("What's 2+2?")
]
let result = chat_completion(client, messages, GPT_4O)
match result {
    Ok(response) => {
        // Process chat completion response
        let (id, object, created, model, choices, usage) = response
        // Extract message from first choice
    }
    Err(error) => {
        // Handle completion error
    }
}
```

### 🎯 Advanced Response Modes
Use different response modes for various use cases.

```moonbit
// Streaming response
let stream_result = stream_chat(client, "Tell me a story about a brave knight")
match stream_result {
    Ok(response) => {
        // Process streaming response
        println("Streaming: " + response)
    }
    Err(error) => {
        // Handle streaming error
    }
}

// Tool calling
let tools = ["get_weather", "get_time", "calculate"]
let tool_result = tool_chat(client, "What's the weather like in New York?", tools)
match tool_result {
    Ok((message, tool_call)) => {
        // Process tool response
        println("Message: " + message)
        match tool_call {
            Some((id, type, function_name, arguments)) => {
                println("Tool called: " + function_name)
                println("Arguments: " + arguments)
            }
            None => {
                println("No tool called")
            }
        }
    }
    Err(error) => {
        // Handle tool calling error
    }
}

// Structured output (json_schema, strict with additionalProperties:false)
let schema = "{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"},\"age\":{\"type\":\"integer\"}},\"required\":[\"name\",\"age\"],\"additionalProperties\":false}"
let format = ("json_schema", schema, "Person")
let struct_result = structured_chat(client, "Extract the name and age from: John is 25 years old.", format)
match struct_result {
    Ok(response) => {
        // Process structured response
        println("Structured data: " + response)
    }
    Err(error) => {
        // Handle structured output error
    }
}
```

### 🔧 Advanced Client Configuration
Configure client with custom settings and options.

```moonbit
// Create client with custom configuration
let client = new_client_with_config(
    "your-api-key",           // API key
    "https://api.openai.com/v1", // Base URL
    30,                       // Timeout in seconds
    3,                        // Max retries
    "MoonBit-SDK/1.0",       // User agent
    false                     // Debug mode
)

// Create HTTP client for custom requests
let http_client = new_http_client("https://api.openai.com/v1")
let request = new_http_request(
    "POST",
    "https://api.openai.com/v1/chat/completions",
    ["Content-Type: application/json", "Authorization: Bearer your-api-key"],
    "{\"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello\"}]}"
)

// Make custom HTTP request
let http_result = http_post(http_client, request)
match http_result {
    Ok((status_code, headers, body)) => {
        // Process HTTP response
        println("Status: " + status_code.to_string())
        println("Response: " + body)
    }
    Err(error) => {
        // Handle HTTP error
    }
}
```

#### Additional runtime configuration helpers

```moonbit
// Enable verbose debug logging (request/response snippets)
let client = enable_debug(client)

// Update timeout and retry attempts at runtime
let client = set_timeout(client, 60)
let client = set_retries(client, 5)

// Optional: set organization and project headers
let client = set_organization(client, "org_123")
let client = set_project(client, "proj_123")
```

### 🔄 Error Handling
Handle various API and network errors gracefully.

```moonbit
// Handle specific error types
let result = simple_chat(client, "Test message")
match result {
    Ok(response) => {
        // Success case
    }
    Err((error_type, message, status_code)) => {
        match error_type {
            "invalid_api_key" => {
                // Handle invalid API key
            }
            "rate_limit_exceeded" => {
                // Handle rate limiting
            }
            "max_retries_exceeded" => {
                // Handle network timeout
            }
            "invalid_request" => {
                // Handle malformed request
            }
            _ => {
                // Handle other errors
            }
        }
    }
}

// Handle network errors
let network_result = check_network_status()
// Network status check with retry logic
```

### 📈 Message and Model Management
Create and manage different types of messages and models.

```moonbit
// Create different message types
let system_msg = system_message("You are a helpful assistant specialized in coding.")
let user_msg = user_message("Explain how to implement a binary search tree")
let assistant_msg = assistant_message("I'll help you implement a binary search tree...")

// Use different models
let gpt4_result = chat_completion(client, messages, GPT_4O)
let gpt35_result = chat_completion(client, messages, GPT_3_5_TURBO)
let gpt4_mini_result = chat_completion(client, messages, GPT_4O_MINI)

// Custom model configuration
let custom_model = "gpt-4-turbo-preview"
let custom_result = chat_completion(client, messages, custom_model)
```

### 🎨 Response Processing
Handle and process different types of API responses.

```moonbit
// Process chat completion response
let result = chat_completion(client, messages, GPT_4O)
match result {
    Ok((id, object, created, model, choices, usage)) => {
        // Extract response details
        println("Response ID: " + id)
        println("Model used: " + model)
        println("Created at: " + created.to_string())
        
        // Process choices
        if choices.length() > 0 {
            let choice = choices.get(0)
            match choice {
                Some(c) => {
                    let message = c.1
                    let finish_reason = c.2
                    let (role, content) = message
                    println("Assistant: " + content)
                    println("Finish reason: " + finish_reason)
                }
                None => {
                    println("No response received")
                }
            }
        }
        
        // Process usage statistics
        let (prompt_tokens, completion_tokens, total_tokens) = usage
        println("Tokens used: " + total_tokens.to_string())
    }
    Err(error) => {
        // Handle error
    }
}
```

### 🏗️ Complex Conversation Management
Handle complex multi-turn conversations and context.

```moonbit
// Build conversation context
let mut conversation = []
conversation = conversation + [system_message("You are a coding tutor.")]
conversation = conversation + [user_message("I want to learn about algorithms.")]

// Get response and continue conversation
let result = chat_completion(client, conversation, GPT_4O)
match result {
    Ok(response) => {
        let choices = response.4
        if choices.length() > 0 {
            let choice = choices.get(0)
            match choice {
                Some(c) => {
                    let message = c.1
                    // Add assistant response to conversation
                    conversation = conversation + [assistant_message(message.1)]
                    
                    // Continue with follow-up question
                    conversation = conversation + [user_message("Can you explain binary search?")]
                    
                    // Get next response
                    let next_result = chat_completion(client, conversation, GPT_4O)
                    // Process next response...
                }
                None => {}
            }
        }
    }
    Err(error) => {
        // Handle conversation error
    }
}
```

## 📋 Data Structures

### Error Types
```moonbit
// OpenAI API error type
pub typealias (String, String, Int) as OpenAIError  // (error_type, message, status_code)

// HTTP error type
pub typealias (String, Int, String) as HttpError  // (error_type, status_code, message)
```

### Core Types
```moonbit
// Message type
pub typealias (String, String) as Message  // (role, content)

// Choice type (with optional tool_calls)
pub typealias (Int, Message, String, Option[ToolCall]) as Choice  // (index, message, finish_reason, tool_calls)

// Usage statistics
pub typealias (Int, Int, Int) as Usage  // (prompt_tokens, completion_tokens, total_tokens)

// Chat completion response
pub typealias (String, String, Int, String, Array[Choice], Usage) as ChatCompletionResponse

// Tool call type
pub typealias (String, String, String, String) as ToolCall  // (id, type, function_name, arguments)

// HTTP client and request types
pub typealias (String, Int, Int, String) as HttpClient  // (base_url, timeout, retries, user_agent)
pub typealias (String, String, Array[String], String) as HttpRequest  // (method, url, headers, body)
```

## 📊 Complete API Reference

### Core Chat Functions
- `simple_chat(client, message)` - Simple chat completion
- `stream_chat(client, message)` - Streaming chat completion
- `tool_chat(client, message, tools)` - Chat with tool calling
- `structured_chat(client, message, format)` - Chat with structured output
- `chat_completion(client, messages, model)` - Full chat completion API

### Client Management
- `new_client(api_key)` - Create client with API key
- `new_client_with_config(api_key, base_url, timeout, retries, user_agent, debug)` - Create configured client

### Message Creation
- `system_message(content)` - Create system message
- `user_message(content)` - Create user message
- `assistant_message(content)` - Create assistant message

### HTTP Operations
- `new_http_client(base_url)` - Create HTTP client
- `new_http_request(method, url, headers, body)` - Create HTTP request
- `http_post(client, request)` - Perform HTTP POST request

### Utility Functions
- `check_network_status()` - Check network connectivity
- `json_serialize(value)` - Serialize string to JSON-safe string
- `json_deserialize(json)` - Validate and normalize JSON
- `extract_json_field(json, field)` - Extract a top-level field

## 📈 Performance Characteristics

| Operation | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
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

## 🏗️ Algorithm Details

### Chat Completion Algorithm
1. **Request Preparation**: Format messages and model parameters
2. **HTTP Request**: Send POST request to OpenAI API endpoint
3. **Response Processing**: Parse JSON response and extract choices
4. **Error Handling**: Handle API errors and network failures

### Streaming Response Algorithm
1. **Stream Setup**: Configure streaming parameters
2. **Chunk Processing**: Process server-sent events incrementally
3. **Data Assembly**: Combine chunks into complete response
4. **Stream Management**: Handle connection and buffering

### Tool Calling Algorithm
1. **Tool Definition**: Define available tools and their schemas
2. **Intent Detection**: Let model determine when to call tools
3. **Function Execution**: Execute called tools with provided parameters
4. **Response Integration**: Combine tool results with model response

### Error Handling Strategy
- **Network Failures**: Implement exponential backoff retry mechanism
- **API Errors**: Parse and categorize OpenAI API error responses
- **Rate Limiting**: Handle rate limit errors with appropriate delays
- **Timeout Management**: Configure and handle request timeouts

## 🧪 Test Coverage

Project includes comprehensive test cases with **25 passing tests**:
- ✅ Basic chat completion functionality tests
- ✅ Streaming response handling tests
- ✅ Tool calling and function execution tests
- ✅ Structured output parsing tests
- ✅ Multi-turn conversation tests
- ✅ Error handling and edge case tests
- ✅ Network simulation and retry tests
- ✅ Configuration and client management tests

### Test Statistics
- **Total Tests**: 25 tests
- **Pass Rate**: 100% (25/25 passed)
- **Test Code Lines**: 605 lines
- **Error Path Coverage**: Comprehensive error handling tests
- **Network Simulation**: Complete network implementation coverage

## 🚀 Build and Run

```bash
# Linux/macOS
moon build
moon test
moon run src/main.mbt
moon coverage report -f cobertura -o coverage.xml

# Windows (add --target native)
moon build --target native
moon test --target native
moon run --target native src/main.mbt
```

### Run the 5 Demo Cases (src/main.mbt)

- **Pass API key**: use one of `--api-key VALUE`, `--key VALUE`, or `-k VALUE` (also supports `--api-key=VALUE`, `--key=VALUE`, `-k=VALUE`).
- **Optional config flags**: `--base-url VALUE`, `--timeout VALUE` (seconds), `--retries VALUE`.
- **Argument separator**: when passing program flags after `moon run`, add `--` before your flags.

Run all 5 cases:

```bash
# Linux/macOS
moon run src/main.mbt -- --api-key sk-your-api-key

# Windows
moon run --target native src/main.mbt -- --api-key sk-your-api-key
```

Run only Case 1 (basic conversation):

```bash
# Linux/macOS
moon run src/main.mbt -- --api-key sk-your-api-key --case=1

# Windows
moon run --target native src/main.mbt -- --api-key sk-your-api-key --case=1
```

- **Case 1**: Basic conversation (`demo_basic_conversation`)
- **Case 2**: Streaming response (`demo_streaming_response`)
- **Case 3**: Tool calling with real tool result handling (`demo_tool_calling`)
- **Case 4**: Structured output with schema (`demo_structured_output`)
- **Case 5**: Multi-turn conversation with context (`demo_multi_turn_conversation`)

## 📦 Dependencies

- `moonbitlang/async: 0.9.0`: Async HTTP and timeout support
- `moonbitlang/core`: Provides basic data structure support

## 🌐 Network Integration

### Current Status
- **Network Library**: `moonbitlang/async: 0.9.0` in use
- **Implementation**: Real HTTP via async/http with timeout and retries
- **Production Ready**: Production-ready real network integration

### Production Deployment
```moonbit
// Real HTTP using async/http
fn perform_real_http_request(
    http_method: String,
    url: String,
    headers: Array[String],
    body: String,
    timeout: Int
) -> Result[HttpResponse, HttpError] {
    // Uses moonbitlang/async for real HTTP requests with timeout
}
```

### Go-style adapter (optional)

For users familiar with Go SDK conventions, a Go-like adapter is provided.

```moonbit
// Create client and tweak settings using Go-like helpers
let client = go_new_client("your-api-key")
let client = go_with_base_url(client, "https://api.openai.com/v1")
let client = go_with_timeout(client, 60)
let client = go_with_retries(client, 5)
let client = go_with_organization(client, "org_123")
let client = go_with_project(client, "proj_123")

// Build messages
let messages = [
  go_system_message("You are helpful."),
  go_user_message("Hello")
]

// Non-streaming chat
let res = go_chat_completions_create(client, GPT_4O, messages)

// Streaming chat
let stream_res = go_chat_completions_create_stream(client, GPT_4O, messages)

// With tools
let tools = ["get_weather"]
let tool_res = go_chat_completions_create_with_tools(client, GPT_4O, messages, tools)

// Structured output
let schema = "{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"}},\"required\":[\"name\"]}"
let fmt = go_response_format_json_schema(schema, "Person")
let structured_res = go_chat_completions_create_structured(client, GPT_4O, messages, fmt)
```

## 🔧 Configuration

### Environment Variables
```bash
# Set environment variables
export OPENAI_API_KEY="your-api-key"
export OPENAI_BASE_URL="https://api.openai.com/v1"
export OPENAI_TIMEOUT="30"
export OPENAI_MAX_RETRIES="3"
```

### Client Configuration
```moonbit
// Configure client with custom settings
let client = new_client_with_config(
    api_key,      // API key
    base_url,     // API base URL
    timeout,      // Request timeout
    retries,      // Max retry attempts
    user_agent,   // Custom user agent
    debug         // Debug mode
)
```

## 🎯 Use Cases Implementation

### Case 1: Basic Conversation
```moonbit
let client = new_client("sk-your-api-key")
let response = simple_chat(client, "Say this is a test")
// Simple question-answer interaction
```

### Case 2: Streaming Response
```moonbit
let response = stream_chat(client, "Tell me a story about a brave knight")
// Real-time streaming output
```

### Case 3: Tool Calling
```moonbit
let tools = ["get_weather"]
let (response, tool_call) = tool_chat(client, "What's the weather like?", tools)
// Function calling capabilities
```

### Case 4: Structured Output
```moonbit
let schema = "{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"},\"age\":{\"type\":\"integer\"}},\"required\":[\"name\",\"age\"],\"additionalProperties\":false}"
let format = ("json_schema", schema, "Person")
let response = structured_chat(client, "Extract name and age", format)
// Strict JSON schema output
```

### Case 5: Multi-turn Conversation
```moonbit
let messages = [
    system_message("You are a helpful assistant."),
    user_message("Hello"),
    assistant_message("Hi! How can I help you?"),
    user_message("What's 2+2?")
]
let result = chat_completion(client, messages, GPT_4O)
// Context-aware conversation
```

## 🏗️ Project Structure

```
openai_sdk/
├── src/
│   ├── openai.mbt                    # OpenAI API core implementation
│   ├── main.mbt                      # Main program entry point
│   ├── utils.mbt                     # Utility functions
│   ├── examples.mbt                  # Usage examples
│   ├── openai_test.mbt              # Complete test suite (605 lines)
│   ├── real_network.mbt             # Real network integration layer
│   └── moon.pkg.json                # Package configuration
├── moon.mod.json                    # Project configuration
├── README.md                        # Project documentation
├── README_zh_CN.md                  # Chinese documentation
└── LICENSE                          # Open source license
```

## 📜 License

This project is licensed under the Apache-2.0 License. See the LICENSE file for details.

## 📢 Contact & Support

• MoonBit Community: moonbit-community  
• GitHub Issues: Report issues  

## 🔍 OpenAI API Information

This SDK provides complete support for OpenAI API features:
- **Chat Completions**: GPT-3.5-turbo, GPT-4, GPT-4-turbo models
- **Streaming**: Server-sent events for real-time responses
- **Tool Calling**: Function calling with JSON schema definitions
- **Structured Output**: JSON mode for structured data extraction
- **Context Management**: Multi-turn conversations with message history

This library provides complete OpenAI API compatibility with efficient request handling and comprehensive error management.

👋 If you like this project, please give it a ⭐! Happy coding! 🚀 