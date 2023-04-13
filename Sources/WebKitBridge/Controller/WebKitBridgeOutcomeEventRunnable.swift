/// Protocol for running custom events in WekKit bridge controller
public protocol WebKitBridgeOutcomeEventRunnable {
    func run(outcomeEvent: WebKitBridgeOutcomeEvent)
}
