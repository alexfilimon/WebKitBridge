import UIKit

public protocol WebKitBridgeViewsProvider {

    func createLoadingView() -> UIView?

    func createReachabilityView() -> UIView?

    func createErrorView() -> UIView?

}

public extension WebKitBridgeViewsProvider {
    func createLoadingView() -> UIView? {
        return nil
    }

    func createReachabilityView() -> UIView? {
        return nil
    }

    func createErrorView() -> UIView? {
        return nil
    }
}
