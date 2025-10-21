import Foundation

/// JavaScript方法处理器类型别名
public typealias JSRawResponseMethodHandler = (_ param: Any?) throws -> JSONValue?

/// JavaScript异步方法处理器类型别名
public typealias JSAsyncMethodHandler = (Any, @escaping (Result<JSONValue?, Error>) -> Void) throws -> Void

enum ContainerHandler {
    case asyncHandler(JSAsyncMethodHandler)
    case syncHandler(JSRawResponseMethodHandler)
}

/// JavaScript方法处理器存储结构
struct JSMethodHandlerContainer {
    let handler: ContainerHandler
    weak var target: AnyObject?
    private let hasTarget: Bool

    init(rawResponseHandler: @escaping JSRawResponseMethodHandler, target: AnyObject? = nil) {
        self.handler = .syncHandler(rawResponseHandler)
        self.target = target
        self.hasTarget = target != nil
    }

    /// 每次调用只能回调一次。
    init(asyncHandler: @escaping JSAsyncMethodHandler, target: AnyObject? = nil) {
        self.handler = .asyncHandler(asyncHandler)
        self.target = target
        self.hasTarget = target != nil
    }

    /// 检查目标对象是否仍然有效（对于实例方法）
    var isValid: Bool {
        // 如果初始化时没有目标对象（静态方法），始终有效
        // 如果有目标对象，检查弱引用是否仍然指向有效对象
        hasTarget ? target != nil : true
    }
}
