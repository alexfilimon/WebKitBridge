protocol WebKitBridgeDOMLoadedDelegate {
    func _domContentLoaded()
}

class WebKitBridgeDOMLoadedIncomeEvent: WebKitBridgeIncomeEvent {

    static let staticName = "CustomDOMContentLoaded"

    var name: String {
        Self.staticName
    }
    let params: [String: String] = [:]

    func fire(params: [String: Any], context: WebKitBridgeIncomeEventFireContext) {
        (context.controller as? WebKitBridgeDOMLoadedDelegate)?._domContentLoaded()
    }

}
