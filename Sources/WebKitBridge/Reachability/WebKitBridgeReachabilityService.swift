import Combine

public enum WebKitBridgeReachabilityStatus {
    case hasInternet
    case noInternet
}

public protocol WebKitBridgeReachabilityService {
    var currentStatus: WebKitBridgeReachabilityStatus { get }
    var reachabilityStatus: AnyPublisher<WebKitBridgeReachabilityStatus, Never> { get }
}
