import Testing
@testable import NTLBridge
import Foundation

@Suite("JSONValue Tests")
struct JSONValueTests {
    
    // MARK: - Basic Type Tests
    
    @Test("String value creation and extraction")
    func testStringValue() {
        let value = JSONValue.string("Hello, World!")
        
        #expect(value.isString == true)
        #expect(value.stringValue == "Hello, World!")
        #expect(value.rawValue as? String == "Hello, World!")
    }
    
    @Test("Number value creation and extraction")
    func testNumberValue() {
        let value = JSONValue.number(42.5)
        
        #expect(value.isNumber == true)
        #expect(value.numberValue == 42.5)
        #expect(value.rawValue as? Double == 42.5)
    }
    
    @Test("Boolean value creation and extraction")
    func testBoolValue() {
        let trueValue = JSONValue.bool(true)
        let falseValue = JSONValue.bool(false)
        
        #expect(trueValue.isBool == true)
        #expect(trueValue.boolValue == true)
        #expect(trueValue.rawValue as? Bool == true)
        
        #expect(falseValue.isBool == true)
        #expect(falseValue.boolValue == false)
        #expect(falseValue.rawValue as? Bool == false)
    }
    
    @Test("Null value creation and extraction")
    func testNullValue() {
        let value = JSONValue.null
        
        #expect(value.isNull == true)
        #expect(value.rawValue == nil)
    }
    
    @Test("Array value creation and extraction")
    func testArrayValue() {
        let array: [JSONValue] = [.string("hello"), .number(42), .bool(true)]
        let value = JSONValue.array(array)
        
        #expect(value.isArray == true)
        #expect(value.arrayValue?.count == 3)
        #expect(value.arrayValue?[0] == .string("hello"))
        #expect(value.arrayValue?[1] == .number(42))
        #expect(value.arrayValue?[2] == .bool(true))
    }
    
    @Test("Dictionary value creation and extraction")
    func testDictionaryValue() {
        let dict: [String: JSONValue] = [
            "name": .string("John"),
            "age": .number(30),
            "active": .bool(true)
        ]
        let value = JSONValue.dictionary(dict)
        
        #expect(value.isDictionary == true)
        #expect(value.dictionaryValue?["name"] == .string("John"))
        #expect(value.dictionaryValue?["age"] == .number(30))
        #expect(value.dictionaryValue?["active"] == .bool(true))
    }
    
    // MARK: - Literal Support Tests
    
    @Test("String literal initialization")
    func testStringLiteral() {
        let value: JSONValue = "Hello"
        #expect(value == .string("Hello"))
    }
    
    @Test("Integer literal initialization")
    func testIntegerLiteral() {
        let value: JSONValue = 42
        #expect(value == .number(42))
    }
    
    @Test("Float literal initialization")
    func testFloatLiteral() {
        let value: JSONValue = 3.14
        #expect(value == .number(3.14))
    }
    
    @Test("Boolean literal initialization")
    func testBooleanLiteral() {
        let trueValue: JSONValue = true
        let falseValue: JSONValue = false
        
        #expect(trueValue == .bool(true))
        #expect(falseValue == .bool(false))
    }
    
    @Test("Array literal initialization")
    func testArrayLiteral() {
        let value: JSONValue = ["hello", 42, true]
        let expected = JSONValue.array([.string("hello"), .number(42), .bool(true)])
        
        #expect(value == expected)
    }
    
    @Test("Dictionary literal initialization")
    func testDictionaryLiteral() {
        let value: JSONValue = ["name": "John", "age": 30]
        let expected = JSONValue.dictionary([
            "name": .string("John"),
            "age": .number(30)
        ])
        
        #expect(value == expected)
    }
    
    @Test("Nil literal initialization")
    func testNilLiteral() {
        let value: JSONValue = nil
        #expect(value == .null)
    }
    
    // MARK: - Any Conversion Tests
    
    @Test("String from Any")
    func testStringFromAny() {
        let value = JSONValue(any: "Hello")
        #expect(value == .string("Hello"))
    }
    
    @Test("NSNumber from Any")
    func testNSNumberFromAny() {
        let numberValue = JSONValue(any: NSNumber(value: 42))
        #expect(numberValue == .number(42))
        
        let boolValue = JSONValue(any: NSNumber(value: true))
        #expect(boolValue == .bool(true))
    }
    
    @Test("Array from Any")
    func testArrayFromAny() {
        let anyArray: [Any] = ["hello", 42, true]
        let value = JSONValue(any: anyArray)
        let expected = JSONValue.array([.string("hello"), .number(42), .bool(true)])
        
        #expect(value == expected)
    }
    
    @Test("Dictionary from Any")
    func testDictionaryFromAny() {
        let anyDict: [String: Any] = ["name": "John", "age": 30]
        let value = JSONValue(any: anyDict)
        let expected = JSONValue.dictionary([
            "name": .string("John"),
            "age": .number(30)
        ])
        
        #expect(value == expected)
    }
    
    @Test("Nil from Any")
    func testNilFromAny() {
        let value = JSONValue(any: nil)
        #expect(value == .null)
    }
    
    @Test("Invalid type from Any")
    func testInvalidTypeFromAny() {
        struct CustomStruct {}
        let value = JSONValue(any: CustomStruct())
        #expect(value == nil)
    }
    
    // MARK: - Codable Tests
    
    @Test("JSON encoding and decoding")
    func testJSONCodable() throws {
        let original: JSONValue = [
            "name": "John",
            "age": 30,
            "active": true,
            "scores": [85.5, 92.0, 78.5],
            "metadata": nil
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(JSONValue.self, from: data)
        
        #expect(decoded == original)
    }
    
    @Test("Complex nested structure")
    func testComplexNestedStructure() throws {
        let original: JSONValue = [
            "users": [
                [
                    "id": 1,
                    "name": "Alice",
                    "preferences": [
                        "theme": "dark",
                        "notifications": true
                    ]
                ],
                [
                    "id": 2,
                    "name": "Bob",
                    "preferences": [
                        "theme": "light",
                        "notifications": false
                    ]
                ]
            ],
            "count": 2
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(JSONValue.self, from: data)
        
        #expect(decoded == original)
    }
    
    // MARK: - Equality Tests
    
    @Test("Equality comparison")
    func testEquality() {
        // Same types
        #expect(JSONValue.string("hello") == JSONValue.string("hello"))
        #expect(JSONValue.number(42) == JSONValue.number(42))
        #expect(JSONValue.bool(true) == JSONValue.bool(true))
        #expect(JSONValue.null == JSONValue.null)
        
        // Different values
        #expect(JSONValue.string("hello") != JSONValue.string("world"))
        #expect(JSONValue.number(42) != JSONValue.number(43))
        #expect(JSONValue.bool(true) != JSONValue.bool(false))
        
        // Different types
        #expect(JSONValue.string("42") != JSONValue.number(42))
        #expect(JSONValue.bool(true) != JSONValue.number(1))
        #expect(JSONValue.null != JSONValue.string("null"))
    }
    
    // MARK: - Raw Value Tests
    
    @Test("Raw value conversion")
    func testRawValueConversion() {
        // Basic types
        #expect(JSONValue.string("hello").rawValue as? String == "hello")
        #expect(JSONValue.number(42.5).rawValue as? Double == 42.5)
        #expect(JSONValue.bool(true).rawValue as? Bool == true)
        #expect(JSONValue.null.rawValue == nil)
        
        // Array
        let arrayValue = JSONValue.array([.string("a"), .number(1)])
        let rawArray = arrayValue.rawValue as? [Any?]
        #expect(rawArray?.count == 2)
        #expect(rawArray?[0] as? String == "a")
        #expect(rawArray?[1] as? Double == 1)
        
        // Dictionary
        let dictValue = JSONValue.dictionary(["key": .string("value")])
        let rawDict = dictValue.rawValue as? [String: Any?]
        #expect(rawDict?["key"] as? String == "value")
    }
}