import Foundation

func jsStructuredError(jsonValue: JSONValue) -> NSError? {
    guard case let .dictionary(dictionary) = jsonValue,
          let name = dictionary["name"]?.stringValue,
          let message = dictionary["message"]?.stringValue,
          let stack = dictionary["stack"]?.stringValue
    else {
        return nil
    }
    let description = "name: \(name)\nmessage: \(message)\nstack: \(stack)"
    let userInfo: [String: Any] = [
        NSLocalizedDescriptionKey: description,
    ]
    return NSError(domain: "NTLBridge", code: -1, userInfo: userInfo)
}

/// Bridge错误类型
public enum NTLBridgeError: Error, LocalizedError {
    case invalidValue
    case typeConversionFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidValue:
            return "Invalid value for conversion"
        case let .typeConversionFailed(error):
            return "Type conversion failed: \(error.localizedDescription)"
        }
    }
}

/// Bridge工具类，提供JSON序列化/反序列化功能
public enum NTLBridgeUtil {
    // MARK: - JSON Encoder/Decoder
    
    /// 创建JSONEncoder实例，可被子类重写
    /// - Returns: 配置好的JSONEncoder实例
    public static func createEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        return encoder
    }
    
    /// 创建JSONDecoder实例，可被子类重写
    /// - Returns: 配置好的JSONDecoder实例
    public static func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }
    
    private static let encoder = createEncoder()
    private static let decoder = createDecoder()
    
    // MARK: - JSONValue Conversion
    
    /// 将JSONValue转换为JSON字符串
    /// - Parameter value: 要转换的JSONValue
    /// - Returns: JSON字符串，转换失败返回"null"
    public static func jsonString(from value: JSONValue?) -> String {
        guard let value = value else { return "null" }
        
        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8) ?? "null"
        } catch {
            return "null"
        }
    }
    
    /// 从JSON字符串解析JSONValue
    /// - Parameter jsonString: JSON字符串
    /// - Returns: 解析后的JSONValue，解析失败返回null
    public static func parseJSONValue(from jsonString: String) -> JSONValue {
        guard let data = jsonString.data(using: .utf8) else {
            return .null
        }
        
        do {
            return try decoder.decode(JSONValue.self, from: data)
        } catch {
            return .null
        }
    }
    
    /// 将Any类型转换为JSONValue
    /// - Parameter any: 要转换的Any值
    /// - Returns: 转换后的JSONValue，转换失败返回null
    public static func jsonValue(from any: Any?) -> JSONValue {
        return JSONValue(any: any) ?? .null
    }
    
    // MARK: - Message Parsing
    
    /// 编码发往JavaScript的调用信息
    /// - Parameter callInfo: 调用信息
    /// - Returns: 编码后的JSON字符串，编码失败返回nil
    public static func encodeCallInfo(_ callInfo: NTLCallInfo) -> String? {
        do {
            let data = try encoder.encode(callInfo)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    // MARK: - Type Conversion
    
    /// 将JSONValue转换为指定类型，抛出错误
    /// - Parameter value: 要转换的JSONValue
    /// - Returns: 转换后的指定类型
    /// - Throws: 类型转换错误
    public static func convertValueOrThrow<T: Decodable>(_ value: JSONValue?) throws -> T {
        guard let value = value else { throw NTLBridgeError.invalidValue }
        
        do {
            let data = try encoder.encode(value)
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NTLBridgeError.typeConversionFailed(error)
        }
    }
    
    // MARK: - Validation
    
    /// 验证方法名是否有效
    /// - Parameter methodName: 方法名
    /// - Returns: 是否有效
    public static func isValidMethodName(_ methodName: String) -> Bool {
        return !methodName.isEmpty &&
            !methodName.contains(" ") &&
            !methodName.hasPrefix("_")
    }
}
