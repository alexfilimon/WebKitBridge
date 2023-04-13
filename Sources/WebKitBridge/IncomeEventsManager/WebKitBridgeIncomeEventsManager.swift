import UIKit
import WebKit

public struct WebKitBridgeIncomeEventsManagerInitInfo {
    public let controller: WebKitBridgeOutcomeEventRunnable & UIViewController
    public let contentController: WKUserContentController
    public let onEventFired: (() -> Void)?

    public init(
        controller: WebKitBridgeOutcomeEventRunnable & UIViewController,
        contentController: WKUserContentController,
        onEventFired: (() -> Void)?
    ) {
        self.controller = controller
        self.contentController = contentController
        self.onEventFired = onEventFired
    }
}

/// Manager for working with income events
public protocol WebKitBridgeIncomeEventsManager {
    func initialize(
        info: WebKitBridgeIncomeEventsManagerInitInfo
    )
}

public extension WebKitBridgeIncomeEventsManager where Self == WebKitBridgeBaseIncomeEventsManager {
    static func base(
        events: [WebKitBridgeIncomeEvent],
        scriptProvider: WebKitBridgeIncomeEventsManagerScriptProvider
    ) -> WebKitBridgeBaseIncomeEventsManager {
        WebKitBridgeBaseIncomeEventsManager(
            events: events,
            scriptProvider: scriptProvider
        )
    }
}
