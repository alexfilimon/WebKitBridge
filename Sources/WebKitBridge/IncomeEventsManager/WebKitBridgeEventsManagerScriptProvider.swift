public protocol WebKitBridgeIncomeEventsManagerScriptProvider {
    func getScript(
        eventName: String,
        additionalParams: [String: String],
        observerName: String
    ) -> String
}

open class NativeJSScriptsProvider: WebKitBridgeIncomeEventsManagerScriptProvider {

    public init() {}

    open func getScript(
        eventName: String,
        additionalParams: [String: String],
        observerName: String
    ) -> String {
        let start = """
            document.addEventListener('\(eventName)', function(event, params) {
                window.webkit.messageHandlers.\(observerName).postMessage({
        """
        var params: [String] = []
        for additionalParam in additionalParams {
            params.append("'\(additionalParam.key)': \(additionalParam.value)")
        }
        let paramsString = params.joined(separator: ",\n")
        let end = """
                });
            })
        """

        let final = start + paramsString + end
        return final
    }

}
