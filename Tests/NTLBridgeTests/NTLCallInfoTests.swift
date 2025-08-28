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
    
    // MARK: - JSONValue Literal Tests
    
    @Test("String literal with encodeCallInfo")
    func testStringLiteralWithEncodeCallInfo() throws {
        let stringValue: JSONValue = "Hello, World!"
        let callInfo = try NTLCallInfo(method: "testString", callbackId: 1, jsonData: stringValue)
        
        #expect(callInfo.method == "testString")
        #expect(callInfo.callbackId == 1)
        #expect(callInfo.data == "\"Hello, World!\"")
        
        // Verify round-trip
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        #expect(parsedData as? String == "Hello, World!")
    }
    
    @Test("Integer literal with encodeCallInfo")
    func testIntegerLiteralWithEncodeCallInfo() throws {
        let intValue: JSONValue = 42
        let callInfo = try NTLCallInfo(method: "testInteger", callbackId: 2, jsonData: intValue)
        
        #expect(callInfo.method == "testInteger")
        #expect(callInfo.callbackId == 2)
        #expect(callInfo.data == "42")
        
        // Verify round-trip
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        #expect(parsedData as? Double == 42)
    }
    
    @Test("Float literal with encodeCallInfo")
    func testFloatLiteralWithEncodeCallInfo() throws {
        let floatValue: JSONValue = 3.14159
        let callInfo = try NTLCallInfo(method: "testFloat", callbackId: 3, jsonData: floatValue)
        
        #expect(callInfo.method == "testFloat")
        #expect(callInfo.callbackId == 3)
        #expect(callInfo.data == "3.14159")
        
        // Verify round-trip
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        #expect(parsedData as? Double == 3.14159)
    }
    
    @Test("Boolean literal with encodeCallInfo")
    func testBooleanLiteralWithEncodeCallInfo() throws {
        let trueValue: JSONValue = true
        let falseValue: JSONValue = false
        
        let trueCallInfo = try NTLCallInfo(method: "testTrue", callbackId: 4, jsonData: trueValue)
        let falseCallInfo = try NTLCallInfo(method: "testFalse", callbackId: 5, jsonData: falseValue)
        
        #expect(trueCallInfo.method == "testTrue")
        #expect(trueCallInfo.callbackId == 4)
        #expect(trueCallInfo.data == "true")
        
        #expect(falseCallInfo.method == "testFalse")
        #expect(falseCallInfo.callbackId == 5)
        #expect(falseCallInfo.data == "false")
        
        // Verify round-trip
        let trueParsed = try JSONSerialization.jsonObject(with: trueCallInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let falseParsed = try JSONSerialization.jsonObject(with: falseCallInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        #expect(trueParsed as? Bool == true)
        #expect(falseParsed as? Bool == false)
    }
    
    @Test("Nil literal with encodeCallInfo")
    func testNilLiteralWithEncodeCallInfo() throws {
        let nullValue: JSONValue = nil
        let callInfo = try NTLCallInfo(method: "testNil", callbackId: 6, jsonData: nullValue)
        
        #expect(callInfo.method == "testNil")
        #expect(callInfo.callbackId == 6)
        #expect(callInfo.data == "null")
        
        // Verify round-trip
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        #expect(parsedData is NSNull)
    }
    
    @Test("Array literal with encodeCallInfo")
    func testArrayLiteralWithEncodeCallInfo() throws {
        let arrayValue: JSONValue = ["hello", 42, true, nil]
        let callInfo = try NTLCallInfo(method: "testArray", callbackId: 7, jsonData: arrayValue)
        
        #expect(callInfo.method == "testArray")
        #expect(callInfo.callbackId == 7)
        
        // Verify round-trip
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let array = parsedData as? [Any]
        
        #expect(array?.count == 4)
        #expect(array?[0] as? String == "hello")
        #expect(array?[1] as? Double == 42)
        #expect(array?[2] as? Bool == true)
        #expect(array?[3] is NSNull)
    }
    
    @Test("Dictionary literal with encodeCallInfo")
    func testDictionaryLiteralWithEncodeCallInfo() throws {
        let dictValue: JSONValue = [
            "name": "Alice",
            "age": 30,
            "active": true,
            "score": 95.5,
            "tags": ["swift", "ios"],
            "metadata": nil
        ]
        
        let callInfo = try NTLCallInfo(method: "testDictionary", callbackId: 8, jsonData: dictValue)
        
        #expect(callInfo.method == "testDictionary")
        #expect(callInfo.callbackId == 8)
        
        // Verify round-trip
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        
        #expect(dict?["name"] as? String == "Alice")
        #expect(dict?["age"] as? Double == 30)
        #expect(dict?["active"] as? Bool == true)
        #expect(dict?["score"] as? Double == 95.5)
        #expect((dict?["tags"] as? [Any])?[0] as? String == "swift")
        #expect(dict?["metadata"] is NSNull)
    }
    
    @Test("Nested structure with literals")
    func testNestedStructureWithLiterals() throws {
        let nestedValue: JSONValue = [
            "user": [
                "id": 123,
                "profile": [
                    "name": "Bob",
                    "preferences": ["theme": "dark", "notifications": true]
                ]
            ],
            "items": ["item1", "item2", nil],
            "stats": ["count": 2, "ratio": 0.85]
        ]
        
        let callInfo = try NTLCallInfo(method: "testNested", callbackId: 9, jsonData: nestedValue)
        
        #expect(callInfo.method == "testNested")
        #expect(callInfo.callbackId == 9)
        
        // Verify complex nested structure
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        
        #expect(dict != nil)
        let user = dict?["user"] as? [String: Any]
        #expect(user != nil)
        let profile = user?["profile"] as? [String: Any]
        #expect(profile?["name"] as? String == "Bob")
        
        let preferences = profile?["preferences"] as? [String: Any]
        #expect(preferences?["theme"] as? String == "dark")
        #expect(preferences?["notifications"] as? Bool == true)
        
        let items = dict?["items"] as? [Any]
        #expect(items?.count == 3)
        #expect(items?[0] as? String == "item1")
        #expect(items?[2] is NSNull)
        
        let stats = dict?["stats"] as? [String: Any]
        #expect(stats?["count"] as? Double == 2)
        #expect(stats?["ratio"] as? Double == 0.85)
    }
    
    @Test("Mixed literal types in complex structure")
    func testMixedLiteralTypesInComplexStructure() throws {
        let complexValue: JSONValue = [
            "booleanFlag": true,
            "integerCount": 100,
            "floatPrice": 19.99,
            "stringName": "Product",
            "nullValue": nil,
            "arrayItems": [1, 2.5, "three", false, nil],
            "nestedDict": ["key": "value", "number": 42]
        ]
        
        let callInfo = try NTLCallInfo(method: "testMixed", callbackId: 10, jsonData: complexValue)
        
        #expect(callInfo.method == "testMixed")
        #expect(callInfo.callbackId == 10)
        
        // Verify all types are preserved
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        
        #expect(dict?["booleanFlag"] as? Bool == true)
        #expect(dict?["integerCount"] as? Double == 100)
        #expect(dict?["floatPrice"] as? Double == 19.99)
        #expect(dict?["stringName"] as? String == "Product")
        #expect(dict?["nullValue"] is NSNull)
        
        let arrayItems = dict?["arrayItems"] as? [Any]
        #expect(arrayItems?.count == 5)
        #expect(arrayItems?[0] as? Double == 1)
        #expect(arrayItems?[1] as? Double == 2.5)
        #expect(arrayItems?[2] as? String == "three")
        #expect(arrayItems?[3] as? Bool == false)
        #expect(arrayItems?[4] is NSNull)
        
        let nestedDict = dict?["nestedDict"] as? [String: Any]
        #expect(nestedDict?["key"] as? String == "value")
        #expect(nestedDict?["number"] as? Double == 42)
    }
    
    @Test("Literal encoding consistency")
    func testLiteralEncodingConsistency() throws {
        // Test that literals encode the same as their explicit counterparts
        let literalString: JSONValue = "test"
        let explicitString = JSONValue.string("test")
        
        let literalCallInfo = try NTLCallInfo(method: "test", callbackId: 1, jsonData: literalString)
        let explicitCallInfo = try NTLCallInfo(method: "test", callbackId: 1, jsonData: explicitString)
        
        #expect(literalCallInfo.data == explicitCallInfo.data)
        
        // Test with numbers
        let literalNumber: JSONValue = 42
        let explicitNumber = JSONValue.number(42)
        
        let literalNumberCallInfo = try NTLCallInfo(method: "test", callbackId: 2, jsonData: literalNumber)
        let explicitNumberCallInfo = try NTLCallInfo(method: "test", callbackId: 2, jsonData: explicitNumber)
        
        #expect(literalNumberCallInfo.data == explicitNumberCallInfo.data)
        
        // Test with arrays
        let literalArray: JSONValue = [1, 2, 3]
        let explicitArray = JSONValue.array([.number(1), .number(2), .number(3)])
        
        let literalArrayCallInfo = try NTLCallInfo(method: "test", callbackId: 3, jsonData: literalArray)
        let explicitArrayCallInfo = try NTLCallInfo(method: "test", callbackId: 3, jsonData: explicitArray)
        
        #expect(literalArrayCallInfo.data == explicitArrayCallInfo.data)
    }
    
    // MARK: - Edge Cases
    
    @Test("Special characters in string literal")
    func testSpecialCharactersInStringLiteral() throws {
        let specialString: JSONValue = "Hello\nWorld\t\"Escaped\"\\Special"
        let callInfo = try NTLCallInfo(method: "testSpecial", callbackId: 11, jsonData: specialString)
        
        #expect(callInfo.method == "testSpecial")
        #expect(callInfo.callbackId == 11)
        
        // Verify special characters are properly escaped
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        #expect(parsedData as? String == "Hello\nWorld\t\"Escaped\"\\Special")
    }
    
    @Test("Unicode characters in string literal")
    func testUnicodeCharactersInStringLiteral() throws {
        let unicodeString: JSONValue = "Hello 世界 🌍"
        let callInfo = try NTLCallInfo(method: "testUnicode", callbackId: 12, jsonData: unicodeString)
        
        #expect(callInfo.method == "testUnicode")
        #expect(callInfo.callbackId == 12)
        
        // Verify Unicode characters are preserved
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        #expect(parsedData as? String == "Hello 世界 🌍")
    }
    
    @Test("Empty array literal")
    func testEmptyArrayLiteral() throws {
        let emptyArray: JSONValue = []
        let callInfo = try NTLCallInfo(method: "testEmptyArray", callbackId: 13, jsonData: emptyArray)
        
        #expect(callInfo.method == "testEmptyArray")
        #expect(callInfo.callbackId == 13)
        #expect(callInfo.data == "[]")
        
        // Verify empty array
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let array = parsedData as? [Any]
        #expect(array?.count == 0)
    }
    
    @Test("Empty dictionary literal")
    func testEmptyDictionaryLiteral() throws {
        let emptyDict: JSONValue = [:]
        let callInfo = try NTLCallInfo(method: "testEmptyDict", callbackId: 14, jsonData: emptyDict)
        
        #expect(callInfo.method == "testEmptyDict")
        #expect(callInfo.callbackId == 14)
        #expect(callInfo.data == "{}")
        
        // Verify empty dictionary
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        #expect(dict?.count == 0)
    }
    
    @Test("Extreme numeric literals")
    func testExtremeNumericLiterals() throws {
        let veryLargeNumber: JSONValue = 999999999999999999.999999
        let verySmallNumber: JSONValue = 0.0000000000000001
        let negativeNumber: JSONValue = -123456789.987654321
        
        let largeCallInfo = try NTLCallInfo(method: "testLarge", callbackId: 15, jsonData: veryLargeNumber)
        let smallCallInfo = try NTLCallInfo(method: "testSmall", callbackId: 16, jsonData: verySmallNumber)
        let negativeCallInfo = try NTLCallInfo(method: "testNegative", callbackId: 17, jsonData: negativeNumber)
        
        // Verify extreme numbers are preserved
        let largeParsed = try JSONSerialization.jsonObject(with: largeCallInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let smallParsed = try JSONSerialization.jsonObject(with: smallCallInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let negativeParsed = try JSONSerialization.jsonObject(with: negativeCallInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        
        #expect(largeParsed as? Double == 999999999999999999.999999)
        #expect(smallParsed as? Double == 0.0000000000000001)
        #expect(negativeParsed as? Double == -123456789.987654321)
    }
    
    // MARK: - Codable Integration Tests
    
    @Test("NTLCallInfo with Codable struct")
    func testNTLCallInfoWithCodableStruct() throws {
        struct User: Codable, Equatable {
            let id: Int
            let name: String
            let isActive: Bool
        }
        
        let user = User(id: 1, name: "Alice", isActive: true)
        let callInfo = try NTLCallInfo(method: "createUser", callbackId: 100, codableData: user)
        
        #expect(callInfo.method == "createUser")
        #expect(callInfo.callbackId == 100)
        
        // Verify the data is properly JSON encoded
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        #expect(dict?["id"] as? Int == 1)
        #expect(dict?["name"] as? String == "Alice")
        #expect(dict?["isActive"] as? Bool == true)
    }
    
    @Test("NTLCallInfo with optional Codable struct")
    func testNTLCallInfoWithOptionalCodableStruct() throws {
        struct Config: Codable {
            let apiKey: String?
            let debugMode: Bool?
        }
        
        let config = Config(apiKey: "secret-key", debugMode: true)
        let callInfo = try NTLCallInfo(method: "updateConfig", callbackId: 200, codableData: config)
        
        #expect(callInfo.method == "updateConfig")
        #expect(callInfo.callbackId == 200)
        
        // Verify the data is properly JSON encoded
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        #expect(dict?["apiKey"] as? String == "secret-key")
        #expect(dict?["debugMode"] as? Bool == true)
    }
    
    @Test("NTLCallInfo with nil Codable")
    func testNTLCallInfoWithNilCodable() throws {
        struct User: Codable {
            let id: Int
            let name: String
        }
        
        let user: User? = nil
        let callInfo = try NTLCallInfo(method: "deleteUser", callbackId: 300, codableData: user)
        
        #expect(callInfo.method == "deleteUser")
        #expect(callInfo.callbackId == 300)
        #expect(callInfo.data == "null")
    }
    
    @Test("NTLCallInfo with Codable array")
    func testNTLCallInfoWithCodableArray() throws {
        struct Item: Codable {
            let name: String
            let quantity: Int
        }
        
        let items = [Item(name: "Apple", quantity: 5), Item(name: "Banana", quantity: 3)]
        let callInfo = try NTLCallInfo(method: "updateInventory", callbackId: 400, codableData: items)
        
        #expect(callInfo.method == "updateInventory")
        #expect(callInfo.callbackId == 400)
        
        // Verify the data is properly JSON encoded
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let array = parsedData as? [Any]
        #expect(array?.count == 2)
        
        let firstItem = array?[0] as? [String: Any]
        #expect(firstItem?["name"] as? String == "Apple")
        #expect(firstItem?["quantity"] as? Int == 5)
        
        let secondItem = array?[1] as? [String: Any]
        #expect(secondItem?["name"] as? String == "Banana")
        #expect(secondItem?["quantity"] as? Int == 3)
    }
    
    @Test("NTLCallInfo with Codable dictionary")
    func testNTLCallInfoWithCodableDictionary() throws {
        let metadata: [String: String] = [
            "version": "1.0.0",
            "author": "Developer",
            "license": "MIT"
        ]
        
        let callInfo = try NTLCallInfo(method: "setMetadata", callbackId: 500, codableData: metadata)
        
        #expect(callInfo.method == "setMetadata")
        #expect(callInfo.callbackId == 500)
        
        // Verify the data is properly JSON encoded
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        #expect(dict?["version"] as? String == "1.0.0")
        #expect(dict?["author"] as? String == "Developer")
        #expect(dict?["license"] as? String == "MIT")
    }
    
    @Test("NTLCallInfo with nested Codable structure")
    func testNTLCallInfoWithNestedCodableStructure() throws {
        struct Address: Codable {
            let street: String
            let city: String
            let zipCode: String
        }
        
        struct Person: Codable {
            let name: String
            let age: Int
            let address: Address
            let hobbies: [String]
        }
        
        let person = Person(
            name: "Bob",
            age: 30,
            address: Address(street: "123 Main St", city: "New York", zipCode: "10001"),
            hobbies: ["reading", "swimming", "coding"]
        )
        
        let callInfo = try NTLCallInfo(method: "createPerson", callbackId: 600, codableData: person)
        
        #expect(callInfo.method == "createPerson")
        #expect(callInfo.callbackId == 600)
        
        // Verify the data is properly JSON encoded
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        #expect(dict?["name"] as? String == "Bob")
        #expect(dict?["age"] as? Int == 30)
        
        let address = dict?["address"] as? [String: Any]
        #expect(address?["street"] as? String == "123 Main St")
        #expect(address?["city"] as? String == "New York")
        #expect(address?["zipCode"] as? String == "10001")
        
        let hobbies = dict?["hobbies"] as? [Any]
        #expect(hobbies?.count == 3)
        #expect(hobbies?[0] as? String == "reading")
        #expect(hobbies?[1] as? String == "swimming")
        #expect(hobbies?[2] as? String == "coding")
    }
    
    @Test("NTLCallInfo with Codable enum")
    func testNTLCallInfoWithCodableEnum() throws {
        enum Status: String, Codable {
            case active
            case inactive
            case pending
        }
        
        let status = Status.active
        let callInfo = try NTLCallInfo(method: "updateStatus", callbackId: 700, codableData: status)
        
        #expect(callInfo.method == "updateStatus")
        #expect(callInfo.callbackId == 700)
        
        // Verify the data is properly JSON encoded
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        #expect(parsedData as? String == "active")
    }
    
    @Test("NTLCallInfo with Codable containing dates")
    func testNTLCallInfoWithCodableContainingDates() throws {
        struct Event: Codable {
            let name: String
            let date: Date
        }
        
        let date = Date(timeIntervalSince1970: 1234567890)
        let event = Event(name: "Conference", date: date)
        let callInfo = try NTLCallInfo(method: "scheduleEvent", callbackId: 800, codableData: event)
        
        #expect(callInfo.method == "scheduleEvent")
        #expect(callInfo.callbackId == 800)
        
        // Verify the data is properly JSON encoded
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        #expect(dict?["name"] as? String == "Conference")
        #expect(dict?["date"] as? Double != nil)
    }
    
    @Test("NTLCallInfo with Codable containing data")
    func testNTLCallInfoWithCodableContainingData() throws {
        struct File: Codable {
            let name: String
            let content: Data
        }
        
        let content = "Hello, World!".data(using: .utf8)!
        let file = File(name: "greeting.txt", content: content)
        let callInfo = try NTLCallInfo(method: "uploadFile", callbackId: 900, codableData: file)
        
        #expect(callInfo.method == "uploadFile")
        #expect(callInfo.callbackId == 900)
        
        // Verify the data is properly JSON encoded
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        #expect(dict?["name"] as? String == "greeting.txt")
        #expect(dict?["content"] as? String != nil)
    }
    
    @Test("NTLCallInfo with custom coding keys")
    func testNTLCallInfoWithCustomCodingKeys() throws {
        struct User: Codable {
            let userId: Int
            let fullName: String
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case fullName = "full_name"
            }
        }
        
        let user = User(userId: 123, fullName: "John Doe")
        let callInfo = try NTLCallInfo(method: "createUser", callbackId: 1000, codableData: user)
        
        #expect(callInfo.method == "createUser")
        #expect(callInfo.callbackId == 1000)
        
        // Verify the data uses custom coding keys
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        #expect(dict?["user_id"] as? Int == 123)
        #expect(dict?["full_name"] as? String == "John Doe")
        #expect(dict?["userId"] == nil)
        #expect(dict?["fullName"] == nil)
    }
    
    @Test("Codable encoding consistency")
    func testCodableEncodingConsistency() throws {
        struct User: Codable, Equatable {
            let id: Int
            let name: String
        }
        
        let user = User(id: 1, name: "Alice")
        
        // Compare direct Codable encoding vs JSONValue then encoding
        let directCallInfo = try NTLCallInfo(method: "test", callbackId: 1, codableData: user)
        let jsonValue = try JSONValue(codable: user)
        let indirectCallInfo = try NTLCallInfo(method: "test", callbackId: 1, jsonData: jsonValue)
        
        // Parse both JSON strings and compare the objects instead of string comparison
        // to handle dictionary ordering differences
        let directData = try JSONSerialization.jsonObject(with: directCallInfo.data.data(using: .utf8)!, options: []) as? [String: Any]
        let indirectData = try JSONSerialization.jsonObject(with: indirectCallInfo.data.data(using: .utf8)!, options: []) as? [String: Any]
        
        // Compare individual values to handle Any type
        #expect(directData?["id"] as? Int == indirectData?["id"] as? Int)
        #expect(directData?["name"] as? String == indirectData?["name"] as? String)
    }
    
    @Test("Complex real-world Codable structure")
    func testComplexRealWorldCodableStructure() throws {
        struct OrderItem: Codable {
            let productId: String
            let quantity: Int
            let price: Double
        }
        
        struct ShippingAddress: Codable {
            let street: String
            let city: String
            let state: String
            let zipCode: String
            let country: String
        }
        
        struct Order: Codable {
            let id: String
            let customerId: String
            let items: [OrderItem]
            let shippingAddress: ShippingAddress
            let subtotal: Double
            let tax: Double
            let total: Double
            let createdAt: Date
            let status: String
        }
        
        let order = Order(
            id: "ORD-12345",
            customerId: "CUST-67890",
            items: [
                OrderItem(productId: "PROD-001", quantity: 2, price: 29.99),
                OrderItem(productId: "PROD-002", quantity: 1, price: 49.99)
            ],
            shippingAddress: ShippingAddress(
                street: "123 Main St",
                city: "New York",
                state: "NY",
                zipCode: "10001",
                country: "USA"
            ),
            subtotal: 109.97,
            tax: 8.80,
            total: 118.77,
            createdAt: Date(),
            status: "pending"
        )
        
        let callInfo = try NTLCallInfo(method: "createOrder", callbackId: 2000, codableData: order)
        
        #expect(callInfo.method == "createOrder")
        #expect(callInfo.callbackId == 2000)
        
        // Verify the complex structure is properly encoded
        let parsedData = try JSONSerialization.jsonObject(with: callInfo.data.data(using: .utf8)!, options: [.fragmentsAllowed])
        let dict = parsedData as? [String: Any]
        
        #expect(dict?["id"] as? String == "ORD-12345")
        #expect(dict?["customerId"] as? String == "CUST-67890")
        
        let items = dict?["items"] as? [Any]
        #expect(items?.count == 2)
        
        let firstItem = items?[0] as? [String: Any]
        #expect(firstItem?["productId"] as? String == "PROD-001")
        #expect(firstItem?["quantity"] as? Int == 2)
        #expect(firstItem?["price"] as? Double == 29.99)
        
        let shippingAddress = dict?["shippingAddress"] as? [String: Any]
        #expect(shippingAddress?["street"] as? String == "123 Main St")
        #expect(shippingAddress?["city"] as? String == "New York")
        #expect(shippingAddress?["state"] as? String == "NY")
        
        #expect(dict?["subtotal"] as? Double == 109.97)
        #expect(dict?["total"] as? Double == 118.77)
        #expect(dict?["status"] as? String == "pending")
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