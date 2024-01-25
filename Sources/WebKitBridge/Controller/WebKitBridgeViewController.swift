import UIKit
import WebKit
import Combine

open class WebKitBridgeViewController: UIViewController, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate, WKNavigationDelegate, AllPageReloaderManagerDelegate, WebKitBridgeOutcomeEventRunnable, WebKitBridgeDOMLoadedDelegate {

    // MARK: - Nested Types

    public enum State {
        // Нужен, чтобы при начальном изменении на loading началась загрузка
        case initial
        
        case loading
        case noInternet
        case error
        case content
    }

    // MARK: - Subviews

    public private(set) var webView: WKWebView?

    // MARK: - Properties

    public let configuration: WebKitBridgeModuleConfiguration
    public private(set) var spinnerManager: WebKitBridgeSpinnerManager?

    private var internalIncomeEventsManager = WebKitBridgeBaseIncomeEventsManager(
        events: [
            WebKitBridgeDOMLoadedIncomeEvent()
        ],
        scriptProvider: NativeJSScriptsProvider()
    )

    private var stateChangeCompletions: [(State) -> Void] = []

    private var lastTapPosition: CGPoint = .zero
    private var cancellable = Set<AnyCancellable>()

    private var reachabilityView: UIView?
    private var loadingView: UIView?
    private var errorView: UIView?

    private(set) var state: State = .initial {
        didSet {
            guard state != oldValue else { return }
            updateSubviewsVisibility()

            if state == .loading {
                loadLink()
            }

            stateChangeCompletions.forEach { $0(state) }
        }
    }
    private var reloadAfterInternetAppearance = false

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
        Task {
            await recreateWebView()
        }
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

    // MARK: - WebKitBridgeDOMLoadedDelegate

    func _domContentLoaded() {
        domContentLoaded()
    }

    // MARK: - Methods to override

    /// Override, if needed changes to `WKWebViewConfiguration` - for example change storage.
    /// This method called inside `recreateWebView()`. So to apply changes on this code, you need to
    /// call `recreateWebView()` if you need changes after `viewDidLoad` - for example on button press
    /// you need to change storage.
    open func getWebViewConfig() async -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()

        let allIncomeEventsManagers: [WebKitBridgeIncomeEventsManager] = [
            configuration.incomeEventsManager,
            internalIncomeEventsManager
        ].compactMap { $0 }

        allIncomeEventsManagers.forEach { manager in
            manager.initialize(
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
        }

        // need to handle DOM loaded event
        let source = """
            var event = new CustomEvent("\(WebKitBridgeDOMLoadedIncomeEvent.staticName)", { });
            document.dispatchEvent(event);
        """
        let userScript = WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)

        return config
    }

    /// Reloads current instance of `WKWebView`. If you need to recreate `WKWebView` from scratch use
    /// method `recreateWebView()` instead
    open func reloadWebView() {
        if
            let reachability = configuration.reachabilityService,
            reachability.currentStatus == .noInternet
        {
            reloadAfterInternetAppearance = true
            return
        }
        state = .loading
    }

    /// Will be called after page loaded and DOM builded. Override this method to
    /// make some configuration after page loaded. For example, for showing/hiding some
    /// custom UI.
    open func domContentLoaded() {}

    /// Call to react on state change. For example to show loading indicator or change
    /// enabled property of reload button.
    open func reactOnStateChange(_ completion: @escaping (State) -> Void) {
        stateChangeCompletions.append(completion)
    }

    /// Method for recreating `WKWebView` from scratch. Call `getWebViewConfig()` inside.
    /// So you can call this method to apply changes to `WKWebViewConfiguration`.
    /// This method automatically called on `viewDidLoad()` first time. Next time you
    /// can call this method manually.
    open func recreateWebView() async {
        state = .initial
        reloadAfterInternetAppearance = false

        await configureWebView()
        configureViewProvider()
        configureReachability()
        AllPageReloaderManager.shared.subscribe(delegate: self)

        // link will be loaded inside reachbility publisher
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

    private func configureWebView() async {
        webView?.removeFromSuperview()
        webView = nil

        webView = WKWebView(frame: .zero, configuration: await getWebViewConfig())
        view.addSubview(webView!)
        view.sendSubviewToBack(webView!)
        webView?.navigationDelegate = self
        webView?.allowsBackForwardNavigationGestures = false
        webView?.scrollView.contentInsetAdjustmentBehavior = .always
        webView?.scrollView.showsHorizontalScrollIndicator = false
        webView?.scrollView.showsVerticalScrollIndicator = false

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(webViewTapped(_:)))
        tapGestureRecognizer.delegate = self
        webView?.addGestureRecognizer(tapGestureRecognizer)
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

    private func updateSubviewsVisibility() {
        loadingView?.isHidden = state != .loading
        errorView?.isHidden = state != .error
        reachabilityView?.isHidden = state != .noInternet

        if state == .loading {
            spinnerManager?.showSpinner()
        } else {
            spinnerManager?.hideSpinner()
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
            checkReachability(status: reachabilityService.currentStatus)
            reachabilityService
                .reachabilityStatus
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] reachabilityStatus in
                    // если пришел что интернета нет, а у нас уже загружена страница, то наверно не нужно ее перезагружать?
                    self?.checkReachability(status: reachabilityStatus)
                })
                .store(in: &cancellable)
        } else {
            state = .loading
        }
    }

    private func checkReachability(status: WebKitBridgeReachabilityStatus) {
        switch status {
        case .hasInternet:
            if state != .content || reloadAfterInternetAppearance {
                state = .loading
                reloadAfterInternetAppearance = false
            }
        case .noInternet:
            if state != .content {
                state = .noInternet
            }
        }
    }

    private func loadLink() {
        DispatchQueue.main.async {
            let url = self.configuration.linkURL
            if url.scheme == "file" {
                self.webView?.loadFileURL(
                    url,
                    allowingReadAccessTo: url
                )
            } else {
                self.webView?.load(URLRequest(url: url))
            }
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
        state = .content
    }

    public func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        if state != .noInternet {
            state = .error
        }
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        if state != .noInternet {
            state = .error
        }
    }

    // MARK: - AllPageReloaderManagerDelegate

    func pageShouldBeReloaded() {
        reloadWebView()
    }

}
