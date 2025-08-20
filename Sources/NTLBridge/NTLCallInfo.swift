import Foundation

/// Native到JavaScript的调用信息模型，用于编码发往JS的调用
public struct NTLCallInfo: Codable, Equatable {
    /// 要调用的JavaScript方法名
    public let method: String
    
    /// 回调ID
    public let callbackId: Int
    
    /// 数据载荷（JSON序列化后的字符串）
    public let data: String
    
    /// 初始化方法
    public init(method: String, callbackId: Int, data: String) {
        self.method = method
        self.callbackId = callbackId
        self.data = data
    }
    
    /// 便捷初始化方法，自动序列化JSONValue数据
    public init(method: String, callbackId: Int, jsonData: JSONValue?) throws {
        self.method = method
        self.callbackId = callbackId
        
        if let jsonData = jsonData {
            let encoder = JSONEncoder()
            let data = try encoder.encode(jsonData)
            self.data = String(data: data, encoding: .utf8) ?? "{}"
        } else {
            self.data = "null"
        }
    }
}