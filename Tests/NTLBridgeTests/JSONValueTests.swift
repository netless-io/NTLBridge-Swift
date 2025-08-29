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
    
    // MARK: - Codable Integration Tests
    
    @Test("JSONValue from Codable struct")
    func testJSONValueFromCodableStruct() throws {
        struct User: Codable, Equatable {
            let id: Int
            let name: String
            let isActive: Bool
        }
        
        let user = User(id: 1, name: "Alice", isActive: true)
        let jsonValue = JSONValue(encodable: user)
        
        #expect(jsonValue.isDictionary == true)
        #expect(jsonValue.dictionaryValue?["id"] == .number(1))
        #expect(jsonValue.dictionaryValue?["name"] == .string("Alice"))
        #expect(jsonValue.dictionaryValue?["isActive"] == .bool(true))
    }
    
    @Test("JSONValue from Codable class")
    func testJSONValueFromCodableClass() throws {
        class Product: Codable, Equatable {
            let sku: String
            let price: Double
            let inStock: Bool
            
            init(sku: String, price: Double, inStock: Bool) {
                self.sku = sku
                self.price = price
                self.inStock = inStock
            }
            
            static func == (lhs: Product, rhs: Product) -> Bool {
                return lhs.sku == rhs.sku && lhs.price == rhs.price && lhs.inStock == rhs.inStock
            }
        }
        
        let product = Product(sku: "PRD-001", price: 29.99, inStock: true)
        let jsonValue = JSONValue(encodable: product)
        
        #expect(jsonValue.isDictionary == true)
        #expect(jsonValue.dictionaryValue?["sku"] == .string("PRD-001"))
        #expect(jsonValue.dictionaryValue?["price"] == .number(29.99))
        #expect(jsonValue.dictionaryValue?["inStock"] == .bool(true))
    }
    
    @Test("JSONValue from Codable enum")
    func testJSONValueFromCodableEnum() throws {
        enum Status: String, Codable {
            case active
            case inactive
            case pending
        }
        
        let status = Status.active
        let jsonValue = JSONValue(encodable: status)
        
        #expect(jsonValue.isString == true)
        #expect(jsonValue.stringValue == "active")
    }
    
    @Test("JSONValue from Codable array")
    func testJSONValueFromCodableArray() throws {
        struct Item: Codable {
            let name: String
            let quantity: Int
        }
        
        let items = [Item(name: "Apple", quantity: 5), Item(name: "Banana", quantity: 3)]
        let jsonValue = JSONValue(encodable: items)
        
        #expect(jsonValue.isArray == true)
        #expect(jsonValue.arrayValue?.count == 2)
        #expect(jsonValue.arrayValue?[0].dictionaryValue?["name"] == .string("Apple"))
        #expect(jsonValue.arrayValue?[0].dictionaryValue?["quantity"] == .number(5))
        #expect(jsonValue.arrayValue?[1].dictionaryValue?["name"] == .string("Banana"))
        #expect(jsonValue.arrayValue?[1].dictionaryValue?["quantity"] == .number(3))
    }
    
    @Test("JSONValue from Codable dictionary")
    func testJSONValueFromCodableDictionary() throws {
        let metadata: [String: String] = [
            "version": "1.0.0",
            "author": "Developer",
            "license": "MIT"
        ]
        
        let jsonValue = JSONValue(encodable: metadata)
        
        #expect(jsonValue.isDictionary == true)
        #expect(jsonValue.dictionaryValue?["version"] == .string("1.0.0"))
        #expect(jsonValue.dictionaryValue?["author"] == .string("Developer"))
        #expect(jsonValue.dictionaryValue?["license"] == .string("MIT"))
    }
    
    @Test("JSONValue from nested Codable structure")
    func testJSONValueFromNestedCodableStructure() throws {
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
        
        let jsonValue = JSONValue(encodable: person)
        
        #expect(jsonValue.isDictionary == true)
        #expect(jsonValue.dictionaryValue?["name"] == .string("Bob"))
        #expect(jsonValue.dictionaryValue?["age"] == .number(30))
        
        let address = jsonValue.dictionaryValue?["address"]?.dictionaryValue
        #expect(address?["street"] == .string("123 Main St"))
        #expect(address?["city"] == .string("New York"))
        #expect(address?["zipCode"] == .string("10001"))
        
        let hobbies = jsonValue.dictionaryValue?["hobbies"]?.arrayValue
        #expect(hobbies?.count == 3)
        #expect(hobbies?[0] == .string("reading"))
        #expect(hobbies?[1] == .string("swimming"))
        #expect(hobbies?[2] == .string("coding"))
    }
    
    @Test("JSONValue from optional Codable")
    func testJSONValueFromOptionalCodable() throws {
        struct Config: Codable {
            let apiKey: String?
            let debugMode: Bool?
        }
        
        let configWithValues = Config(apiKey: "secret-key", debugMode: true)
        let configWithNil = Config(apiKey: nil, debugMode: nil)
        
        let jsonValue1 = JSONValue(encodable: configWithValues)
        let jsonValue2 = JSONValue(encodable: configWithNil)
        
        #expect(jsonValue1.dictionaryValue?["apiKey"] == .string("secret-key"))
        #expect(jsonValue1.dictionaryValue?["debugMode"] == .bool(true))
        
        // Note: Default JSON encoder omits nil values, so these keys won't be present
        #expect(jsonValue2.dictionaryValue?["apiKey"] == nil)
        #expect(jsonValue2.dictionaryValue?["debugMode"] == nil)
    }
    
    @Test("JSONValue from Codable with custom coding keys")
    func testJSONValueFromCodableWithCustomCodingKeys() throws {
        struct User: Codable {
            let userId: Int
            let fullName: String
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case fullName = "full_name"
            }
        }
        
        let user = User(userId: 123, fullName: "John Doe")
        let jsonValue = JSONValue(encodable: user)
        
        #expect(jsonValue.isDictionary == true)
        #expect(jsonValue.dictionaryValue?["user_id"] == .number(123))
        #expect(jsonValue.dictionaryValue?["full_name"] == .string("John Doe"))
        #expect(jsonValue.dictionaryValue?["userId"] == nil)
        #expect(jsonValue.dictionaryValue?["fullName"] == nil)
    }
    
    @Test("JSONValue from Codable with dates")
    func testJSONValueFromCodableWithDates() throws {
        struct Event: Codable {
            let name: String
            let date: Date
        }
        
        let date = Date(timeIntervalSince1970: 1234567890)
        let event = Event(name: "Conference", date: date)
        let jsonValue = JSONValue(encodable: event)
        
        #expect(jsonValue.isDictionary == true)
        #expect(jsonValue.dictionaryValue?["name"] == .string("Conference"))
        #expect(jsonValue.dictionaryValue?["date"]?.isNumber == true)
        
        // Verify the date is properly encoded as timestamp (default strategy)
        let timestamp = jsonValue.dictionaryValue?["date"]?.numberValue
        #expect(timestamp != nil)
    }
    
    @Test("JSONValue from Codable with data")
    func testJSONValueFromCodableWithData() throws {
        struct File: Codable {
            let name: String
            let content: Data
        }
        
        let content = "Hello, World!".data(using: .utf8)!
        let file = File(name: "greeting.txt", content: content)
        let jsonValue = JSONValue(encodable: file)
        
        #expect(jsonValue.isDictionary == true)
        #expect(jsonValue.dictionaryValue?["name"] == .string("greeting.txt"))
        #expect(jsonValue.dictionaryValue?["content"]?.isString == true)
        
        // Verify the data is properly encoded as base64 string
        let base64String = jsonValue.dictionaryValue?["content"]?.stringValue
        #expect(base64String != nil)
    }
}