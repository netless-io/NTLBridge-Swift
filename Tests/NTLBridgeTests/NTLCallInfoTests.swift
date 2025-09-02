import Testing
@testable import NTLBridge
import Foundation

@Suite("NTLCallInfo Tests")
struct NTLCallInfoTests {
    
    // MARK: - Initialization Tests

    @Test("Nil test")
    func testNilValue() throws {
//        let callInfo = try NTLCallInfo(method: "testMethod", callbackId: 123, anyArrayData: [1, nil])
//        let data = callInfo.data.data(using: .utf8)!
//        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
//        let array = object as! [Any]
//        #expect(array.count == 2)
    }

    @Test("Basic initialization")
    func testBasicInitialization() {
        let callInfo = NTLCallInfo(method: "testMethod", callbackId: 123, data: "{\"key\":\"value\"}")
        
        #expect(callInfo.method == "testMethod")
        #expect(callInfo.callbackId == 123)
        #expect(callInfo.data == "{\"key\":\"value\"}")
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
    
        
    // MARK: - Edge Cases
    
        
        
        
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
}
