import Testing
@testable import NTLBridge
import Foundation

@Suite("NTLCallInfo Tests")
struct NTLCallInfoTests {
    
    // MARK: - Initialization Tests
    
    @Test("Basic initialization")
    func testBasicInitialization() {
        let callInfo = NTLCallInfo(method: "testMethod", callbackId: 123, data: "{\"key\":\"value\"}")
        
        #expect(callInfo.method == "testMethod")
        #expect(callInfo.callbackId == 123)
        #expect(callInfo.data == "{\"key\":\"value\"}")
    }
    
    @Test("JSON data initialization with JSONValue")
    func testJSONDataInitialization() throws {
        let jsonData = JSONValue.dictionary(["param1": .string("hello"), "param2": .number(42)])
        let callInfo = try NTLCallInfo(method: "processData", callbackId: 456, jsonData: jsonData)
        
        #expect(callInfo.method == "processData")
        #expect(callInfo.callbackId == 456)
        
        // Verify the data is properly JSON encoded
        let dataObject = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [])
        let dict = dataObject as? [String: Any]
        #expect(dict?["param1"] as? String == "hello")
        #expect(dict?["param2"] as? Double == 42)
    }
    
    @Test("JSON data initialization with nil")
    func testJSONDataInitializationWithNil() throws {
        let callInfo = try NTLCallInfo(method: "noData", callbackId: 789, jsonData: nil)
        
        #expect(callInfo.method == "noData")
        #expect(callInfo.callbackId == 789)
        #expect(callInfo.data == "null")
    }
    
    @Test("JSON data initialization with null JSONValue")
    func testJSONDataInitializationWithNullJSONValue() throws {
        let callInfo = try NTLCallInfo(method: "nullData", callbackId: 999, jsonData: .null)
        
        #expect(callInfo.method == "nullData")
        #expect(callInfo.callbackId == 999)
        #expect(callInfo.data == "null")
    }
    
    // MARK: - Codable Tests
    
    @Test("Encoding to JSON")
    func testEncodingToJSON() throws {
        let callInfo = NTLCallInfo(method: "testMethod", callbackId: 100, data: "{\"test\":true}")
        
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(callInfo)
        let jsonString = String(data: encodedData, encoding: .utf8)
        
        #expect(jsonString?.contains("\"method\":\"testMethod\"") == true)
        #expect(jsonString?.contains("\"callbackId\":100") == true)
        #expect(jsonString?.contains("\"data\":\"{\\\"test\\\":true}\"") == true)
    }
    
    @Test("Decoding from JSON")
    func testDecodingFromJSON() throws {
        let jsonString = """
        {
            "method": "getUserInfo",
            "callbackId": 555,
            "data": "{\\"name\\":\\"John\\",\\"age\\":30}"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let callInfo = try decoder.decode(NTLCallInfo.self, from: jsonData)
        
        #expect(callInfo.method == "getUserInfo")
        #expect(callInfo.callbackId == 555)
        #expect(callInfo.data == "{\"name\":\"John\",\"age\":30}")
    }
    
    @Test("Round trip encoding and decoding")
    func testRoundTripEncodingDecoding() throws {
        let originalCallInfo = NTLCallInfo(
            method: "roundTripTest",
            callbackId: 777,
            data: "{\"array\":[1,2,3],\"object\":{\"nested\":\"value\"}}"
        )
        
        // Encode
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(originalCallInfo)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedCallInfo = try decoder.decode(NTLCallInfo.self, from: encodedData)
        
        #expect(decodedCallInfo.method == originalCallInfo.method)
        #expect(decodedCallInfo.callbackId == originalCallInfo.callbackId)
        #expect(decodedCallInfo.data == originalCallInfo.data)
    }
    
    // MARK: - Equality Tests
    
    @Test("Equality comparison")
    func testEquality() {
        let callInfo1 = NTLCallInfo(method: "test", callbackId: 1, data: "{}")
        let callInfo2 = NTLCallInfo(method: "test", callbackId: 1, data: "{}")
        let callInfo3 = NTLCallInfo(method: "different", callbackId: 1, data: "{}")
        let callInfo4 = NTLCallInfo(method: "test", callbackId: 2, data: "{}")
        let callInfo5 = NTLCallInfo(method: "test", callbackId: 1, data: "{\"different\":true}")
        
        // Same content
        #expect(callInfo1 == callInfo2)
        
        // Different method
        #expect(callInfo1 != callInfo3)
        
        // Different callback ID
        #expect(callInfo1 != callInfo4)
        
        // Different data
        #expect(callInfo1 != callInfo5)
    }
    
    // MARK: - JSONValue Integration Tests
    
    @Test("Complex JSONValue data")
    func testComplexJSONValueData() throws {
        let complexData: JSONValue = [
            "users": [
                ["id": 1, "name": "Alice", "active": true],
                ["id": 2, "name": "Bob", "active": false]
            ],
            "metadata": [
                "total": 2,
                "page": 1,
                "hasMore": false
            ],
            "timestamp": 1234567890.123
        ]
        
        let callInfo = try NTLCallInfo(method: "getUsers", callbackId: 888, jsonData: complexData)
        
        // Verify the data can be parsed back
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [])
        let dict = parsedData as? [String: Any]
        
        #expect(dict != nil)
        #expect((dict?["users"] as? [[String: Any]])?.count == 2)
        #expect((dict?["metadata"] as? [String: Any])?["total"] as? Int == 2)
        #expect(dict?["timestamp"] as? Double == 1234567890.123)
    }
    
    @Test("Array JSONValue data")
    func testArrayJSONValueData() throws {
        let arrayData: JSONValue = [
            .string("item1"),
            .number(42),
            .bool(true),
            .dictionary(["nested": .string("value")])
        ]
        
        let callInfo = try NTLCallInfo(method: "processArray", callbackId: 111, jsonData: arrayData)
        
        // Verify the data can be parsed back as array
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [])
        let array = parsedData as? [Any]
        
        #expect(array?.count == 4)
        #expect(array?[0] as? String == "item1")
        #expect(array?[1] as? Double == 42)
        #expect(array?[2] as? Bool == true)
        #expect((array?[3] as? [String: Any])?["nested"] as? String == "value")
    }
    
    @Test("Primitive JSONValue data types")
    func testPrimitiveJSONValueDataTypes() throws {
        // String
        let stringCallInfo = try NTLCallInfo(method: "test", callbackId: 1, jsonData: .string("hello"))
        #expect(stringCallInfo.data == "\"hello\"")
        
        // Number
        let numberCallInfo = try NTLCallInfo(method: "test", callbackId: 2, jsonData: .number(3.14))
        #expect(numberCallInfo.data == "3.14")
        
        // Boolean
        let boolCallInfo = try NTLCallInfo(method: "test", callbackId: 3, jsonData: .bool(true))
        #expect(boolCallInfo.data == "true")
        
        // Null
        let nullCallInfo = try NTLCallInfo(method: "test", callbackId: 4, jsonData: .null)
        #expect(nullCallInfo.data == "null")
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty method name")
    func testEmptyMethodName() throws {
        let callInfo = try NTLCallInfo(method: "", callbackId: 0, jsonData: .null)
        
        #expect(callInfo.method == "")
        #expect(callInfo.callbackId == 0)
        #expect(callInfo.data == "null")
    }
    
    @Test("Negative callback ID")
    func testNegativeCallbackId() throws {
        let callInfo = try NTLCallInfo(method: "test", callbackId: -1, jsonData: .string("test"))
        
        #expect(callInfo.method == "test")
        #expect(callInfo.callbackId == -1)
        #expect(callInfo.data == "\"test\"")
    }
    
    @Test("Very large callback ID")
    func testVeryLargeCallbackId() throws {
        let largeId = Int.max
        let callInfo = try NTLCallInfo(method: "test", callbackId: largeId, jsonData: .number(42))
        
        #expect(callInfo.method == "test")
        #expect(callInfo.callbackId == largeId)
        #expect(callInfo.data == "42")
    }
    
    @Test("Special characters in method name")
    func testSpecialCharactersInMethodName() throws {
        let methodName = "test.method_with-special&characters"
        let callInfo = try NTLCallInfo(method: methodName, callbackId: 123, jsonData: .string("data"))
        
        #expect(callInfo.method == methodName)
        
        // Test encoding/decoding preserves special characters
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(callInfo)
        
        let decoder = JSONDecoder()
        let decodedCallInfo = try decoder.decode(NTLCallInfo.self, from: encodedData)
        
        #expect(decodedCallInfo.method == methodName)
    }
}