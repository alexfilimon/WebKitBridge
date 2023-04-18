import WebKit

private class IncomeEventObserver: NSObject, WKScriptMessageHandler {

    private let event: WebKitBridgeIncomeEvent
    private weak var controller: (UIViewController & WebKitBridgeOutcomeEventRunnable)?
    let id: String
    let onEventFired: () -> Void

    init(
        event: WebKitBridgeIncomeEvent,
        controller: UIViewController & WebKitBridgeOutcomeEventRunnable,
        onEventFired: @escaping () -> Void
    ) {
        self.id = "_" + UUID().uuidString.replacingOccurrences(of: "-", with: "_")
        self.event = event
        self.controller = controller
        self.onEventFired = onEventFired
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        let bodyParams = (message.body as? [String: Any]) ?? [:]
        guard let controller else {
            assertionFailure("Controller must exist - controller deallocated or not configured")
            return
        }
        onEventFired()
        event.fire(
            params: bodyParams,
            context: .init(
                controller: controller
            )
        )
    }

}

/// Base класс для работы с событиями
open class WebKitBridgeBaseIncomeEventsManager: WebKitBridgeIncomeEventsManager {

    // MARK: - Constants

    public enum Constants {
        public static let eventNameKey = "eventName"
    }

    // MARK: - Public Properties

    private let events: [WebKitBridgeIncomeEvent]
    private let scriptProvider: WebKitBridgeIncomeEventsManagerScriptProvider

    private var observers: [IncomeEventObserver] = []

    // MARK: - Initialization

    public init(
        events: [WebKitBridgeIncomeEvent],
        scriptProvider: WebKitBridgeIncomeEventsManagerScriptProvider
    ) {
        self.events = events
        self.scriptProvider = scriptProvider
    }

    // MARK: - WebKitBridgeEventManager

    public func initialize(info: WebKitBridgeIncomeEventsManagerInitInfo) {
        self.observers = events.map {
            /// Если это не сделать, то контроллер будет утекать, т.к. info будет жить
            let onEventFired = info.onEventFired
            let observer = IncomeEventObserver(
                event: $0,
                controller: info.controller,
                onEventFired: {
                    onEventFired?()
                }
            )

            // добавляем обзервера - тот, кто будет реагировать на event из WebView
            info.contentController.add(observer, name: observer.id)

            // добавляем код для обзервинга в JS
            let source = scriptProvider.getScript(
                eventName: $0.name,
                additionalParams: $0.params,
                observerName: observer.id
            )
            let script = WKUserScript(
                source: source,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            )
            info.contentController.addUserScript(script)

            return observer
        }

    }

}
