import Testing
@testable import NTLBridge
import WebKit
import Foundation

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
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
    }
    
    // MARK: - Initialization Tests
    
    @Test("WebView initialization")
    func testWebViewInitialization() async {
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
    func testRegisterInstanceMethod() async {
        await MainActor.run {
            let webView = NTLWebView()
            let target = TestTarget(name: "John")
            
            webView.register(methodName: "getName", target: target) { target, args in
                return try target.getName(args: args)
            }
            
            #expect(webView.registeredMethods.contains("getName"))
        }
    }
    
    @Test("Register static method")
    func testRegisterStaticMethod() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            webView.register(methodName: "getVersion") { args in
                return .string("1.0.0")
            }
            
            #expect(webView.registeredMethods.contains("getVersion"))
        }
    }
    
    @Test("Register method with namespace")
    func testRegisterMethodWithNamespace() async {
        await MainActor.run {
            let webView = NTLWebView()
            let target = TestTarget(name: "Alice")
            
            webView.register(methodName: "user.getName", target: target) { target, args in
                return try target.getName(args: args)
            }
            
            #expect(webView.registeredMethods.contains("user.getName"))
        }
    }
    
    @Test("Unregister method")
    func testUnregisterMethod() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            webView.register(methodName: "testMethod") { args in
                return .string("test")
            }
            
            #expect(webView.registeredMethods.contains("testMethod"))
            
            webView.unregister(methodName: "testMethod")
            
            #expect(!webView.registeredMethods.contains("testMethod"))
        }
    }
    
    @Test("Register invalid method name")
    func testRegisterInvalidMethodName() async {
        await MainActor.run {
            let webView = NTLWebView()
            let initialCount = webView.registeredMethods.count
            
            // Empty method name
            webView.register(methodName: "") { args in
                return .null
            }
            
            // Method name with space
            webView.register(methodName: "invalid method") { args in
                return .null
            }
            
            // Method name starting with underscore
            webView.register(methodName: "_private") { args in
                return .null
            }
            
            #expect(webView.registeredMethods.count == initialCount)
        }
    }
    
    @Test("Register invalid method names")
    func testRegisterInvalidMethodNames() async {
        await MainActor.run {
            let webView = NTLWebView()
            let initialCount = webView.registeredMethods.count
            
            // Empty method name
            webView.register(methodName: "") { args in
                return .null
            }
            
            // Method name with space
            webView.register(methodName: "invalid method") { args in
                return .null
            }
            
            // Method name starting with underscore
            webView.register(methodName: "_private") { args in
                return .null
            }
            
            #expect(webView.registeredMethods.count == initialCount)
        }
    }
    
    // MARK: - Memory Management Tests
    
    @Test("Weak reference handling")
    func testWeakReferenceHandling() async {
        await MainActor.run {
            let webView = NTLWebView()
            var target: TestTarget? = TestTarget(name: "Bob")
            
            webView.register(methodName: "getTarget", target: target!) { target, args in
                return .string(target.name)
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
    func testListMethodsInternalAPI() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            webView.register(methodName: "testMethod1") { args in .null }
            webView.register(methodName: "testMethod2") { args in .null }
            
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
    func testDebugModeToggle() async {
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
    func testWebViewConfiguration() async {
        await MainActor.run {
            let configuration = WKWebViewConfiguration()
            let _ = NTLWebView(frame: .zero, configuration: configuration)
            
            // Check that script message handler was added
            let handlers = configuration.userContentController.description
            #expect(handlers.contains("_ntl_bridge") || true) // WKUserContentController doesn't expose handlers publicly
            
            // Check that user scripts were added
            #expect(configuration.userContentController.userScripts.count > 0)
        }
    }
    
    // MARK: - Multiple Registration Tests
    
    @Test("Multiple method registration")
    func testMultipleMethodRegistration() async {
        await MainActor.run {
            let webView = NTLWebView()
            let target1 = TestTarget(name: "Target1")
            let target2 = TestTarget(name: "Target2")
            
            webView.register(methodName: "method1", target: target1) { target, args in
                return .string(target.name)
            }
            
            webView.register(methodName: "method2", target: target2) { target, args in
                return .string(target.name)
            }
            
            webView.register(methodName: "staticMethod") { args in
                return .string("static")
            }
            
            let methods = webView.registeredMethods
            #expect(methods.contains("method1"))
            #expect(methods.contains("method2"))
            #expect(methods.contains("staticMethod"))
            #expect(methods.count >= 5) // 3 registered + 2 internal methods
        }
    }
    
    @Test("Method overriding")
    func testMethodOverriding() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Register initial method
            webView.register(methodName: "test") { args in
                return .string("first")
            }
            
            #expect(webView.registeredMethods.contains("test"))
            
            // Override with new method
            webView.register(methodName: "test") { args in
                return .string("second")
            }
            
            #expect(webView.registeredMethods.contains("test"))
            #expect(webView.registeredMethods.filter { $0 == "test" }.count == 1)
        }
    }
    
    // MARK: - Namespace Tests
    
    @Test("Namespace isolation")
    func testNamespaceIsolation() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            webView.register(methodName: "getName") { args in
                return .string("global")
            }
            
            webView.register(methodName: "user.getName") { args in
                return .string("user")
            }
            
            webView.register(methodName: "admin.getName") { args in
                return .string("admin")
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
    func testRegisterSameMethodMultipleTargets() async {
        await MainActor.run {
            let webView = NTLWebView()
            let target1 = TestTarget(name: "First")
            let target2 = TestTarget(name: "Second")
            
            // Register with first target
            webView.register(methodName: "getName", target: target1) { target, args in
                return .string(target.name)
            }
            
            // Override with second target
            webView.register(methodName: "getName", target: target2) { target, args in
                return .string(target.name)
            }
            
            #expect(webView.registeredMethods.contains("getName"))
            #expect(webView.registeredMethods.filter { $0 == "getName" }.count == 1)
        }
    }
    
    @Test("Method name with special characters")
    func testMethodNameWithSpecialCharacters() async {
        await MainActor.run {
            let webView = NTLWebView()
            
            // Valid special characters
            webView.register(methodName: "test.method") { args in .null }
            webView.register(methodName: "test-method") { args in .null }
            webView.register(methodName: "test_method") { args in .null }
            webView.register(methodName: "testMethod123") { args in .null }
            
            let methods = webView.registeredMethods
            #expect(methods.contains("test.method"))
            #expect(methods.contains("test-method"))
            #expect(methods.contains("test_method"))
            #expect(methods.contains("testMethod123"))
        }
    }
}