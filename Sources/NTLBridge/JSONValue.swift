import Foundation

/// 类型安全的JSON值表示，用于Swift与JavaScript之间的数据传递
public enum JSONValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case dictionary([String: JSONValue])
    case array([JSONValue])
    case null
    
    // MARK: - Codable Implementation
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let numberValue = try? container.decode(Double.self) {
            self = .number(numberValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([JSONValue].self) {
            self = .array(arrayValue)
        } else if let dictionaryValue = try? container.decode([String: JSONValue].self) {
            self = .dictionary(dictionaryValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid JSON value"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
    
    // MARK: - Raw Value Conversion
    
    /// 获取原始值，用于与其他框架交互
    public var rawValue: Any? {
        switch self {
        case .null:
            return nil
        case .bool(let value):
            return value
        case .number(let value):
            return value
        case .string(let value):
            return value
        case .array(let values):
            return values.map { $0.rawValue }
        case .dictionary(let dict):
            return dict.compactMapValues { $0.rawValue }
        }
    }
    
    // MARK: - Convenience Initializers
    
    /// 从Any类型创建JSONValue
    public init?(any value: Any?) {
        guard let value = value else {
            self = .null
            return
        }
        
        switch value {
        case let stringValue as String:
            self = .string(stringValue)
        case let boolValue as Bool:
            self = .bool(boolValue)
        case let intValue as Int:
            self = .number(Double(intValue))
        case let doubleValue as Double:
            self = .number(doubleValue)
        case let floatValue as Float:
            self = .number(Double(floatValue))
        case let numberValue as NSNumber:
            // 区分布尔值和数字（NSNumber来源于ObjC）
            if numberValue.isBoolValue {
                self = .bool(numberValue.boolValue)
            } else {
                self = .number(numberValue.doubleValue)
            }
        case let arrayValue as [Any]:
            let jsonValues = arrayValue.compactMap { JSONValue(any: $0) }
            self = .array(jsonValues)
        case let dictValue as [String: Any]:
            let jsonDict = dictValue.compactMapValues { JSONValue(any: $0) }
            self = .dictionary(jsonDict)
        default:
            return nil
        }
    }
    
    // MARK: - Type Checking Properties
    
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }
    
    public var isString: Bool {
        if case .string = self { return true }
        return false
    }
    
    public var isNumber: Bool {
        if case .number = self { return true }
        return false
    }
    
    public var isBool: Bool {
        if case .bool = self { return true }
        return false
    }
    
    public var isArray: Bool {
        if case .array = self { return true }
        return false
    }
    
    public var isDictionary: Bool {
        if case .dictionary = self { return true }
        return false
    }
    
    // MARK: - Value Extraction
    
    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
    
    public var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }
    
    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
    
    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }
    
    public var dictionaryValue: [String: JSONValue]? {
        if case .dictionary(let value) = self { return value }
        return nil
    }
}

// MARK: - NSNumber Extension

private extension NSNumber {
    var isBoolValue: Bool {
        // 检查是否为布尔值
        return CFBooleanGetTypeID() == CFGetTypeID(self)
    }
}

// MARK: - Literal Support

extension JSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension JSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        let dict = Dictionary(uniqueKeysWithValues: elements)
        self = .dictionary(dict)
    }
}

extension JSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}