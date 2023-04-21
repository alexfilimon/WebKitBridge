/// Protocol for running custom events in WekKit bridge controller
public protocol WebKitBridgeOutcomeEventRunnable: AnyObject {
    func run(outcomeEvent: WebKitBridgeOutcomeEvent)
}
