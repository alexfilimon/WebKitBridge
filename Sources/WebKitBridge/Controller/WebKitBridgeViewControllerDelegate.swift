/// Delegate for WevKitBridge. May be used for analytics
public protocol WebKitBridgeViewControllerDelegate: AnyObject {
    func viewWillDisappear(_ animated: Bool)
    func viewWillAppear(_ animated: Bool)
    func didFinishLoadingLink()
}
