import Foundation
import UIKit

/// Entity for configuring design of screen
public struct WebKitBridgeDesignConfiguration {
    public let animationDuration: Double

    public init(
        animationDuration: Double
    ) {
        self.animationDuration = animationDuration
    }
}

public struct WebKitBridgeModuleConfiguration {

    /// Configuration of webView design
    public let designConfiguration: WebKitBridgeDesignConfiguration

    /// URL for open
    public let linkURL: URL

    /// Entity for showing/hiding spinner while loading
    public let spinnerManagerType: WebKitBridgeSpinnerManager.Type?

    /// Events manager to handle income events.
    public let incomeEventsManager: WebKitBridgeIncomeEventsManager?

    /// Provider of custom views
    public let viewsProvider: WebKitBridgeViewsProvider?

    /// Service to handle reachability
    /// (if pass nil, reachability will not be handled)
    public let reachabilityService: WebKitBridgeReachabilityService?

    public init(
        designConfiguration: WebKitBridgeDesignConfiguration,
        linkURL: URL,
        spinnerManagerType: WebKitBridgeSpinnerManager.Type? = nil,
        incomeEventsManager: WebKitBridgeIncomeEventsManager? = nil,
        viewsProvider: WebKitBridgeViewsProvider? = nil,
        reachabilityService: WebKitBridgeReachabilityService? = nil
    ) {
        self.designConfiguration = designConfiguration
        self.linkURL = linkURL
        self.spinnerManagerType = spinnerManagerType
        self.incomeEventsManager = incomeEventsManager
        self.viewsProvider = viewsProvider
        self.reachabilityService = reachabilityService
    }

}
