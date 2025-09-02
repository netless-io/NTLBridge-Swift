import Foundation
import WebKit

/// 核心WebView类，提供JavaScript Bridge功能
open class NTLWebView: WKWebView {
    
    // MARK: - Properties
    
    /// 已注册的JavaScript方法处理器
    internal var registeredHandlers: [String: JSMethodHandlerContainer] = [:]
    
    /// 回调ID计数器，用于生成唯一的回调ID
    internal var callbackIdCounter: Int = 0
    
    /// 待处理的回调字典，存储Native到JS的回调
    internal var pendingCallbacks: [Int: (Result<JSONValue?, Error>) -> Void] = [:]
    
    /// 弱引用代理，用于处理脚本消息
    internal var scriptMessageProxy: WeakScriptMessageHandlerProxy?
    
    /// 待处理的启动队列，存储在JavaScript加载完成前需要调用的方法
    internal var startupCallQueue: [NTLCallInfo] = []
    
    /// 标记是否已初始化完成
    internal var isInitialized: Bool = false
    
    /// 调试模式开关
    public var isDebugMode: Bool = false
    
    /// 脚本消息处理名称，兼容原版DSBridge
    internal static let scriptMessageHandlerName = "asyncBridge"
    
    // MARK: - Initialization
    
    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        setupBridge()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBridge()
    }
    
    deinit {
        cleanupBridge()
    }
    
    // MARK: - Bridge Setup
    
    private func setupBridge() {
        // 设置UIDelegate以支持同步调用
        uiDelegate = self
        
        // 创建弱引用代理避免循环引用
        scriptMessageProxy = WeakScriptMessageHandlerProxy(target: self)
        
        // 添加脚本消息处理器
        configuration.userContentController.add(scriptMessageProxy!, name: Self.scriptMessageHandlerName)
        
        // 注入Bridge JavaScript代码
        injectBridgeScript()
        
        // 注册内部API
        registerInternalAPIs()
    }
    
    private func cleanupBridge() {
        configuration.userContentController.removeScriptMessageHandler(forName: Self.scriptMessageHandlerName)
        scriptMessageProxy = nil
        registeredHandlers.removeAll()
        pendingCallbacks.removeAll()
    }
    
    /// 清理所有待处理的JavaScript调用任务
    private func cleanupPendingJSCalls() {
        // 清理待处理的回调，并通知调用方页面已切换
        for (_, completion) in pendingCallbacks {
            let error = NSError(domain: "NTLBridge", code: -2, userInfo: [NSLocalizedDescriptionKey: "Page navigation occurred, JavaScript call cancelled"])
            completion(.failure(error))
        }
        pendingCallbacks.removeAll()
        
        // 清理启动队列
        startupCallQueue.removeAll()
        
        // 重置初始化状态
        isInitialized = false
        
        debugLog("Cleaned up all pending JavaScript calls due to page navigation")
    }
    
    private func injectBridgeScript() {
        // 注入DSBridge标识，让dsbridge.js知道原生环境可用
        let bridgeScript = "window._dswk=true;"
        let userScript = WKUserScript(source: bridgeScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        
        debugLog("Bridge setup completed, ready for dsbridge.js integration")
    }
    
    // MARK: - Load Overrides
    open override func load(_ request: URLRequest) -> WKNavigation? {
        cleanupPendingJSCalls()
        return super.load(request)
    }
    
    open override func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        cleanupPendingJSCalls()
        return super.loadHTMLString(string, baseURL: baseURL)
    }
    
    // MARK: - Internal Methods
    
    /// 内部统一的调用入口，所有 callHandler 重载方法最终都调用此方法
    /// - Parameters:
    ///   - callInfo: 调用信息
    ///   - completion: 完成回调
    internal func internalcallHandler(callInfo: NTLCallInfo, completion: ((Result<JSONValue?, Error>) -> Void)? = nil) {
        if isInitialized {
            // 如果已初始化，直接调度
            dispatchJavascriptCall(callInfo)
        } else {
            // 如果未初始化，加入启动队列
            startupCallQueue.append(callInfo)
            debugLog("Queued call for later dispatch: \(callInfo.method)")
        }
        
        if let completion = completion {
            pendingCallbacks[callInfo.callbackId] = completion
        }
    }
    
    internal func generateCallbackId() -> Int {
        callbackIdCounter += 1
        return callbackIdCounter
    }
    
    internal func debugLog(_ message: String) {
        if isDebugMode {
            print("[NTLBridge] \(message)")
        }
    }
    
    // MARK: - Private Methods
    
    /// 内部使用的注册方法，跳过验证
    private func registerInternal(
        methodName: String,
        handler: @escaping (_ param: JSONValue) throws -> JSONValue?
    ) {
        let container = JSMethodHandlerContainer(handler: handler)
        registeredHandlers[methodName] = container
        
        debugLog("Registered internal method: \(methodName)")
    }
    
    private func registerInternalAPIs() {
        // DSBridge标准的returnValue API
        registerInternal(methodName: "_dsb.returnValue") { [unowned self] param in
            self.handleReturnValueFromJS(param)
            return nil
        }
        
        // DSBridge标准的dsinit API - 初始化完成后调度启动队列
        registerInternal(methodName: "_dsb.dsinit") { [unowned self] _ in
            self.dispatchStartupQueue()
            return .null
        }
    }
    
    private func dispatchJavascriptCall(_ callInfo: NTLCallInfo) {
        guard let jsonData = NTLBridgeUtil.encodeCallInfo(callInfo) else {
            debugLog("Failed to encode call info for dispatch")
            return
        }
        
        let script = "window._handleMessageFromNative(\(jsonData))"
        evaluateJavaScript(script) { [weak self] _, error in
            if let error = error {
                self?.debugLog("Failed to dispatch JavaScript call: \(error)")
            }
        }
    }
    
    /// 调度启动队列，在JavaScript初始化完成后执行所有待处理的方法调用
    private func dispatchStartupQueue() {
        isInitialized = true
        debugLog("Initialization complete, dispatching startup queue")
        
        guard !startupCallQueue.isEmpty else {
            debugLog("No queued calls to dispatch")
            return
        }
        
        debugLog("Dispatching \(startupCallQueue.count) queued calls")
        
        for callInfo in startupCallQueue {
            dispatchJavascriptCall(callInfo)
        }
        
        startupCallQueue.removeAll()
        debugLog("Startup queue dispatched")
    }
    
    
    private func cleanupDeallocatedHandlers() {
        registeredHandlers = registeredHandlers.filter { _, container in
            return container.isValid
        }
    }
}

// MARK: - WKScriptMessageHandler

extension NTLWebView: WKScriptMessageHandler {
    // 在这里完成异步调用。
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == Self.scriptMessageHandlerName else { return }
        
        debugLog("Received message from JavaScript: \(message.body)")
        
        // 解析DSBridge格式的消息：{"method": "methodName", "arg": "argumentString"}
        guard let messageDict = message.body as? [String: Any],
              let method = messageDict["method"] as? String,
              let argStr = messageDict["arg"] as? String else {
            debugLog("Failed to parse DSBridge message format")
            return
        }
        
        handleDSBridgeCall(method: method, argStr: argStr)
    }
    
    private func handleDSBridgeCall(method: String, argStr: String) {
        debugLog("Handling DSBridge call: \(method) with args: \(argStr)")
        
        // 解析参数：{"data": actualData, "_dscbstub": "callbackId"}
        let argData = NTLBridgeUtil.parseJSONValue(from: argStr)
        var callbackStub: String?
        var methodParam: JSONValue = .null
        
        if case let .dictionary(argDict) = argData {
            callbackStub = argDict["_dscbstub"]?.stringValue
            methodParam = argDict["data"] ?? .null
        }
        
        // 首先清理已释放的处理器
        cleanupDeallocatedHandlers()
        
        guard let container = registeredHandlers[method] else {
            let error = "Method not found: \(method)"
            debugLog(error)
            sendDSBridgeError(callbackStub: callbackStub, error: error)
            return
        }
        
        // 检查处理器是否仍然有效
        guard container.isValid else {
            let error = "Method handler target has been deallocated: \(method)"
            debugLog(error)
            registeredHandlers.removeValue(forKey: method)
            sendDSBridgeError(callbackStub: callbackStub, error: error)
            return
        }
        
        if container.isAsync {
            // 异步处理
            guard let asyncHandler = container.asyncHandler else {
                let error = "Async handler not found for method: \(method)"
                debugLog(error)
                sendDSBridgeError(callbackStub: callbackStub, error: error)
                return
            }
            
            asyncHandler(methodParam) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let value):
                        self?.sendDSBridgeResult(callbackStub: callbackStub, result: value)
                    case .failure(let error):
                        self?.sendDSBridgeError(callbackStub: callbackStub, error: error.localizedDescription)
                    }
                }
            }
        } else {
            // 同步处理
            do {
                let result = try container.handler(methodParam)
                sendDSBridgeResult(callbackStub: callbackStub, result: result)
            } catch {
                debugLog("Method call failed: \(error)")
                sendDSBridgeError(callbackStub: callbackStub, error: error.localizedDescription)
            }
        }
    }
    
    internal func handleReturnValueFromJS(_ param: JSONValue) {
        guard case let .dictionary(dictionary) = param, let callbackId = dictionary["id"]?.numberValue
        else { return }
        let callbackIdInt = Int(callbackId)
        let data = dictionary["data"]
        let complete = dictionary["complete"]?.boolValue ?? true
        let error = dictionary["error"]
        
        if let completion = pendingCallbacks[callbackIdInt] {
            if complete {
                pendingCallbacks.removeValue(forKey: callbackIdInt)
            }
            if let error {
                if let structedError = jsStructuredError(jsonValue: error) {
                    completion(.failure(structedError))
                    return
                }
            }
            completion(.success(data))
        }
    }
    
    private func sendDSBridgeResult(callbackStub: String?, result: JSONValue?) {
        guard let callbackStub else { return }
        
        // DSBridge回调格式：callbackStub({code: 0, data: result})
        let response = JSONValue.dictionary([
            "code": .number(0),
            "data": result ?? .null
        ])
        
        let responseString = NTLBridgeUtil.jsonString(from: response)
        let encodedResponse = responseString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let script = """
        try {
            \(callbackStub)(JSON.parse(decodeURIComponent("\(encodedResponse)")).data);
            delete window.\(callbackStub);
        } catch(e) {
            console.error('DSBridge callback error:', e);
        }
        """
        
        evaluateJavaScript(script) { [weak self] _, error in
            if let error = error {
                self?.debugLog("Failed to send DSBridge result to JS: \(error)")
            }
        }
    }
    
    private func sendDSBridgeError(callbackStub: String?, error: String) {
        guard let callbackStub = callbackStub else { return }
        
        // DSBridge错误格式：callbackStub({code: -1, data: errorMessage})
        let response = JSONValue.dictionary([
            "code": .number(-1),
            "data": .string(error)
        ])
        
        let responseString = NTLBridgeUtil.jsonString(from: response)
        let encodedResponse = responseString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let script = """
        try {
            \(callbackStub)(JSON.parse(decodeURIComponent("\(encodedResponse)")).data);
            delete window.\(callbackStub);
        } catch(e) {
            console.error('DSBridge error callback error:', e);
        }
        """
        
        evaluateJavaScript(script) { [weak self] _, error in
            if let error = error {
                self?.debugLog("Failed to send DSBridge error to JS: \(error)")
            }
        }
    }
}

// MARK: - WKUIDelegate for Synchronous Calls

extension NTLWebView: WKUIDelegate {
    // 在这里完成同步调用。
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        let dsBridgePrefix = "_dsbridge="
        
        if prompt.hasPrefix(dsBridgePrefix) {
            // 这是DSBridge的同步调用
            let method = String(prompt.dropFirst(dsBridgePrefix.count))
            let argStr = defaultText ?? ""
            
            debugLog("Handling DSBridge sync call: \(method) with args: \(argStr)")
            
            // 处理同步调用
            let result = handleDSBridgeSyncCall(method: method, argStr: argStr)
            completionHandler(result)
        } else {
            // 默认处理其他prompt
            completionHandler(defaultText)
        }
    }
    
    internal func handleDSBridgeSyncCall(method: String, argStr: String) -> String {
        // 解析参数（同步调用不需要回调）
        let argData = NTLBridgeUtil.parseJSONValue(from: argStr)
        var methodParam: JSONValue = .null
        
        if case let .dictionary(argDict) = argData,
           let data = argDict["data"] {
            methodParam = data
        }
        
        // 清理已释放的处理器
        cleanupDeallocatedHandlers()
        
        guard let container = registeredHandlers[method] else {
            let error = "Method not found: \(method)"
            debugLog(error)
            return createDSBridgeErrorResponse(error: error)
        }
        
        // 检查处理器是否仍然有效
        guard container.isValid else {
            let error = "Method handler target has been deallocated: \(method)"
            debugLog(error)
            registeredHandlers.removeValue(forKey: method)
            return createDSBridgeErrorResponse(error: error)
        }
        
        // 异步方法不允许同步调用
        if container.isAsync {
            let error = "Async method cannot be called synchronously: \(method)"
            debugLog(error)
            return createDSBridgeErrorResponse(error: error)
        }
        
        do {
            let result = try container.handler(methodParam)
            debugLog("Sync method call succeeded: \(method) with result: \(String(describing: result))")
            return createDSBridgeSuccessResponse(result: result)
        } catch {
            debugLog("Sync method call failed: \(error)")
            return createDSBridgeErrorResponse(error: error.localizedDescription)
        }
    }
    
    private func createDSBridgeSuccessResponse(result: JSONValue?) -> String {
        let response = JSONValue.dictionary([
            "code": .number(0),
            "data": result ?? .null
        ])
        return NTLBridgeUtil.jsonString(from: response)
    }
    
    private func createDSBridgeErrorResponse(error: String) -> String {
        let response = JSONValue.dictionary([
            "code": .number(-1),
            "data": .string(error)
        ])
        return NTLBridgeUtil.jsonString(from: response)
    }
}
