import Foundation

/// JavaScript到Native的消息模型，用于解码来自JS的调用
public struct JSInboundMessage: Codable, Equatable {
    /// 回调存根标识符
    public let callbackStub: String?
    
    /// 消息数据
    public let data: JSONValue?
    
    /// 初始化方法
    public init(callbackStub: String? = nil, data: JSONValue? = nil) {
        self.callbackStub = callbackStub
        self.data = data
    }
    
    private enum CodingKeys: String, CodingKey {
        case callbackStub = "_dscbstub"
        case data
    }
    
    // MARK: - Custom Codable Implementation
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle callbackStub - decode as optional string
        self.callbackStub = try container.decodeIfPresent(String.self, forKey: .callbackStub)
        
        // Handle data - decode as optional JSONValue, converting null to .null
        if container.contains(.data) {
            self.data = try container.decodeIfPresent(JSONValue.self, forKey: .data) ?? .null
        } else {
            self.data = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Always encode callbackStub, even if nil
        try container.encode(callbackStub, forKey: .callbackStub)
        
        // Always encode data, even if nil
        try container.encode(data, forKey: .data)
    }
}