# NTLBridge-Swift

[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/badge/platform-iOS%2012%2B%20%7C%20macOS%2010.14%2B-blue.svg)](https://developer.apple.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

NTLBridge-Swift 是一个强大且轻量级的 JavaScript 桥接库，专为 iOS 和 macOS
应用程序设计。它能够在您的 Swift/Objective-C 代码和 WKWebView 中运行的
JavaScript 之间实现无缝的双向通信，并完全兼容
https://github.com/netless-io/Whiteboard-bridge 规范。

## 功能特性

- 🔄 双向通信：从 JavaScript 调用原生方法，反之亦然
- ⚡ 异步与同步支持：同时支持同步和异步方法调用
- 🛡️ 错误处理：支持JavaScript错误结构化捕获
- 📦 Codable支持：JSONValue支持Codable协议
- ✨ 字面量支持：支持Swift字面量语法
- 🔧 实例方法绑定：支持与实例绑定的方法注册

## 安装

### Swift Package Manager

.package(url: "https://github.com/your-org/NTLBridge-Swift.git", from: "1.0.0")

## 快速入门

### 1. 基础设置

```swift
import NTLBridge
import WebKit
class ViewController: UIViewController {
    var webView: NTLWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // 创建 web 视图
        let config = WKWebViewConfiguration()
        webView = NTLWebView(frame: view.bounds, configuration: config)
        view.addSubview(webView)
        // 启用调试模式（可选）
        webView.isDebugMode = true
        // 加载 HTML
        if let url = Bundle.main.url(forResource: "index", withExtension:
 "html") {
            webView.loadFileURL(url, allowingReadAccessTo:
url.deletingLastPathComponent())
        }
    }
}
```

### 2. 注册原生方法

```swift
// 注册简单方法
webView.register(methodName: "getDeviceInfo") { param in
    return [
        "device": UIDevice.current.model,
        "system": UIDevice.current.systemVersion
    ]
}

// 注册与实例绑定的方法
class DataService {
    func fetchUserData(_ userId: String) -> [String: Any] {
        return ["id": userId, "name": "User \(userId)"]
    }
}
let dataService = DataService()
webView.register(methodName: "getUserData", target: dataService) { target, param in
    guard let userId = param.stringValue else { return nil }
    return target.fetchUserData(userId)
}

// 注册异步方法
webView.registerAsync(methodName: "fetchData") { param, completion in
    // 模拟网络调用
    DispatchQueue.global().async {
        let result = "数据获取成功"
        completion(.success(.string(result)))
    }
}

// 使用字面量语法
webView.register(methodName: "calculate") { param in
    return ["result": 42, "success": true]
}
```

### 3. 从原生调用 JavaScript

```swift
// 调用 JavaScript 方法
webView.callBridge(method: "showAlert", args: ["来自 Swift 的问候！"]) { result in
    switch result {
    case .success(let value):
        print("JS 响应: \(value ?? .null)")
    case .failure(let error):
        print("错误: \(error)")
    }
}

// 使用字面量语法调用
webView.callBridge(method: "calculate", args: [10, 20, "add"])

// 支持Codable类型
struct User: Codable {
    let id: String
    let name: String
}
let user = User(id: "123", name: "张三")
webView.callBridge(method: "updateUser", args: [user])
```

## Web 集成

### 使用 Whiteboard-bridge

Web 端使用 https://github.com/netless-io/Whiteboard-bridge 实现无缝集成：版本需要大于 @netless/webview-bridge@0.2.1

```html
  <!DOCTYPE html>
  <html>
  <head>
      <meta charset="UTF-8">
      <title>桥接测试</title>
      <script type="module">
          import { bridge } from
  "https://github.com/netless-io/Whiteboard-bridge";

          // 使桥接器全局可用
          window.bridge = bridge;

          // 调用原生方法
          const deviceInfo = bridge.syncCall("getDeviceInfo");
          console.log("设备信息:", deviceInfo);

          // 异步调用
          bridge.asyncCall("fetchData", { userId: 123 })
              .then(result => console.log(result))
              .catch(error => console.error(error));
      </script>
  </head>
  <body>
      <h1>桥接测试页面</h1>
  </body>
  </html>
```

## 高级功能

### 1. JSONValue 字面量支持

```swift
// 支持所有Swift字面量语法
let stringValue: JSONValue = "Hello"
let numberValue: JSONValue = 42
let boolValue: JSONValue = true
let arrayValue: JSONValue = [1, 2, 3]
let dictValue: JSONValue = ["key": "value"]
let nullValue: JSONValue = nil

// 在桥接调用中使用
webView.register(methodName: "getConfig") { _ in
    return [
        "appName": "MyApp",
        "version": 1.0,
        "features": ["feature1", "feature2"],
        "debug": false
    ]
}
```

### 2. Codable 支持

```swift
// 定义Codable类型
struct Config: Codable {
    let apiUrl: String
    let timeout: Int
    let enableCache: Bool
}

// 在桥接中使用
webView.register(methodName: "loadConfig") { _ in
    let config = Config(apiUrl: "https://api.example.com", timeout: 30, enableCache: true)
    return try? JSONValue(codable: config)
}
```

### 3. 错误处理

```swift
// JavaScript端错误会被自动捕获并传递到Swift端
// JavaScript代码示例：
bridge.call("someMethod", { error, result }) {
    if (error) {
        console.error("Error:", error);
        return;
    }
    console.log("Result:", result);
}

// Swift端会收到结构化的错误信息，包括：
// - 错误名称
// - 错误消息  
// - 堆栈跟踪
```

## 调试与故障排除

### 启用调试模式

```swift
// 启用调试模式以查看详细的桥接日志
webView.isDebugMode = true
```

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件
