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
      
    /// 便捷初始化方法，直接传入Codable类型数据
    public init<T: Encodable>(method: String, callbackId: Int, codableData: T) throws {
        self.method = method
        self.callbackId = callbackId
        
        let encoder = NTLBridgeUtil.createEncoder()
        let data = try encoder.encode(codableData)
        self.data = String(data: data, encoding: .utf8) ?? "{}"
    }
    
    /// 便捷初始化方法，直接传入可选Codable类型数据
    public init<T: Encodable>(method: String, callbackId: Int, codableData: T?) throws {
        self.method = method
        self.callbackId = callbackId
        
        if let codableData = codableData {
            let encoder = NTLBridgeUtil.createEncoder()
            let data = try encoder.encode(codableData)
            self.data = String(data: data, encoding: .utf8) ?? "{}"
        } else {
            self.data = "null"
        }
    }
    
    /// 便捷初始化方法，直接传入任意类型数组数据
    public init(method: String, callbackId: Int, anyArrayData: [Any]) throws {
        self.method = method
        self.callbackId = callbackId
        
        let jsonValues = anyArrayData.compactMap { JSONValue(any: $0) }
        let jsonArray = JSONValue.array(jsonValues)
        let encoder = NTLBridgeUtil.createEncoder()
        let data = try encoder.encode(jsonArray)
        self.data = String(data: data, encoding: .utf8) ?? "[]"
    }
}
