import Foundation

/// JavaScript方法处理器类型别名
public typealias JSMethodHandler = (JSONValue) throws -> JSONValue?

/// JavaScript异步方法处理器类型别名
public typealias JSAsyncMethodHandler = (JSONValue, @escaping (Result<JSONValue?, Error>) -> Void) -> Void

/// JavaScript方法处理器存储结构
internal struct JSMethodHandlerContainer {
    let handler: JSMethodHandler
    let asyncHandler: JSAsyncMethodHandler?
    weak var target: AnyObject?
    private let hasTarget: Bool
    let isAsync: Bool
    
    init(handler: @escaping JSMethodHandler, target: AnyObject? = nil) {
        self.handler = handler
        self.asyncHandler = nil
        self.target = target
        self.hasTarget = target != nil
        self.isAsync = false
    }
    
    /// 每次调用只能回调一次。
    init(asyncHandler: @escaping JSAsyncMethodHandler, target: AnyObject? = nil) {
        self.handler = { _ in throw NSError(domain: "NTLBridge", code: -1, userInfo: [NSLocalizedDescriptionKey: "Async handler used in sync context"]) }
        self.asyncHandler = asyncHandler
        self.target = target
        self.hasTarget = target != nil
        self.isAsync = true
    }
    
    /// 检查目标对象是否仍然有效（对于实例方法）
    var isValid: Bool {
        // 如果初始化时没有目标对象（静态方法），始终有效
        // 如果有目标对象，检查弱引用是否仍然指向有效对象
        hasTarget ? target != nil : true
    }
}