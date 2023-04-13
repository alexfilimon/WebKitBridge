public protocol WebKitBridgeIncomeEventsManagerScriptProvider {
    func getScript(
        eventName: String,
        additionalParams: [String: String],
        observerName: String
    ) -> String
}
