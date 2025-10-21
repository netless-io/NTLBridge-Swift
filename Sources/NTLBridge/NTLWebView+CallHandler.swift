import Foundation

public extension NTLWebView {
    /// 调用 js bridge 方法，支持直接传入 Codable 参数数组
    func callHandler<T: Encodable>(
        _ method: String,
        arguments: [T] = [String](),
        completion: ((Result<Any?, Error>) -> Void)? = nil
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

    /// 调用 js bridge 方法，接受已经序列化好的 JSON 参数字符串
    func callHandler(
        _ method: String,
        jsonString: String,
        completion: ((Result<Any?, Error>) -> Void)? = nil
    ) {
        let callInfo = NTLCallInfo(
            method: method,
            callbackId: generateCallbackId(),
            data: jsonString
        )
        internalcallHandler(callInfo: callInfo, completion: completion)
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
            case .success(let result):
                do {
                    guard let result else {
                        throw NTLBridgeError.invalidValue
                    }
                    let typedValue: U = try NTLBridgeUtil.convertValueOrThrow(result)
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
