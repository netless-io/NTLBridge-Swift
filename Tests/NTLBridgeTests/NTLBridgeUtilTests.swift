import Testing
@testable import NTLBridge
import Foundation

@Suite("NTLBridgeUtil Tests")
struct NTLBridgeUtilTests {
    
    // MARK: - JSON String Conversion Tests
    
    @Test("JSONValue to JSON string")
    func testJSONValueToString() {
        // String
        let stringResult = NTLBridgeUtil.jsonString(from: .string("hello"))
        #expect(stringResult == "\"hello\"")
        
        // Number
        let numberResult = NTLBridgeUtil.jsonString(from: .number(42))
        #expect(numberResult == "42")
        
        // Boolean
        let boolResult = NTLBridgeUtil.jsonString(from: .bool(true))
        #expect(boolResult == "true")
        
        // Null
        let nullResult = NTLBridgeUtil.jsonString(from: .null)
        #expect(nullResult == "null")
        
        // Array
        let arrayResult = NTLBridgeUtil.jsonString(from: .array([.string("a"), .number(1)]))
        #expect(arrayResult == "[\"a\",1]")
        
        // Dictionary
        let dictResult = NTLBridgeUtil.jsonString(from: .dictionary(["key": .string("value")]))
        #expect(dictResult == "{\"key\":\"value\"}")
    }
    
    @Test("Nil JSONValue to JSON string")
    func testNilJSONValueToString() {
        let result = NTLBridgeUtil.jsonString(from: nil)
        #expect(result == "null")
    }
    
    @Test("JSON string to JSONValue")
    func testJSONStringToJSONValue() {
        // String
        let stringValue = NTLBridgeUtil.parseJSONValue(from: "\"hello\"")
        #expect(stringValue == .string("hello"))
        
        // Number
        let numberValue = NTLBridgeUtil.parseJSONValue(from: "42")
        #expect(numberValue == .number(42))
        
        // Boolean
        let boolValue = NTLBridgeUtil.parseJSONValue(from: "true")
        #expect(boolValue == .bool(true))
        
        // Null
        let nullValue = NTLBridgeUtil.parseJSONValue(from: "null")
        #expect(nullValue == .null)
        
        // Array
        let arrayValue = NTLBridgeUtil.parseJSONValue(from: "[\"a\",1,true]")
        #expect(arrayValue == .array([.string("a"), .number(1), .bool(true)]))
        
        // Dictionary
        let dictValue = NTLBridgeUtil.parseJSONValue(from: "{\"key\":\"value\"}")
        #expect(dictValue == .dictionary(["key": .string("value")]))
    }
    
    @Test("Invalid JSON string to JSONValue")
    func testInvalidJSONStringToJSONValue() {
        let invalidJSON = "{ invalid json }"
        let result = NTLBridgeUtil.parseJSONValue(from: invalidJSON)
        #expect(result == .null)
        
        let emptyString = ""
        let emptyResult = NTLBridgeUtil.parseJSONValue(from: emptyString)
        #expect(emptyResult == .null)
    }
    
    // MARK: - Any Conversion Tests
    
    @Test("Any to JSONValue conversion")
    func testAnyToJSONValue() {
        // String
        let stringValue = NTLBridgeUtil.jsonValue(from: "hello")
        #expect(stringValue == .string("hello"))
        
        // Int
        let intValue = NTLBridgeUtil.jsonValue(from: 42)
        #expect(intValue == .number(42))
        
        // Double
        let doubleValue = NTLBridgeUtil.jsonValue(from: 3.14)
        #expect(doubleValue == .number(3.14))
        
        // Bool
        let boolValue = NTLBridgeUtil.jsonValue(from: true)
        #expect(boolValue == .bool(true))
        
        // NSNumber
        let nsNumberValue = NTLBridgeUtil.jsonValue(from: NSNumber(value: 123))
        #expect(nsNumberValue == .number(123))
        
        // Array
        let arrayValue = NTLBridgeUtil.jsonValue(from: ["hello", 42, true])
        #expect(arrayValue == .array([.string("hello"), .number(42), .bool(true)]))
        
        // Dictionary
        let dictValue = NTLBridgeUtil.jsonValue(from: ["key": "value"])
        #expect(dictValue == .dictionary(["key": .string("value")]))
        
        // Nil
        let nilValue = NTLBridgeUtil.jsonValue(from: nil)
        #expect(nilValue == .null)
    }
    
    // MARK: - Message Parsing Tests
    
    @Test("Encode call info")
    func testEncodeCallInfo() {
        let callInfo = NTLCallInfo(method: "testMethod", callbackId: 123, data: "{\"key\":\"value\"}")
        let encoded = NTLBridgeUtil.encodeCallInfo(callInfo)
        
        #expect(encoded != nil)
        #expect(encoded?.contains("\"method\":\"testMethod\"") == true)
        #expect(encoded?.contains("\"callbackId\":123") == true)
        #expect(encoded?.contains("\"data\":\"{\\\"key\\\":\\\"value\\\"}\"") == true)
    }
    
    // MARK: - Validation Tests
    
    @Test("Valid method names")
    func testValidMethodNames() {
        #expect(NTLBridgeUtil.isValidMethodName("test"))
        #expect(NTLBridgeUtil.isValidMethodName("testMethod"))
        #expect(NTLBridgeUtil.isValidMethodName("test123"))
        #expect(NTLBridgeUtil.isValidMethodName("test.method"))
        #expect(NTLBridgeUtil.isValidMethodName("test-method"))
    }
    
    @Test("Invalid method names")
    func testInvalidMethodNames() {
        #expect(!NTLBridgeUtil.isValidMethodName(""))
        #expect(!NTLBridgeUtil.isValidMethodName("test method"))
        #expect(!NTLBridgeUtil.isValidMethodName("_private"))
    }
    
    // MARK: - Performance and Edge Cases
    
    @Test("Large data structures")
    func testLargeDataStructures() {
        // Create a large array
        var largeArray: [JSONValue] = []
        for i in 0..<1000 {
            largeArray.append(.dictionary([
                "id": .number(Double(i)),
                "name": .string("Item \(i)"),
                "active": .bool(i % 2 == 0)
            ]))
        }
        
        let largeValue = JSONValue.array(largeArray)
        let jsonString = NTLBridgeUtil.jsonString(from: largeValue)
        let parsedValue = NTLBridgeUtil.parseJSONValue(from: jsonString)
        
        #expect(parsedValue.isArray)
        #expect(parsedValue.arrayValue?.count == 1000)
    }
    
    @Test("Special characters and unicode")
    func testSpecialCharactersAndUnicode() {
        let specialData: [String: JSONValue] = [
            "emoji": .string("🎉🚀💻"),
            "chinese": .string("你好世界"),
            "special": .string("\"quotes\" and \\backslashes\\"),
            "newlines": .string("line1\nline2\tline3")
        ]
        
        let jsonValue = JSONValue.dictionary(specialData)
        let jsonString = NTLBridgeUtil.jsonString(from: jsonValue)
        let parsedValue = NTLBridgeUtil.parseJSONValue(from: jsonString)
        
        #expect(parsedValue == jsonValue)
    }
}
