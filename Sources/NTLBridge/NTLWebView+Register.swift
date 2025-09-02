import Foundation

extension NTLWebView {
    /// 注册一个与实例绑定的方法，自动处理内存管理
    public func register<T: AnyObject>(
        methodName: String,
        target: T,
        handler: @escaping (_ target: T, _ param: JSONValue) throws -> JSONValue?
    ) {
        guard NTLBridgeUtil.isValidMethodName(methodName) else {
            debugLog("Invalid method name or namespace: \(methodName))")
            return
        }
        let wrappedHandler: JSMethodHandler = { [weak target] param in
            guard let strongTarget = target else {
                throw NSError(domain: "NTLBridge", code: -1, userInfo: [NSLocalizedDescriptionKey: "Target instance has been deallocated"])
            }
            return try handler(strongTarget, param)
        }
        let container = JSMethodHandlerContainer(handler: wrappedHandler, target: target)
        registeredHandlers[methodName] = container
        debugLog("Registered method: \(methodName) with target: \(type(of: target))")
    }

    /// 注册一个与实例绑定的方法，自动处理内存管理，支持 Codable 返回类型
    public func register<T: AnyObject, R: Codable>(
        methodName: String,
        expecting returnType: R.Type,
        target: T,
        handler: @escaping (_ target: T, _ param: R) throws -> JSONValue?
    ) {
        register(methodName: methodName, target: target) { target, param in
            let typedParam: R = try NTLBridgeUtil.convertValueOrThrow(param)
            let result = try handler(target, typedParam)
            return result
        }
    }

    /// 注册一个静态或独立的闭包，支持 Codable 返回类型
    public func register<R: Codable>(
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
    public func register(
        methodName: String,
        handler: @escaping (_ param: JSONValue) throws -> JSONValue?
    ) {
        guard NTLBridgeUtil.isValidMethodName(methodName) else {
            debugLog("Invalid method name or namespace: \(methodName)")
            return
        }
        let container = JSMethodHandlerContainer(handler: handler)
        registeredHandlers[methodName] = container
        debugLog("Registered static method: \(methodName)")
    }

    /// 注册一个异步方法
    public func registerAsync(
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
    public func registerAsync<T: AnyObject>(
        methodName: String,
        target: T,
        handler: @escaping (_ target: T, _ param: JSONValue, _ completion: @escaping (Result<JSONValue?, Error>) -> Void) -> Void
    ) {
        guard NTLBridgeUtil.isValidMethodName(methodName) else {
            debugLog("Invalid method name or namespace: \(methodName))")
            return
        }
        let wrappedAsyncHandler: JSAsyncMethodHandler = { [weak target] param, completion in
            guard let strongTarget = target else {
                completion(.failure(NSError(domain: "NTLBridge", code: -1, userInfo: [NSLocalizedDescriptionKey: "Target instance has been deallocated"])))
                return
            }
            handler(strongTarget, param, completion)
        }
        let container = JSMethodHandlerContainer(asyncHandler: wrappedAsyncHandler, target: target)
        registeredHandlers[methodName] = container
        debugLog("Registered async method: \(methodName) with target: \(type(of: target))")
    }

    /// 取消注册方法
    public func unregister(methodName: String) {
        registeredHandlers.removeValue(forKey: methodName)
        debugLog("Unregistered method: \(methodName)")
    }

    /// 获取已注册的方法列表
    public var registeredMethods: [String] {
        return Array(registeredHandlers.keys)
    }
}
