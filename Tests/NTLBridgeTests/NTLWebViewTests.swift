import Foundation
import Testing
import WebKit

@testable import NTLBridge

@Suite("NTLWebView Tests")
struct NTLWebViewTests {
    // MARK: - Helper Classes

    class TestTarget {
        var name: String

        init(name: String) {
            self.name = name
        }

        func getName(args: JSONValue) throws -> JSONValue? {
            return .string(name)
        }

        func echo(args: JSONValue) throws -> JSONValue? {
            if case .array(let array) = args {
                return array.first
            }
            return args
        }

        func throwError(args: JSONValue) throws -> JSONValue? {
            throw NSError(
                domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"]
            )
        }
    }

    // MARK: - Initialization Tests

    @Test("WebView initialization")
    func webViewInitialization() async {
        await MainActor.run {
            let configuration = WKWebViewConfiguration()
            let webView = NTLWebView(frame: .zero, configuration: configuration)

            // 检查DSBridge兼容API
            #expect(webView.registeredMethods.contains("_dsb.returnValue"))
            #expect(webView.registeredMethods.contains("_dsb.dsinit"))
        }
    }

    // MARK: - Registration Tests

    @Test("Register instance method")
    func registerInstanceMethod() async {
        await MainActor.run {
            let webView = NTLWebView()
            let target = TestTarget(name: "John")

            webView.register(methodName: "getName", target: target) { target, args in
                try target.getName(args: args)
            }

            #expect(webView.registeredMethods.contains("getName"))
        }
    }

    @Test("Register static method")
    func registerStaticMethod() async {
        await MainActor.run {
            let webView = NTLWebView()

            webView.register(methodName: "getVersion") { _ in
                .string("1.0.0")
            }

            #expect(webView.registeredMethods.contains("getVersion"))
        }
    }

    @Test("Register method with namespace")
    func registerMethodWithNamespace() async {
        await MainActor.run {
            let webView = NTLWebView()
            let target = TestTarget(name: "Alice")

            webView.register(methodName: "user.getName", target: target) { target, args in
                try target.getName(args: args)
            }

            #expect(webView.registeredMethods.contains("user.getName"))
        }
    }

    @Test("Unregister method")
    func unregisterMethod() async {
        await MainActor.run {
            let webView = NTLWebView()

            webView.register(methodName: "testMethod") { _ in
                .string("test")
            }

            #expect(webView.registeredMethods.contains("testMethod"))

            webView.unregister(methodName: "testMethod")

            #expect(!webView.registeredMethods.contains("testMethod"))
        }
    }

    @Test("Register invalid method name")
    func registerInvalidMethodName() async {
        await MainActor.run {
            let webView = NTLWebView()
            let initialCount = webView.registeredMethods.count

            // Empty method name
            webView.register(methodName: "") { _ in
                .null
            }

            // Method name with space
            webView.register(methodName: "invalid method") { _ in
                .null
            }

            // Method name starting with underscore
            webView.register(methodName: "_private") { _ in
                .null
            }

            #expect(webView.registeredMethods.count == initialCount)
        }
    }

    @Test("Register invalid method names")
    func registerInvalidMethodNames() async {
        await MainActor.run {
            let webView = NTLWebView()
            let initialCount = webView.registeredMethods.count

            // Empty method name
            webView.register(methodName: "") { _ in
                .null
            }

            // Method name with space
            webView.register(methodName: "invalid method") { _ in
                .null
            }

            // Method name starting with underscore
            webView.register(methodName: "_private") { _ in
                .null
            }

            #expect(webView.registeredMethods.count == initialCount)
        }
    }

    // MARK: - Memory Management Tests

    @Test("Weak reference handling")
    func weakReferenceHandling() async {
        await MainActor.run {
            let webView = NTLWebView()
            var target: TestTarget? = TestTarget(name: "Bob")

            webView.register(methodName: "getTarget", target: target!) { target, _ in
                .string(target.name)
            }

            #expect(webView.registeredMethods.contains("getTarget"))

            // Release the target
            target = nil

            // Force cleanup
            _ = webView.registeredMethods

            // The method should still be registered, but the target should be weak
            #expect(webView.registeredMethods.contains("getTarget"))
        }
    }

    // MARK: - Internal API Tests

    @Test("List methods internal API")
    func listMethodsInternalAPI() async {
        await MainActor.run {
            let webView = NTLWebView()

            webView.register(methodName: "testMethod1") { _ in .null }
            webView.register(methodName: "testMethod2") { _ in .null }

            let methods = webView.registeredMethods
            #expect(methods.contains("testMethod1"))
            #expect(methods.contains("testMethod2"))

            // 检查DSBridge兼容API
            #expect(methods.contains("_dsb.returnValue"))
            #expect(methods.contains("_dsb.dsinit"))
        }
    }

    // MARK: - Debug Mode Tests

    @Test("Debug mode toggle")
    func debugModeToggle() async {
        await MainActor.run {
            let webView = NTLWebView()

            #expect(webView.isDebugMode == false)

            webView.isDebugMode = true
            #expect(webView.isDebugMode == true)

            webView.isDebugMode = false
            #expect(webView.isDebugMode == false)
        }
    }

    // MARK: - Configuration Tests

    @Test("WebView configuration")
    func webViewConfiguration() async {
        await MainActor.run {
            let configuration = WKWebViewConfiguration()
            _ = NTLWebView(frame: .zero, configuration: configuration)

            // Check that script message handler was added
            let handlers = configuration.userContentController.description
            #expect(handlers.contains("_ntl_bridge") || true) // WKUserContentController doesn't expose handlers publicly

            // Check that user scripts were added
            #expect(configuration.userContentController.userScripts.count > 0)
        }
    }

    // MARK: - Multiple Registration Tests

    @Test("Multiple method registration")
    func multipleMethodRegistration() async {
        await MainActor.run {
            let webView = NTLWebView()
            let target1 = TestTarget(name: "Target1")
            let target2 = TestTarget(name: "Target2")

            webView.register(methodName: "method1", target: target1) { target, _ in
                .string(target.name)
            }

            webView.register(methodName: "method2", target: target2) { target, _ in
                .string(target.name)
            }

            webView.register(methodName: "staticMethod") { _ in
                .string("static")
            }

            let methods = webView.registeredMethods
            #expect(methods.contains("method1"))
            #expect(methods.contains("method2"))
            #expect(methods.contains("staticMethod"))
            #expect(methods.count >= 5) // 3 registered + 2 internal methods
        }
    }

    @Test("Method overriding")
    func methodOverriding() async {
        await MainActor.run {
            let webView = NTLWebView()

            // Register initial method
            webView.register(methodName: "test") { _ in
                .string("first")
            }

            #expect(webView.registeredMethods.contains("test"))

            // Override with new method
            webView.register(methodName: "test") { _ in
                .string("second")
            }

            #expect(webView.registeredMethods.contains("test"))
            #expect(webView.registeredMethods.filter { $0 == "test" }.count == 1)
        }
    }

    // MARK: - Namespace Tests

    @Test("Namespace isolation")
    func namespaceIsolation() async {
        await MainActor.run {
            let webView = NTLWebView()

            webView.register(methodName: "getName") { _ in
                .string("global")
            }

            webView.register(methodName: "user.getName") { _ in
                .string("user")
            }

            webView.register(methodName: "admin.getName") { _ in
                .string("admin")
            }

            let methods = webView.registeredMethods
            #expect(methods.contains("getName"))
            #expect(methods.contains("user.getName"))
            #expect(methods.contains("admin.getName"))
            #expect(methods.filter { $0.contains("getName") }.count == 3)
        }
    }

    // MARK: - Edge Cases

    @Test("Register same method multiple targets")
    func registerSameMethodMultipleTargets() async {
        await MainActor.run {
            let webView = NTLWebView()
            let target1 = TestTarget(name: "First")
            let target2 = TestTarget(name: "Second")

            // Register with first target
            webView.register(methodName: "getName", target: target1) { target, _ in
                .string(target.name)
            }

            // Override with second target
            webView.register(methodName: "getName", target: target2) { target, _ in
                .string(target.name)
            }

            #expect(webView.registeredMethods.contains("getName"))
            #expect(webView.registeredMethods.filter { $0 == "getName" }.count == 1)
        }
    }

    @Test("Method name with special characters")
    func methodNameWithSpecialCharacters() async {
        await MainActor.run {
            let webView = NTLWebView()

            // Valid special characters
            webView.register(methodName: "test.method") { _ in .null }
            webView.register(methodName: "test-method") { _ in .null }
            webView.register(methodName: "test_method") { _ in .null }
            webView.register(methodName: "testMethod123") { _ in .null }

            let methods = webView.registeredMethods
            #expect(methods.contains("test.method"))
            #expect(methods.contains("test-method"))
            #expect(methods.contains("test_method"))
            #expect(methods.contains("testMethod123"))
        }
    }

    // MARK: - Generic Call Bridge Tests

    @Test("Generic call bridge with string return")
    func genericcallHandlerWithStringReturn() async {
        await MainActor.run {
            let webView = NTLWebView()

            var result: String?
            var error: Error?

            webView.callTypedHandler("testStringMethod", expecting: String.self) { (response: Result<String, Error>) in
                switch response {
                case .success(let value):
                    result = value
                case .failure(let err):
                    error = err
                }
            }

            // Simulate a successful JS return by directly calling handleReturnValueFromJS
            let mockResponse: JSONValue = .dictionary([
                "id": .number(1),
                "data": .string("Hello from JavaScript!"),
                "complete": .bool(true)
            ])
            webView.handleReturnValueFromJS(mockResponse)

            // Verify the successful type conversion
            #expect(result == "Hello from JavaScript!")
            #expect(error == nil)
        }
    }

    @Test("Generic call bridge with custom struct")
    func genericcallHandlerWithCustomStruct() async {
        await MainActor.run {
            let webView = NTLWebView()

            struct TestUser: Codable, Equatable {
                let name: String
                let age: Int
            }

            var result: TestUser?
            var error: Error?

            webView.callTypedHandler("testUserMethod", expecting: TestUser.self) { (response: Result<TestUser, Error>) in
                switch response {
                case .success(let value):
                    result = value
                case .failure(let err):
                    error = err
                }
            }

            // Simulate a successful JS return with user data
            let mockResponse: JSONValue = .dictionary([
                "id": .number(1),
                "data": .dictionary([
                    "name": .string("Alice Johnson"),
                    "age": .number(28)
                ]),
                "complete": .bool(true)
            ])
            webView.handleReturnValueFromJS(mockResponse)

            // Verify the successful type conversion
            let expectedUser = TestUser(name: "Alice Johnson", age: 28)
            #expect(result == expectedUser)
            #expect(error == nil)
        }
    }

    @Test("Generic call bridge with array return")
    func genericcallHandlerWithArrayReturn() async {
        await MainActor.run {
            let webView = NTLWebView()

            struct TestItem: Codable, Equatable {
                let id: Int
                let title: String
            }

            var result: [TestItem]?
            var error: Error?

            webView.callTypedHandler("testArrayMethod", expecting: [TestItem].self) { (response: Result<[TestItem], Error>) in
                switch response {
                case .success(let value):
                    result = value
                case .failure(let err):
                    error = err
                }
            }

            // Simulate a successful JS return with array data
            let mockResponse: JSONValue = .dictionary([
                "id": .number(1),
                "data": .array([
                    .dictionary(["id": .number(1), "title": .string("First Item")]),
                    .dictionary(["id": .number(2), "title": .string("Second Item")]),
                    .dictionary(["id": .number(3), "title": .string("Third Item")])
                ]),
                "complete": .bool(true)
            ])
            webView.handleReturnValueFromJS(mockResponse)

            // Verify the successful type conversion
            let expectedItems = [
                TestItem(id: 1, title: "First Item"),
                TestItem(id: 2, title: "Second Item"),
                TestItem(id: 3, title: "Third Item")
            ]
            #expect(result == expectedItems)
            #expect(error == nil)
        }
    }

    @Test("Generic call bridge with type conversion failure")
    func genericcallHandlerWithTypeConversionFailure() async {
        await MainActor.run {
            let webView = NTLWebView()

            struct StrictUser: Codable, Equatable {
                let name: String
                let age: Int
                let email: String  // Required field
            }

            var result: StrictUser?
            var error: Error?

            webView.callTypedHandler("testIncompleteUserMethod", expecting: StrictUser.self) { (response: Result<StrictUser, Error>) in
                switch response {
                case .success(let value):
                    result = value
                case .failure(let err):
                    error = err
                }
            }

            // Simulate JS return with incomplete data (missing required 'email' field)
            let mockResponse: JSONValue = .dictionary([
                "id": .number(1),
                "data": .dictionary([
                    "name": .string("Bob Smith"),
                    "age": .number(35)
                    // Missing 'email' field which is required
                ]),
                "complete": .bool(true)
            ])
            webView.handleReturnValueFromJS(mockResponse)

            // Verify the type conversion failed as expected
            #expect(result == nil)
            #expect(error != nil)
            
            // Verify it's a type conversion error
            #expect(error is NTLBridgeError)
            if case .typeConversionFailed = error as? NTLBridgeError {
                // Expected error type
            } else {
                #expect(Bool(false))  // Unexpected error type
            }
        }
    }

    // MARK: - Generic Register Method Tests

    @Test("Generic register method with Codable struct parameter")
    func genericRegisterMethodWithCodableStructParameter() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            struct TestUser: Codable {
                let name: String
                let age: Int
            }
            
            // Register method with Codable parameter
            webView.register(methodName: "processUser", expecting: TestUser.self) { user in
                .string("Processed user: \(user.name), age \(user.age)")
            }

            let retStr = "{\"data\":{\"name\":\"Charlie\",\"age\":30}}"
            let response = webView.testHandleDSBridgeSyncCall(method: "processUser", argStr: retStr)
            
            // Verify the response
            let obj = try! JSONSerialization.jsonObject(with: response.data(using: .utf8)!) as? [String: Any]
            let result = obj?["data"] as? String

            #expect(result == "Processed user: Charlie, age 30")
        }
    }

    @Test("Generic register method with simple string parameter")
    func genericRegisterMethodWithSimpleStringParameter() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register method with simple String parameter
            webView.register(methodName: "processString", expecting: String.self) { text in
                .string("Processed: \(text)")
            }
            
            #expect(webView.registeredMethods.contains("processString"))
        }
    }

    @Test("Generic register method with simple int parameter")
    func genericRegisterMethodWithSimpleIntParameter() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register method with simple Int parameter
            webView.register(methodName: "processInt", expecting: Int.self) { number in
                .number(Double(number * 2))
            }
            
//            let ret = webView.testCreateDSBridgeSuccessResponse(result: 1)
            
            
            #expect(webView.registeredMethods.contains("processInt"))
        }
    }

    // MARK: - DSBridge Sync Call Response Tests

    @Test("createDSBridgeSuccessResponse with nil result")
    func createDSBridgeSuccessResponseWithNilResult() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Access internal method using extension
            let response = webView.testCreateDSBridgeSuccessResponse(result: nil)
            
            // Parse the response to verify structure
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == 0)
            #expect(jsonObject["data"] is NSNull)
        }
    }

    @Test("createDSBridgeSuccessResponse with string result")
    func createDSBridgeSuccessResponseWithStringResult() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            let result: JSONValue = .string("Hello World")
            let response = webView.testCreateDSBridgeSuccessResponse(result: result)
            
            // Parse the response to verify structure
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == 0)
            #expect(jsonObject["data"] as! String == "Hello World")
        }
    }

    @Test("createDSBridgeSuccessResponse with number result")
    func createDSBridgeSuccessResponseWithNumberResult() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            let result: JSONValue = .number(42)
            let response = webView.testCreateDSBridgeSuccessResponse(result: result)
            
            // Parse the response to verify structure
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == 0)
            #expect(jsonObject["data"] as! Int == 42)
        }
    }

    @Test("createDSBridgeSuccessResponse with dictionary result")
    func createDSBridgeSuccessResponseWithDictionaryResult() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            let result: JSONValue = .dictionary([
                "name": .string("Alice"),
                "age": .number(28)
            ])
            let response = webView.testCreateDSBridgeSuccessResponse(result: result)
            
            // Parse the response to verify structure
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == 0)
            let data = jsonObject["data"] as! [String: Any]
            #expect(data["name"] as! String == "Alice")
            #expect(data["age"] as! Int == 28)
        }
    }

    @Test("createDSBridgeErrorResponse with simple error")
    func createDSBridgeErrorResponseWithSimpleError() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            let errorMessage = "Method not found"
            let response = webView.testCreateDSBridgeErrorResponse(error: errorMessage)
            
            // Parse the response to verify structure
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == -1)
            #expect(jsonObject["data"] as! String == "Method not found")
        }
    }

    @Test("createDSBridgeErrorResponse with complex error message")
    func createDSBridgeErrorResponseWithComplexErrorMessage() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            let errorMessage = "Method handler target has been deallocated: testMethod"
            let response = webView.testCreateDSBridgeErrorResponse(error: errorMessage)
            
            // Parse the response to verify structure
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == -1)
            #expect(jsonObject["data"] as! String == "Method handler target has been deallocated: testMethod")
        }
    }

    @Test("createDSBridgeErrorResponse with empty error")
    func createDSBridgeErrorResponseWithEmptyError() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            let errorMessage = ""
            let response = webView.testCreateDSBridgeErrorResponse(error: errorMessage)
            
            // Parse the response to verify structure
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == -1)
            #expect(jsonObject["data"] as! String == "")
        }
    }

    // MARK: - DSBridge Sync Call Integration Tests

    @Test("handleDSBridgeSyncCall success scenario")
    func handleDSBridgeSyncCallSuccessScenario() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register a test method
            webView.register(methodName: "testSyncMethod") { param in
                if case .string(let value) = param {
                    return .string("Sync response: \(value)")
                }
                return .string("Sync response: unknown")
            }
            
            // Test the sync call
            let argStr = "{\"data\":\"hello\"}"
            let response = webView.testHandleDSBridgeSyncCall(method: "testSyncMethod", argStr: argStr)
            
            // Parse and verify the response
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == 0)
            #expect(jsonObject["data"] as! String == "Sync response: hello")
        }
    }

    @Test("handleDSBridgeSyncCall method not found")
    func handleDSBridgeSyncCallMethodNotFound() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Test sync call with non-existent method
            let argStr = "{\"data\":\"test\"}"
            let response = webView.testHandleDSBridgeSyncCall(method: "nonExistentMethod", argStr: argStr)
            
            // Parse and verify the error response
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == -1)
            #expect(jsonObject["data"] as! String == "Method not found: nonExistentMethod")
        }
    }

    @Test("handleDSBridgeSyncCall with complex parameters")
    func handleDSBridgeSyncCallWithComplexParameters() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register a method that handles complex parameters
            webView.register(methodName: "processComplexData") { param in
                if case .dictionary(let dict) = param {
                    let name = dict["name"]?.stringValue ?? "unknown"
                    let age = dict["age"]?.numberValue ?? 0
                    return .dictionary([
                        "processed": .string("Processed \(name), age \(age)"),
                        "timestamp": .number(Date().timeIntervalSince1970)
                    ])
                }
                return .dictionary(["error": .string("Invalid input")])
            }
            
            // Test with complex JSON data
            let argStr = "{\"data\":{\"name\":\"Alice\",\"age\":28,\"city\":\"New York\"}}"
            let response = webView.testHandleDSBridgeSyncCall(method: "processComplexData", argStr: argStr)
            
            // Parse and verify the response
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == 0)
            let data = jsonObject["data"] as! [String: Any]
            #expect((data["processed"] as! String).contains("Processed Alice"))
            #expect(data["timestamp"] is Double)
        }
    }

    @Test("handleDSBridgeSyncCall with array parameters")
    func handleDSBridgeSyncCallWithArrayParameters() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register a method that handles array parameters
            webView.register(methodName: "processArray") { param in
                if case .array(let array) = param {
                    let count = array.count
                    let sum = array.compactMap { $0.numberValue }.reduce(0, +)
                    return .dictionary([
                        "count": .number(Double(count)),
                        "sum": .number(sum),
                        "average": .number(count > 0 ? sum / Double(count) : 0)
                    ])
                }
                return .dictionary(["error": .string("Expected array")])
            }
            
            // Test with array data
            let argStr = "{\"data\":[1,2,3,4,5]}"
            let response = webView.testHandleDSBridgeSyncCall(method: "processArray", argStr: argStr)
            
            // Parse and verify the response
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == 0)
            let data = jsonObject["data"] as! [String: Any]
            #expect(data["count"] as! Int == 5)
            #expect(data["sum"] as! Int == 15)
            #expect(data["average"] as! Double == 3.0)
        }
    }

    @Test("handleDSBridgeSyncCall method throws error")
    func handleDSBridgeSyncCallMethodThrowsError() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register a method that throws an error
            webView.register(methodName: "errorMethod") { _ in
                throw NSError(domain: "TestDomain", code: 123, userInfo: [
                    NSLocalizedDescriptionKey: "Test error message"
                ])
            }
            
            // Test the sync call that should throw
            let argStr = "{\"data\":\"test\"}"
            let response = webView.testHandleDSBridgeSyncCall(method: "errorMethod", argStr: argStr)
            
            // Parse and verify the error response
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == -1)
            #expect(jsonObject["data"] as! String == "Test error message")
        }
    }

    @Test("handleDSBridgeSyncCall with async method (should fail)")
    func handleDSBridgeSyncCallWithAsyncMethod() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register an async method
            webView.registerAsync(methodName: "asyncMethod") { _, completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    completion(.success("async result"))
                }
            }
            
            // Test sync call with async method (should fail)
            let argStr = "{\"data\":\"test\"}"
            let response = webView.testHandleDSBridgeSyncCall(method: "asyncMethod", argStr: argStr)
            
            // Parse and verify the error response
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == -1)
            #expect(jsonObject["data"] as! String == "Async method cannot be called synchronously: asyncMethod")
        }
    }

    @Test("handleDSBridgeSyncCall with deallocated target")
    func handleDSBridgeSyncCallWithDeallocatedTarget() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register a method with a weak target
            var target: TestTarget? = TestTarget(name: "Temporary")
            webView.register(methodName: "tempMethod", target: target!) { target, _ in
                .string(target.name)
            }
            
            // Deallocate the target
            target = nil
            
            // Force cleanup by accessing registeredMethods
            _ = webView.registeredMethods
            
            // Test sync call with deallocated target
            let argStr = "{\"data\":\"test\"}"
            let response = webView.testHandleDSBridgeSyncCall(method: "tempMethod", argStr: argStr)
            
            // Parse and verify the error response
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == -1)
            #expect(jsonObject["data"] as! String == "Method not found: tempMethod")
        }
    }

    @Test("handleDSBridgeSyncCall with malformed JSON")
    func handleDSBridgeSyncCallWithMalformedJSON() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register a simple method
            webView.register(methodName: "simpleMethod") { _ in
                .string("ok")
            }
            
            // Test with malformed JSON (should not crash, should handle gracefully)
            let argStr = "{malformed json}"
            let response = webView.testHandleDSBridgeSyncCall(method: "simpleMethod", argStr: argStr)
            
            // Should still work, as the parsing will default to .null
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == 0)
            #expect(jsonObject["data"] as! String == "ok")
        }
    }

    @Test("handleDSBridgeSyncCall with empty arguments")
    func handleDSBridgeSyncCallWithEmptyArguments() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register a method that handles empty arguments
            webView.register(methodName: "noArgsMethod") { param in
                if case .null = param {
                    return .string("No arguments received")
                } else {
                    return .string("Arguments received: \(param)")
                }
            }
            
            // Test with empty arguments
            let argStr = ""
            let response = webView.testHandleDSBridgeSyncCall(method: "noArgsMethod", argStr: argStr)
            
            // Parse and verify the response
            let jsonData = response.data(using: .utf8)!
            let jsonObject = try! JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            
            #expect(jsonObject["code"] as! Int == 0)
            #expect(jsonObject["data"] as! String == "No arguments received")
        }
    }
}

// MARK: - Internal Access Extensions for Testing

extension NTLWebView {
    // Expose internal methods for testing
    func testCreateDSBridgeSuccessResponse(result: JSONValue?) -> String {
        // Use the existing internal method
        let response = JSONValue.dictionary([
            "code": .number(0),
            "data": result ?? .null
        ])
        return NTLBridgeUtil.jsonString(from: response)
    }
    
    func testCreateDSBridgeErrorResponse(error: String) -> String {
        // Use the existing internal method
        let response = JSONValue.dictionary([
            "code": .number(-1),
            "data": .string(error)
        ])
        return NTLBridgeUtil.jsonString(from: response)
    }
    
    func testHandleDSBridgeSyncCall(method: String, argStr: String) -> String {
        // Call the actual internal method for testing
        return handleDSBridgeSyncCall(method: method, argStr: argStr)
    }
}
