import Foundation

protocol AllPageReloaderManagerDelegate: AnyObject {
    func pageShouldBeReloaded()
}

private final class AllPageReloaderManagerDelegateWeak {

    // MARK: - Properties

    weak var value: AllPageReloaderManagerDelegate?

    // MARK: - Initializaino

    init(value: AllPageReloaderManagerDelegate) {
        self.value = value
    }

}

/// Entity for reloading all pages except page, where event was occured
final class AllPageReloaderManager {

    // MARK: - Static Properties

    static let shared = AllPageReloaderManager()

    // MARK: - Private Properties

    private var delegates: [AllPageReloaderManagerDelegateWeak] = []

    // MARK: - Initializaion

    private init() {}

    // MARK: - Methods

    func subscribe(delegate: AllPageReloaderManagerDelegate) {
        normalize()
        delegates.append(.init(value: delegate))
    }

    func setNeedsReloadAllPages(except: AllPageReloaderManagerDelegate? = nil) {
        normalize()
        delegates
            .filter { $0.value !== except }
            .forEach { $0.value?.pageShouldBeReloaded() }
    }

    // MARK: - Private Methods

    private func normalize() {
        delegates = delegates.filter { $0.value != nil }
    }

}
