import Foundation

extension URL {

    func isCustomUrlScheme() -> Bool {
        let defaultUrlSchemes = [
            "https://",
            "http://"
        ]

        let urlStringLowerCase = self.absoluteString.lowercased()
        for webUrlPrefix in defaultUrlSchemes where urlStringLowerCase.hasPrefix(webUrlPrefix) {
            return false
        }

        return true
    }

}
