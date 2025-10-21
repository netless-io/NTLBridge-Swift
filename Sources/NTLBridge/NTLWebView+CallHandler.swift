import Foundation

public extension NTLWebView {
    /// 调用 js bridge 方法，支持直接传入 Codable 参数数组
    func callHandler<T: Encodable>(
        _ method: String,
        arguments: [T] = [String](),
        completion: ((Result<JSONValue?, Error>) -> Void)? = nil
    ) {
        do {
            let callInfo = try NTLCallInfo(
                method: method,
                callbackId: generateCallbackId(),
                codableData: arguments
            )
            internalcallHandler(callInfo: callInfo, completion: completion)
        } catch {
            completion?(.failure(error))
        }
    }

    /// 调用 js bridge 方法，支持直接传入 Codable 参数数组并返回指定类型
    func callTypedHandler<T: Encodable, U: Decodable>(
        _ method: String,
        arguments: [T] = [String](),
        expecting type: U.Type,
        completion: @escaping (Result<U, Error>) -> Void
    ) {
        callHandler(method, arguments: arguments) { result in
            switch result {
            case .success(let jsonValue):
                do {
                    let typedValue: U = try NTLBridgeUtil.convertValueOrThrow(jsonValue)
                    completion(.success(typedValue))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
