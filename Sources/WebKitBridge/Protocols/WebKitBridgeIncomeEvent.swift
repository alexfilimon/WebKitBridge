import UIKit

public struct WebKitBridgeIncomeEventFireContext {
    public let controller: WebKitBridgeOutcomeEventRunnable & UIViewController
}

/// Protocol for working with income events (bridge <- WebView)
public protocol WebKitBridgeIncomeEvent {

    /// Название события
    var name: String { get }

    /// Параметры события.
    /// Ключ - название параметра (используется при парсинге).
    /// Значение - значение, которое будет передаваться из JS (константа или переменная).
    /// Примеры:
    /// - 'url': params.url
    /// - 'presentType': params.presentType,
    /// - 'title': params.title || null
    var params: [String: String] { get }

    /// Fired when evenc occured in WebView
    func fire(
        params: [String: Any],
        context: WebKitBridgeIncomeEventFireContext
    )

}
