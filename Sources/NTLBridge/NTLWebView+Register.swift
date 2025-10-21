import Foundation

public extension NTLWebView {
    /// 取消注册方法
    func unregister(methodName: String) {
        registeredHandlers.removeValue(forKey: methodName)
        debugLog("Unregistered method: \(methodName)")
    }

    /// 获取已注册的方法列表
    var registeredMethods: [String] {
        return Array(registeredHandlers.keys)
    }

    // MARK: - Register Sync

    /// 注册一个与实例绑定的方法，自动处理内存管理，支持 Codable 返回类型
    func register<R: Decodable>(
        methodName: String,
        expecting returnType: R.Type,
        handler: @escaping (_ param: R) throws -> JSONValue?
    ) {
        register(methodName: methodName) { param in
            let typedParam: R = try NTLBridgeUtil.convertValueOrThrow(param)
            let result = try handler(typedParam)
            return result
        }
    }

    /// 注册一个静态或独立的闭包
    func register(
        methodName: String,
        handler: @escaping JSRawResponseMethodHandler
    ) {
        guard NTLBridgeUtil.isValidMethodName(methodName) else {
            debugLog("Invalid method name or namespace: \(methodName)")
            return
        }
        let container = JSMethodHandlerContainer(rawResponseHandler: handler)
        registeredHandlers[methodName] = container
        debugLog("Registered static method: \(methodName)")
    }

    // MARK: - Register Async

    /// 注册一个异步方法
    func registerAsync(
        methodName: String,
        handler: @escaping JSAsyncMethodHandler
    ) {
        guard NTLBridgeUtil.isValidMethodName(methodName) else {
            debugLog("Invalid method name or namespace: \(methodName)")
            return
        }
        let container = JSMethodHandlerContainer(asyncHandler: handler)
        registeredHandlers[methodName] = container
        debugLog("Registered async method: \(methodName)")
    }

    /// 注册一个与实例绑定的异步方法
    func registerAsync<R: Decodable>(
        methodName: String,
        expecting returnType: R,
        handler: @escaping (_ param: R, _ completion: @escaping (Result<JSONValue?, Error>) -> Void) -> Void
    ) {
        let wrappedAsyncHandler: JSAsyncMethodHandler = { param, completion in
            let typedParam: R = try NTLBridgeUtil.convertValueOrThrow(param)
            handler(typedParam, completion)
        }
        registerAsync(methodName: methodName, handler: wrappedAsyncHandler)
    }
}
