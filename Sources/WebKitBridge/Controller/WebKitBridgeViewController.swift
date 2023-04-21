import UIKit
import WebKit
import Combine

open class WebKitBridgeViewController: UIViewController, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate, WKNavigationDelegate, AllPageReloaderManagerDelegate, WebKitBridgeOutcomeEventRunnable {

    // MARK: - Subviews

    public private(set) var webView: WKWebView?

    // MARK: - Properties

    public let configuration: WebKitBridgeModuleConfiguration
    public private(set) var spinnerManager: WebKitBridgeSpinnerManager?

    private var lastTapPosition: CGPoint = .zero
    private var cancellable = Set<AnyCancellable>()

    private var reachabilityView: UIView?
    private var loadingView: UIView?
    private var errorView: UIView?

    // MARK: - Initialization

    public init(configuration: WebKitBridgeModuleConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)

        spinnerManager = configuration.spinnerManagerType?.init(controller: self)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        webView?.configuration.userContentController.removeAllScriptMessageHandlers()
    }

    // MARK: - UIViewController

    open override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView?.frame = view.bounds
    }

    open override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        setUIDocumentMenuViewControllerSourceViewesIfNeeded(
            viewControllerToPresent
        )
        super.present(
            viewControllerToPresent,
            animated: flag,
            completion: completion
        )
    }

    // MARK: - WebKitBridgeIncomeEventRunnable

    open func run(outcomeEvent: WebKitBridgeOutcomeEvent) {
        guard let script = outcomeEvent.getScript() else { return }
        webView?.evaluateJavaScript(
            script,
            completionHandler: nil
        )
    }

    // MARK: - Methods to override

    open func getWebViewConfig() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        configuration.incomeEventsManager?.initialize(
            info: .init(
                controller: self,
                contentController: config.userContentController,
                onEventFired: { [weak self] in
                    guard let self = self else { return }
                    UIView.animate(withDuration: self.configuration.designConfiguration.animationDuration) {
                        self.view.layoutIfNeeded()
                    }
                }
            )
        )

        return config
    }

    open func reloadWebView() {
        if
            let reachability = configuration.reachabilityService,
            reachability.currentStatus == .noInternet
        {
            return
        }
        loadingView?.isHidden = false
        errorView?.isHidden = true
        spinnerManager?.showSpinner()
        webView?.reload()
    }

    // MARK: - Private methods

    private func setUIDocumentMenuViewControllerSourceViewesIfNeeded(
        _ viewControllerToPresent: UIViewController
    ) {
        if
            #available(iOS 13, *),
            viewControllerToPresent is UIDocumentMenuViewController,
            UIDevice.current.userInterfaceIdiom == .phone
        {
            viewControllerToPresent.popoverPresentationController?.delegate = self
        }
    }

    private func configureAppearance() {
        configureWebView()
        configureViewProvider()
        configureReachability()
        AllPageReloaderManager.shared.subscribe(delegate: self)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(webViewTapped(_:)))
        tapGestureRecognizer.delegate = self
        webView?.addGestureRecognizer(tapGestureRecognizer)

        // link will be loaded inside reachbility publisher
    }

    private func configureWebView() {
        webView = WKWebView(frame: .zero, configuration: getWebViewConfig())
        view.addSubview(webView!)
        view.sendSubviewToBack(webView!)
        webView?.navigationDelegate = self
        webView?.allowsBackForwardNavigationGestures = false
        webView?.scrollView.contentInsetAdjustmentBehavior = .always
        webView?.scrollView.showsHorizontalScrollIndicator = false
        webView?.scrollView.showsVerticalScrollIndicator = false
        
    }

    private func configureViewProvider() {
        loadingView = configuration.viewsProvider?.createLoadingView()
        if let loadingView {
            addSubviewAndConstraints(subview: loadingView)
        }

        reachabilityView = configuration.viewsProvider?.createReachabilityView()
        if let reachabilityView {
            addSubviewAndConstraints(subview: reachabilityView)
        }

        errorView = configuration.viewsProvider?.createErrorView()
        if let errorView {
            addSubviewAndConstraints(subview: errorView)
        }
    }

    private func addSubviewAndConstraints(subview: UIView) {
        view.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subview.topAnchor.constraint(equalTo: view.topAnchor),
            subview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureReachability() {
        if let reachabilityService = configuration.reachabilityService {
            configureReachability(status: reachabilityService.currentStatus)
            reachabilityService
                .reachabilityStatus
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] reachabilityStatus in
                    self?.configureReachability(status: reachabilityStatus)
                })
                .store(in: &cancellable)
        } else {
            loadLink()
        }
    }

    private func configureReachability(status: WebKitBridgeReachabilityStatus) {
        reachabilityView?.isHidden = status == .hasInternet
        loadingView?.isHidden = true
        errorView?.isHidden = true
        if status == .hasInternet {
            loadLink()
        }
    }

    private func loadLink() {
        loadingView?.isHidden = false
        errorView?.isHidden = true
        spinnerManager?.showSpinner()
        DispatchQueue.main.async {
            self.webView?.load(URLRequest(url: self.configuration.linkURL))
        }
    }

    // MARK: - Actions

    @objc
    private func webViewTapped(_ sender: UITapGestureRecognizer) {
        lastTapPosition = sender.location(in: webView)
    }

    // MARK: - UIGestureRecognizerDelegate

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    // MARK: - UIPopoverControllerDelegate

    public func prepareForPopoverPresentation(
        _ popoverPresentationController: UIPopoverPresentationController
    ) {
        popoverPresentationController.sourceView = webView
        popoverPresentationController.sourceRect = .init(
            origin: lastTapPosition,
            size: .zero
        )
    }

    // MARK: - WKNavigationDelegate

    open func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard
            let requestUrl = navigationAction.request.url,
            requestUrl.isCustomUrlScheme(),
            UIApplication.shared.canOpenURL(requestUrl)
        else {
            decisionHandler(.allow)
            return
        }
        decisionHandler(.cancel)
        UIApplication.shared.open(requestUrl)
    }

    open func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        spinnerManager?.hideSpinner()
        loadingView?.isHidden = true
        errorView?.isHidden = true
    }

    public func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        errorView?.isHidden = false
        loadingView?.isHidden = true
        spinnerManager?.hideSpinner()
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        errorView?.isHidden = false
        loadingView?.isHidden = true
        spinnerManager?.hideSpinner()
    }

    // MARK: - AllPageReloaderManagerDelegate

    func pageShouldBeReloaded() {
        reloadWebView()
    }

}
