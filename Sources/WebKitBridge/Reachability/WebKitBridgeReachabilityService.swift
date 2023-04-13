import Combine

public enum WebKitBridgeReachabilityStatus {
    case hasInternet
    case noInternet
}

public protocol WebKitBridgeReachabilityService {
    // Must be currentValueSubject to load link in view properly
    var reachabilityStatus: AnyPublisher<WebKitBridgeReachabilityStatus, Never> { get }
}
