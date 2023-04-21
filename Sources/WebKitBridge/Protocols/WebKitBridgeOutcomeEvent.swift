/// Protocol for working with outcome events (bridge -> WebView)
public protocol WebKitBridgeOutcomeEvent {

    func getScript() -> String?

}
