//
//  ContentView.swift
//  NTLBridgeDemo
//
//  Created by vince on 2025/8/18.
//

import SwiftUI
import WebKit
import NTLBridge
import Observation

@Observable
class Model {
    init() {
        let configuration = WKWebViewConfiguration()
        let webView = NTLWebView(frame: .init(x: 0, y: 0, width: 244, height: 244), configuration: configuration)
        webView.isDebugMode = true
        webView.isInspectable = true
        webView.load(.init(url: .init(string: "http://localhost:3000/")!))
        
        webView.register(methodName: "testSyn") { args in
            print("get testSyn arg", args)
            return .init("testSyn Hello from Swift!")
        }
        webView.register(methodName: "testNoArgSyn") { param in
            print("get testNoArgSyn arg", param)
            return .init(any: "testNoArgSyn No argument received")
        }
        webView.registerAsync(methodName: "testNoArgAsyn") { param, callback in
            callback(.success("testNoArgAsyn oh no param"))
        }
        webView.registerAsync(methodName: "testAsyn") { param, callback in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                callback(.success("testAsyn result from swift"))
            }
        }
        webView.register(methodName: "echo.syn") { param in
            return .init(any: "Echo \(param.stringValue ?? "")")
        }
        webView.registerAsync(methodName: "echo.asyn") { param, callback in
            callback(.success(.string("Echo asyn \(param.stringValue ?? "")")))
        }
        self.webView = webView
    }
    let webView: NTLWebView
    
    var jsResult: String?
}

struct ContentView: View {
    let model: Model = Model()
    
    var body: some View {
        VStack {
            HStack {
                Text("JS Result")
                Text(model.jsResult ?? "No result yet")
            }
            Button("Call js sync") {
                model.webView.callBridge(method: "syn.tag") { r in
                    switch r {
                    case .success(let value):
                        model.jsResult = value.debugDescription
                    case .failure:
                        return
                    }
                }
            }
            Button("Call js sync multiparam") {
                model.webView.callBridge(method: "syn.multi", args: [.string("1"), .array([.number(111)])]) { r in
                    switch r {
                    case .success(let value):
                        model.jsResult = value.debugDescription
                    case .failure:
                        return
                    }
                }
            }
            Button("Call js async") {
                model.webView.callBridge(method: "asyn.tag", args: [.string("AAA")]) { r in
                    switch r {
                    case .success(let value):
                        model.jsResult = value.debugDescription
                    case .failure:
                        return
                    }
                }
            }
            Button("Call js async multiParam") {
                model.webView.callBridge(method: "asyn.multiParam", args: [.string("BBB"), .dictionary(["ppp": "ttt"])]) { r in
                    switch r {
                    case .success(let value):
                        model.jsResult = value.debugDescription
                    case .failure:
                        return
                    }
                }
            }
        }
        
        WebViewWrapper(webView: model.webView)
    }
}

#Preview {
    ContentView()
}


public struct WebViewWrapper: UIViewRepresentable {
    let webView: NTLWebView
    init(webView: NTLWebView) {
        self.webView = webView
    }
    
    public func makeUIView(context: Context) -> NTLWebView {
        return webView
    }
    
    public func updateUIView(_ uiView: NTLWebView, context: Context) {
        // 更新WebView配置
    }
}
