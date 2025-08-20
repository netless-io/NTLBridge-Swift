import Testing
@testable import NTLBridge
import Foundation

@Suite("JSInboundMessage Tests")
struct JSInboundMessageTests {
    
    // MARK: - Initialization Tests
    
    @Test("Default initialization")
    func testDefaultInitialization() {
        let message = JSInboundMessage()
        
        #expect(message.callbackStub == nil)
        #expect(message.data == nil)
    }
    
    @Test("Initialization with parameters")
    func testInitializationWithParameters() {
        let data = JSONValue.dictionary(["key": .string("value")])
        let message = JSInboundMessage(callbackStub: "callback123", data: data)
        
        #expect(message.callbackStub == "callback123")
        #expect(message.data == data)
    }
    
    // MARK: - Codable Tests
    
    @Test("Encoding with all fields")
    func testEncodingWithAllFields() throws {
        let data = JSONValue.dictionary(["param": .string("test")])
        let message = JSInboundMessage(callbackStub: "cb_001", data: data)
        
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(message)
        let jsonString = String(data: encodedData, encoding: .utf8)
        
        #expect(jsonString?.contains("\"_dscbstub\":\"cb_001\"") == true)
        #expect(jsonString?.contains("\"data\"") == true)
    }
    
    @Test("Encoding with nil fields")
    func testEncodingWithNilFields() throws {
        let message = JSInboundMessage(callbackStub: nil, data: nil)
        
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(message)
        let jsonString = String(data: encodedData, encoding: .utf8)
        
        #expect(jsonString?.contains("\"_dscbstub\":null") == true)
        #expect(jsonString?.contains("\"data\":null") == true)
    }
    
    @Test("Decoding from JSON")
    func testDecodingFromJSON() throws {
        let jsonString = """
        {
            "_dscbstub": "callback_id_123",
            "data": {
                "method": "testMethod",
                "args": ["arg1", 42, true]
            }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let message = try decoder.decode(JSInboundMessage.self, from: jsonData)
        
        #expect(message.callbackStub == "callback_id_123")
        #expect(message.data?.isDictionary == true)
        
        if let dict = message.data?.dictionaryValue {
            #expect(dict["method"] == .string("testMethod"))
            #expect(dict["args"]?.isArray == true)
        }
    }
    
    @Test("Decoding with missing callback stub")
    func testDecodingWithMissingCallbackStub() throws {
        let jsonString = """
        {
            "data": {
                "message": "hello"
            }
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let message = try decoder.decode(JSInboundMessage.self, from: jsonData)
        
        #expect(message.callbackStub == nil)
        #expect(message.data?.isDictionary == true)
    }
    
    @Test("Decoding with missing data")
    func testDecodingWithMissingData() throws {
        let jsonString = """
        {
            "_dscbstub": "test_callback"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let message = try decoder.decode(JSInboundMessage.self, from: jsonData)
        
        #expect(message.callbackStub == "test_callback")
        #expect(message.data == nil)
    }
    
    @Test("Decoding with null values")
    func testDecodingWithNullValues() throws {
        let jsonString = """
        {
            "_dscbstub": null,
            "data": null
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let message = try decoder.decode(JSInboundMessage.self, from: jsonData)
        
        #expect(message.callbackStub == nil)
        #expect(message.data == .null)
    }
    
    @Test("Round trip encoding and decoding")
    func testRoundTripEncodingDecoding() throws {
        let originalData = JSONValue.array([
            .string("hello"),
            .number(123),
            .bool(true),
            .dictionary(["nested": .string("value")])
        ])
        let originalMessage = JSInboundMessage(
            callbackStub: "round_trip_test",
            data: originalData
        )
        
        // Encode
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(originalMessage)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(JSInboundMessage.self, from: encodedData)
        
        #expect(decodedMessage.callbackStub == originalMessage.callbackStub)
        #expect(decodedMessage.data == originalMessage.data)
    }
    
    // MARK: - Equality Tests
    
    @Test("Equality comparison")
    func testEquality() {
        let data1 = JSONValue.string("test")
        let data2 = JSONValue.string("test")
        let data3 = JSONValue.string("different")
        
        let message1 = JSInboundMessage(callbackStub: "cb1", data: data1)
        let message2 = JSInboundMessage(callbackStub: "cb1", data: data2)
        let message3 = JSInboundMessage(callbackStub: "cb2", data: data1)
        let message4 = JSInboundMessage(callbackStub: "cb1", data: data3)
        
        // Same content
        #expect(message1 == message2)
        
        // Different callback stub
        #expect(message1 != message3)
        
        // Different data
        #expect(message1 != message4)
        
        // Nil comparisons
        let messageWithNils = JSInboundMessage(callbackStub: nil, data: nil)
        let anotherMessageWithNils = JSInboundMessage(callbackStub: nil, data: nil)
        #expect(messageWithNils == anotherMessageWithNils)
    }
    
    // MARK: - Edge Cases
    
    @Test("Complex nested data")
    func testComplexNestedData() throws {
        let complexData: JSONValue = [
            "users": [
                ["id": 1, "name": "Alice"],
                ["id": 2, "name": "Bob"]
            ],
            "metadata": [
                "version": "1.0",
                "timestamp": 1234567890
            ]
        ]
        
        let message = JSInboundMessage(callbackStub: "complex_test", data: complexData)
        
        // Test encoding/decoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(message)
        
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(JSInboundMessage.self, from: encodedData)
        
        #expect(decodedMessage == message)
    }
    
    @Test("Empty string callback stub")
    func testEmptyStringCallbackStub() throws {
        let message = JSInboundMessage(callbackStub: "", data: .string("test"))
        
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(message)
        
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(JSInboundMessage.self, from: encodedData)
        
        #expect(decodedMessage.callbackStub == "")
        #expect(decodedMessage == message)
    }
}