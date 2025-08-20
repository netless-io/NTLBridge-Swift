import Foundation

/// Bridge工具类，提供JSON序列化/反序列化功能
public final class NTLBridgeUtil {
    
    // MARK: - JSON Encoder/Decoder
    
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        return encoder
    }()
    
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
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
    
    /// 将JSONValue转换为Any类型
    /// - Parameter value: 要转换的JSONValue
    /// - Returns: 转换后的Any值
    public static func anyValue(from value: JSONValue) -> Any? {
        return value.rawValue
    }
    
    // MARK: - Array Conversion
    
    /// 将参数数组转换为JSONValue数组
    /// - Parameter args: 参数数组
    /// - Returns: JSONValue数组
    public static func jsonArguments(from args: [Any?]) -> [JSONValue] {
        return args.map { jsonValue(from: $0) }
    }
    
    /// 将JSONValue数组转换为Any数组
    /// - Parameter values: JSONValue数组
    /// - Returns: Any数组
    public static func anyArguments(from values: [JSONValue]) -> [Any?] {
        return values.map { anyValue(from: $0) }
    }
    
    // MARK: - Message Parsing
    
    /// 解析来自JavaScript的消息
    /// - Parameter message: 消息字符串
    /// - Returns: 解析后的JSInboundMessage，解析失败返回nil
    public static func parseInboundMessage(_ message: String) -> JSInboundMessage? {
        guard let data = message.data(using: .utf8) else {
            return nil
        }
        
        do {
            return try decoder.decode(JSInboundMessage.self, from: data)
        } catch {
            return nil
        }
    }
    
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
