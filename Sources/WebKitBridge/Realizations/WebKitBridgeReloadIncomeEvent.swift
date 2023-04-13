/// Predefined event for reloading all existing pages
public final class WebKitBridgeReloadIncomeEvent: WebKitBridgeIncomeEvent {

    public var name = "needReloadAllWebviews"

    public var params: [String: String] = [:]

    public init() {}

    public func fire(
        params: [String : Any],
        context: WebKitBridgeIncomeEventFireContext
    ) {
        AllPageReloaderManager
            .shared
            .setNeedsReloadAllPages(
                except: context.controller as? AllPageReloaderManagerDelegate
            )
    }

}
