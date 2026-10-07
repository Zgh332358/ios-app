import Foundation

class ConfigurationService {
    static let shared = ConfigurationService()

    private let storage: KeyValueStorage
    private let bundledEndpoint: String?

    init(storage: KeyValueStorage = UserDefaultsStorage(),
         bundledEndpoint: String? = Bundle.main.object(forInfoDictionaryKey: WebAppConfiguration.bundleKey) as? String) {
        self.storage = storage
        self.bundledEndpoint = bundledEndpoint
    }

    func getWebDestination() -> WebAppDestination {
        let settings = storage.data(forKey: WebAppConfiguration.settingsKey)
            .flatMap { try? JSONDecoder().decode(AppSettings.self, from: $0) }
        return WebAppConfiguration.destination(endpoint: settings?.endpoint,
                                               bundledEndpoint: bundledEndpoint)
    }

    func getConfig() -> [String: Any] {
        guard case .page(let url) = getWebDestination() else {
            return ["configured": false, "webURL": "", "apiEndpoint": ""]
        }
        return [
            "configured": true,
            "webURL": url.absoluteString,
            "apiEndpoint": WebAppConfiguration.origin(of: url)
        ]
    }
}
