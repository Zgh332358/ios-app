import Foundation

struct AppSettings: Codable {
    var endpoint: String?
    static let `default` = AppSettings(endpoint: nil)
}

enum WebAppDestination: Equatable {
    case unconfigured
    case invalid
    case page(URL)
}

/// Selects the hosted web-app. Provider credentials and model IDs belong on its server.
enum WebAppConfiguration {
    static let settingsKey = "app_settings"
    static let bundleKey = "RESONANCE_WEB_URL"

    static func destination(endpoint: String?, bundledEndpoint: String?) -> WebAppDestination {
        let saved = endpoint?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bundled = bundledEndpoint?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let selected = saved.isEmpty ? bundled : saved
        guard !selected.isEmpty else { return .unconfigured }
        guard let url = validatedURL(selected) else { return .invalid }
        return .page(url)
    }

    static func validatedURL(_ value: String) -> URL? {
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              let host = components.host?.lowercased(), !host.isEmpty,
              components.user == nil, components.password == nil,
              let url = components.url else { return nil }
        if let port = components.port, !(1...65535).contains(port) { return nil }
        let loopbackHosts = ["localhost", "127.0.0.1", "::1", "[::1]"]
        guard scheme == "https" || (scheme == "http" && loopbackHosts.contains(host)) else {
            return nil
        }
        return url
    }

    static func origin(of url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return ""
        }
        components.path = ""
        components.query = nil
        components.fragment = nil
        return components.string ?? ""
    }
}
