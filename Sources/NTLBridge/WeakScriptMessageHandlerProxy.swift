import Foundation
import WebKit

/// 弱引用代理，用于打破WKUserContentController与目标对象之间的循环引用
final class WeakScriptMessageHandlerProxy: NSObject, WKScriptMessageHandler {
    private weak var target: WKScriptMessageHandler?
    
    init(target: WKScriptMessageHandler) {
        self.target = target
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}