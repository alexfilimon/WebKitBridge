import UIKit

// TODO: add controls view
public protocol WebKitBridgeViewsProvider {

    func createLoadingView() -> UIView?

    func createReachabilityView() -> UIView?

}

public extension WebKitBridgeViewsProvider {
    func createLoadingView() -> UIView? {
        return nil
    }

    func createReachabilityView() -> UIView? {
        return nil
    }
}
