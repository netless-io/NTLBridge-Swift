import Foundation

extension NTLWebView {
    /// 调用 js bridge 方法，支持直接传入 Codable 参数数组
    public func callHandler<T: Encodable>(
        _ method: String,
        arguments: [T],
        completion: ((Result<JSONValue?, Error>) -> Void)? = nil
    ) {
        do {
            let callInfo = try NTLCallInfo(method: method, callbackId: generateCallbackId(), codableData: arguments)
            internalcallHandler(callInfo: callInfo, completion: completion)
        } catch {
            completion?(.failure(error))
        }
    }

    /// 调用 js bridge 方法（无参数版本）
    public func callHandler(
        _ method: String,
        completion: ((Result<JSONValue?, Error>) -> Void)? = nil
    ) {
        do {
            let callInfo = try NTLCallInfo(method: method, callbackId: generateCallbackId(), codableData: [String]())
            internalcallHandler(callInfo: callInfo, completion: completion)
        } catch {
            completion?(.failure(error))
        }
    }

    /// 调用 js bridge 方法，支持直接传入任意类型参数数组
    public func callHandler(
        _ method: String,
        arguments: [Any],
        completion: ((Result<JSONValue?, Error>) -> Void)? = nil
    ) {
        do {
            let callInfo = try NTLCallInfo(method: method, callbackId: generateCallbackId(), anyArrayData: arguments)
            internalcallHandler(callInfo: callInfo, completion: completion)
        } catch {
            completion?(.failure(error))
        }
    }

    /// 调用 js bridge 方法，支持直接传入 Codable 参数数组并返回指定类型
    public func callTypedHandler<T: Encodable, U: Decodable>(
        _ method: String,
        arguments: [T],
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

    /// 调用 js bridge 方法并返回指定类型（无参数版本）
    public func callTypedHandler<U: Decodable>(
        _ method: String,
        expecting type: U.Type,
        completion: @escaping (Result<U, Error>) -> Void
    ) {
        callTypedHandler(method, arguments: [String](), expecting: type, completion: completion)
    }
}
