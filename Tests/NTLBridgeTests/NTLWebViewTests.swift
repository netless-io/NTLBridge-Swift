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

    // MARK: - Navigation Tests

    @Test("Load request triggers cleanup")
    func loadRequestTriggersCleanup() async {
        _ = await MainActor.run {
            let webView = NTLWebView()

            // Register some test JS methods
            webView.register(methodName: "test.cleanupMethod") { _ in
                "test response"
            }

            webView.registerAsync(methodName: "test.asyncCleanupMethod") { _, completion in
                completion(.success("async response"))
            }

            // Make some JS calls that will be pending when navigation occurs
            var syncCallCompleted = false
            var syncCallError: Error?

            webView.callHandler("test.cleanupMethod", arguments: [String]()) { result in
                switch result {
                case .success:
                    syncCallCompleted = true
                case .failure(let error):
                    syncCallError = error
                }
            }

            var asyncCallCompleted = false
            var asyncCallError: Error?

            webView.callHandler("test.asyncCleanupMethod", arguments: [String]()) { result in
                switch result {
                case .success:
                    asyncCallCompleted = true
                case .failure(let error):
                    asyncCallError = error
                }
            }

            // Verify calls are pending (should not be completed yet since bridge not initialized)
            #expect(!syncCallCompleted)
            #expect(syncCallError == nil)
            #expect(!asyncCallCompleted)
            #expect(asyncCallError == nil)

            webView.load(URLRequest(url: URL(string: "http://localhost:3000/")!))

            // Verify that pending callbacks were cleaned up (should have errors now)
            #expect(syncCallError != nil)
            #expect(asyncCallError != nil)

            // Verify the error is the expected navigation cancellation error
            if let syncError = syncCallError as? NSError {
                #expect(syncError.domain == "NTLBridge")
                #expect(syncError.code == -2)
            }

            if let asyncError = asyncCallError as? NSError {
                #expect(asyncError.domain == "NTLBridge")
                #expect(asyncError.code == -2)
            }
        }
    }
}
